clc; clear; close all;

MODEL = 'PV_ANN1';
load_system(MODEL);

%% =========================
% RUN 1: Rule-Based MPPT
%% =========================
disp('🚀 Running Rule-Based MPPT...');

set_param([MODEL '/Controller Selector Switch'], 'sw','0');
sim(MODEL);

[tr, Pr] = get_power_ws();
Mode_rule = evalin('base','Mode_out');
Node_rule = evalin('base','Selected_Node');

Mode_rule = Mode_rule(:);
Node_rule = Node_rule(:);

%% =========================
% RUN 2: AI-Driven MPPT
%% =========================
disp('🤖 Running AI-Driven MPPT...');

set_param([MODEL '/Controller Selector Switch'], 'sw','1');
sim(MODEL);

[ta, Pa] = get_power_ws();
Mode_ai = evalin('base','Mode_out_AI');
Node_ai = evalin('base','Selected_Node_AI');

Mode_ai = Mode_ai(:);
Node_ai = Node_ai(:);

%% =========================
% Shape fix (فقط برابر کردن طول‌ها برای رسم)
%% =========================
N = min([length(Pr), length(Pa), length(Mode_rule), length(Mode_ai)]);

tr = tr(1:N);
ta = ta(1:N);
Pr = Pr(1:N);
Pa = Pa(1:N);

Mode_rule = Mode_rule(1:N);
Mode_ai   = Mode_ai(1:N);
Node_rule = Node_rule(1:N);
Node_ai   = Node_ai(1:N);

%% =========================
% Figure 1: Power comparison
%% =========================
figure;
plot(tr, Pr,'b','LineWidth',2); hold on;
plot(ta, Pa,'r','LineWidth',2);
grid on;
xlabel('Time (s)');
ylabel('PV Output Power (W)');
title('PV Output Power Comparison');
legend('Rule-Based MPPT','AI-Driven MPPT','Location','Best');

%% =========================
% Figure 2: Mode comparison
%% =========================
figure;

subplot(2,1,1)
stairs(tr, Mode_rule,'b','LineWidth',1.2);
ylim([0.5 3.5]); grid on;
yticks([1 2 3]); yticklabels({'SVM','ANN','P&O'});
title('Rule-Based MPPT Mode');

subplot(2,1,2)
stairs(ta, Mode_ai,'r','LineWidth',1.2);
ylim([0.5 3.5]); grid on;
yticks([1 2 3]); yticklabels({'SVM','ANN','P&O'});
title('AI-Driven MPPT Mode');

xlabel('Time (s)');

%% =========================
% Figure 3: Selected IoT Node
%% =========================
figure;

subplot(2,1,1)
stairs(tr, Node_rule,'b','LineWidth',1.2); grid on;
ylim([0.5 3.5]); yticks(1:3);
title('Rule-Based Selected Node');

subplot(2,1,2)
stairs(ta, Node_ai,'r','LineWidth',1.2); grid on;
ylim([0.5 3.5]); yticks(1:3);
title('AI-Driven Selected Node');

xlabel('Time (s)');

%% =========================
% Report Variables
%% =========================
avg_rule = mean(Pr);
avg_ai   = mean(Pa);
gain = (avg_ai - avg_rule)/avg_rule*100;

fprintf('\n============= RESULT SUMMARY =============\n');
fprintf('Rule-Based Mean Power: %.2f W\n', avg_rule);
fprintf('AI-Based   Mean Power: %.2f W\n', avg_ai);
fprintf('AI Improvement: %.2f %%\n', gain);
fprintf('Rule Mode Switch Count: %d\n', sum(abs(diff(Mode_rule))>0));
fprintf('AI   Mode Switch Count: %d\n', sum(abs(diff(Mode_ai))>0));
fprintf('==========================================\n');

%% =========================
% Save results for thesis
%% =========================
save comparison_results Pr Pa Mode_rule Mode_ai Node_rule Node_ai tr ta

disp('✅ All plots generated and saved successfully.');
function [t,y] = get_power_ws()

    if evalin('base','exist(''power'',''var'')')
        sig = evalin('base','power');
    elseif evalin('base','exist(''Power'',''var'')')
        sig = evalin('base','Power');
    else
        error('Neither power nor Power exists in workspace!');
    end

    if isa(sig,'timeseries')
        y = sig.Data(:);
        t = sig.Time(:);
    else
        y = sig(:);
        if evalin('base','exist(''tout'',''var'')')
            t = evalin('base','tout(:)');
        else
            t = (0:length(y)-1).';
        end
    end
end
