function [ComplexDataTx1, ComplexDataTx2, NumSweeps, RawData] = GetComplexData(handles, RawDataIn)
%GETCOMPLEXDATA  Standalone version of PUPradarGUI's GetComplexData.
%
%   [Tx1, Tx2, NumSweeps] = GetComplexData(handles)
%       Reads raw data from the radar over USB (miniradargetdata) and
%       de-interleaves it into complex I/Q sweeps.
%
%   [...] = GetComplexData(handles, RawData)
%       Skips the hardware read and uses the supplied RawData vector
%       instead (raw, i.e. WITH the 2048 leading leftover samples, exactly
%       as miniradargetdata returns it). Use this to replay a saved capture
%       with no radar attached.
%
%   handles is a plain struct - it does NOT need to be a GUI handles
%   object. Required fields (see makeRadarHandles.m for a builder with
%   sensible defaults):
%
%     ActiveSamplingNumberValue : index into SN_Selections
%     SN_Selections             : vector of available sampling numbers
%     ActiveNum_Tx              : 1 or 2
%     ActiveNum_Rx              : 1, 2 or 4
%     ActiveTransmitterString   : 'Tx1' or 'Tx2'   (only used when 1 Tx)
%     ActiveReceiverString      : 'Rx1'|'Rx2'|'Rx3'|'Rx4'  (1 Rx)
%                                 'Rx1.Rx2'|'Rx3.Rx4'      (2 Rx)
%     NumSweeps                 : number of sweeps requested
%     EndPoint6_Num             : USB endpoint handle (unused if RawDataIn
%                                 is given; may be [] in that case)
%
%   Outputs:
%     ComplexDataTx1 : (LASN*NumRx) x NumSweeps complex samples for Tx1
%     ComplexDataTx2 : same, for Tx2 (zeros when that Tx is inactive)
%     NumSweeps      : sweeps actually decoded (may be < requested)
%     RawData        : the raw vector used, after the 2048-sample discard
%
%   Differences from the in-GUI original: channel-string comparisons use
%   strcmp instead of ==, and the stray "save rx3" debug line was removed.
%   The decode maths is unchanged.

if nargin < 2
    RawDataIn = [];
end

LASNV = handles.ActiveSamplingNumberValue;
LASN  = handles.SN_Selections(LASNV);
LANT  = handles.ActiveNum_Tx;
LANR  = handles.ActiveNum_Rx;
LARS  = handles.ActiveReceiverString;
LATS  = handles.ActiveTransmitterString;
NumSweeps = handles.NumSweeps;

if isempty(RawDataIn)
    % Transfer data from MCU
    DataLength = ceil((NumSweeps + 40) * LASN * 2 * LANR * LANT / 512) * 512 + 4096;
    [RawData, ~] = miniradargetdata(handles.EndPoint6_Num, DataLength);
else
    RawData = RawDataIn;
end

% Discard 2048 leftover data samples
RawData = double(RawData(2049:end));

