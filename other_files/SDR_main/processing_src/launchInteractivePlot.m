function launchInteractivePlot(iq_data, iq_data2, numSweeps, fs, T_sweep, BW, sampSize)
    % --- Create Interactive UI ---
    
    % 1. Create the main UI Figure
    fig = uifigure('Name', 'Interactive Range Profile', 'Position', [100, 100, 800, 600], 'Color', 'w');
    
    % 2. Create UI Axes for the plot
    ax = uiaxes(fig, 'Position', [50, 150, 700, 400]);
    
    % Apply dark theme to the UI axes
    set(ax, 'Color', 'k', ...
             'XColor', 'k', ...
             'YColor', 'k', ...
             'GridColor', [0.23 0.44 0.34], ...
             'GridLineStyle', '--');
    grid(ax, 'on');
    
    % 3. Create the Slider
    maxSweep = min(4000, numSweeps); 
    sld = uislider(fig, 'Position', [150, 70, 500, 3]);
    sld.Limits = [1, maxSweep];
    sld.Value = 1000; % Initial target sweep
    sld.MajorTicks = linspace(1, maxSweep, 10); 
    
    % 4. Add a Label for the Slider
    lbl = uilabel(fig, 'Position', [150, 90, 200, 22], 'Text', 'Target Sweep: 1000');
    
    % 5. Call the update function once to draw the initial graph
    updatePlot(ax, lbl, iq_data, iq_data2, numSweeps, fs, T_sweep, BW, sampSize, sld.Value);
    
    % 6. Assign the callback function to the slider
    sld.ValueChangedFcn = @(src, event) updatePlot(ax, lbl, iq_data, iq_data2, numSweeps, fs, T_sweep, BW, sampSize, round(event.Value));
end

% --- Callback Function ---
% Placed as a local function within the same file so it doesn't crowd your folder
function updatePlot(ax, lbl, iq_data, iq_data2, numSweeps, fs, T_sweep, BW, sampSize, currentSweep)
    
    % Update the label text
    lbl.Text = sprintf('Target Sweep: %d', currentSweep);
    
    % Calculate the new profiles
    [rangeAxis, rangePower] = plotRangeProfile(iq_data, numSweeps, fs, T_sweep, BW, sampSize*2, currentSweep);
    [rangeAxis_b, rangePower_b] = plotRangeProfile(iq_data2, numSweeps, fs, T_sweep, BW, sampSize*2, currentSweep);
    
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
    
    % Force the legend to match the dark theme and pin its location
    set(lgd, 'TextColor', 'k', ...          
             'Color', 'k', ...              
             'EdgeColor', [0.5 0.5 0.5], ...
             'Location', 'northeast');      
end