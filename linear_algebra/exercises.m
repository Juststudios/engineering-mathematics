%% EXERCISES.M - Module 2: Linear Algebra for Engineers & Machine Learning
%
% Complete each exercise by replacing the '% TODO' placeholders with your own code.
% Run each cell independently using Ctrl+Enter (or Run Section).
%
% Progressive Learning Tiers:
%   Level 1: Recall (Vector norms, dot products, backslash operator)
%   Level 2: Understanding & Debugging (Dimension mismatch, ill-conditioned systems)
%   Level 3: Application (Multi-loop electrical network solver & power verification)
%   Level 4: Challenge (3-story building shear frame modal & resonance analysis)

clear; clc; close all;

%% =====================================================================
%% Level 1: Recall
%% =====================================================================

%% Exercise 1.1: Vector Norms and Unit Direction
% In structural health monitoring, an accelerometer on a bridge deck records
% the following peak acceleration vector (in m/s^2):
a_accel = [1.2; -3.4; 8.1];

% 1. Calculate the L1 norm (Manhattan norm)
% TODO: norm_L1 = ...
norm_L1 = []; % TODO: Replace with norm(..., 1)

% 2. Calculate the L2 norm (Euclidean magnitude)
% TODO: norm_L2 = ...
norm_L2 = []; % TODO: Replace with norm(..., 2)

% 3. Calculate the L-infinity norm (Maximum coordinate deviation)
% TODO: norm_Linf = ...
norm_Linf = []; % TODO: Replace with norm(..., inf)

% 4. Compute the unit direction vector u_a pointing in the direction of acceleration
% TODO: u_a = ...
u_a = []; % TODO: Normalize a_accel by its Euclidean norm

fprintf('Level 1.1 Results:\n');
fprintf('  L1 Norm:   %f\n', norm_L1);
fprintf('  L2 Norm:   %f\n', norm_L2);
fprintf('  Linf Norm: %f\n', norm_Linf);
if ~isempty(u_a)
    fprintf('  Unit Vector Norm: %f (Should be 1.0)\n\n', norm(u_a));
end

%% Exercise 1.2: Cable Tension Dot Product and Mechanical Work
% Two guy wires anchor a telecommunication tower top to the ground.
% Tension vector for Cable A (kN): T_A = [15.0; 20.0; -35.0]
% Tension vector for Cable B (kN): T_B = [-10.0; 25.0; -30.0]
T_A = [15.0; 20.0; -35.0];
T_B = [-10.0; 25.0; -30.0];

% 1. Compute the dot product between T_A and T_B
% TODO: dot_AB = ...
dot_AB = []; % TODO: Use dot(T_A, T_B) or T_A' * T_B

% 2. Compute the angle theta (in degrees) between the two cables
% TODO: theta_deg = ...
theta_deg = []; % TODO: Use acosd(...) with the dot product and norms

% 3. A tower maintenance cart is pulled along displacement vector d = [0; 0; -12] m
% under the constant force of Cable A. Compute the mechanical work done (in kJ = kN*m):
d_cart = [0.0; 0.0; -12.0];
% TODO: work_done = ...
work_done = []; % TODO: Compute dot product of T_A and d_cart

fprintf('Level 1.2 Results:\n');
fprintf('  Dot Product:     %f kN^2\n', dot_AB);
fprintf('  Angle between:   %f degrees\n', theta_deg);
fprintf('  Work Done:       %f kJ\n\n', work_done);

%% Exercise 1.3: Solving a Linear System via Backslash
% Consider a static structural spring network where stiffness matrix K (kN/m)
% relates node displacements u (m) to external forces F (kN): K * u = F
K_spring = [ 50, -20,   0;
            -20,  60, -25;
              0, -25,  40];

% Applied force vector (kN)
F_ext = [10.0; -5.0; 15.0];

% 1. Solve for the displacement vector u using MATLAB's backslash operator
% TODO: u_disp = ...
u_disp = []; % TODO: Replace with K_spring \ F_ext

% 2. Calculate the residual norm ||K * u - F|| to verify the solution
% TODO: residual_norm = ...
residual_norm = []; % TODO: norm(K_spring * u_disp - F_ext)

