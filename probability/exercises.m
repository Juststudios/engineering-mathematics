%% exercises.m - 4-Tier Progressive Exercises: Probability & Uncertainty
% =========================================================================
% MODULE: Probability & Uncertainty in Engineering (R4)
%
% INSTRUCTIONS:
% Complete the exercises in each of the 4 progressive levels:
%   Level 1: Recall (Generating normal noise, computing sample moments)
%   Level 2: Understanding & Debugging (Fixing biased variance & Bayes base-rate)
%   Level 3: Application (Sensor telemetry noise suppression & SNR optimization)
%   Level 4: Challenge (Aircraft quad-redundant hydraulic system reliability)
%
% Look for '% TODO' comments where your code is required.
% =========================================================================

clear;
close all;
clc;

fprintf('=================================================================\n');
fprintf('  PROBABILITY & UNCERTAINTY: STUDENT EXERCISE SUITE              \n');
fprintf('=================================================================\n\n');

%% Level 1: Recall
% -------------------------------------------------------------------------
% Problem 1.1: Generating Gaussian Noise & Sample Moments
% An instrumentation amplifier produces an analog output voltage corrupted 
% by thermal noise. The output voltage is normally distributed:
%   V ~ N(mu = 15.0 V, sigma^2 = 2.5^2 V^2)
%
% Tasks:
%   1. Generate N = 100,000 random samples using randn() scaled to mu and sigma.
%   2. Calculate the sample mean (mu_sample), sample variance (var_sample),
%      and sample standard deviation (std_sample) using MATLAB functions.
%   3. Calculate the empirical fraction of samples falling within 1-sigma 
%      [mu - sigma, mu + sigma] and 2-sigma [mu - 2*sigma, mu + 2*sigma].
% -------------------------------------------------------------------------

mu_target  = 15.0; % True population mean [V]
sig_target = 2.5;  % True population standard deviation [V]
N_1        = 100000;
rng(111);          % Set random seed for reproducibility

% TODO: Task 1.1.1 - Generate N_1 normal random samples with mean mu_target and std sig_target
v_samples = []; % Replace with your code using randn()

% TODO: Task 1.1.2 - Compute sample mean, sample variance (N-1 divisor), and sample std
mu_sample  = 0; % Replace with mean()
var_sample = 0; % Replace with var()
std_sample = 0; % Replace with std()

% TODO: Task 1.1.3 - Compute fraction of samples within 1-sigma and 2-sigma
frac_1sigma = 0; % Replace with empirical fraction within [mu - sig, mu + sig]
frac_2sigma = 0; % Replace with empirical fraction within [mu - 2*sig, mu + 2*sig]

fprintf('--- Level 1.1: Gaussian Noise Generation ---\n');
fprintf('Sample Mean (Expected ~15.0 V)       : %.4f V\n', mu_sample);
fprintf('Sample Std Dev (Expected ~2.5 V)     : %.4f V\n', std_sample);
fprintf('1-Sigma Coverage (Expected ~68.27%%)  : %.2f%%\n', frac_1sigma * 100.0);
fprintf('2-Sigma Coverage (Expected ~95.45%%)  : %.2f%%\n\n', frac_2sigma * 100.0);

% -------------------------------------------------------------------------
% Problem 1.2: Discrete Uniform Sampling for Digital ADC Codes
% A 12-bit ADC converts analog signals to integer quantization bins [1, 4096].
% Under wideband excitation, the codes are uniformly distributed across all bins.
%
% Tasks:
%   1. Generate 50,000 random integer codes between 1 and 4096 using randi().
%   2. Compute the theoretical mean: E[K] = (1 + 4096) / 2 = 2048.5
%   3. Compute the sample mean code and compare with theory.
% -------------------------------------------------------------------------

N_adc = 50000;
min_code = 1;
max_code = 4096;

% TODO: Task 1.2.1 - Generate N_adc random integers between min_code and max_code
adc_codes = []; % Replace with your code using randi()

% TODO: Task 1.2.2 - Compute sample mean of adc_codes
mean_code_sim = 0; % Replace with mean()
mean_code_theory = (min_code + max_code) / 2.0;

