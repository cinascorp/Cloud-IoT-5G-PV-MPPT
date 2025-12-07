function IoT_Analysis_All
% Full IoT analysis for PV + MPPT + IoT nodes (mode 2:
%   - short legends
%   - detailed explanations in movable annotation boxes)

%% ---------- Global style for annotation boxes ----------
noteBG    = [0.95 0.95 0.95 0.90];   % light gray, almost opaque
noteColor = [0 0 0];                 % black text
noteFont  = 13;                      % larger font

%% ---------- 1. Load data from base workspace ----------
Vpv_log = evalin('base','Vpv_log(:)');
V1_log  = evalin('base','V1_log(:)');
V2_log  = evalin('base','V2_log(:)');
V3_log  = evalin('base','V3_log(:)');
G_log   = evalin('base','G_log(:)');

E1_log  = evalin('base','E1_log(:)');
E2_log  = evalin('base','E2_log(:)');
E3_log  = evalin('base','E3_log(:)');

if evalin('base','exist(''t'',''var'')')
    t_full = evalin('base','t(:)');
else
    t_full = evalin('base','tout(:)');
end

Vpv  = Vpv_log;
G    = G_log;
t_end = t_full(end);

V1 = V1_log;   N1 = numel(V1);
V2 = V2_log;   N2 = numel(V2);
V3 = V3_log;   N3 = numel(V3);

E1 = E1_log;
E2 = E2_log;
E3 = E3_log;

% time vectors for each node (uniform in [0, t_end])
t1 = linspace(0,t_end,N1).';
t2 = linspace(0,t_end,N2).';
t3 = linspace(0,t_end,N3).';

%% ---------- 2. Node parameters (from Simulink model) ----------
Ts1 = 0.01;  noise1 = 0.005;  P1 = 0.7;
Ts2 = 0.03;  noise2 = 0.010;  P2 = 0.5;
Ts3 = 0.05;  noise3 = 0.020;  P3 = 0.3;

Pkt1 = 1/Ts1;
Pkt2 = 1/Ts2;
Pkt3 = 1/Ts3;

%% ---------- 3. Multi-criteria weights ----------
wV     = 0.30;   % voltage accuracy
wG     = 0.20;   % irradiance accuracy
wE     = 0.20;   % energy consumption
wPkt   = 0.10;   % packet rate
wSNR   = 0.10;   % SNR of 5G link
wDelay = 0.10;   % delay of 5G link

%% ---------- 4. Voltage RMSE ----------
Vpv1 = interp1(t_full,Vpv,t1,'linear','extrap');
Vpv2 = interp1(t_full,Vpv,t2,'linear','extrap');
Vpv3 = interp1(t_full,Vpv,t3,'linear','extrap');

rmseV1 = sqrt(mean((V1 - Vpv1).^2));
rmseV2 = sqrt(mean((V2 - Vpv2).^2));
rmseV3 = sqrt(mean((V3 - Vpv3).^2));
rmseV  = [rmseV1 rmseV2 rmseV3];

%% ---------- 5. Irradiance RMSE ----------
G1 = interp1(t_full,G,t1,'previous');
G2 = interp1(t_full,G,t2,'previous');
G3 = interp1(t_full,G,t3,'previous');

Gpv1 = interp1(t_full,G,t1,'linear','extrap');
Gpv2 = interp1(t_full,G,t2,'linear','extrap');
Gpv3 = interp1(t_full,G,t3,'linear','extrap');

rmseG1 = sqrt(mean((G1 - Gpv1).^2));
rmseG2 = sqrt(mean((G2 - Gpv2).^2));
rmseG3 = sqrt(mean((G3 - Gpv3).^2));
rmseG  = [rmseG1 rmseG2 rmseG3];

%% ---------- 6. Energy, packet rate, SNR, delay ----------
E_vec   = [E1(end) E2(end) E3(end)];
Pkt_vec = [Pkt1 Pkt2 Pkt3];

% Optional 5G metrics from workspace
if evalin('base','exist(''SNR_nodes'',''var'')')
    SNR_nodes = evalin('base','SNR_nodes(:).''');
else
    SNR_nodes = [10 10 10];
end

if evalin('base','exist(''Delay_nodes'',''var'')')
    Delay_nodes = evalin('base','Delay_nodes(:).''');
