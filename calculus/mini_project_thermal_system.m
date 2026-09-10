%% mini_project_thermal_system.m - Transient Thermal Cooling & Parameter Estimation
% =========================================================================
% MODULE     : Calculus for Engineers (R3: Change, Accumulation & Optimization)
% MINI-PROJECT: Inverter Silicon Thermal Management & Convective Parameter ID
%
% ENGINEERING SCENARIO:
% In an electric vehicle traction inverter, Insulated Gate Bipolar Transistors 
% (IGBTs) convert DC battery power to AC motor drive current. Due to conduction 
% and switching losses, the silicon dies generate significant heat P_in(t).
%
% If the junction temperature T(t) exceeds T_max = 85 deg C, thermal runaway 
% or silicon degradation occurs. A liquid-cooled aluminum heat sink dissipates 
% this heat to the cooling loop at temperature T_amb.
%
% GOVERNING FIRST-ORDER ENERGY BALANCE:
%   C_th * (dT/dt) = P_in(t) - h_A * (T(t) - T_amb)
%
% Rearranged in state-variable form:
%   dT/dt = (1 / C_th) * P_in(t) - (h_A / C_th) * (T(t) - T_amb)
%
% Where:
%   C_th  = Lumped thermal capacitance [J / K]
%   h_A   = Convective thermal conductance [W / K] = h * Area
%   P_in  = Electrical loss heat input [W]
%   T_amb = Coolant / ambient temperature [deg C]
%
% PROJECT OBJECTIVES:
%   Part 1: Dynamic forward simulation under realistic 4-phase drive cycle
%   Part 2: Safety audit against maximum allowable temperature T_max
%   Part 3: Parameter identification (estimating h_A from noisy cooldown telemetry)
%   Part 4: Heat sink sizing optimization for continuous peak rating
% =========================================================================

clear;
close all;
clc;

fprintf('===================================================================\n');
fprintf('  CALCULUS MINI-PROJECT: TRANSIENT THERMAL SYSTEM & SIZING OPT     \n');
fprintf('===================================================================\n\n');

%% Part 1: Physical Parameters & Drive Cycle Definition
% Physical constants for an automotive power module
C_th  = 180.0;    % Lumped thermal capacitance [J / K]
h_A   = 4.5;      % Convective thermal conductance [W / K]
T_amb = 25.0;     % Coolant fluid inlet temperature [deg C]
T_max = 85.0;     % Maximum allowable silicon operating temperature [deg C]
T_init = 25.0;    % Initial cold start temperature [deg C]

% Thermal time constant: tau = C_th / h_A [seconds]
tau_thermal = C_th / h_A; 

% 4-Phase Drive Cycle Heat Generation Profile P_in(t):
%   Phase 1 [0   to 120 s]: Idle / Creep Mode        -> P_in = 20 W
%   Phase 2 [120 to 240 s]: Highway Acceleration    -> P_in = 140 W (Heavy load)
%   Phase 3 [240 to 450 s]: Steady Highway Cruise   -> P_in = 65 W
%   Phase 4 [450 to 700 s]: Vehicle Parked / Cooldown -> P_in = 0 W
t_sim_end = 700.0; % Total simulation duration [s]

fprintf('--- 1. THERMAL SYSTEM CONSTANTS ---\n');
fprintf('Thermal Capacitance C_th      : %.1f J/K\n', C_th);
fprintf('Thermal Conductance h*A       : %.2f W/K\n', h_A);
fprintf('Thermal Time Constant tau     : %.2f seconds\n', tau_thermal);
fprintf('Ambient Coolant Temp T_amb    : %.1f deg C\n', T_amb);
fprintf('Maximum Safe Temp T_max       : %.1f deg C\n\n', T_max);

%% Part 2: Forward Dynamic Simulation with ode45
% Define the ODE system using local function thermal_ode()

t_span = [0, t_sim_end];
opts = odeset('RelTol', 1e-6, 'AbsTol', 1e-8);

% Execute numerical integration
[t_history, T_history] = ode45(@(t, T) thermal_ode(t, T, C_th, h_A, T_amb), ...
    t_span, T_init, opts);

% Compute instantaneous heat input and heat rejection profiles along trajectory
P_in_history = zeros(size(t_history));
for i = 1:length(t_history)
    P_in_history(i) = get_power_input(t_history(i));
end
Q_out_history = h_A .* (T_history - T_amb); % Convective heat dissipated [W]

% Thermal Audit Metrics
peak_temp = max(T_history);
[~, idx_peak] = max(T_history);
t_peak = t_history(idx_peak);
final_temp = T_history(end);