fprintf('--- Level 1.2: Uniform Discrete ADC Sampling ---\n');
fprintf('Theoretical Code Mean                 : %.2f\n', mean_code_theory);
fprintf('Simulated Sample Mean                 : %.2f\n\n', mean_code_sim);


%% Level 2: Understanding & Debugging
% -------------------------------------------------------------------------
% Debugging Task 2.1: Correcting a Biased Sample Variance Estimator
% A junior quality inspector wrote an automated quality checking routine 
% for a 5-part CNC sample batch. The inspector used a naive sum-of-squares 
% formula dividing by N instead of N - 1:
%
% FLAGGED CODE:
%   batch = [12.2, 11.8, 12.5, 11.9, 12.6]; % Mass of 5 bearings [grams]
%   N_b = length(batch);
%   m_b = sum(batch) / N_b;
%   var_flawed = sum((batch - m_b).^2) / N_b; % BUG: Biased estimator (N divisor)!
%
% Tasks:
%   1. Identify why dividing by N underestimates true variance for small samples.
%   2. Implement the unbiased sample variance (var_unbiased) using Bessel's 
%      correction (dividing by N - 1).
%   3. Verify your result against MATLAB's built-in var(batch).
% -------------------------------------------------------------------------

batch = [12.2, 11.8, 12.5, 11.9, 12.6];
N_b = length(batch);
m_b = mean(batch);

% Flawed biased variance from junior inspector
var_flawed = sum((batch - m_b).^2) / N_b;

% TODO: Task 2.1.1 - Implement unbiased sample variance using sum of squared deviations / (N_b - 1)
var_corrected = 0; % Replace with your code

% TODO: Task 2.1.2 - Compute using built-in var() for confirmation
var_builtin = 0;   % Replace with var(batch)

fprintf('--- Level 2.1: Biased Variance Debugging ---\n');
fprintf('Flawed Biased Variance (N divisor)    : %.6f\n', var_flawed);
fprintf('Corrected Unbiased Variance (N-1)     : %.6f\n', var_corrected);
fprintf('MATLAB Built-in var() Confirmation    : %.6f\n\n', var_builtin);

% -------------------------------------------------------------------------
% Debugging Task 2.2: Correcting the Base-Rate Fallacy in Sensor Diagnostics
% A test engineer configures a vibration sensor to detect cracked gear teeth.
% Sensor specification:
%   - Sensitivity (True Positive Rate)  : P(Alarm | Crack) = 0.99 (99%)
%   - False Positive Rate               : P(Alarm | Safe)  = 0.03 (3%)
%   - Prior Probability of Gear Crack   : P(Crack)         = 0.004 (0.4%)
%
% The engineer asserts: "When the alarm rings, there is a 99% chance the 
% gear is cracked!" This is the classic Base-Rate Fallacy.
%
% Tasks:
%   1. Compute the total probability of an alarm P(Alarm) using the Law of Total Probability.
%   2. Correct the engineer's calculation by applying Bayes' Theorem to find
%      the true posterior probability: P(Crack | Alarm).
%   3. Compute the false alarm probability: P(Safe | Alarm).
% -------------------------------------------------------------------------

P_crack_prior = 0.004;
P_safe_prior  = 1.0 - P_crack_prior;
P_alarm_given_crack = 0.99;
P_alarm_given_safe  = 0.03;

% TODO: Task 2.2.1 - Compute total probability of alarm P(Alarm) via Law of Total Probability
P_alarm_total = 0; % Replace with your code

% TODO: Task 2.2.2 - Compute true posterior P(Crack | Alarm) via Bayes' Theorem
P_crack_given_alarm = 0; % Replace with your code