fprintf('Level 1.3 Results:\n');
disp('Displacements u (m):');
disp(u_disp);
fprintf('  Residual Norm: %e\n\n', residual_norm);


%% =====================================================================
%% Level 2: Understanding & Debugging
%% =====================================================================

%% Exercise 2.1: Debugging Dimension Mismatch in Coordinate Transformation
% A student attempted to transform a set of 3 sensor readings from a vehicle
% body frame into the world inertial frame using a 3x3 rotation matrix R.
% However, the student received:
%   "Error using  * : Incorrect dimensions for matrix multiplication"
%
% Below is the buggy code:
%   R_sensor = [0.866, -0.500, 0.000;
%               0.500,  0.866, 0.000;
%               0.000,  0.000, 1.000];
%   p_sensor = [12.5, -4.2, 3.8]; % BUG: Defined as 1x3 row vector!
%   p_world  = R_sensor * p_sensor; % Error: 3x3 * 1x3 is invalid!

R_sensor = [0.866, -0.500, 0.000;
            0.500,  0.866, 0.000;
            0.000,  0.000, 1.000];

p_sensor_raw = [12.5, -4.2, 3.8]; % Given raw data (row vector)

% TODO: Fix the orientation of p_sensor so that it is a 3x1 column vector
% p_sensor_col = ...
p_sensor_col = []; % TODO: Transpose p_sensor_raw into a column vector

% TODO: Compute p_world correctly using matrix multiplication
% p_world = ...
p_world = []; % TODO: R_sensor * p_sensor_col

fprintf('Level 2.1 Results (Fixed Dimension Mismatch):\n');
fprintf('  p_world coordinates: [%.3f, %.3f, %.3f]^T\n\n', ...
    p_world(1), p_world(2), p_world(3));

%% Exercise 2.2: Diagnosing and Rectifying an Ill-Conditioned System
% An automated geotechnical sensor system creates the following system A*x = b
% relating pressure and pore fluid depth. Because the raw data mixed
% mega-Pascals (1e6 Pa) with micro-meters (1e-6 m), the matrix became severely ill-conditioned:

A_bad = [ 1.0000e+06,  1.0000e+06;
          1.0000e+06,  1.0001e+06 ];
b_bad = [ 2.0000e+06;  2.0001e+06 ];

% 1. Compute the condition number of A_bad
% TODO: cond_bad = ...
cond_bad = []; % TODO: cond(A_bad)

% 2. Rescale the system by dividing each equation by 1e6 to bring quantities into standard units:
% TODO: A_scaled = ...
% TODO: b_scaled = ...
A_scaled = []; % TODO: A_bad / 1e6
b_scaled = []; % TODO: b_bad / 1e6

% 3. Compute condition number of A_scaled
% TODO: cond_scaled = ...
cond_scaled = []; % TODO: cond(A_scaled)

% 4. Solve the system using backslash
% TODO: x_solution = ...
x_solution = []; % TODO: A_scaled \ b_scaled

fprintf('Level 2.2 Results:\n');
fprintf('  Condition Number (Raw):    %e\n', cond_bad);
fprintf('  Condition Number (Scaled): %e\n', cond_scaled);
fprintf('  Solution x: [%.4f; %.4f]\n\n', x_solution(1), x_solution(2));

%% Exercise 2.3: Debunking inv(A)*b vs A\b
% Using a 10x10 Hilbert matrix H = hilb(10) and exact solution x_true = ones(10,1),
% b = H * x_true:
H_test = hilb(10);
x_exact = ones(10, 1);
b_test = H_test * x_exact;

% 1. Solve using inv(H_test) * b_test
% TODO: x_via_inv = ...
x_via_inv = []; % TODO: inv(H_test) * b_test

% 2. Solve using backslash H_test \ b_test
% TODO: x_via_slash = ...
x_via_slash = []; % TODO: H_test \ b_test

% 3. Compute absolute errors relative to x_exact
% TODO: err_inv = ...
% TODO: err_slash = ...
err_inv = [];   % TODO: norm(x_via_inv - x_exact)
err_slash = []; % TODO: norm(x_via_slash - x_exact)

fprintf('Level 2.3 Results (Numerical Precision):\n');
fprintf('  Error via inv(A)*b: %e\n', err_inv);
fprintf('  Error via A\\b:      %e\n', err_slash);
fprintf('  Backslash is %.1fx more accurate!\n\n', err_inv / err_slash);


