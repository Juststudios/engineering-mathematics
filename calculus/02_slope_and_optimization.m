%% 02_slope_and_optimization.m - Tangent Lines, Critical Points & Optimization
% =========================================================================
% MODULE: Calculus for Engineers (R3: Change, Accumulation & Optimization)
% TOPIC : Slope Visualization, Extrema Classification & Loss Minimization
%
% ENGINEERING CONTEXT:
% Engineering design is fundamentally about optimization:
%   - Minimizing material cost while satisfying stress thresholds
%   - Minimizing fuel consumption or drag in aerodynamic profiles
%   - Minimizing calibration error (loss functions) in sensor processing
%
% Calculus provides the core mechanism:
%   1. The first derivative f'(x) gives the slope of the tangent line.
%   2. Critical points occur where f'(x) = 0 (stationary points).
%   3. The second derivative f''(x) reveals curvature:
%        f''(x) > 0 -> Local Minimum (Stable equilibrium / Optimal design)
%        f''(x) < 0 -> Local Maximum (Peak stress / Unstable point)
%   4. In Machine Learning (Level 3), Gradient Descent finds optimal weights
%      by iteratively stepping downhill against the gradient of the loss.
% =========================================================================

clear;
close all;
clc;

fprintf('=======================================================\n');
fprintf('  CALCULUS FOR ENGINEERS: SLOPE AND OPTIMIZATION       \n');
fprintf('=======================================================\n\n');

%% Section 1: Tangent Line Visualization on a Dynamic Cost Function
% Consider the total operating cost of an industrial pump as a function 
% of operating speed omega (in kRPM, thousands of RPM):
% Cost C(w) = w^4 - 8*w^3 + 18*w^2 - 5*w + 12   [$ / hour]
% Domain: w in [0.0, 4.5] kRPM

w_grid = linspace(0.0, 4.5, 500);

% Define cost function and its analytical derivatives
cost_fun  = @(w) w.^4 - 8.0.*(w.^3) + 18.0.*(w.^2) - 5.0.*w + 12.0;
dcost_dw  = @(w) 4.0.*(w.^3) - 24.0.*(w.^2) + 36.0.*w - 5.0;
d2cost_dw = @(w) 12.0.*(w.^2) - 48.0.*w + 36.0;

C_vals = cost_fun(w_grid);
dC_vals = dcost_dw(w_grid);

% Select an arbitrary operating speed to construct the tangent line
w_sample = 2.5; % Operating point [kRPM]
C_sample = cost_fun(w_sample);
slope_sample = dcost_dw(w_sample);

% Tangent line equation: y - y0 = m * (x - x0) -> y = y0 + m * (x - x0)
w_tangent_span = linspace(w_sample - 0.7, w_sample + 0.7, 50);
C_tangent = C_sample + slope_sample .* (w_tangent_span - w_sample);

fprintf('--- 1. TANGENT LINE AT OPERATING POINT ---\n');
fprintf('Operating speed w0  : %.2f kRPM\n', w_sample);
fprintf('Operating cost C(w0): $%.2f / hour\n', C_sample);
fprintf('Marginal cost C''(w0): $%.2f / (hour * kRPM) [Tangent Slope]\n\n', slope_sample);

%% Section 2: Finding Critical Points Analytically & Numerically
% Critical points occur where dC/dw = 0:
% 4 * w^3 - 24 * w^2 + 36 * w - 5 = 0
% We find roots of this cubic polynomial using MATLAB's roots()

cubic_poly = [4.0, -24.0, 36.0, -5.0];
crit_roots = roots(cubic_poly);

% Keep only real roots within the operating domain [0, 4.5]
real_crit = crit_roots(imag(crit_roots) == 0);
valid_crit = real_crit(real_crit >= 0 & real_crit <= 4.5);
valid_crit = sort(valid_crit); % Sort in ascending order

