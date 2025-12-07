%% ====================  Stage 2A : Build Dataset  ====================

% 1) استخراج بردار زمان
if ~exist('tout','var')
    error('Variable tout does not exist. Make sure you logged tout.');
end
t = tout(:);

% 2) تابع کمکی برای استخراج از timeseries
ts2vec = @(ts) interp1(ts.Time(:), ts.Data(:), t, 'linear', 'extrap');

try
    V  = ts2vec(V_PV);
    I  = ts2vec(I_PV);
    Gv = ts2vec(G);
    Tv = ts2vec(T);
    Dr = ts2vec(D_r);
catch
    error('One of the variables (V_PV, I_PV, G, T, D_r) is missing or not a timeseries.');
end

% 3) توان
P = V .* I;

% 4) تشخیص پله‌های تابش
win = 501;  % اگر Ts خیلی کوچک است، پایین‌تر هم قابل تنظیم است
G_s = movmedian(Gv, win);
dG  = [0; abs(diff(G_s))];
thG = 0.01 * max(G_s);
edges = [1; find(dG > thG); numel(t)+1];

% 5) ساخت برچسب V_MPP ساده
V_MPP = nan(size(t));
seg_id = nan(size(t));

for k = 1:numel(edges)-1
    a = edges(k);
    b = edges(k+1)-1;
    if b <= a, continue; end

    [~, idxLoc] = max(P(a:b));
    idxStar = a + idxLoc - 1;

    V_MPP(a:b) = V(idxStar);
    seg_id(a:b) = k;
end

% 6) حذف NaN
valid = isfinite(V) & isfinite(I) & isfinite(Gv) & isfinite(Tv) & isfinite(V_MPP);
t  = t(valid);
V  = V(valid);
I  = I(valid);
Gv = Gv(valid);
Tv = Tv(valid);
P  = P(valid);
seg_id = seg_id(valid);
V_MPP = V_MPP(valid);

% 7) ساخت جدول نهایی دیتاست
ds = table(t, V, I, Gv, Tv, P, seg_id, V_MPP, ...
    'VariableNames', {'t','V','I','G','T','P','seg','V_MPP'});

% 8) گزارش
fprintf('✅ Dataset created successfully.\n');
fprintf('   Samples: %d\n', height(ds));
fprintf('   Segments detected: %d\n', numel(unique(ds.seg)));

disp('---- First rows of ds ----');
disp(ds(1:min(10,height(ds)), :));
