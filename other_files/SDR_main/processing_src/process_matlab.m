function [raw, I_out, Q_out, freqAxis, rangeAxis, avgSpectrum] = process_matlab(filename, sampSize, T_sweep, BW)
% processRangeProfile  Load SDR data and compute averaged range profile
%
% INPUTS:
%   filename   - full path to data file (no extension needed)
%   sampSize   - number of samples per sweep (e.g. 128)
%   T_sweep    - sweep duration in seconds (e.g. 5e-4)
%   BW         - bandwidth in Hz (e.g. 0.25e9)
%
% OUTPUTS:
%   I_out       - raw I data, reshaped [sampSize/2 x numSweeps]
%   Q_out       - raw Q data, reshaped [sampSize/2 x numSweeps]
%   freqAxis    - frequency axis in Hz [1 x fftSize]
%   rangeAxis   - range axis in metres  [1 x fftSize]
%   avgSpectrum - averaged magnitude range profile [fftSize x 1]

    %% Constants
    c      = 3e8;
    fs     = sampSize / T_sweep / 2;   % sampling frequency
    fftSize = sampSize;

        %% Load data — .mat (GUI export) or raw text
    [~, ~, ext] = fileparts(filename);
    if strcmpi(ext, '.mat')
        S = load(filename);
        % GUI saves ComplexDataTx1 for Tx1, ComplexDataTx2 for Tx2
        if isfield(S, 'ComplexDataTx1') && any(S.ComplexDataTx1(:) ~= 0)
            iqMat = S.ComplexDataTx1;
        else
            iqMat = S.ComplexDataTx2;
        end
        raw       = iqMat;                          % expose the loaded matrix
        numSweeps = size(iqMat, 2);
        Iq_sweeps = iqMat;                          % already [LASN*LANR x numSweeps]
        I_out     = real(iqMat);
        Q_out     = imag(iqMat);
        % override caller args with what the GUI actually used, if present
        if isfield(S, 'LASN'), sampSize = 2 * S.LASN; fftSize = sampSize; end
        if isfield(S, 'LAST'), T_sweep  = S.LAST;  end
        if isfield(S, 'LAFL') && isfield(S, 'LAFH'), BW = S.LAFH - S.LAFL; end
        fs = sampSize / T_sweep / 2;
    end
          % remove first 40 lines of metadata

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

end
