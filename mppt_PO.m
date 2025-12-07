function D = mppt_PO(Vpv, Ipv)
% MPPT با روش Perturb & Observe برای مبدل بوست
% ورودی‌ها:
%   Vpv : ولتاژ پنل خورشیدی (ولت)
%   Ipv : جریان پنل خورشیدی (آمپر)
% خروجی:
%   D   : نسبت سیکل کاری (0 تا 1)

    % متغیرهای پایا (برای ذخیره مقدار قبلی)
    persistent V_prev P_prev D_prev initFlag

    % مقداردهی اولیه در اولین اجرای تابع
    if isempty(initFlag)
        V_prev   = 0;
        P_prev   = 0;
        D_prev   = 0.5;   % مقدار اولیه Duty Cycle (نقطه میانی)
        initFlag = 1;
    end

    % محاسبه توان لحظه‌ای پنل
    P = Vpv * Ipv;

    % اختلافات
    dP = P - P_prev;
    dV = Vpv - V_prev;

    % گام تغییر نسبت سیکل کاری (قابل تنظیم)
    deltaD = 0.005;   % مثلاً 0.5 درصد

    % الگوریتم P&O
    if dP > 0
        % اگر توان زیاد شده:
        if dV > 0
            % ولتاژ هم زیاد شده → در جهت تغییر قبلی ادامه بده (افزایش D)
            D = D_prev + deltaD;
        elseif dV < 0
            % ولتاژ کم شده → در جهت تغییر قبلی ادامه بده (کاهش D)
            D = D_prev - deltaD;
        else
            % تغییر ولتاژ صفر → همان Duty قبلی
            D = D_prev;
        end
    elseif dP < 0
        % اگر توان کم شده، جهت تغییر را معکوس کن
        if dV > 0
            % ولتاژ زیاد شده اما توان کم شده → کاهش D
            D = D_prev - deltaD;
        elseif dV < 0
            % ولتاژ کم شده اما توان کم شده → افزایش D
            D = D_prev + deltaD;
        else
            % تغییر ولتاژ صفر → همان Duty قبلی
            D = D_prev;
        end
    else
        % dP == 0 → در نقطه بیشینه یا نزدیک آن هستیم
        D = D_prev;
    end

    % اشباع Duty Cycle بین 0 و 1
    if D > 0.95
        D = 0.95;
    elseif D < 0.05
        D = 0.05;
    end

    % به‌روزرسانی مقادیر قبلی
    V_prev = Vpv;
    P_prev = P;
    D_prev = D;
end
