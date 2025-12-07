function SelectNode
% تحلیل چندمعیاره سه نود IoT و انتخاب بهترین نود
% معیارها:
%   - RMSE ولتاژ (کوچک‌تر بهتر)
%   - RMSE تابش (کوچک‌تر بهتر)
%   - انرژی مصرفی E_iot (کوچک‌تر بهتر)
%   - نرخ ارسال Pkt_rate = 1/Ts (بزرگ‌تر بهتر)
%   - SNR لینک 5G (بزرگ‌تر بهتر) [در آینده]
%   - Delay لینک 5G (کوچک‌تر بهتر) [در آینده]

%% ========= 1) پارامترهای نودها (طبق مدل Simulink) =========
Ts1    = 0.01;  noise1 = 0.005;  P1 = 0.7;
Ts2    = 0.03;  noise2 = 0.010;  P2 = 0.5;
Ts3    = 0.05;  noise3 = 0.020;  P3 = 0.3;

Pkt1 = 1/Ts1;
Pkt2 = 1/Ts2;
Pkt3 = 1/Ts3;

%% ========= 2) وزن‌های معیارها (قابل تنظیم برای رساله) =========
wV     = 0.30;   % اهمیت دقت ولتاژ
wG     = 0.20;   % اهمیت دقت تابش
wE     = 0.20;   % اهمیت انرژی
wPkt   = 0.10;   % اهمیت نرخ ارسال
wSNR   = 0.10;   % اهمیت SNR
wDelay = 0.10;   % اهمیت Delay

%% ========= 3) خواندن داده‌ها از Workspace =========
Vpv_log = evalin('base','Vpv_log');
V1_log  = evalin('base','V1_log');
V2_log  = evalin('base','V2_log');
V3_log  = evalin('base','V3_log');
G_log   = evalin('base','G_log');

E1_log  = evalin('base','E1_log');
E2_log  = evalin('base','E2_log');
E3_log  = evalin('base','E3_log');

if evalin('base','exist(''t'',''var'')')
    t_full = evalin('base','t(:)');
elseif evalin('base','exist(''tout'',''var'')')
    t_full = evalin('base','tout(:)');
else
    error('متغیر t یا tout در Workspace وجود ندارد.');
end

Vpv = Vpv_log(:);
G    = G_log(:);
t_end = t_full(end);

V1 = V1_log(:);   N1 = length(V1);
V2 = V2_log(:);   N2 = length(V2);
V3 = V3_log(:);   N3 = length(V3);

t1 = linspace(0, t_end, N1).';
t2 = linspace(0, t_end, N2).';
t3 = linspace(0, t_end, N3).';

%% ========= 4) RMSE ولتاژ =========
Vpv1 = interp1(t_full, Vpv, t1, 'linear','extrap');
Vpv2 = interp1(t_full, Vpv, t2, 'linear','extrap');
Vpv3 = interp1(t_full, Vpv, t3, 'linear','extrap');

rmseV1 = sqrt(mean((V1 - Vpv1).^2));
rmseV2 = sqrt(mean((V2 - Vpv2).^2));
rmseV3 = sqrt(mean((V3 - Vpv3).^2));

%% ========= 5) RMSE تابش =========
G1 = interp1(t_full, G, t1, 'previous');
G2 = interp1(t_full, G, t2, 'previous');
G3 = interp1(t_full, G, t3, 'previous');

Gpv1 = interp1(t_full, G, t1, 'linear','extrap');
Gpv2 = interp1(t_full, G, t2, 'linear','extrap');
Gpv3 = interp1(t_full, G, t3, 'linear','extrap');

rmseG1 = sqrt(mean((G1 - Gpv1).^2));
rmseG2 = sqrt(mean((G2 - Gpv2).^2));
rmseG3 = sqrt(mean((G3 - Gpv3).^2));

%% ========= 6) انرژی، نرخ ارسال، SNR و Delay =========
E1 = E1_log(end);
E2 = E2_log(end);
E3 = E3_log(end);

