%% 03_SOLVING_LINEAR_SYSTEMS.M
% Module 2: Linear Algebra for Engineers & Machine Learning
%
% This script demystifies solving systems of linear equations A*x = b:
% - Gaussian elimination and LU decomposition with partial pivoting ([L,U,P] = lu(A))
% - MATLAB's poly-algorithmic backslash operator (x = A\b)
% - The danger of matrix inversion: inv(A)*b vs A\b
% - Matrix condition number: cond(A), error bounds, and lost digits of precision
% - Overdetermined systems (m > n): Least-squares via backslash and normal equations
% - Underdetermined systems (m < n): Minimum-norm solutions and pseudoinverse (pinv)
%
% Educational Objective: Master the computational mechanics, numerical stability,
% and practical engineering decision-making behind solving linear systems.

clear; clc; close all;

fprintf('=======================================================\n');
fprintf('  MODULE 2: CONCEPT 03 - SOLVING LINEAR SYSTEMS\n');
fprintf('=======================================================\n\n');

%% 1. Systems of Linear Equations: Physical Problem Formulation
% Consider an industrial chemical mixing facility with 3 interconnected blending tanks.
% We require a steady-state product composition by balancing 3 raw ingredient streams:
%   2*x1 +   x2 -   x3 = 8     (Mass balance on component A)
%  -3*x1 -   x2 + 2*x3 = -11   (Mass balance on component B)
%  -2*x1 +   x2 + 2*x3 = -3    (Mass balance on component C)
%
% In matrix-vector form: A * x = b

fprintf('--- 1. Linear System Formulation (Chemical Mixing Balance) ---\n');

A = [ 2,  1, -1;
     -3, -1,  2;
     -2,  1,  2];

b = [8; -11; -3];

fprintf('Coefficient matrix A (3x3):\n');
disp(A);
fprintf('Right-hand side vector b (3x1):\n');
disp(b);

%% 2. LU Factorization with Partial Pivoting
% Modern solvers do not compute determinants or Cramer's rule (O(n!) complexity).
% Instead, they factor matrix A into Lower (L) and Upper (U) triangular matrices:
%   P * A = L * U
% where P is a permutation matrix that swaps rows to place the largest pivot element
% on the diagonal, preventing division by zero and minimizing round-off error.

fprintf('--- 2. LU Factorization with Partial Pivoting ---\n');

[L, U, P] = lu(A);

fprintf('Permutation Matrix P (row swaps):\n');
disp(P);
fprintf('Unit Lower Triangular Matrix L:\n');
disp(L);
fprintf('Upper Triangular Matrix U:\n');
disp(U);

% Solving PAx = Pb ==> L*(U*x) = P*b
% Step 1: Forward substitution: solve L * y = P * b
% Step 2: Backward substitution: solve U * x = y
Pb = P * b;
y  = L \ Pb;   % Forward substitution (O(n^2))
x_lu = U \ y;  % Backward substitution (O(n^2))

fprintf('Solution via LU decomposition:\n');
fprintf('  x1 = %8.4f kg/s\n', x_lu(1));
fprintf('  x2 = %8.4f kg/s\n', x_lu(2));
fprintf('  x3 = %8.4f kg/s\n\n', x_lu(3));

%% 3. The Backslash Operator: MATLAB's Workhorse
% The MATLAB backslash operator (x = A\b) is poly-algorithmic:
% 1. If A is upper/lower triangular, it uses immediate back/forward substitution.
% 2. If A is symmetric positive-definite, it executes Cholesky factorization.
% 3. If A is square and general, it executes LU factorization with partial pivoting.
% 4. If A is rectangular (m > n), it executes QR factorization for least-squares.

fprintf('--- 3. Direct Solution via Backslash Operator (x = A\\b) ---\n');

x_backslash = A \ b;

% Compute the residual norm: ||A*x - b||
residual = norm(A * x_backslash - b);

fprintf('Solution via A\\b:\n');
fprintf('  x1 = %8.4f\n', x_backslash(1));
fprintf('  x2 = %8.4f\n', x_backslash(2));
fprintf('  x3 = %8.4f\n', x_backslash(3));
fprintf('Residual norm ||A*x - b||: %e (Zero within machine precision)\n\n', residual);

%% 4. Matrix Inversion Hazards: inv(A)*b vs A\b
% WHY NEVER WRITE inv(A)*b:
% 1. Computational Cost:
%    - Inverting an n x n matrix takes ~ 2*n^3 flops.
%    - Gaussian elimination (A\b) takes ~ (2/3)*n^3 flops (3x faster!).
% 2. Numerical Stability & Error Propagation:
%    - inv(A)*b introduces unnecessary matrix multiplication errors and
%      amplifies roundoff when A is ill-conditioned.

fprintf('--- 4. Numerical Accuracy Demonstration: inv(A)*b vs A\\b ---\n');

% Construct a notoriously ill-conditioned Hilbert matrix of size 12x12:
% H(i,j) = 1 / (i + j - 1)
n_dim = 12;
H = hilb(n_dim);

% Choose a known exact ground truth solution: x_exact = [1; 1; ...; 1]
x_true = ones(n_dim, 1);
b_hilb = H * x_true;

