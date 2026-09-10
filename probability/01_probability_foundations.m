%% 01_probability_foundations.m - Probability Foundations & Bayesian Inference
% =========================================================================
% MODULE: Probability & Uncertainty in Engineering (R4)
% TOPIC : Sample Spaces, Random Variables, Conditional Probability & Bayes
%
% ENGINEERING CONTEXT:
% Modern manufacturing lines and autonomous robotic systems rely on sensor 
% networks to monitor physical health and detect anomalies. Sensors never 
% provide perfect certainty; electromagnetic interference, thermal fluctuations,
% and manufacturing tolerances introduce stochastic uncertainty.
%
% This script demonstrates:
%   1. Discrete Sample Spaces and Event Probability Axioms (Turbine inspection)
%   2. Continuous Random Variables: PDF, CDF, and numerical quadrature
%   3. Joint, Marginal, and Conditional Probabilities in Diagnostic Matrices
%   4. Bayes' Theorem applied to industrial sensor false-alarm rate analysis
%   5. Large-Scale Monte Carlo Verification of Bayesian Posterior Probabilities
% =========================================================================

clear;
close all;
clc;

fprintf('=================================================================\n');
fprintf('  PROBABILITY FOUNDATIONS & BAYESIAN INFERENCE IN ENGINEERING     \n');
fprintf('=================================================================\n\n');

%% Section 1: Discrete Sample Spaces & Kolmogorov's Axioms
% In automated quality inspection of CNC-machined titanium turbine blades,
% an optical scanner classifies each manufactured blade into one of 4 mutually
% exclusive surface finish categories:
%   Outcome 1: 'Mirror'       - Exceeds aerospace specification
%   Outcome 2: 'Nominal'      - Meets target surface roughness Ra <= 0.8 um
%   Outcome 3: 'Marginal'     - Usable with secondary polishing (Ra <= 1.6 um)
%   Outcome 4: 'Reject'       - Scrapped due to tool chatter / gouges

% Historical inspection probabilities across 100,000 parts
P_outcomes = [0.15, 0.70, 0.12, 0.03]; 
categories = {'Mirror', 'Nominal', 'Marginal', 'Reject'};

% Axiom 1: Non-negativity P(E) >= 0 for all events
assert(all(P_outcomes >= 0.0), 'Axiom 1 violation: Probabilities must be non-negative.');

% Axiom 2: Normalization P(Omega) = 1.0
P_total_sample_space = sum(P_outcomes);
assert(abs(P_total_sample_space - 1.0) < 1e-12, 'Axiom 2 violation: Total probability must equal 1.');

% Axiom 3: Additivity for mutually exclusive events
% Event A: Part is immediately acceptable without rework ('Mirror' or 'Nominal')
P_acceptable = P_outcomes(1) + P_outcomes(2); 

% Event B: Part requires engineering intervention ('Marginal' or 'Reject')
P_rework_or_scrap = P_outcomes(3) + P_outcomes(4);

fprintf('--- 1. DISCRETE SAMPLE SPACE & PROBABILITY AXIOMS ---\n');
fprintf('Sample Space Size                     : %d categories\n', length(P_outcomes));
fprintf('Total Sample Space Probability sum(P) : %.6f\n', P_total_sample_space);
fprintf('Probability Immediately Acceptable    : %.2f%%\n', P_acceptable * 100.0);
fprintf('Probability Rework or Scrap           : %.2f%%\n\n', P_rework_or_scrap * 100.0);


%% Section 2: Continuous Random Variables: PDF, CDF, and Numerical Quadrature
% Surface roughness Ra (micrometers) follows a continuous distribution 
% over [0, 2.5] um modeled by a Weibull-like or truncated Gamma density:
% Here we model the PDF using an engineering Rayleigh-like profile:
%   f(x) = (x / sigma^2) * exp(-x^2 / (2 * sigma^2)) for x >= 0
% Parameter sigma = 0.55 um dictates peak modal roughness.

sigma_Ra = 0.55; % Scale parameter [micrometers]
x_grid = linspace(0.0, 2.5, 501); % Continuous roughness evaluation grid
dx = x_grid(2) - x_grid(1);

% Probability Density Function (PDF)
f_Ra = (x_grid ./ (sigma_Ra^2)) .* exp(-(x_grid.^2) ./ (2.0 * (sigma_Ra^2)));

