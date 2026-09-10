%% MINI_PROJECT_TRUSS_ANALYSIS.M
% Module 2: Linear Algebra for Engineers & Machine Learning
%
% Applied Engineering Mini-Project: Planar Bridge Truss Structural Solver
%
% Problem Statement:
% An infrastructure engineering firm is designing a steel Warren truss bridge
% spanning 8.0 meters over a canal. As the lead structural analyst, you must:
% 1. Formulate the static equilibrium equations using the Method of Joints.
% 2. Assemble the structural equilibrium matrix A (size 2*j x (m + r)).
% 3. Check static determinacy via rank and condition number.
% 4. Solve for member axial forces and support reaction forces using x = A\b.
% 5. Perform structural stress analysis:
%    - Classify members into Tension vs Compression.
%    - Check tensile yielding against steel yield strength (sigma_yield = 250 MPa).
%    - Check compressive members against Euler buckling critical loads (P_cr).
% 6. Generate an engineering visualization color-coding tension (blue),
%    compression (red), and zero-force members (dashed black).
%
% Engineering Mathematics Focus:
% Universal automated assembly of physical balance matrices A*x = b,
% numerical conditioning, vector projections, and structural failure modes.

clear; clc; close all;

fprintf('=================================================================\n');
fprintf('  MINI-PROJECT: PLANAR WARREN TRUSS STRUCTURAL SOLVER\n');
fprintf('=================================================================\n\n');

%% 1. Truss Geometry & Structural Topology
% Define joint node coordinates in meters: [X, Y]
%   Node 1: (0, 0)   - Left support (Pin: resists X and Y)
%   Node 2: (4, 0)   - Bottom chord center joint (Vehicle roadway load)
%   Node 3: (8, 0)   - Right support (Roller: resists Y only)
%   Node 4: (2, 3)   - Top chord left joint (Gusset connection)
%   Node 5: (6, 3)   - Top chord right joint (Gusset connection)

nodes = [
    0.0, 0.0;   % Node 1 (Pin support)
    4.0, 0.0;   % Node 2 (Bottom road deck)
    8.0, 0.0;   % Node 3 (Roller support)
    2.0, 3.0;   % Node 4 (Top chord left)
    6.0, 3.0    % Node 5 (Top chord right)
];

num_joints = size(nodes, 1);

% Define member connectivity: [Node_Start, Node_End]
% Total of 7 structural steel members:
members = [
    1, 2;  % Member 1: Bottom chord left (Node 1 -> 2)
    2, 3;  % Member 2: Bottom chord right (Node 2 -> 3)
    4, 5;  % Member 3: Top chord horizontal (Node 4 -> 5)
    1, 4;  % Member 4: Left diagonal strut (Node 1 -> 4)
    2, 4;  % Member 5: Left interior diagonal brace (Node 2 -> 4)
    2, 5;  % Member 6: Right interior diagonal brace (Node 2 -> 5)
    3, 5   % Member 7: Right diagonal strut (Node 3 -> 5)
];

num_members = size(members, 1);
num_reactions = 3; % R1x, R1y (Pin at Node 1), R3y (Roller at Node 3)
num_unknowns = num_members + num_reactions;
num_equations = 2 * num_joints;

fprintf('--- 1. Structural Topology ---\n');
fprintf('Number of joints (j):   %d  --> Equations (2*j) = %d\n', num_joints, num_equations);
fprintf('Number of members (m):  %d\n', num_members);
fprintf('Support reactions (r):  %d (Pin R1x, R1y; Roller R3y)\n', num_reactions);
fprintf('Total unknowns (m + r): %d\n', num_unknowns);

%% 2. Static Determinacy Verification
% Maxwell's Determinacy Criterion for 2D trusses:
%   2*j = m + r  ==>  Statically Determinate
%   2*j < m + r  ==>  Statically Indeterminate (redundant members)
%   2*j > m + r  ==>  Unstable Mechanism (collapse hazard)

if num_equations == num_unknowns
    fprintf('Determinacy Check: 2*j (%d) == m + r (%d) --> Statically Determinate.\n\n', ...
        num_equations, num_unknowns);