% Data check and remove headers
if LANT == 1          % Device has 1 Tx channel
    if strcmp(LATS, 'Tx1')
        try
            Tx1Index = find(RawData >= 49152);    % find and remove Tx1 header
            RawData(Tx1Index) = RawData(Tx1Index) - 49152;
            ValidSweepNumber = (Tx1Index(end-1) - Tx1Index(1)) / (LASN*2*LANR);
            if NumSweeps > ValidSweepNumber
                NumSweeps = ValidSweepNumber;
            end
            ValidData = RawData(Tx1Index(1):Tx1Index(end-1) + LASN*2*LANR - 1); % *2: I&Q
            DataMatrixTx1 = reshape(ValidData, LASN*2*LANR, []);
            if LANR == 1
                ComplexDataTx1(1:LASN, 1:NumSweeps) = DataMatrixTx1(1:2:LASN*2-1, 1:NumSweeps) + ...
                    DataMatrixTx1(2:2:LASN*2, 1:NumSweeps)*1i;
                ComplexDataTx2 = zeros(LASN, NumSweeps);
            elseif LANR == 2
                ComplexDataTx1(1:LASN, 1:NumSweeps) = DataMatrixTx1(1:4:LASN*4-3, 1:NumSweeps) + ...
                    DataMatrixTx1(2:4:LASN*4-2, 1:NumSweeps)*1i;
                ComplexDataTx1(LASN+1:LASN*2, 1:NumSweeps) = DataMatrixTx1(3:4:LASN*4-1, 1:NumSweeps) + ...
                    DataMatrixTx1(4:4:LASN*4, 1:NumSweeps)*1i;
                ComplexDataTx2 = zeros(LASN*2, NumSweeps);
            elseif LANR == 4
                ComplexDataTx1(1:LASN, 1:NumSweeps) = -DataMatrixTx1(1:8:LASN*8-7, 1:NumSweeps)*1i + ...
                    DataMatrixTx1(2:8:LASN*8-6, 1:NumSweeps);
                ComplexDataTx1(LASN+1:LASN*2, 1:NumSweeps) = -DataMatrixTx1(3:8:LASN*8-5, 1:NumSweeps)*1i + ...
                    DataMatrixTx1(4:8:LASN*8-4, 1:NumSweeps);
                ComplexDataTx1(LASN*2+1:LASN*3, 1:NumSweeps) = -DataMatrixTx1(5:8:LASN*8-3, 1:NumSweeps)*1i + ...
                    DataMatrixTx1(6:8:LASN*8-2, 1:NumSweeps);
                ComplexDataTx1(LASN*3+1:LASN*4, 1:NumSweeps) = -DataMatrixTx1(7:8:LASN*8-1, 1:NumSweeps)*1i + ...
                    DataMatrixTx1(8:8:LASN*8, 1:NumSweeps);
                ComplexDataTx2 = zeros(LASN*4, NumSweeps);
            end
        catch
            ComplexDataTx1 = zeros(LASN*4, NumSweeps);
            ComplexDataTx2 = zeros(LASN*4, NumSweeps);
            return
        end

    elseif strcmp(LATS, 'Tx2')
        try
            Tx2Index = find(RawData >= 32768);   % find and remove Tx2 header
            RawData(Tx2Index) = RawData(Tx2Index) - 32768;
            ValidSweepNumber = (Tx2Index(end-1) - Tx2Index(1)) / (LASN*2*LANR);
            if NumSweeps > ValidSweepNumber
                NumSweeps = ValidSweepNumber;
            end
            ValidData = RawData(Tx2Index(1):Tx2Index(end-1) + LASN*2*LANR - 1); % *2: I&Q
            DataMatrixTx2 = reshape(ValidData, LASN*2*LANR, []);
            if LANR == 1
                ComplexDataTx2(1:LASN, 1:NumSweeps) = DataMatrixTx2(1:2:LASN*2-1, 1:NumSweeps) + ...
                    DataMatrixTx2(2:2:LASN*2, 1:NumSweeps)*1i;
                ComplexDataTx1 = zeros(LASN, NumSweeps);
            elseif LANR == 2
                ComplexDataTx2(1:LASN, 1:NumSweeps) = DataMatrixTx2(1:4:LASN*4-3, 1:NumSweeps) + ...
                    DataMatrixTx2(2:4:LASN*4-2, 1:NumSweeps)*1i;
                ComplexDataTx2(LASN+1:LASN*2, 1:NumSweeps) = DataMatrixTx2(3:4:LASN*4-1, 1:NumSweeps) + ...
                    DataMatrixTx2(4:4:LASN*4, 1:NumSweeps)*1i;
                ComplexDataTx1 = zeros(LASN*2, NumSweeps);
            elseif LANR == 4
                ComplexDataTx2(1:LASN, 1:NumSweeps) = DataMatrixTx2(1:8:LASN*8-7, 1:NumSweeps) + ...
                    DataMatrixTx2(2:8:LASN*8-6, 1:NumSweeps)*1i;
                ComplexDataTx2(LASN+1:LASN*2, 1:NumSweeps) = DataMatrixTx2(3:8:LASN*8-5, 1:NumSweeps) + ...
                    DataMatrixTx2(4:8:LASN*8-4, 1:NumSweeps)*1i;
                ComplexDataTx2(LASN*2+1:LASN*3, 1:NumSweeps) = DataMatrixTx2(5:8:LASN*8-3, 1:NumSweeps) + ...
                    DataMatrixTx2(6:8:LASN*8-2, 1:NumSweeps)*1i;
                ComplexDataTx2(LASN*3+1:LASN*4, 1:NumSweeps) = DataMatrixTx2(7:8:LASN*8-1, 1:NumSweeps) + ...
                    DataMatrixTx2(8:8:LASN*8, 1:NumSweeps)*1i;
                ComplexDataTx1 = zeros(LASN*4, NumSweeps);
            end
        catch
            ComplexDataTx1 = zeros(LASN*4, NumSweeps);
            ComplexDataTx2 = zeros(LASN*4, NumSweeps);
            return
        end
    end

