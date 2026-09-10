%% exercises.m - 4-Tier Progressive Exercises: Calculus for Engineers
% =========================================================================
% MODULE: Calculus for Engineers (R3: Change, Accumulation & Optimization)
%
% INSTRUCTIONS:
% Complete the exercises in each of the 4 progressive levels:
%   Level 1: Recall (Basic syntax, diff(), trapz(), analytical rates)
%   Level 2: Understanding & Debugging (Fixing array length errors, spacing)
%   Level 3: Application (Braking vehicle dynamics: stopping distance & power)
%   Level 4: Challenge (Heat sink cooling optimization with ode45)
%
% Look for '% TODO' comments where your code is required.
% =========================================================================

clear; close all; clc;

%% Level 1: Recall
% -------------------------------------------------------------------------
% Problem 1.1: Numerical Differentiation with diff()
% A drone rises vertically with altitude s(t) = 2*t^3 - 5*t + 10 [meters]
% for t in [0, 4] seconds with step size dt = 0.05 s.
% Compute the velocity vector v_diff using diff() divided by dt.
% Also define the corresponding midpoint time vector t_mid.
% -------------------------------------------------------------------------

dt_1 = 0.05;
t_1  = 0:dt_1:4.0;
s_1  = 2.0 .* (t_1.^3) - 5.0 .* t_1 + 10.0;

% TODO: Compute t_mid (vector of midpoint timestamps of length N-1)
t_mid_1 = []; % Replace with your code

% TODO: Compute v_diff (numerical velocity using diff() scaled by dt_1)
v_diff_1 = []; % Replace with your code

% Analytical velocity at midpoints for validation
v_exact_1 = 6.0 .* (t_mid_1.^2) - 5.0;

% -------------------------------------------------------------------------
% Problem 1.2: Numerical Accumulation with trapz()
% An electric actuator draws a current pulse:
%   I(t) = 15 * sin(pi * t / 4) [Amperes] for t in [0, 4] seconds.
% Use trapz() to calculate the total accumulated charge Q_total in Coulombs.
% (Recall: Q = integral I(t) dt)
% -------------------------------------------------------------------------

t_actuator = linspace(0, 4.0, 200);
I_actuator = 15.0 .* sin(pi .* t_actuator ./ 4.0);

% TODO: Calculate total charge Q_total using trapz()
Q_total = 0; % Replace with your code

fprintf('Level 1 Completed: Review outputs.\n\n');


%% Level 2: Understanding & Debugging
% -------------------------------------------------------------------------
% Debugging Task 2.1: Fixing diff() Dimension Mismatch
% A junior engineer wrote the following code to compute acceleration from 
% velocity, but MATLAB threw an error:
%   "Error using plot: Vectors must be the same length."
%
% FLAGGED CODE:
%   t_flawed = 0:0.02:2;
%   v_flawed = 25 * (1 - exp(-t_flawed / 0.5));
%   a_flawed = diff(v_flawed);          % BUG 1: Not divided by dt!
%   plot(t_flawed, a_flawed);           % BUG 2: Dimension mismatch (N vs N-1)!
%
% Correct this by providing two robust solutions:
%   Method A: Use gradient() to preserve full array length N
%   Method B: Use diff() properly scaled by dt with midpoint time alignment
% -------------------------------------------------------------------------

dt_dbg = 0.02;
t_dbg  = 0:dt_dbg:2.0;
v_dbg  = 25.0 .* (1.0 - exp(-t_dbg ./ 0.5));

% TODO: Method A - Compute a_grad using gradient(v, dt)
a_grad_dbg = []; % Replace with your code

% TODO: Method B - Compute a_diff using diff(v) scaled by dt, and matching t_mid_dbg
t_mid_dbg = [];  % Replace with your code
a_diff_dbg = []; % Replace with your code

% -------------------------------------------------------------------------
% Debugging Task 2.2: Non-Uniform Grid Spacing in trapz()
% A sensor node reports battery discharge power P_sensor at irregular intervals:
%   t_sensor = [0.0, 0.5, 1.2, 2.0, 3.5, 5.0] [seconds]
%   P_sensor = [120, 115, 105, 95,  70,  50]  [Watts]
%
% Flawed code was used:
%   E_wrong = trapz(P_sensor); % Assumes uniform dt = 1.0!
%
% Correct the calculation using trapz() with the explicit coordinate grid 
% to obtain the true accumulated energy E_corrected in Joules.
% -------------------------------------------------------------------------

t_sensor = [0.0, 0.5, 1.2, 2.0, 3.5, 5.0];
P_sensor = [120.0, 115.0, 105.0, 95.0, 70.0, 50.0];

% TODO: Compute E_corrected using trapz() with both coordinates and values
E_corrected = 0; % Replace with your code

