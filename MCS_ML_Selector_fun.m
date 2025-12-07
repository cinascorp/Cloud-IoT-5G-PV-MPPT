function MCS_idx = MCS_ML_Selector_fun(SNR_dB, Delay5G_s, PLR)

    persistent mdl
    if isempty(mdl)
        s = load('MCS_ML_model.mat','mdl');
        mdl = s.mdl;
    end

    % Feature vector: [SNR(dB), Delay(ms), PLR]
    X = [SNR_dB, Delay5G_s*1e3, PLR];

    mcs_hat = predict(mdl, X);

    MCS_idx = round(mcs_hat);
    if MCS_idx < 0
        MCS_idx = 0;
    elseif MCS_idx > 13      % اگر حداکثر MCS=13 است
        MCS_idx = 13;
    end
end
