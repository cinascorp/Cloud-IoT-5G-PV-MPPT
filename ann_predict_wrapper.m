function Vref = ann_predict_wrapper(x)
% x must be [Vpv, Ipv, G, T] as 1x4 double
persistent net muX sigX isInit

if nargin < 1
    error('ann_predict_wrapper:InputMissing','You must pass x = [Vpv, Ipv, G, T].');
end
x = double(x);
if ~isvector(x) || numel(x)~=4
    error('ann_predict_wrapper:BadSize','x must be a 1x4 vector: [Vpv, Ipv, G, T].');
end

if isempty(isInit)
    S    = load('ann_vref_net.mat','net_vref','muX','sigX');
    net  = S.net_vref;
    muX  = S.muX;
    sigX = S.sigX;
    isInit = true;
end

xn   = (x(:).'-muX)./sigX;   % 1x4
Vref = double(predict(net, xn));
end
