%% exercises.m
% =========================================================================
% MATLAB Fundamentals & Computational Environment: Progressive Exercises
% =========================================================================
% Instructions:
% Complete all four levels of progressive exercises below. Each level tests
% specific competencies in MATLAB scientific programming.
% Look for the "% TODO" comments indicating where your code should be written.
%
% When complete, run this script to ensure there are no syntax or execution errors.
% Reference solutions are available in:
%   solutions/matlab_exercises_solution.m
%
% Tiers:
%   %% Level 1: Recall (Basic syntax, indexing, element-wise operators)
%   %% Level 2: Understanding & Debugging (Diagnosing and fixing common traps)
%   %% Level 3: Application (Thermocouple calibration & glitch rejection)
%   %% Level 4: Challenge (Dual-rate powertrain telemetry fusion pipeline)
% =========================================================================

clearvars;
close all;
clc;

fprintf('====================================================\n');
fprintf(' MODULE 1: PROGRESSIVE EXERCISES\n');
fprintf('====================================================\n\n');

%% Level 1: Recall
% -------------------------------------------------------------------------
% Objective: Practice basic array generation, 1-based indexing, and
% element-wise vector operations.
% -------------------------------------------------------------------------

fprintf('--- LEVEL 1: RECALL ---\n');

% Task 1.1: Vector Creation and Geometry
% 1. Create a row vector 'u_row' containing integers: [3, 7, -2, 5, 8]
% 2. Create a column vector 'v_col' containing integers: [2; -1; 4; 0; 6]
% 3. Compute their dot product 'dot_uv' using the inner product formula (u_row * v_col)
% 4. Compute their outer product 'outer_uv' (v_col * u_row), yielding a 5x5 matrix.

% TODO: Define u_row (1x5) and v_col (5x1)
u_row = []; % TODO: Replace with row vector
v_col = []; % TODO: Replace with column vector

% TODO: Compute dot_uv and outer_uv
dot_uv = [];   % TODO: Inner product
outer_uv = []; % TODO: Outer product

% Task 1.2: Damped Harmonic Oscillation
% Generate a time vector 't_osc' from 0.0 to 2.0 seconds with exactly 201 points using linspace.
% Given parameters:
%   Amplitude A0 = 12.0
%   Damping ratio zeta = 1.8 s^-1
%   Angular frequency omega = 4 * pi rad/s (2 Hz oscillation)
% Compute the damped oscillation vector 'y_osc':
%   y_osc(t) = A0 .* exp(-zeta .* t) .* cos(omega .* t)
% Note: Be sure to use element-wise operators (.*)!

A0 = 12.0;
zeta = 1.8;
omega = 4 * pi;

% TODO: Generate t_osc and compute y_osc
t_osc = []; % TODO: Use linspace(0.0, 2.0, 201)
y_osc = []; % TODO: Compute vectorized damped oscillation

% Task 1.3: 1-Based Indexing & Slicing
% Given the 4x4 matrix M_grid below:
M_grid = [
    11, 12, 13, 14;
    21, 22, 23, 24;
    31, 32, 33, 34;
    41, 42, 43, 44
];

% 1. Extract the element at row 3, column 2 into variable 'val_r3_c2'.
% 2. Extract the entire 2nd column as a column vector into 'col_2'.
% 3. Extract the 2x2 sub-matrix from the bottom-right corner into 'sub_corner'.
% 4. Reverse the rows of M_grid (row 4 becomes row 1) into 'M_reversed'.

% TODO: Perform the requested indexing operations
val_r3_c2  = []; % TODO
col_2      = []; % TODO
sub_corner = []; % TODO
M_reversed = []; % TODO

% Task 1.4: Logical Indexing & Threshold Clipping
% Given sensor noise readings:
raw_readings = [1.2, 3.8, 5.1, 2.4, 4.9, 6.2, 0.8, 4.5];
% 1. Create a logical mask 'high_mask' identifying elements strictly greater than 4.0.
% 2. Extract all values exceeding 4.0 into 'high_values'.
% 3. Create 'clipped_readings' where all elements > 4.0 are clamped to exactly 4.0.

% TODO: Implement logical indexing tasks
high_mask        = []; % TODO
high_values      = []; % TODO
clipped_readings = []; % TODO

fprintf('Level 1 completed.\n\n');

%% Level 2: Understanding & Debugging
% -------------------------------------------------------------------------
% Objective: Identify and correct 4 classical MATLAB student bugs.
% The buggy snippets below will throw runtime errors if uncommented.
% Fix each snippet so it executes cleanly and produces correct output.
% -------------------------------------------------------------------------

fprintf('--- LEVEL 2: UNDERSTANDING & DEBUGGING ---\n');

% --- Bug 2.1: Python 0-Based Indexing Trap ---
% The student attempted to access the first element using index 0:
% BUGGY CODE:
%   data = [100, 200, 300, 400];
%   first_val = data(0);
% TODO: Correct Bug 2.1 to retrieve the first element in MATLAB:
data = [100, 200, 300, 400];
first_val = []; % TODO: Fix indexing

