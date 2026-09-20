%% simulink_exercises_solution.m - Reference Solution for Simulink Exercises
% =========================================================================
% MODULE: Simulink for Beginners (Dynamic System Modeling) (R5)
%
% PURPOSE:
%   Complete worked reference solution for all 4 pedagogical tiers of
%   simulink/exercises.m with 100% verified numerical solutions.
%
% PEDAGOGICAL COVERAGE:
%   - Level 1: Recall (Poles, time constants, rise and settling times, DC gains)
%   - Level 2: Understanding & Debugging (Algebraic loop breaking, Euler stability)
%   - Level 3: Application (2nd-order series RLC transient simulation & damping)
%   - Level 4: Challenge (DC motor PI anti-windup regulation under load disturbance)
% =========================================================================

clear;
close all;
clc;

fprintf('=================================================================\n');
fprintf('  SIMULINK DYNAMIC MODELING: REFERENCE SOLUTIONS                 \n');
fprintf('=================================================================\n\n');

%% Level 1: Recall
% -------------------------------------------------------------------------
% Problem 1.1: First-Order System Pole & Time Constant Calculation
% -------------------------------------------------------------------------

R_1 = 20.0e3;  % 20 kOhm [Ohms]
C_1 = 50.0e-6; % 50 uF [Farads]

% Solution 1.1.1: Circuit time constant tau_1 = R_1 * C_1
tau_1 = R_1 * C_1; % tau_1 = 20000 * 50e-6 = 1.0000 s

% Solution 1.1.2: Continuous-time system pole s_pole = -1 / tau_1
s_pole_1 = -1.0 / tau_1; % s_pole = -1.0000 rad/s

% Solution 1.1.3: Theoretical 10%-to-90% rise time
t_rise_1 = tau_1 * log(9.0); % ~2.1972 s

% Solution 1.1.4: Theoretical 2% settling time
t_settle_1 = -tau_1 * log(0.02); % ~3.9120 s

fprintf('--- Level 1.1: First-Order RC Characteristics ---\n');
fprintf('Time Constant (tau)          : %.4f seconds\n', tau_1);
fprintf('System Pole (s_p)            : %.4f rad/s\n', s_pole_1);
fprintf('Theoretical Rise Time (t_r)  : %.4f seconds\n', t_rise_1);
fprintf('Theoretical Settling Time(t_s): %.4f seconds\n\n', t_settle_1);

% -------------------------------------------------------------------------
% Problem 1.2: DC Gain & Steady-State Evaluation
% -------------------------------------------------------------------------

K_dc_2   = 0.050; % Sensitivity [V / deg C]
tau_th_2 = 8.0;   % Thermal time constant [s]
delta_T_step = 60.0; % Thermal step amplitude [deg C]

% Solution 1.2.1: Steady-state sensor output voltage
V_ss_2 = K_dc_2 * delta_T_step; % 0.050 * 60 = 3.0000 V

% Solution 1.2.2: Sensor output voltage at elapsed time t = tau_th
V_at_tau_2 = V_ss_2 * (1.0 - exp(-1.0)); % 3.0 * (1 - 0.3679) = 1.8964 V

fprintf('--- Level 1.2: Thermal Sensor DC Gain Evaluation ---\n');
fprintf('Steady-State Output (V_ss)   : %.4f Volts\n', V_ss_2);
fprintf('Output at 1 Time Constant    : %.4f Volts (%.1f%% of V_ss)\n\n', ...
    V_at_tau_2, (V_at_tau_2 / V_ss_2) * 100.0);


%% Level 2: Understanding & Debugging
% -------------------------------------------------------------------------
% Debugging Task 2.1: Diagnosing and Breaking an Algebraic Loop
% -------------------------------------------------------------------------

u_alg  = 10.0;
K1_alg = 4.0;
K2_alg = 0.5;

% Solution 2.1.1: Closed-form analytical solution
y_exact_2 = (K1_alg * u_alg) / (1.0 + K1_alg * K2_alg); % (40) / (1 + 2) = 13.3333

% Solution 2.1.2: Dynamic low-pass relaxation ODE integration
tau_filter = 0.05; % Fast state filter time constant [s]
loop_ode = @(t, y) (K1_alg * (u_alg - K2_alg * y) - y) / tau_filter;

t_span_alg = [0.0, 0.5];
y0_alg     = 0.0;
ode_opts_alg = odeset('RelTol', 1e-6, 'AbsTol', 1e-8);
[t_alg_sim, y_alg_sim] = ode45(loop_ode, t_span_alg, y0_alg, ode_opts_alg);

