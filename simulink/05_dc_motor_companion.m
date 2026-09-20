%% 05_dc_motor_companion.m - Electromechanical DC Motor Dynamics
% =========================================================================
% MODULE: Simulink Dynamic System Modeling (Level 2 / R5)
%
% PURPOSE:
%   Standalone MATLAB companion script modeling coupled 2nd-order
%   electromechanical DC motor state-space dynamics.
%   Integrates the coupled electrical (armature circuit) and mechanical
%   (rotor inertia) ODEs using ode45 under a rated voltage step and
%   subsequent load torque step disturbance.
%
% STATE-SPACE FORMULATION:
%   State vector: x = [i_a; omega]
%     i_a   : Armature current [Amperes]
%     omega : Rotor angular velocity [radians / second]
%
%   Electrical differential equation (KVL):
%     di_a/dt = (V_in(t) - R_a * i_a - K_e * omega) / L_a
%
%   Mechanical differential equation (Newton rotational):
%     domega/dt = (K_t * i_a - b * omega - tau_L(t)) / J
%
%   State-Space Matrix Form: dx/dt = A*x + B*u
%     A = [-R_a/L_a, -K_e/L_a;  K_t/J, -b/J]
%     B = [ 1/L_a,         0;      0,   -1/J]
%     u = [V_in(t); tau_L(t)]
%
% THEORETICAL EQUILIBRIA:
%   - No-Load Speed (tau_L = 0):
%       omega_ss = (K_t * V_in) / (R_a * b + K_t * K_e) = 80.00 rad/s
%       i_a_ss   = (b / K_t) * omega_ss = 8.00 A
%   - Loaded Speed (tau_L = 0.5 N*m):
%       omega_loaded = (K_t * V_in - R_a * tau_L) / (R_a * b + K_t * K_e) = 46.67 rad/s
%       i_a_loaded   = 9.67 A
% =========================================================================

clear;
close all;
clc;

fprintf('=================================================================\n');
fprintf('  SIMULINK COMPANION: DC MOTOR COUPLED ELECTROMECHANICAL DYNAMICS\n');
fprintf('=================================================================\n\n');

%% 1. Electromechanical Motor Parameters
R_a = 2.0;         % Armature electrical resistance [Ohms]
L_a = 0.5;         % Armature electrical inductance [Henries]
K_t = 0.1;         % Motor torque constant [N*m / A]
K_e = 0.1;         % Back-EMF voltage constant [V*s / rad]
J   = 0.02;        % Rotor & shaft moment of inertia [kg*m^2]
b   = 0.01;        % Viscous damping friction coefficient [N*m*s / rad]

% System state-space matrices
A_sys = [-R_a/L_a, -K_e/L_a; ...
          K_t/J,   -b/J];
B_sys = [1.0/L_a, 0.0; ...
         0.0,    -1.0/J];

% System characteristic equation & poles
poles_sys = eig(A_sys);
det_A     = det(A_sys);
tau_elec  = L_a / R_a; % Electrical time constant = 0.25 s
tau_mech  = J / b;     % Mechanical time constant = 2.00 s

fprintf('Motor Physical Specifications:\n');
fprintf('  Armature Resistance (R_a)   : %.2f Ohms\n', R_a);
fprintf('  Armature Inductance (L_a)   : %.2f Henries\n', L_a);
fprintf('  Torque Constant (K_t)       : %.2f N*m/A\n', K_t);
fprintf('  Back-EMF Constant (K_e)     : %.2f V*s/rad\n', K_e);
fprintf('  Rotor Inertia (J)           : %.4f kg*m^2\n', J);
fprintf('  Viscous Damping (b)         : %.4f N*m*s/rad\n', b);
fprintf('  Electrical Time Constant    : %.3f s\n', tau_elec);
fprintf('  Mechanical Time Constant    : %.3f s\n', tau_mech);
fprintf('  System Poles (Eigenvalues)  : %.4f, %.4f\n\n', poles_sys(1), poles_sys(2));