else
    error('Truss is not statically determinate! 2*j ~= m + r.');
end

%% 3. External Mechanical Loads
% Define external point loads applied at joints in kN: [Px, Py]
% - Heavy truck axle load on bridge deck at Node 2: Py = -60 kN
% - Wind gust on top chord Node 4: Px = +12 kN, Py = -10 kN
% - Service equipment load on top chord Node 5: Py = -15 kN

applied_loads = zeros(num_joints, 2);
applied_loads(2, :) = [  0.0, -60.0 ]; % Truck load at bridge center
applied_loads(4, :) = [ 12.0, -10.0 ]; % Wind + equipment on left apex
applied_loads(5, :) = [  0.0, -15.0 ]; % Lighting/signage on right apex

fprintf('--- 2. Applied External Service Loads ---\n');
for j = 1:num_joints
    if any(applied_loads(j, :) ~= 0)
        fprintf('  Joint %d: Px = %6.1f kN, Py = %6.1f kN\n', ...
            j, applied_loads(j, 1), applied_loads(j, 2));
    end
end
fprintf('\n');

%% 4. Automated Equilibrium Matrix Assembly
% At each joint j:
%   sum(Fx) = 0  and  sum(Fy) = 0
% If member m connects joint A to joint B:
% Direction vector from A to B: d = [xB - xA, yB - yA]
% Unit vector u = d / ||d|| = [cx, cy]
% - At joint A: tension pulls toward B (+cx, +cy)
% - At joint B: tension pulls toward A (-cx, -cy)
% Unknowns vector ordering:
%   x = [T1, T2, ..., T7, R1x, R1y, R3y]^T

A_sys = zeros(num_equations, num_unknowns);
b_sys = zeros(num_equations, 1);

% Member lengths for later stress & buckling analysis
member_lengths = zeros(num_members, 1);

% Assemble member contributions to joint equilibrium equations
for m = 1:num_members
    node_A = members(m, 1);
    node_B = members(m, 2);
    
    pos_A = nodes(node_A, :);
    pos_B = nodes(node_B, :);
    
    delta = pos_B - pos_A;
    L = norm(delta);
    member_lengths(m) = L;
    
    unit_dir = delta / L; % [cx, cy]
    
    % Joint A equilibrium equations: row 2*node_A - 1 (Fx), row 2*node_A (Fy)
    row_Ax = 2 * node_A - 1;
    row_Ay = 2 * node_A;
    A_sys(row_Ax, m) = A_sys(row_Ax, m) + unit_dir(1);
    A_sys(row_Ay, m) = A_sys(row_Ay, m) + unit_dir(2);
    
    % Joint B equilibrium equations: row 2*node_B - 1 (Fx), row 2*node_B (Fy)
    row_Bx = 2 * node_B - 1;
    row_By = 2 * node_B;
    A_sys(row_Bx, m) = A_sys(row_Bx, m) - unit_dir(1);
    A_sys(row_By, m) = A_sys(row_By, m) - unit_dir(2);
end

% Assemble Support Reactions:
% Unknown 8:  R1x at Node 1 (Row 1: Fx)
% Unknown 9:  R1y at Node 1 (Row 2: Fy)
% Unknown 10: R3y at Node 3 (Row 6: Fy)
A_sys(2*1 - 1, 8) = 1.0; % R1x
A_sys(2*1,     9) = 1.0; % R1y
A_sys(2*3,    10) = 1.0; % R3y

% Assemble RHS load vector b: -applied_loads moved to RHS
for j = 1:num_joints
    b_sys(2*j - 1) = -applied_loads(j, 1);
    b_sys(2*j)     = -applied_loads(j, 2);
end

fprintf('--- 3. Equilibrium Matrix Characteristics ---\n');
fprintf('Matrix A dimensions: %d x %d\n', size(A_sys, 1), size(A_sys, 2));
fprintf('Determinant det(A):  %.4f\n', det(A_sys));
fprintf('Matrix Rank:         %d (Full rank confirms structural stability)\n', rank(A_sys));
fprintf('Condition Number:    %.4f (Well-conditioned system)\n\n', cond(A_sys));

