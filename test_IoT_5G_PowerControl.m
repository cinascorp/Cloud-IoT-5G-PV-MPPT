%% ========================================================================
%  IoT + 5G + Power Control (3 Nodes)
%  Comprehensive test & plotting script
%  Run your Simulink model first, then run this script.
% ========================================================================

clc;
fprintf('=== IoT + 5G + Power Control: Comprehensive Test ===\n');

%% 0) Check mandatory variables (SNR, Tx Power, tout)

req = {'SNR_Node1','SNR_Node2','SNR_Node3', ...
       'TxP_Node1','TxP_Node2','TxP_Node3', ...
       'tout'};

for k = 1:numel(req)
    if ~exist(req{k},'var')
        error('Missing variable "%s" in workspace. Please log it from Simulink.', req{k});
    end
end

%% 1) Make SNR & TxPower same length and build time vector

lenMandatory = [ ...
    numel(SNR_Node1), numel(SNR_Node2), numel(SNR_Node3), ...
    numel(TxP_Node1), numel(TxP_Node2), numel(TxP_Node3) ...
    ];
N = min(lenMandatory);

trim = @(x) x(1:N);

SNR_Node1 = trim(SNR_Node1(:));
SNR_Node2 = trim(SNR_Node2(:));
SNR_Node3 = trim(SNR_Node3(:));

TxP_Node1 = trim(TxP_Node1(:));
TxP_Node2 = trim(TxP_Node2(:));
TxP_Node3 = trim(TxP_Node3(:));

t = linspace(0, tout(end), N).';   % time vector aligned to N samples

idx_steady = floor(N/2):N;

%% 2) Metrics for SNR & Tx Power (always available)

mSNR1 = mean(SNR_Node1(idx_steady));
mSNR2 = mean(SNR_Node2(idx_steady));
mSNR3 = mean(SNR_Node3(idx_steady));

mP1 = mean(TxP_Node1(idx_steady));
mP2 = mean(TxP_Node2(idx_steady));
mP3 = mean(TxP_Node3(idx_steady));

fprintf('\n--- Mandatory metrics (steady state averages) ---\n');
fprintf('Node   SNR(dB)   TxPower(dBm)\n');
fprintf('N1   %8.2f   %10.2f\n', mSNR1, mP1);
fprintf('N2   %8.2f   %10.2f\n', mSNR2, mP2);
fprintf('N3   %8.2f   %10.2f\n', mSNR3, mP3);

%% 3) Optional metrics (Throughput / Delay / Energy / PLR) if available

hasThr   = exist('Thr_Node1','var')      && exist('Thr_Node2','var')      && exist('Thr_Node3','var');
hasDelay = exist('Delay5G_Node1','var')  && exist('Delay5G_Node2','var')  && exist('Delay5G_Node3','var');
hasEn    = exist('E5G_Node1','var')      && exist('E5G_Node2','var')      && exist('E5G_Node3','var');
hasPL    = exist('PL_Node1','var')       && exist('PL_Node2','var')       && exist('PL_Node3','var');

if hasThr
    lenThr = [numel(Thr_Node1), numel(Thr_Node2), numel(Thr_Node3)];
    Nthr   = min([N lenThr]);
    trimThr = @(x) x(1:Nthr);
    t_thr = linspace(0, tout(end), Nthr).';
    Thr_Node1 = trimThr(Thr_Node1(:));
    Thr_Node2 = trimThr(Thr_Node2(:));
    Thr_Node3 = trimThr(Thr_Node3(:));
    
    mThr1 = mean(Thr_Node1(floor(Nthr/2):Nthr))/1e6;
    mThr2 = mean(Thr_Node2(floor(Nthr/2):Nthr))/1e6;
    mThr3 = mean(Thr_Node3(floor(Nthr/2):Nthr))/1e6;
else
    fprintf('\n[INFO] Throughput signals Thr_Node1/2/3 not found. Throughput plots will be skipped.\n');
end

