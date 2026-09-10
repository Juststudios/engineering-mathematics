%% 04_sensor_noise_filtering.m - Sensor Noise Modeling & Digital Filtering
% =========================================================================
% MODULE: Probability & Uncertainty in Engineering (R4)
% TOPIC : Additive White Gaussian Noise (AWGN), SNR & Moving-Average Filtering
%
% ENGINEERING CONTEXT:
% All electronic transducers (thermocouples, RTDs, strain gauges, piezoelectric
% accelerometers) produce noisy signals due to thermal Johnson-Nyquist noise,
% 50/60 Hz mains electromagnetic interference (EMI), and digitization. 
% Embedded control systems and state estimators cannot act on raw noisy telemetry 
% without chattering or destabilizing. Digital filtering suppresses high-frequency 
% noise while preserving the underlying physical dynamics.
%
% This script demonstrates:
%   1. Synthesizing Ground-Truth Sensor Telemetry & Computing Signal Power
%   2. Modeling Additive White Gaussian Noise (AWGN) & Calculating SNR (dB)
%   3. Digital Moving-Average Filtering via filter() and Convolution
%   4. Mathematical Proof & Empirical Verification of Variance Reduction (sigma^2 / W)
%   5. Filter Phase Lag, Delay Compensation, and Window Size Optimization
% =========================================================================

clear;
close all;
clc;

fprintf('=================================================================\n');
fprintf('  SENSOR NOISE MODELING & MOVING-AVERAGE FILTERING IN MATLAB     \n');
fprintf('=================================================================\n\n');

%% Section 1: Synthesizing Ground-Truth Sensor Telemetry
% Consider an industrial turbine bearing thermocouple measuring transient heatup.
% The true underlying physical temperature profile combines an exponential thermal
% rise with a periodic harmonic component caused by turbine rotation:
%   s(t) = T_ambient + Delta_T * (1 - exp(-t / tau_th)) + A_rot * sin(2*pi*f_rot*t)

fs = 200.0;           % Sampling frequency [Hz]
dt = 1.0 / fs;        % Sampling interval [s] (5 milliseconds)
t_end = 10.0;         % Observation duration [s]
t = 0.0:dt:t_end;     % Time vector
N_samples = length(t);

% Physical parameters
T_ambient = 25.0;     % Initial ambient temperature [deg C]
Delta_T   = 60.0;     % Asymptotic steady-state temperature rise [deg C]
tau_th    = 2.5;      % Thermal time constant [s]
A_rot     = 2.0;      % Rotational thermal oscillation amplitude [deg C]
f_rot     = 1.0;      % Rotational frequency [Hz]

% Ground-truth deterministic signal s(t)
s_clean = T_ambient + Delta_T .* (1.0 - exp(-t ./ tau_th)) + ...
          A_rot .* sin(2.0 * pi * f_rot .* t);

% Calculate clean signal mean and AC signal power
mu_sig = mean(s_clean);
% AC signal power (variance of signal without DC offset):
P_sig_ac = mean((s_clean - mu_sig).^2);
% Total signal power:
P_sig_total = mean(s_clean.^2);

fprintf('--- 1. GROUND TRUTH SENSOR TELEMETRY ---\n');
fprintf('Sampling Frequency fs              : %.1f Hz (dt = %.4f s)\n', fs, dt);
fprintf('Total Telemetry Samples N          : %d\n', N_samples);
fprintf('Steady-State Final Temperature     : %.2f deg C\n', s_clean(end));
fprintf('Total Signal Power P_sig           : %.2f (deg C)^2\n', P_sig_total);
fprintf('AC Signal Power P_sig_ac           : %.2f (deg C)^2\n\n', P_sig_ac);


%% Section 2: Additive White Gaussian Noise (AWGN) Modeling & SNR
% High-frequency electromagnetic noise w(t) corrupts the measurement:
%   w(t) ~ N(0, sigma_noise^2)
%   x(t) = s(t) + w(t)