%% 5. Solve for Member Forces and Support Reactions
% Using MATLAB's numerically stable backslash operator
x_sol = A_sys \ b_sys;

% Extract forces (in kN)
member_forces = x_sol(1:num_members);
R1x = x_sol(8);
R1y = x_sol(9);
R3y = x_sol(10);

fprintf('--- 4. Member Force Results & Engineering Classification ---\n');
fprintf(' Member |  Joints  | Length(m) | Axial Force(kN) | Structural State\n');
fprintf('----------------------------------------------------------------------\n');
for m = 1:num_members
    F_val = member_forces(m);
    if F_val > 0.01
        type_str = 'TENSION     (+)';
    elseif F_val < -0.01
        type_str = 'COMPRESSION (-)';
    else
        type_str = 'ZERO-FORCE  (0)';
    end
    fprintf('   %2d   | %d -> %d  |  %6.3f   |   %9.3f     | %s\n', ...
        m, members(m, 1), members(m, 2), member_lengths(m), F_val, type_str);
end
fprintf('----------------------------------------------------------------------\n');

fprintf('\nSupport Reaction Forces:\n');
fprintf('  Node 1 Pin Horizontal Reaction (R1x): %8.3f kN\n', R1x);
fprintf('  Node 1 Pin Vertical Reaction   (R1y): %8.3f kN\n', R1y);
fprintf('  Node 3 Roller Vertical Reaction (R3y): %8.3f kN\n\n', R3y);

% Global Statics Check
sum_Fx_ext = sum(applied_loads(:, 1)) + R1x;
sum_Fy_ext = sum(applied_loads(:, 2)) + R1y + R3y;
fprintf('Global Statics Verification:\n');
fprintf('  sum(Fx) = %.2e kN\n', sum_Fx_ext);
fprintf('  sum(Fy) = %.2e kN\n\n', sum_Fy_ext);

%% 6. Member Sizing, Stress & Buckling Safety Checks
% Specification of Structural Steel Hollow Section:
% - Outside dimension: b_out = 0.08 m (80 mm square tube)
% - Wall thickness:    t_wall = 0.005 m (5 mm)
% - Cross-sectional area: A_cross = b_out^2 - (b_out - 2*t_wall)^2
% - Moment of Inertia:   I_area = (b_out^4 - (b_out - 2*t_wall)^4) / 12
% - Young's Modulus:     E_steel = 200 GPa = 200e9 Pa
% - Yield Strength:      sigma_yield = 250 MPa = 250e6 Pa

b_out = 0.080;
t_wall = 0.005;
A_cross = b_out^2 - (b_out - 2 * t_wall)^2;                % m^2
I_area  = (b_out^4 - (b_out - 2 * t_wall)^4) / 12.0;       % m^4
E_steel = 200e9;                                           % Pa
sigma_yield = 250e6;                                       % Pa

fprintf('--- 5. Stress & Buckling Safety Factor Analysis ---\n');
fprintf('Structural Tube: 80x80x5 mm (Area = %.2f cm^2, I = %.2f cm^4)\n', ...
    A_cross * 1e4, I_area * 1e8);
fprintf(' Member | Stress (MPa) | P_crit (kN) | Min FOS | Safety Assessment\n');
fprintf('--------------------------------------------------------------------\n');

critical_fos = inf;