%% =====================================================================
%% Level 3: Application
%% =====================================================================

%% Exercise 3.1: Multi-Loop Electrical Circuit Network Solver
% Consider a 4-node DC electrical circuit network with Ground (Node 0 = 0V)
% and 3 active nodes (V1, V2, V3):
%
% Sources:
% - Current Source Is1 = 5.0 A injected into Node 1
% - Current Source Is2 = 2.0 A injected into Node 3
%
% Resistors:
% - R1 = 4.0 Ohm between Node 1 and Node 2   --> G1 = 1 / 4.0 = 0.25 S
% - R2 = 10.0 Ohm between Node 1 and Ground   --> G2 = 1 / 10.0 = 0.10 S
% - R3 = 5.0 Ohm between Node 2 and Node 3   --> G3 = 1 / 5.0 = 0.20 S
% - R4 = 20.0 Ohm between Node 2 and Ground  --> G4 = 1 / 20.0 = 0.05 S
% - R5 = 8.0 Ohm between Node 3 and Ground   --> G5 = 1 / 8.0 = 0.125 S
%
% Tasks:
% 1. Assemble the 3x3 conductance matrix G_net:
%      Row 1 (KCL at Node 1): (G1 + G2)*V1 - G1*V2 - 0*V3 = Is1
%      Row 2 (KCL at Node 2): -G1*V1 + (G1 + G3 + G4)*V2 - G3*V3 = 0
%      Row 3 (KCL at Node 3): -0*V1 - G3*V2 + (G3 + G5)*V3 = Is2
% 2. Assemble the injected current vector i_net = [Is1; 0; Is2]
% 3. Solve for node voltages v_net = G_net \ i_net
% 4. Compute branch currents:
%      I_R1 = (V1 - V2) * G1
%      I_R2 = V1 * G2
%      I_R3 = (V2 - V3) * G3
%      I_R4 = V2 * G4
%      I_R5 = V3 * G5
% 5. Verify Energy Conservation:
%      P_supplied   = Is1 * V1 + Is2 * V3
%      P_dissipated = I_R1^2*R1 + I_R2^2*R2 + I_R3^2*R3 + I_R4^2*R4 + I_R5^2*R5
%      Discrepancy  = abs(P_supplied - P_dissipated)

R1 = 4.0; R2 = 10.0; R3 = 5.0; R4 = 20.0; R5 = 8.0;
G1 = 1/R1; G2 = 1/R2; G3 = 1/R3; G4 = 1/R4; G5 = 1/R5;
Is1 = 5.0; Is2 = 2.0;

% TODO: Assemble 3x3 conductance matrix G_net
% G_net = [ ... ];
G_net = []; % TODO: Fill 3x3 conductance matrix

% TODO: Assemble injected current vector i_net
% i_net = [ ... ];
i_net = []; % TODO: [Is1; 0; Is2]

% TODO: Solve for node voltages v_net = [V1; V2; V3]
% v_net = ...
v_net = []; % TODO: G_net \ i_net

% TODO: Compute branch currents
I_R1 = []; % TODO: (v_net(1) - v_net(2)) * G1
I_R2 = []; % TODO: v_net(1) * G2
I_R3 = []; % TODO: (v_net(2) - v_net(3)) * G3
I_R4 = []; % TODO: v_net(2) * G4
I_R5 = []; % TODO: v_net(3) * G5

% TODO: Compute power supplied and power dissipated
P_supplied = [];   % TODO: Is1 * v_net(1) + Is2 * v_net(3)
P_dissipated = []; % TODO: sum of I_Rk^2 * Rk for k=1..5
power_error = [];  % TODO: abs(P_supplied - P_dissipated)

fprintf('Level 3 Application Results (Circuit Solver):\n');
if ~isempty(v_net)
    fprintf('  Node Voltages: V1 = %.4f V, V2 = %.4f V, V3 = %.4f V\n', ...
        v_net(1), v_net(2), v_net(3));
    fprintf('  Power Supplied:   %.4f W\n', P_supplied);
    fprintf('  Power Dissipated: %.4f W\n', P_dissipated);
    fprintf('  Energy Balance Discrepancy: %e W\n\n', power_error);
