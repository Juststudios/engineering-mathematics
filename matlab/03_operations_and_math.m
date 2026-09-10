%% 03_operations_and_math.m
% =========================================================================
% MATLAB Fundamentals & Computational Environment: Operations and Math
% =========================================================================
% Pedagogical Objective:
% This script resolves the single most common conceptual and syntax trap for
% engineering students in MATLAB: the profound mathematical and physical
% distinction between MATRIX LINEAR ALGEBRA operations (*, /, ^) and
% ELEMENT-WISE ARRAY operations (.*, ./, .^).
%
% Key Engineering Topics Covered:
%   1. Matrix Multiplication (C = A * B) as Linear Space Transformation
%   2. Element-Wise (Hadamard) Operations (.*, ./, .^) as Physical Point-Wise Math
%   3. Physical Rationale: Instantaneous Electrical Power, Aerodynamic Drag, Kinetic Energy
%   4. Vector Geometry: Dot Product, Cross Product, and Euclidean Norm
%   5. Linear System Solving: The Backslash Operator (x = A \ b)
%   6. Benchmark: SIMD Vectorization vs. Interpreted Scalar for-loop
% =========================================================================

clearvars;
close all;
clc;

fprintf('====================================================\n');
fprintf(' MODULE 1: MATRIX ALGEBRA VS. ELEMENT-WISE OPERATIONS\n');
fprintf('====================================================\n\n');

%% 1. The Fundamental Distinction: Space Transformations vs. Parallel Signals
%
% MATHEMATICAL PERSPECTIVE:
% - In linear algebra, A * B represents the composition of two linear maps.
%   Dimensions must satisfy: (m x k) * (k x n) = (m x n).
% - In physical signal processing, vectors represent simultaneous time-series
%   measurements. Computing instantaneous power p(t) = v(t) * i(t) requires
%   multiplying values at the SAME instant t_k: that is Hadamard product (.*).

% Example matrices for linear transformation:
A_trans = [2.0, 1.0; 
           0.0, 3.0]; % 2x2 coordinate transformation matrix
x_coords = [1.0, 2.0, 3.0; 
            4.0, 5.0, 6.0]; % 2x3 matrix representing 3 2D point vectors

% Matrix Multiplication: Linear transformation of coordinate points
y_coords = A_trans * x_coords; % (2x2) * (2x3) -> (2x3)
fprintf('Matrix multiplication A * x completed. Result size: [%d, %d]\n', ...
    size(y_coords, 1), size(y_coords, 2));

%% 2. Physical Rationale for Element-Wise Operators (.*, ./, .^)

% --- Case Study A: Instantaneous Electrical Power in an AC Circuit ---
% Instantaneous voltage: v(t) = V_pk * cos(omega * t)
% Instantaneous current: i(t) = I_pk * cos(omega * t - phi)
% Instantaneous power:   p(t) = v(t) .* i(t)
%
% If an engineer mistakenly wrote 'p = v * i', MATLAB would attempt matrix
% multiplication between two (1 x N) row vectors and throw an immediate dimension error!

fs = 10000;            % 10 kHz sample rate
t = 0 : (1/fs) : 0.04; % 40 milliseconds (2 complete 50 Hz cycles)
omega = 2 * pi * 50;   % 50 Hz grid frequency [rad/s]
phi = pi / 6;          % 30 degree phase lag (inductive load)

v = 325.27 .* cos(omega .* t);        % 230 V RMS -> 325.27 V peak
i = 14.14  .* cos(omega .* t - phi);  % 10 A RMS  -> 14.14 A peak

% CORRECT: Element-wise multiplication (.*)
p_instantaneous = v .* i; % [Watts]

% Average Real Power P = (1/T) * integral(p dt) = V_rms * I_rms * cos(phi)
p_real_simulated = mean(p_instantaneous);
p_real_theoretical = (325.27 / sqrt(2)) * (14.14 / sqrt(2)) * cos(phi);

fprintf('--- ELECTRICAL POWER CALCULATION (v .* i) ---\n');
fprintf('Theoretical Real Power P : %7.2f Watts\n', p_real_theoretical);
fprintf('Simulated Average Power  : %7.2f Watts\n', p_real_simulated);
fprintf('Error between theory & sim: %e Watts\n\n', ...
    abs(p_real_simulated - p_real_theoretical));

% --- Case Study B: Aerodynamic Drag Force & Kinetic Energy ---
% Drag equation: F_d(v) = 0.5 * rho * C_d * A_frontal .* (v .^ 2)
% Kinetic Energy: E_k(v) = 0.5 * m .* (v .^ 2)
% Notice the dot-exponentiation (.^ 2) squaring each velocity entry!

rho_air = 1.225;        % Air density [kg/m^3]
C_d = 0.28;             % Drag coefficient (aerodynamic EV)
A_frontal = 2.2;        % Vehicle frontal area [m^2]
vehicle_mass = 1800;    % Vehicle curb mass [kg]

% Velocity sweep from 0 to 40 m/s (~0 to 144 km/h)
velocity_sweep = linspace(0, 40, 5); % 5 discrete speeds [m/s]

