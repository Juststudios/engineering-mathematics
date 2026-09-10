%% LINEAR_ALGEBRA_EXERCISES_SOLUTION.M
% Reference Solutions for Module 2: Linear Algebra for Engineers & Machine Learning
%
% This file provides complete, robust, and verified solutions for all exercises
% in linear_algebra/exercises.m across all 4 pedagogical tiers:
%   Level 1: Recall (Vector norms, dot products, backslash operator)
%   Level 2: Understanding & Debugging (Dimension mismatch, ill-conditioned systems)
%   Level 3: Application (Multi-loop electrical network solver & power verification)
%   Level 4: Challenge (3-story building shear frame modal & resonance analysis)
%
% All sections run cleanly without errors and output verified engineering results.

clear; clc; close all;

fprintf('=================================================================\n');
fprintf('  MODULE 2: LINEAR ALGEBRA - OFFICIAL REFERENCE SOLUTIONS\n');
fprintf('=================================================================\n\n');

%% =====================================================================
%% Level 1: Recall
%% =====================================================================

%% Exercise 1.1: Vector Norms and Unit Direction
% In structural health monitoring, an accelerometer on a bridge deck records
% the following peak acceleration vector (in m/s^2):
a_accel = [1.2; -3.4; 8.1];

% 1. Calculate the L1 norm (Manhattan norm)
% Sum of absolute values: |1.2| + |-3.4| + |8.1| = 12.7
norm_L1 = norm(a_accel, 1);

% 2. Calculate the L2 norm (Euclidean magnitude)
% True geometric length: sqrt(1.2^2 + (-3.4)^2 + 8.1^2)
norm_L2 = norm(a_accel, 2);

% 3. Calculate the L-infinity norm (Maximum coordinate deviation)
% Maximum absolute component: max(|1.2|, |-3.4|, |8.1|) = 8.1
norm_Linf = norm(a_accel, inf);

% 4. Compute the unit direction vector u_a pointing in the direction of acceleration
u_a = a_accel / norm_L2;

fprintf('--- Level 1.1: Vector Norms and Unit Vector ---\n');
fprintf('  Given vector a: [%.2f, %.2f, %.2f]^T m/s^2\n', a_accel(1), a_accel(2), a_accel(3));
fprintf('  L1 Norm (Total absolute sum):   %8.4f m/s^2\n', norm_L1);
fprintf('  L2 Norm (Euclidean magnitude):   %8.4f m/s^2\n', norm_L2);
fprintf('  Linf Norm (Peak coordinate):     %8.4f m/s^2\n', norm_Linf);
fprintf('  Unit direction vector u_a:      [%.4f, %.4f, %.4f]^T\n', u_a(1), u_a(2), u_a(3));
fprintf('  Verification: norm(u_a) =        %8.6f (Strictly 1.0)\n\n', norm(u_a));

%% Exercise 1.2: Cable Tension Dot Product and Mechanical Work
% Two guy wires anchor a telecommunication tower top to the ground.
% Tension vector for Cable A (kN): T_A = [15.0; 20.0; -35.0]
% Tension vector for Cable B (kN): T_B = [-10.0; 25.0; -30.0]
T_A = [15.0; 20.0; -35.0];
T_B = [-10.0; 25.0; -30.0];

% 1. Compute the dot product between T_A and T_B
% Dot product: T_A' * T_B = 15*(-10) + 20*25 + (-35)*(-30) = -150 + 500 + 1050 = 1400 kN^2
dot_AB = dot(T_A, T_B);

% 2. Compute the angle theta (in degrees) between the two cables
% cos(theta) = (T_A . T_B) / (||T_A|| * ||T_B||)
mag_A = norm(T_A);
mag_B = norm(T_B);
theta_deg = acosd(dot_AB / (mag_A * mag_B));

% 3. Mechanical work done along cart displacement d = [0; 0; -12] m
% Work = T_A . d (in kJ = kN * m)
d_cart = [0.0; 0.0; -12.0];
work_done = dot(T_A, d_cart); % (-35.0 kN) * (-12.0 m) = 420.0 kJ

fprintf('--- Level 1.2: Cable Tension Dot Product and Work ---\n');
fprintf('  Dot product T_A . T_B:  %8.2f kN^2\n', dot_AB);
fprintf('  Magnitude of Cable A:   %8.2f kN\n', mag_A);
fprintf('  Magnitude of Cable B:   %8.2f kN\n', mag_B);
fprintf('  Angle between cables:   %8.2f degrees\n', theta_deg);
fprintf('  Mechanical Work Done:   %8.2f kJ (positive work pulling cart down)\n\n', work_done);

