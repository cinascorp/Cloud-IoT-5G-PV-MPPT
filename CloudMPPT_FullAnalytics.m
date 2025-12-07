%% CloudMPPT_FullAnalytics.m
% Full analytics suite for Cloud-based MPPT + IoT/5G system
% Runs multiple test scenarios, collects data, generates plots and
% comparison tables, and exports results to Excel/MAT files.
%
% Author: [Your Name]
% Date  : [YYYY-MM-DD]

clear; clc; close all;

%% 1) Model and test configuration
modelName = 'PV_ANN1';

% TestID mapping:
% 0 = Baseline (no injected fault)
% 1 = MPPT fault
% 2 = Communication fault
% 3 = Global/system-level fault
testIDs  = [0 1 2 3];
testDesc = { ...
    'Baseline (No Fault)', ...
    'MPPT Fault', ...
    'Communication Fault', ...
    'Global Fault'};

simStopTime = '3';   % change if your model StopTime is different

%% 2) Load model if needed
if ~bdIsLoaded(modelName)
    load_system(modelName);
end

%% 3) Run simulations for all test scenarios
numTests = numel(testIDs);
results  = struct([]);

for k = 1:numTests
    TestID = testIDs(k);
    fprintf('\n==============================\n');
    fprintf('Running TestID = %d : %s\n', TestID, testDesc{k});
    fprintf('==============================\n');
    
    % Provide TestID to Simulink TestScenario via base workspace
    assignin('base','TestID',TestID);
    
    % Run simulation and collect To Workspace outputs in simOut
    simOut = sim(modelName, ...
        'StopTime',              simStopTime, ...
        'ReturnWorkspaceOutputs','on');
    
    % Extract timeseries signals from simOut
    EffIdx_ts    = simOut.EffIdx;      % Efficiency index
    QoSIdx_ts    = simOut.QoSIdx;      % Communication QoS index
    FaultCode_ts = simOut.FaultCode;   % Fault code (0..3)
    Anomaly_ts   = simOut.Anomaly;     % Anomaly score
    
    % Convert to vectors for convenience
    t   = EffIdx_ts.Time;
    dt  = mean(diff(t));
    Eff = EffIdx_ts.Data;
    QoS = QoSIdx_ts.Data;
    FC  = FaultCode_ts.Data;
    Ano = Anomaly_ts.Data;
    
    % Basic averages and min/max
    Eff_mean  = mean(Eff);
    Eff_min   = min(Eff);
    Eff_max   = max(Eff);
    
    QoS_mean  = mean(QoS);
    QoS_min   = min(QoS);
    QoS_max   = max(QoS);
    
    Ano_mean  = mean(Ano);
    Ano_min   = min(Ano);
    Ano_max   = max(Ano);
    
    % Fault time percentages
    totalTime = t(end) - t(1);
    if totalTime <= 0
        totalTime = dt * numel(t);
    end
    
    timeNo   = sum(FC == 0) * dt;
    timeMPPT = sum(FC == 1) * dt;
    timeCOMM = sum(FC == 2) * dt;
    timeGlob = sum(FC == 3) * dt;
    
    pctNo   = 100 * timeNo   / totalTime;
    pctMPPT = 100 * timeMPPT / totalTime;
    pctCOMM = 100 * timeCOMM / totalTime;
    pctGlob = 100 * timeGlob / totalTime;
    
    % Store everything in results struct
    results(k).TestID       = TestID;
    results(k).Description  = testDesc{k};
    results(k).Time         = t;
    results(k).Eff          = Eff;
    results(k).QoS          = QoS;
    results(k).FaultCode    = FC;
    results(k).Anomaly      = Ano;
    
    results(k).Eff_mean     = Eff_mean;
    results(k).Eff_min      = Eff_min;
    results(k).Eff_max      = Eff_max;
    results(k).QoS_mean     = QoS_mean;
    results(k).QoS_min      = QoS_min;
    results(k).QoS_max      = QoS_max;
    results(k).Anom_mean    = Ano_mean;
    results(k).Anom_min     = Ano_min;
    results(k).Anom_max     = Ano_max;
    
    results(k).Pct_NoFault  = pctNo;
    results(k).Pct_MPPT     = pctMPPT;
    results(k).Pct_COMM     = pctCOMM;
    results(k).Pct_GLOBAL   = pctGlob;
end

fprintf('\n*** All tests completed. ***\n');

