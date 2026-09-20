%% probability_exercises_solution.m - Reference Solution for Probability Exercises
% =========================================================================
% MODULE: Probability & Uncertainty in Engineering (Level 2 / R4)
%
% PURPOSE:
%   Complete worked reference solution for all 4 progressive pedagogical tiers
%   of probability/exercises.m with 100% verified analytical and numerical solutions.
%
% PEDAGOGICAL COVERAGE:
%   - Level 1: Recall (Normal and uniform distributions, sample moments, empirical coverage)
%   - Level 2: Understanding & Debugging (Bessel unbiased variance, Bayes base-rate fallacy)
%   - Level 3: Application (Telemetry noise filtering, moving average variance reduction, SNR)
%   - Level 4: Challenge (Aircraft quad-redundant 2-out-of-4 hydraulic reliability, MTBF, FAA)
% =========================================================================

clear;
close all;
clc;

fprintf('=================================================================\n');
fprintf('  PROBABILITY & UNCERTAINTY: REFERENCE SOLUTIONS                 \n');
fprintf('=================================================================\n\n');

%% Level 1: Recall
% -------------------------------------------------------------------------
% Problem 1.1: Generating Gaussian Noise & Sample Moments
% -------------------------------------------------------------------------

mu_target  = 15.0; % Population mean [V]
sig_target = 2.5;  % Population standard deviation [V]
N_1        = 100000;
rng(111);          % Deterministic random seed

% Solution 1.1.1: Generate N_1 normal random samples
v_samples = mu_target + sig_target * randn(1, N_1);

% Solution 1.1.2: Compute sample statistics (mean, unbiased variance, std)
mu_sample  = mean(v_samples);
var_sample = var(v_samples);
std_sample = std(v_samples);

% Solution 1.1.3: Empirical 1-sigma and 2-sigma coverage fractions
in_1sigma = (v_samples >= mu_target - sig_target) & (v_samples <= mu_target + sig_target);
in_2sigma = (v_samples >= mu_target - 2.0 * sig_target) & (v_samples <= mu_target + 2.0 * sig_target);
frac_1sigma = mean(in_1sigma);
frac_2sigma = mean(in_2sigma);

fprintf('--- Level 1.1: Gaussian Noise Generation ---\n');
fprintf('Sample Mean (Expected ~15.0 V)       : %.4f V\n', mu_sample);
fprintf('Sample Std Dev (Expected ~2.5 V)     : %.4f V\n', std_sample);
fprintf('1-Sigma Coverage (Expected ~68.27%%)  : %.2f%%\n', frac_1sigma * 100.0);
fprintf('2-Sigma Coverage (Expected ~95.45%%)  : %.2f%%\n\n', frac_2sigma * 100.0);

% -------------------------------------------------------------------------
% Problem 1.2: Discrete Uniform Sampling for Digital ADC Codes
% -------------------------------------------------------------------------

N_adc    = 50000;
min_code = 1;
max_code = 4096;

% Solution 1.2.1: Generate N_adc discrete uniform integers
adc_codes = randi([min_code, max_code], 1, N_adc);

% Solution 1.2.2: Compute sample mean and compare with theoretical expectation
mean_code_sim    = mean(adc_codes);
mean_code_theory = (min_code + max_code) / 2.0; % 2048.5

fprintf('--- Level 1.2: Uniform Discrete ADC Sampling ---\n');
fprintf('Theoretical Code Mean                 : %.2f\n', mean_code_theory);
fprintf('Simulated Sample Mean                 : %.2f\n\n', mean_code_sim);


%% Level 2: Understanding & Debugging
% -------------------------------------------------------------------------
% Debugging Task 2.1: Correcting a Biased Sample Variance Estimator
% -------------------------------------------------------------------------

batch = [12.2, 11.8, 12.5, 11.9, 12.6];
N_b = length(batch);
m_b = mean(batch);

% Flawed biased variance from inspector (N divisor)
var_flawed = sum((batch - m_b).^2) / N_b;

% Solution 2.1.1: Unbiased sample variance with Bessel's correction (N - 1 divisor)
var_corrected = sum((batch - m_b).^2) / (N_b - 1);

% Solution 2.1.2: MATLAB built-in confirmation
var_builtin = var(batch);

