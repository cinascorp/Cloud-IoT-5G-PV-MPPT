%% build_dataset_MCS.m
clc;
fprintf('=== Building dataset for ML-based MCS selector ===\n');

% لیست متغیرهای لازم
varsNeeded = { ...
    'SNR_Node1','SNR_Node2','SNR_Node3',...
    'MCS_Node1','MCS_Node2','MCS_Node3',...
    'Delay5G_Node1','Delay5G_Node2','Delay5G_Node3',...
    'PL_Node1','PL_Node2','PL_Node3'};

for k = 1:numel(varsNeeded)
    if ~evalin('base',sprintf('exist(''%s'',''var'')',varsNeeded{k}))
        error('⛔ Variable missing in workspace: %s', varsNeeded{k});
    end
end

% مستقیماً به صورت بردار double
S1  = SNR_Node1(:);   S2 = SNR_Node2(:);   S3 = SNR_Node3(:);
M1  = MCS_Node1(:);   M2 = MCS_Node2(:);   M3 = MCS_Node3(:);
D1  = Delay5G_Node1(:); D2 = Delay5G_Node2(:); D3 = Delay5G_Node3(:);
PL1 = PL_Node1(:);    PL2 = PL_Node2(:);   PL3 = PL_Node3(:);

% هم‌طول کردن
lenList = [numel(S1) numel(S2) numel(S3) ...
           numel(M1) numel(M2) numel(M3) ...
           numel(D1) numel(D2) numel(D3) ...
           numel(PL1) numel(PL2) numel(PL3)];

N = min(lenList);
trim = @(x) x(1:N);

S1 = trim(S1); S2 = trim(S2); S3 = trim(S3);
M1 = trim(M1); M2 = trim(M2); M3 = trim(M3);
D1 = trim(D1); D2 = trim(D2); D3 = trim(D3);
PL1 = trim(PL1); PL2 = trim(PL2); PL3 = trim(PL3);

% ویژگی‌ها (X) و برچسب‌ها (Y)
% Feature: [SNR(dB), Delay(ms), PLR]
X = [ ...
    S1, 1e3*D1, PL1; ...
    S2, 1e3*D2, PL2; ...
    S3, 1e3*D3, PL3 ];

Y = [M1; M2; M3];

% حذف NaN
valid = all(~isnan(X),2) & ~isnan(Y);
X = X(valid,:);
Y = Y(valid);

fprintf('Dataset size: %d samples\n', size(X,1));
save('MCS_dataset.mat','X','Y');
fprintf('✅ Saved to MCS_dataset.mat\n');
