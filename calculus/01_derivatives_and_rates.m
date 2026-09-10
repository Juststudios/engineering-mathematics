%% 01_derivatives_and_rates.m - Kinematics and Numerical Differentiation
% =========================================================================
% MODULE: Calculus for Engineers (R3: Change, Accumulation & Optimization)
% TOPIC : Derivatives as Instantaneous Rates of Change & Finite Differences
%
% ENGINEERING CONTEXT:
% In dynamic physical systems, sensors measure quantities at discrete time 
% intervals (sample period dt). For example, GPS or optical encoders measure 
% vehicle displacement s(t). Control systems require velocity v(t) = ds/dt 
% and acceleration a(t) = dv/dt to compute motor torque and braking force.
%
% This script demonstrates:
%   1. Continuous kinematics: s(t) -> v(t) -> a(t) with analytical derivatives
%   2. Finite difference methods: Forward, Backward, and Central differences
%   3. Convergence and truncation error analysis: O(h) vs O(h^2)
%   4. MATLAB built-in differentiation tools: diff() vs gradient()
%   5. Sensor noise sensitivity: Why numerical differentiation amplifies noise
% =========================================================================

clear;
close all;
clc;

fprintf('=======================================================\n');
fprintf('  CALCULUS FOR ENGINEERS: DERIVATIVES AND RATES        \n');
fprintf('=======================================================\n\n');

%% Section 1: Analytical Kinematics of an Accelerating Vehicle
% Consider a rocket-assisted sled with a cubic position profile over 10 s:
% Position:     s(t) = 0.5 * t^3 - 3 * t^2 + 20 * t   [meters]
% Velocity:     v(t) = ds/dt = 1.5 * t^2 - 6 * t + 20 [m/s]
% Acceleration: a(t) = dv/dt = 3.0 * t - 6             [m/s^2]
% Jerk:         j(t) = da/dt = 3.0                     [m/s^3]

t_start = 0.0;    % Start time [s]
t_end   = 10.0;   % End time [s]
dt      = 0.1;    % Nominal sampling interval [s]
t = t_start:dt:t_end; % Discrete time grid

% Analytical evaluations (ground truth)
s_exact = 0.5 .* (t.^3) - 3.0 .* (t.^2) + 20.0 .* t;
v_exact = 1.5 .* (t.^2) - 6.0 .* t + 20.0;
a_exact = 3.0 .* t - 6.0;

fprintf('--- 1. ANALYTICAL KINEMATICS AT KEY INTERVALS ---\n');
fprintf('Time t=0 s : s=%.2f m, v=%.2f m/s, a=%.2f m/s^2\n', ...
    s_exact(1), v_exact(1), a_exact(1));
fprintf('Time t=5 s : s=%.2f m, v=%.2f m/s, a=%.2f m/s^2\n', ...
    s_exact(t == 5.0), v_exact(t == 5.0), a_exact(t == 5.0));
fprintf('Time t=10 s: s=%.2f m, v=%.2f m/s, a=%.2f m/s^2\n\n', ...
    s_exact(end), v_exact(end), a_exact(end));

%% Section 2: Finite Difference Formulations (Manual Implementation)
% Given discrete samples s_k at t_k with constant step size h = dt:
%
% 1. Forward Difference:  v_fwd(k) = (s(k+1) - s(k)) / h          [O(h)]
% 2. Backward Difference: v_bwd(k) = (s(k) - s(k-1)) / h          [O(h)]
% 3. Central Difference:  v_cnt(k) = (s(k+1) - s(k-1)) / (2*h)    [O(h^2)]

N = length(t);
h = dt;

% Allocate arrays for computed velocities
v_fwd = zeros(1, N - 1); % Forward diff evaluated at indices 1 to N-1
v_bwd = zeros(1, N - 1); % Backward diff evaluated at indices 2 to N
v_cnt = zeros(1, N - 2); % Central diff evaluated at interior indices 2 to N-1

% Compute forward differences for k = 1 to N-1
for k = 1:(N - 1)
    v_fwd(k) = (s_exact(k + 1) - s_exact(k)) / h;
