%% تست بلوک 5G برای سه نود IoT
% قبل از اجرای این فایل، مدل Simulink را ران کن تا متغیرها در Workspace باشند.

clc; clearvars -except tout ...
    SNR_Node1 SNR_Node2 SNR_Node3 ...
    Thr_Node1 Thr_Node2 Thr_Node3 ...
    Delay5G_Node1 Delay5G_Node2 Delay5G_Node3 ...
    PL_Node1 PL_Node2 PL_Node3 ...
    E5G_Node1 E5G_Node2 E5G_Node3;

%% 0) هم‌طول کردن سیگنال‌ها

% طول هر سیگنال
L = [
    numel(tout) ...
    numel(SNR_Node1) numel(SNR_Node2) numel(SNR_Node3) ...
    numel(Thr_Node1) numel(Thr_Node2) numel(Thr_Node3) ...
    numel(Delay5G_Node1) numel(Delay5G_Node2) numel(Delay5G_Node3) ...
    numel(PL_Node1) numel(PL_Node2) numel(PL_Node3) ...
    numel(E5G_Node1) numel(E5G_Node2) numel(E5G_Node3) ...
    ];

N = min(L);           % کمترین طول مشترک

% برش دادن همه سیگنال‌ها به طول N
t           = tout(1:N);
SNR_Node1   = SNR_Node1(1:N);
SNR_Node2   = SNR_Node2(1:N);
SNR_Node3   = SNR_Node3(1:N);
Thr_Node1   = Thr_Node1(1:N);
Thr_Node2   = Thr_Node2(1:N);
Thr_Node3   = Thr_Node3(1:N);
Delay5G_Node1 = Delay5G_Node1(1:N);
Delay5G_Node2 = Delay5G_Node2(1:N);
Delay5G_Node3 = Delay5G_Node3(1:N);
PL_Node1    = PL_Node1(1:N);
PL_Node2    = PL_Node2(1:N);
PL_Node3    = PL_Node3(1:N);
E5G_Node1   = E5G_Node1(1:N);
E5G_Node2   = E5G_Node2(1:N);
E5G_Node3   = E5G_Node3(1:N);

% ناحیه پایدار: نیمه دوم شبیه‌سازی
idx_steady = floor(N/2):N;

%% 1) تست SNR

mSNR1 = mean(SNR_Node1(idx_steady));
mSNR2 = mean(SNR_Node2(idx_steady));
mSNR3 = mean(SNR_Node3(idx_steady));

fprintf('--- تست SNR ---\n');
fprintf('میانگین SNR Node1 = %.2f dB\n', mSNR1);
fprintf('میانگین SNR Node2 = %.2f dB\n', mSNR2);
fprintf('میانگین SNR Node3 = %.2f dB\n', mSNR3);

if (mSNR1 > mSNR2) && (mSNR2 > mSNR3)
    fprintf('✅ ترتیب SNR منطقی است (Node1 > Node2 > Node3)\n\n');
else
    fprintf('⚠️  ترتیب SNR غیرمنتظره است.\n\n');
end

%% 2) تست Throughput

mThr1 = mean(Thr_Node1(idx_steady));
mThr2 = mean(Thr_Node2(idx_steady));
mThr3 = mean(Thr_Node3(idx_steady));

fprintf('--- تست Throughput ---\n');
fprintf('میانگین Thr Node1 = %.2f Mbps\n', mThr1/1e6);
fprintf('میانگین Thr Node2 = %.2f Mbps\n', mThr2/1e6);
fprintf('میانگین Thr Node3 = %.2f Mbps\n', mThr3/1e6);

if (mThr1 > mThr2) && (mThr2 > mThr3)
    fprintf('✅ ترتیب Throughput منطقی است (Node1 > Node2 > Node3)\n\n');
else
    fprintf('⚠️  ترتیب Throughput غیرمنتظره است.\n\n');
end

