%% =====================================================================
%   IEEE-Style Plot Package for IoT + 5G + Power Control (3 Nodes)
%   Run AFTER Simulink model (signals in workspace).
% ======================================================================

clc;
fprintf('=== IEEE Plot Package for IoT + 5G + Power Control ===\n');

%% 0) Check required variables

reqVars = {'tout', ...
    'SNR_Node1','SNR_Node2','SNR_Node3', ...
    'TxP_Node1','TxP_Node2','TxP_Node3', ...
    'MCS_Node1','MCS_Node2','MCS_Node3', ...
    'SE_Node1','SE_Node2','SE_Node3', ...
    'Thr_Node1','Thr_Node2','Thr_Node3', ...
    'Delay5G_Node1','Delay5G_Node2','Delay5G_Node3', ...
    'E5G_Node1','E5G_Node2','E5G_Node3', ...
    'PL_Node1','PL_Node2','PL_Node3'};

for k = 1:numel(reqVars)
    if ~exist(reqVars{k},'var')
        warning('Variable "%s" is missing in the workspace.', reqVars{k});
    end
end

%% 1) Colors and basic settings

blue  = [0 0.4470 0.7410];      % Node 1
red   = [0.8500 0.3250 0.0980]; % Node 2
green = [0.4660 0.6740 0.1880]; % Node 3

set(0,'DefaultFigureColor','w');   % white background

%% 2) Align lengths (defensive)

lenList = [
    numel(tout) ...
    numel(SNR_Node1) numel(SNR_Node2) numel(SNR_Node3) ...
    numel(TxP_Node1) numel(TxP_Node2) numel(TxP_Node3) ...
    numel(MCS_Node1) numel(MCS_Node2) numel(MCS_Node3) ...
    numel(SE_Node1)  numel(SE_Node2)  numel(SE_Node3) ...
    numel(Thr_Node1) numel(Thr_Node2) numel(Thr_Node3) ...
    numel(Delay5G_Node1) numel(Delay5G_Node2) numel(Delay5G_Node3) ...
    numel(E5G_Node1) numel(E5G_Node2) numel(E5G_Node3) ...
    numel(PL_Node1)  numel(PL_Node2)  numel(PL_Node3) ...
    ];

N = min(lenList);

t  = linspace(0, tout(end), N).';

trim = @(x) x(1:N);

SNR1 = trim(SNR_Node1(:));
SNR2 = trim(SNR_Node2(:));
SNR3 = trim(SNR_Node3(:));

Tx1  = trim(TxP_Node1(:));
Tx2  = trim(TxP_Node2(:));
Tx3  = trim(TxP_Node3(:));

MCS1 = trim(MCS_Node1(:));
MCS2 = trim(MCS_Node2(:));
MCS3 = trim(MCS_Node3(:));

SE1  = trim(SE_Node1(:));
SE2  = trim(SE_Node2(:));
SE3  = trim(SE_Node3(:));

Thr1 = trim(Thr_Node1(:));
Thr2 = trim(Thr_Node2(:));
Thr3 = trim(Thr_Node3(:));

Del1 = trim(Delay5G_Node1(:));
Del2 = trim(Delay5G_Node2(:));
Del3 = trim(Delay5G_Node3(:));

E1   = trim(E5G_Node1(:));
E2   = trim(E5G_Node2(:));
E3   = trim(E5G_Node3(:));

PL1  = trim(PL_Node1(:));
PL2  = trim(PL_Node2(:));
PL3  = trim(PL_Node3(:));

idx_steady = floor(N/2):N;

%% 3) Compute metrics (steady-state averages)

mSNR1 = mean(SNR1(idx_steady));
mSNR2 = mean(SNR2(idx_steady));
mSNR3 = mean(SNR3(idx_steady));

mTx1  = mean(Tx1(idx_steady));
mTx2  = mean(Tx2(idx_steady));
mTx3  = mean(Tx3(idx_steady));

mThr1 = mean(Thr1(idx_steady))/1e6;  % Mbps
mThr2 = mean(Thr2(idx_steady))/1e6;
mThr3 = mean(Thr3(idx_steady))/1e6;