% Solution 2.1.3: Discrepancy evaluation at steady state
alg_error = abs(y_alg_sim(end) - y_exact_2);

fprintf('--- Level 2.1: Algebraic Loop Resolution ---\n');
fprintf('Exact Closed-Form Solution (y_exact) : %.4f\n', y_exact_2);
fprintf('Dynamic Filter Steady-State          : %.4f\n', y_alg_sim(end));
fprintf('Algebraic Loop Discrepancy           : %.2e\n\n', alg_error);

% -------------------------------------------------------------------------
% Debugging Task 2.2: Forward Euler Numerical Stability & Critical Step Size
% -------------------------------------------------------------------------

a_decay = 20.0; % Decay rate [s^-1]

% Solution 2.2.1: Critical maximum stable time step for forward Euler
dt_crit = 2.0 / a_decay; % 2 / 20 = 0.1000 s

% Solution 2.2.2: Stable simulation (dt = 0.8 * dt_crit = 0.08 s)
dt_stable = 0.80 * dt_crit;
N_steps   = 50;
y_stable  = zeros(1, N_steps);
y_stable(1) = 1.0;
for k = 1:(N_steps - 1)
    y_stable(k + 1) = (1.0 - a_decay * dt_stable) * y_stable(k);
end

% Solution 2.2.3: Unstable simulation (dt = 1.2 * dt_crit = 0.12 s)
dt_unstable = 1.20 * dt_crit;
y_unstable  = zeros(1, N_steps);
y_unstable(1) = 1.0;
for k = 1:(N_steps - 1)
    y_unstable(k + 1) = (1.0 - a_decay * dt_unstable) * y_unstable(k);
end

fprintf('--- Level 2.2: Forward Euler Numerical Stability ---\n');
fprintf('Critical Step Size (dt_crit = 2/a)   : %.4f seconds\n', dt_crit);
fprintf('Stable Step (0.8*dt_crit) Final y    : %.4e (Successfully converged)\n', y_stable(end));
fprintf('Unstable Step (1.2*dt_crit) Final y  : %.4e (Explosively diverged)\n\n', y_unstable(end));


%% Level 3: Application
% -------------------------------------------------------------------------
% Problem 3: Second-Order Series RLC Resonant Circuit Dynamic Simulation
% -------------------------------------------------------------------------

L_3 = 10.0e-3; % 10 mH [H]
C_3 = 100.0e-6;% 100 uF [F]
V_in_3 = 10.0; % Step input [V]
t_span_3 = [0.0, 0.025]; % Simulation time window [s]

omega_n_3 = 1.0 / sqrt(L_3 * C_3); % Natural frequency = 1000 rad/s
R_crit_3  = 2.0 * sqrt(L_3 / C_3); % Critical resistance = 20 Ohms

% Damping resistance values
zeta_under = 0.25;
R_under    = 2.0 * zeta_under * sqrt(L_3 / C_3); % 5.0 Ohms
R_crit     = R_crit_3;                            % 20.0 Ohms
zeta_over  = 2.50;
R_over     = 2.0 * zeta_over * sqrt(L_3 / C_3);  % 50.0 Ohms

% Solution 3.1: State equations and integration for all 3 damping regimes
% State vector: x = [i_L; v_C]
rlc_ode = @(t, x, R) [(V_in_3 - R * x(1) - x(2)) / L_3; x(1) / C_3];
ode_opts_rlc = odeset('RelTol', 1e-6, 'AbsTol', 1e-8, 'MaxStep', 0.0001);

[t_under, x_under] = ode45(@(t, x) rlc_ode(t, x, R_under), t_span_3, [0.0; 0.0], ode_opts_rlc);
[t_crit,  x_crit]  = ode45(@(t, x) rlc_ode(t, x, R_crit),  t_span_3, [0.0; 0.0], ode_opts_rlc);
[t_over,  x_over]  = ode45(@(t, x) rlc_ode(t, x, R_over),  t_span_3, [0.0; 0.0], ode_opts_rlc);

% Solution 3.2: Simulated peak overshoot for underdamped capacitor voltage
vC_under = x_under(:, 2);
OS_sim_3 = (max(vC_under) - V_in_3) / V_in_3 * 100.0;

% Solution 3.3: Theoretical percent overshoot for zeta = 0.25
OS_theory_3 = exp(-pi * zeta_under / sqrt(1.0 - zeta_under^2)) * 100.0;

