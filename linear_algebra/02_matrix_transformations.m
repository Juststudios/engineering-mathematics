%% 02_MATRIX_TRANSFORMATIONS.M
% Module 2: Linear Algebra for Engineers & Machine Learning
%
% This script explores matrices as geometric transformations of space:
% - 2D linear transformations: Rotation, Scaling, and Shearing
% - The Determinant: Geometric interpretation as area scaling factor
% - Orientation preservation vs reflection (sign of determinant)
% - Non-commutativity of composite transformations (order matters: R*S ~= S*R)
% - 3D Rotations (Euler angles: Yaw, Pitch, Roll) and SO(3) properties
% - Homogeneous coordinates (SE(3)) for robotic coordinate frame transformations
%
% Educational Objective: Understand how matrices act as dynamic spatial operators
% that warp, rotate, and reposition coordinate systems in robotics, CAD, and graphics.

clear; clc; close all;

fprintf('=======================================================\n');
fprintf('  MODULE 2: CONCEPT 02 - MATRIX TRANSFORMATIONS\n');
fprintf('=======================================================\n\n');

%% 1. 2D Geometric Transformations: Shape Definition
% Define a unit square object with vertices in 2D space.
% Vertices are arranged as columns in a 2xN matrix:
%   Column 1: (0,0), Column 2: (1,0), Column 3: (1,1), Column 4: (0,1), Column 5: (0,0) (closing loop)

V_square = [0, 1, 1, 0, 0;   % X coordinates
            0, 0, 1, 1, 0];  % Y coordinates

fprintf('--- 1. 2D Linear Transformations ---\n');
fprintf('Original unit square area: 1.0000\n');

%% 2. Rotation Matrix R(theta)
% A rotation matrix in 2D turns vectors counterclockwise by angle theta:
%   R(theta) = [cos(theta), -sin(theta);
%               sin(theta),  cos(theta)]
% Key properties:
% - det(R) = cos^2(theta) + sin^2(theta) = 1.0 (Rigid transformation: area preserved)
% - R' * R = I (Orthogonal matrix: preserves lengths and angles)

theta_deg = 45.0;
theta_rad = deg2rad(theta_deg);

R = [cos(theta_rad), -sin(theta_rad);
     sin(theta_rad),  cos(theta_rad)];

V_rotated = R * V_square;

fprintf('Rotation matrix R (theta = %.1f deg):\n', theta_deg);
disp(R);
fprintf('det(R) = %.4f (Pure rotation: area scaling factor = 1)\n\n', det(R));

%% 3. Scaling Matrix S(sx, sy)
% Non-uniform scaling stretches or squashes coordinates along principal axes:
%   S = [sx,  0;
%        0,  sy]
% Determinant: det(S) = sx * sy (The area of any shape is multiplied by sx*sy)

sx = 2.0;
sy = 0.5;
S = [sx,  0;
     0,  sy];

V_scaled = S * V_square;

fprintf('Scaling matrix S (sx = %.1f, sy = %.1f):\n', sx, sy);
disp(S);
fprintf('det(S) = %.4f (New area = original_area * det(S) = %.4f)\n\n', det(S), det(S) * 1.0);

