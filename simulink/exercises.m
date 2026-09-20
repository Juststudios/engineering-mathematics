%% exercises.m - 4-Tier Progressive Exercises: Simulink Dynamic Modeling
% =========================================================================
% MODULE: Simulink for Beginners (Dynamic System Modeling) (R5)
%
% INSTRUCTIONS:
% Complete the exercises in each of the 4 progressive pedagogical tiers:
%   Level 1: Recall (Transfer function poles, time constants, and DC gains)
%   Level 2: Understanding & Debugging (Algebraic loops & numerical stability limits)
%   Level 3: Application (Series RLC 2nd-order dynamic simulation in 3 damping regimes)
%   Level 4: Challenge (DC motor closed-loop PI anti-windup regulation under disturbance)
%
% Look for '% TODO' comments where your code and calculations are required.
% =========================================================================

clear;
close all;
clc;

fprintf('=================================================================\n');
fprintf('  SIMULINK DYNAMIC MODELING: STUDENT EXERCISE SUITE              \n');
fprintf('=================================================================\n\n');

%% Level 1: Recall
% -------------------------------------------------------------------------
% Problem 1.1: First-Order System Pole & Time Constant Calculation
% A physical RC filter has R = 20.0 kOhm and C = 50.0 uF.
%
% Tasks:
%   1. Compute the theoretical time constant tau_1 = R * C [seconds].
%   2. Compute the system pole location s_pole = -1 / tau_1 [rad/s].
%   3. Compute the 10%-to-90% rise time t_r = tau_1 * ln(9) [seconds].
%   4. Compute the 2% settling time t_s = -tau_1 * ln(0.02) [seconds].
% -------------------------------------------------------------------------

R_1 = 20.0e3;  % 20 kOhm [Ohms]
C_1 = 50.0e-6; % 50 uF [Farads]

% TODO: Task 1.1.1 - Calculate circuit time constant tau_1 = R_1 * C_1
tau_1 = 0; % Replace with your calculation

% TODO: Task 1.1.2 - Calculate continuous-time pole location s_pole = -1 / tau_1
s_pole_1 = 0; % Replace with -1 / tau_1

% TODO: Task 1.1.3 - Calculate theoretical 10%-to-90% rise time t_rise_1 = tau_1 * log(9)
t_rise_1 = 0; % Replace with tau_1 * log(9.0)

% TODO: Task 1.1.4 - Calculate theoretical 2% settling time t_settle_1 = -tau_1 * log(0.02)
t_settle_1 = 0; % Replace with -tau_1 * log(0.02)

fprintf('--- Level 1.1: First-Order RC Characteristics ---\n');
fprintf('Time Constant (tau)          : %.4f seconds\n', tau_1);
fprintf('System Pole (s_p)            : %.4f rad/s\n', s_pole_1);
fprintf('Theoretical Rise Time (t_r)  : %.4f seconds\n', t_rise_1);
fprintf('Theoretical Settling Time(t_s): %.4f seconds\n\n', t_settle_1);

% -------------------------------------------------------------------------
% Problem 1.2: DC Gain & Steady-State Evaluation
% A thermal sensor produces voltage V_out in response to temperature change Delta_T:
%   G(s) = K_dc / (tau_th * s + 1)
% where K_dc = 0.050 V/deg C and tau_th = 8.0 seconds.
%
% Tasks:
%   1. Compute the steady-state sensor output voltage for a Delta_T = 60.0 deg C step.
%   2. Compute the sensor voltage at elapsed time t = tau_th (1 time constant, 63.2%).
% -------------------------------------------------------------------------

K_dc_2   = 0.050; % Sensitivity [V / deg C]
tau_th_2 = 8.0;   % Thermal time constant [s]
delta_T_step = 60.0; % Thermal step amplitude [deg C]

% TODO: Task 1.2.1 - Compute steady-state output voltage V_ss = K_dc_2 * delta_T_step
V_ss_2 = 0; % Replace with K_dc_2 * delta_T_step

% TODO: Task 1.2.2 - Compute output voltage at t = tau_th: V(tau) = V_ss * (1 - exp(-1))
V_at_tau_2 = 0; % Replace with V_ss_2 * (1.0 - exp(-1.0))

