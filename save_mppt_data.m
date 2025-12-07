% save_mppt_data.m
% ذخیره‌ی امن داده‌های MPPT بدون خطا حتی اگر بعضی متغیرها وجود نداشته باشند

filename = 'mppt_data_all.mat';

vars = {};

% --- Power signals ---
if exist('Power_PO','var'),  vars{end+1} = 'Power_PO';  end
if exist('Power_SVM','var'), vars{end+1} = 'Power_SVM'; end
if exist('Power_ANN','var'), vars{end+1} = 'Power_ANN'; end

% --- Duty signals ---
if exist('D_PO','var'),  vars{end+1} = 'D_PO';  end
if exist('D_SVM','var'), vars{end+1} = 'D_SVM'; end
if exist('D_ANN','var'), vars{end+1} = 'D_ANN'; end

% --- Time vector ---
if exist('tout','var')
    time = tout; %#ok<NASGU>
    vars{end+1} = 'time';
elseif exist('T','var')
    time = T; %#ok<NASGU>
    vars{end+1} = 'time';
end

% اگر هیچ دیتایی پیدا نشد
if isempty(vars)
    warning('هیچ داده‌ای با نام Power/Duty پیدا نشد. چیزی ذخیره نشد.');
    return;
end

% ذخیره‌ی امن
save(filename, vars{:});

disp('✅ پارامترهای موجود MPPT در فایل mppt_data_all.mat ذخیره شدند:');
disp(vars');
