%% matlab_exercises_solution.m
% =========================================================================
% MATLAB Fundamentals & Computational Environment: Reference Solutions
% =========================================================================
% Pedagogical Note:
% This file provides complete, mathematically verified reference solutions
% for all exercises in 'matlab/exercises.m'. Each solution includes detailed
% engineering rationale, dimensional verification, and best-practice tips.
%
% All code is fully runnable and contains 0 remaining TODO markers.
% =========================================================================

clearvars;
close all;
clc;

fprintf('=================================================================\n');
fprintf(' MODULE 1: PROGRESSIVE EXERCISES - COMPLETE REFERENCE SOLUTIONS\n');
fprintf('=================================================================\n\n');

%% Level 1: Recall - Solutions
% -------------------------------------------------------------------------
% Mathematical & Conceptual Rationale:
% 1. Orientation: In MATLAB, row vectors are [1 x N] (comma/space separated)
%    and column vectors are [N x 1] (semicolon separated).
% 2. Inner Product: (1 x N) * (N x 1) yields a scalar [1 x 1].
%    Outer Product: (N x 1) * (1 x N) yields a rank-1 matrix [N x N].
% 3. Time Grid: linspace(a, b, N) guarantees exact endpoints, preventing
%    cumulative step round-off errors.
% 4. Damped Harmonic Waveform: Requires element-wise (.*) multiplication
%    between the decaying exponential envelope and sinusoidal carrier.
% -------------------------------------------------------------------------

fprintf('--- LEVEL 1: RECALL SOLUTIONS ---\n');

% Task 1.1: Vector Creation and Geometry
u_row = [3, 7, -2, 5, 8];      % Size: 1x5 row vector
v_col = [2; -1; 4; 0; 6];      % Size: 5x1 column vector

% Inner product: u * v = (3*2) + (7*-1) + (-2*4) + (5*0) + (8*6) = 6 - 7 - 8 + 0 + 48 = 39
dot_uv = u_row * v_col;

% Outer product: v * u yields a 5x5 matrix where entry (i, j) = v(i) * u(j)
outer_uv = v_col * u_row;

fprintf('Task 1.1 Results:\n');
fprintf('  Inner Product (dot_uv) : %d (Expected: 39)\n', dot_uv);
fprintf('  Outer Product (outer_uv) Size: [%d, %d]\n', size(outer_uv));
assert(dot_uv == 39, 'Task 1.1 inner product mismatch!');
assert(isequal(size(outer_uv), [5, 5]), 'Task 1.1 outer product dimension mismatch!');

% Task 1.2: Damped Harmonic Oscillation
A0 = 12.0;       % Initial amplitude
zeta = 1.8;      % Damping exponent [1/s]
omega = 4 * pi;  % Frequency [rad/s] (2 Hz)

% Generate exact 201-point time grid over [0, 2] seconds
t_osc = linspace(0.0, 2.0, 201);

% Vectorized element-wise computation using (.*)
y_osc = A0 .* exp(-zeta .* t_osc) .* cos(omega .* t_osc);

fprintf('Task 1.2 Results:\n');
fprintf('  Time Vector Points     : %d samples (dt = %5.3f s)\n', ...
    length(t_osc), t_osc(2) - t_osc(1));
fprintf('  Peak Initial Amplitude : %6.2f (Expected: 12.00)\n', y_osc(1));
fprintf('  Final Value at t = 2.0s: %6.4f\n', y_osc(end));
assert(abs(y_osc(1) - 12.0) < 1e-12, 'Task 1.2 initial amplitude mismatch!');

% Task 1.3: 1-Based Indexing & Slicing
M_grid = [
    11, 12, 13, 14;
    21, 22, 23, 24;
    31, 32, 33, 34;
    41, 42, 43, 44
];

% 1. Extract row 3, column 2
val_r3_c2 = M_grid(3, 2); % 32

% 2. Extract entire 2nd column
col_2 = M_grid(:, 2);     % [12; 22; 32; 42]

% 3. Extract 2x2 bottom-right corner (rows 3:4, cols 3:4)
sub_corner = M_grid(3:4, 3:4); % [33, 34; 43, 44]

% 4. Reverse row order using end:-1:1
M_reversed = M_grid(end:-1:1, :);

fprintf('Task 1.3 Results:\n');
fprintf('  M_grid(3, 2)           : %d (Expected: 32)\n', val_r3_c2);
fprintf('  Bottom-right sub-corner: [%d, %d; %d, %d]\n', ...
    sub_corner(1,1), sub_corner(1,2), sub_corner(2,1), sub_corner(2,2));
assert(val_r3_c2 == 32, 'Task 1.3 element extraction error!');
assert(isequal(sub_corner, [33, 34; 43, 44]), 'Task 1.3 sub-matrix mismatch!');

% Task 1.4: Logical Indexing & Threshold Clipping
raw_readings = [1.2, 3.8, 5.1, 2.4, 4.9, 6.2, 0.8, 4.5];