fprintf('--- 2. DYNAMIC DRIVE CYCLE SIMULATION RESULTS ---\n');
fprintf('Peak Temperature Reached      : %.2f deg C at t = %.1f s\n', peak_temp, t_peak);
fprintf('Final Temperature after cooldown: %.2f deg C\n', final_temp);
if peak_temp <= T_max
    fprintf('Thermal Safety Status         : [PASS] Peak temp is %.2f deg C below limit.\n\n', ...
        T_max - peak_temp);
else
    fprintf('Thermal Safety Status         : [FAIL] Thermal limit exceeded by %.2f deg C!\n\n', ...
        peak_temp - T_max);
end

%% Part 3: Parameter Identification from Cooldown Telemetry
% During vehicle cooldown (t in [450, 700] s), power input is zero (P_in = 0).
% The governing ODE simplifies to pure exponential relaxation:
%   dT/dt = -k * (T - T_amb),  where k = h_A / C_th
%
% Integrating gives:
%   (T(t) - T_amb) = (T_cd0 - T_amb) * exp(-k * (t - t_cd0))
%
% Linearizing via natural logarithm:
%   ln(T(t) - T_amb) = ln(T_cd0 - T_amb) - k * (t - t_cd0)
%
% This is a linear relationship y = m * x + b, where the slope m = -k!

t_cd0 = 450.0; % Cooldown start time
idx_cooldown = (t_history >= t_cd0);
t_cooldown = t_history(idx_cooldown) - t_cd0; % Relative cooldown time [s]
T_cooldown_clean = T_history(idx_cooldown);

% Simulate realistic thermal sensor telemetry with Gaussian noise
rng(2026);
noise_std = 0.4; % 0.4 deg C sensor measurement noise
T_cooldown_noisy = T_cooldown_clean + noise_std * randn(size(T_cooldown_clean));

% Linear regression on log temperature difference:
% y = ln(T_noisy - T_amb)
y_log = log(max(T_cooldown_noisy - T_amb, 0.01)); % Protect against non-positive log
X_reg = [t_cooldown, ones(size(t_cooldown))];     % Design matrix: [t, 1]

% Solve normal equations: beta = (X' * X) \ (X' * y)
beta = X_reg \ y_log;
k_estimated = -beta(1);
h_A_estimated = k_estimated * C_th; % Derived conductance assuming known C_th

true_k = h_A / C_th;
param_err_percent = abs(h_A_estimated - h_A) / h_A * 100;

fprintf('--- 3. TELEMETRY PARAMETER ESTIMATION (COOLDOWN PHASE) ---\n');
fprintf('True Thermal Conductance h_A  : %.4f W/K\n', h_A);
fprintf('Estimated Conductance h_A_hat : %.4f W/K\n', h_A_estimated);
fprintf('Estimation Error              : %.2f %%\n\n', param_err_percent);

%% Part 4: Optimal Heat Sink Sizing for Extreme Steady-State Rating
% In extreme continuous uphill towing, the inverter dissipates a constant 
% P_extreme = 110 W under hot ambient conditions T_amb_hot = 38 deg C.
%
% At steady state, dT/dt = 0:
%   0 = P_extreme - (h_A) * (T_steady - T_amb_hot)
%   T_steady = T_amb_hot + P_extreme / (h_A)
%
% To guarantee a 5 deg C safety margin below T_max (T_target <= 80 deg C):
%   (h_A)_required = P_extreme / (T_target - T_amb_hot)

P_extreme = 110.0;    % Sustained severe load [W]
T_amb_hot = 38.0;     % High ambient summer temperature [deg C]
T_target  = 80.0;     % Conservative operating ceiling [deg C]

h_A_min_required = P_extreme / (T_target - T_amb_hot);

% Conductance sweep to visualize design trade-off curve
h_A_sweep = linspace(1.5, 6.5, 200);
T_steady_curve = T_amb_hot + P_extreme ./ h_A_sweep;

fprintf('--- 4. HEAT SINK SIZING OPTIMIZATION ---\n');
fprintf('Sustained Extreme Load        : %.1f W\n', P_extreme);
fprintf('Hot Ambient Condition         : %.1f deg C\n', T_amb_hot);
fprintf('Target Safety Margin Ceiling  : %.1f deg C (5 deg C below T_max)\n', T_target);
fprintf('Minimum Required h*A          : %.3f W/K (Baseline is %.2f W/K)\n', ...
    h_A_min_required, h_A);
if h_A >= h_A_min_required
    fprintf('Baseline Sizing Assessment    : Heat sink is ADEQUATE for extreme continuous rating.\n\n');
