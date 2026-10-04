%RUN_SEND_PLL_SAWTOOTH  Example: program the FMCW chirp outside the PUP GUI.
%
% DRY_RUN = true  -> just compute and print the PLL registers, no hardware
% DRY_RUN = false -> actually write them to the radar over USB endpoint 2
%
% Run from the folder containing the .mexw64 files ("Matlab src"), or add
% that folder to the path first.

clear; clc;

DRY_RUN = true;

%% ---- Chirp configuration ----------------------------------------------
handles = makeRadarHandles( ...
    'ActiveFrequencyLow',  24.0e9, ...   % chirp start, Hz
    'ActiveFrequencyHigh', 24.25e9, ...  % chirp stop, Hz
    'ActiveSweepTime',     1e-3);        % 0.5e-3 | 1e-3 | 2e-3 | 4e-3 | 8e-3

%% ---- Program the PLL ---------------------------------------------------
if DRY_RUN
    fprintf('DRY RUN - nothing is sent to the radar.\n\n');
    [regs, handles] = Send_PLL_Sawtooth(handles, 'DryRun', true, 'Verbose', true);
else
    % Brings up USB, downloads the firmware and fills in the endpoints.
    handles = PUPradar_initiating(handles, 'Verbose', true);
    [regs, handles] = Send_PLL_Sawtooth(handles, 'Verbose', true);
end

%% ---- Report ------------------------------------------------------------
fprintf('\nBandwidth      : %.3f GHz\n', regs.Bandwidth/1e9);
fprintf('Sweep-up ratio : %.2f  (T_sweepup = %.3f ms of %.3f ms)\n', ...
    regs.SweepUpPercent, regs.T_Sweepup*1e3, handles.ActiveSweepTime*1e3);
fprintf('PLLSweepStop   : %d\n', regs.PLLSweepStop);
fprintf('Steps          : %d   step size = %d (2^-24 x 50 MHz units)\n', ...
    regs.NumSteps, regs.Step_N);
fprintf('\nPLL registers:\n');
fprintf('  Reg03 (start int)  = %10d  0x%s\n', regs.PLLReg03, dec2hex(regs.PLLReg03, 6));
fprintf('  Reg04 (start frac) = %10d  0x%s\n', regs.PLLReg04, dec2hex(regs.PLLReg04, 6));
fprintf('  Reg0A (step)       = %10d  0x%s\n', regs.PLLReg0A, dec2hex(regs.PLLReg0A, 6));
fprintf('  Reg0C (stop int)   = %10d  0x%s\n', regs.PLLReg0C, dec2hex(regs.PLLReg0C, 6));
fprintf('  Reg0D (stop frac)  = %10d  0x%s\n', regs.PLLReg0D, dec2hex(regs.PLLReg0D, 6));

% Cross-check: what stop frequency do Reg0C/Reg0D actually land on?
F_stop_actual = (regs.PLLReg0C + regs.PLLReg0D/2^24) * 50e6 * 16;
fprintf('\nRequested stop : %.6f GHz\n', handles.ActiveFrequencyHigh/1e9);
fprintf('Achieved stop  : %.6f GHz  (error %.3f MHz)\n', ...
    F_stop_actual/1e9, (F_stop_actual - handles.ActiveFrequencyHigh)/1e6);

fprintf('\n%d register byte-writes total.\n', size(regs.Writes, 1));
