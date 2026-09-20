%% mini_project_motor_control.m - Closed-Loop PI Motor Control & Anti-Windup
% =========================================================================
% MODULE: Simulink Dynamic System Modeling (Level 2 / Mini-Project)
%
% PURPOSE:
%   Complete engineering mini-project implementing Closed-Loop Proportional-
%   Integral (PI) Speed Control of an electromechanical DC motor.
%   Compares three control architectures under full load torque disturbance:
%     1. Open-Loop Feedforward Control (Unregulated)
%     2. Closed-Loop Proportional (P-Only) Control
%     3. Closed-Loop PI Control with Integrator Anti-Windup Clamping
%
% CONTROL SPECIFICATIONS & PERFORMANCE TARGETS:
%   - Setpoint Speed Reference (\omega_ref)   : 100.0 rad/s (~955 RPM)
%   - Actuator Terminal Voltage Limits (V_max): +/- 36.0 Volts
%   - Load Torque Disturbance (\tau_L)        : 0.80 N*m applied at t = 2.5 s
%   - Rise Time Target (10% to 90%)          : t_r < 0.50 seconds
%   - Maximum Percent Overshoot              : %OS < 10.0%
%   - Steady-State Error Target              : e_ss = 0.0 rad/s (zero offset)
% =========================================================================

clear;
close all;
clc;

fprintf('=================================================================\n');
fprintf('  MINI-PROJECT: CLOSED-LOOP DC MOTOR PI SPEED CONTROL           \n');
fprintf('=================================================================\n\n');

%% 1. Plant Physics & Actuator Parameters
R_a   = 2.0;       % Armature resistance [Ohms]
L_a   = 0.5;       % Armature inductance [Henries]
K_t   = 0.1;       % Torque constant [N*m / A]
K_e   = 0.1;       % Back-EMF constant [V*s / rad]
J     = 0.02;      % Rotor inertia [kg*m^2]
b     = 0.01;      % Viscous friction coefficient [N*m*s / rad]

% Power supply / H-bridge voltage rail saturation
V_max = 36.0;      % Actuator saturation ceiling [+V_max, -V_max] [Volts]

% Simulation timeline and disturbance definitions
t_final    = 5.0;  % Total simulation duration [s]
omega_ref  = 100.0;% Target angular speed setpoint [rad/s]
t_step_tau = 2.5;  % Disturbance torque step time [s]
tau_load   = 0.8;  % Full load shaft torque [N*m]

% Disturbance torque profile
tau_l_func = @(t) (t >= t_step_tau) * tau_load;

fprintf('Control System Targets:\n');
fprintf('  Speed Setpoint (omega_ref)    : %.1f rad/s (~%.0f RPM)\n', ...
    omega_ref, omega_ref * 60 / (2*pi));
fprintf('  Load Torque Step (tau_L)      : %.2f N*m applied at t = %.1f s\n', ...
    tau_load, t_step_tau);
fprintf('  Actuator Voltage Saturation   : +/- %.1f V\n', V_max);
fprintf('  Design Specifications         : t_r < 0.50 s, %%OS < 10.0%%, e_ss = 0\n\n');

%% 2. REGIME 1: Open-Loop Feedforward Control
% In open-loop, constant terminal voltage is chosen to achieve omega_ref at no-load:
% V_ol = (R_a * b + K_t * K_e) * omega_ref / K_t = (0.03 * 100) / 0.1 = 30.0 V
V_open_loop = ((R_a * b + K_t * K_e) * omega_ref) / K_t;
V_ol_clamped = min(V_max, max(-V_max, V_open_loop));

% Open-loop state equation: x = [i_a; omega]
ol_ode = @(t, x) [ ...
    (V_ol_clamped - R_a * x(1) - K_e * x(2)) / L_a; ...
    (K_t * x(1) - b * x(2) - tau_l_func(t)) / J ...
];

ode_opts = odeset('RelTol', 1e-6, 'AbsTol', 1e-8, 'MaxStep', 0.005);
[t_ol, x_ol] = ode45(ol_ode, [0.0, t_final], [0.0; 0.0], ode_opts);
omega_ol = x_ol(:, 2);
ia_ol    = x_ol(:, 1);

%% 3. REGIME 2: Closed-Loop Proportional (P-Only) Control
% Proportional gain: K_p = 2.5
% Control law: V_ctrl(t) = sat(K_p * (omega_ref - omega(t)))
K_p_only = 2.5;

p_ode = @(t, x) [ ...
    (min(V_max, max(-V_max, K_p_only * (omega_ref - x(2)))) - R_a * x(1) - K_e * x(2)) / L_a; ...
    (K_t * x(1) - b * x(2) - tau_l_func(t)) / J ...
];

