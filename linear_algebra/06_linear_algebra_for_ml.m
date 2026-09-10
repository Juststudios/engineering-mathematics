%% 06_LINEAR_ALGEBRA_FOR_ML.M
% Module 2: Linear Algebra for Engineers & Machine Learning
%
% This script builds the foundational bridge between Linear Algebra (Level 2)
% and Machine Learning / Data Science (Level 3):
% - Feature matrices X (N x D), weight vectors w, and target vectors y
% - Ordinary Least Squares (OLS) as orthogonal projection onto Col(X)
% - The Normal Equations: (X^T * X) * w = X^T * y  ==>  w = X \ y
% - Ridge Regression (L2 / Tikhonov regularization) and condition improvement
% - Centering matrix, sample mean vector, and covariance matrix Sigma
% - Principal Component Analysis (PCA) via Eigendecomposition and SVD
%
% Educational Objective: Understand how data tables become vector spaces,
% regression models become linear solvers, and PCA becomes an eigenvalue problem.

clear; clc; close all;

fprintf('=======================================================\n');
fprintf('  MODULE 2: CONCEPT 06 - LINEAR ALGEBRA FOR ML\n');
fprintf('=======================================================\n\n');

%% 1. The Machine Learning Representation
% In machine learning:
% - N = Number of engineering observations (rows)
% - D = Number of sensor telemetry features (columns)
%
% Feature Matrix X: N x D
% Target Vector   y: N x 1
% Weight Vector   w: D x 1
%
% Linear Model: y_hat = X * w

fprintf('--- 1. Data Representation in Machine Learning ---\n');

% Generate synthetic engineering telemetry for an electric vehicle (N = 100 samples)
rng(42); % Seed for exact reproducibility
N = 100;

% Feature 1: Motor Speed (RPM / 1000)
motor_speed_krpm = 2.0 + 3.0 * rand(N, 1);
% Feature 2: Motor Torque (Nm / 100)
motor_torque_scale = 0.5 + 1.5 * rand(N, 1);
% Feature 3: Battery Current (Amps / 100)
battery_current_scale = 0.8 * motor_speed_krpm + 1.2 * motor_torque_scale + 0.1 * randn(N, 1);

% True physical process governing Inverter Temperature (deg C):
%   Temp = 25.0 + 8.5 * Speed + 12.0 * Torque + 5.0 * Current + noise
y_temp = 25.0 + 8.5 * motor_speed_krpm + 12.0 * motor_torque_scale + ...
         5.0 * battery_current_scale + 0.5 * randn(N, 1);

% Assemble Feature Matrix X with intercept column (column of ones)
X = [ones(N, 1), motor_speed_krpm, motor_torque_scale, battery_current_scale];

fprintf('Telemetry Dataset Size: N = %d samples, D = %d features (including intercept)\n', ...
    size(X, 1), size(X, 2));
fprintf('First 5 rows of Feature Matrix X [Intercept, Speed, Torque, Current]:\n');
disp(X(1:5, :));
fprintf('First 5 values of Target Vector y (Inverter Temp in deg C):\n');
disp(y_temp(1:5));

%% 2. Ordinary Least Squares (OLS) Linear Regression
% The goal of linear regression is to find weights w minimizing Mean Squared Error:
%   J(w) = (1 / 2N) * ||X*w - y||_2^2
%
% Setting gradient to zero yields the Normal Equations:
%   (X^T * X) * w = X^T * y
%
% Geometrically, y_hat = X*w is the ORTHOGONAL PROJECTION of y onto the subspace
% spanned by the columns of X (Col(X)). The residual vector e = y - y_hat
% is strictly orthogonal to all feature columns: X^T * e = 0.

fprintf('--- 2. Ordinary Least Squares (Normal Equations & Backslash) ---\n');

% Solve using MATLAB backslash (QR factorization behind the scenes)
w_ols = X \ y_temp;

% Verify with the analytic Normal Equations: w = (X^T * X)^(-1) * X^T * y
w_normal = (X' * X) \ (X' * y_temp);