end

% Compute backward differences for k = 2 to N
for k = 2:N
    v_bwd(k - 1) = (s_exact(k) - s_exact(k - 1)) / h;
end

% Compute central differences for interior nodes k = 2 to N-1
for k = 2:(N - 1)
    v_cnt(k - 1) = (s_exact(k + 1) - s_exact(k - 1)) / (2 * h);
end

% Calculate maximum absolute truncation error against exact velocity
err_fwd = max(abs(v_fwd - v_exact(1:end-1)));
err_bwd = max(abs(v_bwd - v_exact(2:end)));
err_cnt = max(abs(v_cnt - v_exact(2:end-1)));

fprintf('--- 2. FINITE DIFFERENCE TRUNCATION ERROR (dt = %.3f s) ---\n', h);
fprintf('Forward Difference Max Error : %.6e m/s (First-order O(h))\n', err_fwd);
fprintf('Backward Difference Max Error: %.6e m/s (First-order O(h))\n', err_bwd);
fprintf('Central Difference Max Error : %.6e m/s (Second-order O(h^2))\n\n', err_cnt);

%% Section 3: Empirical Convergence Rate Study (O(h) vs O(h^2))
% By varying step size h over multiple orders of magnitude, we verify that
% halving h reduces first-order error by ~2x and central error by ~4x.

test_steps = [0.5, 0.25, 0.1, 0.05, 0.01, 0.005];
fwd_errors = zeros(size(test_steps));
cnt_errors = zeros(size(test_steps));

% Evaluation point for convergence check: t_eval = 4.0 s
t_eval = 4.0;
v_eval_exact = 1.5 * (t_eval^2) - 6.0 * t_eval + 20.0;

for i = 1:length(test_steps)
    step = test_steps(i);
    
    % Forward difference at t_eval
    s_curr = 0.5 * (t_eval^3) - 3.0 * (t_eval^2) + 20.0 * t_eval;
    s_plus = 0.5 * ((t_eval + step)^3) - 3.0 * ((t_eval + step)^2) + 20.0 * (t_eval + step);
    s_minus = 0.5 * ((t_eval - step)^3) - 3.0 * ((t_eval - step)^2) + 20.0 * (t_eval - step);
    
    v_fwd_est = (s_plus - s_curr) / step;
    v_cnt_est = (s_plus - s_minus) / (2 * step);
    
    fwd_errors(i) = abs(v_fwd_est - v_eval_exact);
    cnt_errors(i) = abs(v_cnt_est - v_eval_exact);
end

fprintf('--- 3. STEP SIZE CONVERGENCE AT t = %.1f s ---\n', t_eval);
fprintf('%-10s %-18s %-18s\n', 'Step (h)', 'Forward Err (m/s)', 'Central Err (m/s)');
for i = 1:length(test_steps)
    fprintf('%-10.4f %-18.4e %-18.4e\n', test_steps(i), fwd_errors(i), cnt_errors(i));
end
fprintf('\n');

%% Section 4: MATLAB Built-In Functions: diff() vs gradient()
% Common pitfall: diff(y) reduces array length by 1!
% diff(y) computes differences: [y(2)-y(1), y(3)-y(2), ..., y(N)-y(N-1)]
% To get derivative, one MUST divide by dt or diff(t).
%
% In contrast, gradient(y, dt) preserves length N:
% - Uses forward diff at first point
% - Uses central diff at all interior points
% - Uses backward diff at last point

% Method A: Using diff() with midpoint time alignment
v_diff = diff(s_exact) ./ dt;
t_mid = t(1:end-1) + dt / 2; % Correct time alignment for diff()

% Method B: Using gradient() with full array preservation
v_grad = gradient(s_exact, dt);
a_grad = gradient(v_grad, dt); % Second derivative for acceleration

max_grad_err_v = max(abs(v_grad - v_exact));
max_grad_err_a = max(abs(a_grad - a_exact));

