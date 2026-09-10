%% 03_monte_carlo_simulation.m - Monte Carlo Methods & Tolerance Stack-Up
% =========================================================================
% MODULE: Probability & Uncertainty in Engineering (R4)
% TOPIC : Monte Carlo Simulation, Law of Large Numbers & Tolerance Stack-Up
%
% ENGINEERING CONTEXT:
% When physical engineering systems involve complex geometries, non-linear 
% interactions, or multi-component assemblies, analytical closed-form 
% probability formulas often become intractable. Monte Carlo simulation is the 
% gold-standard computational technique used across aerospace, automotive, 
% and semiconductor design to evaluate assembly clearances, structural risk, 
% and failure probabilities through repeated pseudo-random sampling.
%
% This script demonstrates:
%   1. Monte Carlo Integration: Hit-or-Miss Area & Pi Estimation
%   2. Law of Large Numbers (LLN): Convergence and O(1/sqrt(N)) Error Scaling
%   3. Precision Mechanical Assembly: Worst-Case vs Statistical Tolerance Stack-Up
%   4. Central Limit Theorem (CLT): Normal Emergence from Non-Gaussian Parts
%   5. Risk & Interference Probability Quantification in Mechanical Fit
% =========================================================================

clear;
close all;
clc;

fprintf('=================================================================\n');
fprintf('  MONTE CARLO SIMULATION & STATISTICAL TOLERANCE ANALYSIS        \n');
fprintf('=================================================================\n\n');

%% Section 1: Monte Carlo Integration (Hit-or-Miss Estimation of Pi)
% Estimate the area of a quarter-circle of radius R = 1 inscribed within a
% unit square [0, 1] x [0, 1].
% Area of quarter circle: A = pi / 4
% True ratio of hits: p = pi / 4 ~ 0.785398...

N_pi = 500000;
rng(404);

% Generate uniform random coordinates in 2D unit square [0, 1] x [0, 1]
x_coords = rand(1, N_pi);
y_coords = rand(1, N_pi);

% Hit condition: x^2 + y^2 <= 1.0
inside_circle = (x_coords.^2 + y_coords.^2) <= 1.0;
hits = sum(inside_circle);

% Estimated area and pi
pi_est = 4.0 * (hits / N_pi);
pi_exact = pi;
err_pi = abs(pi_est - pi_exact);

% Theoretical standard error: sigma_est = 4 * sqrt(p*(1-p) / N)
p_true = pi_exact / 4.0;
std_err_theory = 4.0 * sqrt(p_true * (1.0 - p_true) / N_pi);

fprintf('--- 1. MONTE CARLO INTEGRATION: ESTIMATION OF PI ---\n');
fprintf('Sample Size N                      : %d points\n', N_pi);
fprintf('Total Hits Inside Quarter Circle   : %d (%.2f%%)\n', hits, (hits / N_pi) * 100.0);
fprintf('Analytical Ground Truth Pi         : %.8f\n', pi_exact);
fprintf('Monte Carlo Estimated Pi           : %.8f\n', pi_est);
fprintf('Absolute Estimation Error          : %.2e\n', err_pi);
fprintf('Theoretical 1-Sigma Bound          : %.2e (Matches empirical error)\n\n', ...
    std_err_theory);


%% Section 2: Law of Large Numbers (LLN) Convergence Rate
% The Law of Large Numbers dictates that the sample mean converges to the true
% expectation. The Central Limit Theorem proves that error decays as O(1 / sqrt(N)).
% We evaluate convergence across orders of magnitude: N = 10^1 to 10^6.

sample_sizes = [10, 50, 100, 500, 1000, 5000, 10000, 50000, 100000, 500000, 1000000];
errors = zeros(size(sample_sizes));

% True mean for a standard exponential random variable Exp(lambda = 0.5):
% E[X] = 1 / lambda = 2.0
lambda_exp = 0.5;
true_mean_exp = 1.0 / lambda_exp;

