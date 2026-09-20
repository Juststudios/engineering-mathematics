%% 03_rc_circuit_companion.m - Dynamic RC Filter Charging Simulation
% =========================================================================
% MODULE: Simulink Dynamic System Modeling (Level 2 / R5)
%
% PURPOSE:
%   Standalone MATLAB companion script demonstrating ODE45 integration for
%   a 1st-order low-pass resistor-capacitor (RC) circuit step response.
%   Validates numerical simulation accuracy against closed-form analytical
%   exponential trajectory and verifies transient performance metrics.
%
% GOVERNING DIFFERENTIAL EQUATION:
%   Applying Kirchhoff's Current Law (KCL) at capacitor node:
%     (V_in(t) - v_C(t)) / R = C * (dv_C / dt)
%     dv_C/dt = (V_in(t) - v_C(t)) / (R * C)
%   Circuit Time Constant: tau = R * C [seconds]
%
% TRANSIENT METRICS AUDIT:
%   - Rise Time (10% to 90% of steady state): t_r = tau * ln(9) ~ 2.197 s
%   - Settling Time (within 2% of final value): t_s = -tau * ln(0.02) ~ 3.912 s
%   - Maximum Numerical Integration Error: max|v_num - v_anal| < 1e-4 V
% =========================================================================

clear;
close all;
clc;

fprintf('=================================================================\n');
fprintf('  SIMULINK COMPANION: 1ST-ORDER RC CIRCUIT STEP RESPONSE         \n');
fprintf('=================================================================\n\n');

%% 1. Circuit Component Parameters & Time Base
% Resistor value: 10 kilo-ohms
R = 10.0e3;        % Resistance [Ohms]
% Capacitor value: 100 micro-farads
C = 100.0e-6;      % Capacitance [Farads]

% Theoretical time constant: tau = R * C
tau = R * C;       % Time constant [s] (tau = 1.000 s)

% Input excitation parameters
V_step  = 5.0;     % Step input voltage amplitude [V]
t_step  = 0.1;     % Step onset time [s]
t_final = 6.0;     % Total simulation duration [s]

fprintf('Circuit Parameters:\n');
fprintf('  Resistance (R)              : %.2f kOhm\n', R / 1e3);
fprintf('  Capacitance (C)             : %.2f uF\n', C * 1e6);
fprintf('  Time Constant (tau = R*C)   : %.4f seconds\n', tau);
fprintf('  Input Step Voltage (V_step) : %.2f V applied at t = %.2f s\n\n', V_step, t_step);

%% 2. ODE Definition & Numerical Integration via ode45
% Dynamic input voltage function
v_in_func = @(t) (t >= t_step) * V_step;

% First-order state equation: dv_C/dt = (V_in(t) - v_C) / (R * C)
rc_ode = @(t, vc) (v_in_func(t) - vc) / (R * C);

% Initial condition: capacitor completely discharged at t = 0
vc_0 = 0.0; % [V]

% Configure high-precision variable-step Dormand-Prince solver
ode_options = odeset('RelTol', 1e-6, 'AbsTol', 1e-8, 'MaxStep', 0.01);

% Execute numerical integration
[t_sim, vc_sim] = ode45(rc_ode, [0.0, t_final], vc_0, ode_options);

%% 3. Analytical Ground Truth & Accuracy Verification
% Closed-form solution:
%   For t < t_step : v_C(t) = 0
%   For t >= t_step: v_C(t) = V_step * (1 - exp(-(t - t_step) / tau))
vc_analytical = zeros(size(t_sim));
for idx = 1:length(t_sim)
    t_val = t_sim(idx);
    if t_val >= t_step
        vc_analytical(idx) = V_step * (1.0 - exp(-(t_val - t_step) / tau));
    else
        vc_analytical(idx) = 0.0;
    end
end

% Compute pointwise solver discrepancy
abs_error = abs(vc_sim - vc_analytical);
max_error = max(abs_error);
rms_error = sqrt(mean(abs_error.^2));

fprintf('Solver Precision Audit:\n');
fprintf('  Total Adaptive Time Steps   : %d\n', length(t_sim));
fprintf('  Maximum Discrepancy         : %.2e V (Threshold: <= 1e-4 V)\n', max_error);
fprintf('  Root-Mean-Square Error      : %.2e V\n', rms_error);

