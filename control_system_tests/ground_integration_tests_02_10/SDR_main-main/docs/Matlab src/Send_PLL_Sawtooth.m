function [regs, handles] = Send_PLL_Sawtooth(handles, varargin)
%SEND_PLL_SAWTOOTH  Standalone version of PUPradarGUI's Send_PLL_Sawtooth.
%
%   Programs the PLL for an FMCW sawtooth (up-chirp) sweep by pushing
%   register bytes to the MCU over USB endpoint 2.
%
%   regs = Send_PLL_Sawtooth(handles)
%       Computes the PLL registers and writes them to the radar.
%
%   regs = Send_PLL_Sawtooth(handles, 'DryRun', true)
%       Computes and returns everything but sends nothing. Use this to
%       inspect the register values with no radar connected.
%
%   regs = Send_PLL_Sawtooth(handles, 'Verbose', true)
%       Prints each register write as it happens.
%
%   handles is a plain struct - no GUI needed. Required fields
%   (see makeRadarHandles.m):
%
%     ActiveFrequencyLow  : sweep start frequency in Hz  (e.g. 24.0e9)
%     ActiveFrequencyHigh : sweep stop frequency in Hz   (e.g. 24.25e9)
%     ActiveSweepTime     : 0.5e-3 | 1e-3 | 2e-3 | 4e-3 | 8e-3 seconds
%     EndPoint2_Num       : USB endpoint handle (unused when DryRun)
%
%   Outputs:
%     regs    : struct of the computed values -
%                 .PLLReg03 .PLLReg04 .PLLReg0A .PLLReg0C .PLLReg0D
%                 .PLLSweepStop .Bandwidth .SweepUpPercent .T_Sweepup
%                 .NumSteps .Step_N .Writes (n-by-2: [address_hex_word, byte])
%     handles : handles with ActiveBandwidth / ActivePLLSweepStop filled in,
%               matching what the GUI stored back.
%
%   Assumes a BGT24 front end (F_PLLinput = F_Tx/16) and a 50 MHz
%   reference, exactly as the original. The arithmetic is unchanged; the
%   only additions are the DryRun/Verbose options and an error for an
%   unsupported sweep time (the original silently used a stale
%   MaxSweepover).

opts = struct('DryRun', false, 'Verbose', false);
if mod(numel(varargin), 2) ~= 0
    error('Send_PLL_Sawtooth:badArgs', 'Options must be Name/value pairs.');
end
for k = 1:2:numel(varargin)
    if ~isfield(opts, varargin{k})
        error('Send_PLL_Sawtooth:badOpt', 'Unknown option ''%s''.', varargin{k});
    end
    opts.(varargin{k}) = varargin{k+1};
end

LAFL = handles.ActiveFrequencyLow;
LAFH = handles.ActiveFrequencyHigh;
LAST = handles.ActiveSweepTime;

T_ref = 1/50e6;    % T_ref = 1/F_ref = 1/50MHz

handles.ActiveBandwidth = LAFH - LAFL;
LABW = handles.ActiveBandwidth;
if LABW <= 0
    error('Send_PLL_Sawtooth:badBandwidth', ...
        'ActiveFrequencyHigh (%g) must be above ActiveFrequencyLow (%g).', LAFH, LAFL);
end

if LABW <= 0.5e9
    T_Sweepup_Percent = 0.94;   % for BW <= 500MHz
elseif LABW == 1e9
    T_Sweepup_Percent = 0.92;   % for BW = 1GHz
elseif LABW == 1.5e9
    T_Sweepup_Percent = 0.84;   % for BW = 1.5GHz
elseif LABW == 2e9
    T_Sweepup_Percent = 0.8;    % for BW = 2GHz
else
    T_Sweepup_Percent = 0.75;   % for BW > 2GHz
end

switch LAST  % Local Active Sweep Time
    case 0.5e-3
        MaxSweepover = 4096;    % 4096 steps
    case 1e-3
        MaxSweepover = 8192;    % 8192 steps
    case 2e-3
        MaxSweepover = 16384;
    case 4e-3
        MaxSweepover = 32768;
    case 8e-3
        MaxSweepover = 65536;
    otherwise
        error('Send_PLL_Sawtooth:badSweepTime', ...
            ['ActiveSweepTime %g s is not supported. ', ...
             'Use 0.5e-3, 1e-3, 2e-3, 4e-3 or 8e-3.'], LAST);
end

handles.ActivePLLSweepStop = ceil(MaxSweepover * (T_Sweepup_Percent + 0.01));
LocalActivePLLSweepStop = handles.ActivePLLSweepStop;
T_Sweepup = LAST * T_Sweepup_Percent;

Writes = zeros(0, 2);

% --- PLLSweepStop, 16 bits ---------------------------------------------
[Low8bit, High8bit] = split16(LocalActivePLLSweepStop);
Writes = send(Writes, 'D200', Low8bit,  'PLLSweepStop low',  handles, opts);
Writes = send(Writes, 'D100', High8bit, 'PLLSweepStop high', handles, opts);

