%% TrainSVM.m
% آموزش SVM برای تخمین V_MPP از روی [V, I, G, T]

clc;
disp("🚀 TrainSVM: شروع آموزش SVM برای MPPT ...");

%% 1) بارگذاری دیتاست
load svm_dataset.mat  % شامل X, Y, ds
fprintf("   نمونه‌ها: %d  ویژگی‌ها: %d\n", size(X,1), size(X,2));

%% 2) تقسیم داده به Train / Validation
% 80% آموزش، 20% اعتبارسنجی
cv = cvpartition(size(X,1), 'HoldOut', 0.2);
idxTrain = training(cv);
idxVal   = test(cv);

Xtr = X(idxTrain,:);
Ytr = Y(idxTrain);

Xval = X(idxVal,:);
Yval = Y(idxVal);

fprintf("   Train: %d نمونه  |  Val: %d نمونه\n", size(Xtr,1), size(Xval,1));

%% 3) آموزش SVM رگرسیونی با کرنل RBF
disp("   🔧 در حال آموزش SVM (RBF SVR) ...");

Mdl = fitrsvm(Xtr, Ytr, ...
    'KernelFunction','rbf', ...
    'KernelScale','auto', ...
    'Standardize',true, ...
    'Epsilon',0.003, ...
    'BoxConstraint',200);

disp("   ✅ آموزش تمام شد.");

%% 4) ارزیابی روی Train و Validation

Ytr_hat  = predict(Mdl, Xtr);
Yval_hat = predict(Mdl, Xval);

% خطاها
e_tr  = Ytr  - Ytr_hat;
e_val = Yval - Yval_hat;

MAE_tr  = mean(abs(e_tr));
RMSE_tr = sqrt(mean(e_tr.^2));

MAE_val  = mean(abs(e_val));
RMSE_val = sqrt(mean(e_val.^2));

fprintf("\n📊 نتایج SVM:\n");
fprintf("   Train: MAE = %.4f V , RMSE = %.4f V\n", MAE_tr, RMSE_tr);
fprintf("   Val  : MAE = %.4f V , RMSE = %.4f V\n", MAE_val, RMSE_val);

%% 5) چند نمودار ساده برای کیفیت مدل

figure;
histogram(e_val,50);
grid on;
xlabel('خطای ولتاژ (V_MPP - V_{SVM})'); ylabel('تعداد');
title('Error Histogram (Validation) - SVM MPPT');

figure;
plot(Yval, Yval_hat, '.');
grid on;
xlabel('V_{MPP} واقعی (Val)'); ylabel('V_{MPP} برآوردی توسط SVM');
title('Regression Plot (Validation) - SVM');
refline(1,0);  % خط y=x

%% 6) ذخیره مدل برای استفاده در Simulink
save svm_vref_Mdl.mat Mdl
disp("   💾 مدل SVM در فایل svm_vref_Mdl.mat ذخیره شد.");
disp("✅ TrainSVM تمام شد.");
