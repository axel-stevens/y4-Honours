function [handles, info] = PUPradar_initiating(handles, varargin)
%PUPRADAR_INITIATING  Standalone version of PUPradarGUI's PUPradar_initiating.
%
%   Brings up the USB link: checks the chip, selects interface 1, finds the
%   two endpoints, downloads the firmware, then queries the board for its
%   model information.
%
%   handles = PUPradar_initiating(handles)
%       Initialises the radar and returns handles with EndPoint2_Num,
%       EndPoint6_Num and the board info fields filled in. Call this before
%       Send_PLL_Sawtooth or GetComplexData.
%
%   handles = PUPradar_initiating()
%       Same, starting from makeRadarHandles() defaults.
%
%   [handles, info] = PUPradar_initiating(...)
%       info also returns the decoded board fields on their own.
%
%   Options:
%     'HexFile', path   firmware hex file (default 'SDR_USB_FW.hex',
%                       looked up next to this .m file if not in the cwd)
%     'Verbose', true   print each step as it happens
%
%   Fields added to handles:
%     EndPoint2_Num, EndPoint6_Num   USB endpoint handles
%     FrequencyBand, Num_Tx, Num_Rx, AntennaType, Version
%     modelcode, model
%
%   Unlike the GUI original, failures raise an error instead of writing to
%   a text box and returning half-initialised handles - there is no message
%   window outside the GUI, and a silent return would leave you with an
%   empty endpoint that fails much later. Identifier prefix is
%   'PUPradar_initiating:'.
%
%   See also MAKERADARHANDLES, SEND_PLL_SAWTOOTH, GETCOMPLEXDATA.

if nargin < 1 || isempty(handles)
    handles = makeRadarHandles();
end

opts = struct('HexFile', 'SDR_USB_FW.hex', 'Verbose', false);
if mod(numel(varargin), 2) ~= 0
    error('PUPradar_initiating:badArgs', 'Options must be Name/value pairs.');
end
for k = 1:2:numel(varargin)
    if ~isfield(opts, varargin{k})
        error('PUPradar_initiating:badOpt', 'Unknown option ''%s''.', varargin{k});
    end
    opts.(varargin{k}) = varargin{k+1};
end

    function say(fmt, varargin)
        if opts.Verbose
            fprintf(['  ' fmt '\n'], varargin{:});
        end
    end

%% ---- USB chip check ----------------------------------------------------
[device_count, vID, pID] = usbcheckchip;
if device_count > 1
    error('PUPradar_initiating:multipleBoards', ...
        'More than one USB board found (%d). Disconnect all but one.', device_count);
elseif device_count == 0
    error('PUPradar_initiating:noBoard', 'No USB board found.');
end
if (vID ~= 1204) || (pID ~= 34323)
    error('PUPradar_initiating:wrongChip', ...
        'Wrong USB chip: vID=%d pID=%d (expected 1204 / 34323).', vID, pID);
end
say('USB board found (vID=%d, pID=%d)', vID, pID);

%% ---- Interface and endpoints -------------------------------------------
interface_no = usbsetinterface1;
if interface_no ~= 1
    error('PUPradar_initiating:setInterface', ...
        'Set interface failure (usbsetinterface1 returned %d).', interface_no);
end

handles.EndPoint2_Num = usbfindendpoint(2);
if handles.EndPoint2_Num == 0
    error('PUPradar_initiating:noEndpoint2', 'Could not find endpoint 2.');
end
handles.EndPoint6_Num = usbfindendpoint(134);   % 134 = 0x86
if handles.EndPoint6_Num == 0
    error('PUPradar_initiating:noEndpoint6', 'Could not find endpoint 6.');
end
say('Endpoints: 2 -> %d, 6 -> %d', handles.EndPoint2_Num, handles.EndPoint6_Num);

%% ---- Firmware download --------------------------------------------------
hexFile = resolveHexFile(opts.HexFile);
fid = fopen(hexFile);
if fid == -1
    error('PUPradar_initiating:hexOpen', 'Could not open hex file ''%s''.', hexFile);
end
cleanup = onCleanup(@() fclose(fid));