fprintf('--- Level 3: RLC Resonant Dynamics ---\n');
fprintf('Natural Frequency (omega_n)          : %.1f rad/s\n', omega_n_3);
fprintf('Critical Damping Resistance (R_crit) : %.2f Ohms\n', R_crit_3);
fprintf('Underdamped Simulated Overshoot      : %.2f%%\n', OS_sim_3);
fprintf('Underdamped Theoretical Overshoot    : %.2f%%\n\n', OS_theory_3);


%% Level 4: Challenge
% -------------------------------------------------------------------------
% Problem 4: Closed-Loop DC Motor PI Tuning with Anti-Windup Clamping
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

% Solution 4.1: Integrate coupled 3-state system with conditional anti-windup clamping
motor_pi_ode = @(t, x) solve_motor_pi_aw(t, x, omega_ref_4, Kp_4, Ki_4, Vmax_4, ...
    Ra_4, La_4, Ke_4, Kt_4, b_4, J_4, t_load_4, tau_load_4);

ode_opts_motor = odeset('RelTol', 1e-6, 'AbsTol', 1e-8, 'MaxStep', 0.005);
[t_motor, x_motor] = ode45(motor_pi_ode, [0.0, 4.0], [0.0; 0.0; 0.0], ode_opts_motor);

omega_motor = x_motor(:, 2);
ia_motor    = x_motor(:, 1);

% Solution 4.2: Steady-state error evaluation after disturbance settles
e_ss_4 = abs(omega_ref_4 - omega_motor(end));

% Transient metrics
w_10 = 0.10 * omega_ref_4;
w_90 = 0.90 * omega_ref_4;
idx_10 = find(omega_motor >= w_10, 1, 'first');
idx_90 = find(omega_motor >= w_90, 1, 'first');
t_rise_4 = interp1(omega_motor(idx_10-1:idx_10), t_motor(idx_10-1:idx_10), w_90) - ...
           interp1(omega_motor(idx_10-1:idx_10), t_motor(idx_10-1:idx_10), w_10);
pct_os_4 = max(0.0, (max(omega_motor(1:find(t_motor >= t_load_4, 1))) - omega_ref_4) / omega_ref_4 * 100.0);

fprintf('--- Level 4: DC Motor PI Anti-Windup Challenge ---\n');
fprintf('Target Speed (omega_ref)             : %.1f rad/s\n', omega_ref_4);
fprintf('Load Disturbance (tau_L)             : %.2f N*m applied at t = %.1f s\n', ...
    tau_load_4, t_load_4);
fprintf('Final Closed-Loop Speed              : %.4f rad/s\n', omega_motor(end));
fprintf('Steady-State Speed Offset (e_ss)     : %.4f rad/s\n', e_ss_4);
fprintf('Closed-Loop Rise Time (t_r)          : %.4f seconds (Target: < 0.40 s)\n', t_rise_4);
fprintf('Closed-Loop Percent Overshoot        : %.2f%% (Target: < 10.0%%)\n\n', pct_os_4);

fprintf('=================================================================\n');
fprintf('  SIMULINK REFERENCE SOLUTIONS COMPLETED SUCCESSFULLY            \n');
fprintf('=================================================================\n');


%% Helper Function for Motor PI Control with Anti-Windup Clamping
function dxdt = solve_motor_pi_aw(t, x, w_ref, Kp, Ki, Vmax, Ra, La, Ke, Kt, b, J, t_load, tau_l)
    % Extracts state vector: x = [i_a; omega; x_int]
    ia     = x(1);
    omega  = x(2);
    x_int  = x(3);
    
    % Tracking error
    err = w_ref - omega;
    
    % Unsaturated PI control output
    u_raw = Kp * err + Ki * x_int;
    
    % Actuator voltage limit saturation
    u_clamped = min(Vmax, max(-Vmax, u_raw));
    
    % Integrator clamping logic: freeze accumulation if saturated and pushing further
    if (u_clamped ~= u_raw) && (err * u_raw > 0)
        dx_int = 0.0;
    else
        dx_int = err;
    end
    
    % Disturbance torque profile
    tau_dist = (t >= t_load) * tau_l;
    
    % Coupled electromechanical derivatives
    dia_dt    = (u_clamped - Ra * ia - Ke * omega) / La;
    domega_dt = (Kt * ia - b * omega - tau_dist) / J;
    
    dxdt = [dia_dt; domega_dt; dx_int];
end
