%% 01_VECTORS_AND_SPACES.M
% Module 2: Linear Algebra for Engineers & Machine Learning
%
% This script introduces vectors as physical and computational entities:
% - Vector representations: row vectors vs column vectors
% - Vector norms: L1 (Manhattan), L2 (Euclidean), and L-infinity (Chebyshev)
% - Dot product, vector angles, and work calculation
% - Orthogonal projections and force decomposition on an incline
% - Cross products, moment arms, and mechanical torque in 3D
% - Linear independence, span, and basis representation
%
% Educational Objective: Understand how physical engineering quantities
% (forces, displacements, velocities, torques) map to linear algebraic vectors
% and how vector operations quantify magnitude, alignment, and perpendicularity.

clear; clc; close all;

fprintf('=======================================================\n');
fprintf('  MODULE 2: CONCEPT 01 - VECTORS AND SPACES\n');
fprintf('=======================================================\n\n');

%% 1. Vector Representations: Row vs Column Vectors
% In mathematics and engineering mechanics, column vectors are the standard
% convention for state vectors, positions, and forces. In MATLAB:
% - Comma or space creates a row vector: [1, 2, 3] or [1 2 3]
% - Semicolon creates a column vector: [1; 2; 3]
% - The apostrophe (') computes the complex conjugate transpose (transpose for real numbers)

fprintf('--- 1. Vector Representations ---\n');

% Force vector applied at a structural node (in Newtons: [Fx; Fy; Fz])
F_col = [120.0; -45.0; 80.0];      % 3x1 column vector
fprintf('Column Vector F (Force in N):\n');
disp(F_col);

% Displacement vector of the node (in meters: [dx, dy, dz])
d_row = [0.015, -0.005, 0.010];     % 1x3 row vector
fprintf('Row Vector d (Displacement in m):\n');
disp(d_row);

% Convert row vector to column vector using transpose
d_col = d_row';
fprintf('Dimensions of F_col: %d x %d\n', size(F_col, 1), size(F_col, 2));
fprintf('Dimensions of d_col: %d x %d\n\n', size(d_col, 1), size(d_col, 2));

%% 2. Vector Norms: Quantifying Size and Engineering Tolerances
% A norm measures the length or magnitude of a vector.
% Different norms correspond to different engineering physical metrics:
% - L1 Norm (Taxicab / Manhattan): sum(|v_i|). Used in L1 regularization (Lasso)
%   and robotic grid-path planning where movement is axis-aligned.
% - L2 Norm (Euclidean): sqrt(sum(v_i^2)). The true geometric length/distance.
% - L_inf Norm (Chebyshev / Maximum): max(|v_i|). Used in structural engineering
%   tolerance checks (worst-case deviation along any single coordinate axis).

fprintf('--- 2. Vector Norms ---\n');

% Position error vector of a CNC milling machine toolhead (in mm)
pos_error = [-0.042; 0.085; -0.019];

norm_L1   = norm(pos_error, 1);    % Sum of absolute errors
norm_L2   = norm(pos_error, 2);    % Euclidean distance error
norm_Linf = norm(pos_error, inf);  % Worst-case coordinate error

fprintf('CNC Toolhead Position Error (mm): [%.3f, %.3f, %.3f]^T\n', ...
    pos_error(1), pos_error(2), pos_error(3));
fprintf('  L1 Norm   (Total absolute offset):   %.4f mm\n', norm_L1);
fprintf('  L2 Norm   (True Euclidean distance):  %.4f mm\n', norm_L2);
fprintf('  L-inf Norm (Worst-case single axis):  %.4f mm\n\n', norm_Linf);

% Unit vector: direction without magnitude (scaling by 1 / norm)
u_dir = pos_error / norm_L2;
fprintf('Unit direction vector: [%.4f, %.4f, %.4f]^T (Norm = %.4f)\n\n', ...
    u_dir(1), u_dir(2), u_dir(3), norm(u_dir));

%% 3. Dot Product, Angles, and Mechanical Work
% The dot product (inner product) measures directional alignment:
%   u . v = u^T * v = ||u|| * ||v|| * cos(theta)
% Physical Meaning in Mechanics:
%   Work = F . d = ||F|| * ||d|| * cos(theta)
% - If Work > 0: Force aids motion (theta < 90 deg)
% - If Work = 0: Force is orthogonal to motion, doing NO work (theta = 90 deg)
% - If Work < 0: Force opposes motion (friction/braking, theta > 90 deg)

fprintf('--- 3. Dot Product, Angles, and Work ---\n');

% Force vector acting on an autonomous rover (Newtons)
F_rover = [250.0; 150.0; 0.0];      % Driving force
d_rover = [40.0; 30.0; 0.0];        % Displacement vector (meters)

% Algebraic dot product using matrix multiplication (row * column)
work_matrix = F_rover' * d_rover;

% Using MATLAB's built-in dot function
work_dot = dot(F_rover, d_rover);

% Calculate the angle theta between force and displacement
cos_theta = dot(F_rover, d_rover) / (norm(F_rover) * norm(d_rover));
theta_rad = acos(cos_theta);
theta_deg = rad2deg(theta_rad);

fprintf('Force vector:        [%.1f, %.1f, %.1f]^T N  (Magnitude = %.2f N)\n', ...
    F_rover(1), F_rover(2), F_rover(3), norm(F_rover));
fprintf('Displacement vector: [%.1f, %.1f, %.1f]^T m  (Magnitude = %.2f m)\n', ...
    d_rover(1), d_rover(2), d_rover(3), norm(d_rover));
fprintf('Angle between F and d: %.2f degrees (%.4f radians)\n', theta_deg, theta_rad);
fprintf('Mechanical Work done:  %.2f Joules (N*m)\n\n', work_dot);

%% 4. Orthogonal Projections and Force Decomposition
% In civil and mechanical design, vectors must be decomposed along
% natural physical axes (e.g., parallel and normal to an inclined plane).
%
% Projection formula: proj_v(u) = (u . v / ||v||^2) * v
% Orthogonal residual: u_perp = u - proj_v(u)
% Property: dot(proj_v(u), u_perp) == 0 (Strictly perpendicular!)

fprintf('--- 4. Orthogonal Projection on an Inclined Plane ---\n');

% Gravity force acting downward on a 1500 kg vehicle on a 20-degree incline
m_vehicle = 1500;                  % Mass in kg
g_accel   = 9.81;                  % Acceleration of gravity in m/s^2
F_gravity = [0.0; -m_vehicle * g_accel]; % 2D vector in [x; y], pointing down

% Incline surface direction vector (at angle alpha = 20 degrees above horizontal)
alpha_deg = 20.0;
alpha_rad = deg2rad(alpha_deg);
v_incline = [cos(alpha_rad); sin(alpha_rad)]; % Unit vector along slope surface

% Project gravity force onto the incline direction (parallel component)
F_parallel = (dot(F_gravity, v_incline) / norm(v_incline)^2) * v_incline;

% Orthogonal component (normal force pushing into the incline surface)
F_normal = F_gravity - F_parallel;

fprintf('Vehicle mass: %d kg, Slope angle: %.1f deg\n', m_vehicle, alpha_deg);
fprintf('Total gravity force: [%.2f, %.2f]^T N (Magnitude = %.2f N)\n', ...
    F_gravity(1), F_gravity(2), norm(F_gravity));
fprintf('Parallel force (sliding down slope):  [%.2f, %.2f]^T N (Mag = %.2f N)\n', ...
    F_parallel(1), F_parallel(2), norm(F_parallel));
fprintf('Normal force   (pressing into slope): [%.2f, %.2f]^T N (Mag = %.2f N)\n', ...
    F_normal(1), F_normal(2), norm(F_normal));

% Verify orthogonality: dot product should be identically zero
ortho_check = dot(F_parallel, F_normal);
fprintf('Orthogonality check dot(F_parallel, F_normal): %e (0 within machine eps)\n\n', ortho_check);

%% 5. 3D Cross Product: Torque and Rotational Moments
% The cross product produces a vector strictly orthogonal to both operands:
%   w = u x v
% Direction follows the right-hand rule; magnitude equals the area
% of the parallelogram spanned by u and v:
%   ||u x v|| = ||u|| * ||v|| * sin(theta)
%
% Physical Application: Torque (Moment of a Force)
%   tau = r x F
% where r is the moment arm vector from pivot to force application point.

fprintf('--- 5. 3D Cross Product: Mechanical Torque ---\n');

% Moment arm from robotic shoulder joint to end-effector (meters)
r_arm = [0.65; 0.40; -0.15];

% Force exerted on payload by the robotic gripper (Newtons)
F_payload = [50.0; -120.0; 200.0];

% Calculate torque vector using MATLAB cross function
tau_joint = cross(r_arm, F_payload);

% Magnitude of torque
tau_magnitude = norm(tau_joint);

fprintf('Moment arm vector r:   [%.2f, %.2f, %.2f]^T m\n', r_arm(1), r_arm(2), r_arm(3));
fprintf('Applied force vector F: [%.2f, %.2f, %.2f]^T N\n', F_payload(1), F_payload(2), F_payload(3));
fprintf('Resultant torque tau = r x F:\n');
fprintf('  tau_x (Pitch torque):  %8.2f N*m\n', tau_joint(1));
fprintf('  tau_y (Roll torque):   %8.2f N*m\n', tau_joint(2));
fprintf('  tau_z (Yaw torque):    %8.2f N*m\n', tau_joint(3));
fprintf('  Total torque magnitude: %8.2f N*m\n', tau_magnitude);

% Verify torque is orthogonal to both r and F
fprintf('Check: dot(tau, r) = %e\n', dot(tau_joint, r_arm));
fprintf('Check: dot(tau, F) = %e\n\n', dot(tau_joint, F_payload));

%% 6. Linear Independence, Basis, and Vector Spaces
% A set of vectors {v1, v2, ..., vk} is linearly independent if no vector
% can be written as a linear combination of the others:
%   c1*v1 + c2*v2 + ... + ck*vk = 0  only has the trivial solution c = 0.
%
% In engineering, basis vectors define the coordinate reference frames
% (e.g. Earth-centered inertial, aircraft body frame, sensor camera frame).

fprintf('--- 6. Linear Independence and Basis Verification ---\n');

% Define three candidate 3D spatial basis vectors
b1 = [1.0;  0.0; 2.0];
b2 = [0.0;  1.0; 1.0];
b3 = [2.0; -1.0; 3.0];

% Assemble basis candidate matrix B = [b1, b2, b3]
B = [b1, b2, b3];

% Check determinant and matrix rank
det_B  = det(B);
rank_B = rank(B);

fprintf('Basis matrix B = [b1, b2, b3]:\n');
disp(B);
fprintf('Determinant: det(B) = %.4f\n', det_B);
fprintf('Matrix Rank: rank(B) = %d (Dimension = 3)\n', rank_B);

if rank_B == 3 && abs(det_B) > 1e-12
    fprintf('Conclusion: The vectors are linearly independent and form a valid basis for R^3.\n');
else
    fprintf('Conclusion: The vectors are linearly dependent (coplanar or collinear).\n');
end

% Represent an arbitrary engineering vector p in basis B:
%   p = c1*b1 + c2*b2 + c3*b3 = B * c  ==>  c = B \ p
p_target = [5.0; 3.0; 11.0];
c_coords = B \ p_target;

fprintf('\nCoordinates of target vector p = [%.1f, %.1f, %.1f]^T in basis B:\n', ...
    p_target(1), p_target(2), p_target(3));
fprintf('  c1 = %.4f\n', c_coords(1));
fprintf('  c2 = %.4f\n', c_coords(2));
fprintf('  c3 = %.4f\n', c_coords(3));

% Reconstruct to verify
p_reconstructed = B * c_coords;
reconstruction_error = norm(p_target - p_reconstructed);
fprintf('Reconstruction error: %e\n\n', reconstruction_error);

%% 7. Graphical Visualization (Vectors & Projections)
% Create a 2D engineering diagram demonstrating force projection
figure('Name', 'Vector Operations and Projections', 'Color', 'w');

% Subplot 1: Force decomposition on an inclined plane
subplot(1, 2, 1);
hold on; grid on; axis equal;
title('Gravitational Force Decomposition on Incline');
xlabel('Horizontal axis (m)');
ylabel('Vertical axis (m)');

% Draw incline surface line
incline_x = [-2, 2];
incline_y = incline_x * tan(alpha_rad);
plot(incline_x, incline_y, 'k--', 'LineWidth', 1.5, 'DisplayName', 'Incline Surface');

% Plot vectors using quiver (scaled for visualization)
scale = 1 / 5000;
quiver(0, 0, F_gravity(1)*scale, F_gravity(2)*scale, 0, 'r', 'LineWidth', 2.5, ...
    'DisplayName', 'Gravity Force F_{grav}');
quiver(0, 0, F_parallel(1)*scale, F_parallel(2)*scale, 0, 'b', 'LineWidth', 2.0, ...
    'DisplayName', 'Parallel F_{parallel} (sliding)');
quiver(F_parallel(1)*scale, F_parallel(2)*scale, F_normal(1)*scale, F_normal(2)*scale, 0, 'm', 'LineWidth', 2.0, ...
    'DisplayName', 'Normal F_{normal} (pressure)');

legend('Location', 'best');
xlim([-2, 2]);
ylim([-3.5, 1.5]);

% Subplot 2: 3D Torque vector orthogonal to moment arm and force
subplot(1, 2, 2);
hold on; grid on; axis equal; view(45, 30);
title('3D Torque \tau = r \times F (Orthogonality)');
xlabel('X (m)'); ylabel('Y (m)'); zlabel('Z (m)');

% Plot r, F, and tau with appropriate visualization scaling
scale_F   = 0.005;
scale_tau = 0.005;

quiver3(0, 0, 0, r_arm(1), r_arm(2), r_arm(3), 0, 'b', 'LineWidth', 2, 'DisplayName', 'Moment Arm r');
quiver3(r_arm(1), r_arm(2), r_arm(3), F_payload(1)*scale_F, F_payload(2)*scale_F, F_payload(3)*scale_F, 0, ...
    'r', 'LineWidth', 2, 'DisplayName', 'Applied Force F');
quiver3(0, 0, 0, tau_joint(1)*scale_tau, tau_joint(2)*scale_tau, tau_joint(3)*scale_tau, 0, ...
    'k', 'LineWidth', 2.5, 'DisplayName', 'Torque \tau = r \times F');

legend('Location', 'best');

fprintf('=======================================================\n');
fprintf('  CONCEPT 01 COMPLETED SUCCESSFULLY\n');
fprintf('=======================================================\n');
