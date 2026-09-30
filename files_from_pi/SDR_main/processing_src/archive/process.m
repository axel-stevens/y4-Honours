% 1. Open the binary file for reading
fid = fopen("C:\Users\eliza\SDR_main\SDR_main\temp\cap_background.bin", 'rb');
fid2 = fopen("C:\Users\eliza\SDR_main\SDR_main\temp\cap_wavinghand2.bin", 'rb');

% 2. Read the data as 16-bit integers
% Using '*int16' keeps the data type as int16 in MATLAB (saves memory)
raw = fread(fid, inf, 'uint16');
raw2 = fread(fid2, inf, 'uint16');

% Now the standard header removal logic will work
headerIndices = find(raw >= 49152);
raw(headerIndices) = raw(headerIndices) - 49152;

headerIndices2 = find(raw2 >= 49152);
raw2(headerIndices2) = raw2(headerIndices2) - 49152;
sampSize = 256;

% 3. Close the file
fclose(fid);
fclose(fid2);

% 4. Separate I (odd indices) and Q (even indices) and form the complex array
% Note: MATLAB uses 1-based indexing
Q = double(raw(1:2:end)); 
I = double(raw(2:2:end));
min_len = min(length(I), length(Q));
iq_data = I(1:min_len) + 1i * Q(1:min_len);

Q2 = double(raw2(1:2:end)); 
I2 = double(raw2(2:2:end));
min_len2 = min(length(I2), length(Q2));
iq_data2 = I2(1:min_len2) + 1i * Q2(1:min_len2);

% select the minimum length out of 2 data
numSweeps = floor(min(length(iq_data), length(iq_data2))/sampSize);
iq_data = I(1:numSweeps*sampSize) + 1i * Q(1:numSweeps*sampSize);
iq_data2 = I2(1:numSweeps*sampSize) + 1i * Q2(1:numSweeps*sampSize);

% ... [Keep all your file reading and IQ data generation code above this line] ...

fs = 256000;            % Sampling frequency (2.048 MHz)
T_sweep = 0.001;        % Time per sweep
BW = 250000000;         % Bandwidth
sampSize = 256;         % Samples per sweep

% --- Create Interactive UI ---

% 1. Create the main UI Figure
fig = uifigure('Name', 'Interactive Range Profile', 'Position', [100, 100, 800, 600], 'Color', 'w');

% 2. Create UI Axes for the plot
ax = uiaxes(fig, 'Position', [50, 150, 700, 400]);
% Apply your dark theme to the UI axes
set(ax, 'Color', 'k', ...
         'XColor', 'w', ...
         'YColor', 'w', ...
         'GridColor', [0.23 0.44 0.34], ...
         'GridLineStyle', '--');
grid(ax, 'on');

% 3. Create the Slider
% Set limits from 1 to 4000 (or up to numSweeps if less than 4000)
maxSweep = min(4000, numSweeps); 
sld = uislider(fig, 'Position', [150, 70, 500, 3]);
sld.Limits = [1, maxSweep];
sld.Value = 1000; % Initial target sweep
sld.MajorTicks = linspace(1, maxSweep, 10); % Add tick marks for readability

% 4. Add a Label for the Slider
lbl = uilabel(fig, 'Position', [150, 90, 200, 22], 'Text', 'Target Sweep: 1000');

% 5. Call the update function once to draw the initial graph
updatePlot(ax, lbl, iq_data, iq_data2, numSweeps, fs, T_sweep, BW, sampSize, sld.Value);

% 6. Assign the callback function to the slider
% Whenever the slider moves, it will trigger the updatePlot function
sld.ValueChangedFcn = @(src, event) updatePlot(ax, lbl, iq_data, iq_data2, numSweeps, fs, T_sweep, BW, sampSize, round(event.Value));

% --- Callback Function ---
% This function runs every time the slider is moved
function updatePlot(ax, lbl, iq_data, iq_data2, numSweeps, fs, T_sweep, BW, sampSize, currentSweep)
    
    % Update the label text
    lbl.Text = sprintf('Target Sweep: %d', currentSweep);
    
    % Calculate the new profiles
    [rangeAxis, rangePower] = plotRangeProfile(iq_data, numSweeps, fs, T_sweep, BW, sampSize, currentSweep);
    [rangeAxis_b, rangePower_b] = plotRangeProfile(iq_data2, numSweeps, fs, T_sweep, BW, sampSize, currentSweep);
    
    % Clear the current axes
    cla(ax);
    
    % Plot the new data
    plot(ax, rangeAxis, rangePower, 'g', 'LineWidth', 1.5);
    hold(ax, 'on');
    plot(ax, rangeAxis_b, rangePower_b, 'r', 'LineWidth', 1.5);
    hold(ax, 'off');
    
    % Reapply formatting
    xlabel(ax, 'Range (meters)');
    ylabel(ax, 'Power (dB)');
    title(ax, sprintf('Comparison of Range Profiles (Sweep %d)', currentSweep));
    lgd = legend(ax, 'Background Capture', 'Waving hand Capture');
    
    % Force the legend to match the dark theme d pin itsan location
    set(lgd, 'TextColor', 'w', ...          % White text
             'Color', 'k', ...              % Black background
             'EdgeColor', [0.5 0.5 0.5], ...% Gray border so it stands out
             'Location', 'northeast');      % Pin to the top right corner
end