%% 02_distributions_and_moments.m - Statistical Distributions & Moments
% =========================================================================
% MODULE: Probability & Uncertainty in Engineering (R4)
% TOPIC : Uniform, Binomial, and Normal Distributions; Moments & 68-95-99.7 Rule
%
% ENGINEERING CONTEXT:
% Precision manufacturing requires tight control over physical dimensions, 
% material strength, and electronic tolerances. Resistors fluctuate around 
% nominal resistance, CNC milling machines cut shafts with microscopic 
% deviations, and Analog-to-Digital Converters (ADCs) introduce quantization 
% uncertainty. Engineers use probability distributions to model these physical 
% dispersions and compute process capability metrics (Six Sigma).
%
% This script demonstrates:
%   1. Continuous Uniform Distribution & ADC Quantization Noise
%   2. Discrete Binomial Distribution in Batch Quality Control
%   3. Gaussian (Normal) Distribution & the Empirical 68-95-99.7 Rule
%   4. Statistical Moments & Bessel's Correction (Unbiased N-1 vs Biased N)
%   5. Industrial Process Capability Analysis (Cp, Cpk, and Defect PPM)
% =========================================================================

clear;
close all;
clc;

fprintf('=================================================================\n');
fprintf('  ENGINEERING DISTRIBUTIONS, MOMENTS & PROCESS CAPABILITY         \n');
fprintf('=================================================================\n\n');

%% Section 1: Uniform Distribution & ADC Quantization Noise
% An Analog-to-Digital Converter (ADC) digitizes a continuous sensor voltage.
% Due to finite resolution, the quantization round-off error e_q is uniformly
% distributed between -Delta/2 and +Delta/2, where Delta = V_ref / (2^Bits - 1).

V_ref = 3.3;             % ADC full-scale reference voltage [V]
Bits  = 12;              % 12-bit ADC resolution
Delta = V_ref / (2^Bits - 1); % Least Significant Bit (LSB) step size [V]

% Uniform error bounds: [a, b]
a_quant = -Delta / 2.0;
b_quant =  Delta / 2.0;

% Theoretical moments for Uniform U(a, b):
% Mean: E[X] = (a + b) / 2
% Variance: Var[X] = (b - a)^2 / 12
% Standard Deviation: sigma = Delta / sqrt(12)
mean_quant_exact = (a_quant + b_quant) / 2.0; % Exactly 0.0 V
var_quant_exact  = ((b_quant - a_quant)^2) / 12.0;
std_quant_exact  = sqrt(var_quant_exact);

% Monte Carlo simulation of ADC quantization errors
N_adc = 100000;
rng(202);
% rand() produces numbers in [0, 1]; scale to [a, b]
e_sim = a_quant + (b_quant - a_quant) .* rand(1, N_adc);

mean_quant_sim = mean(e_sim);
var_quant_sim  = var(e_sim); % Default: N-1 denominator
std_quant_sim  = std(e_sim);

fprintf('--- 1. UNIFORM DISTRIBUTION: ADC QUANTIZATION NOISE ---\n');
fprintf('ADC Step Size (Delta / LSB)        : %.4f mV\n', Delta * 1000.0);
fprintf('Theoretical Quantization Mean      : %.4f V\n', mean_quant_exact);
fprintf('Simulated Sample Mean              : %.4f V (Error: %.2e V)\n', ...
    mean_quant_sim, abs(mean_quant_sim - mean_quant_exact));
fprintf('Theoretical RMS Noise (sigma)      : %.4f mV\n', std_quant_exact * 1000.0);
fprintf('Simulated RMS Noise (std dev)      : %.4f mV\n\n', std_quant_sim * 1000.0);


%% Section 2: Discrete Binomial Distribution in Batch Quality Control
% Surface Mount Technology (SMT) resistors are placed onto circuit boards.
% Each resistor has an independent defect probability p = 0.02 (2.0%).
% A quality inspector samples n = 60 components per production lot.
% Number of defective components K follows a Binomial distribution B(n, p):
%   P(K = k) = nchoosek(n, k) * p^k * (1 - p)^(n - k)

n_lot = 60;   % Batch sample size
p_def = 0.02; % Probability of defective component

% Theoretical Binomial moments:
% Mean: E[K] = n * p
% Variance: Var[K] = n * p * (1 - p)
mu_bin_exact  = n_lot * p_def;
var_bin_exact = n_lot * p_def * (1.0 - p_def);
std_bin_exact = sqrt(var_bin_exact);

