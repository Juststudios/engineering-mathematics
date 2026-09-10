%% 04_differential_equations.m - 1st-Order ODEs and MATLAB ode45
% =========================================================================
% MODULE: Calculus for Engineers (R3: Change, Accumulation & Optimization)
% TOPIC : First-Order Ordinary Differential Equations in Physical Systems
%
% ENGINEERING CONTEXT:
% Many fundamental physical systems are governed by first-order rate laws:
%   1. Thermal Systems (Newton's Law of Cooling):
%        dT/dt = -k * (T(t) - T_env)
%   2. Electrical RC Circuits (Kirchhoff's Voltage Law):
%        dv_C/dt = (V_in(t) - v_C(t)) / (R * C)
%
% These equations share identical mathematical structure: exponential relaxation
% towards equilibrium characterized by a system time constant tau.
%
% In this script, you will learn:
%   - How to formulate first-order ODEs as MATLAB function handles
%   - How to solve non-stiff ODEs numerically using ode45 (Dormand-Prince)
%   - How to configure solver tolerances using odeset()
%   - How to detect physical events (such as settling time) using Event Functions
%   - How to compare numerical trajectories against analytical closed-form solutions
% =========================================================================

clear;
close all;
clc;

fprintf('=======================================================\n');
fprintf('  CALCULUS FOR ENGINEERS: DIFFERENTIAL EQUATIONS       \n');
fprintf('=======================================================\n\n');

%% Section 1: Newton's Law of Cooling - Model Formulation
% Physical Problem:
% An aluminum heat sink on an automotive power inverter is operating at 
% an initial temperature T0 = 95 deg C. At t = 0 s, the vehicle is parked 
% in a garage with ambient environment temperature T_env = 22 deg C.
%
% Governing Differential Equation:
%   dT/dt = -k * (T - T_env)
% where:
%   k = cooling coefficient [s^-1] = (h * A) / (m * c_p)
%
% Analytical Closed-Form Solution:
%   T(t) = T_env + (T0 - T_env) * exp(-k * t)
% Thermal time constant: tau = 1 / k [seconds]

T0    = 95.0;    % Initial heat sink temperature [deg C]
T_env = 22.0;    % Ambient environment temperature [deg C]
k_cool = 0.015;  % Cooling rate constant [s^-1]
tau_th = 1.0 / k_cool; % Thermal time constant [s] (~66.67 s)

t_span_cool = [0, 300]; % Simulate for 300 seconds (approx 4.5 time constants)

% Formulate ODE as a MATLAB function handle: f(t, T)
% Note: In MATLAB ODE solvers, the state derivative MUST be a column vector!
ode_cooling = @(t, T) -k_cool * (T - T_env);

% Configure solver tolerances for high precision
opts_cooling = odeset('RelTol', 1e-6, 'AbsTol', 1e-8);

% Solve using ode45
[t_cool_num, T_cool_num] = ode45(ode_cooling, t_span_cool, T0, opts_cooling);

% Compute analytical solution at the exact solver output timestamps
T_cool_exact = T_env + (T0 - T_env) .* exp(-k_cool .* t_cool_num);

% Measure maximum numerical integration error
max_cooling_err = max(abs(T_cool_num - T_cool_exact));

fprintf('--- 1. THERMAL COOLING TRANSIENT (ode45 vs EXACT) ---\n');
fprintf('Initial Temperature T0       : %.1f deg C\n', T0);
fprintf('Ambient Temperature T_env    : %.1f deg C\n', T_env);
fprintf('Thermal Time Constant tau    : %.2f seconds\n', tau_th);
fprintf('Final Temperature at 300 s   : %.2f deg C (Exact: %.2f deg C)\n', ...
    T_cool_num(end), T_cool_exact(end));
fprintf('Max Numerical Error (ode45)  : %.4e deg C\n\n', max_cooling_err);

%% Section 2: Transient Time Constant & Settling Time Analysis
% In linear first-order systems:
%   - At t = 1 * tau: System has completed (1 - exp(-1)) = 63.2% of transition
%   - At t = 2 * tau: System has completed (1 - exp(-2)) = 86.5% of transition
%   - At t = 3 * tau: System has completed (1 - exp(-3)) = 95.0% of transition
%   - At t = 4 * tau: System has completed (1 - exp(-4)) = 98.2% (Standard Settling Time)

T_at_1tau = T_env + (T0 - T_env) * exp(-1.0);
T_at_4tau = T_env + (T0 - T_env) * exp(-4.0);

fprintf('--- 2. FIRST-ORDER RELAXATION BENCHMARKS ---\n');
fprintf('At t = 1*tau (%.1f s): T = %.2f deg C (63.2%% cooling completed)\n', ...
    tau_th, T_at_1tau);
fprintf('At t = 4*tau (%.1f s): T = %.2f deg C (98.2%% settling threshold)\n\n', ...
    4.0 * tau_th, T_at_4tau);

%% Section 3: Electrical RC Circuit Transient Response
% Physical Problem:
% An RC low-pass filter with R = 4.7 kOhm and C = 220 uF is energized 
% with a step input voltage V_in = 12.0 V at t = 0 s (capacitor uncharged: v_c(0) = 0 V).
%
% Governing ODE:
%   C * (dv_c / dt) = (V_in - v_c) / R
%   dv_c / dt = (V_in - v_c) / (R * C)
%
% Electrical time constant: tau_rc = R * C [seconds]
% Analytical solution: v_c(t) = V_in * (1 - exp(-t / tau_rc))

R_val = 4700.0;     % Resistance: 4.7 kOhm [Ohms]
C_val = 220.0e-6;   % Capacitance: 220 uF [Farads]
V_step = 12.0;      % Step input voltage [Volts]
tau_rc = R_val * C_val; % Electrical time constant [s] (1.034 s)

t_span_rc = [0, 5.0]; % Simulate 5 seconds (~5 time constants)
v_c_0 = 0.0;          % Uncharged capacitor initial state [V]

ode_rc = @(t, vc) (V_step - vc) / (R_val * C_val);

% Solve RC circuit using ode45
[t_rc_num, v_rc_num] = ode45(ode_rc, t_span_rc, v_c_0, opts_cooling);

% Analytical voltage
v_rc_exact = V_step * (1.0 - exp(-t_rc_num / tau_rc));
max_rc_err = max(abs(v_rc_num - v_rc_exact));

fprintf('--- 3. ELECTRICAL RC CIRCUIT CHARGING ---\n');
fprintf('Resistance R                 : %.1f kOhm\n', R_val / 1000);
fprintf('Capacitance C                : %.1f uF\n', C_val * 1e6);
fprintf('Electrical Time Constant tau : %.4f seconds\n', tau_rc);
fprintf('Capacitor Voltage at 1*tau   : %.3f V (Expected 63.2%% of 12V = %.3f V)\n', ...
    interp1(t_rc_num, v_rc_num, tau_rc), 0.63212 * V_step);
fprintf('Capacitor Voltage at 5 s     : %.3f V\n', v_rc_num(end));
fprintf('Max Numerical Error (ode45)  : %.4e V\n\n', max_rc_err);

%% Section 4: Advanced ode45 Feature - Event Detection
% Often engineers need to know EXACTLY when a physical threshold is crossed:
% E.g., "At what precise millisecond does the capacitor reach 95% of V_step?"
%
% Instead of manual post-processing, ode45 supports Event Functions.
% An event function returns [value, isterminal, direction]:
%   - value: Function whose zero-crossing is sought (e.g. vc - 0.95*V_step)
%   - isterminal: 1 to halt solver, 0 to continue
%   - direction: +1 (rising), -1 (falling), or 0 (any)

V_target = 0.95 * V_step; % 95% threshold = 11.4 V

% Define event function handle using local helper function
opts_event = odeset('Events', @(t, vc) rc_threshold_event(t, vc, V_target), ...
    'RelTol', 1e-8, 'AbsTol', 1e-10);

[t_evt_all, v_evt_all, t_evt_hit, v_evt_hit, ~] = ...
    ode45(ode_rc, t_span_rc, v_c_0, opts_event);

t_analytical_95 = -tau_rc * log(1.0 - 0.95);

fprintf('--- 4. ODE45 EVENT FUNCTION DETECTION ---\n');
fprintf('Target Threshold Voltage     : %.2f V (95%% of V_step)\n', V_target);
fprintf('Event Timestamp Detected     : %.4f seconds\n', t_evt_hit);
fprintf('Analytical 95%% Time          : %.4f seconds\n', t_analytical_95);
fprintf('Detection Difference         : %.4e seconds\n\n', abs(t_evt_hit - t_analytical_95));

%% Section 5: Engineering Visualization
figure('Name', 'First-Order Physical ODEs via ode45', ...
    'Position', [120, 120, 1050, 750]);

% Subplot 1: Newton Cooling Transient
subplot(2, 2, 1);
plot(t_cool_num, T_cool_num, 'b-', 'LineWidth', 2); hold on;
plot(t_cool_num, T_cool_exact, 'r--', 'LineWidth', 1.5);
yline(T_env, 'k:', 'Ambient 22^\circC', 'LineWidth', 1.5);
xline(tau_th, 'm--', sprintf('1\\tau = %.1fs', tau_th));
xline(4 * tau_th, 'g--', sprintf('4\\tau = %.1fs (Settled)', 4 * tau_th));
grid on;
title('Newton Cooling: Heat Sink Dissipation', 'FontSize', 11);
xlabel('Time t [seconds]');
ylabel('Temperature T(t) [^\circC]');
legend('ode45 Numerical Trajectory', 'Analytical Exact Solution', ...
    'Ambient Equil', 'Location', 'northeast');

% Subplot 2: Cooling Integration Error
subplot(2, 2, 2);
semilogy(t_cool_num, abs(T_cool_num - T_cool_exact) + 1e-14, 'k.-', 'LineWidth', 1.2);
grid on;
title('ode45 Truncation Error Over Time', 'FontSize', 11);
xlabel('Time t [seconds]');
ylabel('Absolute Error |T_{num} - T_{exact}| [^\circC]');

% Subplot 3: RC Circuit Step Response
subplot(2, 2, 3);
plot(t_rc_num, v_rc_num, 'b-', 'LineWidth', 2); hold on;
yline(V_step, 'k:', 'V_{in} = 12 V', 'LineWidth', 1.5);
yline(V_target, 'r--', '95% Threshold (11.4 V)', 'LineWidth', 1.2);
plot(t_evt_hit, v_evt_hit, 'ro', 'MarkerFaceColor', 'r', 'MarkerSize', 8);
grid on;
title('RC Filter Step Response (Kirchhoff ODE)', 'FontSize', 11);
xlabel('Time t [seconds]');
ylabel('Capacitor Voltage v_C(t) [V]');
legend('Capacitor Voltage v_C(t)', 'Supply Rail V_{in}', '95% Settling Target', ...
    'Event Trigger', 'Location', 'southeast');

% Subplot 4: Charging Current Decay
subplot(2, 2, 4);
i_rc = (V_step - v_rc_num) / R_val * 1000; % Current in mA
plot(t_rc_num, i_rc, 'Color', [0.8, 0.3, 0.0], 'LineWidth', 1.8);
grid on;
title('Transient Charging Current i_C(t) = C(dv/dt)', 'FontSize', 11);
xlabel('Time t [seconds]');
ylabel('Current i_C(t) [mA]');

fprintf('Calculus script 04_differential_equations.m executed successfully.\n');

%% Helper Functions (Must be placed at end of script)
function [value, isterminal, direction] = rc_threshold_event(~, vc, v_target)
    % Event condition: value == 0
    value = vc - v_target;
    isterminal = 0; % 0: Record event timestamp but continue integration
    direction = 1;  % +1: Detect only positive-slope (rising) zero crossings
end