else
    fprintf('Baseline Sizing Assessment    : Heat sink is UNDERSIZED by %.2f W/K for continuous extreme load.\n\n', ...
        h_A_min_required - h_A);
end

%% Part 5: Comprehensive Engineering Visualization
figure('Name', 'Inverter Thermal Management Mini-Project', ...
    'Position', [100, 100, 1100, 800]);

% Subplot 1: Dynamic Temperature Response vs Limits
subplot(2, 2, 1);
plot(t_history, T_history, 'b-', 'LineWidth', 2); hold on;
yline(T_max, 'r--', 'T_{max} Safety Limit (85^\circC)', 'LineWidth', 1.5);
yline(T_amb, 'k:', 'Coolant Temp (25^\circC)', 'LineWidth', 1.2);
plot(t_peak, peak_temp, 'ro', 'MarkerFaceColor', 'r', 'MarkerSize', 8);
grid on;
title('Inverter Silicon Junction Temperature T(t)', 'FontSize', 11);
xlabel('Time t [seconds]');
ylabel('Temperature [^\circC]');
legend('Silicon Temperature T(t)', 'T_{max} Safety Threshold', ...
    'Coolant Inlet T_{amb}', 'Peak Operating Point', 'Location', 'northwest');

% Subplot 2: Power Generation vs Convective Rejection
subplot(2, 2, 2);
plot(t_history, P_in_history, 'r-', 'LineWidth', 1.8); hold on;
plot(t_history, Q_out_history, 'b--', 'LineWidth', 1.8);
grid on;
title('Thermal Power Balance: P_{in}(t) vs Q_{out}(t)', 'FontSize', 11);
xlabel('Time t [seconds]');
ylabel('Thermal Power [Watts]');
legend('Heat Generated P_{in}(t)', 'Convective Heat Dissipated Q_{out}(t)', ...
    'Location', 'northeast');

% Subplot 3: Telemetry Cooldown Fit & Parameter ID
subplot(2, 2, 3);
plot(t_cooldown + t_cd0, T_cooldown_noisy, 'k.', 'MarkerSize', 6); hold on;
T_fitted_trajectory = T_amb + (T_cooldown_clean(1) - T_amb) .* ...
    exp(-k_estimated .* t_cooldown);
plot(t_cooldown + t_cd0, T_fitted_trajectory, 'm-', 'LineWidth', 2);
grid on;
title(sprintf('Parameter ID: Cooldown Fit (hA_{est} = %.2f W/K)', h_A_estimated), 'FontSize', 11);
xlabel('Time t [seconds]');
ylabel('Temperature [^\circC]');
legend('Noisy Telemetry Samples', 'Fitted Exponential Model', 'Location', 'northeast');

% Subplot 4: Heat Sink Conductance Sizing Trade-off
subplot(2, 2, 4);
plot(h_A_sweep, T_steady_curve, 'Color', [0.1, 0.5, 0.2], 'LineWidth', 2); hold on;
yline(T_target, 'r--', 'Target Ceiling (80^\circC)', 'LineWidth', 1.2);
xline(h_A_min_required, 'm--', sprintf('Min hA = %.2f W/K', h_A_min_required), 'LineWidth', 1.2);
xline(h_A, 'b:', sprintf('Baseline hA = %.2f W/K', h_A), 'LineWidth', 1.2);
grid on;
title('Steady-State Sizing: T_{steady} vs Conductance hA', 'FontSize', 11);
xlabel('Heat Sink Conductance hA [W / K]');
ylabel('Steady-State Temperature [^\circC]');
legend('T_{steady} Curve (110W load)', 'Target Limit', 'Required Sizing', ...
    'Current Baseline', 'Location', 'northeast');

fprintf('Calculus mini-project mini_project_thermal_system.m completed successfully.\n');

%% Local Helper Functions
function dTdt = thermal_ode(t, T, C_th, h_A, T_amb)
    % Evaluates first-order thermal ODE state derivative
    % State derivative MUST be a column vector
    P_in = get_power_input(t);
    dTdt = (1.0 / C_th) * P_in - (h_A / C_th) * (T - T_amb);
end

function P = get_power_input(t)
    % Evaluates piece-wise power generation profile across the 4-phase drive cycle
    if t < 120.0
        P = 20.0;   % Phase 1: Creep / Idle load
    elseif t < 240.0
        P = 140.0;  % Phase 2: High acceleration burst
    elseif t < 450.0
        P = 65.0;   % Phase 3: Steady highway cruise
    else
        P = 0.0;    % Phase 4: Cooldown / vehicle shutoff
    end
end
