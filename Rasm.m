%% Rasm.m
% مقایسه سه روش MPPT: 1 = P&O , 2 = ANN , 3 = SVM
clear; clc; close all;

% نام مدل سیمولینک
model = 'PV_ANN1';   % <-- اگر مدل‌ات اسم دیگه‌ای داره، اینجا عوضش کن

% برچسب روش‌ها برای نمودار و legend
methods = {'P&O','ANN','SVM'};

% رنگ‌ها: آبی، قرمز، سبز
colors = [
    0 0 1;    % P&O  → آبی
    1 0 0;    % ANN  → قرمز
    0 0.6 0;  % SVM  → سبز
];

% متغیرهای ذخیره نتایج
P_all  = cell(1,3);
t_all  = cell(1,3);
Pmax   = zeros(1,3);
tPmax  = zeros(1,3);

for i = 1:3
    % انتخاب روش MPPT (mode = 1,2,3)
    mppt_mode = i;
    assignin('base','mppt_mode', mppt_mode);   % به workspace مدل فرستاده می‌شود

    % اجرای شبیه‌سازی
    simOut = sim(model, 'ReturnWorkspaceOutputs','on');

    % خواندن خروجی توان از متغیر P (To Workspace)
    P_struct = simOut.P;   % چون variable name در To Workspace = P است

    % بررسی نوع داده و استخراج t و P
    if isstruct(P_struct) && isfield(P_struct,'signals')
        % حالت Structure With Time
        t = P_struct.time;
        P = P_struct.signals.values;

    elseif isa(P_struct,'timeseries')
        % حالت timeseries
        t = P_struct.Time;
        P = P_struct.Data;

    else
        % حالت Array → فرض می‌کنیم زمان همان tout است
        t = simOut.tout;
        P = P_struct;
    end

    % ذخیره برای رسم
    t_all{i} = t;
    P_all{i} = P;

    % پیدا کردن ماکزیمم توان و زمان آن
    [Pmax(i), idx] = max(P);
    tPmax(i) = t(idx);
end

%% رسم نمودار مقایسه‌ای
figure; hold on; grid on;

% رسم سه منحنی توان
for i = 1:3
    plot(t_all{i}, P_all{i}, 'LineWidth', 1.8, 'Color', colors(i,:));
end

% علامت زدن ماکزیمم توان هر روش
for i = 1:3
    plot(tPmax(i), Pmax(i), 'o', ...
        'Color', colors(i,:), ...
        'MarkerFaceColor', colors(i,:), ...
        'MarkerSize', 7);

    text(tPmax(i), Pmax(i), ...
        sprintf('  %s: %.1f W', methods{i}, Pmax(i)), ...
        'Color', colors(i,:), ...
        'FontSize', 10, ...
        'FontWeight','bold', ...
        'VerticalAlignment','bottom');
end

xlabel('Time (s)');
ylabel('P (W)');
title('Comparison of MPPT Methods (P&O / ANN / SVM)');
legend(methods, 'Location','best');
hold off;