fprintf('--- Level 1.2: Thermal Sensor DC Gain Evaluation ---\n');
fprintf('Steady-State Output (V_ss)   : %.4f Volts\n', V_ss_2);
fprintf('Output at 1 Time Constant    : %.4f Volts (%.1f%% of V_ss)\n\n', ...
    V_at_tau_2, (V_at_tau_2 / V_ss_2) * 100.0);


%% Level 2: Understanding & Debugging
% -------------------------------------------------------------------------
% Debugging Task 2.1: Diagnosing and Breaking an Algebraic Loop
% A junior engineer built a feedback block diagram where two gain blocks
% are coupled directly in a closed algebraic loop without state dynamics:
%
% FLAGGED CODE:
%   % Loop equation: y = K1 * (u - K2 * y)
%   % Rearranging algebraically: y * (1 + K1 * K2) = K1 * u
%   % Junior engineer attempted naive iterative loop without convergence guard:
%   u = 10.0; K1 = 4.0; K2 = 0.5;
%
% Tasks:
%   1. Calculate the exact closed-form algebraic solution: y_exact = (K1 * u) / (1 + K1 * K2).
%   2. Simulate a 1st-order low-pass filter insertion to break the algebraic loop:
%      dy/dt = (K1 * (u - K2 * y) - y) / tau_filter with tau_filter = 0.05 s.
%   3. Verify that the dynamic filter relaxes to y_exact as t -> inf.
% -------------------------------------------------------------------------

u_alg  = 10.0;
K1_alg = 4.0;
K2_alg = 0.5;

% TODO: Task 2.1.1 - Compute analytical closed-form solution y_exact
y_exact_2 = 0; % Replace with (K1_alg * u_alg) / (1.0 + K1_alg * K2_alg)

% Dynamic relaxation filter to break algebraic loop:
tau_filter = 0.05; % Fast state delay [seconds]
loop_ode = @(t, y) (K1_alg * (u_alg - K2_alg * y) - y) / tau_filter;

% TODO: Task 2.1.2 - Integrate loop_ode using ode45 over [0, 0.5] seconds starting from y=0
t_span_alg = [0.0, 0.5];
y0_alg     = 0.0;
t_alg_sim  = []; % Replace with ode45 output
y_alg_sim  = []; % Replace with ode45 output

% TODO: Task 2.1.3 - Evaluate final value discrepancy |y_alg_sim(end) - y_exact_2|
alg_error = 0; % Replace with abs(y_alg_sim(end) - y_exact_2)

fprintf('--- Level 2.1: Algebraic Loop Resolution ---\n');
fprintf('Exact Closed-Form Solution (y_exact) : %.4f\n', y_exact_2);
fprintf('Dynamic Filter Steady-State          : %.4f\n', y_exact_2);
fprintf('Algebraic Loop Discrepancy           : %.2e\n\n', alg_error);

% -------------------------------------------------------------------------
% Debugging Task 2.2: Forward Euler Numerical Stability & Critical Step Size
% In Simulink fixed-step simulations, selecting Forward Euler (ode1) with an
% excessively large time step dt causes explosive numerical divergence.
%
% For a 1st-order system dy/dt = -a * y with eigenvalue lambda = -a (a > 0):
%   Discrete update: y[k+1] = (1 - a * dt) * y[k]
%   Stability requires: |1 - a * dt| < 1  ==>  dt < 2 / a
%
% Tasks:
%   1. For a system with decay rate a = 20.0 s^-1 (tau = 0.05 s), compute the
%      critical maximum stable time step dt_crit = 2 / a.
%   2. Simulate 50 steps of Forward Euler with stable dt = 0.8 * dt_crit.
%   3. Simulate 50 steps of Forward Euler with unstable dt = 1.2 * dt_crit.
%   4. Verify that the unstable step diverges (|y_unstable[end]| > 1e3).
% -------------------------------------------------------------------------

a_decay = 20.0; % Decay rate [s^-1]

% TODO: Task 2.2.1 - Compute critical maximum stable time step dt_crit = 2.0 / a_decay
dt_crit = 0; % Replace with 2.0 / a_decay

% Stable simulation parameters
dt_stable = 0.80 * dt_crit;
N_steps   = 50;
y_stable  = zeros(1, N_steps);
y_stable(1) = 1.0; % Initial perturbation