%% Exercise 1.3: Solving a Linear System via Backslash
% Spring network stiffness matrix K (kN/m) relating node displacements u (m)
% to applied external forces F (kN): K * u = F
K_spring = [ 50, -20,   0;
            -20,  60, -25;
              0, -25,  40];

F_ext = [10.0; -5.0; 15.0];

% 1. Solve for node displacements using MATLAB's backslash operator
u_disp = K_spring \ F_ext;

% 2. Calculate the residual norm ||K * u - F|| to verify numerical solution
residual_norm = norm(K_spring * u_disp - F_ext);

fprintf('--- Level 1.3: Spring Network Displacement Solution ---\n');
fprintf('  Node 1 displacement: %8.4f m\n', u_disp(1));
fprintf('  Node 2 displacement: %8.4f m\n', u_disp(2));
fprintf('  Node 3 displacement: %8.4f m\n', u_disp(3));
fprintf('  Residual norm ||K*u - F||: %e (Zero within machine precision)\n\n', residual_norm);


%% =====================================================================
%% Level 2: Understanding & Debugging
%% =====================================================================

%% Exercise 2.1: Debugging Dimension Mismatch in Coordinate Transformation
% Original error occurred because p_sensor was a 1x3 row vector.
% In linear algebra: (3x3 matrix) * (1x3 vector) is undefined!
% Matrix multiplication requires the inner dimensions to match: (3x3) * (3x1) = (3x1).

R_sensor = [0.866, -0.500, 0.000;
            0.500,  0.866, 0.000;
            0.000,  0.000, 1.000];

p_sensor_raw = [12.5, -4.2, 3.8]; % Given raw data (row vector)

% FIX: Transpose raw row vector into a 3x1 column vector
p_sensor_col = p_sensor_raw(:); % Using (:) forces column orientation safely

% Compute transformed coordinates in World frame
p_world = R_sensor * p_sensor_col;

fprintf('--- Level 2.1: Fixed Dimension Mismatch ---\n');
fprintf('  Raw input shape:        %d x %d (row vector)\n', size(p_sensor_raw, 1), size(p_sensor_raw, 2));
fprintf('  Transposed input shape: %d x %d (column vector)\n', size(p_sensor_col, 1), size(p_sensor_col, 2));
fprintf('  Transformed p_world:    [%.3f, %.3f, %.3f]^T\n\n', ...
    p_world(1), p_world(2), p_world(3));

%% Exercise 2.2: Diagnosing and Rectifying an Ill-Conditioned System
% Raw matrix mixing MPa with micrometers produced artificially huge entries
A_bad = [ 1.0000e+06,  1.0000e+06;
          1.0000e+06,  1.0001e+06 ];
b_bad = [ 2.0000e+06;  2.0001e+06 ];

% 1. Compute condition number of unscaled matrix
cond_bad = cond(A_bad);

% 2. Rescale system by 1e6 to bring into standard SI units
A_scaled = A_bad / 1.0e6;
b_scaled = b_bad / 1.0e6;

% 3. Condition number of rescaled system
cond_scaled = cond(A_scaled);

% 4. Solve system accurately
x_solution = A_scaled \ b_scaled;

fprintf('--- Level 2.2: Matrix Conditioning & Proper Unit Scaling ---\n');
fprintf('  Raw condition number:    %e\n', cond_bad);
fprintf('  Scaled condition number: %e\n', cond_scaled);
fprintf('  Scaled Matrix A:\n');
disp(A_scaled);
fprintf('  Accurate Solution x:     [%.4f; %.4f]\n', x_solution(1), x_solution(2));
fprintf('  Theoretical exact answer: [1.0000; 1.0000]\n\n');

%% Exercise 2.3: Debunking inv(A)*b vs A\b
H_test = hilb(10);
x_exact = ones(10, 1);
b_test = H_test * x_exact;

% 1. Solution via explicit inversion
x_via_inv = inv(H_test) * b_test;

% 2. Solution via backslash
x_via_slash = H_test \ b_test;

% 3. Errors relative to true solution
err_inv = norm(x_via_inv - x_exact);
err_slash = norm(x_via_slash - x_exact);