mDel1 = mean(Del1(idx_steady))*1e3;  % ms
mDel2 = mean(Del2(idx_steady))*1e3;
mDel3 = mean(Del3(idx_steady))*1e3;

PLR1  = mean(PL1(idx_steady));
PLR2  = mean(PL2(idx_steady));
PLR3  = mean(PL3(idx_steady));

mSE1  = mean(SE1(idx_steady));
mSE2  = mean(SE2(idx_steady));
mSE3  = mean(SE3(idx_steady));

mE1   = mean(E1(idx_steady))*1e3;    % mJ per step
mE2   = mean(E2(idx_steady))*1e3;
mE3   = mean(E3(idx_steady))*1e3;

Etot1 = sum(E1)*1e3;   % total mJ
Etot2 = sum(E2)*1e3;
Etot3 = sum(E3)*1e3;

fprintf('\n--- Steady-state Metrics (Averages) ---\n');
fprintf('Node   SNR(dB)  TxP(dBm)  Thr(Mbps)  Delay(ms)  PLR   SE(bit/s/Hz)  Eavg(mJ)  Etot(mJ)\n');
fprintf('N1   %8.2f  %8.2f  %9.3f  %9.3f  %5.3f  %12.3f  %9.3f  %9.3f\n', ...
    mSNR1, mTx1, mThr1, mDel1, PLR1, mSE1, mE1, Etot1);
fprintf('N2   %8.2f  %8.2f  %9.3f  %9.3f  %5.3f  %12.3f  %9.3f  %9.3f\n', ...
    mSNR2, mTx2, mThr2, mDel2, PLR2, mSE2, mE2, Etot2);
fprintf('N3   %8.2f  %8.2f  %9.3f  %9.3f  %5.3f  %12.3f  %9.3f  %9.3f\n', ...
    mSNR3, mTx3, mThr3, mDel3, PLR3, mSE3, mE3, Etot3);

%% ========= 4) SNR vs Time =========
figure;
plot(t, SNR1, 'Color', blue,  'LineWidth', 1.6); hold on;
plot(t, SNR2, 'Color', red,   'LineWidth', 1.6);
plot(t, SNR3, 'Color', green, 'LineWidth', 1.6);
grid on; xlabel('Time (s)'); ylabel('SNR (dB)');
title('SNR vs Time for Three IoT Nodes over 5G Link');
legend('Node 1','Node 2','Node 3','Location','best');

txt = sprintf(['Average SNR (steady state)\n',...
    'Node 1: %.2f dB\nNode 2: %.2f dB\nNode 3: %.2f dB'], ...
    mSNR1, mSNR2, mSNR3);
annotation('textbox',[0.15 0.72 0.30 0.18],'String',txt,...
    'FitBoxToText','on','BackgroundColor','w');

%% ========= 5) Tx Power vs Time =========
figure;
plot(t, Tx1, 'Color', blue,  'LineWidth', 1.6); hold on;
plot(t, Tx2, 'Color', red,   'LineWidth', 1.6);
plot(t, Tx3, 'Color', green, 'LineWidth', 1.6);
grid on; xlabel('Time (s)'); ylabel('Tx Power (dBm)');
title('Transmit Power vs Time (5G Power Control)');
legend('Node 1','Node 2','Node 3','Location','best');

txt = sprintf(['Mean Tx Power (steady state)\n',...
    'Node 1: %.2f dBm\nNode 2: %.2f dBm\nNode 3: %.2f dBm'], ...
    mTx1, mTx2, mTx3);
annotation('textbox',[0.15 0.72 0.30 0.18],'String',txt,...
    'FitBoxToText','on','BackgroundColor','w');

%% ========= 6) MCS vs Time =========
figure;
stairs(t, MCS1, 'Color', blue,  'LineWidth', 1.4); hold on;
stairs(t, MCS2, 'Color', red,   'LineWidth', 1.4);
stairs(t, MCS3, 'Color', green, 'LineWidth', 1.4);
grid on; xlabel('Time (s)'); ylabel('MCS Index');
title('Adaptive MCS Index vs Time');
legend('Node 1','Node 2','Node 3','Location','best');

