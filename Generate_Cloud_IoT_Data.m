%% Cloud–IoT Data Generator for Smart PV–MPPT Model
clc; clear; close all;

N = 301;                   % تعداد نمونه‌ها
Tsim = 5e-3;               % زمان شبیه‌سازی (ثانیه)
t = linspace(0, Tsim, N);

Delay_IoT   = 0.0005 + 0.0002 * rand(1, N);
Delay5G_Node = 0.001 + 0.0003 * rand(1, N);
SNR_Node    = 20 + 5 * randn(1, N);
Energy_IoT  = 0.05 + 0.01 * rand(1, N);
Energy5G_Node = 0.20 + 0.03 * rand(1, N);

cloud_delay_file = 'simulated_cloud_delays.npy';
if isfile(cloud_delay_file)
    DelayCloud = readNPY(cloud_delay_file);
    DelayCloud = resample(DelayCloud, N, numel(DelayCloud));
else
    DelayCloud = 0.001 + 0.0004 * rand(1, N);
end

EnergyCloud = Energy5G_Node .* (1 + 0.05 * rand(1, N));
Decision = double(SNR_Node > 15 & DelayCloud < 0.0015);

normalize = @(x) (x - min(x)) / (max(x) - min(x) + eps);
DelayCloud_norm = normalize(DelayCloud);
EnergyCloud_norm = normalize(EnergyCloud);
SNR_norm = normalize(SNR_Node);

IoT_5G_PV_Params = struct(... 
    'time', t, ...
    'Delay_IoT', Delay_IoT, ...
    'Delay5G_Node', Delay5G_Node, ...
    'SNR_Node', SNR_Node, ...
    'Energy_IoT', Energy_IoT, ...
    'Energy5G_Node', Energy5G_Node, ...
    'DelayCloud', DelayCloud, ...
    'EnergyCloud', EnergyCloud, ...
    'Decision', Decision, ...
    'DelayCloud_norm', DelayCloud_norm, ...
    'EnergyCloud_norm', EnergyCloud_norm, ...
    'SNR_norm', SNR_norm ...
);

save('Cloud_IoT_Data.mat', '-struct', 'IoT_5G_PV_Params');
disp('✅ فایل Cloud_IoT_Data.mat با موفقیت ساخته شد.');