Pkt_vec  = [Pkt1 Pkt2 Pkt3];

% اگر بعداً 5G_Link اضافه شد، این دو بردار را در Workspace تعریف می‌کنیم
if evalin('base','exist(''SNR_nodes'',''var'')')
    SNR_nodes = evalin('base','SNR_nodes');
else
    SNR_nodes = [10 10 10];   % مقدار یکسان موقت
end

if evalin('base','exist(''Delay_nodes'',''var'')')
    Delay_nodes = evalin('base','Delay_nodes');
else
    Delay_nodes = [0.01 0.01 0.01];  % مقدار یکسان موقت
end

%% ========= 7) ساخت بردار معیارها =========
errV   = [rmseV1 rmseV2 rmseV3];   % کوچکتر بهتر
errG   = [rmseG1 rmseG2 rmseG3];   % کوچکتر بهتر
E_vec  = [E1 E2 E3];               % کوچکتر بهتر
SNRvec = SNR_nodes(:).';           % بزرگ‌تر بهتر
D_vec  = Delay_nodes(:).';         % کوچکتر بهتر

%% ========= 8) نرمال‌سازی به صورت Benefit (0..1) =========
epsv = 1e-12;

% معیارهای "هزینه" (کمتر → بهتر)
bV   = benefit_cost(errV, epsv);
bG   = benefit_cost(errG, epsv);
bE   = benefit_cost(E_vec, epsv);
bD   = benefit_cost(D_vec, epsv);

% معیارهای "سود" (بیشتر → بهتر)
bPkt = benefit_gain(Pkt_vec, epsv);
bSNR = benefit_gain(SNRvec, epsv);

%% ========= 9) امتیاز نهایی هر نود =========
Score = wV*bV + wG*bG + wE*bE + wPkt*bPkt + wSNR*bSNR + wDelay*bD;

[Score_best, idx_best] = max(Score);
bestNode = idx_best;

%% ========= 10) چاپ جدول در Command Window =========
fprintf('\n===== Multi-Criteria Node Evaluation =====\n');
fprintf('Node  RMSE_V   RMSE_G   E[J]    Pkt[1/s]   SNR[dB]  Delay[s]   Score\n');
for k = 1:3
    fprintf('%4d  %7.4f  %7.4f  %7.4f  %9.2f  %8.2f  %8.4f  %7.4f\n', ...
        k, errV(k), errG(k), E_vec(k), Pkt_vec(k), SNRvec(k), D_vec(k), Score(k));
end
fprintf('==> Best Node (multi-criteria) = Node %d, Score = %.4f\n\n', bestNode, Score_best);

%% ========= 11) پیدا کردن نقاط عطف تابش =========
dG = diff(G);
idx_ch = find(abs(dG) > 1e-3) + 1;
t_ch   = t_full(idx_ch);
G_ch   = G(idx_ch);

%% ========= 12) شکل 1 - ولتاژ PV و نودهای IoT =========
figure;
hold on; grid on;

plot(t_full, Vpv, 'Color',[1 1 0], 'LineWidth', 1.5);      % PV زرد
plot(t1, V1, 'Color',[0 1 0], 'LineWidth', 1.2);           % Node1 سبز
plot(t2, V2, 'Color',[0 0 1], 'LineWidth', 1.2);           % Node2 آبی
plot(t3, V3, 'Color',[1 0 0], 'LineWidth', 1.2);           % Node3 قرمز

xlabel('Time (s)', 'FontSize', 14);
ylabel('Voltage (V)', 'FontSize', 14);
title('PV Voltage vs. IoT Nodes (Multi-Criteria)', 'FontSize', 16);

