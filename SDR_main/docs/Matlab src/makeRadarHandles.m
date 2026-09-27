function handles = makeRadarHandles(varargin)
%MAKERADARHANDLES  Build the handles struct GetComplexData and
%   Send_PLL_Sawtooth need, outside the GUI.
%
%   handles = makeRadarHandles()
%   handles = makeRadarHandles('Name', value, ...)
%
%   Any field can be overridden by name. Examples:
%
%     h = makeRadarHandles('ActiveNum_Rx', 4, 'NumSweeps', 256);
%     h = makeRadarHandles('SN_Selections', [4096 2048 1024 512], ...
%                          'ActiveSamplingNumberValue', 2);   % -> LASN = 2048
%
%   Note LASN (samples per sweep per Rx) = SN_Selections(ActiveSamplingNumberValue).
%   If you'd rather set that number directly, pass 'SamplingNumber':
%
%     h = makeRadarHandles('SamplingNumber', 1024);
%
%   See also GETCOMPLEXDATA, SEND_PLL_SAWTOOTH.

% Defaults matching a typical PUP configuration.
handles = struct( ...
    ... % --- acquisition (GetComplexData) ---
    'SN_Selections',              [1024, 512, 256, 128], ...
    'ActiveSamplingNumberValue',  1, ...
    'ActiveNum_Tx',               1, ...
    'ActiveNum_Rx',               1, ...
    'ActiveTransmitterString',    'Tx1', ...
    'ActiveReceiverString',       'Rx1', ...
    'NumSweeps',                  128, ...
    'EndPoint6_Num',              [], ...
    'modelcode',                  '', ...
    ... % --- FMCW chirp (Send_PLL_Sawtooth) ---
    'ActiveFrequencyLow',         24.0e9, ...
    'ActiveFrequencyHigh',        24.25e9, ...
    'ActiveSweepTime',            1e-3, ...
    'EndPoint2_Num',              []);

if mod(numel(varargin), 2) ~= 0
    error('makeRadarHandles:badArgs', 'Arguments must be Name/value pairs.');
end

samplingNumber = [];
for k = 1:2:numel(varargin)
    name = varargin{k};
    value = varargin{k+1};
    if strcmpi(name, 'SamplingNumber')
        samplingNumber = value;
    else
        handles.(name) = value;
    end
end

% 'SamplingNumber' shortcut: put the value straight into SN_Selections(1).
if ~isempty(samplingNumber)
    handles.SN_Selections = samplingNumber;
    handles.ActiveSamplingNumberValue = 1;
end

validateRadarHandles(handles);
end


function validateRadarHandles(h)
if h.ActiveSamplingNumberValue < 1 || h.ActiveSamplingNumberValue > numel(h.SN_Selections)
    error('makeRadarHandles:badIndex', ...
        'ActiveSamplingNumberValue (%d) is outside SN_Selections (1..%d).', ...
        h.ActiveSamplingNumberValue, numel(h.SN_Selections));
end
if ~ismember(h.ActiveNum_Tx, [1 2])
    error('makeRadarHandles:badTx', 'ActiveNum_Tx must be 1 or 2.');
end
if ~ismember(h.ActiveNum_Rx, [1 2 4])
    error('makeRadarHandles:badRx', 'ActiveNum_Rx must be 1, 2 or 4.');
end
if ~ismember(h.ActiveTransmitterString, {'Tx1', 'Tx2'})
    error('makeRadarHandles:badTxStr', 'ActiveTransmitterString must be ''Tx1'' or ''Tx2''.');
end
switch h.ActiveNum_Rx
    case 1
        valid = {'Rx1', 'Rx2', 'Rx3', 'Rx4'};
    case 2
        valid = {'Rx1.Rx2', 'Rx3.Rx4'};
    otherwise
        valid = {'Rx1.Rx2.Rx3.Rx4', 'Rx1', ''};  % 4-Rx path ignores the string
end
if ~ismember(h.ActiveReceiverString, valid)
    warning('makeRadarHandles:rxStr', ...
        'ActiveReceiverString ''%s'' is unusual for %d Rx channels.', ...
        h.ActiveReceiverString, h.ActiveNum_Rx);
end
if h.ActiveFrequencyHigh <= h.ActiveFrequencyLow
    error('makeRadarHandles:badSweep', ...
        'ActiveFrequencyHigh (%g) must be above ActiveFrequencyLow (%g).', ...
        h.ActiveFrequencyHigh, h.ActiveFrequencyLow);
end
if ~ismember(h.ActiveSweepTime, [0.5e-3, 1e-3, 2e-3, 4e-3, 8e-3])
    error('makeRadarHandles:badSweepTime', ...
        'ActiveSweepTime must be 0.5e-3, 1e-3, 2e-3, 4e-3 or 8e-3 s.');
end
end