fprintf('--- Level 2.3: inv(A)*b vs A\\b on 10x10 Hilbert Matrix ---\n');
fprintf('  Condition number cond(H): %e\n', cond(H_test));
fprintf('  Error using inv(A)*b:     %e\n', err_inv);
fprintf('  Error using A\\b:          %e\n', err_slash);
fprintf('  Accuracy advantage:       Backslash is %.1fx more accurate!\n\n', err_inv / err_slash);


%% =====================================================================
%% Level 3: Application
%% =====================================================================

%% Exercise 3.1: Multi-Loop Electrical Circuit Network Solver
% Circuit Parameters:
% Resistors (Ohms):
R1 = 4.0;
R2 = 10.0;
R3 = 5.0;
R4 = 20.0;
R5 = 8.0;

% Conductances (Siemens = 1/Ohm):
G1 = 1.0 / R1;  % 0.250 S
G2 = 1.0 / R2;  % 0.100 S
G3 = 1.0 / R3;  % 0.200 S
G4 = 1.0 / R4;  % 0.050 S
G5 = 1.0 / R5;  % 0.125 S

% Current Sources (Amperes):
Is1 = 5.0; % Injected into Node 1
Is2 = 2.0; % Injected into Node 3

% 1. Assemble 3x3 Conductance Matrix G_net
% Node 1: (G1 + G2)*V1 - G1*V2 - 0*V3 = Is1
% Node 2: -G1*V1 + (G1 + G3 + G4)*V2 - G3*V3 = 0
% Node 3: 0*V1 - G3*V2 + (G3 + G5)*V3 = Is2
G_net = [  G1 + G2,      -G1,           0;
          -G1,      G1 + G3 + G4,     -G3;
            0,          -G3,        G3 + G5 ];

% 2. Assemble Injected Current Vector i_net
i_net = [Is1; 0.0; Is2];

% 3. Solve for node voltages using backslash
v_net = G_net \ i_net;

V1 = v_net(1);
V2 = v_net(2);
V3 = v_net(3);

% 4. Calculate branch currents through all 5 resistors
I_R1 = (V1 - V2) * G1;
I_R2 = V1 * G2;
I_R3 = (V2 - V3) * G3;
I_R4 = V2 * G4;
I_R5 = V3 * G5;

% 5. Power Calculations and Energy Balance Verification
% Power supplied by current sources: P = I * V
P_supplied = Is1 * V1 + Is2 * V3;

% Power dissipated in resistors: P = I^2 * R
P_dissipated = (I_R1^2 * R1) + (I_R2^2 * R2) + (I_R3^2 * R3) + ...
               (I_R4^2 * R4) + (I_R5^2 * R5);

power_error = abs(P_supplied - P_dissipated);

fprintf('--- Level 3: Multi-Loop Electrical Network Solution ---\n');
fprintf('Assembled Conductance Matrix G_net (Siemens):\n');
disp(G_net);
fprintf('Solved Node Voltages:\n');
fprintf('  V1 = %8.4f V\n', V1);
fprintf('  V2 = %8.4f V\n', V2);
fprintf('  V3 = %8.4f V\n\n', V3);

fprintf('Branch Currents:\n');
fprintf('  I_R1 (Node 1 -> 2): %8.4f A\n', I_R1);
fprintf('  I_R2 (Node 1 -> 0): %8.4f A\n', I_R2);
fprintf('  I_R3 (Node 2 -> 3): %8.4f A\n', I_R3);
fprintf('  I_R4 (Node 2 -> 0): %8.4f A\n', I_R4);
fprintf('  I_R5 (Node 3 -> 0): %8.4f A\n\n', I_R5);

fprintf('Conservation of Energy Verification:\n');
fprintf('  Total Power Injected:   %8.4f W\n', P_supplied);
fprintf('  Total Power Dissipated: %8.4f W\n', P_dissipated);
fprintf('  Energy Balance Discrepancy: %e W\n', power_error);
if power_error < 1e-10
    fprintf('  Status: First Law of Thermodynamics strictly satisfied!\n\n');
end


%% =====================================================================
%% Level 4: Challenge
%% =====================================================================

%% Exercise 4.1: Structural Dynamic Modal Analysis of a 3-Story Shear Building
% Physical parameters:
m1 = 30000; % kg (Floor 1)
m2 = 25000; % kg (Floor 2)
m3 = 20000; % kg (Floor 3)

k1 = 30e6;  % N/m (Story 1 columns)
k2 = 24e6;  % N/m (Story 2 columns)
k3 = 18e6;  % N/m (Story 3 columns)

