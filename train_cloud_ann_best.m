%% train_cloud_ann_best.m
clear; clc;

% 1) لود دیتاست علمی
load dataset_best  % X [N x 12], y [N x 1] با مقادیر 1,2,3

X = X.';           % حالا X: [12 x N]
N = size(X,2);
numClasses = 3;
inputSize  = 12;

% 2) شافل کردن نمونه‌ها (برای آموزش بهتر)
rng(0);                    % برای تکرارپذیری
perm = randperm(N);
X = X(:,perm);
y = y(perm);

% 3) ساخت برچسب One-Hot → Y_onehot: [3 x N]
Y_onehot = zeros(numClasses, N);
for i = 1:N
    Y_onehot(y(i), i) = 1;
end

% 4) مقداردهی اولیه‌ی وزن‌ها
W = 0.01 * randn(numClasses, inputSize);   % [3 x 12]
b = zeros(numClasses,1);                   % [3 x 1]

learningRate = 0.01;
numEpochs    = 200;

for epoch = 1:numEpochs
    % --- forward ---
    scores       = W * X + b;                  % [3 x N]
    scores_shift = scores - max(scores, [], 1);% برای پایداری عددی
    exp_scores   = exp(scores_shift);
    probs        = exp_scores ./ sum(exp_scores, 1);  % softmax → [3 x N]

    % --- loss (cross-entropy) فقط برای مانیتور ---
    log_probs = -log(sum(probs .* Y_onehot, 1) + 1e-12);
    loss      = mean(log_probs);

    % --- gradient ---
    dscores = probs - Y_onehot;            % [3 x N]
    dW      = (dscores * X.') / N;         % [3 x 12]
    db      = mean(dscores, 2);            % [3 x 1]

    % --- update ---
    W = W - learningRate * dW;
    b = b - learningRate * db;

    if mod(epoch, 20) == 0
        % محاسبه دقت روی همین داده برای دیدن روند
        [~, y_pred] = max(probs, [], 1);
        acc = mean( y_pred.' == y );
        fprintf('epoch %3d: loss = %.4f, acc = %.2f%%\n', ...
                 epoch, loss, acc*100);
    end
end

% 5) ذخیره وزن‌ها برای استفاده در سیمولینک
save cloud_ann_weights W b
disp('✅ آموزش تمام شد، W و b در cloud_ann_weights.mat ذخیره شد');