% for BGT24, F_PLLinput = F_Tx/16; others may be F_Tx/2
F_start = LAFL / 16;
F_stop  = LAFH / 16;

% Calculate PLL output value
Start_N = F_start / 50e6;
Stop_N  = F_stop  / 50e6;
Start_N_int  = floor(Start_N);
Start_N_frac = Start_N - Start_N_int;
PLLReg03 = Start_N_int;
PLLReg04 = round(Start_N_frac * 2^24);

% --- Reg 03: integer part of start frequency ---------------------------
[L, M, H] = split24(PLLReg03);
Writes = send(Writes, 'C300', L, 'Reg03 low',    handles, opts);
Writes = send(Writes, 'C200', M, 'Reg03 middle', handles, opts);
Writes = send(Writes, 'C100', H, 'Reg03 high',   handles, opts);

% --- Reg 04: fractional part of start frequency ------------------------
[L, M, H] = split24(PLLReg04);
Writes = send(Writes, 'C600', L, 'Reg04 low',    handles, opts);
Writes = send(Writes, 'C500', M, 'Reg04 middle', handles, opts);
Writes = send(Writes, 'C400', H, 'Reg04 high',   handles, opts);

% estimated number of steps in T_sweepup
NumSteps = T_Sweepup / T_ref;

% step size in number of 50MHz
Step_int = (Stop_N - Start_N) / NumSteps;
% step size in number of the minimum frequency, 2.98Hz
Step_N = round(Step_int * 2^24);
PLLReg0A = Step_N;

% --- Reg 0A: step size --------------------------------------------------
[L, M, H] = split24(PLLReg0A);
Writes = send(Writes, 'C900', L, 'Reg0A low',    handles, opts);
Writes = send(Writes, 'C800', M, 'Reg0A middle', handles, opts);
Writes = send(Writes, 'C700', H, 'Reg0A high',   handles, opts);

% adjust to approach accurate stop frequency
NumSteps = round((Stop_N - Start_N) / (Step_N/2^24));

% Number of steps in 50MHz
Num_of_50MHz = floor(NumSteps * Step_N / 2^24);
PLLReg0C = Start_N_int + Num_of_50MHz;
PLLReg0D = mod(NumSteps*Step_N, 2^24) + PLLReg04;

if PLLReg0D > 2^24
    PLLReg0C = PLLReg0C + 1;
    PLLReg0D = PLLReg0D - 2^24;
end

% --- Reg 0C: integer part of stop frequency ----------------------------
[L, M, H] = split24(PLLReg0C);
Writes = send(Writes, 'CC00', L, 'Reg0C low',    handles, opts);
Writes = send(Writes, 'CB00', M, 'Reg0C middle', handles, opts);
Writes = send(Writes, 'CA00', H, 'Reg0C high',   handles, opts);

% --- Reg 0D: fractional part of stop frequency -------------------------
[L, M, H] = split24(PLLReg0D);
Writes = send(Writes, 'CF00', L, 'Reg0D low',    handles, opts);
Writes = send(Writes, 'CE00', M, 'Reg0D middle', handles, opts);
Writes = send(Writes, 'CD00', H, 'Reg0D high',   handles, opts);

regs = struct( ...
    'PLLReg03',       PLLReg03, ...
    'PLLReg04',       PLLReg04, ...
    'PLLReg0A',       PLLReg0A, ...
    'PLLReg0C',       PLLReg0C, ...
    'PLLReg0D',       PLLReg0D, ...
    'PLLSweepStop',   LocalActivePLLSweepStop, ...
    'Bandwidth',      LABW, ...
    'SweepUpPercent', T_Sweepup_Percent, ...
    'T_Sweepup',      T_Sweepup, ...
    'NumSteps',       NumSteps, ...
    'Step_N',         Step_N, ...
    'Writes',         Writes);
end


function [Low8bit, High8bit] = split16(value)
Low8bit  = mod(value, 2^8);
High8bit = mod(value - Low8bit, 2^16) / 2^8;
end


function [Low8bit, Middle8bit, High8bit] = split24(value)
Low8bit    = mod(value, 2^8);
Middle8bit = mod(value - Low8bit, 2^16) / 2^8;
High8bit   = (value - Low8bit - Middle8bit*2^8) / 2^16;
end


function Writes = send(Writes, AddrHex, Byte, Label, handles, opts)
% One PLL byte write: the MCU expects 1024 copies of (address | byte).
Word = hex2dec(AddrHex) + Byte;
Writes(end+1, :) = [Word, Byte]; %#ok<AGROW>

if opts.Verbose
    fprintf('  %-16s  %s -> 0x%s\n', Label, AddrHex, dec2hex(Word, 4));
end
if ~opts.DryRun
    ForwardData = zeros(1024, 1) + Word;
    SendOutData = uint16(ForwardData);
    miniradarputdata(SendOutData, handles.EndPoint2_Num);
end
end
