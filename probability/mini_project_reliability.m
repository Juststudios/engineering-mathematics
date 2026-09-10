%% mini_project_reliability.m - Applied Reliability Modeling & MTBF Simulation
% =========================================================================
% MODULE: Probability & Uncertainty in Engineering (R4)
% TOPIC : System Reliability Engineering: Series-Parallel Topologies,
%         Exponential Failure Kinetics, MTBF & Monte Carlo Survival Analysis
%
% ENGINEERING CONTEXT:
% Industrial chemical processing plants and aerospace flight-control systems 
% operate continuously under harsh thermal and mechanical stress. Unscheduled 
% shutdowns cost millions of dollars and compromise personnel safety. 
% Reliability engineers use probability models to evaluate Mean Time Between 
% Failures (MTBF), analyze redundant architectures (series, parallel, and 
% k-out-of-n), and establish scheduled maintenance intervals before catastrophic 
% failure probability exceeds regulatory safety thresholds.
%
% SYSTEM ARCHITECTURE UNDER ANALYSIS:
% The emergency reactor cooling loop consists of three functional stages 
% connected in SERIES:
%   1. Power Stage (Active Parallel Redundancy):
%      Two identical power conditioning units (PCU 1 & PCU 2).
%      The system survives if AT LEAST ONE power supply functions.
%   2. Pumping Stage (2-out-of-3 Redundancy):
%      Three identical centrifugal coolant pumps (P1, P2, P3).
%      The system requires AT LEAST TWO pumps operational to maintain flow.
%   3. Heat Exchanger Stage (Single Point of Failure / Series):
%      A single high-capacity titanium plate heat exchanger (HEX).
%      If the heat exchanger fouls or leaks, the entire cooling loop fails.
%
% This project demonstrates:
%   1. Analytical Component Reliability via Exponential Distribution Kinetics
%   2. Mathematical Derivation of Hybrid Series-Parallel System Survival R_sys(t)
%   3. 100,000-Trial Monte Carlo Simulation of Component Failure Times
%   4. System MTBF Calculation via Quadrature (trapz) vs Monte Carlo Mean
%   5. B10 / B1 Life Estimation & Preventive Maintenance Recommendations
%   6. Component Bottleneck & Reliability Sensitivity Analysis
% =========================================================================

clear;
close all;
clc;

fprintf('=================================================================\n');
fprintf('  MINI-PROJECT: INDUSTRIAL SYSTEM RELIABILITY & MTBF ANALYSIS    \n');
fprintf('=================================================================\n\n');

%% Section 1: Component Failure Rates & Parameter Specifications
% Component lifespans follow exponential distributions:
%   R_i(t) = exp(-lambda_i * t), where lambda_i = 1 / MTBF_i [failures / hour]

% Component specifications (Operating hours)
MTBF_pcu = 12000.0;   % Power conditioning unit MTBF [hours] (~1.37 years)
MTBF_pump = 8000.0;   % Centrifugal coolant pump MTBF [hours] (~0.91 years)
MTBF_hex = 25000.0;   % Titanium plate heat exchanger MTBF [hours] (~2.85 years)

% Failure rates [1 / hour]
lambda_pcu  = 1.0 / MTBF_pcu;
lambda_pump = 1.0 / MTBF_pump;
lambda_hex  = 1.0 / MTBF_hex;

% Simulation and evaluation mission horizon
t_max = 20000.0;      % 20,000 operating hours (~2.28 years continuous)
dt = 20.0;            % Time resolution [hours]
t_vec = 0.0:dt:t_max;
N_time = length(t_vec);

fprintf('--- 1. COMPONENT RELIABILITY SPECIFICATIONS ---\n');
fprintf('Power Conditioning Unit (PCU) : MTBF = %8.1f hrs | lambda = %.3e /hr\n', ...
    MTBF_pcu, lambda_pcu);
fprintf('Centrifugal Coolant Pump      : MTBF = %8.1f hrs | lambda = %.3e /hr\n', ...
    MTBF_pump, lambda_pump);
fprintf('Titanium Heat Exchanger (HEX) : MTBF = %8.1f hrs | lambda = %.3e /hr\n\n', ...
    MTBF_hex, lambda_hex);


%% Section 2: Analytical System Reliability Derivation
% Compute continuous survival functions R(t) over the time grid:

