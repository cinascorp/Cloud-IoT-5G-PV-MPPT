%% make_svm_dataset.m
% ساخت دیتاست برای SVM از جدول ds

disp("🔄 در حال ساخت دیتاست SVM ...");

% اگر ds وجود ندارد، دوباره آن را بساز
if ~exist('ds','var')
    if exist('step2dataset.m','file')
        disp("➡️ اجرای step2dataset برای ساخت ds ...");
        step2dataset;
    else
        error("❌ فایل step2dataset.m پیدا نشد.");
    end
end

% بررسی اینکه ds یک جدول است
if ~istable(ds)
    error("❌ ds باید یک جدول (table) باشد.");
end

% بررسی وجود ستون‌ها
requiredCols = {'V','I','G','T','V_MPP'};
for k = 1:length(requiredCols)
    if ~ismember(requiredCols{k}, ds.Properties.VariableNames)
        error("❌ ستون '%s' در ds وجود ندارد.", requiredCols{k});
    end
end

% ساخت ورودی‌ها: 4 ویژگی اصلی
X = [ds.V, ds.I, ds.G, ds.T];

% ساخت خروجی: ولتاژ MPP واقعی
Y = ds.V_MPP;

% ذخیره دیتاست
save svm_dataset.mat X Y ds

disp("✅ svm_dataset.mat ساخته شد.");
fprintf("   تعداد نمونه‌ها: %d\n", size(X,1));
