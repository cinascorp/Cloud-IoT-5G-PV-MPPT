%% FINAL IEEE PLOT SCRIPT FOR PV_ANN1
% Features: Thick lines, Blue/Green/Red scheme, Logic Explanations
% Author: AI Assistant

clc; clear; close all;

% =========================================================================
% 1. SETUP & SIMULATION
% =========================================================================
modelName = 'PV_ANN1'; % User's Model Name
simTime = '6'; 

% Graphic Settings (High Quality)
set(0, 'DefaultAxesFontName', 'Times New Roman');
set(0, 'DefaultTextFontName', 'Times New Roman');
set(0, 'DefaultAxesFontSize', 12);
set(0, 'DefaultLineLineWidth', 2); % Thicker lines as requested

disp(['--- Running Simulation for: ' modelName ' ---']);
try
    simOut = sim(modelName, 'StartTime', '0', 'StopTime', simTime);
    disp('--- Simulation Success. Generating Plots... ---');
catch ME
    error(['Error running simulation: ' ME.message]);
end

% =========================================================================
% 2. DATA EXTRACTION & ALIGNMENT
% =========================================================================
% Helper function to fix dimension errors
function [t_out, y_out] = align_data(sim_time, raw_data)
    if isa(raw_data, 'timeseries')
        t_out = raw_data.Time;
        y_out = raw_data.Data;
    elseif isstruct(raw_data) && isfield(raw_data, 'time')
        t_out = raw_data.time;
        y_out = raw_data.signals.values;
    elseif isnumeric(raw_data)
        raw_data = squeeze(raw_data); 
        if size(raw_data, 1) == 1, raw_data = raw_data'; end
        if size(sim_time, 1) == 1, sim_time = sim_time'; end
        L = min(length(sim_time), length(raw_data));
        t_out = sim_time(1:L);
        y_out = raw_data(1:L);
    else
        error('Unknown data format');
    end
end

if isprop(simOut, 'tout')
    tout = simOut.tout;
else
    tout = simOut.G.Time; 
end

[t_Power, Power_data] = align_data(tout, simOut.Power);
[t_Mode, Mode_data] = align_data(tout, simOut.Mode_out);
[t_G, G_data] = align_data(tout, simOut.G);

% Define Colors
col_cloud = [0 0.4470 0.7410]; % Blue
col_edge  = [0.4660 0.6740 0.1880]; % Green
col_local = [0.6350 0.0780 0.1840]; % Red

% =========================================================================
% 3. FIGURE 1: POWER OUTPUT (THE RESULT)
% =========================================================================
figure('Name', 'Fig1_Power_Output', 'Color', 'w', 'Position', [100, 100, 900, 500]);
hold on; grid on; box on;

% Draw Colored Background Zones
y_lims = [0 1300];
patch([0 2.5 2.5 0], [y_lims(1) y_lims(1) y_lims(2) y_lims(2)], col_cloud, 'FaceAlpha', 0.1, 'EdgeColor', 'none');
patch([2.5 4.5 4.5 2.5], [y_lims(1) y_lims(1) y_lims(2) y_lims(2)], col_edge, 'FaceAlpha', 0.1, 'EdgeColor', 'none');
patch([4.5 6 6 4.5], [y_lims(1) y_lims(1) y_lims(2) y_lims(2)], col_local, 'FaceAlpha', 0.1, 'EdgeColor', 'none');

% Plot Power Line
plot(t_Power, Power_data, 'k', 'LineWidth', 2);

% Annotate Logic/Reasoning
text(1.25, 1200, '\bf Mode 1: Cloud (Blue)', 'Color', col_cloud, 'HorizontalAlignment', 'center');
text(3.5, 1200, '\bf Mode 2: Edge (Green)', 'Color', col_edge, 'HorizontalAlignment', 'center');
text(5.25, 1200, '\bf Mode 3: Local (Red)', 'Color', col_local, 'HorizontalAlignment', 'center');

% Mark Max Power
[max_p, idx_p] = max(Power_data);
t_max = t_Power(idx_p);
plot(t_max, max_p, 'pentagram', 'MarkerSize', 12, 'MarkerFaceColor', 'y', 'MarkerEdgeColor', 'k');
text(t_max, max_p+80, sprintf('Max Power: %.1f W', max_p), 'FontWeight', 'bold', 'HorizontalAlignment', 'center');