if hasDelay
    lenDel = [numel(Delay5G_Node1), numel(Delay5G_Node2), numel(Delay5G_Node3)];
    Ndel   = min([N lenDel]);
    trimDel = @(x) x(1:Ndel);
    t_del = linspace(0, tout(end), Ndel).';
    Delay5G_Node1 = trimDel(Delay5G_Node1(:));
    Delay5G_Node2 = trimDel(Delay5G_Node2(:));
    Delay5G_Node3 = trimDel(Delay5G_Node3(:));
    
    mDel1 = mean(Delay5G_Node1(floor(Ndel/2):Ndel))*1e3;
    mDel2 = mean(Delay5G_Node2(floor(Ndel/2):Ndel))*1e3;
    mDel3 = mean(Delay5G_Node3(floor(Ndel/2):Ndel))*1e3;
else
    fprintf('[INFO] Delay signals Delay5G_Node1/2/3 not found. Delay plots will be skipped.\n');
end

if hasEn
    lenEn = [numel(E5G_Node1), numel(E5G_Node2), numel(E5G_Node3)];
    Nen   = min([N lenEn]);
    trimEn = @(x) x(1:Nen);
    t_en = linspace(0, tout(end), Nen).';
    E5G_Node1 = trimEn(E5G_Node1(:));
    E5G_Node2 = trimEn(E5G_Node2(:));
    E5G_Node3 = trimEn(E5G_Node3(:));
    
    mE1  = mean(E5G_Node1(floor(Nen/2):Nen))*1e3;
    mE2  = mean(E5G_Node2(floor(Nen/2):Nen))*1e3;
    mE3  = mean(E5G_Node3(floor(Nen/2):Nen))*1e3;
    
    E_total1 = sum(E5G_Node1)*1e3;
    E_total2 = sum(E5G_Node2)*1e3;
    E_total3 = sum(E5G_Node3)*1e3;
else
    fprintf('[INFO] Energy signals E5G_Node1/2/3 not found. Energy plots will be skipped.\n');
end

if hasPL
    lenPL = [numel(PL_Node1), numel(PL_Node2), numel(PL_Node3)];
    Npl   = min([N lenPL]);
    trimPL = @(x) x(1:Npl);
    t_pl = linspace(0, tout(end), Npl).';
    PL_Node1 = trimPL(PL_Node1(:));
    PL_Node2 = trimPL(PL_Node2(:));
    PL_Node3 = trimPL(PL_Node3(:));
    
    PLR1 = mean(PL_Node1(floor(Npl/2):Npl));
    PLR2 = mean(PL_Node2(floor(Npl/2):Npl));
    PLR3 = mean(PL_Node3(floor(Npl/2):Npl));
else
    fprintf('[INFO] Packet loss signals PL_Node1/2/3 not found. PLR plots will be skipped.\n');
end

%% 4) Plot SNR

figure;
plot(t, SNR_Node1, 'LineWidth', 1.4); hold on;
plot(t, SNR_Node2, 'LineWidth', 1.4);
plot(t, SNR_Node3, 'LineWidth', 1.4);
grid on; xlabel('Time (s)'); ylabel('SNR (dB)');
legend('Node 1','Node 2','Node 3','Location','best');
title('SNR of Three IoT Nodes over 5G Link');

txt = sprintf(['Average SNR (steady state)\n',...
               'Node 1: %.2f dB\nNode 2: %.2f dB\nNode 3: %.2f dB'], ...
               mSNR1, mSNR2, mSNR3);
annotation('textbox',[0.15 0.72 0.25 0.2],'String',txt,...
           'FitBoxToText','on','BackgroundColor','w');

%% 5) Plot Tx Power

figure;
plot(t, TxP_Node1, 'LineWidth', 1.4); hold on;
plot(t, TxP_Node2, 'LineWidth', 1.4);
plot(t, TxP_Node3, 'LineWidth', 1.4);
grid on; xlabel('Time (s)'); ylabel('Tx Power (dBm)');
legend('Node 1','Node 2','Node 3','Location','best');
title('Transmit Power of Three IoT Nodes (5G Power Control)');

