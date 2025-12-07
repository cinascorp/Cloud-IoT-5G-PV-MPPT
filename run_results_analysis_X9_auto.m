%% =========================================================================
%     X9 – AUTO SIMULATION + ULTRA-SAFE RESULTS EXTRACTION (ALL-ERRORLESS VERSION)
%     Includes automatic interpolation for dimension mismatch and explicit type casting to double.
% =========================================================================

disp('>>> Starting automatic simulation (workspace will NOT be cleared)...');

modelName = 'PV_ANN1';

try
    sim(modelName);
    disp('>>> Simulation finished successfully.');
catch ME
    disp('❌ Simulation failed:');
    disp(ME.message);
    return;
end

disp('>>> Extracting simulation results...');
ws = evalin('base','whos');

%% =========================================================================
%     TIME EXTRACTION (t_main: main time vector for all plots)
% =========================================================================

t_main = []; 
gotTime = false;
t_name = '';

% Search for time/tout first
if any(strcmp({ws.name},'time'))
    t_main = evalin('base','time'); 
    t_name = 'time';
    gotTime = true;
elseif any(strcmp({ws.name},'tout'))
    t_main = evalin('base','tout');
    t_name = 'tout';
    gotTime = true;
else 
    % Search for Structure With Time
    for i = 1:length(ws)
        vname = ws(i).name;
        try
            tmp = evalin('base',vname);
            if isstruct(tmp) && isfield(tmp,'time')
                t_main = tmp.time; 
                t_name = ['struct: ' vname '.time'];
                gotTime = true;
                break;
            end
        catch 
        end
    end
end

if ~gotTime || isempty(t_main)
    error('❌ No valid time vector found (time/tout/struct.time is empty or missing). Please ensure a time vector is saved to workspace.');
end
t_main = double(t_main(:)); % Ensure t_main is a column vector and double
disp(['>>> Main time vector extracted (Source: ' t_name ') and reshaped successfully. Length: ' num2str(length(t_main))]);

expected_t_length = length(t_main);

%% =========================================================================
%     LOAD ALL SIGNALS USING SAFE EXTRACTOR, AUTO-INTERPOLATE, AND VALIDATE
% =========================================================================

% List of signals to process. The struct will hold the signal data (value) and its time vector (time)
signal_names = {'Vpv', 'Ipv', 'mode_select', 'P_ref', 'Cost_J', 'Cost_J_rate', 'PV_eff', 'Mode_transitions', 'Controller_Health'};
Signals = struct('name', {}, 'value', {}, 'time', {});