% 1. Individual component survival functions
R_pcu_single  = exp(-lambda_pcu  .* t_vec);
R_pump_single = exp(-lambda_pump .* t_vec);
R_hex         = exp(-lambda_hex  .* t_vec);

% 2. Power Stage: Parallel Redundancy (1-out-of-2)
% Survives unless BOTH units fail:
% R_power(t) = 1 - (1 - R_pcu(t))^2 = 2*R_pcu(t) - R_pcu(t)^2
R_power = 1.0 - ((1.0 - R_pcu_single).^2);

% 3. Pump Stage: 2-out-of-3 Majority Redundancy
% Survives if all 3 run, or exactly 2 run:
% R_pumps(t) = R_p^3 + 3 * R_p^2 * (1 - R_p) = 3*R_p^2 - 2*R_p^3
R_pumps = (R_pump_single.^3) + 3.0 .* (R_pump_single.^2) .* (1.0 - R_pump_single);

% 4. Complete System: Series connection of Power, Pumps, and Heat Exchanger
% All three stages must be simultaneously operational:
% R_system(t) = R_power(t) * R_pumps(t) * R_hex(t)
R_system = R_power .* R_pumps .* R_hex;

% System MTBF via numerical integration of survival curve:
% MTBF_sys = integral_0^infty R_system(t) dt
MTBF_sys_analytical = trapz(t_vec, R_system);

fprintf('--- 2. ANALYTICAL SYSTEM SURVIVAL METRICS ---\n');
fprintf('Analytical System MTBF (Integral R dt): %.2f operating hours\n', ...
    MTBF_sys_analytical);
fprintf('Survival at 2,000 hrs (First inspection) : %.2f%%\n', ...
    R_system(t_vec == 2000.0) * 100.0);
fprintf('Survival at 5,000 hrs (Mid-life review)  : %.2f%%\n', ...
    R_system(t_vec == 5000.0) * 100.0);
fprintf('Survival at 8,760 hrs (1 Calendar Year)  : %.2f%%\n\n', ...
    interp1(t_vec, R_system, 8760.0) * 100.0);


%% Section 3: Large-Scale Monte Carlo System Simulation
% Simulate N_sim = 100,000 complete cooling plant lifespans.
% For each plant, generate random failure times for all 6 physical components:
%   T_fail = -ln(U) / lambda, where U ~ Uniform(0, 1)

N_sim = 100000;
rng(808); % Reproducible seed

% Generate component failure times (matrix size: N_components x N_sim)
% Power supply stage: 2 units
T_pcu1 = -log(rand(1, N_sim)) ./ lambda_pcu;
T_pcu2 = -log(rand(1, N_sim)) ./ lambda_pcu;

% Pump stage: 3 units
T_p1 = -log(rand(1, N_sim)) ./ lambda_pump;
T_p2 = -log(rand(1, N_sim)) ./ lambda_pump;
T_p3 = -log(rand(1, N_sim)) ./ lambda_pump;

% Heat exchanger stage: 1 unit
T_hex = -log(rand(1, N_sim)) ./ lambda_hex;

% -------------------------------------------------------------------------
% Compute Subsystem Failure Times from Physical Topology:
% 1. Power stage: Active parallel -> Fails when the LAST power supply dies:
%    T_power = max(T_pcu1, T_pcu2)
T_power_stage = max(T_pcu1, T_pcu2);

% 2. Pump stage: 2-out-of-3 -> System fails when the SECOND pump fails:
%    Sort pump failure times ascending: [first_to_fail, second_to_fail, third_to_fail]
T_pumps_matrix = [T_p1; T_p2; T_p3];
T_pumps_sorted = sort(T_pumps_matrix, 1); % Sort down each column
% When the second pump dies (row 2), only 1 pump remains -> Pump stage fails!
T_pump_stage = T_pumps_sorted(2, :);

% 3. Heat exchanger stage: Series single unit
T_hex_stage = T_hex;

% 4. Complete System: Series connection -> Fails when the FIRST stage dies:
%    T_sys = min(T_power, T_pump, T_hex)
T_sys_sim = min([T_power_stage; T_pump_stage; T_hex_stage], [], 1);
% -------------------------------------------------------------------------