% --- Bug 2.2: Missing Element-Wise Operator Trap ---
% The student attempted to compute instantaneous kinetic energy E = 0.5 * m * v^2
% for a vector of velocities, but forgot the dot (.^ and .*) operators.
% BUGGY CODE:
%   mass = 1500; % kg
%   vel = [10, 20, 30, 40]; % m/s
%   E_k = 0.5 * mass * vel ^ 2;
% TODO: Correct Bug 2.2 using proper element-wise operators:
mass = 1500;
vel = [10, 20, 30, 40];
E_k = []; % TODO: Fix operator to compute kinetic energy vector

% --- Bug 2.3: Inconsistent Concatenation Dimensions Trap ---
% The student wanted to assemble a 2x3 matrix from two rows, but row2 has 4 elements!
% BUGGY CODE:
%   row1 = [1, 2, 3];
%   row2 = [4, 5, 6, 7];
%   assembled_mat = [row1; row2];
% TODO: Fix row2 so both rows have 3 elements and assemble the 2x3 matrix:
row1 = [1, 2, 3];
row2_fixed = []; % TODO: Define row with matching 3 elements [4, 5, 6]
assembled_mat = []; % TODO: Concatenate vertically [row1; row2_fixed]

% --- Bug 2.4: Un-Preallocated Dynamic Array Growth Trap ---
% The student wrote a loop that dynamically expands array 'sig' on every iteration.
% This causes severe performance degradation and triggers MATLAB warnings.
% BUGGY CODE:
%   for k = 1:1000
%       sig(k) = sin(k * 0.05);
%   end
% TODO: Correct Bug 2.4 by preallocating 'sig' with zeros(1, 1000) before the loop:
N_loop = 1000;
sig = []; % TODO: Preallocate sig with zeros(1, N_loop)
for k = 1:N_loop
    sig(k) = sin(k * 0.05);
end

fprintf('Level 2 completed.\n\n');

%% Level 3: Application
% -------------------------------------------------------------------------
% Objective: Implement a real-world sensor calibration and telemetry
% conditioning pipeline for an industrial thermocouple amplifier.
%
% Scenario:
% A high-temperature chemical reactor has an amplified K-type thermocouple
% feeding a 10-bit ADC (values 0 to 1023) operating on a 0.0 to 5.0 V range.
%
% Transfer Characteristics:
%   1. ADC Count to Voltage: V = (ADC / 1023) * 5.0  [Volts]
%   2. Voltage to Temperature: T = 100.0 * (V - 1.25) [deg Celsius]
%      (At 1.25V, T = 0 C; at 3.75V, T = 250 C)
%
% Anomaly Rejection:
% Due to electrical contact bounce during switching, the ADC occasionally
% drops to 0 counts (false 0V) or saturates to 1023 counts (false 5V).
% Real reactor operating temperatures are physically bounded between 20 C and 300 C.
% -------------------------------------------------------------------------

fprintf('--- LEVEL 3: APPLICATION (THERMOCOUPLE TELEMETRY) ---\n');

% Raw 10-bit ADC counts logged over a 12-sample test run (sampling dt = 0.5 s):
adc_raw_stream = [1450/5, 1475/5, 0, 1500/5, 1520/5, 1023, 1540/5, 1560/5, 1575/5, 0, 1600/5, 1625/5];
% Round to integer counts:
adc_raw_stream = round(adc_raw_stream);
dt_sample = 0.5; % seconds

% Task 3.1: Convert raw ADC stream to voltage (v_stream)
% TODO: Compute v_stream = (adc_raw_stream / 1023) * 5.0
v_stream = []; % TODO

% Task 3.2: Convert voltage to temperature in deg C (temp_stream_c)
% TODO: Compute temp_stream_c = 100.0 * (v_stream - 1.25)
temp_stream_c = []; % TODO

% Task 3.3: Anomaly Rejection via Logical Masking
% Create logical mask 'valid_mask' for temperatures strictly between 20.0 and 300.0 C:
% TODO: valid_mask = (temp_stream_c >= 20.0) & (temp_stream_c <= 300.0);
valid_mask = []; % TODO

% Extract only valid temperatures into 'clean_temp_c':
clean_temp_c = []; % TODO

% Task 3.4: Compute Statistical Metrics on Clean Data
% TODO: Calculate mean, standard deviation, and peak temperature
mean_temp_c = []; % TODO: mean(clean_temp_c)
std_temp_c  = []; % TODO: std(clean_temp_c)
peak_temp_c = []; % TODO: max(clean_temp_c)

