%% 03_integration_accumulation.m - Physical Accumulation & Numerical Quadrature
% =========================================================================
% MODULE: Calculus for Engineers (R3: Change, Accumulation & Optimization)
% TOPIC : Definite Integration as Physical Accumulation & Numerical Quadrature
%
% ENGINEERING CONTEXT:
% While differentiation breaks continuous processes into instantaneous rates,
% integration performs the reverse: accumulating instantaneous rates into net 
% physical state variables.
%
% Three fundamental physical accumulation domains:
%   1. Kinematics:          Position s(t) = s0 + integral( v(tau) dtau )
%   2. Electrical Circuits: Charge   Q(t) = Q0 + integral( I(tau) dtau )
%   3. Energy Systems:      Energy   E(t) = E0 + integral( P(tau) dtau )
%
% In this script:
%   - We implement discrete quadrature using trapz() and cumtrapz()
%   - We solve continuous integrals using adaptive Gauss-Kronrod: integral()
%   - We compare numerical integration schemes: Rectangular vs Trapezoidal vs Simpson's
%   - We analyze non-uniform telemetry time steps and grid convergence
% =========================================================================

clear;
close all;
clc;

fprintf('=======================================================\n');
fprintf('  CALCULUS FOR ENGINEERS: INTEGRATION & ACCUMULATION   \n');
fprintf('=======================================================\n\n');

%% Section 1: Physical Accumulation 1 - Velocity to Position
% An electric delivery van starts from rest (s0 = 0 m).
% During an urban acceleration phase, velocity follows a sinusoid:
%   v(t) = 12 * sin(pi * t / 10)  [m/s],  for t in [0, 10] s
%
% Analytical displacement:
%   s(t) = integral_0^t 12 * sin(pi * tau / 10) dtau
%        = 12 * (10 / pi) * [ 1 - cos(pi * t / 10) ]

t_total = 10.0;     % Duration [s]
dt = 0.05;          % Sampling period [s]
t_van = 0:dt:t_total;

v_van = 12.0 * sin(pi * t_van / 10.0); % Velocity [m/s]
s_van_exact = 12.0 * (10.0 / pi) * (1.0 - cos(pi * t_van / 10.0));

% Numerical cumulative integration using cumtrapz
s_van_num = cumtrapz(t_van, v_van);
van_total_dist_trapz = trapz(t_van, v_van);
van_total_dist_exact = s_van_exact(end);

fprintf('--- 1. VEHICLE DISPLACEMENT ACCUMULATION (v -> s) ---\n');
fprintf('Exact Total Distance Traveled    : %.4f m\n', van_total_dist_exact);
fprintf('Numerical Distance (trapz)       : %.4f m\n', van_total_dist_trapz);
fprintf('Max Trajectory Error (cumtrapz)  : %.4e m\n\n', max(abs(s_van_num - s_van_exact)));

%% Section 2: Physical Accumulation 2 - Current to Charge (Battery Charging)
% An EV lithium-ion battery cell is charged using a constant-current 
% constant-voltage (CCCV) profile modeled as an exponential decay:
%   I(t) = I_max * exp(-t / tau_charge)   [Amperes]
% where I_max = 50 A and tau_charge = 1800 s (30 minutes).
%
% Total charge delivered: Q = integral_0^T I(t) dt [Coulombs = A*s]
% Battery capacity in Ampere-hours: C_Ah = Q / 3600

I_max = 50.0;           % Peak charging current [A]
tau_charge = 1800.0;    % Time constant [s]
t_charge_end = 3600.0;  % 1 hour of charging [s]

t_battery = linspace(0, t_charge_end, 2000); % Time vector [s]
I_battery = I_max * exp(-t_battery / tau_charge); % Current [A]

% Analytical charge:
% Q_exact = I_max * tau_charge * (1 - exp(-T / tau_charge))
Q_exact = I_max * tau_charge * (1.0 - exp(-t_charge_end / tau_charge));

% Numerical charge accumulation
Q_num = trapz(t_battery, I_battery);
Q_trajectory = cumtrapz(t_battery, I_battery);

fprintf('--- 2. BATTERY CHARGE ACCUMULATION (I -> Q) ---\n');
fprintf('Analytical Charge Delivered : %.2f Coulombs (%.4f Ah)\n', ...
    Q_exact, Q_exact / 3600);