% TODO: Task 2.2.2 - Run Forward Euler loop for stable step size
% for k = 1:(N_steps - 1)
%     y_stable(k + 1) = (1.0 - a_decay * dt_stable) * y_stable(k);
% end

% Unstable simulation parameters
dt_unstable = 1.20 * dt_crit;
y_unstable  = zeros(1, N_steps);
y_unstable(1) = 1.0;

% TODO: Task 2.2.3 - Run Forward Euler loop for unstable step size
% for k = 1:(N_steps - 1)
%     y_unstable(k + 1) = (1.0 - a_decay * dt_unstable) * y_unstable(k);
% end

fprintf('--- Level 2.2: Forward Euler Numerical Stability ---\n');
fprintf('Critical Step Size (dt_crit = 2/a)   : %.4f seconds\n', dt_crit);
fprintf('Stable Step (0.8*dt_crit) Final y    : %.4e (Converges to 0)\n', 0.0);
fprintf('Unstable Step (1.2*dt_crit) Final y  : %.4e (Diverges!)\n\n', 1.0);


%% Level 3: Application
% -------------------------------------------------------------------------
% Problem 3: Second-Order Series RLC Resonant Circuit Dynamic Simulation
% A series RLC circuit is driven by a 10.0 V step voltage.
% Parameters:
%   - Inductance : L = 10.0 mH = 0.010 H
%   - Capacitance: C = 100.0 uF = 1.0e-4 F
%   - Undamped natural frequency: omega_n = 1 / sqrt(L * C) = 1000.0 rad/s
%   - Characteristic impedance  : Z_0 = sqrt(L / C) = 10.0 Ohms
%   - Critical damping resistance: R_crit = 2 * Z_0 = 20.0 Ohms
%
% State variables: x = [i_L; v_C]
%   di_L/dt = (V_in - R * i_L - v_C) / L
%   dv_C/dt = i_L / C
%
% Damping Regimes:
%   1. Underdamped (zeta = 0.25): R_under = 0.25 * R_crit = 5.0 Ohms
%   2. Critically Damped (zeta = 1.0): R_crit = 20.0 Ohms
%   3. Overdamped (zeta = 2.5): R_over = 2.5 * R_crit = 50.0 Ohms
%
% Tasks:
%   1. Integrate the state equations for all 3 damping regimes using ode45 over [0, 0.02] s.
%   2. Calculate the peak overshoot for the underdamped regime (%OS).
%   3. Verify theoretical underdamped overshoot: %OS_theory = exp(-pi*zeta / sqrt(1 - zeta^2)) * 100.
% -------------------------------------------------------------------------

L_3 = 10.0e-3; % 10 mH [H]
C_3 = 100.0e-6;% 100 uF [F]
V_in_3 = 10.0; % Step input [V]
t_span_3 = [0.0, 0.025]; % Simulation time window [s]

omega_n_3 = 1.0 / sqrt(L_3 * C_3); % Natural frequency = 1000 rad/s
R_crit_3  = 2.0 * sqrt(L_3 / C_3); % Critical resistance = 20 Ohms

% Damping cases
zeta_under = 0.25;
R_under    = 2.0 * zeta_under * sqrt(L_3 / C_3); % 5.0 Ohms
R_crit     = R_crit_3;                            % 20.0 Ohms
zeta_over  = 2.50;
R_over     = 2.0 * zeta_over * sqrt(L_3 / C_3);  % 50.0 Ohms

% TODO: Task 3.1 - Define ODE functions and integrate for all three damping cases
% rlc_ode = @(t, x, R) [(V_in_3 - R * x(1) - x(2)) / L_3; x(1) / C_3];
% [t_under, x_under] = ode45(@(t, x) rlc_ode(t, x, R_under), t_span_3, [0.0; 0.0]);
% [t_crit,  x_crit]  = ode45(@(t, x) rlc_ode(t, x, R_crit),  t_span_3, [0.0; 0.0]);
% [t_over,  x_over]  = ode45(@(t, x) rlc_ode(t, x, R_over),  t_span_3, [0.0; 0.0]);

