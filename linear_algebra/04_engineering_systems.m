%% 04_ENGINEERING_SYSTEMS.M
% Module 2: Linear Algebra for Engineers & Machine Learning
%
% This script demonstrates how fundamental physical conservation laws
% across disparate engineering disciplines map to the universal linear system:
%                              A * x = b
%
% We model two benchmark physical engineering systems:
%   Part 1: Multi-node Electrical Resistive Circuit (Kirchhoff's Current Law)
%   Part 2: Pin-Jointed Planar Structural Truss (Method of Joints Equilibrium)
%
% Educational Objective: Formulate real physical balance equations into
% rigorous matrix systems, solve with MATLAB backslash, and perform
% engineering verification (energy conservation and static equilibrium checks).

clear; clc; close all;

fprintf('=======================================================\n');
fprintf('  MODULE 2: CONCEPT 04 - PHYSICAL ENGINEERING SYSTEMS\n');
fprintf('=======================================================\n\n');

%% =====================================================================
%% PART 1: ELECTRICAL CIRCUIT NODAL ANALYSIS (KCL)
%% =====================================================================
% System Description:
% A 4-node DC circuit with Ground (Node 0 = 0V) and 3 active nodes (V1, V2, V3).
%
% Circuit Components:
% - Current Source Is = 3.0 A injected into Node 1
% - Resistor R1 = 5 Ohm between Node 1 and Node 2
% - Resistor R2 = 10 Ohm between Node 1 and Node 3
% - Resistor R3 = 8 Ohm between Node 2 and Ground (Node 0)
% - Resistor R4 = 4 Ohm between Node 3 and Ground (Node 0)
% - Resistor R5 = 20 Ohm between Node 2 and Node 3 (Bridge resistor)

fprintf('-------------------------------------------------------\n');
fprintf('PART 1: ELECTRICAL CIRCUIT NODAL ANALYSIS\n');
fprintf('-------------------------------------------------------\n');

% Component values
R_vals = [5.0, 10.0, 8.0, 4.0, 20.0]; % Ohms
G = 1 ./ R_vals;                      % Conductances (Siemens = 1/Ohm)
I_source = 3.0;                       % Amperes

% Kirchhoff's Current Law at each node: Sum of leaving currents = Injected current
% Node 1:  G1*(V1 - V2) + G2*(V1 - V3) = Is
%          (G1 + G2)*V1 - G1*V2 - G2*V3 = Is
% Node 2:  G1*(V2 - V1) + G3*(V2 - 0) + G5*(V2 - V3) = 0
%          -G1*V1 + (G1 + G3 + G5)*V2 - G5*V3 = 0
% Node 3:  G2*(V3 - V1) + G4*(V3 - 0) + G5*(V3 - V2) = 0
%          -G2*V1 - G5*V2 + (G2 + G4 + G5)*V3 = 0

% Assemble Conductance Matrix G_sys (Symmetric Positive-Definite)
G_sys = [  G(1) + G(2),        -G(1),                 -G(2);
          -G(1),         G(1) + G(3) + G(5),          -G(5);
          -G(2),               -G(5),          G(2) + G(4) + G(5) ];

% Injected current vector
i_sys = [I_source; 0.0; 0.0];

fprintf('Assembled Conductance Matrix G (Siemens):\n');
disp(G_sys);
fprintf('Condition number cond(G): %.4f (Extremely well-conditioned)\n', cond(G_sys));

% Solve for unknown node voltages using backslash
v_nodes = G_sys \ i_sys;

fprintf('Calculated Node Voltages:\n');
fprintf('  V1 = %8.4f V\n', v_nodes(1));
fprintf('  V2 = %8.4f V\n', v_nodes(2));
fprintf('  V3 = %8.4f V\n\n', v_nodes(3));

% Post-Processing: Branch Currents and Power Dissipation
I_R1 = (v_nodes(1) - v_nodes(2)) * G(1);
I_R2 = (v_nodes(1) - v_nodes(3)) * G(2);
I_R3 = (v_nodes(2) - 0.0)        * G(3);
I_R4 = (v_nodes(3) - 0.0)        * G(4);
I_R5 = (v_nodes(2) - v_nodes(3)) * G(5);

% Power dissipated in each resistor: P = I^2 * R
P_dissipated = [I_R1^2 * R_vals(1);
                I_R2^2 * R_vals(2);
                I_R3^2 * R_vals(3);
                I_R4^2 * R_vals(4);
                I_R5^2 * R_vals(5)];

% Power supplied by source: P_source = Is * V1
P_total_supplied = I_source * v_nodes(1);
P_total_consumed = sum(P_dissipated);

fprintf('Branch Currents:\n');
fprintf('  I_R1 (Node 1 -> 2): %8.4f A\n', I_R1);
fprintf('  I_R2 (Node 1 -> 3): %8.4f A\n', I_R2);
fprintf('  I_R3 (Node 2 -> 0): %8.4f A\n', I_R3);
fprintf('  I_R4 (Node 3 -> 0): %8.4f A\n', I_R4);
fprintf('  I_R5 (Node 2 -> 3): %8.4f A\n\n', I_R5);

fprintf('Energy Conservation Verification:\n');
fprintf('  Total Power Supplied by Source:   %8.4f W\n', P_total_supplied);
fprintf('  Total Power Dissipated in R1-R5:  %8.4f W\n', P_total_consumed);
fprintf('  Power Balance Discrepancy:        %e W\n\n', abs(P_total_supplied - P_total_consumed));

%% =====================================================================
%% PART 2: PIN-JOINTED PLANAR TRUSS EQUILIBRIUM
%% =====================================================================
% System Description:
% A triangular 3-bar planar truss spanning L = 4 meters:
% - Joint 1: Pin support at (0, 0) m  --> 2 reaction forces (R1x, R1y)
% - Joint 2: Roller support at (4, 0) m --> 1 reaction force (R2y)
% - Joint 3: Apex joint at (2, 2*sqrt(3)) m (Equilateral 60-degree triangle)
%
% Members:
% - Member 1: Joint 1 -> Joint 2 (Horizontal base, length 4m, angle = 0 deg)
% - Member 2: Joint 1 -> Joint 3 (Left diagonal, length 4m, angle = 60 deg)
% - Member 3: Joint 2 -> Joint 3 (Right diagonal, length 4m, angle = 120 deg)
%
% External Load applied at Apex (Joint 3):
%   Px = +15.0 kN (horizontal wind/thrust), Py = -30.0 kN (downward gravity load)
%
% Equilibrium Formulation (Method of Joints):
% At each joint j: sum(Fx) = 0 and sum(Fy) = 0
% Unknowns vector x = [T1; T2; T3; R1x; R1y; R2y] (6 unknowns, 6 equations)

fprintf('-------------------------------------------------------\n');
fprintf('PART 2: PIN-JOINTED PLANAR TRUSS FORCE BALANCE\n');
fprintf('-------------------------------------------------------\n');

% Geometry angles in degrees
theta1 = 0.0;    % Member 1 (horizontal from J1 to J2)
theta2 = 60.0;   % Member 2 (from J1 to J3)
theta3 = 120.0;  % Member 3 (from J2 to J3)

% Applied loads at Joint 3 (in kN)
Px = 15.0;
Py = -30.0;

% Equations at Joint 1 (x=0, y=0):
% sum(Fx) = T1*cos(0) + T2*cos(60) + R1x = 0
% sum(Fy) = T1*sin(0) + T2*sin(60) + R1y = 0

% Equations at Joint 2 (x=4, y=0):
% sum(Fx) = -T1*cos(0) + T3*cos(120 - 180) ... careful with direction:
% Force pulling away from Joint 2 toward Joint 1: -T1
% Force pulling away from Joint 2 toward Joint 3: T3 * cos(120 deg) = -T3 * cos(60)
% sum(Fx) = -T1 + T3 * cosd(120) = 0
% sum(Fy) = T3 * sind(120) + R2y = 0

% Equations at Joint 3 (Apex, x=2, y=3.464):
% Forces pulling away from Joint 3 toward Joint 1 and 2:
% From J3 to J1: -T2 * cosd(60) in x, -T2 * sind(60) in y
% From J3 to J2: -T3 * cosd(120) = +T3*cosd(60) in x, -T3 * sind(120) in y
% sum(Fx) = -T2*cosd(60) - T3*cosd(120) = -Px
% sum(Fy) = -T2*sind(60) - T3*sind(120) = -Py

% Matrix columns correspond to: [T1, T2, T3, R1x, R1y, R2y]
A_truss = [
    % J1: Fx, Fy
    cosd(0),   cosd(60),        0,         1, 0, 0;
    sind(0),   sind(60),        0,         0, 1, 0;
    % J2: Fx, Fy
    -cosd(0),     0,         cosd(120),    0, 0, 0;
        0,        0,         sind(120),    0, 0, 1;
    % J3: Fx, Fy
        0,    -cosd(60),    -cosd(120),    0, 0, 0;
        0,    -sind(60),    -sind(120),    0, 0, 0
];

% Load vector b_truss (negative of external loads moved to RHS)
b_truss = [0; 0; 0; 0; -Px; -Py];

fprintf('Truss Equilibrium Matrix A (6x6):\n');
disp(A_truss);
fprintf('Determinant det(A): %.4f\n', det(A_truss));
fprintf('Matrix Rank: %d (Full rank = statically determinate)\n\n', rank(A_truss));

% Solve for member forces and reactions
sol_truss = A_truss \ b_truss;

T1  = sol_truss(1);
T2  = sol_truss(2);
T3  = sol_truss(3);
R1x = sol_truss(4);
R1y = sol_truss(5);
R2y = sol_truss(6);

fprintf('Solved Internal Member Forces:\n');
fprintf('  Member 1 (Base chord):   %8.2f kN  [%s]\n', T1, get_stress_state(T1));
fprintf('  Member 2 (Left diagonal):%8.2f kN  [%s]\n', T2, get_stress_state(T2));
fprintf('  Member 3 (Right diag):   %8.2f kN  [%s]\n\n', T3, get_stress_state(T3));

fprintf('Solved Support Reaction Forces:\n');
fprintf('  R1x (Pin horizontal reaction):  %8.2f kN\n', R1x);
fprintf('  R1y (Pin vertical reaction):    %8.2f kN\n', R1y);
fprintf('  R2y (Roller vertical reaction): %8.2f kN\n\n', R2y);

% Global Statics Equilibrium Verification
sum_Fx_global = R1x + Px;
sum_Fy_global = R1y + R2y + Py;
% Moment about Joint 1 (anticlockwise positive): R2y * 4 + Py * 2 - Px * (2*sqrt(3))
y3 = 2 * sqrt(3);
sum_M1_global = R2y * 4.0 + Py * 2.0 - Px * y3;

fprintf('Global Equilibrium Verification:\n');
fprintf('  sum(Fx) = R1x + Px = %.2e kN\n', sum_Fx_global);
fprintf('  sum(Fy) = R1y + R2y + Py = %.2e kN\n', sum_Fy_global);
fprintf('  sum(M_J1) = %.2e kN*m\n', sum_M1_global);

if max(abs([sum_Fx_global, sum_Fy_global, sum_M1_global])) < 1e-10
    fprintf('Result: Global static equilibrium strictly satisfied!\n\n');
end

%% Helper Function for Engineering Classification
function state_str = get_stress_state(force_val)
    if force_val > 1e-4
        state_str = 'TENSION (Tensile Yield Risk)';
    elseif force_val < -1e-4
        state_str = 'COMPRESSION (Buckling Hazard)';
    else
        state_str = 'ZERO-FORCE MEMBER';
    end
end

fprintf('=======================================================\n');
fprintf('  CONCEPT 04 COMPLETED SUCCESSFULLY\n');
fprintf('=======================================================\n');
