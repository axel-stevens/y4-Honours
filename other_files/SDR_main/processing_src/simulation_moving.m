clear;
% Parameters
c = 3e8;                % Speed of light (m/s)
f_start = 24e6;         % Start frequency (Hz)
f_end = 26e6;         % Start frequency (Hz)
B = f_end-f_start;              % Sweep bandwidth (Hz)
T_sweep = 1e-3;         % Sweep time (s)
R0 = 20000;                 % Target initial range (m)
v  = 10000;                % Target radial velocity (m/s)
Num_sweeps =1000;
fs = 2 * B;
N = T_sweep*fs;
target=400;

% Derived parameters
S = B / T_sweep;        % Frequency slope (Hz/s)

% Time vector 
t_full = 0:1/fs:(Num_sweeps*T_sweep - 1/fs);   % one continuous time axis
n_tx = floor(t_full / T_sweep);
t_slow_tx = n_tx * T_sweep;
tx = exp(1i * (2*pi*f_start*(t_full - t_slow_tx) + pi*S*(t_full - t_slow_tx).^2));

R_t   = R0 + v * t_full; 
tau_t = 2 * R_t / c;         
t_rx  = t_full - tau_t;       % time at which the echo currently arriving was actually transmitted
valid = t_rx >= 0;            % remove neg time
n_rx  = floor(t_rx / T_sweep);
t_slow_rx = n_rx .* T_sweep;

rx = zeros(1, length(tx));
rx(valid) = exp(1i * (2*pi*f_start*(t_rx(valid) - t_slow_rx(valid)) + ...
                       pi*S*(t_rx(valid) - t_slow_rx(valid)).^2));

iq_signal = tx .* conj(rx);

t_full = (0:length(tx)-1) / fs;

% Extract I and Q components
I_channel = real(iq_signal);
Q_channel = imag(iq_signal);

% FFT Processing
[rangeAxis, rangePower] = plotRangeProfileRaw(iq_signal, Num_sweeps, fs, T_sweep, B, N, target);

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
title(['FMCW Range Detection of a Perfect Reflector initally', R0, "m away (plotRangeProfileRaw)", v, "M/S"]);
grid on;

launchInteractiveRawPlot(iq_signal, iq_signal, Num_sweeps, fs, T_sweep, B, N);
