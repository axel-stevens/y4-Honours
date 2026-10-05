clear;





filename1 = "C:\Users\eliza\SDR_main\SDR_main\data\30082026_matlab\3008_0-5GHz_256_1ms_loopback";
filename1 = "C:\Users\eliza\SDR_main\SDR_main\data\30082026_matlab\3008_1GHz_128_0-5ms_outdoor_4m";


filename1 = "C:\Users\eliza\SDR_main\SDR_main\data\23082026_matlab\2308_128_0-5ms_8m_Static";
filename1 = "C:\Users\eliza\SDR_main\SDR_main\data\30082026_matlab\3008_1GHz_128_0-5ms_outdoor_1-6m";
raw = readmatrix(filename1); 
raw = raw(41:end); % remove first 40 lines of meta data

sampSize = 128;
T_sweep=0.5e-3;
fs = sampSize/ T_sweep;          % Sampling frequency
fftSize = sampSize;
BW=1e9;
c = 3e8;

% Separate I (even indices) and Q (odd indices) and form the complex array
Q = double(raw(1:2:end)); 
I = double(raw(2:2:end));
min_len = min(length(I), length(Q));
iq_data = I(1:min_len) + 1i * Q(1:min_len);

% select the minimum length out of 2 data
numSweeps = floor(min(length(iq_data))/sampSize);
iq_data = I(1:numSweeps*sampSize) + 1i * Q(1:numSweeps*sampSize);

% Reshape into [sampSize x numSweeps] so each COLUMN of iq_sweeps is an
% array of data from single sweep (128 iq samples)
Iq_sweeps = reshape(iq_data, sampSize, numSweeps);

% Remove the DC offset
Iq_sweeps = Iq_sweeps - mean(Iq_sweeps, 1);

[b, a] = butter(4, [0.04, 0.85]);
Iq_sweeps = filter(b, a, Iq_sweeps);
Iq_sweeps = Iq_sweeps(sampSize/4+1: sampSize*3/4, :);

[nRows, nCols] = size(Iq_sweeps);
tmp = complex(zeros(nRows*2, nCols));
    for k = 1:nCols
        tmp(:,k) = interp(real(Iq_sweeps(:,k)), 2) ...
              + 1i*interp(imag(Iq_sweeps(:,k)), 2);
    end
Iq_sweeps = tmp;

Iq_sweeps = mean(Iq_sweeps, 2);

% Plot raw IQ
figure;
subplot(3,1,1);
plot(imag(Iq_sweeps));
xlabel('Sample Index');
ylabel('Amplitude');
title('Raw Q Data');
grid on;

subplot(3,1,2);
plot(real(Iq_sweeps));
xlabel('Sample Index');
ylabel('Amplitude');
title('Raw I Data');
grid on;

% FFT each column (each sweep) independently
rangefft_all = fft(Iq_sweeps, fftSize, 1);

% Magnitude spectrum per sweep, then average across sweeps
magSpectra = abs(rangefft_all);              % [fftSize x numSweeps]
avgSpectrum = mean(magSpectra, 2);            % average across sweeps

% Frequency / range axis 
frequencyBinWidth = fs / fftSize;
freqAxis = (0:fftSize- 1) * frequencyBinWidth;
rangeAxis = freqAxis * T_sweep / (2 * BW) * c;

% Plot averaged spectrum (positive frequencies only)
subplot(3,1,3);
plot(rangeAxis, avgSpectrum');
xlabel('Range (m)');
ylabel('Averaged Magnitude');
title('Range Profile Averaged Across Sweeps');
grid on;