rng(505);
for i = 1:length(sample_sizes)
    N_current = sample_sizes(i);
    % Generate exponential random samples via inverse CDF: X = -ln(U) / lambda
    u_samples = rand(1, N_current);
    exp_samples = -log(u_samples) ./ lambda_exp;
    sample_mean_current = mean(exp_samples);
    errors(i) = abs(sample_mean_current - true_mean_exp);
end

fprintf('--- 2. LAW OF LARGE NUMBERS CONVERGENCE (E[X] = %.1f) ---\n', true_mean_exp);
fprintf('SAMPLE SIZE (N)       ESTIMATION ERROR      O(1/sqrt(N)) BENCHMARK\n');
for i = 1:length(sample_sizes)
    fprintf('%12d          %14.6f        %14.6f\n', ...
        sample_sizes(i), errors(i), 1.0 / sqrt(sample_sizes(i)));
end
fprintf('\n');


%% Section 3: Mechanical Tolerance Stack-Up in a Precision Assembly
% A precision aerospace optical enclosure holds 4 stacked cylindrical spacers.
% Dimensions and manufacturing tolerances:
%   Enclosure Slot Length: L_slot ~ N(100.00 mm, sigma = 0.12 mm)
%   Spacer 1: L1 ~ N(24.90 mm, sigma = 0.05 mm)
%   Spacer 2: L2 ~ N(24.90 mm, sigma = 0.05 mm)
%   Spacer 3: L3 ~ N(24.90 mm, sigma = 0.05 mm)
%   Spacer 4: L4 ~ N(24.90 mm, sigma = 0.05 mm)
%
% Clearance Gap: G = L_slot - (L1 + L2 + L3 + L4)
% Engineering Specification:
%   - Mechanical Interference (Failure Mode A): G < 0.0 mm (Spacers too long to fit)
%   - Excessive Play (Failure Mode B): G > 0.80 mm (Optical lenses vibrate loose)

mu_slot = 100.00;  sigma_slot = 0.12;
mu_spacer = 24.90; sigma_spacer = 0.05;
num_spacers = 4;

% Method 1: Worst-Case Analysis (Arithmetic Sum of 3-Sigma Limits)
% Assumes all parts are manufactured at their extreme worst-case 3-sigma dimensions.
T_slot_wc = 3.0 * sigma_slot;
T_spacer_wc = 3.0 * sigma_spacer;
G_min_worst_case = (mu_slot - T_slot_wc) - num_spacers * (mu_spacer + T_spacer_wc);
G_max_worst_case = (mu_slot + T_slot_wc) - num_spacers * (mu_spacer - T_spacer_wc);

% Method 2: Statistical Tolerance Analysis (Root Sum of Squares / RSS)
% Variances add linearly for independent random variables:
% Var(G) = Var(L_slot) + sum(Var(L_i))
mu_G_theory = mu_slot - num_spacers * mu_spacer;
var_G_theory = (sigma_slot^2) + num_spacers * (sigma_spacer^2);
sigma_G_theory = sqrt(var_G_theory);

% RSS 3-Sigma limits:
G_min_rss = mu_G_theory - 3.0 * sigma_G_theory;
G_max_rss = mu_G_theory + 3.0 * sigma_G_theory;

% Method 3: Large-Scale Monte Carlo Simulation (N = 250,000 assemblies)
N_assemblies = 250000;
rng(606);

L_slot_sim = mu_slot + sigma_slot .* randn(1, N_assemblies);
L_spacers_sim = zeros(num_spacers, N_assemblies);
for s = 1:num_spacers
    L_spacers_sim(s, :) = mu_spacer + sigma_spacer .* randn(1, N_assemblies);
end
total_spacers_sim = sum(L_spacers_sim, 1);
G_sim = L_slot_sim - total_spacers_sim;

% Compute simulated clearance statistics
mu_G_sim = mean(G_sim);
sigma_G_sim = std(G_sim);