end


%% =====================================================================
%% Level 4: Challenge
%% =====================================================================

%% Exercise 4.1: Structural Dynamic Modal Analysis of a 3-Story Shear Building
% A 3-story steel frame building has the following floor lumped masses:
%   Floor 1: m1 = 30,000 kg
%   Floor 2: m2 = 25,000 kg
%   Floor 3: m3 = 20,000 kg
%
% Story lateral shear stiffnesses:
%   Story 1: k1 = 30 MN/m = 30e6 N/m
%   Story 2: k2 = 24 MN/m = 24e6 N/m
%   Story 3: k3 = 18 MN/m = 18e6 N/m
%
% Tasks:
% 1. Assemble the 3x3 diagonal Mass Matrix M:
%      M = diag([m1, m2, m3])
% 2. Assemble the 3x3 tridiagonal Stiffness Matrix K:
%      K = [ k1 + k2,   -k2,         0;
%             -k2,     k2 + k3,     -k3;
%               0,       -k3,        k3 ]
% 3. Solve the generalized eigenvalue problem: K * phi = omega^2 * M * phi
%      [Phi, Omega2_mat] = eig(K, M)
% 4. Extract eigenvalues (omega^2), sort them in ascending order,
%    and rearrange modal matrix Phi accordingly.
% 5. Compute natural angular frequencies omega_n (rad/s) and cyclic frequencies f_n (Hz).
% 6. Mass-normalize each mode shape such that phi_i' * M * phi_i = 1.0.
% 7. Check whether a rooftop AC unit spinning at 240 RPM (f_motor = 240/60 = 4.0 Hz)
%    poses a resonance hazard (within 10% of any natural frequency).

m1 = 30000; m2 = 25000; m3 = 20000;
k1 = 30e6;  k2 = 24e6;  k3 = 18e6;

% TODO: Assemble 3x3 Mass Matrix M
% M_bldg = ...
M_bldg = []; % TODO: diag([m1, m2, m3])

% TODO: Assemble 3x3 Stiffness Matrix K
% K_bldg = ...
K_bldg = []; % TODO: Tridiagonal matrix as defined above

% TODO: Solve generalized eigenvalue problem [Phi_raw, D_raw] = eig(K_bldg, M_bldg)
Phi_raw = [];
D_raw   = [];

% TODO: Sort eigenvalues in ascending order and get sorting index
omega2_sorted = [];
sort_idx = [];

% TODO: Compute natural angular frequencies (rad/s) and cyclic frequencies (Hz)
omega_nat = []; % sqrt(omega2_sorted)
freq_hz   = []; % omega_nat / (2 * pi)

% TODO: Mass-normalize each mode shape: phi_norm(:, i) = phi(:, i) / sqrt(phi(:, i)' * M * phi(:, i))
Phi_mass_norm = zeros(3, 3);

fprintf('Level 4 Challenge Results (Modal Analysis):\n');
if ~isempty(freq_hz)
    for mode = 1:3
        fprintf('  Mode %d: Frequency = %8.3f rad/s (%6.3f Hz)\n', ...
            mode, omega_nat(mode), freq_hz(mode));
        fprintf('    Mass-Normalized Mode Shape: [%.4f, %.4f, %.4f]^T\n', ...
            Phi_mass_norm(1, mode), Phi_mass_norm(2, mode), Phi_mass_norm(3, mode));
    end
    
    % Resonance check with 4.0 Hz rooftop equipment
    f_motor = 240.0 / 60.0; % 4.0 Hz
    fprintf('\nRooftop Equipment Frequency: %.2f Hz\n', f_motor);
    for mode = 1:3
        delta_pct = abs(f_motor - freq_hz(mode)) / freq_hz(mode) * 100;
        if delta_pct < 10.0
            fprintf('  RESONANCE ALERT on Mode %d: Difference is only %.1f%%!\n', mode, delta_pct);
        else
            fprintf('  Mode %d is safe from resonance (Difference = %.1f%%).\n', mode, delta_pct);
        end
    end
end

fprintf('\n=======================================================\n');
fprintf('  EXERCISES SCRIPT LOADED\n');
fprintf('=======================================================\n');