fprintf('--- Level 2.1: Biased Variance Debugging ---\n');
fprintf('Flawed Biased Variance (N divisor)    : %.6f\n', var_flawed);
fprintf('Corrected Unbiased Variance (N-1)     : %.6f\n', var_corrected);
fprintf('MATLAB Built-in var() Confirmation    : %.6f\n\n', var_builtin);

% -------------------------------------------------------------------------
% Debugging Task 2.2: Correcting the Base-Rate Fallacy in Sensor Diagnostics
% -------------------------------------------------------------------------

P_crack_prior       = 0.004;
P_safe_prior        = 1.0 - P_crack_prior;
P_alarm_given_crack = 0.99;
P_alarm_given_safe  = 0.03;

% Solution 2.2.1: Law of Total Probability for P(Alarm)
P_alarm_total = P_alarm_given_crack * P_crack_prior + P_alarm_given_safe * P_safe_prior;

% Solution 2.2.2: Bayes' Theorem for true posterior P(Crack | Alarm)
P_crack_given_alarm = (P_alarm_given_crack * P_crack_prior) / P_alarm_total;

% Solution 2.2.3: False alarm posterior probability P(Safe | Alarm)
P_safe_given_alarm = 1.0 - P_crack_given_alarm;

fprintf('--- Level 2.2: Bayesian Diagnostic Correction ---\n');
fprintf('Total Alarm Probability P(Alarm)      : %.4f (%.2f%%)\n', ...
    P_alarm_total, P_alarm_total * 100.0);
fprintf('True Posterior P(Crack | Alarm)       : %.4f (%.2f%%)\n', ...
    P_crack_given_alarm, P_crack_given_alarm * 100.0);
fprintf('False Alarm Probability P(Safe | Alarm: %.4f (%.2f%%)\n\n', ...
    P_safe_given_alarm, P_safe_given_alarm * 100.0);


%% Level 3: Application
% -------------------------------------------------------------------------
% Problem 3: Sensor Telemetry Noise Suppression & SNR Optimization
% -------------------------------------------------------------------------

fs_3 = 400.0;
dt_3 = 1.0 / fs_3;
t_3  = 0.0:dt_3:4.0;
N_3  = length(t_3);

rng(333); % Deterministic seed
sigma_noise_3 = 4.0; % Noise std [kN]

% Ground truth sinusoidal thrust signal
s_thrust_clean = 50.0 + 8.0 .* sin(2.0 * pi * 2.5 .* t_3);

% Corrupted sensor signal with additive white Gaussian noise
noise_thrust = sigma_noise_3 .* randn(1, N_3);
x_thrust_noisy = s_thrust_clean + noise_thrust;

% Solution 3.1: AC signal power and raw SNR in dB
P_sig_ac_3 = mean((s_thrust_clean - mean(s_thrust_clean)).^2);
P_noise_raw = var(noise_thrust);
SNR_raw_dB = 10.0 * log10(P_sig_ac_3 / P_noise_raw);

% Filter configuration: Moving average window of size W = 17
W_3 = 17;
b_3 = ones(1, W_3) / W_3;

% Solution 3.2: Filter noisy telemetry using filter()
y_filtered = filter(b_3, 1.0, x_thrust_noisy);

% Solution 3.3: Filter isolated noise to verify theoretical variance reduction
noise_filt = filter(b_3, 1.0, noise_thrust);
var_filt_empirical = var(noise_filt(W_3:end));
var_filt_theoretical = (sigma_noise_3^2) / W_3;

% Solution 3.4: Group delay compensation and filtered SNR calculation
delay_samples_3 = (W_3 - 1) / 2; % 8 samples
y_aligned = y_filtered((W_3 + delay_samples_3):end);
s_aligned = s_thrust_clean(W_3:(end - delay_samples_3));

residual_noise_3 = y_aligned - s_aligned;
SNR_filt_dB = 10.0 * log10(P_sig_ac_3 / mean(residual_noise_3.^2));

