%RUN_GETCOMPLEXDATA  Example: call GetComplexData outside the PUP GUI.
%
% Edit the settings below and run this script. Two modes:
%   USE_HARDWARE = true   -> reads live from the radar over USB
%   USE_HARDWARE = false  -> replays a saved RawData vector from a .mat file
%
% Run this from the folder containing the .mexw64 files ("Matlab src"),
% or add that folder to the path first.

clear; clc;

USE_HARDWARE = false;
RAW_FILE     = 'RawData.mat';   % must contain a variable named RawData

%% ---- Radar configuration (put whatever you want here) ------------------
handles = makeRadarHandles( ...
    'SamplingNumber',          1024, ...   % samples per sweep per Rx (LASN)
    'ActiveNum_Tx',            1, ...      % 1 or 2
    'ActiveNum_Rx',            1, ...      % 1, 2 or 4
    'ActiveTransmitterString', 'Tx1', ...  % 'Tx1' or 'Tx2'
    'ActiveReceiverString',    'Rx1', ...  % 'Rx1'..'Rx4', or 'Rx1.Rx2'/'Rx3.Rx4'
    'NumSweeps',               128);

%% ---- Get the data -----------------------------------------------------
if USE_HARDWARE
    % Bring up the USB link and download the firmware, as the GUI does.
    handles = PUPradar_initiating(handles, 'Verbose', true);

    % Program the FMCW chirp before acquiring.
    Send_PLL_Sawtooth(handles);

    [Tx1, Tx2, NumSweeps] = GetComplexData(handles);
else
    S = load(RAW_FILE);
    [Tx1, Tx2, NumSweeps] = GetComplexData(handles, S.RawData);
end

fprintf('Decoded %d sweeps.\n', NumSweeps);
fprintf('Tx1: %s   Tx2: %s\n', mat2str(size(Tx1)), mat2str(size(Tx2)));

%% ---- Quick look -------------------------------------------------------
if NumSweeps > 0
    figure('Name', 'GetComplexData output');

    subplot(2,1,1);
    plot(real(Tx1(:,1)), 'DisplayName', 'I');
    hold on;
    plot(imag(Tx1(:,1)), 'DisplayName', 'Q');
    grid on; legend show;
    title('Tx1, first sweep - raw I/Q');
    xlabel('Sample'); ylabel('Amplitude');

    subplot(2,1,2);
    RangeProfile = 20*log10(abs(fft(Tx1(:,1))) + eps);
    plot(RangeProfile);
    grid on;
    title('Tx1, first sweep - range profile');
    xlabel('Range bin'); ylabel('dB');
end
