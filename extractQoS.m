function qos = extractQoS()
%EXTRACTQOS  استخراج و خلاصه‌سازی SNR / Delay / PacketLoss از شبکه
% فرض: بعد از اجرای sim، متغیرهای زیر در Workspace موجودند:
%  SNR_Node1, SNR_Node2, SNR_Node3
%  Delay5G_Node1, Delay5G_Node2, Delay5G_Node3
%  PL_Node1, PL_Node2, PL_Node3

    qos = struct();

    % ---------- Node 1 ----------
    qos.Node1.SNR_all    = SNR_Node1(:);
    qos.Node1.Delay_all  = Delay5G_Node1(:);
    qos.Node1.PL_all     = PL_Node1(:);

    qos.Node1.SNR_mean   = mean(qos.Node1.SNR_all);
    qos.Node1.SNR_min    = min(qos.Node1.SNR_all);
    qos.Node1.SNR_max    = max(qos.Node1.SNR_all);

    qos.Node1.Delay_mean = mean(qos.Node1.Delay_all);
    qos.Node1.Delay_max  = max(qos.Node1.Delay_all);

    qos.Node1.PL_mean    = mean(qos.Node1.PL_all);
    qos.Node1.PL_max     = max(qos.Node1.PL_all);

    % ---------- Node 2 ----------
    qos.Node2.SNR_all    = SNR_Node2(:);
    qos.Node2.Delay_all  = Delay5G_Node2(:);
    qos.Node2.PL_all     = PL_Node2(:);

    qos.Node2.SNR_mean   = mean(qos.Node2.SNR_all);
    qos.Node2.SNR_min    = min(qos.Node2.SNR_all);
    qos.Node2.SNR_max    = max(qos.Node2.SNR_all);

    qos.Node2.Delay_mean = mean(qos.Node2.Delay_all);
    qos.Node2.Delay_max  = max(qos.Node2.Delay_all);

    qos.Node2.PL_mean    = mean(qos.Node2.PL_all);
    qos.Node2.PL_max     = max(qos.Node2.PL_all);

    % ---------- Node 3 ----------
    qos.Node3.SNR_all    = SNR_Node3(:);
    qos.Node3.Delay_all  = Delay5G_Node3(:);
    qos.Node3.PL_all     = PL_Node3(:);

    qos.Node3.SNR_mean   = mean(qos.Node3.SNR_all);
    qos.Node3.SNR_min    = min(qos.Node3.SNR_all);
    qos.Node3.SNR_max    = max(qos.Node3.SNR_all);

    qos.Node3.Delay_mean = mean(qos.Node3.Delay_all);
    qos.Node3.Delay_max  = max(qos.Node3.Delay_all);

    qos.Node3.PL_mean    = mean(qos.Node3.PL_all);
    qos.Node3.PL_max     = max(qos.Node3.PL_all);
end
