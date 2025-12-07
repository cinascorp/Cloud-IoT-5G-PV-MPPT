function Vref = svm_predict_wrapper(Vpv, Ipv, G, T)
% svm_predict_wrapper
%  - اگر 1 ورودی داشته باشی: u = [V I G T]
%  - اگر 4 ورودی داشته باشی: Vpv, Ipv, G, T جداگانه

persistent Mdl
if isempty(Mdl)
    S = load('svm_vref_Mdl.mat','Mdl');
    Mdl = S.Mdl;
end

% تشخیص نوع ورودی
if nargin == 1
    % حالت یک ورودی برداری: u = [V I G T]
    u = Vpv;              % نام آرگومان، ولی درواقع کل برداره
    u = reshape(u,1,4);   % تبدیل به 1x4
elseif nargin == 4
    % حالت چهار ورودی اسکالر
    u = [Vpv, Ipv, G, T]; % 1x4
else
    error('svm_predict_wrapper: تعداد ورودی باید 1 (بردار) یا 4 (اسکالر) باشد.');
end

Vref = predict(Mdl, u);
end