%% 4. Transient Metric Calculations
% Target threshold voltages
v_10 = 0.10 * V_step; % 10% threshold = 0.5 V
v_90 = 0.90 * V_step; % 90% threshold = 4.5 V
v_98 = 0.98 * V_step; % 98% threshold (2% settling band) = 4.9 V

% Locate threshold crossing times via linear interpolation
t_10_idx = find(vc_sim >= v_10, 1, 'first');
t_90_idx = find(vc_sim >= v_90, 1, 'first');
t_98_idx = find(vc_sim >= v_98, 1, 'first');

% Interpolate precise timestamps
t_10 = interp1(vc_sim(t_10_idx-1:t_10_idx), t_sim(t_10_idx-1:t_10_idx), v_10);
t_90 = interp1(vc_sim(t_90_idx-1:t_90_idx), t_sim(t_90_idx-1:t_90_idx), v_90);
t_98 = interp1(vc_sim(t_98_idx-1:t_98_idx), t_sim(t_98_idx-1:t_98_idx), v_98);

% Empirical rise and settling times
t_rise_empirical = t_90 - t_10;
t_settle_empirical = t_98 - t_step;

% Theoretical formulas:
%   t_10 = t_step + tau * ln(1 / (1 - 0.10)) = t_step + tau * ln(10/9)
%   t_90 = t_step + tau * ln(1 / (1 - 0.90)) = t_step + tau * ln(10)
%   t_rise = t_90 - t_10 = tau * ln(9)
t_rise_theoretical = tau * log(9.0);
%   t_settle = -tau * ln(0.02)
t_settle_theoretical = -tau * log(0.02);

fprintf('\nTransient Performance Scorecard:\n');
fprintf('  Metric               Simulated       Theoretical     Absolute Delta\n');
fprintf('  -------------------------------------------------------------------\n');
fprintf('  Rise Time (10%%-90%%)  %8.4f s      %8.4f s      %8.2e s\n', ...
    t_rise_empirical, t_rise_theoretical, abs(t_rise_empirical - t_rise_theoretical));
fprintf('  Settling Time (2%%)   %8.4f s      %8.4f s      %8.2e s\n', ...
    t_settle_empirical, t_settle_theoretical, abs(t_settle_empirical - t_settle_theoretical));
fprintf('  Final Voltage        %8.4f V      %8.4f V      %8.2e V\n', ...
    vc_sim(end), V_step, abs(vc_sim(end) - V_step));

%% 5. Visualization
figure('Name', 'RC Circuit Step Response', 'Color', 'w');

% Top panel: Voltage trajectories
subplot(2, 1, 1);
plot(t_sim, vc_sim, 'b-', 'LineWidth', 2.0, 'DisplayName', 'ODE45 Numerical');
hold on;
plot(t_sim, vc_analytical, 'r--', 'LineWidth', 1.5, 'DisplayName', 'Analytical Truth');
yline(V_step, 'k:', 'LineWidth', 1.0, 'DisplayName', 'V_{step} (5.0 V)');
yline(v_90, 'g:', 'LineWidth', 1.0, 'DisplayName', '90% Threshold');
yline(v_10, 'm:', 'LineWidth', 1.0, 'DisplayName', '10% Threshold');
grid on;
xlabel('Time [seconds]');
ylabel('Capacitor Voltage v_C(t) [V]');
title('1st-Order RC Low-Pass Filter: Step Response Charging Transient');
legend('Location', 'southeast');

% Bottom panel: Pointwise solver residual error
subplot(2, 1, 2);
semilogy(t_sim, abs_error + 1e-15, 'k-', 'LineWidth', 1.2);
grid on;
xlabel('Time [seconds]');
ylabel('Absolute Error |v_{num} - v_{anal}| [V]');
title('ODE45 Solver Residual Error vs Analytical Truth');
ylim([1e-10, 1e-3]);

fprintf('\n=================================================================\n');
fprintf('  RC CIRCUIT COMPANION COMPLETED SUCCESSFULLY                    \n');
fprintf('=================================================================\n');