%% 3) تست Delay_5G

mDel1 = mean(Delay5G_Node1(idx_steady));
mDel2 = mean(Delay5G_Node2(idx_steady));
mDel3 = mean(Delay5G_Node3(idx_steady));

fprintf('--- تست Delay_5G ---\n');
fprintf('میانگین Delay Node1 = %.3f ms\n', 1e3*mDel1);
fprintf('میانگین Delay Node2 = %.3f ms\n', 1e3*mDel2);
fprintf('میانگین Delay Node3 = %.3f ms\n', 1e3*mDel3);

if (mDel1 < mDel2) && (mDel2 < mDel3)
    fprintf('✅ ترتیب Delay منطقی است (Node1 < Node2 < Node3)\n\n');
else
    fprintf('⚠️  ترتیب Delay غیرمنتظره است.\n\n');
end

%% 4) تست Packet Loss Rate

PLR1 = mean(PL_Node1(idx_steady));
PLR2 = mean(PL_Node2(idx_steady));
PLR3 = mean(PL_Node3(idx_steady));

fprintf('--- تست Packet Loss Rate ---\n');
fprintf('PLR Node1 ≈ %.3f\n', PLR1);
fprintf('PLR Node2 ≈ %.3f\n', PLR2);
fprintf('PLR Node3 ≈ %.3f\n', PLR3);

if (PLR1 < PLR2) && (PLR2 < PLR3)
    fprintf('✅ رفتار Packet Loss با SNR سازگار است\n\n');
else
    fprintf('⚠️  رفتار Packet Loss غیرمنتظره است.\n\n');
end

%% 5) تست انرژی مصرفی 5G

E_total1 = sum(E5G_Node1(idx_steady));
E_total2 = sum(E5G_Node2(idx_steady));
E_total3 = sum(E5G_Node3(idx_steady));

fprintf('--- تست Energy_5G ---\n');
fprintf('Energy مجموع Node1 ≈ %.3f mJ\n', 1e3*E_total1);
fprintf('Energy مجموع Node2 ≈ %.3f mJ\n', 1e3*E_total2);
fprintf('Energy مجموع Node3 ≈ %.3f mJ\n', 1e3*E_total3);

if (E_total1 < E_total2) && (E_total2 < E_total3)
    fprintf('✅ انرژی نود نزدیک کمتر و نود دور بیشتر است\n\n');
else
    fprintf('⚠️  ترتیب انرژی غیرمنتظره است.\n\n');
end

%% 6) رسم نمودارها

figure;
plot(t, SNR_Node1, t, SNR_Node2, t, SNR_Node3, 'LineWidth', 1.2);
grid on; xlabel('Time (s)'); ylabel('SNR (dB)');
legend('Node1','Node2','Node3','Location','best');
title('SNR سه نود IoT روی لینک 5G');

figure;
plot(t, Thr_Node1/1e6, t, Thr_Node2/1e6, t, Thr_Node3/1e6, 'LineWidth', 1.2);
grid on; xlabel('Time (s)'); ylabel('Throughput (Mbps)');
legend('Node1','Node2','Node3','Location','best');
title('Throughput سه نود IoT روی لینک 5G');

figure;
plot(t, 1e3*Delay5G_Node1, t, 1e3*Delay5G_Node2, t, 1e3*Delay5G_Node3, 'LineWidth', 1.2);
grid on; xlabel('Time (s)'); ylabel('Delay 5G (ms)');
legend('Node1','Node2','Node3','Location','best');
title('Delay 5G سه نود IoT');

figure;
plot(t, 1e3*E5G_Node1, t, 1e3*E5G_Node2, t, 1e3*E5G_Node3, 'LineWidth', 1.2);
grid on; xlabel('Time (s)'); ylabel('Energy per step (mJ)');
legend('Node1','Node2','Node3','Location','best');
title('انرژی مصرفی 5G برای سه نود IoT');