codedata = {};
i = 0;
while true
    tline = fgetl(fid);
    if ~ischar(tline)
        error('PUPradar_initiating:hexRead', ...
            'Hex file read error: reached end of ''%s'' without an end record.', hexFile);
    end
    if strcmp(tline(2:3), '00')
        break
    end
    i = i + 1;
    codedata{i,1} = int64(hex2dec(tline(2:3)));   %#ok<AGROW>
    codedata{i,2} = uint16(hex2dec(tline(4:7)));  %#ok<AGROW>
    bincode = uint8([]);
    for j = 10:2:(size(tline,2)-2)
        bincode((j-8)/2) = uint8(hex2dec(tline(j:(j+1))));
    end
    codedata{i,3} = bincode;                      %#ok<AGROW>
end
clear cleanup   % closes the file
say('Firmware: %d records read from %s', i, hexFile);

linesdone = usbdownload(codedata);
if linesdone ~= (i-1)
    error('PUPradar_initiating:fwDownload', ...
        'Firmware download error: %d of %d records written.', linesdone, i-1);
end
say('Firmware downloaded (%d records)', linesdone);

%% ---- Query board info ---------------------------------------------------
instruction = hex2dec('FA00');
ForwardData = zeros(512,1) + instruction;
SendOutData = uint16(ForwardData);
miniradarputdata(SendOutData, handles.EndPoint2_Num);

DataLength = 512 + 2048;
[PUPradarBoardInfo, ~] = miniradargetdata(handles.EndPoint6_Num, DataLength);
PUPradarBoardInfo = dec2hex(PUPradarBoardInfo(1025:1100), 4);

if strcmp(PUPradarBoardInfo(1,:), 'FA05')
    handles.FrequencyBand = hex2dec(PUPradarBoardInfo(2, 3:4));   % new protocol: 240 = xFA
    handles.Num_Tx        = hex2dec(PUPradarBoardInfo(3, 1));
    handles.Num_Rx        = hex2dec(PUPradarBoardInfo(3, 2));
    handles.AntennaType   = hex2dec(PUPradarBoardInfo(3, 3:4));
    handles.Version       = hex2dec(PUPradarBoardInfo(4, 2));

    handles.modelcode = handles.FrequencyBand*1000000 + handles.Num_Tx*100000 + ...
                        handles.Num_Rx*10000 + handles.AntennaType*100 + handles.Version;

    switch handles.modelcode
        case 24240100
            handles.model = 'Model  PUP_DU24P_T2R4';    % band=24 (24G), old module name
        case 240240100
            handles.model = 'Model  PUP_EN24P_T2R4';    % band=240, 24GHz new define
        case 240240200
            handles.model = 'Model  PUP_EN24C_T2R4 V1';
        case 240240202
            handles.model = 'Model  PUP_EN24C_T2R4 V2';
        case 240140201
            handles.model = 'Model  PUP_EN24C_T1R4';
        otherwise
            handles.model = 'Needs Refresh';
    end
    say('Board: %s (modelcode %d, %d Tx / %d Rx)', ...
        handles.model, handles.modelcode, handles.Num_Tx, handles.Num_Rx);
else
    handles.model = '';
    warning('PUPradar_initiating:noBoardInfo', ...
        ['Board info header was ''%s'', expected ''FA05'' - model fields not filled in. ', ...
         'The endpoints are still valid, so acquisition may still work.'], ...
        PUPradarBoardInfo(1,:));
end

info = struct( ...
    'model',         handles.model, ...
    'modelcode',     getfielddef(handles, 'modelcode', []), ...
    'FrequencyBand', getfielddef(handles, 'FrequencyBand', []), ...
    'Num_Tx',        getfielddef(handles, 'Num_Tx', []), ...
    'Num_Rx',        getfielddef(handles, 'Num_Rx', []), ...
    'AntennaType',   getfielddef(handles, 'AntennaType', []), ...
    'Version',       getfielddef(handles, 'Version', []));
end


function path = resolveHexFile(name)
% Use the file as given if it exists, otherwise look next to this .m file.
if exist(name, 'file') == 2
    path = name;
    return
end
here = fileparts(mfilename('fullpath'));
candidate = fullfile(here, name);
if exist(candidate, 'file') == 2
    path = candidate;
    return
end
error('PUPradar_initiating:hexMissing', ...
    'Firmware file ''%s'' not found in the current folder or in %s.', name, here);
end


function v = getfielddef(s, name, default)
if isfield(s, name)
    v = s.(name);
else
    v = default;
end
end