%% ========= 7) MCS vs SNR (Scatter) =========
figure; hold on; grid on;
scatter(SNR1, MCS1, 25, blue,  'filled');
scatter(SNR2, MCS2, 25, red,   'filled');
scatter(SNR3, MCS3, 25, green, 'filled');
xlabel('SNR (dB)'); ylabel('MCS Index');
title('MCS Adaptation as a Function of SNR');
legend('Node 1','Node 2','Node 3','Location','best');

%% ========= 8) Spectral Efficiency vs Time =========
figure;
plot(t, SE1, 'Color', blue,  'LineWidth', 1.6); hold on;
plot(t, SE2, 'Color', red,   'LineWidth', 1.6);
plot(t, SE3, 'Color', green, 'LineWidth', 1.6);
grid on; xlabel('Time (s)'); ylabel('Spectral Efficiency (bit/s/Hz)');
title('Spectral Efficiency vs Time');
legend('Node 1','Node 2','Node 3','Location','best');

txt = sprintf(['Average SE (steady state)\n',...
    'Node 1: %.2f bit/s/Hz\nNode 2: %.2f bit/s/Hz\nNode 3: %.2f bit/s/Hz'], ...
    mSE1, mSE2, mSE3);
annotation('textbox',[0.15 0.72 0.34 0.18],'String',txt,...
    'FitBoxToText','on','BackgroundColor','w');

%% ========= 9) Throughput vs Time =========
figure;
plot(t, Thr1/1e6, 'Color', blue,  'LineWidth', 1.6); hold on;
plot(t, Thr2/1e6, 'Color', red,   'LineWidth', 1.6);
plot(t, Thr3/1e6, 'Color', green, 'LineWidth', 1.6);
grid on; xlabel('Time (s)'); ylabel('Throughput (Mbps)');
title('5G Throughput vs Time for Three IoT Nodes');
legend('Node 1','Node 2','Node 3','Location','best');

txt = sprintf(['Average Throughput (steady state)\n',...
    'Node 1: %.2f Mbps\nNode 2: %.2f Mbps\nNode 3: %.2f Mbps'], ...
    mThr1, mThr2, mThr3);
annotation('textbox',[0.15 0.72 0.34 0.18],'String',txt,...
    'FitBoxToText','on','BackgroundColor','w');

%% ========= 10) Delay vs Time =========
figure;
plot(t, Del1*1e3, 'Color', blue,  'LineWidth', 1.6); hold on;
plot(t, Del2*1e3, 'Color', red,   'LineWidth', 1.6);
plot(t, Del3*1e3, 'Color', green, 'LineWidth', 1.6);
grid on; xlabel('Time (s)'); ylabel('5G Delay (ms)');
title('End-to-End 5G Delay vs Time');
legend('Node 1','Node 2','Node 3','Location','best');

txt = sprintf(['Average 5G Delay (steady state)\n',...
    'Node 1: %.3f ms\nNode 2: %.3f ms\nNode 3: %.3f ms'], ...
    mDel1, mDel2, mDel3);
annotation('textbox',[0.15 0.72 0.34 0.18],'String',txt,...
    'FitBoxToText','on','BackgroundColor','w');

%% ========= 11) Packet Loss vs Time =========
figure;
plot(t, PL1*100, 'Color', blue,  'LineWidth', 1.4); hold on;
plot(t, PL2*100, 'Color', red,   'LineWidth', 1.4);
plot(t, PL3*100, 'Color', green, 'LineWidth', 1.4);
grid on; xlabel('Time (s)'); ylabel('Packet Lost (%)');
title('Instantaneous Packet Loss Indicator (0 or 100%)');
legend('Node 1','Node 2','Node 3','Location','best');

txt = sprintf(['Average Packet Loss Rate\n',...
    'Node 1: %.3f\nNode 2: %.3f\nNode 3: %.3f'], ...
    PLR1, PLR2, PLR3);
annotation('textbox',[0.15 0.72 0.32 0.18],'String',txt,...
    'FitBoxToText','on','BackgroundColor','w');