% Compute analytical PMF for k = 0, 1, 2, 3, 4, 5
k_vals = 0:5;
P_k_exact = zeros(size(k_vals));
for idx = 1:length(k_vals)
    k = k_vals(idx);
    P_k_exact(idx) = nchoosek(n_lot, k) * (p_def^k) * ((1.0 - p_def)^(n_lot - k));
end

% Lot Acceptance Criterion: Accept lot if k <= 2 defective components
P_accept_lot = sum(P_k_exact(k_vals <= 2));

% Monte Carlo simulation of 50,000 inspected lots
N_lots_sim = 50000;
% Each lot has n_lot Bernoulli trials
defects_per_lot = sum(rand(n_lot, N_lots_sim) < p_def, 1);

mu_bin_sim = mean(defects_per_lot);
var_bin_sim = var(defects_per_lot);
P_accept_sim = mean(defects_per_lot <= 2);

fprintf('--- 2. BINOMIAL DISTRIBUTION: BATCH QUALITY CONTROL ---\n');
fprintf('Batch Size n = %d, Defect Rate p = %.2f%%\n', n_lot, p_def * 100.0);
fprintf('Expected Defective Count E[K]      : %.4f (Simulated: %.4f)\n', ...
    mu_bin_exact, mu_bin_sim);
fprintf('Theoretical Defective Std Dev      : %.4f (Simulated: %.4f)\n', ...
    std_bin_exact, sqrt(var_bin_sim));
fprintf('Analytical Lot Acceptance P(K <= 2): %.2f%%\n', P_accept_lot * 100.0);
fprintf('Simulated Lot Acceptance Rate      : %.2f%%\n\n', P_accept_sim * 100.0);


%% Section 3: Gaussian (Normal) Distribution & the 68-95-99.7 Rule
% A precision CNC lathe turns stainless steel hydraulic actuator rods.
% Target diameter: mu = 25.00 mm
% Manufacturing process standard deviation: sigma = 0.04 mm (40 micrometers)
% Diameter X ~ N(mu, sigma^2)

mu_rod = 25.00;   % Nominal diameter [mm]
sigma_rod = 0.04; % Process standard deviation [mm]

N_rods = 200000;
rng(303);
% randn() produces standard normal N(0, 1); scale and shift:
diameters = mu_rod + sigma_rod .* randn(1, N_rods);

% Empirical 68-95-99.7% Rule Evaluation
% Interval 1: [mu - 1*sigma, mu + 1*sigma] (Theoretical: 68.2689%)
within_1sig = mean(abs(diameters - mu_rod) <= 1.0 * sigma_rod);

% Interval 2: [mu - 2*sigma, mu + 2*sigma] (Theoretical: 95.4499%)
within_2sig = mean(abs(diameters - mu_rod) <= 2.0 * sigma_rod);

% Interval 3: [mu - 3*sigma, mu + 3*sigma] (Theoretical: 99.7300%)
within_3sig = mean(abs(diameters - mu_rod) <= 3.0 * sigma_rod);

% Theoretical values via Gaussian error function erf()
% P(|X - mu| <= k*sigma) = erf(k / sqrt(2))
p_1sig_theory = erf(1.0 / sqrt(2.0));
p_2sig_theory = erf(2.0 / sqrt(2.0));
p_3sig_theory = erf(3.0 / sqrt(2.0));

fprintf('--- 3. GAUSSIAN DISTRIBUTION & 68-95-99.7 EMPIRICAL RULE ---\n');
fprintf('Nominal mu = %.2f mm, sigma = %.4f mm (N = %d rods)\n', ...
    mu_rod, sigma_rod, N_rods);
fprintf('1-Sigma Coverage [24.96, 25.04] mm: Actual = %.4f%% | Theory = %.4f%%\n', ...
    within_1sig * 100.0, p_1sig_theory * 100.0);
fprintf('2-Sigma Coverage [24.92, 25.08] mm: Actual = %.4f%% | Theory = %.4f%%\n', ...
    within_2sig * 100.0, p_2sig_theory * 100.0);
fprintf('3-Sigma Coverage [24.88, 25.12] mm: Actual = %.4f%% | Theory = %.4f%%\n\n', ...
    within_3sig * 100.0, p_3sig_theory * 100.0);