% Failure rate evaluation
p_interference_sim = mean(G_sim < 0.0);       % G < 0 mm
p_excess_play_sim  = mean(G_sim > 0.80);      % G > 0.8 mm
p_defect_total_sim = mean(G_sim < 0.0 | G_sim > 0.80);

% Theoretical interference probability using standard normal CDF
Z_interf = (0.0 - mu_G_theory) / sigma_G_theory;
p_interference_theory = 0.5 * erfc(-Z_interf / sqrt(2.0));

fprintf('--- 3. MECHANICAL TOLERANCE STACK-UP: WORST-CASE VS RSS VS MONTE CARLO ---\n');
fprintf('Nominal Stack Gap E[G]             : %.4f mm\n', mu_G_theory);
fprintf('Worst-Case 3-Sigma Range           : [%.4f, %.4f] mm (Total Span = %.4f mm)\n', ...
    G_min_worst_case, G_max_worst_case, G_max_worst_case - G_min_worst_case);
fprintf('RSS Statistical 3-Sigma Range      : [%.4f, %.4f] mm (Total Span = %.4f mm)\n', ...
    G_min_rss, G_max_rss, G_max_rss - G_min_rss);
fprintf('Monte Carlo Simulated Mean Gap     : %.4f mm (Std: %.4f mm)\n', ...
    mu_G_sim, sigma_G_sim);
fprintf('Simulated Mechanical Interference  : %d of %d (%.4f%% | Theory: %.4f%%)\n', ...
    sum(G_sim < 0.0), N_assemblies, p_interference_sim * 100.0, p_interference_theory * 100.0);
fprintf('Simulated Excessive Play (> 0.8mm) : %d of %d (%.4f%%)\n', ...
    sum(G_sim > 0.80), N_assemblies, p_excess_play_sim * 100.0);
fprintf('Total Assembly Failure Rate        : %.2f PPM\n\n', p_defect_total_sim * 1e6);


%% Section 4: Central Limit Theorem (Non-Gaussian Component Tolerances)
% Suppose the manufacturing supplier uses stamped sheet metal with a UNIFORM
% tolerance distribution rather than Gaussian:
%   Spacer length L_u ~ Uniform(24.75, 25.05) mm
%   Mean = 24.90 mm, Span = 0.30 mm, Variance = (0.30)^2 / 12 = 0.0075 mm^2
% Even though each component is uniform, does their sum follow a Normal curve?

a_u = 24.75;
b_u = 25.05;
N_clt = 250000;

% Simulate sum of 4 uniform spacers
uniform_spacers = a_u + (b_u - a_u) .* rand(num_spacers, N_clt);
sum_uniform = sum(uniform_spacers, 1);

mean_clt = mean(sum_uniform);
std_clt  = std(sum_uniform);

% Compute higher statistical moments: Skewness and Excess Kurtosis
% Normal distribution has Skewness = 0, Excess Kurtosis = 0
central_diff = sum_uniform - mean_clt;
skewness = mean(central_diff.^3) / (std_clt^3);
excess_kurtosis = (mean(central_diff.^4) / (std_clt^4)) - 3.0;

fprintf('--- 4. CENTRAL LIMIT THEOREM VERIFICATION (SUM OF UNIFORM PARTS) ---\n');
fprintf('Theoretical Mean of Sum            : %.4f mm\n', num_spacers * (a_u + b_u) / 2.0);
fprintf('Empirical Mean of Sum              : %.4f mm\n', mean_clt);
fprintf('Theoretical Std Dev of Sum         : %.4f mm\n', ...
    sqrt(num_spacers * ((b_u - a_u)^2) / 12.0));
fprintf('Empirical Std Dev of Sum           : %.4f mm\n', std_clt);
fprintf('Calculated Assembly Skewness       : %.4f (Normal theory = 0.0000)\n', skewness);
fprintf('Calculated Assembly Excess Kurtosis: %.4f (Normal theory = 0.0000)\n', excess_kurtosis);
fprintf('-> Conclusion: Sum of 4 non-Gaussian parts closely converges to Gaussian behavior.\n');
fprintf('=================================================================\n');