leg1 = 'V_{PV} (Real)';
leg2 = sprintf('Node1: Ts=%.3f, noise=%.3f, P=%.2f', Ts1, noise1, P1);
leg3 = sprintf('Node2: Ts=%.3f, noise=%.3f, P=%.2f', Ts2, noise2, P2);
leg4 = sprintf('Node3: Ts=%.3f, noise=%.3f, P=%.2f', Ts3, noise3, P3);
lg = legend(leg1, leg2, leg3, leg4, 'Location','best');
set(lg,'FontSize',12);
set(gca,'FontSize',13);

% متن بهترین نود با خلاصه معیارها
yl = ylim; xl = xlim;
xtext = xl(1) + 0.05*(xl(2)-xl(1));
ytext = yl(2) - 0.10*(yl(2)-yl(1));

txt = sprintf(['Best Node (multi-criteria): Node %d\n', ...
               'Score=%.3f, RMSE_V=%.3f, E=%.3f J,\nPkt=%.1f 1/s, SNR=%.1f dB, Delay=%.4f s'], ...
               bestNode, Score_best, errV(bestNode), E_vec(bestNode), ...
               Pkt_vec(bestNode), SNRvec(bestNode), D_vec(bestNode));

text(xtext, ytext, txt, ...
    'FontSize', 11, 'FontWeight', 'bold', 'Color', 'w', ...
    'BackgroundColor', [0 0 0 0.7]);

% خطوط عمودی نقاط تغییر تابش
for k = 1:numel(t_ch)
    xline(t_ch(k),'--k','LineWidth',1);
    text(t_ch(k), yl(1)+0.05*(yl(2)-yl(1)), ...
        sprintf('  ΔG @ %.2fs', t_ch(k)), ...
        'Rotation',90, 'VerticalAlignment','bottom', ...
        'FontSize',10, 'Color','k');
end

hold off;

%% ========= 13) شکل 2 - تابش PV و نودهای IoT =========
figure;
hold on; grid on;

plot(t_full, G, 'Color',[1 1 0], 'LineWidth', 1.5);      % PV زرد
plot(t1, G1, 'Color',[0 1 0], 'LineWidth', 1.2);         % Node1 سبز
plot(t2, G2, 'Color',[0 0 1], 'LineWidth', 1.2);         % Node2 آبی
plot(t3, G3, 'Color',[1 0 0], 'LineWidth', 1.2);         % Node3 قرمز

xlabel('Time (s)', 'FontSize', 14);
ylabel('Irradiance (W/m^2)', 'FontSize', 14);
title('Irradiance G vs. IoT Nodes', 'FontSize', 16);

ylim([550 1050]);
legG1 = 'G (Real)';
legG2 = sprintf('G_{Node1} (Ts=%.3f)', Ts1);
legG3 = sprintf('G_{Node2} (Ts=%.3f)', Ts2);
legG4 = sprintf('G_{Node3} (Ts=%.3f)', Ts3);
lg2 = legend(legG1, legG2, legG3, legG4, 'Location','best');
set(lg2,'FontSize',12);
set(gca,'FontSize',13);

yl2 = ylim;
for k = 1:numel(t_ch)
    xline(t_ch(k),'--k','LineWidth',1);
    plot(t_ch(k), G_ch(k), 'ko','MarkerFaceColor','k','MarkerSize',5);
    text(t_ch(k), G_ch(k)+15, sprintf('%.2f s', t_ch(k)), ...
        'HorizontalAlignment','center', 'FontSize',11, 'Color','k');
end

hold off;

end

%% ====== توابع کمکی نرمال‌سازی ======
function b = benefit_cost(x, epsv)
% x: معیار هزینه (کمتر بهتر)
x = x(:).';
if max(x)-min(x) < epsv
    b = ones(size(x));
else
    b = (max(x) - x) ./ (max(x) - min(x) + epsv);
end
end

function b = benefit_gain(x, epsv)
% x: معیار سود (بیشتر بهتر)
x = x(:).';
if max(x)-min(x) < epsv
    b = ones(size(x));
else
    b = (x - min(x)) ./ (max(x) - min(x) + epsv);
end
end