% Cumulative Distribution Function (CDF) via numerical accumulation (trapz/cumtrapz)
% Analytical CDF for Rayleigh: F(x) = 1 - exp(-x^2 / (2 * sigma^2))
F_Ra_analytical = 1.0 - exp(-(x_grid.^2) ./ (2.0 * (sigma_Ra^2)));
F_Ra_numerical  = cumtrapz(x_grid, f_Ra);

% Total integral over domain must approach 1.0
total_area_pdf = trapz(x_grid, f_Ra);

% Engineering threshold: Specification limit is Ra <= 0.8 um
Ra_limit = 0.8;
% Probability that a blade meets specification: P(Ra <= 0.8)
P_in_spec_analytical = 1.0 - exp(-(Ra_limit^2) ./ (2.0 * (sigma_Ra^2)));

% Numerical evaluation using trapz up to Ra_limit
idx_limit = find(x_grid <= Ra_limit, 1, 'last');
P_in_spec_numerical = trapz(x_grid(1:idx_limit), f_Ra(1:idx_limit));

% Expectation (mean surface roughness): E[X] = integral x * f(x) dx
% Analytical expectation for Rayleigh: sigma * sqrt(pi / 2)
mean_Ra_analytical = sigma_Ra * sqrt(pi / 2.0);
mean_Ra_numerical  = trapz(x_grid, x_grid .* f_Ra);

fprintf('--- 2. CONTINUOUS RANDOM VARIABLE: SURFACE ROUGHNESS ---\n');
fprintf('Total PDF Area under curve (trapz)    : %.6f\n', total_area_pdf);
fprintf('Expected Mean Roughness E[Ra]         : %.4f um (Analytical: %.4f um)\n', ...
    mean_Ra_numerical, mean_Ra_analytical);
fprintf('P(Ra <= 0.8 um) In-Spec Yield         : %.2f%% (Analytical: %.2f%%)\n\n', ...
    P_in_spec_numerical * 100.0, P_in_spec_analytical * 100.0);


%% Section 3: Joint, Marginal, and Conditional Probability
% Consider an industrial pump bearing monitored by an acoustic sensor.
% States of the bearing:
%   S1: Normal healthy operation (P(S1) = 0.96)
%   S2: Bearing race fatigue / spalling (P(S2) = 0.04)
%
% Sensor readings:
%   R1: Low acoustic emission (Below 30 dB threshold)
%   R2: High acoustic emission (Above 30 dB threshold)
%
% Joint probability matrix P_joint(State, Reading):
% Columns: [R1 (Low), R2 (High)]
% Rows:    [S1 (Healthy); S2 (Damaged)]
P_joint = [
    0.9312, 0.0288;  % S1 Healthy: 93.12% correctly quiet, 2.88% false high
    0.0032, 0.0368   % S2 Damaged: 0.32% missed low, 3.68% correctly detected high
];

% Marginal probabilities by summing along dimensions
% P(State) = sum across columns (dimension 2)
P_state = sum(P_joint, 2); 
P_healthy = P_state(1);
P_damaged = P_state(2);

% P(Reading) = sum down rows (dimension 1)
P_reading = sum(P_joint, 1);
P_low_signal  = P_reading(1);
P_high_signal = P_reading(2);

% Conditional probabilities: P(Reading | State) = P(Joint) / P(State)
% Sensitivity (True Positive Rate) = P(R2 | S2)
P_high_given_damaged = P_joint(2, 2) / P_damaged;

% Specificity (True Negative Rate) = P(R1 | S1)
P_low_given_healthy = P_joint(1, 1) / P_healthy;

% False Positive Rate = P(R2 | S1)
P_high_given_healthy = P_joint(1, 2) / P_healthy;

fprintf('--- 3. JOINT AND CONDITIONAL PROBABILITY MATRIX ---\n');
fprintf('Bearing Health Priors: P(Healthy) = %.2f%%, P(Damaged) = %.2f%%\n', ...
    P_healthy * 100.0, P_damaged * 100.0);
fprintf('Sensor Sensitivity P(High | Damaged) : %.2f%%\n', P_high_given_damaged * 100.0);
fprintf('Sensor Specificity P(Low | Healthy)  : %.2f%%\n', P_low_given_healthy * 100.0);
fprintf('Sensor False Positive Rate P(High|OK): %.2f%%\n\n', P_high_given_healthy * 100.0);