%% 4) Time-series comparison figure (4x4 grid)
figure('Name','Cloud MPPT - Time Series Overview','NumberTitle','off');
for k = 1:numTests
    t   = results(k).Time;
    Eff = results(k).Eff;
    QoS = results(k).QoS;
    FC  = results(k).FaultCode;
    Ano = results(k).Anomaly;
    TID = results(k).TestID;
    
    % Row 1: Efficiency
    subplot(4, numTests, k);
    plot(t, Eff); grid on;
    title(sprintf('Eff, Test %d', TID));
    if k == 1
        ylabel('Efficiency');
    end
    
    % Row 2: QoS
    subplot(4, numTests, k + numTests);
    plot(t, QoS); grid on;
    title(sprintf('QoS, Test %d', TID));
    if k == 1
        ylabel('Comm QoS');
    end
    
    % Row 3: FaultCode
    subplot(4, numTests, k + 2*numTests);
    stairs(t, FC); grid on;
    ylim([-0.2 3.2]);
    yticks(0:3);
    title(sprintf('FaultCode, Test %d', TID));
    if k == 1
        ylabel('Fault Code');
    end
    
    % Row 4: Anomaly
    subplot(4, numTests, k + 3*numTests);
    plot(t, Ano); grid on;
    title(sprintf('Anomaly, Test %d', TID));
    if k == 1
        ylabel('Anomaly');
    end
    xlabel('Time (s)');
end

%% 5) Build comparison table (numeric summary)
TestID_col   = zeros(numTests,1);
EffMean_col  = zeros(numTests,1);
EffMin_col   = zeros(numTests,1);
EffMax_col   = zeros(numTests,1);
QoSMean_col  = zeros(numTests,1);
QoSMin_col   = zeros(numTests,1);
QoSMax_col   = zeros(numTests,1);
AnomMean_col = zeros(numTests,1);
AnomMin_col  = zeros(numTests,1);
AnomMax_col  = zeros(numTests,1);
PctNo_col    = zeros(numTests,1);
PctMPPT_col  = zeros(numTests,1);
PctCOMM_col  = zeros(numTests,1);
PctGlob_col  = zeros(numTests,1);

for k = 1:numTests
    TestID_col(k)   = results(k).TestID;
    EffMean_col(k)  = results(k).Eff_mean;
    EffMin_col(k)   = results(k).Eff_min;
    EffMax_col(k)   = results(k).Eff_max;
    QoSMean_col(k)  = results(k).QoS_mean;
    QoSMin_col(k)   = results(k).QoS_min;
    QoSMax_col(k)   = results(k).QoS_max;
    AnomMean_col(k) = results(k).Anom_mean;
    AnomMin_col(k)  = results(k).Anom_min;
    AnomMax_col(k)  = results(k).Anom_max;
    PctNo_col(k)    = results(k).Pct_NoFault;
    PctMPPT_col(k)  = results(k).Pct_MPPT;
    PctCOMM_col(k)  = results(k).Pct_COMM;
    PctGlob_col(k)  = results(k).Pct_GLOBAL;
end

CloudMPPT_Report = table( ...
    TestID_col, ...
    EffMean_col, EffMin_col, EffMax_col, ...
    QoSMean_col, QoSMin_col, QoSMax_col, ...
    AnomMean_col, AnomMin_col, AnomMax_col, ...
    PctNo_col, PctMPPT_col, PctCOMM_col, PctGlob_col, ...
    'VariableNames', { ...
        'TestID', ...
        'Eff_Mean','Eff_Min','Eff_Max', ...
        'QoS_Mean','QoS_Min','QoS_Max', ...
        'Anom_Mean','Anom_Min','Anom_Max', ...
        'Pct_NoFault','Pct_MPPT','Pct_COMM','Pct_GLOBAL'});

disp('=== Cloud MPPT Summary Table ===');
disp(CloudMPPT_Report);

%% 6) Export table to Excel and MAT
excelFileName = 'CloudMPPT_SummaryReport.xlsx';
matFileName   = 'CloudMPPT_SummaryReport.mat';

writetable(CloudMPPT_Report, excelFileName);
save(matFileName, 'CloudMPPT_Report', 'results');

fprintf('\nSummary table exported to:\n  %s\n  %s\n', excelFileName, matFileName);

%% 7) Bar charts for publication-quality figures

% 7.1 Mean efficiency, QoS, anomaly
figure('Name','Cloud MPPT - Mean Indices','NumberTitle','off');

subplot(3,1,1);
bar(TestID_col, EffMean_col);
grid on;
xlabel('Test ID');
ylabel('Mean Efficiency');
title('Mean Efficiency per Test');

subplot(3,1,2);
bar(TestID_col, QoSMean_col);
grid on;
xlabel('Test ID');
ylabel('Mean Comm QoS');
title('Mean Communication QoS per Test');

subplot(3,1,3);
bar(TestID_col, AnomMean_col);
grid on;
xlabel('Test ID');
ylabel('Mean Anomaly Score');
title('Mean Anomaly Score per Test');

% 7.2 Stacked bar of fault time percentages
figure('Name','Cloud MPPT - Fault Time Distribution','NumberTitle','off');

faultPctMatrix = [PctNo_col, PctMPPT_col, PctCOMM_col, PctGlob_col];

bar(TestID_col, faultPctMatrix, 'stacked');
grid on;
xlabel('Test ID');
ylabel('Time Percentage [%]');
legend({'No Fault','MPPT Fault','COMM Fault','Global Fault'}, 'Location','bestoutside');
title('Fault Time Distribution per Test');