fprintf('Numerical Charge Delivered  : %.2f Coulombs (%.4f Ah)\n', ...
    Q_num, Q_num / 3600);
fprintf('Relative Integration Error  : %.4e %%\n\n', ...
    abs(Q_num - Q_exact) / Q_exact * 100);

%% Section 3: Physical Accumulation 3 - Power to Energy
% Instantaneous electrical power drawn by an industrial facility fluctuates:
%   P(t) = P_base + P_peak * sin(2 * pi * t / T_shift)^2 + P_transient * exp(-t / 300)
% Total energy: E = integral P(t) dt [Joules or kiloWatt-hours (kWh)]

P_base = 25.0e3;        % Base load: 25 kW
P_peak = 60.0e3;        % Cyclic machinery peak: 60 kW
P_transient = 15.0e3;   % Morning startup surge: 15 kW
T_shift = 28800.0;      % 8-hour shift duration [s]

t_power = linspace(0, T_shift, 5000);
P_facility = P_base + P_peak .* (sin(2.0 * pi .* t_power ./ T_shift).^2) + ...
    P_transient .* exp(-t_power ./ 300.0);

% Accumulated energy over 8-hour shift in Joules and kWh (1 kWh = 3.6e6 J)
E_joules = trapz(t_power, P_facility);
E_kwh = E_joules / 3.6e6;
E_trajectory_kwh = cumtrapz(t_power, P_facility) / 3.6e6;

fprintf('--- 3. INDUSTRIAL POWER TO ENERGY (P -> E) ---\n');
fprintf('Average Facility Power : %.2f kW\n', mean(P_facility) / 1000);
fprintf('Peak Facility Power    : %.2f kW\n', max(P_facility) / 1000);
fprintf('Total Energy Consumed  : %.2f kWh (%.2e Joules)\n\n', E_kwh, E_joules);

%% Section 4: Continuous Integration with MATLAB integral()
% For mathematically defined continuous functions, integral() performs 
% adaptive Gauss-Kronrod quadrature, achieving high numerical precision.
%
% Test problem: Aerodynamic drag work done over distance x in [0, 500] m:
%   F_drag(x) = 0.5 * rho * Cd * A * v(x)^2
% where v(x) = 20 + 0.05 * x

rho = 1.225;     % Air density [kg/m^3]
Cd  = 0.28;      % Drag coefficient [dimensionless]
A_frontal = 2.4; % Frontal area [m^2]

drag_force = @(x) 0.5 .* rho .* Cd .* A_frontal .* ((20.0 + 0.05 .* x).^2);

% Compute work done: W = integral_0^500 F_drag(x) dx
x_a = 0.0;
x_b = 500.0;
work_adaptive = integral(drag_force, x_a, x_b, 'RelTol', 1e-10, 'AbsTol', 1e-12);

% Compare with coarse trapezoidal approximation across 20 samples
x_coarse = linspace(x_a, x_b, 20);
F_coarse = drag_force(x_coarse);
work_coarse = trapz(x_coarse, F_coarse);

fprintf('--- 4. CONTINUOUS QUADRATURE: integral() vs trapz() ---\n');
fprintf('Adaptive Gauss-Kronrod Work: %.4f J\n', work_adaptive);
fprintf('Coarse trapz (N=20 points) : %.4f J (Discretization Error: %.2f J)\n\n', ...
    work_coarse, abs(work_coarse - work_adaptive));

%% Section 5: Quadrature Comparison - Rectangular vs Trapezoidal vs Simpson's
% We benchmark three classic numerical integration methods on the test function:
%   f(x) = x * exp(-x),   on [0, 4]
% Analytical: integral_0^4 x*exp(-x) dx = 1 - 5*exp(-4) ~= 0.908421805556

test_fun = @(x) x .* exp(-x);
exact_integral = 1.0 - 5.0 * exp(-4.0);

N_panels = [4, 8, 16, 32, 64, 128, 256];
err_rect = zeros(size(N_panels));
err_trap = zeros(size(N_panels));
err_simp = zeros(size(N_panels));