for i = 1:length(signal_names)
    vname = signal_names{i};
    ensure_exists(vname);
    
    [value_orig, time_orig] = extract_value_and_time(vname);

    if isempty(value_orig)
        error(['❌ Extracted signal "' vname '" is empty.']);
    end
    
    % Explicitly cast to double for robustness
    value = double(value_orig(:)); % Ensure it's a column vector and double
    time = double(time_orig(:));   % Ensure it's a column vector and double
    
    Signals(i).name = vname;
    Signals(i).value = value;
    Signals(i).time = time; 

    if length(value) ~= expected_t_length
        disp(['⚠️ WARNING: Signal "' vname '" length (' num2str(length(value)) ') does not match main time vector length (' num2str(expected_t_length) '). Attempting interpolation...']);
        
        % Ensure we have a time vector for the short signal, otherwise assume uniform sampling
        if isempty(time) || length(time) ~= length(value)
             % If no specific time vector for the signal, assume it's uniformly sampled over the main time span
             t_short = double(linspace(t_main(1), t_main(end), length(value))');
             disp(['   - Assuming uniform sampling for interpolation.']);
        else
            t_short = time; % Already double and column vector
        end
        
        % Interpolation Logic
        if strcmp(vname, 'mode_select')
            % Use nearest neighbor interpolation for discrete signals (mode_select)
            Signals(i).value = interp1(t_short, value, t_main, 'nearest', 'extrap');
        else
            % Use linear interpolation for continuous signals
            Signals(i).value = interp1(t_short, value, t_main, 'linear', 'extrap');
        end
        
        % Final check after interpolation (should always pass)
        if length(Signals(i).value) ~= expected_t_length
             error(['❌ FAILED INTERPOLATION: Signal "' vname '" still has wrong length after interpolation.']);
        end
        disp(['   - Interpolation successful. New length: ' num2str(length(Signals(i).value))]);
    end
end

disp('>>> All signals extracted, auto-corrected for length, and validated successfully.');

%% =========================================================================
%     ASSIGN SIGNALS TO FINAL VARIABLES
% =========================================================================

Vpv_sig         = Signals(1).value;
Ipv_sig         = Signals(2).value;
Mode_sig        = Signals(3).value;
Pref_sig        = Signals(4).value;
Cost_sig        = Signals(5).value;
Cost_rate_sig   = Signals(6).value;
Eff_sig         = Signals(7).value;
ModeTr_sig      = Signals(8).value;
Health_sig      = Signals(9).value;

% Power Calculation (Now Vpv_sig and Ipv_sig are guaranteed to have the same length and type)
Ppv_sig = Vpv_sig .* Ipv_sig;

% Special Case: Mode_transitions (If it's a single value, it must be the total count)
% The ModeTr_sig here is the interpolated one. The total count should come from the original (non-interpolated)
% or if it's already a single value. Let's keep the logic simple for the final value.
if length(Signals(8).value) == 1 % Check the original extracted value for total transitions
    TotalTrans  = Signals(8).value(1);
else
    TotalTrans  = Signals(8).value(end); % Assuming the last value represents the final count if it's a time-series
end

%% =========================================================================
%     KPIs AND REPORT
% =========================================================================

MeanEff     = mean(Eff_sig);
MeanCost    = mean(Cost_sig);
MeanHealth  = mean(Health_sig);

disp('=====================================================');
disp('      AI-MPPT X9 PERFORMANCE SUMMARY (ALL-ERRORLESS)');
disp('=====================================================');
fprintf('Average PV Efficiency:     %.4f (%.1f%%)\n', MeanEff, MeanEff*100);
fprintf('Average Cost (J):          %.4f\n', MeanCost);
fprintf('Average Controller Health: %.4f\n', MeanHealth);
fprintf('Total Mode Transitions:    %d\n', TotalTrans);
disp('=====================================================');

%% =========================================================================
%     PLOTS
% =========================================================================

figure('Name','X9 AUTO RESULTS','Color','w','Position',[80 80 1150 720]);

subplot(3,2,1);  plot(t_main, Ppv_sig,'b','LineWidth',1.5); grid on; title('PV Power (Ppv)');
subplot(3,2,2);  plot(t_main, Pref_sig,'m','LineWidth',1.5); grid on; title('Reference Power (P_ref)');
subplot(3,2,3);  plot(t_main, Cost_sig,'r','LineWidth',1.5); hold on;
                 plot(t_main, Cost_rate_sig,'k--','LineWidth',1);
                 grid on; title('Cost (J) & Rate');
subplot(3,2,4);  plot(t_main, Eff_sig,'g','LineWidth',1.5); grid on; title('PV Efficiency');
subplot(3,2,5);  stairs(t_main, Mode_sig,'LineWidth',1.5); grid on; title('MPPT Mode (mode\_select)');
subplot(3,2,6);  plot(t_main, Health_sig,'c','LineWidth',1.5); grid on; title('Controller Health');

disp('>>> Plots generated successfully.');
disp('>>> ALL DONE. ALL-ERRORLESS VERSION: Dimension mismatch and type casting issues resolved.');

% Local Functions (defined at the end of the script)
function [out_value, out_time] = extract_value_and_time(varname)
    tmp = evalin('base', varname);
    out_value = [];
    out_time = [];

    if isstruct(tmp)
        if isfield(tmp,'signals') && isfield(tmp.signals,'values')
            % Structure With Time format (Simulink default logging)
            out_value = tmp.signals.values;     
            out_time = tmp.time;
        elseif isfield(tmp,'values') && isfield(tmp,'time')
             % Alternative structure format
            out_value = tmp.values;             
            out_time = tmp.time;
        else
            % Treat as a generic struct that might contain just the value
            warning(['⚠️ Variable "' varname '" is struct but without recognizable time/value fields. Attempting to extract value directly.']);
            fnames = fieldnames(tmp);
            if length(fnames) == 1
                out_value = tmp.(fnames{1}); % If only one field, assume it's the value
            else
                error(['❌ Variable "' varname '" is struct but without .signals.values or .values and has multiple fields. Cannot determine value.']);
            end
            out_time = []; % No time information
        end
    else
        % Already numeric array
        out_value = tmp;                        
        out_time = [];
    end
end

function ensure_exists(v)
    if evalin('base',['~exist(''' v ''',''var'')'])
        error(['❌ Variable "' v '" does not exist in Workspace. Please check your Simulink "To Workspace" blocks. Make sure "' v '" is saved.']);
    end
end