%% 2. Input Profiles & ODE Definition
V_rated  = 24.0;   % Rated armature step voltage [V] applied at t = 0
t_dist   = 3.0;    % Disturbance onset timestamp [s]
tau_load = 0.5;    % Mechanical load torque step [N*m]
t_final  = 6.0;    % Total simulation window [s]

% Input functions
v_in_func  = @(t) V_rated;
tau_l_func = @(t) (t >= t_dist) * tau_load;

% State derivative function: dx/dt = [di_a/dt; domega/dt]
motor_ode = @(t, x) [ ...
    (v_in_func(t) - R_a * x(1) - K_e * x(2)) / L_a; ...
    (K_t * x(1) - b * x(2) - tau_l_func(t)) / J ...
];

% Initial state: motor stationary with zero current at rest
x0 = [0.0; 0.0]; % [i_a(0); omega(0)]

% Configure high-precision integration options
ode_options = odeset('RelTol', 1e-6, 'AbsTol', 1e-8, 'MaxStep', 0.01);

% Solve coupled ODE system
[t_sim, x_sim] = ode45(motor_ode, [0.0, t_final], x0, ode_options);

% Extract individual state variables
i_a_sim   = x_sim(:, 1); % Armature current [A]
omega_sim = x_sim(:, 2); % Angular speed [rad/s]
rpm_sim   = omega_sim * (60.0 / (2.0 * pi)); % Speed in RPM

%% 3. Theoretical Steady-State Benchmarks
% Determinant factor: R_a * b + K_t * K_e
denom = R_a * b + K_t * K_e; % 2.0*0.01 + 0.1*0.1 = 0.03

% No-load steady-state (prior to t = 3.0 s)
omega_ss_noload_theory = (K_t * V_rated) / denom;
i_a_ss_noload_theory   = (b * omega_ss_noload_theory) / K_t;

% Loaded steady-state (after t = 3.0 s with tau_L = 0.5 N*m)
omega_ss_loaded_theory = (K_t * V_rated - R_a * tau_load) / denom;
i_a_ss_loaded_theory   = (b * omega_ss_loaded_theory + tau_load) / K_t;

% Extract numerical values from simulation
% Sample near t = 2.9 s (just before load disturbance)
idx_noload = find(t_sim >= 2.9, 1, 'first');
omega_ss_noload_sim = omega_sim(idx_noload);
i_a_ss_noload_sim   = i_a_sim(idx_noload);

% Sample at final time t = 6.0 s (after load disturbance settles)
omega_ss_loaded_sim = omega_sim(end);
i_a_ss_loaded_sim   = i_a_sim(end);

% Inrush current analysis
[i_a_peak, peak_idx] = max(i_a_sim);
t_peak = t_sim(peak_idx);
speed_droop_rad_s = omega_ss_noload_sim - omega_ss_loaded_sim;
speed_droop_pct   = (speed_droop_rad_s / omega_ss_noload_sim) * 100.0;

fprintf('Steady-State & Transient Performance Scorecard:\n');
fprintf('  Condition          Metric           Simulated      Theoretical    Delta\n');
fprintf('  ------------------------------------------------------------------------\n');
fprintf('  No-Load (t < 3s)   Speed (omega)    %8.3f rad/s  %8.3f rad/s  %8.2e\n', ...
    omega_ss_noload_sim, omega_ss_noload_theory, abs(omega_ss_noload_sim - omega_ss_noload_theory));
fprintf('  No-Load (t < 3s)   Current (i_a)    %8.3f A      %8.3f A      %8.2e\n', ...
    i_a_ss_noload_sim, i_a_ss_noload_theory, abs(i_a_ss_noload_sim - i_a_ss_noload_theory));
