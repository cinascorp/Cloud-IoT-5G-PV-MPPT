%% ===== Stage 2B: split + train ANN (Vref = V_MPP) =====
X = [ds.V, ds.I, ds.G, ds.T];    % ورودی‌ها
Y = ds.V_MPP(:);                 % برچسب

% نرمال‌سازی دستی (چون لایه ورودی را بدون نرمال‌سازی می‌گذاریم)
muX = mean(X,1);  sigX = std(X,[],1) + 1e-9;
Xn  = (X - muX) ./ sigX;

% --- تقسیم براساس segment: با 4 سگمنت → 2train / 1val / 1test ---
uSeg = unique(ds.seg);
rng('default');
uSeg = uSeg(randperm(numel(uSeg)));   % shuffle

trSeg = uSeg(1:2);
vaSeg = uSeg(3);
teSeg = uSeg(4);

isTr = ismember(ds.seg, trSeg);
isVa = ismember(ds.seg, vaSeg);
isTe = ismember(ds.seg, teSeg);

Xtr = Xn(isTr,:);  Ytr = Y(isTr);
Xva = Xn(isVa,:);  Yva = Y(isVa);
Xte = Xn(isTe,:);  Yte = Y(isTe);

fprintf('Segments -> Train:%d  Val:%d  Test:%d  (Total:%d)\n', numel(trSeg),1,1,numel(uSeg));
fprintf('Samples  -> Train:%d  Val:%d  Test:%d\n', size(Xtr,1), size(Xva,1), size(Xte,1));

% --- شبکه رگرسیون ---
layers = [
    featureInputLayer(size(Xtr,2), 'Normalization','none')
    fullyConnectedLayer(128)
    reluLayer
    dropoutLayer(0.05)
    fullyConnectedLayer(64)
    reluLayer
    fullyConnectedLayer(1)      % یک خروجی: Vref
    regressionLayer
];

options = trainingOptions('adam', ...
    'InitialLearnRate',1e-3, ...
    'MaxEpochs',80, ...
    'MiniBatchSize',2048, ...
    'Shuffle','every-epoch', ...
    'ValidationData',{Xva, Yva}, ...
    'ValidationPatience',10, ...
    'Verbose',false);

net_vref = trainNetwork(Xtr, Ytr, layers, options);

% --- ارزیابی ---
MAE  = @(a,b) mean(abs(a-b));
RMSE = @(a,b) sqrt(mean((a-b).^2));

Yhat_tr = predict(net_vref, Xtr);
Yhat_va = predict(net_vref, Xva);
Yhat_te = predict(net_vref, Xte);

fprintf('Train  MAE=%.3f V, RMSE=%.3f V\n', MAE(Ytr,Yhat_tr), RMSE(Ytr,Yhat_tr));
fprintf('Val    MAE=%.3f V, RMSE=%.3f V\n', MAE(Yva,Yhat_va), RMSE(Yva,Yhat_va));
fprintf('Test   MAE=%.3f V, RMSE=%.3f V\n', MAE(Yte,Yhat_te), RMSE(Yte,Yhat_te));

save('ann_vref_net.mat','net_vref','muX','sigX');

figure('Name','ANN Vref Fit','Color','w');
subplot(2,1,1); plot(Yte,'-'); hold on; plot(Yhat_te,'--'); grid on;
legend('Y_{true}','Y_{pred}'); title('Test set V_{MPP} tracking'); ylabel('V');
subplot(2,1,2); plot(Yte - Yhat_te); grid on; ylabel('Error [V]'); xlabel('samples');