% TODO: Task 3.2 - Compute simulated percent overshoot for underdamped capacitor voltage
% vC_under = x_under(:, 2);
% OS_sim_3 = (max(vC_under) - V_in_3) / V_in_3 * 100.0;
OS_sim_3 = 0; % Replace with simulated overshoot %

% TODO: Task 3.3 - Compute theoretical percent overshoot for zeta = 0.25
% OS_theory_3 = exp(-pi * zeta_under / sqrt(1.0 - zeta_under^2)) * 100.0;
OS_theory_3 = 0; % Replace with theoretical formula

fprintf('--- Level 3: RLC Resonant Dynamics ---\n');
fprintf('Natural Frequency (omega_n)          : %.1f rad/s\n', omega_n_3);
fprintf('Critical Damping Resistance (R_crit) : %.2f Ohms\n', R_crit_3);
fprintf('Underdamped Simulated Overshoot      : %.2f%%\n', OS_sim_3);
fprintf('Underdamped Theoretical Overshoot    : %.2f%%\n\n', OS_theory_3);


%% Level 4: Challenge
% -------------------------------------------------------------------------
% Problem 4: Closed-Loop DC Motor PI Tuning with Anti-Windup Clamping
% Regulate DC motor angular speed to omega_ref = 120.0 rad/s under full load
% disturbance torque tau_L = 0.6 N*m applied at t = 2.0 s.
%
% Plant parameters:
%   R_a = 1.5 Ohm, L_a = 0.4 H, K_t = 0.15 N*m/A, K_e = 0.15 V*s/rad,
%   J = 0.03 kg*m^2, b = 0.02 N*m*s/rad.
% Actuator voltage limit: V_max = +/- 40.0 V.
%
% Tasks:
%   1. Implement PI controller with Anti-Windup clamping:
%        K_p = 3.0, K_i = 15.0
%        u_unsat = K_p * e + K_i * x_int
%        u_sat = min(V_max, max(-V_max, u_unsat))
%        dx_int/dt = 0 if (u_sat ~= u_unsat and e * u_unsat > 0) else e
%   2. Integrate coupled 3-state system over [0, 4.0] seconds.
%   3. Verify steady-state error e_ss = 0.0 after disturbance settles.
%   4. Verify rise time t_r < 0.40 seconds and overshoot < 10%.
% -------------------------------------------------------------------------

Ra_4   = 1.5;   % Armature resistance [Ohms]
La_4   = 0.4;   % Armature inductance [H]
Kt_4   = 0.15;  % Torque constant [N*m/A]
Ke_4   = 0.15;  % Back-EMF constant [V*s/rad]
J_4    = 0.03;  % Inertia [kg*m^2]
b_4    = 0.02;  % Viscous friction [N*m*s/rad]
Vmax_4 = 40.0;  % Saturation limit [V]

omega_ref_4 = 120.0; % Target speed setpoint [rad/s]
t_load_4    = 2.0;   % Load step onset time [s]
tau_load_4  = 0.60;  % Disturbance torque [N*m]

Kp_4 = 3.0;
Ki_4 = 15.0;

% TODO: Task 4.1 - Implement derivatives with anti-windup clamping and solve using ode45
% Augmented state: x = [i_a; omega; x_int]
% [t_motor, x_motor] = ode45(@(t, x) motor_pi_aw_ode(t, x, ...), [0.0, 4.0], [0.0; 0.0; 0.0]);

% TODO: Task 4.2 - Extract speed omega(t) and calculate steady-state error at t = 4.0 s
% e_ss_4 = abs(omega_ref_4 - omega_motor(end));
e_ss_4 = 0; % Replace with simulated steady-state error

fprintf('--- Level 4: DC Motor PI Anti-Windup Challenge ---\n');
fprintf('Target Speed (omega_ref)             : %.1f rad/s\n', omega_ref_4);
fprintf('Load Disturbance (tau_L)             : %.2f N*m applied at t = %.1f s\n', ...
    tau_load_4, t_load_4);
fprintf('Final Closed-Loop Speed              : %.2f rad/s\n', omega_ref_4);
fprintf('Steady-State Speed Offset (e_ss)     : %.4f rad/s (Target: 0.0000)\n', e_ss_4);

fprintf('\n=================================================================\n');
fprintf('  SIMULINK EXERCISES TEMPLATE READY                              \n');
fprintf('=================================================================\n');
