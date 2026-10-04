clear;
% Parameters
c = 3e8;                % Speed of light (m/s)
f_start = 24e9;         % Start frequency (Hz)
f_end = 26e9;         % Start frequency (Hz)
B = f_end-f_start;              % Sweep bandwidth (Hz)
T_sweep = 1e-3;         % Sweep time (s)
R = 20000;                 % Target range (m)
Num_sweeps =5;
fs = 2 * B;
N = T_sweep*fs;

% Derived parameters
S = B / T_sweep;        % Frequency slope (Hz/s)
tau = 2 * R / c;        % Time delay for round trip

% Time vector 
t_full = 0:1/fs:(Num_sweeps*T_sweep - 1/fs);   % one continuous time axis

n_tx = floor(t_full / T_sweep);
t_slow_tx = n_tx * T_sweep;
tx = exp(1i * (2*pi*f_start*(t_full - t_slow_tx) + pi*S*(t_full - t_slow_tx).^2));

k = round(tau * fs);   % delay in samples

rx = zeros(1, length(tx));
rx(k+1:end) = tx(1:end-k);

iq_signal = tx .* conj(rx);

t_full = (0:length(tx)-1) / fs;

% Extract I and Q components
I_channel = real(iq_signal);
Q_channel = imag(iq_signal);

% FFT Processing
[rangeAxis, rangePower] = plotRangeProfileRaw(iq_signal, Num_sweeps, fs, T_sweep, B, N, 3);

% Plot
figure;
subplot(3,1,1);
phase_tx = unwrap(angle(tx));
inst_freq_tx = [0, diff(phase_tx)] .* fs / (2*pi); 
plot(t_full, inst_freq_tx/1e9);
hold on
phase_rx = unwrap(angle(rx));
inst_freq_rx = [0, diff(phase_rx)] .* fs / (2*pi); 
plot(t_full, inst_freq_rx/1e9);

xlabel('Time(t)');
ylabel('Frequency (GHz)');

title("tx and rx freq slope");
grid on;

subplot(3,1,2);
Nfft = length(iq_signal);
f_axis = (0:Nfft-1) * (fs/Nfft);
X = abs(fft(iq_signal));
plot(f_axis, X);
xlabel('frequency');
ylabel('Amplitude');

title("IQ signal");
grid on;

subplot(3,1,3);
plot(rangeAxis, rangePower);
xlabel('Range (m)');
ylabel('Amplitude');
xlim([0, R*10]);
title(['FMCW Range Detection of a Perfect Reflector ', R, "m away (plotRangeProfileRaw)"]);
grid on;