% TODO: Task 2.2.3 - Compute false alarm probability P(Safe | Alarm)
P_safe_given_alarm = 0;  % Replace with your code

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
% A rocket motor test stand uses a piezoelectric load cell to measure thrust.
% The true thrust signal exhibits a sinusoidal oscillation during combustion:
%   s(t) = 50.0 + 8.0 * sin(2*pi * 2.5 * t) [kiloNewtons (kN)]
% for t in [0, 4.0] seconds sampled at fs = 400 Hz (dt = 0.0025 s).
%
% The sensor signal is corrupted by additive zero-mean Gaussian noise with
% standard deviation sigma_noise = 4.0 kN.
%
% Tasks:
%   1. Synthesize the clean signal s_clean and noisy signal x_noisy = s_clean + noise.
%   2. Calculate AC signal power P_sig_ac and raw SNR in decibels (SNR_raw_dB).
%   3. Implement a moving-average filter with window size W = 17 using filter().
%   4. Compute the theoretical noise variance reduction factor (1 / W) and 
%      verify the empirical filtered noise variance.
%   5. Compensate for the filter phase delay (delay = (W - 1) / 2 samples)
%      and compute the final filtered SNR in decibels (SNR_filt_dB).
% -------------------------------------------------------------------------

fs_3 = 400.0;
dt_3 = 1.0 / fs_3;
t_3  = 0.0:dt_3:4.0;
N_3  = length(t_3);

rng(333); % Deterministic seed
sigma_noise_3 = 4.0; % Noise std [kN]

% Ground truth thrust signal
s_thrust_clean = 50.0 + 8.0 .* sin(2.0 * pi * 2.5 .* t_3);

% Additive white Gaussian noise
noise_thrust = sigma_noise_3 .* randn(1, N_3);
x_thrust_noisy = s_thrust_clean + noise_thrust;

% TODO: Task 3.1 - Compute AC signal power and raw SNR in dB
% AC signal power: mean((s - mean(s)).^2)
P_sig_ac_3 = 0; % Replace with your code
SNR_raw_dB = 0; % Replace with 10 * log10(P_sig_ac_3 / var(noise_thrust))

% Filter window specification
W_3 = 17; % Window length (odd integer)

% TODO: Task 3.2 - Apply moving average filter to x_thrust_noisy using filter()
% Filter coefficients: b = ones(1, W_3) / W_3, a = 1.0
b_3 = [];      % Replace with filter numerator coefficients
y_filtered = []; % Replace with filter(b_3, 1.0, x_thrust_noisy)

% TODO: Task 3.3 - Filter isolated noise vector to verify variance reduction
% Exclude startup transient (samples 1 to W_3 - 1)
noise_filt = [];     % Replace with filter(b_3, 1.0, noise_thrust)
var_filt_empirical = 0; % Replace with var of noise_filt(W_3:end)
var_filt_theoretical = (sigma_noise_3^2) / W_3;

% TODO: Task 3.4 - Delay compensation and filtered SNR calculation
% Group delay: delay_samples = (W_3 - 1) / 2
delay_samples_3 = 0; % Replace with (W_3 - 1) / 2
% Align filtered output with clean signal:
% y_aligned = y_filtered(W_3 + delay_samples_3 : end);
% s_aligned = s_thrust_clean(W_3 : end - delay_samples_3);
y_aligned = []; % Replace with your code
s_aligned = []; % Replace with your code

% Compute residual noise and filtered SNR in dB
residual_noise_3 = []; % Replace with y_aligned - s_aligned
SNR_filt_dB = 0;       % Replace with 10 * log10(P_sig_ac_3 / mean(residual_noise_3.^2))

fprintf('--- Level 3: Telemetry Noise Filtering ---\n');
fprintf('Raw Telemetry SNR                     : %.2f dB\n', SNR_raw_dB);
fprintf('Theoretical Noise Variance (sigma^2/W): %.4f (kN)^2\n', var_filt_theoretical);
fprintf('Empirical Filtered Noise Variance     : %.4f (kN)^2\n', var_filt_empirical);
fprintf('Filtered Delay-Compensated SNR        : %.2f dB\n', SNR_filt_dB);
fprintf('Net Telemetry SNR Improvement         : +%.2f dB\n\n', SNR_filt_dB - SNR_raw_dB);