fprintf('--- 4. MATLAB GRADIENT() ACCURACY ---\n');
fprintf('Max velocity error using gradient(): %.6e m/s\n', max_grad_err_v);
fprintf('Max accel error using gradient()   : %.6e m/s^2\n\n', max_grad_err_a);

%% Section 5: The Physical Challenge: Differentiating Noisy Sensor Data
% In real engineering telemetry, physical signals are corrupted by sensor 
% noise (thermal noise, ADC quantization).
% High-frequency noise is severely amplified by differentiation because:
% d/dt [ sin(omega * t) ] = omega * cos(omega * t)  (amplitude scaled by omega!)

rng(42); % Seed for reproducible telemetry noise
noise_sigma = 0.05; % 5 cm Gaussian measurement jitter on displacement
s_noisy = s_exact + noise_sigma * randn(size(s_exact));

% Direct numerical derivative of noisy signal
v_noisy = gradient(s_noisy, dt);
a_noisy = gradient(v_noisy, dt);

% Noise metrics: Root-Mean-Square Error (RMSE)
rmse_clean = sqrt(mean((v_grad - v_exact).^2));
rmse_noisy = sqrt(mean((v_noisy - v_exact).^2));
rmse_accel_noisy = sqrt(mean((a_noisy - a_exact).^2));

fprintf('--- 5. SENSOR NOISE AMPLIFICATION ---\n');
fprintf('Position noise standard dev (sigma): %.3f m\n', noise_sigma);
fprintf('Velocity RMSE on clean signal      : %.4e m/s\n', rmse_clean);
fprintf('Velocity RMSE on noisy signal      : %.4f m/s (severe amplification!)\n', rmse_noisy);
fprintf('Acceleration RMSE on noisy signal  : %.4f m/s^2\n\n', rmse_accel_noisy);

%% Section 6: Engineering Visualization
figure('Name', 'Kinematics and Numerical Differentiation', 'Position', [100, 100, 950, 750]);

% Subplot 1: Position Trajectory
subplot(3, 1, 1);
plot(t, s_exact, 'b-', 'LineWidth', 2); hold on;
plot(t, s_noisy, 'r.', 'MarkerSize', 8);
grid on;
title('Vehicle Trajectory: Exact vs Noisy Sensor Telemetry', 'FontSize', 12);
xlabel('Time t (seconds)');
ylabel('Position s(t) [m]');
legend('Clean Trajectory s(t)', 'Noisy Sensor Telemetry', 'Location', 'northwest');

% Subplot 2: Velocity & Truncation Comparison
subplot(3, 1, 2);
plot(t, v_exact, 'k-', 'LineWidth', 2); hold on;
plot(t_mid, v_diff, 'b--', 'LineWidth', 1.5);
plot(t, v_grad, 'g:', 'LineWidth', 2);
plot(t, v_noisy, 'r-', 'LineWidth', 0.8);
grid on;
title('Instantaneous Velocity: Analytical vs diff() vs gradient() vs Noisy', 'FontSize', 12);
xlabel('Time t (seconds)');
ylabel('Velocity v(t) [m/s]');
legend('Exact v(t)', 'diff(s)/dt (midpoints)', 'gradient(s, dt)', 'Differentiated Noisy Signal', ...
    'Location', 'northwest');

% Subplot 3: Convergence Rate (Log-Log Scale)
subplot(3, 1, 3);
loglog(test_steps, fwd_errors, 'ro-', 'LineWidth', 1.8, 'MarkerFaceColor', 'r'); hold on;
loglog(test_steps, cnt_errors, 'bs-', 'LineWidth', 1.8, 'MarkerFaceColor', 'b');
grid on;
title('Error Convergence: First-Order O(h) vs Second-Order O(h^2)', 'FontSize', 12);
xlabel('Step Size h = \Delta t (seconds)');
ylabel('Max Absolute Truncation Error [m/s]');
legend('Forward Difference O(h)', 'Central Difference O(h^2)', 'Location', 'southeast');

fprintf('Calculus script 01_derivatives_and_rates.m executed successfully.\n');