else  % Device has 2 Tx channels
    try
        Tx1Index = find(RawData >= 49152);
        Tx2Index = find(RawData < 49150 & RawData >= 32768);

        % remove headers
        RawData(Tx1Index) = RawData(Tx1Index) - 49152; % find and remove Tx1 header
        RawData(Tx2Index) = RawData(Tx2Index) - 32768; % find and remove Tx2 header
        ValidSweepNumber = (Tx2Index(end-1) - Tx1Index(1)) / (LASN*2*LANR*LANT);
        if NumSweeps > ValidSweepNumber
            NumSweeps = ValidSweepNumber;
        end
        ValidData = RawData(Tx1Index(1):Tx1Index(1) + LASN*2*LANR*LANT*NumSweeps - 1);
        DataMatrix = reshape(ValidData, LASN*2*LANR, []);
        DataMatrixTx1 = DataMatrix(:, 1:2:NumSweeps*2);
        DataMatrixTx2 = DataMatrix(:, 2:2:NumSweeps*2);
        if LANR == 1
            ComplexDataTx1(1:LASN, 1:NumSweeps) = DataMatrixTx1(1:2:LASN*2-1, 1:NumSweeps)*4 + ...
                DataMatrixTx1(2:2:LASN*2, 1:NumSweeps)*4*1i;
            ComplexDataTx2(1:LASN, 1:NumSweeps) = DataMatrixTx2(1:2:LASN*2-1, 1:NumSweeps)*4 + ...
                DataMatrixTx2(2:2:LASN*2, 1:NumSweeps)*4*1i;
        elseif LANR == 2
            ComplexDataTx1(1:LASN, 1:NumSweeps) = DataMatrixTx1(1:4:LASN*4-3, 1:NumSweeps)*4 + ...
                DataMatrixTx1(2:4:LASN*4-2, 1:NumSweeps)*4*1i;
            ComplexDataTx1(LASN+1:LASN*2, 1:NumSweeps) = DataMatrixTx1(3:4:LASN*4-1, 1:NumSweeps)*4 + ...
                DataMatrixTx1(4:4:LASN*4, 1:NumSweeps)*4*1i;
            ComplexDataTx2(1:LASN, 1:NumSweeps) = DataMatrixTx2(1:4:LASN*4-3, 1:NumSweeps)*4 + ...
                DataMatrixTx2(2:4:LASN*4-2, 1:NumSweeps)*4*1i;
            ComplexDataTx2(LASN+1:LASN*2, 1:NumSweeps) = DataMatrixTx2(3:4:LASN*4-1, 1:NumSweeps)*4 + ...
                DataMatrixTx2(4:4:LASN*4, 1:NumSweeps)*4*1i;
        elseif LANR == 4
            ComplexDataTx1(1:LASN, 1:NumSweeps) = DataMatrixTx1(1:8:LASN*8-7, 1:NumSweeps)*4 + ...
                DataMatrixTx1(2:8:LASN*8-6, 1:NumSweeps)*4*1i;
            ComplexDataTx1(LASN+1:LASN*2, 1:NumSweeps) = DataMatrixTx1(3:8:LASN*8-5, 1:NumSweeps)*4 + ...
                DataMatrixTx1(4:8:LASN*8-4, 1:NumSweeps)*4*1i;
            ComplexDataTx1(LASN*2+1:LASN*3, 1:NumSweeps) = DataMatrixTx1(5:8:LASN*8-3, 1:NumSweeps)*4 + ...
                DataMatrixTx1(6:8:LASN*8-2, 1:NumSweeps)*4*1i;
            ComplexDataTx1(LASN*3+1:LASN*4, 1:NumSweeps) = DataMatrixTx1(7:8:LASN*8-1, 1:NumSweeps)*4 + ...
                DataMatrixTx1(8:8:LASN*8, 1:NumSweeps)*4*1i;
            ComplexDataTx2(1:LASN, 1:NumSweeps) = DataMatrixTx2(1:8:LASN*8-7, 1:NumSweeps)*4 + ...
                DataMatrixTx2(2:8:LASN*8-6, 1:NumSweeps)*4*1i;
            ComplexDataTx2(LASN+1:LASN*2, 1:NumSweeps) = DataMatrixTx2(3:8:LASN*8-5, 1:NumSweeps)*4 + ...
                DataMatrixTx2(4:8:LASN*8-4, 1:NumSweeps)*4*1i;
            ComplexDataTx2(LASN*2+1:LASN*3, 1:NumSweeps) = DataMatrixTx2(5:8:LASN*8-3, 1:NumSweeps)*4 + ...
                DataMatrixTx2(6:8:LASN*8-2, 1:NumSweeps)*4*1i;
            ComplexDataTx2(LASN*3+1:LASN*4, 1:NumSweeps) = DataMatrixTx2(7:8:LASN*8-1, 1:NumSweeps)*4 + ...
                DataMatrixTx2(8:8:LASN*8, 1:NumSweeps)*4*1i;
        end
    catch
        ComplexDataTx1 = zeros(LASN*4, NumSweeps);
        ComplexDataTx2 = zeros(LASN*4, NumSweeps);
        return
    end
end
