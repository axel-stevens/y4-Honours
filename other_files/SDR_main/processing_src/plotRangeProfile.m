function [rangeAxis, rangePower] = plotRangeProfile(iqArray1D, numSweeps, fs, T_sweep, BW, fftSize, targetSweep)
    % Inputs:
    % iqArray1D: 1D complex array of IQ samples
    % numSweeps: Number of sweeps contained in the data
    % fs:        Sampling frequency (Hz)
    % T_sweep:   Active sweep time (s)
    % BW:        Bandwidth (Hz)
    % fftSize:   Size of the FFT (GUI defaults to 1024)

    %% 1. Reshape 1D Array to Matrix
    totalSamples = length(iqArray1D);
    samplesPerSweep = totalSamples / numSweeps;
    
    if mod(totalSamples, numSweeps) ~= 0
        error('Total samples must be divisible by the number of sweeps.');
    end
    
    % Reshape into [Samples per Sweep x Number of Sweeps]
    iqMatrix = reshape(iqArray1D, [samplesPerSweep, numSweeps]);

    %% 2. Signal Conditioning (Per GUI Logic)
    % Remove DC offset (mean of each sweep) [cite: 83]
    iqMatrix = iqMatrix - mean(iqMatrix, 1);
    
    % Apply Butterworth bandpass filter
    % GUI uses [0.04, 0.85] normalized frequency [cite: 76, 83]
    %[b, a] = butter(4, [0.04, 0.85]);
    %iqMatrix = filter(b, a, iqMatrix);

    %% 3. Range FFT & Static Clutter Removal
    % Perform FFT along the first dimension (Fast-Time) [cite: 83]
    rangeFFT = fft(iqMatrix, fftSize, 1);
    
    % Keep positive range bins [cite: 84]
    rangeFFT = rangeFFT(1:fftSize/2, :); 
    
    % Subtract mean across the second dimension (Slow-Time)
    % This is the "Moving Target Indicator" logic to remove ground/static clutter [cite: 84]
    rangeFFT = rangeFFT - mean(rangeFFT, 2);

    %% 4. Power Calculation & Normalization
    % Extract magnitude (GUI typically visualizes index 32) [cite: 84]
    rangePowerRaw = abs(rangeFFT(:, targetSweep));
    
    % GUI-specific normalization: scales signal to a 5-50 dB visual range [cite: 85]
    pMax = max(rangePowerRaw);
    pMin = min(rangePowerRaw);
    rangePower = (rangePowerRaw - pMin) / (pMax - pMin) * 45 + 5;

    %% 4b. Find Time Delay and Range of the strongest target
    % Find the index of the highest power peak
    [~, peakIndex] = max(rangePowerRaw);
    
    % 1. Calculate the beat frequency of that specific FFT bin
    frequencyBinWidth = fs / fftSize;
    beatFrequency = (peakIndex - 1) * frequencyBinWidth;
    
    % 2. Calculate the Time Delay (tau)
    f_slope = BW / T_sweep;        % Frequency slope (Hz/s)
    timeDelay = beatFrequency / f_slope;
    
    % 3. Calculate Range (just to verify it matches your plot axis)
    c = 3e8;
    targetRange = (timeDelay * c) / 2;
    
    % Print the results to the console
    fprintf('Target Beat Frequency: %.2f Hz\n', beatFrequency);
    fprintf('Signal Time Delay:   %.3e seconds\n', timeDelay);
    fprintf('Calculated Range:    %.2f meters\n', targetRange);

    %% 5. Range Axis Mapping
    c = 3e8; 
    %LARR = 1.4; % Calibration Range Ratio from source [cite: 53]
    
    % The GUI maps the axis up to fs/4 [cite: 86]
    % freqAxis = linspace(0, fs/4, fftSize/2);
    freqAxis = (0:fftSize/2-1) * frequencyBinWidth;
    
    % Convert frequency to range [cite: 86]
    rangeAxis = freqAxis * T_sweep / (2 * BW)  * c;

end