%% ========= 12) Energy per Transmission vs Time =========
figure;
plot(t, 1e3*E1, 'Color', blue,  'LineWidth', 1.6); hold on;
plot(t, 1e3*E2, 'Color', red,   'LineWidth', 1.6);
plot(t, 1e3*E3, 'Color', green, 'LineWidth', 1.6);
grid on; xlabel('Time (s)'); ylabel('Energy per step (mJ)');
title('5G Transmission Energy vs Time');
legend('Node 1','Node 2','Node 3','Location','best');

txt = sprintf(['Mean Energy per step (steady state)\n',...
    'Node 1: %.3f mJ\nNode 2: %.3f mJ\nNode 3: %.3f mJ'], ...
    mE1, mE2, mE3);
annotation('textbox',[0.15 0.72 0.36 0.18],'String',txt,...
    'FitBoxToText','on','BackgroundColor','w');

%% ========= 13) CDF of SNR =========
figure; hold on; grid on;

[F1,X1] = ecdf(SNR1);
plot(X1, F1, 'Color', blue,  'LineWidth', 1.6);

[F2,X2] = ecdf(SNR2);
plot(X2, F2, 'Color', red,   'LineWidth', 1.6);

[F3,X3] = ecdf(SNR3);
plot(X3, F3, 'Color', green, 'LineWidth', 1.6);

xlabel('SNR (dB)'); ylabel('CDF');
title('Empirical CDF of SNR for Three IoT Nodes');
legend('Node 1','Node 2','Node 3','Location','best');

%% ========= 14) Histogram of MCS =========
figure; hold on; grid on;
histogram(MCS1,'FaceColor',blue,'FaceAlpha',0.5);
histogram(MCS2,'FaceColor',red,'FaceAlpha',0.5);
histogram(MCS3,'FaceColor',green,'FaceAlpha',0.5);
xlabel('MCS Index'); ylabel('Count');
title('Histogram of Selected MCS for Each Node');
legend('Node 1','Node 2','Node 3','Location','best');

%% ========= 15) Scatter SNR vs Throughput =========
figure; hold on; grid on;
scatter(SNR1, Thr1/1e6, 25, blue,  'filled');
scatter(SNR2, Thr2/1e6, 25, red,   'filled');
scatter(SNR3, Thr3/1e6, 25, green, 'filled');
xlabel('SNR (dB)'); ylabel('Throughput (Mbps)');
title('SNR vs Throughput');
legend('Node 1','Node 2','Node 3','Location','best');

%% ========= 16) Summary Bar Charts =========
nodes = categorical({'Node 1','Node 2','Node 3'});
nodes = reordercats(nodes,{'Node 1','Node 2','Node 3'});

figure;
subplot(2,3,1);
bar(nodes,[mSNR1 mSNR2 mSNR3],'FaceColor','flat');
set(gca,'YGrid','on'); ylabel('SNR (dB)'); title('Average SNR');

subplot(2,3,2);
bar(nodes,[mThr1 mThr2 mThr3],'FaceColor','flat');
set(gca,'YGrid','on'); ylabel('Throughput (Mbps)'); title('Average Throughput');

subplot(2,3,3);
bar(nodes,[mDel1 mDel2 mDel3],'FaceColor','flat');
set(gca,'YGrid','on'); ylabel('Delay (ms)'); title('Average 5G Delay');

subplot(2,3,4);
bar(nodes,[PLR1 PLR2 PLR3],'FaceColor','flat');
set(gca,'YGrid','on'); ylabel('PLR'); title('Packet Loss Rate');

subplot(2,3,5);
bar(nodes,[mTx1 mTx2 mTx3],'FaceColor','flat');
set(gca,'YGrid','on'); ylabel('Tx Power (dBm)'); title('Average Tx Power');

subplot(2,3,6);
bar(nodes,[Etot1 Etot2 Etot3],'FaceColor','flat');
set(gca,'YGrid','on'); ylabel('Total Energy (mJ)'); title('Total 5G Energy');

sgtitle('Summary of Key Metrics for Three IoT Nodes over 5G');

fprintf('\nAll IEEE-style plots generated. Use them in your thesis and Q1 paper.\n');
