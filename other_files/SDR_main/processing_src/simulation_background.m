clear;
 
% Parameters
c = 3e8;                % Speed of light (m/s)
f_start = 24e9;         % Start frequency (Hz)
f_end = 24.25e9;         % Start frequency (Hz)
B = f_end-f_start;              % Sweep bandwidth (Hz)
T_sweep = 0.5e-3;         % Sweep time (s)
R = 3;                 % Target range (m)
R_bg = 37.8;             % Background/clutter reflector range (m)
Num_sweeps =10;          % Number of chirp sweeps to simulate
N = 128;   % Number of samples per sweep after downsampling (FFT size)
fs = round(B*3 ./ N) * N;
c_bg = 0.7;
c_target = 0.3;
 
% fs_ds: "slow"/effective sampling rate after downsampling, sized so
% that exactly N samples are captured per sweep (N samples / T_sweep).
fs_ds = N/ T_sweep;

% ds_factor: integer decimation factor to go from the high-rate
% synthesized signal (fs) down to the processed rate (fs_ds).
ds_factor = fs/fs_ds;
% Derived parameters
S = B / T_sweep;        % Frequency slope (Hz/s)
tau_target = 2 * R / c;        % Time delay for round trip
tau_bg = 2 * R_bg / c; 

% Time vector 
t_full = 0:1/fs:(Num_sweeps*T_sweep - 1/fs);   % one continuous time axis

n_tx = floor(t_full / T_sweep);
t_slow_tx = n_tx * T_sweep;
tx = exp(1i * (2*pi*f_start*(t_full - t_slow_tx) + pi*S*(t_full - t_slow_tx).^2));

% rx of target
k = round(tau_target * fs);   % delay in samples
rx_target = zeros(1, length(tx));
rx_target(k+1:end) = tx(1:end-k);

% Assuming there are some sort of strong reflector in the background
k = round(tau_bg * fs);   % delay in samples
rx_bg = zeros(1, length(tx));
rx_bg(k+1:end) = tx(1:end-k);

rx = rx_bg*c_bg + rx_target*c_target;

iq_signal = tx .* conj(rx);

t_full = (0:length(tx)-1) / fs;

% Extract I and Q components
% Noted each sweep we obtain N/2 amount of I and Q data
I_channel = real(iq_signal);
I_channel = I_channel(1:ds_factor*2:end);
Q_channel = imag(iq_signal);
Q_channel = Q_channel(1:ds_factor*2:end);
% Recombine downsampled I/Q into a single complex baseband signal at fs_ds
iq_signal = I_channel + 1i*Q_channel;

% FFT Processing
[rangeAxis, rangePower] = plotRangeProfileRaw(iq_signal, Num_sweeps, fs_ds, T_sweep, B, N, 3);

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
f_axis = (0:N-1) * (fs_ds/N);
X = abs(fft(iq_signal, N));
plot(f_axis, X);
xlabel('frequency');
ylabel('Amplitude');

plot(real(I_channel));
xlabel('frequency');
ylabel('Amplitude');


title("IQ signal");
grid on;

subplot(3,1,3);
plot(rangeAxis, rangePower);
xlabel('Range (m)');
ylabel('Amplitude');
title(['FMCW Range Detection of a Perfect Reflector ', R, "m away (plotRangeProfileRaw)"]);
grid on;