fprintf('Level 2 Completed: Debugging exercises resolved.\n\n');


%% Level 3: Application
% -------------------------------------------------------------------------
% Engineering Scenario: Braking Dynamics of an Electric Passenger Train
% A commuter train of mass M = 450,000 kg traveling at v0 = 70 m/s (252 km/h)
% initiates full service braking at t = 0 s.
%
% The onboard telemetry records speed according to the empirical profile:
%   v(t) = v0 * exp(-t / 18.0) * cos(pi * t / 140.0) [m/s]
% for t in [0, 80] seconds with sample interval dt = 0.01 s.
%
% Tasks:
%   1. Generate time vector t_train and velocity vector v_train.
%   2. Determine stopping time t_stop: the first time timestamp where 
%      v_train <= 0.2 m/s.
%   3. Compute deceleration a_train = gradient(v_train, dt_train) over the 
%      braking interval [0, t_stop]. Determine peak deceleration magnitude a_peak [m/s^2].
%   4. Compute total stopping distance d_stop using trapz() over [0, t_stop].
%   5. Compute total mechanical energy dissipated E_dissipated_MJ in MegaJoules (MJ)
%      by integrating brake power: P_brake = M * abs(a_train) .* v_braking.
% -------------------------------------------------------------------------

M_train = 450000.0; % Train mass [kg]
v0_train = 70.0;    % Initial velocity [m/s]
dt_train = 0.01;    % Sample interval [s]
t_train = 0:dt_train:80.0;

% Velocity profile
v_train = v0_train .* exp(-t_train ./ 18.0) .* cos(pi .* t_train ./ 140.0);

% TODO: Find index and timestamp t_stop where v_train first drops <= 0.2 m/s
idx_stop = 1;      % Replace with your code
t_stop = 0;        % Replace with your code

% TODO: Truncate t_braking and v_braking to [0, t_stop]
t_braking = [];    % Replace with your code
v_braking = [];    % Replace with your code

% TODO: Compute instantaneous acceleration a_braking using gradient()
a_braking = [];    % Replace with your code

% TODO: Compute peak deceleration magnitude a_peak [m/s^2]
a_peak = 0;        % Replace with your code

% TODO: Compute total stopping distance d_stop using trapz()
d_stop = 0;        % Replace with your code

% TODO: Compute total mechanical braking energy dissipated in MegaJoules (MJ)
% P_brake = M_train * abs(a_braking) .* v_braking
% E_dissipated_MJ = trapz(t_braking, P_brake) / 1e6
E_dissipated_MJ = 0; % Replace with your code

fprintf('Level 3 Completed: Train braking analysis calculated.\n\n');


%% Level 4: Challenge
% -------------------------------------------------------------------------
% Engineering Scenario: Optimal Heat Sink Sizing for an Avionics Processor
% An embedded flight computer processor dissipates fluctuating power:
%   P_in(t) = P_base + P_burst * (sin(2 * pi * t / 60.0)^2) [Watts]
% where P_base = 35 W and P_burst = 65 W.
%
% Thermal parameters:
%   C_th  = 220.0 J/K   (Thermal capacitance)
%   T_amb = 32.0 deg C  (Avionics bay ambient temperature)
%   T_max = 75.0 deg C  (Maximum allowable steady operating temperature)
%
% Governing ODE:
%   dT/dt = (1 / C_th) * P_in(t) - (h_A / C_th) * (T - T_amb)
%
% Challenge Tasks:
%   1. Define a function or evaluation loop using ode45 that simulates 
%      the temperature trajectory T(t) over t in [0, 600] s starting from T(0) = T_amb.
%   2. Determine the minimum convective conductance h_A_opt [W/K] (with precision 
%      within 0.05 W/K) such that the maximum periodic temperature remains 
%      at or below T_max (75.0 deg C).
%   3. Given forced air convective heat transfer coefficient h = 28 W/(m^2 K), 
%      calculate the required effective fin surface area A_fin_m2 = h_A_opt / h.
% -------------------------------------------------------------------------

P_base_4  = 35.0;     % Base power [W]
P_burst_4 = 65.0;     % Burst power [W]
C_th_4    = 220.0;    % Capacitance [J/K]
T_amb_4   = 32.0;     % Ambient temp [deg C]
T_max_4   = 75.0;     % Safety ceiling [deg C]
h_coeff   = 28.0;     % Convection coefficient [W/(m^2 K)]

% TODO: Write an iterative search or bisection algorithm to determine h_A_opt
h_A_opt = 0;          % Replace with your optimized value

% TODO: Calculate required fin area A_fin_m2
A_fin_m2 = 0;         % Replace with your calculated area

fprintf('Level 4 Completed: Heat sink challenge evaluated.\n');

%% Helper Functions
% (Implement any local helper functions here if needed)