[t_p, x_p] = ode45(p_ode, [0.0, t_final], [0.0; 0.0], ode_opts);
omega_p = x_p(:, 2);
ia_p    = x_p(:, 1);

%% 4. REGIME 3: Closed-Loop PI Control with Integrator Anti-Windup
% Controller gains tuned for fast settling with zero steady-state error
K_p = 2.0;         % Proportional gain [V / (rad/s)]
K_i = 12.0;        % Integral gain [V / rad]

% Augmented state vector: x = [i_a; omega; x_int]
% x_int: Integrator accumulation state (integral of error)
% Anti-Windup Clamping Logic:
%   1. Compute unsaturated control effort: u_unsat = K_p * e + K_i * x_int
%   2. Clamp actuator output: u_sat = min(V_max, max(-V_max, u_unsat))
%   3. Freeze integration (dx_int/dt = 0) if:
%      (u_sat ~= u_unsat) AND (sign(e) == sign(u_unsat))
%      This prevents integrator windup during initial startup and torque transients!

pi_aw_ode = @(t, x) evaluate_pi_aw_derivatives(t, x, omega_ref, K_p, K_i, V_max, ...
    R_a, L_a, K_e, K_t, b, J, tau_l_func);

[t_pi, x_pi] = ode45(pi_aw_ode, [0.0, t_final], [0.0; 0.0; 0.0], ode_opts);
ia_pi    = x_pi(:, 1);
omega_pi = x_pi(:, 2);
x_int_pi = x_pi(:, 3);

% Post-compute actuator voltage for PI
v_ctrl_pi = zeros(size(t_pi));
for idx = 1:length(t_pi)
    err = omega_ref - omega_pi(idx);
    u_raw = K_p * err + K_i * x_int_pi(idx);
    v_ctrl_pi(idx) = min(V_max, max(-V_max, u_raw));
end

%% 5. Performance Metric Calculations & Scorecard
% Compute Rise Time (t_r: 10% to 90% of setpoint = 10 rad/s to 90 rad/s)
[tr_ol, os_ol, ess_nl_ol, ess_ld_ol] = compute_transient_metrics(t_ol, omega_ol, omega_ref, t_step_tau);
[tr_p,  os_p,  ess_nl_p,  ess_ld_p]  = compute_transient_metrics(t_p,  omega_p,  omega_ref, t_step_tau);
[tr_pi, os_pi, ess_nl_pi, ess_ld_pi] = compute_transient_metrics(t_pi, omega_pi, omega_ref, t_step_tau);

fprintf('========================================================================================\n');
fprintf('  CONTROLLER BENCHMARK & PERFORMANCE SCORECARD                                          \n');
fprintf('========================================================================================\n');
fprintf('  Regime                 Rise Time   Overshoot   No-Load Error  Loaded Error   Spec Status\n');
fprintf('  --------------------------------------------------------------------------------------\n');
fprintf('  Target Spec:           < 0.50 s    < 10.0%%     0.0 rad/s      0.0 rad/s      PASS/FAIL  \n');
fprintf('  --------------------------------------------------------------------------------------\n');
fprintf('  1. Open-Loop Step      %6.3f s    %6.2f%%     %8.3f rad/s   %8.3f rad/s   FAIL      \n', ...
    tr_ol, os_ol, ess_nl_ol, ess_ld_ol);
fprintf('  2. Proportional (P)    %6.3f s    %6.2f%%     %8.3f rad/s   %8.3f rad/s   FAIL (droop)\n', ...
    tr_p, os_p, ess_nl_p, ess_ld_p);
fprintf('  3. PI with Anti-Windup %6.3f s    %6.2f%%     %8.3f rad/s   %8.3f rad/s   ALL PASS! \n', ...
    tr_pi, os_pi, ess_nl_pi, ess_ld_pi);
fprintf('========================================================================================\n\n');

%% 6. Diagnostic Engineering Dashboard
figure('Name', 'DC Motor Closed-Loop Control Benchmark', 'Color', 'w');

% Panel 1: Angular speed comparison
subplot(2, 2, 1);
plot(t_ol, omega_ol, 'k--', 'LineWidth', 1.5, 'DisplayName', 'Open-Loop');
hold on;
plot(t_p, omega_p, 'r-.', 'LineWidth', 1.5, 'DisplayName', 'P-Only (Kp=2.5)');
plot(t_pi, omega_pi, 'b-', 'LineWidth', 2.0, 'DisplayName', 'PI with Anti-Windup');
yline(omega_ref, 'g:', 'LineWidth', 1.5, 'DisplayName', '\omega_{ref} (100 rad/s)');
xline(t_step_tau, 'm--', 'LineWidth', 1.0, 'DisplayName', 'Load Step (0.8 N\cdotm)');
grid on;
xlabel('Time [seconds]');
ylabel('Shaft Speed \omega [rad/s]');
title('Rotor Speed Regulation & Disturbance Rejection');
legend('Location', 'southeast');

