function [rangeAxis, rangePower] = plotRangeProfileRaw(iqArray1D, numSweeps, fs, T_sweep, BW, fftSize, targetSweep)
    % Inputs:
    % iqArray1D: 1D complex array of IQ samples
    % numSweeps: Number of sweeps contained in the data
    % fs:        Sampling frequency of data where I connotated with Q(Hz)
    % T_sweep:   Active sweep time (s)
    % BW:        Bandwidth (Hz)
    % fftSize:   Size of the FFT (GUI defaults to 1024)

    fs = fs/2; % sampling raw i and q with fs mean sampling complex iq with fs/2

    %% 1. Reshape 1D Array to Matrix
    totalSamples = length(iqArray1D)*2;
    samplesPerSweep = totalSamples / numSweeps;
    
    if mod(totalSamples, numSweeps) ~= 0
        error('Total samples must be divisible by the number of sweeps.');
    end
    
    % Reshape into [Samples per Sweep x Number of Sweeps]
    iqMatrix = reshape(iqArray1D, [samplesPerSweep/2, numSweeps]);
    
    %% 3. RangeA FFT & Static Clutter Removal
    % Perform FFT along the first dimension (Fast-Time) [cite: 83]
    rangeFFT = fft(iqMatrix, fftSize, 1);

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

    freqAxis = (0:fftSize-1) * frequencyBinWidth;
    
    % Convert frequency to range [cite: 86]
    rangeAxis = freqAxis * c/ ( 2 * f_slope);

end