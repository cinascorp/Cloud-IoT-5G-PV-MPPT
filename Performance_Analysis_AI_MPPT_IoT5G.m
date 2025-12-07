% تشخیص طول واقعی داده‌ها
t = tout;   % از فایل .mat یا workspace

% محدوده زمان واقعی را از داده استخراج کن
t_min = min(t);
t_max = max(t);

% بازه رسم را متناسب با واقعی تنظیم کنیم
figure('Name','AI-MPPT–IoT–5G Performance','Color','white','Position',[100 100 1200 800]);
sgtitle('Performance Evaluation of AI–MPPT–Refiner Under 5G–Cloud IoT','FontWeight','bold','FontSize',14);

% --- Power ---
subplot(2,2,1);
plot(t, power, 'LineWidth', 1.8, 'Color',[0 0.45 0.74]);
xlabel('Time (s)');
ylabel('Output Power (W)');
title('PV Power Curve – Hybrid MPPT Algorithm');
grid on; xlim([t_min t_max]); ylim([-100 550]);

% --- Delay ---
subplot(2,2,2);
plot(t, Delay, 'Color',[0.85 0.33 0.1],'LineWidth',1.8);
xlabel('Time (s)');
ylabel('Network Delay (ms)');
title('Cloud–MEC Communication Delay Analysis');
grid on; xlim([t_min t_max]);

% --- Cost ---
subplot(2,2,3);
plot(t, Cost, 'Color',[0.47 0.67 0.19],'LineWidth',1.8);
xlabel('Time (s)'); ylabel('Normalized Cost');
title('Communication and Processing Cost Analysis');
grid on; xlim([t_min t_max]);

% --- Mode ---
subplot(2,2,4);
stairs(t, Mode, 'Color',[0.49 0.18 0.56],'LineWidth',2);
xlabel('Time (s)');
ylabel('Selected MPPT Mode');
title('Algorithm Mode Change in Intelligent Control');
grid on;
yticks([1 2 3]); yticklabels({'SVM','ANN','P&O'});
xlim([t_min t_max]); ylim([0.5 3.5]);

saveas(gcf,'AI_MPPT_IoT5G_Results_Corrected.png');
