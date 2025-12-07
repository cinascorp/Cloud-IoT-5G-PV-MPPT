function [Mode_out, Selected_Node, Final_Cost] = Cloud_MPPT_Selector(...
    SNR_dB, MCS_index, SE_eff, Throughput_bps, Delay_5G, PacketLost, Energy_5G, ...
    V_pv, I_pv, G_solar, TxRate_iot, Energy_iot, Delay_iot)
% Cloud_MPPT_Selector  -- آماده برای Simulink Coder
% Hybrid AHP + CRITIC weighting  + VIKOR ranking
%
% Outputs:
%   Mode_out      : uint8 scalar {1=SVM, 2=ANN, 3=P&O}
%   Selected_Node : uint8 scalar {1,2,3}
%   Final_Cost    : double scalar (higher better, approx 0..1)
%
% IMPORTANT:
% - Do NOT change output variable types. Simulink expects fixed-size outputs.
% - If TxRate_iot / Energy_iot / Delay_iot are scalars, they will be replicated for 3 nodes.
%
% TUNABLE PARAMETERS (edit if desired):
%   alpha = 0.5    -> weight for AHP vs CRITIC in hybrid weighting
%   v     = 0.5    -> VIKOR balance coefficient (0..1)
%   ref_PV_power  -> normalization reference for PV power (W)
%   ref_net_throughput -> normalization reference for net throughput (bps)

% -------------------- Parameters / Tunables --------------------
coder.extrinsic('disp'); %#ok<*NASGU>
alpha = 0.5;               % weight of subjective (AHP) relative to objective (CRITIC)
v = 0.5;                   % VIKOR trade-off parameter (0..1)
ref_PV_power = 1000;       % W (for normalization)
ref_net_throughput = 1e7;  % bps (for normalization)
ref_energy5g = 10;         % J or arbitrary energy ref

% -------------------- Input sanitation & fixed-size enforcement --------------------
% Ensure numeric scalars for Simulink codegen
SNR_dB        = double(SNR_dB(1));
MCS_index     = double(MCS_index(1));
SE_eff        = double(SE_eff(1));
Throughput_bps= double(Throughput_bps(1));
Delay_5G      = double(Delay_5G(1));
PacketLost    = double(PacketLost(1));
Energy_5G     = double(Energy_5G(1));
V_pv          = double(V_pv(1));
I_pv          = double(I_pv(1));
G_solar       = double(G_solar(1));

% IoT vectors: make length-3 vectors (if scalar replicate, if length>=3 truncate)
TxRate_iot = make_len3_vector(TxRate_iot);
Energy_iot = make_len3_vector(Energy_iot);
Delay_iot  = make_len3_vector(Delay_iot);

% clamp PacketLost between 0 and 1
PacketLost = min(max(PacketLost,0),1);

% -------------------- Derived normalized indicators (scalars) --------------------
PV_power = V_pv * I_pv;                       % instantaneous PV power (W)
pv_norm  = min(max(PV_power / ref_PV_power, 0), 1);   % 0..1
G_norm   = min(max(G_solar / 1000, 0), 1);            % irradiance normalized 0..1

net_q = Throughput_bps * (1 - PacketLost) * max(SE_eff, 1e-12);
net_q_norm = min(max(net_q / ref_net_throughput, 0), 1);

latency_score = 1 / (1 + Delay_5G);           % higher better
lat_norm = min(max(latency_score, 0), 1);

energy5g_norm = min(max(Energy_5G / ref_energy5g, 0), 1);

% -------------------- Heuristic estimates for each MPPT method (scalars) --------------------
% Values in [0,1] representing relative performance on each criterion.

% ANN: high accuracy in nonlinear/PSC, higher compute
ann_acc   = 0.95 * (0.6*pv_norm + 0.4*G_norm) * (0.7 + 0.3*net_q_norm);
ann_speed = 0.9  * (0.6*net_q_norm + 0.4*lat_norm);
ann_rob   = 0.95 * (1 - PacketLost) * (0.5 + 0.5*G_norm);

% SVM: robust, medium compute
svm_acc   = 0.85 * (0.5*pv_norm + 0.5*G_norm) * (0.6 + 0.4*net_q_norm);
svm_speed = 0.85 * (0.5*net_q_norm + 0.5*lat_norm);
svm_rob   = 0.80 * (1 - PacketLost) * (0.5 + 0.5*G_norm);

% P&O: lightweight, low compute, less robust under PSC
po_acc    = 0.65 * pv_norm * (1 - 0.5*PacketLost);
po_speed  = 0.60 * lat_norm;  % independent/local method
po_rob    = 0.55 * (1 - PacketLost) * pv_norm;

% Computation/Energy benefit (higher = cheaper)
comp_SVM = 0.6 * energy5g_norm;
comp_ANN = 0.4 * energy5g_norm;
comp_PO  = 0.95 * (1 - energy5g_norm) + 0.05;

% Network dependency benefit (higher = less risky)
net_SVM = 0.6 * (1 - PacketLost);
net_ANN = 0.5 * (1 - PacketLost);
net_PO  = 0.95 * (1 - PacketLost);

% -------------------- Decision matrix D (3 alternatives x 5 criteria) --------------------
% Criteria order:
%  C1 = Tracking Efficiency (higher better)
%  C2 = Convergence/Settling Speed
%  C3 = Robustness under irradiance/PSC
%  C4 = Computation/Energy Benefit (higher better)
%  C5 = Network Dependency Benefit (higher better)