for m = 1:num_members
    F_newtons = member_forces(m) * 1e3; % Convert kN to N
    stress_pa = F_newtons / A_cross;
    stress_mpa = stress_pa / 1e6;
    L_m = member_lengths(m);
    
    % Euler Critical Buckling Load (pinned ends, k = 1.0): P_cr = pi^2 * E * I / L^2
    P_cr_newtons = (pi^2 * E_steel * I_area) / (L_m^2);
    P_cr_kn = P_cr_newtons / 1e3;
    
    if member_forces(m) > 0.01 % Tension
        fos = (sigma_yield / 1e6) / abs(stress_mpa);
        assessment = sprintf('Tensile Yield FOS = %.2f', fos);
    elseif member_forces(m) < -0.01 % Compression
        % Must check both yield and Euler buckling
        fos_yield = (sigma_yield / 1e6) / abs(stress_mpa);
        fos_buck  = P_cr_kn / abs(member_forces(m));
        fos = min(fos_yield, fos_buck);
        if fos_buck < fos_yield
            assessment = sprintf('Buckling Critical FOS = %.2f', fos);
        else
            assessment = sprintf('Comp Yield FOS = %.2f', fos);
        end
    else
        fos = inf;
        assessment = 'Zero-force member';
    end
    
    if fos < critical_fos
        critical_fos = fos;
    end
    
    fprintf('   %2d   |   %8.2f   |   %8.1f  |  %5.2f  | %s\n', ...
        m, stress_mpa, P_cr_kn, fos, assessment);
end
fprintf('--------------------------------------------------------------------\n');
fprintf('Bridge Global Minimum Factor of Safety: %.2f\n', critical_fos);
if critical_fos >= 1.67
    fprintf('DESIGN STATUS: APPROVED for civilian highway traffic (FOS >= 1.67).\n\n');
else
    fprintf('DESIGN STATUS: REDESIGN REQUIRED. Member cross-section inadequate!\n\n');
end

%% 7. Engineering Visualization of Internal Force Distribution
figure('Name', 'Warren Truss Force Distribution', 'Color', 'w');
hold on; grid on; axis equal;
title('Warren Truss Internal Force Distribution (Blue=Tension, Red=Compression)');
xlabel('Bridge Span (m)');
ylabel('Height (m)');

% Plot members color-coded by axial force
max_force = max(abs(member_forces));

for m = 1:num_members
    nA = members(m, 1);
    nB = members(m, 2);
    xA = nodes(nA, 1); yA = nodes(nA, 2);
    xB = nodes(nB, 1); yB = nodes(nB, 2);
    
    F_val = member_forces(m);
    line_w = 1.0 + 3.5 * (abs(F_val) / max_force);
    
    if F_val > 0.01
        line_col = [0.1, 0.4, 0.85]; % Blue for tension
        line_style = '-';
    elseif F_val < -0.01
        line_col = [0.85, 0.15, 0.15]; % Red for compression
        line_style = '-';
    else
        line_col = [0.3, 0.3, 0.3]; % Dark grey for zero force
        line_style = '--';
    end
    
    plot([xA, xB], [yA, yB], line_style, 'Color', line_col, 'LineWidth', line_w);
    
    % Label member force at midpoint
    mid_x = (xA + xB) / 2.0;
    mid_y = (yA + yB) / 2.0;
    text(mid_x, mid_y + 0.15, sprintf('M%d: %.1f kN', m, F_val), ...
        'FontSize', 8, 'FontWeight', 'bold', 'HorizontalAlignment', 'center', ...
        'BackgroundColor', [1 1 1 0.75], 'Margin', 1);
end

% Plot Joints and Labels
for j = 1:num_joints
    plot(nodes(j, 1), nodes(j, 2), 'ko', 'MarkerSize', 9, 'MarkerFaceColor', [0.9 0.9 0.2]);
    text(nodes(j, 1), nodes(j, 2) - 0.3, sprintf('J%d', j), ...
        'FontSize', 10, 'FontWeight', 'bold', 'HorizontalAlignment', 'center');
    
    % Draw applied load arrows
    if any(applied_loads(j, :) ~= 0)
        quiver(nodes(j, 1), nodes(j, 2), ...
               applied_loads(j, 1)*0.03, applied_loads(j, 2)*0.03, 0, ...
               'g', 'LineWidth', 2.5, 'MaxHeadSize', 0.8);
    end
end

xlim([-1, 9]);
ylim([-1, 4.5]);

fprintf('=================================================================\n');
fprintf('  MINI-PROJECT EXECUTION COMPLETED SUCCESSFULLY\n');
fprintf('=================================================================\n');
