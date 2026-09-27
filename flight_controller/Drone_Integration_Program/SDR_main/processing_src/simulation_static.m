% Parameters
c = 3e8;                % Speed of light (m/s)
f_start = 24e9;         % Start frequency (Hz)
f_end = 26e9;         % Start frequency (Hz)
B = f_end-f_start;              % Sweep bandwidth (Hz)
T_sweep = 1e-3;         % Sweep time (s)
R = 4.5;                 % Target range (m)

% Derived parameters
S = B / T_sweep;        % Frequency slope (Hz/s)
tau = 2 * R / c;        % Time delay for round trip

% Time vector
fs = 2 * B;             % Sampling frequency
t = 0:1/fs:T_sweep;     % Time array for one sweep

% Transmitted and Received Signals
tx = exp(1i * (2*pi*f_start*t + pi*S*t.^2));
rx = -exp(1i * (2*pi*f_start*(t-tau) + pi*S*(t-tau).^2)); 

% Mixing
iq_signal = tx .* conj(rx);

% Extract I and Q components
I_channel = real(iq_signal);
Q_channel = imag(iq_signal);

% FFT Processing
N = length(iq_signal);
f_axis = (0:N-1)*(fs/N);
f_axis = f_axis(1:N/2);
X = abs(fft(iq_signal));

[rangeAxis, rangePower] = plotRangeProfileRaw(iq_signal, 1, fs, T_sweep, B, N, 1);

% Plot Range Spectrum
figure;
subplot(2,1,1);
plot(t, unwrap(angle(rx)));
xlim([0, T_sweep])
xlabel('Time(t)');
ylabel('Phase');
title("Rx Phase slope");
grid on;

subplot(2,1,2);
plot(rangeAxis, rangePower);
xlabel('Range (m)');
ylabel('Amplitude');
xlim([0, 5]);
title(['FMCW Range Detection of a Perfect Reflector ', R, "m away (plotRangeProfileRaw)"]);
grid on;