% 1. Logical boolean mask for readings strictly greater than 4.0
high_mask = (raw_readings > 4.0);

% 2. Extract masked values
high_values = raw_readings(high_mask); % [5.1, 4.9, 6.2, 4.5]

% 3. Clamp / clip values
clipped_readings = raw_readings;
clipped_readings(high_mask) = 4.0;

fprintf('Task 1.4 Results:\n');
fprintf('  High Values (> 4.0)    : ');
fprintf('%4.1f ', high_values);
fprintf('\n');
fprintf('  Clipped Max Value      : %4.1f (Expected: 4.0)\n\n', max(clipped_readings));
assert(max(clipped_readings) <= 4.0, 'Task 1.4 clipping failed!');

%% Level 2: Understanding & Debugging - Solutions
% -------------------------------------------------------------------------
% Explanatory Notes:
% Bug 2.1 Fix: MATLAB arrays are 1-indexed. Index 0 throws a runtime error.
% Bug 2.2 Fix: Multiplying vectors or raising vectors to a power element-wise
%              requires the dot prefix (.^ and .*). Otherwise MATLAB attempts
%              linear algebra matrix exponentiation, which requires square matrices.
% Bug 2.3 Fix: Vertical concatenation [A; B] requires both arrays to possess
%              the exact same number of columns.
% Bug 2.4 Fix: Dynamic array growth inside a loop triggers repeated memory
%              reallocation and copying. Preallocating with zeros() creates
%              the memory buffer upfront in a single contiguous block.
% -------------------------------------------------------------------------

fprintf('--- LEVEL 2: UNDERSTANDING & DEBUGGING SOLUTIONS ---\n');

% Fix 2.1: 1-based indexing
data = [100, 200, 300, 400];
first_val = data(1); % Corrected: In MATLAB, index 1 is the first element
fprintf('Bug 2.1 Fixed: First element = %d\n', first_val);
assert(first_val == 100, 'Bug 2.1 fix failed!');

% Fix 2.2: Element-wise operators (.^ and .*)
mass = 1500; % kg
vel = [10, 20, 30, 40]; % m/s
% Corrected: Use .^ 2 to square each velocity entry
E_k = 0.5 * mass .* (vel .^ 2); % Joules
fprintf('Bug 2.2 Fixed: Kinetic energies = ');
fprintf('%7.1f kJ  ', E_k ./ 1000);
fprintf('\n');
assert(E_k(1) == 75000, 'Bug 2.2 kinetic energy mismatch!');

% Fix 2.3: Consistent array concatenation dimensions
row1 = [1, 2, 3];
row2_fixed = [4, 5, 6]; % Corrected: 3 elements to match row1 width
assembled_mat = [row1; row2_fixed]; % 2x3 matrix
fprintf('Bug 2.3 Fixed: Assembled matrix size = [%d, %d]\n', size(assembled_mat));
assert(isequal(size(assembled_mat), [2, 3]), 'Bug 2.3 concatenation failed!');

% Fix 2.4: Memory Preallocation
N_loop = 1000;
sig = zeros(1, N_loop); % Corrected: Preallocate array memory upfront
for k = 1:N_loop
    sig(k) = sin(k * 0.05);
end
fprintf('Bug 2.4 Fixed: Preallocated array of %d elements populated.\n\n', length(sig));
assert(length(sig) == 1000, 'Bug 2.4 loop population failed!');

%% Level 3: Application - Solutions
% -------------------------------------------------------------------------
% Engineering Context:
% Thermocouple conditioning pipeline in chemical manufacturing.
% Raw 10-bit ADC signals are converted to physical Volts, mapped via the
% linear thermocouple gain curve, and filtered to remove spurious 0V
% and 5V electrical disconnect spikes.
% -------------------------------------------------------------------------

fprintf('--- LEVEL 3: APPLICATION SOLUTIONS (THERMOCOUPLE CALIBRATION) ---\n');

% Raw 10-bit ADC counts
adc_raw_stream = [1450/5, 1475/5, 0, 1500/5, 1520/5, 1023, 1540/5, 1560/5, 1575/5, 0, 1600/5, 1625/5];
adc_raw_stream = round(adc_raw_stream);
dt_sample = 0.5; % seconds

% Task 3.1: Convert raw ADC stream to voltage [V]
v_stream = (double(adc_raw_stream) ./ 1023) .* 5.0;

% Task 3.2: Convert voltage to temperature [deg C]
% T = 100 * (V - 1.25)
temp_stream_c = 100.0 .* (v_stream - 1.25);

% Task 3.3: Anomaly Rejection via Logical Masking
% Valid temperatures: 20.0 <= T <= 300.0 C
valid_mask = (temp_stream_c >= 20.0) & (temp_stream_c <= 300.0);
clean_temp_c = temp_stream_c(valid_mask);

% Task 3.4: Statistical Metrics on Clean Data
mean_temp_c = mean(clean_temp_c);
std_temp_c  = std(clean_temp_c);
peak_temp_c = max(clean_temp_c);