% Task 3.5: Numerical Rate of Temperature Rise (dT/dt)
% Use MATLAB's diff() function on clean_temp_c:
%   dT = diff(clean_temp_c);
%   cooling_rate = dT / dt_sample; [deg C / s]
% TODO: Compute cooling_rate and mean_rate
dT_vals   = []; % TODO: diff(clean_temp_c)
dT_dt     = []; % TODO: dT_vals / dt_sample
mean_rate = []; % TODO: mean(dT_dt)

fprintf('Level 3 completed.\n\n');

%% Level 4: Challenge
% -------------------------------------------------------------------------
% Objective: Build a complete dual-rate multi-sensor fusion pipeline
% for an electric vehicle powertrain test bench.
%
% Problem Statement:
% An electric vehicle dynamometer logs two asynchronous data streams:
% Stream 1 (Mechanical Channel): Sampled at fs1 = 100 Hz (dt1 = 0.01 s)
%   - Duration: 2.0 seconds (N1 = 200 samples)
%   - Motor Speed: N_rpm(t) [RPM]
%   - Motor Shaft Torque: tau_nm(t) [N*m]
%
% Stream 2 (Electrical Channel): Sampled at fs2 = 200 Hz (dt2 = 0.005 s)
%   - Duration: 2.0 seconds (N2 = 400 samples)
%   - Battery DC Bus Voltage: V_dc(t) [V]
%   - Battery DC Current:     I_dc(t) [A]
%
% Your Pipeline Requirements:
% 1. Downsample the Electrical Stream:
%    Use stride slicing (1:2:end) to downsample V_dc and I_dc from 200 Hz to 100 Hz,
%    yielding matching 200-sample vectors 'V_dc_sync' and 'I_dc_sync'.
%
% 2. Compute Powers:
%    - Angular speed: omega_rad_s = N_rpm * (2 * pi / 60) [rad/s]
%    - Mechanical Power: P_mech = tau_nm .* omega_rad_s [Watts]
%    - Electrical Power: P_elec = V_dc_sync .* I_dc_sync [Watts]
%
% 3. Powertrain Efficiency:
%    - In motoring mode (P_mech > 0 and P_elec > 0):
%      efficiency = P_mech ./ P_elec
%
% 4. Efficiency Thresholding:
%    - Using logical indexing, identify all time steps where the motor is
%      actively delivering significant mechanical power (P_mech >= 15000 W).
%    - Compute the mean powertrain efficiency 'mean_eff_motoring' during
%      this high-power motoring phase.
%
% 5. Total Energy Integration:
%    - Integrate electrical power over time to compute total energy consumed
%      using MATLAB's trapz() function:
%      E_joules = trapz(t_mech, P_elec);
%    - Convert to Watt-hours: E_Wh = E_joules / 3600;
% -------------------------------------------------------------------------

fprintf('--- LEVEL 4: CHALLENGE (DUAL-RATE TELEMETRY FUSION) ---\n');

% Generate Synthetic Test Data
t_mech = linspace(0, 1.99, 200); % 100 Hz mechanical time vector (200 samples)
t_elec = linspace(0, 1.995, 400); % 200 Hz electrical time vector (400 samples)

% Mechanical signals (100 Hz):
% Motor speeds up from 1000 to 5000 RPM
N_rpm = 1000 + 4000 .* (t_mech ./ 2.0); 
% Torque ramps up, plateaus at 80 N*m
tau_nm = 80 .* sin(pi .* t_mech ./ 2.0);

% Electrical signals (200 Hz):
% DC bus nominal 350V with slight battery sag under load
V_dc = 360 - 20 .* (t_elec ./ 2.0);
% Current proportional to torque + losses
I_dc = (80 .* sin(pi .* t_elec ./ 2.0) .* (1000 + 4000 .* (t_elec ./ 2.0)) * (2*pi/60)) ./ (340 * 0.88) + 2.0;

% TODO Task 4.1: Downsample electrical signals using stride slicing (1:2:end)
V_dc_sync = []; % TODO: V_dc(1:2:end)
I_dc_sync = []; % TODO: I_dc(1:2:end)

% TODO Task 4.2: Compute mechanical and electrical powers
omega_rad_s = []; % TODO: N_rpm * (2 * pi / 60)
P_mech      = []; % TODO: tau_nm .* omega_rad_s [Watts]
P_elec      = []; % TODO: V_dc_sync .* I_dc_sync [Watts]

% TODO Task 4.3: Instantaneous Efficiency
efficiency = []; % TODO: P_mech ./ P_elec

% TODO Task 4.4: High-Power Regime Filtering
% Find mask where P_mech >= 15000 Watts
high_pwr_mask = []; % TODO: (P_mech >= 15000)
mean_eff_motoring = []; % TODO: mean(efficiency(high_pwr_mask))

% TODO Task 4.5: Total Electrical Energy Consumed via trapz
E_joules = []; % TODO: trapz(t_mech, P_elec)
E_Wh     = []; % TODO: E_joules / 3600

fprintf('Level 4 challenge completed.\n');
fprintf('====================================================\n');