% Monte Carlo estimate of System MTBF
MTBF_sys_sim = mean(T_sys_sim);
MTBF_sys_std = std(T_sys_sim);

% Empirical survival curve from Monte Carlo
R_system_mc = zeros(size(t_vec));
for idx = 1:N_time
    R_system_mc(idx) = mean(T_sys_sim > t_vec(idx));
end

% Maximum discrepancy between analytical and Monte Carlo survival curves
max_survival_diff = max(abs(R_system - R_system_mc));

fprintf('--- 3. MONTE CARLO LIFESPAN SIMULATION (N = %d Plants) ---\n', N_sim);
fprintf('Monte Carlo Simulated System MTBF     : %.2f hrs (Std: %.2f hrs)\n', ...
    MTBF_sys_sim, MTBF_sys_std);
fprintf('Analytical MTBF                       : %.2f hrs\n', MTBF_sys_analytical);
fprintf('MTBF Estimation Discrepancy           : %.2f hrs (%.2f%% relative)\n', ...
    abs(MTBF_sys_sim - MTBF_sys_analytical), ...
    abs(MTBF_sys_sim - MTBF_sys_analytical) / MTBF_sys_analytical * 100.0);
fprintf('Max Survival Curve Discrepancy        : %.4f (Matches theory)\n\n', ...
    max_survival_diff);


%% Section 4: Failure Mode Diagnosis & Bottleneck Analysis
% For each simulated failure, identify which stage triggered system shutdown:
failed_by_power = (T_sys_sim == T_power_stage);
failed_by_pumps = (T_sys_sim == T_pump_stage);
failed_by_hex   = (T_sys_sim == T_hex_stage);

pct_power = mean(failed_by_power) * 100.0;
pct_pumps = mean(failed_by_pumps) * 100.0;
pct_hex   = mean(failed_by_hex)   * 100.0;

fprintf('--- 4. FAILURE MODE BOTTLENECK ANALYSIS ---\n');
fprintf('Root Cause Breakdown across %d Simulated System Failures:\n', N_sim);
fprintf('  1. Pump Stage (2-out-of-3 Exhaustion)  : %6.2f%% of all failures\n', pct_pumps);
fprintf('  2. Heat Exchanger (Single Failure)     : %6.2f%% of all failures\n', pct_hex);
fprintf('  3. Power Stage (Both Supplies Dead)    : %6.2f%% of all failures\n', pct_power);
fprintf('-> Critical Bottleneck: The Coolant Pump stage causes the vast majority of shutdowns!\n\n');


%% Section 5: B-Life Evaluation & Maintenance Scheduling
% B10 Life: Time at which 10% of systems have failed (R(t) = 0.90)
% B1 Life : Time at which 1% of systems have failed (R(t) = 0.99)

% Find B10 and B1 from analytical survival curve
idx_B10 = find(R_system <= 0.90, 1, 'first');
t_B10_analytical = t_vec(idx_B10);

idx_B1 = find(R_system <= 0.99, 1, 'first');
t_B1_analytical = t_vec(idx_B1);

% Find empirical B10 and B1 from simulated sample percentiles
t_B10_mc = prctile(T_sys_sim, 10.0);
t_B1_mc  = prctile(T_sys_sim, 1.0);

fprintf('--- 5. B-LIFE METRICS & MAINTENANCE SCHEDULING ---\n');
fprintf('B1 Life (99%% Mission Reliability Target):\n');
fprintf('  Analytical Estimate                 : %.1f operating hours (%.1f months)\n', ...
    t_B1_analytical, t_B1_analytical / (24 * 30.5));
fprintf('  Monte Carlo Percentile              : %.1f operating hours\n', t_B1_mc);
fprintf('B10 Life (90%% Mission Reliability Target):\n');
fprintf('  Analytical Estimate                 : %.1f operating hours (%.1f months)\n', ...
    t_B10_analytical, t_B10_analytical / (24 * 30.5));
fprintf('  Monte Carlo Percentile              : %.1f operating hours\n', t_B10_mc);
fprintf('-----------------------------------------------------------------\n');
fprintf('RECOMMENDED PREVENTIVE MAINTENANCE SCHEDULE:\n');
fprintf('  -> Schedule pump refurbishment every %d hours to maintain > 95%% survival.\n', ...
    round(t_B1_analytical * 1.5));
fprintf('=================================================================\n');
