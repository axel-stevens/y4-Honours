clear;
isPUP = true;

% Note: Overwritten filename variables from your original script are consolidated here
filename1 = "C:\Users\eliza\SDR_main\SDR_main\temp\1907_160cm_PUP_01.txt";
filename2 = "C:\Users\eliza\SDR_main\SDR_main\temp\1907_160to10cm_PUP_128ns_05ms_01.txt";

sampSize = 128;
T_sweep = 0.5 * 1E-3;
fs = sampSize / T_sweep;          % Sampling frequency
BW = 1000000000;

if isPUP == false
    % 1. Open the binary file for reading
    fid = fopen(filename1, 'rb');
    fid2 = fopen(filename2, 'rb');
    
    % 2. Read the data as 16-bit integers
    raw = fread(fid, inf, 'uint16');
    raw2 = fread(fid2, inf, 'uint16');
    
    % Now the standard header removal logic will work
    headerIndices = find(raw >= 49152);
    raw(headerIndices) = raw(headerIndices) - 49152;
    
    headerIndices2 = find(raw2 >= 49152);
    raw2(headerIndices2) = raw2(headerIndices2) - 49152;
    fclose(fid);
    fclose(fid2);
else
    raw = readmatrix(filename1);
    raw = raw(41:end);
    raw2 = readmatrix(filename2);
    raw2 = raw2(41:end);
end

% 4. Separate I (even indices) and Q (odd indices) and form the complex array
Q = double(raw(1:2:end)); 
I = double(raw(2:2:end));
Q2 = double(raw2(1:2:end)); 
I2 = double(raw2(2:2:end));

min_len = min([length(I), length(Q), length(I2), length(Q2)]);

% select the minimum length out of 2 data
numSweeps = floor(min_len/sampSize);
iq_data = I(1:numSweeps*sampSize) + 1i * Q(1:numSweeps*sampSize);
iq_data2 = I2(1:numSweeps*sampSize) + 1i * Q2(1:numSweeps*sampSize);

% Launch the interactive plot modularly
launchInteractivePlot(iq_data, iq_data2, numSweeps, fs, T_sweep, BW, sampSize);