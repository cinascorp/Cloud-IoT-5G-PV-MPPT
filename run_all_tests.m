%% run_all_tests.m
% اجرای خودکار سناریوهای تست برای مدل PV_ANN1

clear; clc;

modelName = 'PV_ANN1';

% اگر مدل باز نیست، بازش کن
if ~bdIsLoaded(modelName)
    load_system(modelName);
end

% لیست تست‌ها:
% 0 = بدون خطا (baseline)
% 1 = خطای MPPT
% 2 = خطای شبکه (Communication)
% 3 = خرابی کلی (Global fault)
testIDs = [0 1 2 3];

% ساخت آرایه ساختاری برای ذخیره نتایج
results = struct([]);

for k = 1:numel(testIDs)
    TestID = testIDs(k);
    fprintf('Running test ID = %d ...\n', TestID);
    
    % مقدار TestID را در Workspace پایه قرار می‌دهیم
    % تا بلوک Constant مربوط به TestScenario از آن استفاده کند.
    assignin('base','TestID',TestID);
    
    % شبیه‌سازی:
    % حتماً ReturnWorkspaceOutputs را 'on' بگذار تا خروجی‌های To Workspace
    % به صورت field داخل simOut برگردند.
    simOut = sim(modelName, ...
        'StopTime', '3', ...                  % StopTime را در صورت نیاز عوض کن
        'ReturnWorkspaceOutputs', 'on');       % مهم برای گرفتن EffIdx, QoSIdx, ...
    
    % خواندن خروجی‌ها از simOut
    % توجه: این نام‌ها باید با Variable name در بلوک‌های To Workspace یکی باشند.
    EffIdx    = simOut.EffIdx;      % timeseries
    QoSIdx    = simOut.QoSIdx;      % timeseries
    FaultCode = simOut.FaultCode;   % timeseries
    Anomaly   = simOut.Anomaly;     % timeseries
    
    % ذخیره در ساختار نتایج
    results(k).TestID    = TestID;
    results(k).EffIdx    = EffIdx;
    results(k).QoSIdx    = QoSIdx;
    results(k).FaultCode = FaultCode;
    results(k).Anomaly   = Anomaly;
end

fprintf('تمام تست‌ها اجرا شدند.\n');

%% رسم مقایسه‌ای نتایج برای هر تست
figure;
numTests = numel(testIDs);

for k = 1:numTests
    TID  = results(k).TestID;
    Eff  = results(k).EffIdx;      % timeseries
    QoS  = results(k).QoSIdx;      % timeseries
    FC   = results(k).FaultCode;   % timeseries
    Ano  = results(k).Anomaly;     % timeseries
    
    % چون خروجی‌ها timeseries هستند، از Time و Data استفاده می‌کنیم
    t1    = Eff.Time;
    yEff  = Eff.Data;
    yQoS  = QoS.Data;
    yCode = FC.Data;
    yAnom = Ano.Data;
    
    % ردیف 1: Efficiency
    subplot(4, numTests, k);
    plot(t1, yEff); grid on;
    title(sprintf('Eff, Test %d', TID));
    if k == 1
        ylabel('Efficiency');
    end
    
    % ردیف 2: QoS
    subplot(4, numTests, k + numTests);
    plot(t1, yQoS); grid on;
    title(sprintf('QoS, Test %d', TID));
    if k == 1
        ylabel('Comm QoS');
    end
    
    % ردیف 3: Fault Code
    subplot(4, numTests, k + 2*numTests);
    stairs(t1, yCode); grid on;
    title(sprintf('FaultCode, Test %d', TID));
    if k == 1
        ylabel('Fault Code');
    end
    
    % ردیف 4: Anomaly Score
    subplot(4, numTests, k + 3*numTests);
    plot(t1, yAnom); grid on;
    title(sprintf('Anomaly, Test %d', TID));
    if k == 1
        ylabel('Anomaly');
    end
    xlabel('Time (s)');
end