fprintf('--- Level 3: Telemetry Noise Filtering ---\n');
fprintf('Raw Telemetry SNR                     : %.2f dB\n', SNR_raw_dB);
fprintf('Theoretical Noise Variance (sigma^2/W): %.4f (kN)^2\n', var_filt_theoretical);
fprintf('Empirical Filtered Noise Variance     : %.4f (kN)^2\n', var_filt_empirical);
fprintf('Filtered Delay-Compensated SNR        : %.2f dB\n', SNR_filt_dB);
fprintf('Net Telemetry SNR Improvement         : +%.2f dB\n\n', SNR_filt_dB - SNR_raw_dB);


%% Level 4: Challenge
% -------------------------------------------------------------------------
% Problem 4: Reliability Modeling of Aircraft Quad-Redundant Hydraulic System
% -------------------------------------------------------------------------

MTBF_single_pump = 10000.0; % Single pump MTBF [flight hours]
lambda_pump = 1.0 / MTBF_single_pump;
t_mission   = 5000.0;       % Evaluation mission duration [hours]

% Solution 4.1: Analytical 2-out-of-4 system survival probability at 5,000 hours
R_p_5k = exp(-lambda_pump * t_mission); % ~0.6065
% Binomial 2-out-of-4 expansion:
% P(k=4) = R_p^4
% P(k=3) = 4 * R_p^3 * (1 - R_p)
% P(k=2) = 6 * R_p^2 * (1 - R_p)^2
R_sys_analytical_5k = (R_p_5k^4) + ...
                      4.0 * (R_p_5k^3) * (1.0 - R_p_5k) + ...
                      6.0 * (R_p_5k^2) * ((1.0 - R_p_5k)^2);

% Solution 4.2: Monte Carlo reliability simulation (50,000 aircraft fleets)
N_aircraft = 50000;
rng(444); % Reproducible seed
T_pumps_sim = -log(rand(4, N_aircraft)) ./ lambda_pump;
T_pumps_sorted = sort(T_pumps_sim, 1);
T_system_fail  = T_pumps_sorted(3, :); % 3rd failure terminates 2-out-of-4 operation

R_sys_mc_5k = mean(T_system_fail > t_mission);

% Solution 4.3: Analytical and simulated system MTBF
% Order statistics for independent exponential components:
% MTBF_sys = (1/lambda) * (1/4 + 1/3 + 1/2) = (13/12) * MTBF_single
MTBF_sys_analytical = MTBF_single_pump * (1.0/2.0 + 1.0/3.0 + 1.0/4.0);
MTBF_sys_mc         = mean(T_system_fail);

% Solution 4.4: Regulatory FAA safety directive compliance at t = 1,000 flight hours
t_faa = 1000.0;
R_p_faa = exp(-lambda_pump * t_faa);
R_sys_faa = (R_p_faa^4) + ...
            4.0 * (R_p_faa^3) * (1.0 - R_p_faa) + ...
            6.0 * (R_p_faa^2) * ((1.0 - R_p_faa)^2);
P_loss_faa = 1.0 - R_sys_faa;
meets_faa_directive = (P_loss_faa <= 1.0e-4);

fprintf('--- Level 4: Aircraft Quad-Redundant Reliability ---\n');
fprintf('Single Pump MTBF                      : %.1f flight hours\n', MTBF_single_pump);
fprintf('Analytical System R(5000 hrs)         : %.4f (%.2f%%)\n', ...
    R_sys_analytical_5k, R_sys_analytical_5k * 100.0);
fprintf('Monte Carlo System R(5000 hrs)        : %.4f (%.2f%%)\n', ...
    R_sys_mc_5k, R_sys_mc_5k * 100.0);
fprintf('Analytical System MTBF                : %.1f flight hours\n', MTBF_sys_analytical);
fprintf('Simulated System MTBF                 : %.1f flight hours\n', MTBF_sys_mc);
fprintf('Loss of Control Prob at 1,000 hrs     : %.2e (Limit: 1.00e-04)\n', P_loss_faa);
if meets_faa_directive
    fprintf('Airworthiness Compliance              : COMPLIANT with FAA Safety Directive.\n');
else
    fprintf('Airworthiness Compliance              : NON-COMPLIANT. Redesign required.\n');
end
fprintf('=================================================================\n');
fprintf('  PROBABILITY REFERENCE SOLUTIONS COMPLETED SUCCESSFULLY         \n');
fprintf('=================================================================\n');