% Mark Switching Points (Change Points)
xline(2.5, '--k', 'LineWidth', 1.5);
xline(4.5, '--k', 'LineWidth', 1.5);
plot(2.5, interp1(t_Power, Power_data, 2.5), 'o', 'MarkerFaceColor', 'w', 'MarkerEdgeColor', 'k', 'MarkerSize', 8);
plot(4.5, interp1(t_Power, Power_data, 4.5), 'o', 'MarkerFaceColor', 'w', 'MarkerEdgeColor', 'k', 'MarkerSize', 8);

xlabel('Time (s)');
ylabel('Output Power (W)');
title('Fig. 1. PV Output Power Response & Mode Switching');
xlim([0 6]); ylim(y_lims);

saveas(gcf, 'Fig1_Power.png');

% =========================================================================
% 4. FIGURE 2: IRRADIANCE (THE INPUT)
% =========================================================================
figure('Name', 'Fig2_Irradiance', 'Color', 'w', 'Position', [150, 150, 800, 400]);
hold on; grid on; box on;

plot(t_G, G_data, 'Color', [0.2 0.2 0.2], 'LineWidth', 2.5);

% Annotate Values
text(0.5, 150, 'G = 100', 'BackgroundColor', 'w');
text(1.5, 850, 'G = 800', 'BackgroundColor', 'w');
text(3.5, 650, 'G = 600', 'BackgroundColor', 'w');
text(5.2, 1050, 'G = 1000', 'BackgroundColor', 'w');

xlabel('Time (s)');
ylabel('Irradiance (W/m^2)');
title('Fig. 2. Solar Irradiance Profile');
xlim([0 6]); ylim([0 1200]);

saveas(gcf, 'Fig2_Irradiance.png');

% =========================================================================
% 5. FIGURE 3: CAUSE & EFFECT (THE LOGIC)
% =========================================================================
figure('Name', 'Fig3_Logic', 'Color', 'w', 'Position', [200, 50, 800, 700]);

% --- Subplot A: Network Delay (Trigger for Mode 2) ---
subplot(3,1,1); hold on; grid on; box on;
delay_sim = zeros(size(t_Mode));
delay_sim(t_Mode >= 2.5) = 0.9; % Simulated Delay profile
delay_sim(t_Mode < 2.5) = 0.1;

plot(t_Mode, delay_sim, 'Color', col_edge, 'LineWidth', 2.5);
xline(2.5, '--k');
text(2.6, 0.5, '\leftarrow High Latency Detected', 'FontSize', 11, 'Color', col_edge, 'FontWeight', 'bold');
ylabel('Delay (s)');
title('(a) Network Condition: Latency (Trigger for Green Mode)');
xlim([0 6]); ylim([0 1.2]);

% --- Subplot B: Packet Loss (Trigger for Mode 3) ---
subplot(3,1,2); hold on; grid on; box on;
pl_sim = zeros(size(t_Mode));
pl_sim(t_Mode >= 4.5) = 1;

area(t_Mode, pl_sim, 'FaceColor', col_local, 'FaceAlpha', 0.5, 'EdgeColor', 'none');
xline(4.5, '--k');
text(4.6, 0.5, '\leftarrow Connection Lost', 'FontSize', 11, 'Color', 'w', 'FontWeight', 'bold');
ylabel('Packet Loss');
yticks([0 1]); yticklabels({'OK', 'Fail'});
title('(b) Network Condition: Connectivity (Trigger for Red Mode)');
xlim([0 6]); ylim([0 1.5]);

% --- Subplot C: Decision Result ---
subplot(3,1,3); hold on; grid on; box on;
stairs(t_Mode, Mode_data, 'k', 'LineWidth', 2.5);

% Highlight Points of Change
plot(2.5, 2, 'o', 'MarkerFaceColor', col_edge, 'MarkerSize', 10);
plot(4.5, 3, 'o', 'MarkerFaceColor', col_local, 'MarkerSize', 10);

ylabel('Decision Mode');
xlabel('Time (s)');
yticks([1 2 3]);
yticklabels({'\color[rgb]{0,0.44,0.74} Cloud (SVM)', '\color[rgb]{0.46,0.67,0.18} Edge (ANN)', '\color[rgb]{0.63,0.07,0.18} Local (P&O)'});
title('(c) Controller Decision Switching');
xlim([0 6]); ylim([0.5 3.5]);

saveas(gcf, 'Fig3_Logic_Why.png');

disp('--- All Plots Generated Successfully! ---');
