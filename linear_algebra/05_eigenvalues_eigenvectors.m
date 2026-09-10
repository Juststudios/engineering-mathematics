%% 05_EIGENVALUES_EIGENVECTORS.M
% Module 2: Linear Algebra for Engineers & Machine Learning
%
% This script explores eigenvalues and eigenvectors in theory and engineering:
% - Mathematical formulation: A*v = lambda*v and characteristic polynomial det(A - lambda*I) = 0
% - MATLAB syntax: [V, D] = eig(A), sorting, and modal orthogonality
% - Application 1: Multi-Degree-of-Freedom (MDOF) Building Vibration & Resonance
%   (Generalized eigenvalue problem: K*phi = omega^2 * M*phi)
% - Application 2: Principal Stresses and Failure Criteria in Solid Mechanics
%   (Cauchy stress tensor diagonalization, Tresca and von Mises stresses)
%
% Educational Objective: Understand that eigenvalues represent intrinsic physical
% properties (natural frequencies, principal loads, decay rates) that do not
% depend on the choice of coordinate axes.

clear; clc; close all;

fprintf('=======================================================\n');
fprintf('  MODULE 2: CONCEPT 05 - EIGENVALUES & EIGENVECTORS\n');
fprintf('=======================================================\n\n');

%% 1. Mathematical Foundations and Geometric Meaning
% An eigenvector v of matrix A is a direction that remains unchanged in direction
% when transformed by A; it only stretches by factor lambda:
%   A * v = lambda * v  ==>  (A - lambda * I) * v = 0

fprintf('--- 1. Mathematical Foundations & Eigendecomposition ---\n');

A_test = [4, 1;
          2, 3];

% Characteristic polynomial coefficients: det(A - lambda*I) = lambda^2 - tr(A)*lambda + det(A)
p_coeffs = charpoly(A_test);
fprintf('Characteristic polynomial of A: lambda^2 - %.1f*lambda + %.1f = 0\n', ...
    -p_coeffs(2), p_coeffs(3));

% Roots of characteristic polynomial give eigenvalues
lambda_roots = roots(p_coeffs);
fprintf('Roots of characteristic polynomial:\n');
disp(lambda_roots);

% Direct MATLAB eigendecomposition: [V, D] = eig(A)
[V, D] = eig(A_test);
fprintf('Eigenvalues (diagonal of D):\n');
disp(diag(D));
fprintf('Eigenvector matrix V (columns are unit eigenvectors):\n');
disp(V);

% Verify A*v = lambda*v for the first eigenpair
v1 = V(:, 1);
lambda1 = D(1, 1);
lhs = A_test * v1;
rhs = lambda1 * v1;
fprintf('Verification A*v1 vs lambda1*v1:\n');
fprintf('  A*v1 =        [%.4f; %.4f]\n', lhs(1), lhs(2));
fprintf('  lambda1*v1 =  [%.4f; %.4f]\n', rhs(1), rhs(2));
fprintf('  Discrepancy norm: %e\n\n', norm(lhs - rhs));

%% 2. Symmetric Matrices & Spectral Theorem
% For any real symmetric matrix (A = A^T):
% 1. All eigenvalues are strictly REAL.
% 2. Eigenvectors for distinct eigenvalues are mutually ORTHOGONAL (V^T * V = I).
% 3. The matrix can be diagonalized: A = V * D * V^T

fprintf('--- 2. Spectral Theorem for Symmetric Matrices ---\n');

A_symm = [6, -2,  2;
         -2,  5,  0;
          2,  0,  7];

[V_symm, D_symm] = eig(A_symm);