% Element-wise squaring (.^ 2)
aerodynamic_drag_force = 0.5 * rho_air * C_d * A_frontal .* (velocity_sweep .^ 2); % [N]
kinetic_energy_joules  = 0.5 * vehicle_mass .* (velocity_sweep .^ 2);              % [J]

fprintf('--- AERODYNAMIC & KINETIC ENERGY SCALING ---\n');
for k = 1:length(velocity_sweep)
    fprintf('  Speed = %4.1f m/s (%5.1f km/h) -> Drag = %6.1f N, Kinetic Energy = %7.1f kJ\n', ...
        velocity_sweep(k), velocity_sweep(k)*3.6, ...
        aerodynamic_drag_force(k), kinetic_energy_joules(k) / 1000);
end
fprintf('\n');

%% 3. Vector Geometric Operations: Dot Product, Cross Product, and Norm
% Engineering mechanics relies extensively on vector projections and moments.

% Consider two 3D force / moment vectors [x; y; z]
force_vector = [120.0; -45.0; 80.0];      % Force [N]
lever_arm    = [0.25; 0.10; -0.05];       % Position vector from pivot [m]

% Euclidean Norm (Magnitude of vector) ||F|| = sqrt(Fx^2 + Fy^2 + Fz^2)
force_magnitude = norm(force_vector);
fprintf('--- VECTOR GEOMETRIC OPERATIONS ---\n');
fprintf('Force Vector Magnitude: %7.2f N\n', force_magnitude);

% Dot Product (Work done or projection along a direction)
unit_direction = [1; 0; 0]; % Unit vector along X-axis
fx_projection = dot(force_vector, unit_direction);
% Equivalent via matrix transpose inner product:
fx_inner_prod = unit_direction' * force_vector;
fprintf('X-Axis Projection via dot(): %7.2f N\n', fx_projection);
fprintf('X-Axis Projection via u''*v : %7.2f N\n', fx_inner_prod);

% Cross Product: Torque / Moment Tau = r x F
torque_vector = cross(lever_arm, force_vector);
fprintf('Torque Vector (r x F): [%6.2f, %6.2f, %6.2f] N*m\n\n', ...
    torque_vector(1), torque_vector(2), torque_vector(3));

%% 4. Matrix Powers (A^n) vs Element Powers (A.^n)
% Square matrix:
M = [2, 1; 
     1, 3];

% Matrix square M^2 = M * M (Linear algebra)
M_mat_squared = M ^ 2;

% Element square M.^2 = [2^2, 1^2; 1^2, 3^2] (Hadamard)
M_elem_squared = M .^ 2;

fprintf('--- MATRIX POWER VS. ELEMENT POWER ---\n');
fprintf('Matrix M^2 (M * M):\n');
disp(M_mat_squared);
fprintf('Element M.^2 (M_ij ^ 2):\n');
disp(M_elem_squared);

%% 5. Solving Systems of Equations: Backslash (\) Operator Preview
% In physics, equilibrium states are represented by A * x = b.
% NEVER use inv(A) * b in engineering code! It is numerically unstable and slow.
% Always use the MATLAB backslash operator: x = A \ b (Gaussian elimination with pivoting).

% Example: 3-equation electrical circuit nodal equilibrium
A_nodes = [ 4, -1, -1;
           -1,  3,  0;
           -1,  0,  2];
b_currents = [12; 0; 5]; % Source current injection vector

% Backslash solve:
nodal_voltages = A_nodes \ b_currents;

fprintf('--- LINEAR SYSTEM SOLUTION (A \\ b) ---\n');
fprintf('Nodal Voltages: V1 = %5.2f V, V2 = %5.2f V, V3 = %5.2f V\n\n', ...
    nodal_voltages(1), nodal_voltages(2), nodal_voltages(3));

%% 6. Performance Benchmark: Vectorization vs. Scalar for-Loop
% Why is vectorization stressed so heavily? Because MATLAB is an interpreted
% runtime that relies on C/Fortran BLAS libraries for vector math.
% Loops incur interpreter overhead on every iteration.

N_samples = 500000;
test_data = linspace(0, 100, N_samples);

% --- Benchmark 1: Scalar for-loop with preallocation ---
tic;
res_loop = zeros(1, N_samples);
for idx = 1:N_samples
    res_loop(idx) = sin(test_data(idx)) * exp(-0.01 * test_data(idx));
end
time_loop = toc;

% --- Benchmark 2: Pure Vectorized Operation ---
tic;
res_vectorized = sin(test_data) .* exp(-0.01 .* test_data);
time_vectorized = toc;

speedup = time_loop / time_vectorized;
max_diff = max(abs(res_loop - res_vectorized));

fprintf('--- BENCHMARK: LOOP VS VECTORIZATION (%d samples) ---\n', N_samples);
fprintf('Scalar for-loop time   : %8.5f s\n', time_loop);
fprintf('Vectorized time (SIMD) : %8.5f s\n', time_vectorized);
fprintf('Speedup Factor         : %8.1fx FASTER\n', speedup);
fprintf('Discrepancy            : %e (Identical numerical results)\n', max_diff);
fprintf('====================================================\n');
fprintf(' 03_operations_and_math.m execution completed successfully.\n');