else
    Delay_nodes = [0.01 0.01 0.01];
end

SNRvec = SNR_nodes;
D_vec  = Delay_nodes;

%% ---------- 7. Multi-criteria score ----------
epsv = 1e-12;
bV   = benefit_cost(rmseV, epsv);      % smaller is better
bG   = benefit_cost(rmseG, epsv);
bE   = benefit_cost(E_vec, epsv);
bD   = benefit_cost(D_vec, epsv);

bPkt = benefit_gain(Pkt_vec, epsv);    % larger is better
bSNR = benefit_gain(SNRvec, epsv);

Score = wV*bV + wG*bG + wE*bE + wPkt*bPkt + wSNR*bSNR + wDelay*bD;
[Score_best, bestNode] = max(Score);
[~, idx_Emin] = min(E_vec);

%% ---------- 8. Print summary table ----------
fprintf('\n===== Multi-Criteria IoT Node Evaluation =====\n');
fprintf('Node  RMSE_V   RMSE_G   E[J]    Pkt[1/s]   SNR[dB]  Delay[s]   Score\n');
for k = 1:3
    fprintf('%4d  %7.4f  %7.4f  %7.4f  %9.2f  %8.2f  %8.4f  %7.4f\n', ...
        k, rmseV(k), rmseG(k), E_vec(k), Pkt_vec(k), SNRvec(k), D_vec(k), Score(k));
end
fprintf('==> Best node (multi-criteria) : Node %d, Score = %.4f\n', bestNode, Score_best);
fprintf('==> Lowest-energy node          : Node %d, E = %.4f J\n\n', idx_Emin, E_vec(idx_Emin));

%% ---------- 9. Irradiance change instants ----------
dG    = diff(G);
idx_ch = find(abs(dG) > 1e-3) + 1;
t_ch   = t_full(idx_ch);
G_ch   = G(idx_ch);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FIGURE 1 – PV voltage vs IoT nodes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
f1 = figure; hold on; grid on;

hPV = plot(t_full,Vpv,'Color',[1 1 0],'LineWidth',1.5);
h1  = plot(t1,V1,'Color',[0 1 0],'LineWidth',1.2);
h2  = plot(t2,V2,'Color',[0 0 1],'LineWidth',1.2);
h3  = plot(t3,V3,'Color',[1 0 0],'LineWidth',1.2);

xlabel('Time (s)','FontSize',14);
ylabel('Voltage (V)','FontSize',14);
title('PV Voltage vs. IoT Nodes (Multi-Criteria Analysis)','FontSize',16);
set(gca,'FontSize',12);

% dummy handle just to show best node in legend
hBest = plot(nan,nan,'k--','LineWidth',1.2);

lg1 = legend([hPV h1 h2 h3 hBest], ...
    {'V_{PV} (real)','Node1','Node2','Node3', ...
     sprintf('Best node (MC): Node %d',bestNode)}, ...
    'Location','best');
set(lg1,'FontSize',11);

txt1 = sprintf( ...
['Voltage plot interpretation:\n' ...
 '• Yellow curve is the real PV voltage seen by the MPPT controller.\n' ...
 '• IoT nodes sample with different Ts and noise → Node1 is fastest and most accurate.\n' ...
 '• Voltage RMSE:  N1=%.3f  |  N2=%.3f  |  N3=%.3f\n' ...
 '• Multi-criteria best node = Node %d (Score = %.3f).'], ...
 rmseV1,rmseV2,rmseV3,bestNode,Score_best);

ann1 = annotation(f1,'textbox',[0.14 0.77 0.32 0.18], ...
    'Units','normalized', ...
    'String',txt1,'Interpreter','tex', ...
    'FitBoxToText','on', ...
    'BackgroundColor',noteBG, ...
    'Color',noteColor, ...
    'FontSize',noteFont, ...
    'EdgeColor',[0.5 0.5 0.5], ...
    'LineWidth',0.8, ...
    'Margin',8);

for k = 1:numel(t_ch)
    xline(t_ch(k),'--k','LineWidth',1);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FIGURE 2 – Irradiance vs IoT nodes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
f2 = figure; hold on; grid on;