fprintf('  Loaded (t = 6s)    Speed (omega)    %8.3f rad/s  %8.3f rad/s  %8.2e\n', ...
    omega_ss_loaded_sim, omega_ss_loaded_theory, abs(omega_ss_loaded_sim - omega_ss_loaded_theory));
fprintf('  Loaded (t = 6s)    Current (i_a)    %8.3f A      %8.3f A      %8.2e\n', ...
    i_a_ss_loaded_sim, i_a_ss_loaded_theory, abs(i_a_ss_loaded_sim - i_a_ss_loaded_theory));
fprintf('  Inrush Peak        Peak Current     %8.3f A      at t = %.4f s\n', ...
    i_a_peak, t_peak);
fprintf('  Open-Loop Droop    Speed Droop      %8.3f rad/s  (%.1f%% droop under load)\n\n', ...
    speed_droop_rad_s, speed_droop_pct);

%% 4. Multi-Panel Electromechanical Visualization
figure('Name', 'Coupled DC Motor Dynamics', 'Color', 'w');

% Subplot 1: Angular speed response
subplot(2, 2, 1);
plot(t_sim, omega_sim, 'b-', 'LineWidth', 2.0, 'DisplayName', '\omega(t) Simulated');
hold on;
yline(omega_ss_noload_theory, 'k--', 'DisplayName', 'No-Load Target (80 rad/s)');
yline(omega_ss_loaded_theory, 'r--', 'DisplayName', 'Loaded Steady-State (46.67 rad/s)');
xline(t_dist, 'm:', 'LineWidth', 1.5, 'DisplayName', 'Disturbance Step (3.0 s)');
grid on;
xlabel('Time [seconds]');
ylabel('Angular Speed \omega [rad/s]');
title('Rotor Speed Response to Voltage & Load Steps');
legend('Location', 'southeast');

% Subplot 2: Rotational Speed in RPM
subplot(2, 2, 2);
plot(t_sim, rpm_sim, 'Color', [0.2, 0.6, 0.2], 'LineWidth', 2.0);
hold on;
xline(t_dist, 'm:', 'LineWidth', 1.5);
grid on;
xlabel('Time [seconds]');
ylabel('Speed [RPM]');
title('Shaft Speed in Revolutions Per Minute');

% Subplot 3: Armature current trajectory
subplot(2, 2, 3);
plot(t_sim, i_a_sim, 'r-', 'LineWidth', 2.0, 'DisplayName', 'i_a(t) Armature Current');
hold on;
yline(i_a_ss_noload_theory, 'k--', 'DisplayName', 'No-Load Current (8.0 A)');
yline(i_a_ss_loaded_theory, 'b--', 'DisplayName', 'Loaded Current (9.67 A)');
xline(t_dist, 'm:', 'LineWidth', 1.5);
grid on;
xlabel('Time [seconds]');
ylabel('Armature Current i_a [Amperes]');
title('Armature Current & Inrush Dynamics');
legend('Location', 'northeast');

% Subplot 4: Developed Motor Torque vs Load Torque
subplot(2, 2, 4);
tau_motor_sim = K_t .* i_a_sim;
tau_load_plot = zeros(size(t_sim));
for idx = 1:length(t_sim)
    tau_load_plot(idx) = tau_l_func(t_sim(idx));
end
plot(t_sim, tau_motor_sim, 'k-', 'LineWidth', 2.0, 'DisplayName', '\tau_{motor} = K_t \cdot i_a');
hold on;
plot(t_sim, tau_load_plot, 'm--', 'LineWidth', 1.5, 'DisplayName', '\tau_L Load Torque');
grid on;
xlabel('Time [seconds]');
ylabel('Torque [N\cdotm]');
title('Torque Balance & Disturbance Rejection');
legend('Location', 'southeast');

fprintf('=================================================================\n');
fprintf('  DC MOTOR COMPANION COMPLETED SUCCESSFULLY                      \n');
fprintf('=================================================================\n');