for i = 1:length(N_panels)
    n = N_panels(i);
    dx = 4.0 / n;
    x_nodes = linspace(0, 4, n + 1);
    y_nodes = test_fun(x_nodes);
    
    % 1. Left Riemann Sum (Rectangular Rule, O(h))
    I_rect = sum(y_nodes(1:end-1)) * dx;
    err_rect(i) = abs(I_rect - exact_integral);
    
    % 2. Trapezoidal Rule (O(h^2))
    I_trap = trapz(x_nodes, y_nodes);
    err_trap(i) = abs(I_trap - exact_integral);
    
    % 3. Simpson's 1/3 Rule (O(h^4)) - Requires even number of panels
    % I_simp = (dx/3) * [ y0 + 4*sum(odd) + 2*sum(even) + yn ]
    I_simp = (dx / 3.0) * (y_nodes(1) + ...
        4.0 * sum(y_nodes(2:2:end-1)) + ...
        2.0 * sum(y_nodes(3:2:end-2)) + ...
        y_nodes(end));
    err_simp(i) = abs(I_simp - exact_integral);
end

fprintf('--- 5. QUADRATURE ACCURACY CONVERGENCE ---\n');
fprintf('%-6s %-16s %-16s %-16s\n', 'Panels', 'Rect Error', 'Trapz Error', 'Simpson Error');
for i = 1:length(N_panels)
    fprintf('%-6d %-16.4e %-16.4e %-16.4e\n', ...
        N_panels(i), err_rect(i), err_trap(i), err_simp(i));
end
fprintf('\n');

%% Section 6: Engineering Visualization
figure('Name', 'Physical Accumulation and Numerical Quadrature', ...
    'Position', [120, 120, 1000, 750]);

% Subplot 1: Vehicle Velocity and Accumulated Distance
subplot(2, 2, 1);
yyaxis left;
plot(t_van, v_van, 'b-', 'LineWidth', 1.8);
ylabel('Velocity v(t) [m/s]');
grid on;
yyaxis right;
plot(t_van, s_van_num, 'r--', 'LineWidth', 2);
ylabel('Accumulated Position s(t) [m]');
title('Kinematic Accumulation: v(t) \rightarrow s(t)', 'FontSize', 11);
xlabel('Time t [seconds]');

% Subplot 2: Battery Charging Current and Accumulated Charge
subplot(2, 2, 2);
yyaxis left;
plot(t_battery / 60, I_battery, 'b-', 'LineWidth', 1.8);
ylabel('Current I(t) [A]');
grid on;
yyaxis right;
plot(t_battery / 60, Q_trajectory / 3600, 'm--', 'LineWidth', 2);
ylabel('Accumulated Charge [Ah]');
title('Battery Charging: I(t) \rightarrow Q(t)', 'FontSize', 11);
xlabel('Time t [minutes]');

% Subplot 3: Power Load and Accumulated Energy
subplot(2, 2, 3);
yyaxis left;
plot(t_power / 3600, P_facility / 1000, 'Color', [0.2, 0.6, 0.2], 'LineWidth', 1.5);
ylabel('Power Demand P(t) [kW]');
grid on;
yyaxis right;
plot(t_power / 3600, E_trajectory_kwh, 'k-', 'LineWidth', 2);
ylabel('Accumulated Energy [kWh]');
title('Energy Auditing: P(t) \rightarrow E(t)', 'FontSize', 11);
xlabel('Time t [hours]');

% Subplot 4: Quadrature Convergence Comparison (Log-Log Scale)
subplot(2, 2, 4);
panel_widths = 4.0 ./ N_panels;
loglog(panel_widths, err_rect, 'ro-', 'LineWidth', 1.5, 'MarkerFaceColor', 'r'); hold on;
loglog(panel_widths, err_trap, 'bs-', 'LineWidth', 1.5, 'MarkerFaceColor', 'b');
loglog(panel_widths, err_simp, 'g^-', 'LineWidth', 1.5, 'MarkerFaceColor', 'g');
grid on;
title('Convergence: Rectangular vs Trapezoidal vs Simpson', 'FontSize', 11);
xlabel('Panel Width h = \Delta x');
ylabel('Absolute Quadrature Error');
legend('Rectangular O(h)', 'Trapezoidal O(h^2)', 'Simpson O(h^4)', 'Location', 'southeast');

fprintf('Calculus script 03_integration_accumulation.m executed successfully.\n');