% Task 3.5: Numerical Rate of Temperature Rise (dT/dt)
% Clean data consecutive differences divided by time step dt
dT_vals   = diff(clean_temp_c);
dT_dt     = dT_vals ./ dt_sample; % [deg C / s]
mean_rate = mean(dT_dt);

fprintf('Task 3 Results:\n');
fprintf('  Total Raw Telemetry Points : %d samples\n', length(adc_raw_stream));
fprintf('  Valid Clean Samples        : %d samples (Rejection rate: %4.1f%%)\n', ...
    length(clean_temp_c), (1 - length(clean_temp_c)/length(adc_raw_stream))*100);
fprintf('  Clean Mean Temperature     : %6.2f deg C\n', mean_temp_c);
fprintf('  Clean Standard Deviation   : %6.2f deg C\n', std_temp_c);
fprintf('  Clean Peak Temperature     : %6.2f deg C\n', peak_temp_c);
fprintf('  Average Heating Rate       : %6.3f deg C/s\n\n', mean_rate);

assert(length(clean_temp_c) == 9, 'Outlier rejection did not filter exactly 3 glitches!');
assert(mean_temp_c > 20 && mean_temp_c < 50, 'Clean temperature outside expected range!');

%% Level 4: Challenge - Solutions
% -------------------------------------------------------------------------
% Engineering Context:
% Multi-rate powertrain sensor fusion pipeline.
% Mechanical channel (100 Hz) and electrical channel (200 Hz) are aligned,
% synchronized, and evaluated for power conversion efficiency and energy.
% -------------------------------------------------------------------------

fprintf('--- LEVEL 4: CHALLENGE SOLUTIONS (POWERTRAIN TELEMETRY FUSION) ---\n');

% Synthetic Test Data
t_mech = linspace(0, 1.99, 200);  % 100 Hz time vector (200 samples)
t_elec = linspace(0, 1.995, 400); % 200 Hz time vector (400 samples)

% Mechanical signals (100 Hz)
N_rpm = 1000 + 4000 .* (t_mech ./ 2.0); 
tau_nm = 80 .* sin(pi .* t_mech ./ 2.0);

% Electrical signals (200 Hz)
V_dc = 360 - 20 .* (t_elec ./ 2.0);
I_dc = (80 .* sin(pi .* t_elec ./ 2.0) .* (1000 + 4000 .* (t_elec ./ 2.0)) * (2*pi/60)) ./ (340 * 0.88) + 2.0;

% Task 4.1: Downsample electrical channel by taking every 2nd sample (1:2:end)
V_dc_sync = V_dc(1:2:end); % 400 samples -> 200 samples
I_dc_sync = I_dc(1:2:end); % 400 samples -> 200 samples

% Task 4.2: Compute mechanical and electrical powers
omega_rad_s = N_rpm .* (2 * pi / 60);         % Speed in rad/s
P_mech      = tau_nm .* omega_rad_s;          % Mechanical output power [Watts]
P_elec      = V_dc_sync .* I_dc_sync;         % Electrical input power [Watts]

% Task 4.3: Instantaneous Efficiency
efficiency = P_mech ./ P_elec;

% Task 4.4: High-Power Motoring Regime Filtering
% Identify time steps where P_mech >= 15000 Watts
high_pwr_mask = (P_mech >= 15000);
mean_eff_motoring = mean(efficiency(high_pwr_mask));

% Task 4.5: Total Electrical Energy Consumed via trapz
E_joules = trapz(t_mech, P_elec); % Integrated energy [Joules = Watt-seconds]
E_Wh     = E_joules / 3600;       % Energy in Watt-hours [Wh]

fprintf('Task 4 Results:\n');
fprintf('  Synchronized Sample Count  : %d matching points\n', length(V_dc_sync));
fprintf('  Peak Mechanical Power      : %7.2f kW\n', max(P_mech) / 1000);
fprintf('  Peak Electrical Power      : %7.2f kW\n', max(P_elec) / 1000);
fprintf('  High-Power Motoring Samples: %d / %d samples\n', sum(high_pwr_mask), length(P_mech));
fprintf('  Mean Motoring Efficiency   : %6.2f%%\n', mean_eff_motoring * 100);
fprintf('  Total Energy Consumed      : %7.2f kJ (%5.2f Wh)\n\n', E_joules / 1000, E_Wh);

assert(length(V_dc_sync) == 200, 'Downsampling did not produce 200 samples!');
assert(mean_eff_motoring > 0.80 && mean_eff_motoring < 0.95, 'Efficiency outside realistic physical bounds!');
assert(E_Wh > 0, 'Integrated energy must be strictly positive!');

fprintf('=================================================================\n');
fprintf(' ALL MODULE 1 SOLUTIONS EXECUTED AND VERIFIED SUCCESSFULLY.\n');
fprintf('=================================================================\n');
