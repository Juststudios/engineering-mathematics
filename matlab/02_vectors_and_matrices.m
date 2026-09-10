%% 02_vectors_and_matrices.m
% =========================================================================
% MATLAB Fundamentals & Computational Environment: Vectors and Matrices
% =========================================================================
% Pedagogical Objective:
% This script establishes the core mechanics of multi-dimensional arrays
% in MATLAB. Coming from Python/NumPy, students must reorient their mental
% models around:
%   1. 1-based indexing (first element is 1, not 0)
%   2. Row vs. Column vectors and orientation discipline
%   3. Column-Major storage (Fortran memory layout) vs Row-Major (C layout)
%   4. Colon slicing (start:step:end) and end keyword
%   5. Linear Indexing, sub2ind, and ind2sub
%   6. Logical Indexing (Boolean masking) for physical anomaly detection
%
% Applied Engineering Context:
% Multi-axis flight dynamic sensor package (3-axis gyroscope + 3-axis accelerometer)
% recording structural telemetry during an aerodynamic gust event.
% =========================================================================

clearvars;
close all;
clc;

fprintf('====================================================\n');
fprintf(' MODULE 1: VECTORS, MATRICES, AND INDEXING IN MATLAB\n');
fprintf('====================================================\n\n');

%% 1. Row Vectors vs. Column Vectors: Orientation Matters
% In linear algebra, a row vector is a 1xN matrix, whereas a column vector
% is an Nx1 matrix. In NumPy, a 1D array typically has shape (N,), which is
% neither row nor column until explicitly reshaped. In MATLAB, every vector
% has a strictly defined 2D orientation!

% --- Row vector: Elements separated by commas or spaces ---
row_vec = [10, 20, 30, 40, 50]; % Size: 1x5
fprintf('row_vec: Size = [%d, %d], Orientation = Row Vector\n', ...
    size(row_vec, 1), size(row_vec, 2));

% --- Column vector: Elements separated by semicolons ---
col_vec = [10; 20; 30; 40; 50]; % Size: 5x1
fprintf('col_vec: Size = [%d, %d], Orientation = Column Vector\n', ...
    size(col_vec, 1), size(col_vec, 2));

% --- Transpose operators: Complex Conjugate (') vs Array Transpose (.') ---
% In real numbers, both produce identical results. In complex signal processing,
% A' computes the Hermitian conjugate (transpose + conjugate), whereas A.'
% computes pure transpose without conjugate.
row_from_col = col_vec';
fprintf('Transpose of col_vec: Size = [%d, %d]\n\n', ...
    size(row_from_col, 1), size(row_from_col, 2));

%% 2. Uniform Vector Generation: Colon Operator and linspace
% Time and space grids are the foundation of physical modeling.
% Method A: Colon operator -> start:step:end (known spacing)
t_colon = 0.0 : 0.1 : 1.0; % 0.0, 0.1, 0.2, ... 1.0 (11 elements)

% Method B: linspace -> linspace(start, end, num_points) (known sample count)
t_linspace = linspace(0.0, 1.0, 11);

% Engineering note: linspace guarantees exact inclusion of the endpoint,
% avoiding floating-point step-accumulation round-off errors.
max_discrepancy = max(abs(t_colon - t_linspace));
fprintf('Max difference between colon and linspace: %e (Exact match)\n\n', ...
    max_discrepancy);

%% 3. Matrix Generation & Preallocation Routines
% High-performance scientific codes ALWAYS preallocate arrays to prevent
% dynamic heap memory reallocation during loops.
n_rows = 3;
n_cols = 4;

zeros_mat = zeros(n_rows, n_cols);   % 3x4 matrix filled with 0.0
ones_mat  = ones(n_rows, n_cols);    % 3x4 matrix filled with 1.0
eye_mat   = eye(n_rows);             % 3x3 Identity matrix I
rand_mat  = rand(n_rows, n_cols);    % Uniform random numbers in (0, 1)
randn_mat = randn(n_rows, n_cols);   % Gaussian / Normal random (mean=0, std=1)

fprintf('Generated 3x3 Identity Matrix:\n');
disp(eye_mat);

%% 4. Array Concatenation: Horizontal vs Vertical
% Horizontal concatenation [A, B] combines columns (must share row count)
% Vertical concatenation [A; B] combines rows (must share column count)

mat_A = [1, 2; 3, 4];   % 2x2
mat_B = [5, 6; 7, 8];   % 2x2

mat_horz = [mat_A, mat_B]; % 2x4 horizontal concatenation
mat_vert = [mat_A; mat_B]; % 4x2 vertical concatenation

fprintf('Horizontal concatenation [A, B] size: [%d, %d]\n', size(mat_horz));
fprintf('Vertical concatenation   [A; B] size: [%d, %d]\n\n', size(mat_vert));

%% 5. 1-Based Indexing and Colon Slicing
% In MATLAB, indices start at 1. The keyword 'end' refers to the final element
% along the specified dimension.