sigma_noise = 3.5;    % Noise standard deviation [deg C]
var_noise = sigma_noise^2;

rng(707); % Fixed seed for deterministic verification
noise_raw = sigma_noise .* randn(1, N_samples);
x_noisy   = s_clean + noise_raw;

% Compute Signal-to-Noise Ratio (SNR)
% SNR_linear = P_sig_ac / Var(noise)
% SNR_dB = 10 * log10(SNR_linear)
SNR_linear_raw = P_sig_ac / var_noise;
SNR_dB_raw     = 10.0 * log10(SNR_linear_raw);

% Root-Mean-Square Error (RMSE) of raw signal relative to clean signal
rmse_raw = sqrt(mean((x_noisy - s_clean).^2));

fprintf('--- 2. RAW NOISE CORRUPTION & SNR CALCULATION ---\n');
fprintf('Noise Standard Deviation sigma     : %.2f deg C\n', sigma_noise);
fprintf('True Noise Variance sigma^2        : %.2f (deg C)^2\n', var_noise);
fprintf('Empirical Sample Noise Variance    : %.2f (deg C)^2\n', var(noise_raw));
fprintf('Raw Telemetry SNR (Linear Scale)   : %.3f\n', SNR_linear_raw);
fprintf('Raw Telemetry SNR (Decibel Scale)  : %.2f dB\n', SNR_dB_raw);
fprintf('Raw Measurement RMSE               : %.4f deg C (Theory: %.4f)\n\n', ...
    rmse_raw, sigma_noise);


%% Section 3: Digital Moving-Average Filter Formulation
% A causal moving-average filter averages the most recent W samples:
%   y[k] = (1 / W) * sum_{j=0}^{W-1} x[k - j]
%
% In discrete filter notation:
%   Numerator coefficients:   b = (1 / W) * ones(1, W)
%   Denominator coefficients: a = 1.0
%   y = filter(b, a, x)

W = 15; % Filter window size (odd integer)
b_coeff = ones(1, W) ./ W;
a_coeff = 1.0;

% Execute causal moving-average filter via filter()
y_causal = filter(b_coeff, a_coeff, x_noisy);

% -------------------------------------------------------------------------
% Mathematical Proof of Noise Variance Reduction:
% For W independent identically distributed (i.i.d.) noise samples w_j ~ N(0, sigma^2):
%   Var( (1/W) * sum_{j=1}^W w_j ) = (1 / W^2) * sum_{j=1}^W Var(w_j)
%                                   = (1 / W^2) * (W * sigma^2)
%                                   = sigma^2 / W.
% Therefore, noise variance is reduced by exactly a factor of 1 / W!
% -------------------------------------------------------------------------

% Filter isolated noise vector to isolate noise variance reduction
filtered_noise = filter(b_coeff, a_coeff, noise_raw);

% Exclude initial boundary startup transient (first W-1 samples)
valid_range = W:N_samples;
var_noise_filtered_actual = var(filtered_noise(valid_range));
var_noise_filtered_theory = var_noise / W;

% Theoretical SNR improvement in decibels:
% Delta_SNR_dB = 10 * log10(W)
SNR_improvement_theory_dB = 10.0 * log10(W);

fprintf('--- 3. MOVING-AVERAGE FILTER VARIANCE REDUCTION (W = %d) ---\n', W);
fprintf('Theoretical Filtered Noise Variance: %.4f (deg C)^2 (sigma^2 / W)\n', ...
    var_noise_filtered_theory);
fprintf('Empirical Filtered Noise Variance  : %.4f (deg C)^2\n', ...
    var_noise_filtered_actual);
fprintf('Variance Attenuation Factor        : %.2fx reduction\n', ...
    var_noise / var_noise_filtered_actual);
fprintf('Theoretical SNR Improvement        : +%.2f dB\n\n', SNR_improvement_theory_dB);