txt = sprintf(['Mean Tx Power (steady state)\n',...
               'Node 1: %.2f dBm\nNode 2: %.2f dBm\nNode 3: %.2f dBm'], ...
               mP1, mP2, mP3);
annotation('textbox',[0.15 0.72 0.28 0.18],'String',txt,...
           'FitBoxToText','on','BackgroundColor','w');

%% 6) Optional plots

% Throughput
if hasThr
    figure;
    plot(t_thr, Thr_Node1/1e6, 'LineWidth', 1.4); hold on;
    plot(t_thr, Thr_Node2/1e6, 'LineWidth', 1.4);
    plot(t_thr, Thr_Node3/1e6, 'LineWidth', 1.4);
    grid on; xlabel('Time (s)'); ylabel('Throughput (Mbps)');
    legend('Node 1','Node 2','Node 3','Location','best');
    title('5G Throughput of Three IoT Nodes');
    
    txt = sprintf(['Average Throughput\n',...
                   'Node 1: %.2f Mbps\nNode 2: %.2f Mbps\nNode 3: %.2f Mbps'], ...
                   mThr1, mThr2, mThr3);
    annotation('textbox',[0.15 0.72 0.30 0.18],'String',txt,...
               'FitBoxToText','on','BackgroundColor','w');
end

% Delay
if hasDelay
    figure;
    plot(t_del, 1e3*Delay5G_Node1, 'LineWidth', 1.4); hold on;
    plot(t_del, 1e3*Delay5G_Node2, 'LineWidth', 1.4);
    plot(t_del, 1e3*Delay5G_Node3, 'LineWidth', 1.4);
    grid on; xlabel('Time (s)'); ylabel('5G Delay (ms)');
    legend('Node 1','Node 2','Node 3','Location','best');
    title('End-to-End 5G Delay for Three IoT Nodes');
    
    txt = sprintf(['Average 5G Delay\n',...
                   'Node 1: %.3f ms\nNode 2: %.3f ms\nNode 3: %.3f ms'], ...
                   mDel1, mDel2, mDel3);
    annotation('textbox',[0.15 0.72 0.30 0.18],'String',txt,...
               'FitBoxToText','on','BackgroundColor','w');
end

% Energy
if hasEn
    figure;
    plot(t_en, 1e3*E5G_Node1, 'LineWidth', 1.4); hold on;
    plot(t_en, 1e3*E5G_Node2, 'LineWidth', 1.4);
    plot(t_en, 1e3*E5G_Node3, 'LineWidth', 1.4);
    grid on; xlabel('Time (s)'); ylabel('5G Energy per step (mJ)');
    legend('Node 1','Node 2','Node 3','Location','best');
    title('5G Transmission Energy for Three IoT Nodes');
    
    txt = sprintf(['Mean Energy per step\n',...
                   'Node 1: %.3f mJ\nNode 2: %.3f mJ\nNode 3: %.3f mJ'], ...
                   mE1, mE2, mE3);
    annotation('textbox',[0.15 0.72 0.30 0.18],'String',txt,...
               'FitBoxToText','on','BackgroundColor','w');
end

% Packet loss
if hasPL
    figure;
    plot(t_pl, PL_Node1, 'LineWidth', 1.4); hold on;
    plot(t_pl, PL_Node2, 'LineWidth', 1.4);
    plot(t_pl, PL_Node3, 'LineWidth', 1.4);
    grid on; xlabel('Time (s)'); ylabel('Packet Lost (0 or 1)');
    legend('Node 1','Node 2','Node 3','Location','best');
    title('5G Packet Loss Indicator for Three IoT Nodes');
    
    txt = sprintf(['Average Packet Loss Rate\n',...
                   'Node 1: %.3f\nNode 2: %.3f\nNode 3: %.3f'], ...
                   PLR1, PLR2, PLR3);
    annotation('textbox',[0.15 0.72 0.30 0.18],'String',txt,...
               'FitBoxToText','on','BackgroundColor','w');
end

fprintf('\nAll available plots generated. Use them directly in your thesis and paper.\n');