hG  = plot(t_full,G,'Color',[1 1 0],'LineWidth',1.5);
hG1 = plot(t1,G1,'Color',[0 1 0],'LineWidth',1.2);
hG2 = plot(t2,G2,'Color',[0 0 1],'LineWidth',1.2);
hG3 = plot(t3,G3,'Color',[1 0 0],'LineWidth',1.2);

xlabel('Time (s)','FontSize',14);
ylabel('Irradiance (W/m^2)','FontSize',14);
title('Irradiance G vs. IoT Nodes','FontSize',16);
set(gca,'FontSize',12);

ylim([550 1050]);   % as requested

lg2 = legend([hG hG1 hG2 hG3], ...
    {'G (real)','G_{Node1}','G_{Node2}','G_{Node3}'}, ...
    'Location','best');
set(lg2,'FontSize',11);

txt2 = [ ...
 'Irradiance plot interpretation:' newline ...
 '• The yellow step profile is the reference G(t) applied to the PV array.' newline ...
 '• Due to different sampling times, each node detects the step changes' newline ...
 '  with a slightly different delay (larger Ts → larger delay and loss of detail).' newline ...
 '• Vertical dashed lines and black markers show the exact instants' newline ...
 '  where G changes in the PV system.' ];

ann2 = annotation(f2,'textbox',[0.14 0.77 0.36 0.18], ...
    'Units','normalized', ...
    'String',txt2, ...
    'Interpreter','tex', ...
    'FitBoxToText','on', ...
    'BackgroundColor',noteBG, ...
    'Color',noteColor, ...
    'FontSize',noteFont, ...
    'EdgeColor',[0.5 0.5 0.5], ...
    'LineWidth',0.8, ...
    'Margin',8);

for k = 1:numel(t_ch)
    xline(t_ch(k),'--k','LineWidth',1);
    plot(t_ch(k),G_ch(k),'ko','MarkerFaceColor','k','MarkerSize',5);
    text(t_ch(k),G_ch(k)+15,sprintf('%.2f s',t_ch(k)), ...
        'HorizontalAlignment','center','FontSize',9,'Color','k');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FIGURE 3 – Voltage error
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
f3 = figure; hold on; grid on;

err1 = V1 - Vpv1;
err2 = V2 - Vpv2;
err3 = V3 - Vpv3;

hE1 = plot(t1,err1,'Color',[0 1 0],'LineWidth',1.2);
hE2 = plot(t2,err2,'Color',[0 0 1],'LineWidth',1.2);
hE3 = plot(t3,err3,'Color',[1 0 0],'LineWidth',1.2);

xlabel('Time (s)','FontSize',14);
ylabel('Voltage error  V_{IoT} - V_{PV} (V)','FontSize',14);
title('Voltage Measurement Error (Noise + ADC + Sampling)','FontSize',16);
set(gca,'FontSize',12);

lg3 = legend([hE1 hE2 hE3],{'Node1 error','Node2 error','Node3 error'}, ...
    'Location','best');
set(lg3,'FontSize',11);

txt3 = sprintf( ...
['Error plot interpretation:\n' ...
 '• This figure shows the instantaneous voltage error of each node.\n' ...
 '• Node1 has the smallest error (fine sampling + low noise).\n' ...
 '• Node3 exhibits the largest error due to higher noise and larger Ts.\n' ...
 '• RMSE_V summarizes the overall impact of noise and ADC:\n' ...
 '  RMSE_V = [N1: %.3f  N2: %.3f  N3: %.3f] V.'], ...
 rmseV1,rmseV2,rmseV3);

ann3 = annotation(f3,'textbox',[0.14 0.77 0.38 0.18], ...
    'Units','normalized', ...
    'String',txt3, ...
    'Interpreter','tex', ...
    'FitBoxToText','on', ...
    'BackgroundColor',noteBG, ...
    'Color',noteColor, ...
    'FontSize',noteFont, ...
    'EdgeColor',[0.5 0.5 0.5], ...
    'LineWidth',0.8, ...
    'Margin',8);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FIGURE 4 – Cumulative energy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
f4 = figure; hold on; grid on;

hEn1 = plot(t1,E1,'Color',[0 1 0],'LineWidth',1.5);
hEn2 = plot(t2,E2,'Color',[0 0 1],'LineWidth',1.5);
hEn3 = plot(t3,E3,'Color',[1 0 0],'LineWidth',1.5);