% Create a simulated multi-channel telemetry matrix:
% 6 rows (Sensors: Accel X, Y, Z, Gyro X, Y, Z)
% 8 columns (Time points t1 through t8)
telemetry_data = [
    0.12,  0.15,  0.18,  0.22,  0.25,  0.30,  0.28,  0.20;  % Accel X [g]
   -0.02, -0.01,  0.03,  0.05, -0.02, -0.04,  0.01,  0.00;  % Accel Y [g]
    0.98,  0.99,  1.02,  1.05,  1.01,  0.98,  0.99,  1.00;  % Accel Z [g]
    1.20,  1.45,  1.80,  2.10,  1.75,  1.30,  0.90,  0.50;  % Gyro X [deg/s]
   -0.40, -0.35, -0.50, -0.62, -0.45, -0.20,  0.00,  0.10;  % Gyro Y [deg/s]
    0.05,  0.08,  0.12,  0.15,  0.10,  0.05,  0.02,  0.00   % Gyro Z [deg/s]
];

% Extract a single value: Row 1, Column 3 (Accel X at t3)
accel_x_t3 = telemetry_data(1, 3);
fprintf('Single value access telemetry_data(1, 3): %6.3f g\n', accel_x_t3);

% Extract entire 3rd row: All Accel Z time series (Row 3, All Columns ':')
accel_z_all = telemetry_data(3, :);
fprintf('Extracted Row 3 (Accel Z, length %d): Mean = %6.3f g\n', ...
    length(accel_z_all), mean(accel_z_all));

% Extract sub-matrix: All accelerometer channels (Rows 1:3) at middle time steps (Cols 3:6)
accel_mid_burst = telemetry_data(1:3, 3:6);
fprintf('Sub-matrix slice (Rows 1:3, Cols 3:6) Size: [%d, %d]\n', ...
    size(accel_mid_burst, 1), size(accel_mid_burst, 2));

% Slicing with strides: e.g. downsample by taking every 2nd time sample
downsampled_data = telemetry_data(:, 1:2:end);
fprintf('Downsampled telemetry (every 2nd column) Size: [%d, %d]\n\n', ...
    size(downsampled_data, 1), size(downsampled_data, 2));

%% 6. Column-Major Memory Layout & Linear Indexing
% MATLAB stores matrices internally as a contiguous 1D stream of elements,
% ordered DOWN COLUMNS FIRST.
% For an m x n matrix, element (i, j) has linear index:
%   k = (j - 1) * m + i

test_grid = [10, 40, 70;
             20, 50, 80;
             30, 60, 90]; % 3x3 matrix

% Accessing via single linear index:
fprintf('Column-major 1D stream: test_grid(1:9) = \n');
fprintf(' %d', test_grid(1:9)); % Prints 10 20 30 40 50 60 70 80 90
fprintf('\n');

% Converting between (row, col) and linear index using sub2ind and ind2sub
target_row = 2;
target_col = 3;
lin_idx = sub2ind(size(test_grid), target_row, target_col);
fprintf('sub2ind: Element at (%d, %d) has linear index %d (Value = %d)\n', ...
    target_row, target_col, lin_idx, test_grid(lin_idx));

[retrieved_row, retrieved_col] = ind2sub(size(test_grid), lin_idx);
fprintf('ind2sub: Linear index %d maps back to row %d, col %d\n\n', ...
    lin_idx, retrieved_row, retrieved_col);

%% 7. Logical Indexing (Boolean Masking) for Physical Anomaly Detection
% In engineering, logical indexing is the most computationally efficient method
% for threshold filtering, outlier detection, and signal clipping.

% Scenario: Detect when Gyro X rate exceeds safety limit of 1.5 deg/s
gyro_x_channel = telemetry_data(4, :); % Extract Gyro X row
safety_limit_rate = 1.5;               % [deg/s]

% Create logical mask array (array of true/false)
exceeds_threshold_mask = (gyro_x_channel > safety_limit_rate);

fprintf('--- LOGICAL INDEXING SAFETY FILTER ---\n');
fprintf('Threshold: Rate > %4.2f deg/s\n', safety_limit_rate);
fprintf('Mask vector: ');
fprintf('%d ', exceeds_threshold_mask);
fprintf('\n');

% Extract ONLY the values that violated the safety threshold
critical_violations = gyro_x_channel(exceeds_threshold_mask);
fprintf('Identified %d safety violations: ', length(critical_violations));
fprintf('%5.2f deg/s ', critical_violations);
fprintf('\n');

% Applied Conditioning: Clip / Saturated Telemetry values
% Clamp all values exceeding 2.0 down to exactly 2.0 (Sensor Saturation Model)
gyro_x_clamped = gyro_x_channel;
gyro_x_clamped(gyro_x_clamped > 2.0) = 2.0;
fprintf('Clamped peak value from %5.2f to %5.2f deg/s\n\n', ...
    max(gyro_x_channel), max(gyro_x_clamped));

%% 8. Reshaping and Flattening
% reshape(A, m, n) reorganizes the matrix into new dimensions while
% strictly preserving column-major order. Total element count must not change.
flat_column = telemetry_data(:); % The colon operator (:) flattens any array to Nx1 column
fprintf('Flattened telemetry vector length: %d (Total elements = %d)\n', ...
    length(flat_column), numel(telemetry_data));

reconstructed_mat = reshape(flat_column, size(telemetry_data));
diff_reconstruct = max(max(abs(reconstructed_mat - telemetry_data)));
fprintf('Reshape round-trip maximum error: %e\n', diff_reconstruct);

fprintf('====================================================\n');
fprintf(' 02_vectors_and_matrices.m execution completed successfully.\n');
