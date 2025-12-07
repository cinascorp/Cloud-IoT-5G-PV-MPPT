figure;

subplot(2,1,1);
plot(time, Power, 'LineWidth', 1.5);
ylabel('Power (W)');
title('PV Output Power');
grid on;

subplot(2,1,2);
stairs(time, mode_select, 'LineWidth', 1.5);
ylim([0.5 3.5]);
yticks([1 2 3]);
yticklabels({'ANN','SVM','P&O'});
ylabel('Mode');
xlabel('Time (s)');
grid on;
title('MPPT Mode Switching');