fprintf('--- 2. CRITICAL POINTS AND SECOND DERIVATIVE CLASSIFICATION ---\n');
fprintf('%-10s %-12s %-14s %-16s %-18s\n', ...
    'Root (w)', 'Cost C(w)', '1st Deriv f''', '2nd Deriv f''''', 'Classification');

for i = 1:length(valid_crit)
    w_crit = valid_crit(i);
    cost_crit = cost_fun(w_crit);
    f1_crit = dcost_dw(w_crit);
    f2_crit = d2cost_dw(w_crit);
    
    if f2_crit > 0
        nature = 'LOCAL MINIMUM (Optimal)';
    elseif f2_crit < 0
        nature = 'LOCAL MAXIMUM (Cost Peak)';
    else
        nature = 'INFLECTION POINT';
    end
    
    fprintf('%-10.4f $%-11.2f %-14.2e %-16.4f %-18s\n', ...
        w_crit, cost_crit, f1_crit, f2_crit, nature);
end
fprintf('\n');

%% Section 3: Engineering Loss Minimization (Machine Learning Intuition)
% In ML and parameter estimation, we calibrate a model parameter theta 
% by minimizing a loss function L(theta) that measures prediction error.
%
% Problem: Calibrate sensor scale factor theta for an optical pyrometer.
% Given measured true temperatures T_true and sensor voltage V_sensor:
% Prediction: T_hat = theta * V_sensor
% Mean Squared Error Loss: L(theta) = (1/M) * sum( (T_true - theta * V_sensor)^2 )
%
% Expanding L(theta):
% L(theta) = c2 * theta^2 - 2 * c1 * theta + c0
% This is a convex quadratic bowl with a unique global minimum!

M_samples = 20;
rng(101);
V_sensor = linspace(0.5, 4.5, M_samples);
true_scale = 18.5; % True physics: 18.5 deg C / Volt
sensor_noise = 1.2 * randn(1, M_samples);
T_true = true_scale * V_sensor + sensor_noise;

% Analytical coefficients for quadratic loss:
% L(theta) = (1/M) * [ sum(V^2)*theta^2 - 2*sum(T*V)*theta + sum(T^2) ]
c2 = mean(V_sensor.^2);
c1 = mean(T_true .* V_sensor);
c0 = mean(T_true.^2);

loss_fun = @(th) c2 .* (th.^2) - 2.0 .* c1 .* th + c0;
dloss_dth = @(th) 2.0 .* c2 .* th - 2.0 .* c1;

% Analytical optimal theta* where dL/dth = 0:
theta_star = c1 / c2;
min_loss = loss_fun(theta_star);

fprintf('--- 3. SENSOR CALIBRATION LOSS FUNCTION ---\n');
fprintf('True Scale Factor theta_true : %.2f degC/V\n', true_scale);
fprintf('Analytical Optimum theta*   : %.4f degC/V\n', theta_star);
fprintf('Minimum Residual Loss L(th*): %.4f (degC)^2\n\n', min_loss);

%% Section 4: 1D Gradient Descent Optimization Algorithm
% Gradient descent iteratively updates theta in the direction of steepest descent:
%   theta_{k+1} = theta_k - alpha * dL/dth(theta_k)
% where alpha is the learning rate (step size).

alpha = 0.08;            % Learning rate [dimensionless]
max_iter = 30;           % Maximum iterations
tol = 1e-6;              % Convergence tolerance on gradient magnitude

% Initial guess (intentionally far from optimum)
theta_init = 5.0;        % Initial guess: 5 degC/V

theta_history = zeros(1, max_iter + 1);
loss_history  = zeros(1, max_iter + 1);
grad_history  = zeros(1, max_iter + 1);

theta_history(1) = theta_init;
loss_history(1)  = loss_fun(theta_init);
grad_history(1)  = dloss_dth(theta_init);

fprintf('--- 4. GRADIENT DESCENT ITERATION HISTORY ---\n');
fprintf('%-6s %-16s %-16s %-16s\n', 'Iter', 'Theta (degC/V)', 'Loss L(theta)', 'Grad dL/dtheta');

converged_iter = max_iter;
for k = 1:max_iter
    curr_theta = theta_history(k);
    grad = dloss_dth(curr_theta);
    
    if abs(grad) < tol
        converged_iter = k - 1;
        theta_history = theta_history(1:k);
        loss_history = loss_history(1:k);
        grad_history = grad_history(1:k);
        break;
    end
    
    % Gradient update step
    next_theta = curr_theta - alpha * grad;
    
    theta_history(k + 1) = next_theta;
    loss_history(k + 1)  = loss_fun(next_theta);
    grad_history(k + 1)  = grad;
    
    if mod(k, 5) == 0 || k == 1
        fprintf('%-6d %-16.4f %-16.4f %-16.4e\n', ...
            k, curr_theta, loss_history(k), grad);
    end
end

final_theta = theta_history(end);
fprintf('Final Iter %-4d: theta = %.4f, Loss = %.4f, Grad = %.2e\n\n', ...
    length(theta_history)-1, final_theta, loss_history(end), grad_history(end));

%% Section 5: Engineering Visualization
figure('Name', 'Slope, Critical Points, and Gradient Optimization', ...
    'Position', [150, 150, 1000, 750]);

% Subplot 1: Cost Function and Tangent Line
subplot(2, 2, 1);
plot(w_grid, C_vals, 'b-', 'LineWidth', 2); hold on;
plot(w_tangent_span, C_tangent, 'r--', 'LineWidth', 1.8);
plot(w_sample, C_sample, 'ko', 'MarkerFaceColor', 'r', 'MarkerSize', 8);

% Mark critical points
for i = 1:length(valid_crit)
    cw = valid_crit(i);
    cC = cost_fun(cw);
    if d2cost_dw(cw) > 0
        plot(cw, cC, 'g^', 'MarkerFaceColor', 'g', 'MarkerSize', 9); % Local min
    else
        plot(cw, cC, 'rv', 'MarkerFaceColor', 'r', 'MarkerSize', 9); % Local max
    end
end
grid on;
title('Operating Cost Curve & Critical Points', 'FontSize', 11);
xlabel('Operating Speed \omega (kRPM)');
ylabel('Cost C(\omega) [$/hour]');
legend('Cost Function C(\omega)', 'Tangent Line', 'Evaluation Point', ...
    'Local Minimum (Optimum)', 'Local Maximum (Peak)', 'Location', 'north');

% Subplot 2: First Derivative (Slope)
subplot(2, 2, 2);
plot(w_grid, dC_vals, 'k-', 'LineWidth', 1.8); hold on;
plot([0, 4.5], [0, 0], 'k:'); % Zero-slope reference line
plot(valid_crit, zeros(size(valid_crit)), 'mo', 'MarkerFaceColor', 'm', 'MarkerSize', 8);
grid on;
title('First Derivative: C''(\omega) = 0 Identifies Extrema', 'FontSize', 11);
xlabel('Operating Speed \omega (kRPM)');
ylabel('Marginal Cost dC/d\omega');
legend('dC/d\omega (Slope)', 'Zero-Crossing Threshold', 'Critical Points', 'Location', 'northwest');

% Subplot 3: Loss Function Bowl and Gradient Descent Trajectory
subplot(2, 2, 3);
theta_span = linspace(2.0, 25.0, 300);
plot(theta_span, loss_fun(theta_span), 'b-', 'LineWidth', 2); hold on;
plot(theta_history, loss_history, 'r.-', 'LineWidth', 1.5, 'MarkerSize', 12);
plot(theta_star, min_loss, 'kp', 'MarkerFaceColor', 'y', 'MarkerSize', 12);
grid on;
title('Loss Surface & Gradient Descent Trajectory', 'FontSize', 11);
xlabel('Parameter \theta (degC / Volt)');
ylabel('Loss L(\theta) [(degC)^2]');
legend('Loss Surface L(\theta)', 'Optimization Path', 'Global Minimum \theta^*', 'Location', 'north');

% Subplot 4: Loss Convergence vs Iteration
subplot(2, 2, 4);
plot(0:(length(loss_history)-1), loss_history, 'bo-', 'LineWidth', 1.5, 'MarkerFaceColor', 'b');
grid on;
title('Convergence of Loss Function L(\theta_k)', 'FontSize', 11);
xlabel('Iteration Step k');
ylabel('Mean Squared Error Loss');

fprintf('Calculus script 02_slope_and_optimization.m executed successfully.\n');