fprintf('Symmetric Matrix A:\n');
disp(A_symm);
fprintf('Orthogonality check (V^T * V - I):\n');
disp(norm(V_symm' * V_symm - eye(3), 'fro'));

% Reconstruction via spectral decomposition: A = sum(lambda_i * v_i * v_i^T)
A_reconstructed = V_symm * D_symm * V_symm';
fprintf('Spectral reconstruction error ||A - V*D*V^T||: %e\n\n', norm(A_symm - A_reconstructed));

%% 3. Engineering Application 1: MDOF Structural Vibration
% Consider a 2-story building modeled as a 2-DOF shear frame.
% Floor 1 mass m1 = 20,000 kg, Floor 2 mass m2 = 15,000 kg
% Story 1 shear stiffness k1 = 18 MN/m, Story 2 shear stiffness k2 = 12 MN/m
%
% Equations of Motion (undamped free vibration):
%   M * x_ddot + K * x = 0
%
% Mass Matrix M:
%   M = [m1,  0;
%        0,  m2]
%
% Stiffness Matrix K:
%   K = [k1 + k2,  -k2;
%          -k2,     k2]
%
% Harmonic motion assumption: x(t) = phi * cos(omega*t)
% Leads to generalized eigenvalue problem: K * phi = omega^2 * M * phi

fprintf('--- 3. Structural Vibration: 2-Story Building Shear Frame ---\n');

m1 = 20000; % kg
m2 = 15000; % kg
k1 = 18e6;  % N/m
k2 = 12e6;  % N/m

M = [m1,  0;
     0,  m2];

K = [k1 + k2,  -k2;
       -k2,     k2];

% Solve generalized eigenvalue problem: [Phi, Omega2] = eig(K, M)
[Phi, Omega2] = eig(K, M);

% Extract eigenvalues (omega^2) and sort in ascending order
[omega2_sorted, sort_idx] = sort(diag(Omega2), 'ascend');
Phi_sorted = Phi(:, sort_idx);

% Natural angular frequencies (rad/s) and cyclic frequencies (Hz)
omega_n = sqrt(omega2_sorted);
freq_hz = omega_n / (2 * pi);

fprintf('Modal Analysis Results:\n');
for i = 1:2
    fprintf('  Mode %d:\n', i);
    fprintf('    Eigenvalue (omega_%d^2):     %12.2f (rad/s)^2\n', i, omega2_sorted(i));
    fprintf('    Natural Frequency (omega_%d): %8.2f rad/s\n', i, omega_n(i));
    fprintf('    Cyclic Frequency (f_%d):      %8.2f Hz (T = %.3f s)\n', i, freq_hz(i), 1/freq_hz(i));
    % Normalize mode shape relative to top floor (x2 = 1.0)
    phi_norm = Phi_sorted(:, i) / Phi_sorted(2, i);
    fprintf('    Normalized Mode Shape: [Floor 1: %.3f, Floor 2: %.3f]^T\n\n', ...
        phi_norm(1), phi_norm(2));
end

% Physical Resonance Assessment:
% Mode 1 (Fundamental Mode): Floors sway in phase (phi1 and phi2 same sign)
% Mode 2 (Higher Mode): Floors sway in opposite phase (phi1 and phi2 opposite signs)
fprintf('Engineering Resonance Assessment:\n');
fprintf('  If an earthquake or rotating rooftop HVAC equipment vibrates at\n');
fprintf('  f ~= %.2f Hz or f ~= %.2f Hz, resonance will induce violent sway.\n\n', ...
    freq_hz(1), freq_hz(2));

%% 4. Engineering Application 2: Principal Stresses in Solid Mechanics
% At any point inside a loaded machine component, the 3D stress state is
% defined by the symmetric Cauchy Stress Tensor:
%   sigma = [sigma_xx,  tau_xy,   tau_xz;
%            tau_xy,    sigma_yy,  tau_yz;
%            tau_xz,    tau_yz,   sigma_zz]
%
% Finding the eigenvalues of sigma yields the PRINCIPAL STRESSES (sigma1 >= sigma2 >= sigma3).
% The eigenvectors define the PRINCIPAL PLANES (planes where shear stress is zero).

fprintf('--- 4. Solid Mechanics: 3D Principal Stresses & Failure Check ---\n');

% Measured stress tensor on a pressurized turbine casing (values in MPa)
sigma_tensor = [ 120.0,   45.0,  -15.0;
                  45.0,   80.0,   25.0;
                 -15.0,   25.0,  -40.0 ];

% Compute eigenvalues and eigenvectors
[V_planes, D_stress] = eig(sigma_tensor);

% Sort eigenvalues descending: sigma1 >= sigma2 >= sigma3
[sigma_p, p_idx] = sort(diag(D_stress), 'descend');
V_planes = V_planes(:, p_idx);

sigma1 = sigma_p(1); % Maximum principal stress
sigma2 = sigma_p(2); % Intermediate principal stress
sigma3 = sigma_p(3); % Minimum principal stress

fprintf('Stress Tensor (MPa):\n');
disp(sigma_tensor);

fprintf('Principal Stresses (Eigenvalues in MPa):\n');
fprintf('  sigma_1 (Max tension):      %8.2f MPa\n', sigma1);
fprintf('  sigma_2 (Intermediate):     %8.2f MPa\n', sigma2);
fprintf('  sigma_3 (Max compression):  %8.2f MPa\n\n', sigma3);

% Maximum Shear Stress (Tresca Failure Criterion):
%   tau_max = (sigma1 - sigma3) / 2
tau_max = (sigma1 - sigma3) / 2.0;

% Von Mises Equivalent Stress (Distortion Energy Criterion):
%   sigma_vm = sqrt(0.5 * [(s1-s2)^2 + (s2-s3)^2 + (s3-s1)^2])
sigma_vm = sqrt(0.5 * ((sigma1 - sigma2)^2 + (sigma2 - sigma3)^2 + (sigma3 - sigma1)^2));

% Material Yield Strength (Structural Steel ASTM A36)
sigma_yield = 250.0; % MPa

% Factor of Safety against Yielding
FOS_tresca = (sigma_yield / 2.0) / tau_max;
FOS_vm     = sigma_yield / sigma_vm;

fprintf('Failure Criteria and Safety Factor Analysis:\n');
fprintf('  Max Shear Stress (Tresca):   %8.2f MPa\n', tau_max);
fprintf('  Von Mises Equivalent Stress: %8.2f MPa\n', sigma_vm);
fprintf('  Material Yield Strength:     %8.2f MPa\n', sigma_yield);
fprintf('  Factor of Safety (Tresca):   %8.2f\n', FOS_tresca);
fprintf('  Factor of Safety (von Mises):%8.2f\n\n', FOS_vm);

if FOS_vm >= 1.5
    fprintf('Status: Component is structurally SAFE under operational loads (FOS >= 1.5).\n');
else
    fprintf('Status: WARNING - Inadequate factor of safety; component at risk of plastic yield!\n');
end

fprintf('=======================================================\n');
fprintf('  CONCEPT 05 COMPLETED SUCCESSFULLY\n');
fprintf('=======================================================\n');