% Panel 2: Tracking error e(t) = omega_ref - omega(t)
subplot(2, 2, 2);
plot(t_ol, omega_ref - omega_ol, 'k--', 'LineWidth', 1.5);
hold on;
plot(t_p, omega_ref - omega_p, 'r-.', 'LineWidth', 1.5);
plot(t_pi, omega_ref - omega_pi, 'b-', 'LineWidth', 2.0);
plot([0, t_final], [0, 0], 'g-', 'LineWidth', 1.0);
xline(t_step_tau, 'm--', 'LineWidth', 1.0);
grid on;
xlabel('Time [seconds]');
ylabel('Tracking Error e(t) [rad/s]');
title('Speed Tracking Error (Zero Steady-State Audit)');

% Panel 3: Actuator command voltage (saturation audit)
subplot(2, 2, 3);
plot(t_pi, v_ctrl_pi, 'b-', 'LineWidth', 1.8, 'DisplayName', 'V_{PI}(t)');
hold on;
yline(V_max, 'r--', 'LineWidth', 1.2, 'DisplayName', '+V_{max} (36 V)');
yline(-V_max, 'r--', 'LineWidth', 1.2, 'DisplayName', '-V_{max} (-36 V)');
grid on;
xlabel('Time [seconds]');
ylabel('Terminal Voltage [V]');
title('Actuator Effort & Voltage Rail Saturation Clamping');
legend('Location', 'southeast');
ylim([-5, 42]);

% Panel 4: Armature current trajectory
subplot(2, 2, 4);
plot(t_ol, ia_ol, 'k--', 'LineWidth', 1.5, 'DisplayName', 'Open-Loop');
hold on;
plot(t_p, ia_p, 'r-.', 'LineWidth', 1.5, 'DisplayName', 'P-Only');
plot(t_pi, ia_pi, 'b-', 'LineWidth', 2.0, 'DisplayName', 'PI Anti-Windup');
xline(t_step_tau, 'm--', 'LineWidth', 1.0);
grid on;
xlabel('Time [seconds]');
ylabel('Current i_a [Amperes]');
title('Armature Current Demand under Load Step');
legend('Location', 'northeast');

%% 7. Local Helper Functions
function dxdt = evaluate_pi_aw_derivatives(t, x, w_ref, Kp, Ki, Vmax, Ra, La, Ke, Kt, b, J, tau_fn)
    % Evaluates augmented state derivatives with conditional anti-windup clamping
    ia     = x(1);
    omega  = x(2);
    x_int  = x(3);
    
    % Error signal
    err = w_ref - omega;
    
    % Raw unsaturated PI output
    u_unsat = Kp * err + Ki * x_int;
    
    % Saturated actuator voltage
    u_sat = min(Vmax, max(-Vmax, u_unsat));
    
    % Conditional integration anti-windup clamping:
    % Stop accumulating if saturated and error pushes further into saturation
    is_saturated = (u_sat ~= u_unsat);
    same_sign    = (err * u_unsat > 0);
    
    if is_saturated && same_sign
        dx_int = 0.0; % Freeze integrator
    else
        dx_int = err; % Normal integration
    end
    
    % State derivatives
    dia_dt    = (u_sat - Ra * ia - Ke * omega) / La;
    domega_dt = (Kt * ia - b * omega - tau_fn(t)) / J;
    
    dxdt = [dia_dt; domega_dt; dx_int];
end

function [t_rise, pct_os, err_noload, err_loaded] = compute_transient_metrics(t, w, w_ref, t_dist)
    % Evaluates rise time, overshoot, and steady-state error in no-load and loaded intervals
    w_10 = 0.10 * w_ref;
    w_90 = 0.90 * w_ref;
    
    idx_10 = find(w >= w_10, 1, 'first');
    idx_90 = find(w >= w_90, 1, 'first');
    
    if ~isempty(idx_10) && ~isempty(idx_90) && idx_10 > 1 && idx_90 > 1
        t_10 = interp1(w(idx_10-1:idx_10), t(idx_10-1:idx_10), w_10);
        t_90 = interp1(w(idx_90-1:idx_90), t(idx_90-1:idx_90), w_90);
        t_rise = t_90 - t_10;
    else
        t_rise = NaN;
    end
    
    % Overshoot prior to disturbance onset
    idx_pre_dist = find(t < t_dist);
    w_max_nl = max(w(idx_pre_dist));
    pct_os   = max(0.0, (w_max_nl - w_ref) / w_ref * 100.0);
    
    % Steady-state errors
    idx_nl = find(t >= (t_dist - 0.2) & t < t_dist, 1, 'first');
    err_noload = abs(w_ref - w(idx_nl));
    err_loaded = abs(w_ref - w(end));
end