fprintf('Learned Model Weights w = [w0 (bias); w1; w2; w3]:\n');
fprintf('  w0 (Ambient / Base Temp):  %8.4f degC (Ground truth = 25.0)\n', w_ols(1));
fprintf('  w1 (Speed coefficient):    %8.4f degC/krpm (Ground truth = 8.5)\n', w_ols(2));
fprintf('  w2 (Torque coefficient):   %8.4f degC/unit (Ground truth = 12.0)\n', w_ols(3));
fprintf('  w3 (Current coefficient):  %8.4f degC/unit (Ground truth = 5.0)\n\n', w_ols(4));

% Evaluate predictions and model metrics
y_pred = X * w_ols;
residuals = y_temp - y_pred;

% Check residual orthogonality to columns of X
ortho_error = norm(X' * residuals);
fprintf('Orthogonality Check ||X^T * (y - X*w)||: %e\n', ortho_error);

% Model evaluation metrics: RMSE and R^2 Score
RMSE = sqrt(mean(residuals.^2));
SS_tot = sum((y_temp - mean(y_temp)).^2);
SS_res = sum(residuals.^2);
R2_score = 1.0 - (SS_res / SS_tot);

fprintf('Regression Performance:\n');
fprintf('  Root Mean Squared Error (RMSE): %.4f deg C\n', RMSE);
fprintf('  Coefficient of Determination R^2: %.4f (%.2f%% variance explained)\n\n', ...
    R2_score, R2_score * 100);

%% 3. Ridge Regression (L2 / Tikhonov Regularization)
% When features are collinear (e.g. Current depends heavily on Speed and Torque),
% X^T * X has a very large condition number. Small measurement noise can blow up weights.
%
% Ridge regression adds a diagonal penalty:
%   (X^T * X + lambda * I) * w_ridge = X^T * y
%
% This stabilizes the inversion and improves numerical conditioning:
%   cond(X^T * X + lambda * I) < cond(X^T * X)

fprintf('--- 3. Ridge Regression & Condition Number Improvement ---\n');

XtX = X' * X;
kappa_ols = cond(XtX);

lambda_reg = 10.0; % Regularization hyperparameter
I_reg = eye(size(X, 2));
I_reg(1, 1) = 0;   % Do not regularize the intercept term

XtX_ridge = XtX + lambda_reg * I_reg;
kappa_ridge = cond(XtX_ridge);

w_ridge = XtX_ridge \ (X' * y_temp);

fprintf('Gram Matrix Condition Number: cond(X^T * X) = %.2f\n', kappa_ols);
fprintf('Ridge Matrix Condition Number: cond(X^T * X + lambda*I) = %.2f\n', kappa_ridge);
fprintf('Condition improvement factor: %.2f x\n\n', kappa_ols / kappa_ridge);

%% 4. Sample Mean, Centering, and Covariance Matrix
% To understand relationships between telemetry channels:
% 1. Compute mean vector mu = (1/N) * sum(X_raw)
% 2. Center the data: X_tilde = X_raw - ones(N, 1) * mu^T
% 3. Sample Covariance Matrix:
%      Sigma = (1 / (N - 1)) * (X_tilde^T * X_tilde)
%
% Diagonal entries: variances sigma_j^2
% Off-diagonal entries: covariances sigma_jk

fprintf('--- 4. Telemetry Covariance Analysis ---\n');

% Select continuous sensor telemetry channels (excluding intercept)
X_raw = [motor_speed_krpm, motor_torque_scale, battery_current_scale];
channel_names = {'Motor Speed', 'Motor Torque', 'Battery Current'};

% Mean vector (1 x D)
mu_vec = mean(X_raw, 1);

% Centered data matrix X_tilde
X_tilde = X_raw - mu_vec;

% Sample Covariance Matrix (3x3)
Sigma = (X_tilde' * X_tilde) / (N - 1);

fprintf('Mean Telemetry Vector [Speed, Torque, Current]:\n');
disp(mu_vec);
fprintf('Sample Covariance Matrix Sigma:\n');
disp(Sigma);

% Correlation Matrix: R_jk = Sigma_jk / (sigma_j * sigma_k)
D_inv_sqrt = diag(1 ./ sqrt(diag(Sigma)));
R_corr = D_inv_sqrt * Sigma * D_inv_sqrt;

fprintf('Correlation Matrix (Values in [-1, +1]):\n');
disp(R_corr);

%% 5. Principal Component Analysis (PCA) via Eigendecomposition & SVD
% PCA rotates high-dimensional data into orthogonal axes of maximal variance:
% 1. Compute eigendecomposition of Covariance Matrix Sigma:
%      Sigma * v_i = lambda_i * v_i
% 2. Eigenvectors v_i are the Principal Component Directions (Loadings)
% 3. Eigenvalues lambda_i are the Variances along those directions
% 4. Singular Value Decomposition (SVD) of X_tilde achieves the exact same result:
%      X_tilde = U * S * V^T  ==>  lambda_i = s_i^2 / (N - 1)

fprintf('--- 5. Dimensionality Reduction via PCA and SVD ---\n');

% Eigendecomposition of Sigma
[V_eig, D_eig] = eig(Sigma);

% Sort eigenvalues descending (largest variance first)
[eigenvalues, sort_order] = sort(diag(D_eig), 'descend');
V_pca = V_eig(:, sort_order);

% Compute Explained Variance Ratio
total_variance = sum(eigenvalues);
var_explained_ratio = eigenvalues / total_variance;
cumulative_var = cumsum(var_explained_ratio);

fprintf('PCA Eigenvalues (Variances):\n');
for k = 1:length(eigenvalues)
    fprintf('  PC %d: Variance = %8.4f | Explained = %6.2f%% | Cumulative = %6.2f%%\n', ...
        k, eigenvalues(k), var_explained_ratio(k)*100, cumulative_var(k)*100);
end

% Verify equivalence with Economy SVD: [U, S, V_svd] = svd(X_tilde, 'econ')
[U_svd, S_svd, V_svd] = svd(X_tilde, 'econ');
singular_values = diag(S_svd);
svd_variances = (singular_values.^2) / (N - 1);

fprintf('\nVerification with Singular Value Decomposition (SVD):\n');
fprintf('  Max discrepancy between SVD and Eigendecomposition variances: %e\n', ...
    norm(eigenvalues - svd_variances));

% Project high-dimensional telemetry (3D) to 2D Principal Component Space:
%   Z = X_tilde * V_2D  (N x 2)
V_2D = V_pca(:, 1:2);
Z_projected = X_tilde * V_2D;

fprintf('Projected data shape: %d samples x %d latent dimensions\n', ...
    size(Z_projected, 1), size(Z_projected, 2));
fprintf('Compression retains %.2f%% of total physical system variance!\n\n', ...
    cumulative_var(2) * 100);

%% 6. Graphical Visualization (Regression & PCA Projection)
figure('Name', 'Linear Algebra for Machine Learning', 'Color', 'w');

% Subplot 1: True vs Predicted Temperature (OLS Model Quality)
subplot(1, 2, 1);
plot(y_temp, y_pred, 'b.', 'MarkerSize', 12); hold on; grid on; axis equal;
plot([min(y_temp), max(y_temp)], [min(y_temp), max(y_temp)], 'r--', 'LineWidth', 2);
title(sprintf('OLS Fit: Inverter Temp (R^2 = %.3f, RMSE = %.2f^\\circC)', R2_score, RMSE));
xlabel('Actual Measured Temp (^\circC)');
ylabel('Predicted Model Temp (^\circC)');
legend('Telemetry Points', 'Ideal Prediction Line (y = \hat{y})', 'Location', 'northwest');

% Subplot 2: 2D PCA Latent Space
subplot(1, 2, 2);
scatter(Z_projected(:, 1), Z_projected(:, 2), 35, y_temp, 'filled');
grid on; colorbar;
title(sprintf('PCA Latent Space (2 PCs capture %.1f%% Variance)', cumulative_var(2)*100));
xlabel(sprintf('PC 1 (%.1f%% Variance)', var_explained_ratio(1)*100));
ylabel(sprintf('PC 2 (%.1f%% Variance)', var_explained_ratio(2)*100));
colormap('jet');

fprintf('=======================================================\n');
fprintf('  CONCEPT 06 COMPLETED SUCCESSFULLY\n');
fprintf('=======================================================\n');
