%% train_MCS_ML.m
clc;
fprintf('=== Training ML model for MCS selection ===\n');

load('MCS_dataset.mat','X','Y');

% shuffle
idx = randperm(size(X,1));
X = X(idx,:);
Y = Y(idx);

% train/test split
N  = size(X,1);
Nt = round(0.8*N);
Xtr = X(1:Nt,:);  Ytr = Y(1:Nt);
Xts = X(Nt+1:end,:); Yts = Y(Nt+1:end);

% یک مدل Ensemble ساده (Random Forest سبک)
t = templateTree('MinLeafSize',10);
mdl = fitcensemble(Xtr, Ytr, ...
    'Method','Bag', ...
    'NumLearningCycles',50,...
    'Learners',t);

% ارزیابی
Ypred = predict(mdl,Xts);
acc = mean(Ypred == Yts);
fprintf('Test accuracy: %.2f %%\n', 100*acc);

% ذخیره مدل
save('MCS_ML_model.mat','mdl');
fprintf('✅ Model saved to MCS_ML_model.mat\n');