%% Section 4: Statistical Moments & Bessel's Correction
% Why do engineers divide by N-1 rather than N when calculating sample variance?
% When the true population mean mu is unknown, using the sample mean x_bar 
% consumes 1 degree of freedom, systematically underestimating variance.
%
% Bessel's correction:
%   s_unbiased^2 = (1 / (N - 1)) * sum((x_i - x_bar)^2)   [E[s^2] = sigma^2]
%   s_biased^2   = (1 / N)       * sum((x_i - x_bar)^2)   [E[s^2] = (N-1)/N * sigma^2]

N_small = 6;            % Small batch sample size
N_experiments = 100000; % Repeat 100,000 small batch inspections
sigma_true = 2.5;       % True population standard deviation
var_true   = sigma_true^2;

% Simulate 100,000 small batches of size 6
small_samples = sigma_true .* randn(N_small, N_experiments);

% Compute sample variances with both formulas
% var(x, 0) -> N - 1 denominator (unbiased)
% var(x, 1) -> N denominator (biased)
var_unbiased_samples = var(small_samples, 0, 1);
var_biased_samples   = var(small_samples, 1, 1);

mean_var_unbiased = mean(var_unbiased_samples);
mean_var_biased   = mean(var_biased_samples);
expected_biased   = ((N_small - 1) / N_small) * var_true;

fprintf('--- 4. BESSEL''S CORRECTION DEMONSTRATION (N = %d) ---\n', N_small);
fprintf('True Population Variance sigma^2   : %.4f\n', var_true);
fprintf('Unbiased Estimator E[s^2] (N - 1)  : %.4f (Matches true variance)\n', ...
    mean_var_unbiased);
fprintf('Biased Estimator E[s^2] (N)        : %.4f (Underestimates variance!)\n', ...
    mean_var_biased);
fprintf('Theoretical Biased Expectation     : %.4f ((N-1)/N * sigma^2)\n', ...
    expected_biased);
fprintf('Relative Bias Percentage           : %.2f%%\n\n', ...
    ((mean_var_biased - var_true) / var_true) * 100.0);


%% Section 5: Process Capability Analysis (Cp, Cpk, and Defect PPM)
% An aerospace client specifies tolerances on hydraulic rod diameter:
%   Lower Specification Limit (LSL): 24.85 mm
%   Upper Specification Limit (USL): 25.15 mm
% Tolerance band T = USL - LSL = 0.30 mm

LSL = 24.85;
USL = 25.15;

% 1. Process Capability Index (Cp): Potential capability if centered
% Cp = (USL - LSL) / (6 * sigma)
Cp = (USL - LSL) / (6.0 * sigma_rod);

% 2. Process Capability Index (Cpk): Accounts for centering off-target
% Cpk = min((USL - mu) / (3*sigma), (mu - LSL) / (3*sigma))
Cpu = (USL - mu_rod) / (3.0 * sigma_rod);
Cpl = (mu_rod - LSL) / (3.0 * sigma_rod);
Cpk = min(Cpu, Cpl);

% 3. Calculate Defect Rate in Parts Per Million (PPM)
% Standardized Z-scores:
Z_upper = (USL - mu_rod) / sigma_rod;
Z_lower = (LSL - mu_rod) / sigma_rod;

% Probability of defect (outside spec):
% P(X > USL) + P(X < LSL)
p_defect_upper = 0.5 * erfc(Z_upper / sqrt(2.0));
p_defect_lower = 0.5 * erfc(-Z_lower / sqrt(2.0));
p_defect_total = p_defect_upper + p_defect_lower;
ppm_defect = p_defect_total * 1e6;

fprintf('--- 5. SIX SIGMA PROCESS CAPABILITY & QUALITY METRICS ---\n');
fprintf('Tolerance Window [LSL, USL]        : [%.2f, %.2f] mm (Width = %.2f mm)\n', ...
    LSL, USL, USL - LSL);
fprintf('Process Capability Index Cp        : %.3f (Target: >= 1.33 for Six Sigma)\n', Cp);
fprintf('Process Centering Index Cpk        : %.3f\n', Cpk);
fprintf('Predicted Defect Rate              : %.4e (%.2f PPM)\n', ...
    p_defect_total, ppm_defect);
if Cpk >= 1.33
    fprintf('Engineering Verdict                : Process is CAPABLE and APPROVED for flight.\n');
else
    fprintf('Engineering Verdict                : Process NOT CAPABLE. Tool recalibration required.\n');
end
fprintf('=================================================================\n');
