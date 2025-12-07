%% train_cloud_ann_best_normalized.m
clear; clc;

load dataset_best   % X [N x 12], y [N x 1]

% --- حذف نمونه‌های خراب ---
bad = any(~isfinite(X),2) | ~isfinite(y);
X(bad,:) = [];
y(bad)   = [];

% --- شافل ---
rng(0);
N = size(X,1);
idx = randperm(N);
X = X(idx,:);
y = y(idx);

% --- نرمال‌سازی (فقط روی X) ---
mu    = mean(X,1);
sigma = std(X,[],1) + 1e-6;
Xn = (X - mu) ./ sigma;

% --- آماده‌سازی ---
Xn = Xn.';        % [12 x N]
numClasses = 3;   % ولی بعداً ما فقط از کلاس 1 و 2 استفاده می‌کنیم
inputSize  = 12;

Y = zeros(numClasses, N);
for i = 1:N
    if y(i) < 1 || y(i) > 3
        continue;
    end
    Y(y(i), i) = 1;
end

% --- init وزن‌ها (softmax linear) ---
W = 0.01*randn(numClasses, inputSize);
b = zeros(numClasses,1);

lr     = 0.01;
epochs = 300;

for ep = 1:epochs
    scores = W*Xn + b;
    scores_shift = scores - max(scores,[],1);
    exp_scores = exp(scores_shift);
    probs = exp_scores ./ sum(exp_scores,1);

    % cross-entropy
    loss = -mean(log(sum(probs.*Y,1) + 1e-12));

    ds = probs - Y;
    dW = (ds * Xn.') / N;
    db = mean(ds,2);

    W = W - lr*dW;
    b = b - lr*db;

    if mod(ep,25)==0
        [~,pred] = max(probs,[],1);
        acc = mean(pred'==y);
        fprintf('Epoch %3d | Loss=%.4f | Acc=%.2f%%\n',ep,loss,acc*100);
    end
end

save cloud_ann_weights W b mu sigma
disp('✅ آموزش جدید با نرمال‌سازی انجام شد و ذخیره گردید');