xlabel('Time (s)','FontSize',14);
ylabel('Cumulative energy E_{IoT} (J)','FontSize',14);
title('IoT Node Energy Consumption vs Time','FontSize',16);
set(gca,'FontSize',12);

lg4 = legend([hEn1 hEn2 hEn3],{'Node1','Node2','Node3'},'Location','best');
set(lg4,'FontSize',11);

txt4 = sprintf( ...
['Energy plot interpretation:\n' ...
 '• Node1 transmits more frequently (small Ts) → higher energy usage.\n' ...
 '• Node3 has the lowest energy due to the largest sampling period.\n' ...
 '• Total energy after simulation:\n' ...
 '  E_1 = %.3f J,  E_2 = %.3f J,  E_3 = %.3f J.'], ...
 E_vec(1),E_vec(2),E_vec(3));

ann4 = annotation(f4,'textbox',[0.14 0.77 0.38 0.18], ...
    'Units','normalized', ...
    'String',txt4, ...
    'Interpreter','tex', ...
    'FitBoxToText','on', ...
    'BackgroundColor',noteBG, ...
    'Color',noteColor, ...
    'FontSize',noteFont, ...
    'EdgeColor',[0.5 0.5 0.5], ...
    'LineWidth',0.8, ...
    'Margin',8);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FIGURE 5 – Bar chart of total energy with different colors
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
f5 = figure;
b = bar(1:3,E_vec,'FaceColor','flat');
b.CData(1,:) = [0 0.7 0];   % green for Node1
b.CData(2,:) = [0 0 1];     % blue for Node2
b.CData(3,:) = [1 0 0];     % red  for Node3

set(gca,'XTick',1:3,'XTickLabel',{'Node1','Node2','Node3'},'FontSize',12);
ylabel('Total energy E_{IoT} (J)','FontSize',14);
title('Total IoT Node Energy after Simulation','FontSize',16);
hold on;

plot(idx_Emin,E_vec(idx_Emin),'p','MarkerFaceColor','y','MarkerEdgeColor','k','MarkerSize',14);

for k = 1:3
    text(k,E_vec(k)+0.03*max(E_vec),sprintf('%.3f J',E_vec(k)), ...
        'HorizontalAlignment','center','FontSize',12);
end

lg5 = legend({'Node1','Node2','Node3', ...
              sprintf('Min energy node: Node %d',idx_Emin)}, ...
             'Location','best');
set(lg5,'FontSize',11);

txt5 = sprintf( ...
['Bar chart interpretation:\n' ...
 '• Each bar shows the total energy consumed by one IoT node.\n' ...
 '• The yellow-marked node (Node %d) has the minimum energy.\n' ...
 '• This clearly illustrates the trade-off between sensing accuracy\n' ...
 '  (Node1) and energy saving (Node3).'], idx_Emin);

ann5 = annotation(f5,'textbox',[0.58 0.72 0.35 0.18], ...
    'Units','normalized', ...
    'String',txt5, ...
    'Interpreter','tex', ...
    'FitBoxToText','on', ...
    'BackgroundColor',noteBG, ...
    'Color',noteColor, ...
    'FontSize',noteFont, ...
    'EdgeColor',[0.5 0.5 0.5], ...
    'LineWidth',0.8, ...
    'Margin',8);

%% ---------- Export annotation handles to base (optional) ----------
assignin('base','ann1',ann1);
assignin('base','ann2',ann2);
assignin('base','ann3',ann3);
assignin('base','ann4',ann4);
assignin('base','ann5',ann5);

% Enable interactive edit mode so you can drag legends/annotations with mouse
plotedit on;

end

%% ---------- Helper functions ----------
function b = benefit_cost(x,epsv)
% cost-type metric (smaller is better) → normalized benefit [0,1]
x = x(:).';
if max(x)-min(x) < epsv
    b = ones(size(x));
else
    b = (max(x) - x) ./ (max(x) - min(x) + epsv);
end
end

function b = benefit_gain(x,epsv)
% gain-type metric (larger is better) → normalized benefit [0,1]
x = x(:).';
if max(x)-min(x) < epsv
    b = ones(size(x));
else
    b = (x - min(x)) ./ (max(x) - min(x) + epsv);
end
end
