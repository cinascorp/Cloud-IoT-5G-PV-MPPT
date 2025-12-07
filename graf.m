%% === فرض: شبکه آموزش دیده و net و tr موجود است ===
% net  --> شبکه آموزش دیده (SeriesNetwork یا شبکه کلاسیک feedforward)
% tr   --> خروجی train() شامل اطلاعات آموزش

% اگر شبکه کلاسیک train() داشتی:
% [net,tr] = train(net, X, T);

%% 1) Error Histogram
figure;
ploterrhist(tr.perf);  % روش ساده، اما اگر دقیق مثل عکس می‌خواهی:

e = gsubtract(net(tr.trainInd), tr.targets(tr.trainInd)); % خطای آموزش
figure;
errhist(e,20);
title('Error Histogram with 20 Bins');

%% 2) Regression Plot (R-value)
figure;
plotregression(tr.targets, net(tr.trainInd));
title(sprintf('Training: R = %.5f', tr.best_regression));

%% 3) Training State (gradient, mu, validation)
figure;
plottrainstate(tr);
title('Training State');

%% 4) Performance (MSE)
figure;
plotperform(tr);
title(sprintf('Best Training Performance = %.7f at epoch %d', ...
               tr.best_perf, tr.best_epoch));