%% Section 4: Bayes' Theorem in Industrial Diagnostics
% A telemetry alarm sounds: The sensor reports R2 (High acoustic emission).
% Plant operators must decide: Should we initiate an emergency shutdown?
%
% Bayes' Rule computes the posterior probability of actual mechanical damage:
%   P(Damaged | High) = [P(High | Damaged) * P(Damaged)] / P(High)
% where P(High) = P(High | Damaged)*P(Damaged) + P(High | Healthy)*P(Healthy)

% Analytical formulation
numerator = P_high_given_damaged * P_damaged;
denominator = (P_high_given_damaged * P_damaged) + (P_high_given_healthy * P_healthy);
P_damaged_given_high = numerator / denominator;
P_healthy_given_high = 1.0 - P_damaged_given_high;

fprintf('--- 4. BAYESIAN DIAGNOSTIC POSTERIOR CALCULATION ---\n');
fprintf('Numerator [P(High|Damaged) * P(Damaged)]  : %.6f\n', numerator);
fprintf('Denominator P(High) [Total Evidence]      : %.6f\n', denominator);
fprintf('Posterior P(Damaged | High Alarm)         : %.4f (%.2f%%)\n', ...
    P_damaged_given_high, P_damaged_given_high * 100.0);
fprintf('Posterior P(Healthy | High Alarm)         : %.4f (%.2f%%)\n', ...
    P_healthy_given_high, P_healthy_given_high * 100.0);
fprintf('-> Engineering Insight: %.2f%% of all triggered alarms are FALSE ALARMS!\n\n', ...
    P_healthy_given_high * 100.0);


%% Section 5: Large-Scale Monte Carlo Empirical Verification
% Simulate 200,000 independent pump operating cycles to empirically verify
% the analytical Bayesian posterior calculations.

N_mc = 200000;
rng(101); % Seed for reproducible simulation results

% 1. Simulate true physical health state for each cycle
% rand() returns uniform numbers in [0, 1]. If rand < P_damaged, bearing is damaged.
is_damaged = rand(1, N_mc) < P_damaged;

% 2. Simulate sensor measurements conditioned on physical state
sensor_alarm = false(1, N_mc);

% Damaged bearings trigger alarm with probability P_high_given_damaged
damaged_indices = find(is_damaged);
sensor_alarm(damaged_indices) = rand(1, length(damaged_indices)) < P_high_given_damaged;

% Healthy bearings trigger false alarm with probability P_high_given_healthy
healthy_indices = find(~is_damaged);
sensor_alarm(healthy_indices) = rand(1, length(healthy_indices)) < P_high_given_healthy;

% 3. Extract empirical statistics from simulated ensemble
total_alarms_sim      = sum(sensor_alarm);
true_positives_sim    = sum(sensor_alarm & is_damaged);
false_positives_sim   = sum(sensor_alarm & ~is_damaged);

% Empirical posterior probability: P(Damaged | Alarm) = True Positives / Total Alarms
P_damaged_alarm_mc = true_positives_sim / total_alarms_sim;
P_healthy_alarm_mc = false_positives_sim / total_alarms_sim;

% Error between analytical Bayes and Monte Carlo simulation
err_posterior = abs(P_damaged_given_high - P_damaged_alarm_mc);

fprintf('--- 5. MONTE CARLO EMPIRICAL VERIFICATION (N = %d) ---\n', N_mc);
fprintf('Simulated Total Alarms Triggered      : %d (%.2f%% of all cycles)\n', ...
    total_alarms_sim, (total_alarms_sim / N_mc) * 100.0);
fprintf('  - True Positives (Real Damage)      : %d\n', true_positives_sim);
fprintf('  - False Positives (Healthy False)   : %d\n', false_positives_sim);
fprintf('Analytical Posterior P(Damaged|Alarm) : %.5f\n', P_damaged_given_high);
fprintf('Monte Carlo Posterior P(Damaged|Alarm): %.5f\n', P_damaged_alarm_mc);
fprintf('Absolute Estimation Error             : %.2e (Matches theory)\n', err_posterior);
fprintf('=================================================================\n');