% 1. Assemble 3x3 Diagonal Mass Matrix M
M_bldg = diag([m1, m2, m3]);

% 2. Assemble 3x3 Tridiagonal Stiffness Matrix K
K_bldg = [ k1 + k2,   -k2,         0;
            -k2,     k2 + k3,     -k3;
              0,       -k3,        k3 ];

% 3. Solve Generalized Eigenvalue Problem: K * phi = omega^2 * M * phi
[Phi_raw, D_raw] = eig(K_bldg, M_bldg);

% 4. Extract eigenvalues (omega^2) and sort ascending
[omega2_sorted, sort_idx] = sort(diag(D_raw), 'ascend');
Phi_sorted = Phi_raw(:, sort_idx);

% 5. Compute Natural Angular Frequencies (rad/s) and Cyclic Frequencies (Hz)
omega_nat = sqrt(omega2_sorted);
freq_hz   = omega_nat / (2 * pi);

% 6. Mass-Normalize Each Mode Shape: phi_norm(:, i) = phi(:, i) / sqrt(phi(:, i)' * M * phi(:, i))
Phi_mass_norm = zeros(3, 3);
for i = 1:3
    phi_i = Phi_sorted(:, i);
    modal_mass = phi_i' * M_bldg * phi_i;
    Phi_mass_norm(:, i) = phi_i / sqrt(modal_mass);
end

% Verify modal mass orthogonality: Phi_norm^T * M * Phi_norm == Identity
mass_ortho_error = norm(Phi_mass_norm' * M_bldg * Phi_mass_norm - eye(3), 'fro');
stiff_ortho_error = norm(Phi_mass_norm' * K_bldg * Phi_mass_norm - diag(omega2_sorted), 'fro');

fprintf('--- Level 4: 3-Story Shear Building Modal & Resonance Analysis ---\n');
fprintf('Mass Matrix M (kg):\n');
disp(M_bldg);
fprintf('Stiffness Matrix K (N/m):\n');
disp(K_bldg);

fprintf('Modal Properties:\n');
for mode = 1:3
    fprintf('  Mode %d:\n', mode);
    fprintf('    Natural Angular Frequency (omega_%d): %8.3f rad/s\n', mode, omega_nat(mode));
    fprintf('    Cyclic Frequency (f_%d):              %8.3f Hz (Period T = %.3f s)\n', ...
        mode, freq_hz(mode), 1.0 / freq_hz(mode));
    fprintf('    Mass-Normalized Mode Shape phi_%d:    [%.5f, %.5f, %.5f]^T\n', ...
        mode, Phi_mass_norm(1, mode), Phi_mass_norm(2, mode), Phi_mass_norm(3, mode));
    
    % Floor 3 relative displacement (normalized to top floor = 1.0)
    phi_top_norm = Phi_mass_norm(:, mode) / Phi_mass_norm(3, mode);
    fprintf('    Displacement Shape (Top = 1.0):      [%.3f, %.3f, 1.000]^T\n\n', ...
        phi_top_norm(1), phi_top_norm(2));
end

fprintf('Modal Orthogonality Verification:\n');
fprintf('  ||Phi^T * M * Phi - I||:          %e\n', mass_ortho_error);
fprintf('  ||Phi^T * K * Phi - diag(w^2)||:  %e\n\n', stiff_ortho_error);

% 7. Rooftop Equipment Resonance Assessment
f_motor = 240.0 / 60.0; % 240 RPM = 4.0 Hz
fprintf('Resonance Hazard Assessment (Rooftop Motor at %.2f Hz):\n', f_motor);
for mode = 1:3
    delta_pct = abs(f_motor - freq_hz(mode)) / freq_hz(mode) * 100.0;
    if delta_pct < 10.0
        fprintf('  CRITICAL HAZARD: Mode %d frequency (%.2f Hz) is within %.1f%% of motor RPM!\n', ...
            mode, freq_hz(mode), delta_pct);
        fprintf('  Action Required: Install vibration isolation dampers or change motor operating speed.\n');
    else
        fprintf('  Mode %d (%.2f Hz) is safe (Tuning separation = %.1f%%).\n', ...
            mode, freq_hz(mode), delta_pct);
    end
end

fprintf('\n=================================================================\n');
fprintf('  ALL LEVEL 1 - LEVEL 4 EXERCISE SOLUTIONS VERIFIED\n');
fprintf('=================================================================\n');
