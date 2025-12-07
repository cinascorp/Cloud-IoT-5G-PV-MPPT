%% ============================================================
%   AI‑MPPT X9 – Switching‑Plot + SUPER‑DIAGNOSTIC (FINAL)
%   Compatible with ALL-ERRORLESS Architecture
%   Auto‑Adaptive: Plots only what is available.
% ============================================================

clear; clc;

%% ============================
% Load simulation results
% ============================
if exist('Simulation_Results.mat','file')
    load('Simulation_Results.mat');
else
    error('Simulation_Results.mat not found.');
end

%% ============================
% Safe extract helper
% ============================
extract_numeric = @(x) double( ...
    reshape( ...
        (isstruct(x) && isfield(x,'signals')) .* x.signals.values + ...
        (~isstruct(x)) .* x , [] , 1 ) );

%% ============================
% Extract time vector
% ============================
if exist('time','var')
    t = double(time(:));
elseif exist('tout','var')
    t = double(tout(:));
else
    error('Cannot find time vector (time / tout).');
end


%% ================
% Required signals
% ================
% Ppv
try   Ppv = extract_numeric(Ppv);
catch error('Signal "Ppv" missing.');
end

% Mode
try   mode = extract_numeric(mode_select);
catch error('Signal "mode_select" missing.');
end

%% ============================
% Interpolate if lengths mismatch
% ============================
if length(Ppv) ~= length(t)
    Ppv = interp1(linspace(0,1,length(Ppv)), Ppv, linspace(0,1,length(t)));
end
if length(mode) ~= length(t)
    mode = interp1(linspace(0,1,length(mode)), mode, linspace(0,1,length(t)),'nearest');
end


%% ============================================================
%               PART A — Switching Plot Enhanced
% ============================================================

dmode = [0; diff(mode)];
idx_sw = find(dmode ~= 0);

transition_times = t(idx_sw);
transition_from = mode(idx_sw - 1);
transition_to   = mode(idx_sw);

fprintf('\n=====================================\n');
fprintf('     MPPT Switching Events\n');
fprintf('=====================================\n');

if isempty(idx_sw)
    fprintf('No transitions detected.\n');
else
    for k = 1:length(idx_sw)
        fprintf('#%d: t = %.4f s | %d → %d\n', ...
            k, transition_times(k), transition_from(k), transition_to(k));
    end
end

fprintf('Total Transitions = %d\n', length(idx_sw));
fprintf('=====================================\n\n');


%% ======== Plot 1: Power + Transition Marks ========
figure('Name','Switching‑Plot Enhanced');
subplot(2,1,1);
plot(t, Ppv,'LineWidth',1.6); hold on;

% Mark transitions
for k = 1:length(idx_sw)
    plot(t(idx_sw(k)), Ppv(idx_sw(k)), 'ro','MarkerSize',8,'LineWidth',2);
end

ylabel('Power (W)');
title('PV Output Power (with switch markers)');
grid on;

%% ======== Plot 2: Mode steps ========
subplot(2,1,2);
stairs(t, mode,'LineWidth',1.6);
grid on;
ylim([0.5 3.5]);
yticks([1 2 3]);
yticklabels({'ANN','SVM','P&O'});
xlabel('Time (s)');
ylabel('Mode');
title('MPPT Mode Switching');

hold on;
u = unique(mode);
for k = 1:length(u)
    mk = (mode == u(k));
    if any(mk)
        area(t, mk*3.5, 'FaceAlpha',0.05,'LineStyle','none');
    end
end

%% ============================================================
%               PART B — SUPER‑DIAGNOSTIC MODULE
% ============================================================

fprintf('\n=====================================\n');
fprintf('         SUPER‑DIAGNOSTIC\n');
fprintf('=====================================\n');


%% ================
% 1) Duty Cycle
% ================
if exist('Duty','var')
    Duty_cycle = extract_numeric(Duty);
    if length(Duty_cycle) ~= length(t)
        Duty_cycle = interp1(linspace(0,1,length(Duty_cycle)), ...
                             Duty_cycle, linspace(0,1,length(t)));
    end

    figure('Name','Duty Cycle Diagnostic');
    subplot(2,1,1);
    plot(t, Duty_cycle, 'LineWidth', 1.4);
    ylabel('Duty');
    title('Duty Cycle Evolution');
    grid on;

    subplot(2,1,2);
    stairs(t, mode,'LineWidth',1.2);
    ylim([0.5 3.5]); yticks([1 2 3]);
    yticklabels({'ANN','SVM','P&O'});
    title('Duty Cycle vs Mode'); grid on;

    fprintf('• Duty Cycle plotted.\n');
else
    fprintf('• Duty Cycle not found → skipping.\n');
end


%% ======================
% 2) Cost Function J
% ======================
if exist('J','var')
    Jc = extract_numeric(J);
    if length(Jc) ~= length(t)
        Jc = interp1(linspace(0,1,length(Jc)), Jc, linspace(0,1,length(t)));
    end

    figure('Name','Cost Function Diagnostic');
    subplot(2,1,1);
    plot(t, Jc,'LineWidth',1.3);
    title('Cost Function J(t)'); grid on;

    subplot(2,1,2);
    plot(t, Ppv,'b'); hold on;
    plot(t, Jc/max(Jc)*max(Ppv)*0.4,'r');
    legend('Ppv','scaled J'); grid on;
    title('Ppv with Scaled J Overlay');

    fprintf('• Cost function plotted.\n');
else
    fprintf('• J not found → skipping.\n');
end


%% ======================
% 3) Irradiance / Temp
% ======================
if exist('Irr','var')
    Irr2 = extract_numeric(Irr);
    Irr2 = interp1(linspace(0,1,length(Irr2)), Irr2, linspace(0,1,length(t)));

    figure('Name','Environmental Diagnostics');
    subplot(2,1,1);
    plot(t, Irr2,'LineWidth',1.2);
    ylabel('Irr'); title('Irradiance'); grid on;

    fprintf('• Irradiance plotted.\n');
end

if exist('Temp','var')
    Temp2 = extract_numeric(Temp);
    Temp2 = interp1(linspace(0,1,length(Temp2)), Temp2, linspace(0,1,length(t)));

    subplot(2,1,2);
    plot(t, Temp2,'LineWidth',1.2);
    ylabel('Temp'); title('Temperature'); grid on;

    fprintf('• Temperature plotted.\n');
end


%% ======================
% 4) 3D Mode–Cost–Power
% ======================
if exist('J','var')
    figure('Name','3D Mode–Cost–Power Diagnostic');
    scatter3(mode, Jc, Ppv, 15, t, 'filled');
    xlabel('Mode'); ylabel('J'); zlabel('Ppv');
    title('3D Diagnostic: Mode–Cost–Power');
    grid on;
    fprintf('• 3D scatter plotted.\n');
else
    fprintf('• J missing → skipping 3D diagnostic.\n');
end


fprintf('\n=====================================\n');
fprintf(' SUPER‑DIAGNOSTIC Completed\n');
fprintf('=====================================\n');