%% 4. Shear Matrix H(kx, ky)
% Shearing slides parallel layers of an object without changing height:
%   Hx = [1, kx;   (horizontal shear)
%         0,  1]
% Determinant: det(Hx) = 1 * 1 - 0 = 1.0 (Area is strictly preserved, Cavalieri's principle!)

kx = 0.8;
H = [1.0, kx;
     0.0, 1.0];

V_sheared = H * V_square;

fprintf('Shear matrix H (kx = %.1f):\n', kx);
disp(H);
fprintf('det(H) = %.4f (Area is conserved during pure shear)\n\n', det(H));

%% 5. Singular Matrix: Dimensional Collapse
% When det(A) = 0, the matrix collapses 2D space onto a 1D line.
% Information is destroyed, meaning the transformation cannot be inverted.

A_singular = [1, 2;
              2, 4]; % Row 2 is 2 * Row 1 (linearly dependent)

V_collapsed = A_singular * V_square;

fprintf('Singular transformation matrix A_singular:\n');
disp(A_singular);
fprintf('det(A_singular) = %.4f (Determinant is 0: collapses 2D area to 0)\n', det(A_singular));
fprintf('Rank of A_singular = %d (Space dimension collapsed from 2 to 1)\n\n', rank(A_singular));

%% 6. Non-Commutativity of Composite Transformations
% In linear algebra, matrix multiplication is NOT commutative:
%   A * B ~= B * A
% In robotics and graphics, applying Rotation then Scaling gives a completely
% different result than applying Scaling then Rotation!

T_rot_then_scale = S * R; % Rotate first, then scale
T_scale_then_rot = R * S; % Scale first, then rotate

diff_norm = norm(T_rot_then_scale - T_scale_then_rot, 'fro');

fprintf('--- 2. Composite Transformations and Non-Commutativity ---\n');
fprintf('Matrix T1 (Rotate then Scale):\n');
disp(T_rot_then_scale);
fprintf('Matrix T2 (Scale then Rotate):\n');
disp(T_scale_then_rot);
fprintf('Frobenius norm of (T1 - T2): %.4f\n', diff_norm);
if diff_norm > 1e-6
    fprintf('Result: T1 ~= T2. Matrix transformations do NOT commute in general!\n\n');
end

%% 7. 3D Rotations and Euler Angles (Aerospace & Robotics)
% 3D rotations occur around the X (Roll), Y (Pitch), and Z (Yaw) axes:
%   Rx(phi):   Roll around X
%   Ry(theta): Pitch around Y
%   Rz(psi):   Yaw around Z
% The total rotation matrix for Yaw-Pitch-Roll (Z-Y-X convention):
%   R_total = Rz(psi) * Ry(theta) * Rx(phi)

fprintf('--- 3. 3D Rotations (Yaw, Pitch, Roll) ---\n');

% Angles in degrees
yaw_psi_deg   = 30.0;
pitch_th_deg  = 15.0;
roll_phi_deg  = -10.0;

psi = deg2rad(yaw_psi_deg);
th  = deg2rad(pitch_th_deg);
phi = deg2rad(roll_phi_deg);

% Rotation around Z axis (Yaw)
R_z = [ cos(psi), -sin(psi),  0;
        sin(psi),  cos(psi),  0;
        0,         0,         1];

% Rotation around Y axis (Pitch)
R_y = [ cos(th),   0,         sin(th);
        0,         1,         0;
       -sin(th),   0,         cos(th)];

% Rotation around X axis (Roll)
R_x = [ 1,         0,         0;
        0,         cos(phi), -sin(phi);
        0,         sin(phi),  cos(phi)];

% Composite Direction Cosine Matrix (DCM)
R_3D = R_z * R_y * R_x;

fprintf('3D Rotation Matrix R_total = Rz(30) * Ry(15) * Rx(-10):\n');
disp(R_3D);

% Verify Special Orthogonal Group SO(3) properties:
% 1. det(R) = +1 (preserves volume and handedness, no reflection)
% 2. R' * R = I (preserves vector lengths: ||R*v|| = ||v||)
ortho_error = norm(R_3D' * R_3D - eye(3), 'fro');
fprintf('Properties of SO(3) Rotation Matrix:\n');
fprintf('  det(R_3D) = %.6f (+1 confirms proper rigid rotation)\n', det(R_3D));
fprintf('  Orthogonality error ||R^T * R - I||: %e\n\n', ortho_error);

%% 8. Homogeneous Transformation Matrices (SE(3) in Robotics)
% A rigid body transformation involves both Rotation R (3x3) and Translation p (3x1).
% We unify both in a 4x4 Homogeneous Transformation Matrix:
%   T = [ R,    p ;
%         000,  1 ]
%
% This allows chaining coordinate frame transformations by simple matrix multiplication:
%   p_world = T_world_robot * T_robot_camera * p_camera

fprintf('--- 4. Homogeneous Coordinates & Coordinate Frame Transformation ---\n');

% Position of robotic base in World frame (meters)
p_base_in_world = [1.5; 2.0; 0.0];
R_base_in_world = eye(3); % Aligned with world axes

T_world_base = [R_base_in_world,   p_base_in_world;
                0, 0, 0,           1];

% Position and orientation of end-effector relative to robotic base
p_tool_in_base = [0.8; 0.2; 0.5];
% End-effector has rotated by 45 degrees around Z axis relative to base
T_base_tool = [cosd(45), -sind(45), 0,  p_tool_in_base(1);
               sind(45),  cosd(45), 0,  p_tool_in_base(2);
               0,         0,        1,  p_tool_in_base(3);
               0,         0,        0,  1];

% Compute end-effector pose in World frame by matrix multiplication:
T_world_tool = T_world_base * T_base_tool;

% Target point on workpiece measured in tool coordinates: p_tool = [0.1; 0; 0.05; 1]
p_target_tool = [0.1; 0.0; 0.05; 1.0]; % Homogeneous vector [x; y; z; 1]

% Transform point to World coordinates
p_target_world = T_world_tool * p_target_tool;

fprintf('Workpiece point in tool frame:  [%.2f, %.2f, %.2f]^T m\n', ...
    p_target_tool(1), p_target_tool(2), p_target_tool(3));
fprintf('Workpiece point in world frame: [%.2f, %.2f, %.2f]^T m\n\n', ...
    p_target_world(1), p_target_world(2), p_target_world(3));

%% 9. Graphical Visualization of 2D Transformations
figure('Name', '2D Matrix Transformations', 'Color', 'w');

subplot(2, 2, 1);
plot(V_square(1,:), V_square(2,:), 'k-o', 'LineWidth', 2, 'MarkerFaceColor', 'k');
hold on; grid on; axis equal; xlim([-2, 3]); ylim([-2, 3]);
title('Original Unit Square (Area = 1.0)');
xlabel('X'); ylabel('Y');

subplot(2, 2, 2);
plot(V_square(1,:), V_square(2,:), 'k--', 'LineWidth', 1); hold on;
plot(V_rotated(1,:), V_rotated(2,:), 'b-s', 'LineWidth', 2, 'MarkerFaceColor', 'b');
grid on; axis equal; xlim([-2, 3]); ylim([-2, 3]);
title(sprintf('Rotation (45^\\circ) [det = %.2f]', det(R)));
xlabel('X'); ylabel('Y'); legend('Original', 'Rotated');

subplot(2, 2, 3);
plot(V_square(1,:), V_square(2,:), 'k--', 'LineWidth', 1); hold on;
plot(V_scaled(1,:), V_scaled(2,:), 'r-d', 'LineWidth', 2, 'MarkerFaceColor', 'r');
grid on; axis equal; xlim([-2, 3]); ylim([-2, 3]);
title(sprintf('Scaling (sx=2.0, sy=0.5) [det = %.2f]', det(S)));
xlabel('X'); ylabel('Y'); legend('Original', 'Scaled');

subplot(2, 2, 4);
plot(V_square(1,:), V_square(2,:), 'k--', 'LineWidth', 1); hold on;
plot(V_sheared(1,:), V_sheared(2,:), 'm-^', 'LineWidth', 2, 'MarkerFaceColor', 'm');
grid on; axis equal; xlim([-2, 3]); ylim([-2, 3]);
title(sprintf('Shear (kx=0.8) [det = %.2f]', det(H)));
xlabel('X'); ylabel('Y'); legend('Original', 'Sheared');

fprintf('=======================================================\n');
fprintf('  CONCEPT 02 COMPLETED SUCCESSFULLY\n');
fprintf('=======================================================\n');
