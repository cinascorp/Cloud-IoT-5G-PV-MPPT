%% تست عملکرد Power Control برای سه نود
clc; clearvars -except tout ...
    SNR_Node1 SNR_Node2 SNR_Node3 ...
    TxP_Node1 TxP_Node2 TxP_Node3;

%% هم‌طول کردن سیگنال‌ها
L = [
    numel(tout) ...
    numel(SNR_Node1) numel(SNR_Node2) numel(SNR_Node3) ...
    numel(TxP_Node1) numel(TxP_Node2) numel(TxP_Node3) ...
    ];

N = min(L);
t         = tout(1:N);
SNR_Node1 = SNR_Node1(1:N);
SNR_Node2 = SNR_Node2(1:N);
SNR_Node3 = SNR_Node3(1:N);
TxP_Node1 = TxP_Node1(1:N);
TxP_Node2 = TxP_Node2(1:N);
TxP_Node3 = TxP_Node3(1:N);

idx_steady = floor(N/2):N;

%% میانگین SNR بعد از پایدار شدن
mSNR1 = mean(SNR_Node1(idx_steady));
mSNR2 = mean(SNR_Node2(idx_steady));
mSNR3 = mean(SNR_Node3(idx_steady));

fprintf('--- میانگین SNR بعد از کنترل توان ---\n');
fprintf('Node1: %.2f dB\n', mSNR1);
fprintf('Node2: %.2f dB\n', mSNR2);
fprintf('Node3: %.2f dB\n', mSNR3);

%% رسم SNR در زمان
figure;
plot(t, SNR_Node1, t, SNR_Node2, t, SNR_Node3, 'LineWidth', 1.2);
grid on;
xlabel('Time (s)');
ylabel('SNR (dB)');
legend('Node1','Node2','Node3','Location','best');
title('SNR سه نود با کنترل توان');

%% رسم توان ارسال در زمان
figure;
plot(t, TxP_Node1, t, TxP_Node2, t, TxP_Node3, 'LineWidth', 1.2);
grid on;
xlabel('Time (s)');
ylabel('Tx Power (dBm)');
legend('Node1','Node2','Node3','Location','best');
title('توان ارسال سه نود IoT (Power Control)');