%% Section 4: Filter Phase Lag & Time Delay Compensation
% A causal FIR filter introduces a physical group delay of:
%   tau_delay = (W - 1) / 2  samples = (W - 1) / (2 * fs) seconds.
% For real-time applications, this delay is unavoidable.
% For post-processing / telemetry analysis, we align the signal by shifting 
% backwards by tau_delay samples (or using zero-phase filtering).

delay_samples = (W - 1) / 2;
delay_seconds = delay_samples * dt;

% Construct delay-compensated signal for interior points
idx_start = W;
idx_end   = N_samples - delay_samples;

% Uncompensated causal RMSE
rmse_causal = sqrt(mean((y_causal(idx_start:idx_end) - s_clean(idx_start:idx_end)).^2));

% Compensated aligned RMSE: compare y(t + delay) with s_clean(t)
y_aligned = y_causal(idx_start + delay_samples : end);
s_aligned = s_clean(idx_start : end - delay_samples);
rmse_aligned = sqrt(mean((y_aligned - s_aligned).^2));

% Filtered SNR after delay compensation
residual_noise_aligned = y_aligned - s_aligned;
P_residual_noise = mean(residual_noise_aligned.^2);
SNR_linear_filtered = P_sig_ac / P_residual_noise;
SNR_dB_filtered     = 10.0 * log10(SNR_linear_filtered);

fprintf('--- 4. PHASE LAG & DELAY COMPENSATION ---\n');
fprintf('Filter Group Delay                 : %d samples (%.4f seconds)\n', ...
    delay_samples, delay_seconds);
fprintf('Uncompensated Causal RMSE          : %.4f deg C\n', rmse_causal);
fprintf('Delay-Compensated Aligned RMSE     : %.4f deg C (Significant improvement)\n', ...
    rmse_aligned);
fprintf('Filtered Telemetry SNR             : %.2f dB (Raw was %.2f dB)\n', ...
    SNR_dB_filtered, SNR_dB_raw);
fprintf('Net SNR Gain                       : +%.2f dB\n\n', ...
    SNR_dB_filtered - SNR_dB_raw);


%% Section 5: Window Size Optimization: Noise vs Distortion Trade-off
% Increasing window size W suppresses more noise (proportional to 1/W),
% but increases phase lag and smooths out real high-frequency physical dynamics.
% We sweep window sizes W = [3, 7, 15, 31, 61, 101] to find the optimal balance.

candidate_W = [3, 7, 15, 31, 61, 101];
rmse_sweep = zeros(size(candidate_W));

for w_idx = 1:length(candidate_W)
    w_curr = candidate_W(w_idx);
    b_curr = ones(1, w_curr) ./ w_curr;
    y_curr = filter(b_curr, 1.0, x_noisy);
    
    del = (w_curr - 1) / 2;
    eval_start = candidate_W(end);
    eval_end   = N_samples - candidate_W(end);
    
    % Evaluate aligned RMSE over common central window
    y_eval = y_curr(eval_start + del : eval_end + del);
    s_eval = s_clean(eval_start : eval_end);
    
    rmse_sweep(w_idx) = sqrt(mean((y_eval - s_eval).^2));
end

[min_rmse, best_idx] = min(rmse_sweep);
best_W = candidate_W(best_idx);

fprintf('--- 5. WINDOW SIZE OPTIMIZATION SWEEP ---\n');
fprintf('WINDOW SIZE (W)       ALIGNED RMSE       ATTENUATION FACTOR\n');
for w_idx = 1:length(candidate_W)
    fprintf('%12d          %10.4f          %12.2f dB\n', ...
        candidate_W(w_idx), rmse_sweep(w_idx), 10*log10(candidate_W(w_idx)));
end
fprintf('Optimal Window Size W*             : %d (RMSE = %.4f deg C)\n', best_W, min_rmse);
fprintf('=================================================================\n');