D = [
    svm_acc, svm_speed, svm_rob, comp_SVM, net_SVM;
    ann_acc, ann_speed, ann_rob, comp_ANN, net_ANN;
    po_acc,  po_speed,  po_rob,  comp_PO,  net_PO
];

% ensure within 0..1
D = min(max(D, 0), 1);

% -------------------- AHP (subjective) weights --------------------
% Default pairwise matrix A for criteria [C1 C2 C3 C4 C5]
% (Saaty scale). You can modify A based on advisor / paper specifics.
A = [ 1    2    3    4    3;
      1/2  1    2    3    2;
      1/3  1/2  1    2    1.5;
      1/4  1/3  1/2  1    1/2;
      1/3  1/2  2/3  2    1 ];

% compute principal eigenvector as AHP weights
[w_ahp, CR] = ahp_weights(A); %#ok<NASGU>

% -------------------- CRITIC (objective) weights --------------------
w_critic = critic_weights(D);  % 1x5

% -------------------- Hybrid final weights --------------------
w_final = alpha * w_ahp + (1 - alpha) * w_critic;  % 1x5
w_final = w_final ./ (sum(w_final) + eps);

% -------------------- VIKOR ranking --------------------
f_star = max(D,[],1);   % best for each criterion
f_minus = min(D,[],1);  % worst

m = size(D,1);
S = zeros(m,1); R = zeros(m,1);
for i = 1:m
    diff = (f_star - D(i,:)) ./ (f_star - f_minus + eps);
    S(i) = sum(w_final .* diff);
    R(i) = max(w_final .* diff);
end

Smin = min(S); Smax = max(S);
Rmin = min(R); Rmax = max(R);

Q = zeros(m,1);
for i = 1:m
    Q(i) = v * (S(i) - Smin) / (Smax - Smin + eps) + ...
           (1 - v) * (R(i) - Rmin) / (Rmax - Rmin + eps);
end

% VIKOR: lower Q is better
[~, idx_best] = min(Q);

% map to outputs (uint8 for Simulink compatibility)
Mode_out = uint8(idx_best);    % 1=SVM, 2=ANN, 3=P&O
Final_Cost = double(1 - Q(idx_best)); % convert lower-is-bad to higher-is-good score ~ (0..1)

% -------------------- Select best IoT node (simple weighted score) --------------------
% Ensure we use length-3 vectors for node selection
tx = double(TxRate_iot(1:3));
bat = double(Energy_iot(1:3));
del = double(Delay_iot(1:3));

% normalize across nodes (avoid division by zero)
tx_n = tx ./ (max(tx) + eps);
bat_n = bat ./ (max(bat) + eps);
del_n = 1 ./ (1 + del);
del_n = del_n ./ (max(del_n) + eps);

% weights for node selection (tunable)
w_tx = 0.50; w_bat = 0.35; w_del = 0.15;
node_score = w_tx*tx_n + w_bat*bat_n + w_del*del_n;

[~, best_node] = max(node_score);
Selected_Node = uint8(best_node(1));  % 1..3

end

% -------------------- Helper functions --------------------

function vec3 = make_len3_vector(x)
% Returns a double 1x3 vector from scalar or vector input
x = double(x);
if isscalar(x)
    vec3 = repmat(x, 1, 3);
else
    x = x(:)'; % row
    n = length(x);
    if n >= 3
        vec3 = x(1:3);
    else
        vec3 = [x, repmat(x(end), 1, 3-n)]; % pad with last value
    end
end
end

function [w, CR] = ahp_weights(A)
% Compute normalized principal eigenvector of A (AHP) and consistency ratio
% A must be square
% returns row vector w (1 x n)
n = size(A,1);
% power method / eig
[V, D] = eig(A);
[~, idx] = max(real(diag(D)));
v = real(V(:, idx));
w = (v ./ sum(v))';
% consistency
lambda_max = real(D(idx, idx));
CI = (lambda_max - n) / (n - 1);
% Random index values for n=1..9
RI_vals = [0, 0, 0.58, 0.90, 1.12, 1.24, 1.32, 1.41, 1.45];
if n <= length(RI_vals)
    RI = RI_vals(n);
else
    RI = RI_vals(end);
end
CR = CI / (RI + eps);
% if CR > 0.10 indicates inconsistent judgments (user can adjust A)
end

function w = critic_weights(X)
% CRITIC method: X is m x n (alternatives x criteria)
% returns 1 x n weights
% normalize columns 0..1
col_min = min(X,[],1);
col_max = max(X,[],1);
Xn = (X - col_min) ./ (col_max - col_min + eps);
std_dev = std(Xn, 0, 1); % 1 x n
R = corrcoef(Xn);
% when m < 2, corrcoef may be ill-defined; handle:
if any(isnan(R(:)))
    R = eye(size(R));
end
conflict = 1 - abs(R);
Cj = zeros(1, size(Xn,2));
for j = 1:size(Xn,2)
    Cj(j) = std_dev(j) * sum(conflict(j,:));
end
% ensure non-negative
Cj = max(Cj, 0);
if sum(Cj) <= eps
    % fallback to equal weights
    w = ones(1, size(Xn,2)) / size(Xn,2);
else
    w = (Cj ./ sum(Cj));
end
end
