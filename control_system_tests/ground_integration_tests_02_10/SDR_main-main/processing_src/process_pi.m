function [raw, I_out, Q_out, freqAxis, rangeAxis, avgSpectrum, ComplexDataTx1, info] = ...
         process_pi(filename, sampSize, T_sweep, BW, opts)
% process_pi  Load a Raspberry Pi .bin capture into the MATLAB GUI's format.
%
% The Pi tool writes the untouched EP6 bulk stream, so the file carries a lot
% that is not signal: each bulk read is preceded by stale FIFO contents (the
% tail of the board-info reply, then filler), sweeps get cut short when a read
% ends mid-sweep, and the first words of the file are whatever was left in the
% endpoint. The GUI throws all of that away before it looks at a single sample.
%
% This function reproduces the framing half of GetComplexData in
% PUPradarGUI.m (lines 2734-2755), so ComplexDataTx1 here is the same thing the
% GUI's Record button saves to .mat: a [LASN x NumSweeps] complex matrix, one
% column per sweep, raw ADC counts with no scaling. The processing that follows
% is unchanged from the previous version of this file.
%
% What gets discarded:
%   * everything before the first sweep marker (stale preamble / filler)
%   * any sweep shorter than the measured stride (a read ended mid-sweep)
%   * the trailing partial sweep at end of file
%
% INPUTS:
%   filename  - full path to the .bin. If sampSize/T_sweep/BW are omitted they
%               are read from the matching .json sidecar.
%   sampSize  - complex samples per sweep per Rx channel (LASN, e.g. 128). Used
%               as a cross-check against the stride measured from the file.
%   T_sweep   - sweep duration in seconds (e.g. 5e-4)
%   BW        - sweep bandwidth in Hz (e.g. 0.25e9)
%
% NAME-VALUE OPTIONS:
%   MaxSweeps - keep at most this many sweeps (default Inf), taken from the
%               start. Use it to cap memory on a long capture.
%   FFTSize   - range-FFT length. Default is one bin per complex sample, which
%               equals sampSize on a capture the device framed as requested.
%   Verbose   - print what was kept and what was thrown away (default true)
%
% OUTPUTS:
%   raw            - the trimmed, de-tagged word stream actually used, column
%                    vector (NOT the whole file — that is the point here)
%   I_out          - real part, [LASN x numSweeps]  (== real(ComplexDataTx1))
%   Q_out          - imag part, [LASN x numSweeps]  (== imag(ComplexDataTx1))
%   freqAxis       - beat-frequency axis in Hz [1 x fftSize]
%   rangeAxis      - range axis in metres      [1 x fftSize]
%   avgSpectrum    - averaged magnitude range profile [fftSize x 1]
%   ComplexDataTx1 - the GUI-format complex matrix [LASN x numSweeps]
%   info           - struct describing the framing and how much was discarded

    arguments
        filename
        sampSize = []
        T_sweep  = []
        BW       = []
        opts.MaxSweeps (1,1) double  = Inf
        opts.FFTSize   (1,1) double  = 0
        opts.Verbose   (1,1) logical = true
    end

    c       = 3e8;
    HDR_TAG = 49152;   % 0xC000 — Tx1 sweep marker (PUPradarGUI.m:2741)
    ADC_MAX = 4095;    % 12-bit ADC, so a real marker word is 0xC000..0xCFFF

    filename = char(filename);

    %% 1. Load the whole file as unsigned 16-bit little-endian words
    fid = fopen(filename, 'rb');
    if fid < 0
        error('process_pi:CannotOpen', 'Cannot open %s', filename);
    end
    closeFile  = onCleanup(@() fclose(fid));
    words      = fread(fid, inf, 'uint16=>double', 0, 'ieee-le');
    nWordsFile = numel(words);

    %% 2. Find the sweep markers and strip their tag bits
    % The firmware ORs 0xC000 into the first word of every Tx1 sweep. Like the
    % GUI we subtract the tag rather than deleting the word, so the marker word
    % survives as an ordinary sample and the sweep keeps its full length
    % (PUPradarGUI.m:2743).
    hdr = find(words >= HDR_TAG & words <= HDR_TAG + ADC_MAX);
    if numel(hdr) < 2
        error('process_pi:NoSweepMarker', ...
              ['Found %d sweep markers (0x%X..0x%X) in %s. A Tx1 capture ' ...
               'should have one per sweep — is this a Tx2 capture, or an ' ...
               'already-processed file?'], ...
              numel(hdr), HDR_TAG, HDR_TAG + ADC_MAX, filename);
    end
    words(hdr) = words(hdr) - HDR_TAG;

    %% 3. Measure the true sweep stride from the marker spacing
    strideWords   = mode(diff(hdr));
    expectedWords = 2 * sampSize;   % I,Q interleaved, single Rx channel

    if mod(strideWords, 2) ~= 0
        error('process_pi:OddStride', ...
              'Measured sweep stride %d is odd — cannot split into I/Q pairs.', ...
              strideWords);
    end

    %% 4. Keep only markers that own a whole sweep
    gapToNext = [diff(hdr); nWordsFile - hdr(end) + 1];
    starts    = hdr(gapToNext >= strideWords);
    nRejected = numel(hdr) - numel(starts);

    if isempty(starts)
        error('process_pi:NoWholeSweep', ...
              'No complete sweep of %d words found in %s.', strideWords, filename);
    end
    if isfinite(opts.MaxSweeps) && numel(starts) > opts.MaxSweeps
        starts = starts(1:opts.MaxSweeps);
    end

    %% 5. Gather the sweeps — one column each, aligned to its own marker
    idx    = starts(:).' + (0:strideWords-1).';   % [strideWords x numSweeps]
    sweeps = words(idx);

    % Drop any sweep still holding an out-of-range word: those are stale bytes
    % that survived the preamble, not samples.
    goodSweep = ~any(sweeps > ADC_MAX, 1);
    nDirty    = sum(~goodSweep);
    sweeps    = sweeps(:, goodSweep);
    if isempty(sweeps)
        error('process_pi:NoCleanSweep', ...
              'Every candidate sweep in %s contained out-of-range words.', filename);
    end
    numSweeps = size(sweeps, 2);
    raw       = sweeps(:);                        % only the words we kept

    %% 6. Build ComplexDataTx1 exactly as the GUI does
    I_out = sweeps(1:2:end, :);   % real part — [LASN x numSweeps]
    Q_out = sweeps(2:2:end, :);   % imag part
    ComplexDataTx1 = I_out + 1i * Q_out;

    complexPerSweep = strideWords / 2;   % == LASN when the device obeyed
    fs              = complexPerSweep / T_sweep;
    if opts.FFTSize > 0
        fftSize = opts.FFTSize;
    else
        fftSize = complexPerSweep;
    end

    Iq_sweeps = ComplexDataTx1;

    %% ---- processing below is unchanged ----

    %% DC offset removal
    Iq_sweeps = Iq_sweeps - mean(Iq_sweeps, 'all');

    %% Range FFT across each sweep (column-wise)
    rangefft_all = fft(Iq_sweeps, fftSize, 1);   % [fftSize x numSweeps]

    %% Average magnitude across all sweeps
    magSpectra  = abs(rangefft_all);              % [fftSize x numSweeps]
    avgSpectrum = mean(magSpectra, 2);            % [fftSize x 1]

    %% Build frequency and range axes
    freqBinWidth = fs / fftSize;
    freqAxis     = (0:fftSize-1) * freqBinWidth; % [1 x fftSize]
    rangeAxis    = freqAxis * T_sweep / (2 * BW) * c; % [1 x fftSize]

    %% Report what was kept and what was thrown away
    wordsUsed = numel(raw);
    info = struct( ...
        'file',                 filename, ...
        'wordsInFile',          nWordsFile, ...
        'wordsUsed',            wordsUsed, ...
        'discardedPercent',     100 * (1 - wordsUsed / nWordsFile), ...
        'markersFound',         numel(hdr), ...
        'preambleWordsDropped', starts(1) - 1, ...
        'sweepStrideWords',     strideWords, ...
        'sweepStrideExpected',  expectedWords, ...
        'strideMismatch',       strideWords ~= expectedWords, ...
        'sweepsKept',           numSweeps, ...
        'sweepsRejectedShort',  nRejected, ...
        'sweepsRejectedDirty',  nDirty, ...
        'complexPerSweep',      complexPerSweep, ...
        'fs',                   fs, ...
        'fftSize',              fftSize);

    if info.strideMismatch
        warning('process_pi:StrideMismatch', ...
            ['Measured sweep stride is %d words (%d complex samples) but ' ...
             'sampSize=%d implies %d words for a single Rx channel.\n' ...
             'Trusting the file. On Tx1/Rx1 the device is delivering %.3gx ' ...
             'the data you asked for — it likely kept the sampling number ' ...
             'from an earlier run, so power-cycle it and re-capture.'], ...
            strideWords, complexPerSweep, sampSize, expectedWords, ...
            strideWords / expectedWords);
    end

    if opts.Verbose
        if info.strideMismatch
            strideNote = sprintf('  <-- sampSize=%d implies %d', sampSize, expectedWords);
        else
            strideNote = '';
        end
        fprintf('process_pi: %s\n', filename);
        fprintf('  stride       : %d words/sweep (%d complex samples)%s\n', ...
                strideWords, complexPerSweep, strideNote);
        fprintf('  sweeps       : %d kept, %d short, %d with stale words\n', ...
                numSweeps, nRejected, nDirty);
        fprintf('  preamble     : %d words dropped before the first marker\n', ...
                info.preambleWordsDropped);
        fprintf('  data used    : %d of %d words (%.1f%% of the file discarded)\n', ...
                wordsUsed, nWordsFile, info.discardedPercent);
        fprintf('  ComplexDataTx1: [%d x %d]   fs %.6g Hz   fftSize %d\n', ...
                size(ComplexDataTx1,1), size(ComplexDataTx1,2), fs, fftSize);
    end
end