% Solve using backslash
x_slash_hilb = H \ b_hilb;

% Solve using matrix inversion
x_inv_hilb = inv(H) * b_hilb;

% Compare absolute solution errors relative to ground truth
error_slash = norm(x_slash_hilb - x_true);
error_inv   = norm(x_inv_hilb - x_true);

fprintf('Hilbert Matrix size: %d x %d\n', n_dim, n_dim);
fprintf('Condition number cond(H): %e\n', cond(H));
fprintf('Error ||x_backslash - x_true||: %e\n', error_slash);
fprintf('Error ||x_inverse   - x_true||: %e\n', error_inv);
fprintf('Ratio (inv error / backslash error): %.2f x\n', error_inv / error_slash);
fprintf('Conclusion: Backslash is significantly more accurate and numerically stable.\n\n');

%% 5. Matrix Condition Number and Sensitivity Analysis
% The condition number kappa(A) = ||A|| * ||A^(-1)|| measures the sensitivity
% of the solution x to perturbations in b or A:
%   ||Delta x|| / ||x|| <= kappa(A) * (||Delta b|| / ||b||)
%
% Rule of Thumb: If kappa(A) = 10^k, you can lose up to k decimal digits of
% accuracy in IEEE 754 double precision (which has 16 decimal digits).

fprintf('--- 5. Condition Number and Precision Loss ---\n');

% Well-conditioned system
A_well = [10, 1; 2, 8];
kappa_well = cond(A_well);
digits_lost_well = log10(kappa_well);

% Poorly conditioned system (nearly parallel lines)
A_ill = [1.000, 1.000;
         1.000, 1.001];
kappa_ill = cond(A_ill);
digits_lost_ill = log10(kappa_ill);

fprintf('Well-conditioned matrix A_well:\n');
disp(A_well);
fprintf('  Condition number: %.2f  --> Estimated digits lost: %.1f / 16\n\n', ...
    kappa_well, digits_lost_well);

fprintf('Ill-conditioned matrix A_ill (nearly singular):\n');
disp(A_ill);
fprintf('  Condition number: %.2e  --> Estimated digits lost: %.1f / 16\n\n', ...
    kappa_ill, digits_lost_ill);

%% 6. Overdetermined Systems: Least Squares Calibration (m > n)
% In sensor calibration and experimental data fitting, we often have MORE
% measurements than unknown parameters (m > n).
% An exact solution Ax = b does not exist due to noise, so we minimize
% the sum of squared residuals: min ||A*x - b||^2.
%
% The normal equations state: (A^T * A) * x = A^T * b
% MATLAB's backslash automatically computes the least squares solution via QR factorization!

fprintf('--- 6. Overdetermined System: Sensor Calibration (m > n) ---\n');

% Thermistor calibration: Voltage V vs Temperature T
% Model: V = c1 + c2 * T
% Experimental data points [Temperature (deg C), Measured Voltage (V)]:
T_data = [10; 20; 30; 40; 50; 60; 70]; % 7 measurements
V_data = [1.22; 1.58; 1.95; 2.31; 2.74; 3.09; 3.48];

% Assemble design matrix A with a column of ones for intercept c1
A_design = [ones(length(T_data), 1), T_data];

% Solve least squares via backslash: x_fit = [c1; c2]
c_params = A_design \ V_data;

% Verify with the Normal Equations: (A'*A) \ (A'*V)
c_normal = (A_design' * A_design) \ (A_design' * V_data);

% Verify with Moore-Penrose pseudoinverse: pinv(A) * V
c_pinv = pinv(A_design) * V_data;

fprintf('Calibration parameters (V = c1 + c2*T):\n');
fprintf('  c1 (Intercept):  %.4f V\n', c_params(1));
fprintf('  c2 (Sensitivity): %.4f V/degC\n', c_params(2));
fprintf('Discrepancy between Backslash and Normal Equations: %e\n', norm(c_params - c_normal));
fprintf('Discrepancy between Backslash and Pseudoinverse:    %e\n\n', norm(c_params - c_pinv));

%% 7. Graphical Visualization (Least Squares Fit)
figure('Name', 'Linear Systems & Least Squares', 'Color', 'w');

% Plot data points and fitted model
plot(T_data, V_data, 'ro', 'MarkerSize', 8, 'MarkerFaceColor', 'r', 'DisplayName', 'Sensor Data');
hold on; grid on;
T_fit = linspace(5, 75, 100)';
V_fit = c_params(1) + c_params(2) * T_fit;
plot(T_fit, V_fit, 'b-', 'LineWidth', 2, 'DisplayName', sprintf('Least-Squares Line: V = %.2f + %.4f T', c_params(1), c_params(2)));

title('Overdetermined System: Sensor Least-Squares Line Fit (A\\b)');
xlabel('Temperature (^\circC)');
ylabel('Sensor Output Voltage (V)');
legend('Location', 'northwest');

fprintf('=======================================================\n');
fprintf('  CONCEPT 03 COMPLETED SUCCESSFULLY\n');
fprintf('=======================================================\n');