%% Level 4: Challenge
% -------------------------------------------------------------------------
% Problem 4: Reliability Modeling of an Aircraft Quad-Redundant Hydraulic System
% Commercial airliners use a quad-redundant hydraulic architecture (4 parallel
% hydraulic pumps: Pump A, B, C, D) to power primary flight control surfaces 
% (elevators, ailerons, rudder).
%
% Safety Architecture:
%   - The system is a 2-out-of-4 system: Safe aircraft control requires 
%     AT LEAST 2 pumps operational.
%   - If 3 or 4 pumps fail (fewer than 2 pumps running), hydraulic pressure 
%     is lost, resulting in catastrophic flight control loss.
%   - Each individual pump has an exponential failure distribution with 
%     MTBF = 10,000 flight hours (lambda = 1 / 10,000 hr^-1).
%   - Individual component survival probability: R(t) = exp(-lambda * t).
%
% Tasks:
%   1. Analytical Survival Function: Derive and compute the system survival 
%      probability R_sys(t) at t = 5,000 flight hours using the binomial formula:
%        R_sys(t) = sum_{k=2}^4 nchoosek(4, k) * R(t)^k * (1 - R(t))^(4 - k)
%   2. Large-Scale Monte Carlo Simulation (N = 50,000 aircraft):
%      Generate random failure times for all 4 pumps: T = -ln(U) / lambda.
%      For each aircraft, the system fails when the THIRD pump fails (i.e.
%      the second-largest failure time among the 4 pumps).
%      Estimate simulated survival probability at t = 5,000 hours.
%   3. System MTBF Estimation:
%      Analytical MTBF for a 2-out-of-4 exponential system is:
%        MTBF_sys = (1 / lambda) * (1/2 + 1/3 + 1/4) = (13 / 12) * MTBF_pump
%      Compare this analytical value with the sample mean of Monte Carlo failure times.
%   4. Regulatory Safety Compliance:
%      The FAA requires loss of control probability P_loss <= 1.0e-4 (0.01%) 
%      at a routine scheduled maintenance inspection interval of t = 1,000 flight hours.
%      Evaluate whether the quad-redundant system meets this airworthiness directive.
% -------------------------------------------------------------------------

MTBF_single_pump = 10000.0; % Single pump MTBF [flight hours]
lambda_pump = 1.0 / MTBF_single_pump;
t_mission   = 5000.0;       % Evaluation mission duration [hours]

% TODO: Task 4.1 - Analytical Survival at t = 5,000 hours
% Compute single pump reliability R_p = exp(-lambda_pump * t_mission)
R_p_5k = 0; % Replace with exp(-lambda_pump * t_mission)

% Compute R_sys_analytical_5k using 2-out-of-4 binomial expansion:
% P(k = 4) = R_p^4
% P(k = 3) = 4 * R_p^3 * (1 - R_p)
% P(k = 2) = 6 * R_p^2 * (1 - R_p)^2
R_sys_analytical_5k = 0; % Replace with your code

% TODO: Task 4.2 - Monte Carlo Simulation (N_sim = 50,000 aircraft)
N_aircraft = 50000;
rng(444); % Reproducible seed

% Generate failure times for 4 pumps across N_aircraft simulations
% Matrix size: 4 x N_aircraft
T_pumps_sim = []; % Replace with -log(rand(4, N_aircraft)) ./ lambda_pump

% Sort pump failure times in ascending order for each aircraft
% Row 1: 1st pump to fail
% Row 2: 2nd pump to fail
% Row 3: 3rd pump to fail -> System drops to 1 pump remaining -> SYSTEM FAILS!
T_pumps_sorted = []; % Replace with sort(T_pumps_sim, 1)
T_system_fail  = []; % Replace with row 3: T_pumps_sorted(3, :)

% Estimate simulated survival probability at t = 5,000 hours
R_sys_mc_5k = 0; % Replace with mean(T_system_fail > t_mission)

% TODO: Task 4.3 - System MTBF Comparison
% Analytical: MTBF_sys = MTBF_single_pump * (1/2 + 1/3 + 1/4)
MTBF_sys_analytical = 0; % Replace with your code
MTBF_sys_mc         = 0; % Replace with mean(T_system_fail)

% TODO: Task 4.4 - FAA Airworthiness Compliance at t = 1,000 hours
t_faa = 1000.0;
R_p_faa = exp(-lambda_pump * t_faa);
% Compute system survival at t = 1,000 hrs:
R_sys_faa = 0; % Replace with 2-out-of-4 reliability at t_faa
P_loss_faa = 1.0 - R_sys_faa; % Probability of hydraulic loss
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
