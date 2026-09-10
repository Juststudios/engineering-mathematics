%% mini_project_signal_calc.m
% =========================================================================
% MATLAB Fundamentals: Mini-Project - Industrial Vibration Telemetry Pipeline
% =========================================================================
% Engineering Scenario:
% You are a Condition Monitoring Engineer at an electric powertrain test
% facility. A 3-phase AC permanent magnet synchronous motor (PMSM) is undergoing
% accelerated endurance testing on a high-speed dynamometer.
%
% An industrial piezoelectric accelerometer is mounted on the drive-end bearing
% housing. The sensor is interfaced to a 12-bit Analog-to-Digital Converter (ADC).
%
% Your Mission:
% Build an automated MATLAB processing pipeline that:
%   1. Generates realistic sensor telemetry: Multi-harmonic vibration signal
%      (30 Hz shaft rotation, 120 Hz 4th harmonic bearing fault tone, 600 Hz
%      inverter PWM switching noise, plus Gaussian white noise and sensor DC drift).
%   2. Simulates ADC quantization (12-bit, 0-3.3V full scale).
%   3. Implements two-point linear sensor calibration: raw ADC counts -> Volts -> Acceleration (g).
%   4. Applies a zero-phase moving-average digital smoothing filter vectorially.
%   5. Computes statistical energy metrics: Mean offset, Standard Deviation,
%      RMS Vibration Severity, Peak-to-Peak amplitude, and Crest Factor.
%   6. Performs Fast Fourier Transform (FFT) spectral analysis to identify
%      the dominant fault frequencies.
%   7. Evaluates vibration severity against ISO 10816-3 industrial standards.
%   8. Plots a publication-ready 4-panel condition monitoring dashboard.
% =========================================================================

clearvars;
close all;
clc;

fprintf('=================================================================\n');
fprintf(' MINI-PROJECT: INDUSTRIAL VIBRATION SIGNAL TELEMETRY PIPELINE\n');
fprintf(' Electric Powertrain Bearing Condition Monitoring System\n');
fprintf('=================================================================\n\n');

%% 1. Simulation Parameters & Sampling Grid
fs = 4000;                      % Sampling frequency [Hz] (Nyquist limit = 2000 Hz)
dt = 1 / fs;                    % Sampling interval [s]
T_total = 1.0;                  % Observation window duration [s]
t = 0 : dt : (T_total - dt);    % Discrete time vector (4000 samples)
N = length(t);                  % Number of samples

fprintf('--- STEP 1: SAMPLING GRID CONFIGURATION ---\n');
fprintf('Sampling Frequency (fs) : %d Hz\n', fs);
fprintf('Total Acquisition Time  : %4.2f seconds\n', T_total);
fprintf('Total Telemetry Samples : %d data points\n\n', N);

%% 2. Synthetic Physical Signal Generation
% Physical components:
%   - Shaft rotational unbalance tone : f1 = 30 Hz (1800 RPM), amplitude = 2.5 g
%   - Outer race bearing fault tone   : f2 = 120 Hz (4x unbalance), amplitude = 1.8 g
%   - Inverter PWM switching ripple   : f3 = 600 Hz, amplitude = 0.6 g
%   - Sensor DC drift offset          : +0.35 g
%   - Wideband sensor thermal noise   : Gaussian white noise (sigma = 0.4 g)

rng(42); % Seed random number generator for reproducible engineering analysis

true_vibration_g = 0.35 + ...
    2.5 .* sin(2 * pi * 30 .* t) + ...
    1.8 .* sin(2 * pi * 120 .* t + pi/4) + ...
    0.6 .* sin(2 * pi * 600 .* t) + ...
    0.4 .* randn(size(t));

%% 3. Hardware Transduction & ADC Quantization Model
% Transducer calibration parameters:
% Accelerometer sensitivity : S = 100.0 mV/g = 0.100 V/g
% Zero-g bias voltage       : V_bias = 1.650 V (Center of 3.3V rail)
% Sensor Voltage Output     : V_sensor = V_bias + a * S
% ADC: 12-bit quantization  : 0 to 4095 counts for 0.0V to 3.3V full-scale

S_volt_per_g = 0.100;     % Transducer sensitivity [V/g]
V_bias_actual = 1.650;    % Hardware bias offset [V]
V_ref = 3.300;            % ADC full-scale reference [V]
ADC_levels = 4095;        % 2^12 - 1 quantization bins

% Analog sensor voltage output (clamped between 0 and V_ref to prevent damage)
v_analog = V_bias_actual + true_vibration_g .* S_volt_per_g;
v_analog_clamped = min(max(v_analog, 0.0), V_ref);

% Quantize to discrete 12-bit integer counts: uint16
raw_adc_counts = uint16(round((v_analog_clamped ./ V_ref) .* ADC_levels));

fprintf('--- STEP 2: TRANSDUCTION & ADC ACQUISITION ---\n');
fprintf('First 5 Raw ADC integer counts:\n  ');
fprintf('%d  ', raw_adc_counts(1:5));
fprintf('\nADC bit resolution: 12 bits (Quantization step size = %6.4f mV)\n\n', ...
    (V_ref / ADC_levels) * 1000);

%% 4. Vectorized Sensor Calibration Pipeline
% In software, the engineer receives raw_adc_counts. We must invert the
% transduction chain back into physical acceleration in g units.
%
% Step 4.1: Convert ADC integer counts to Volts
v_measured = (double(raw_adc_counts) ./ ADC_levels) .* V_ref;

% Step 4.2: Invert sensor sensitivity to obtain calibrated acceleration [g]
% a_calibrated = (v_measured - V_bias) / S
a_calibrated_g = (v_measured - V_bias_actual) ./ S_volt_per_g;

% Verification check: Calibration accuracy
cal_error_rms = sqrt(mean((a_calibrated_g - true_vibration_g) .^ 2));
fprintf('--- STEP 3: CALIBRATION ACCURACY ---\n');
fprintf('ADC Quantization Root-Mean-Square Error: %6.4f g\n\n', cal_error_rms);

%% 5. Vectorized Digital Smoothing Filter (Moving Average)
% High-frequency inverter switching noise (600 Hz) can be smoothed out
% using an N-point FIR moving-average filter.
% y[n] = (1/M) * sum_{k=0}^{M-1} x[n-k]
% We use MATLAB's built-in vector convolution 'conv' with 'same' sizing.

filter_window_size = 15; % 15-sample moving average filter
filter_kernel = ones(1, filter_window_size) ./ filter_window_size;
a_filtered_g = conv(a_calibrated_g, filter_kernel, 'same');

fprintf('--- STEP 4: DIGITAL FILTERING ---\n');
fprintf('Applied %d-point moving-average FIR smoothing filter.\n\n', filter_window_size);

%% 6. Statistical Energy & Vibration Severity Metrics
% Compute standard industrial vibration condition indicators:
%   - Mean acceleration (reveals sensor mounting tilt or DC drift)
%   - Standard deviation (AC vibration dynamic intensity)
%   - RMS Acceleration (Root-Mean-Square energy severity)
%   - Peak-to-Peak amplitude (Shock envelope)
%   - Crest Factor = Peak / RMS (High crest factor indicates localized bearing impacts)

mean_accel = mean(a_filtered_g);
std_accel  = std(a_filtered_g);
rms_accel  = sqrt(mean(a_filtered_g .^ 2));
peak_val   = max(abs(a_filtered_g));
ptp_val    = max(a_filtered_g) - min(a_filtered_g);
crest_factor = peak_val / rms_accel;

fprintf('--- STEP 5: VIBRATION TELEMETRY STATISTICAL METRICS ---\n');
fprintf('Mean DC Offset         : %6.3f g\n', mean_accel);
fprintf('Standard Deviation     : %6.3f g\n', std_accel);
fprintf('RMS Vibration Severity : %6.3f g (%6.2f m/s^2)\n', ...
    rms_accel, rms_accel * 9.80665);
fprintf('Peak-to-Peak Amplitude : %6.3f g\n', ptp_val);
fprintf('Crest Factor           : %6.3f\n\n', crest_factor);

%% 7. Frequency Domain Spectral Analysis (FFT)
% Convert the time-domain signal into the frequency domain to identify
% individual machine vibration harmonics.
%
% Fast Fourier Transform mathematics:
%   Y = fft(x)
%   Two-sided spectrum: P2 = abs(Y / N)
%   Single-sided spectrum: P1 = P2(1:N/2+1), multiplied by 2 (except DC and Nyquist)
%   Frequency grid: f = fs * (0:(N/2)) / N

Y_fft = fft(a_calibrated_g);
P2 = abs(Y_fft ./ N);
P1 = P2(1 : floor(N/2) + 1);
P1(2 : end-1) = 2 .* P1(2 : end-1); % Conserve spectral energy for positive frequencies
f_axis = fs .* (0 : floor(N/2)) ./ N;

% Find dominant frequency peaks in the spectrum (frequencies with amplitude > 0.5 g)
dominant_mask = (P1 > 0.5) & (f_axis > 5); % Ignore DC offset below 5 Hz
dominant_freqs = f_axis(dominant_mask);
dominant_amps  = P1(dominant_mask);

fprintf('--- STEP 6: FAST FOURIER TRANSFORM SPECTRAL PEAKS ---\n');
fprintf('Identified Dominant Vibration Harmonics:\n');
for idx = 1:length(dominant_freqs)
    fprintf('  Harmonic %d: Frequency = %6.1f Hz, Amplitude = %5.2f g\n', ...
        idx, dominant_freqs(idx), dominant_amps(idx));
end
fprintf('\n');

%% 8. Automated ISO 10816-3 Industrial Health Assessment
% ISO 10816-3 classifies vibration severity for industrial machinery:
% For rigid foundation Class II/III medium electric machines:
%   Zone A (Good)        : RMS < 1.4 g equivalent
%   Zone B (Acceptable)  : 1.4 <= RMS < 2.8 g
%   Zone C (Alert)       : 2.8 <= RMS < 4.5 g
%   Zone D (Danger/Trip) : RMS >= 4.5 g

fprintf('--- STEP 7: ISO 10816 VIBRATION SEVERITY EVALUATION ---\n');
if rms_accel < 1.4
    iso_status = "ZONE A: GOOD (Normal Operation)";
    action_item = "No maintenance required. Routine monitoring.";
elseif rms_accel < 2.8
    iso_status = "ZONE B: ACCEPTABLE (Satisfactory)";
    action_item = "Machine operable for long-term service. Re-inspect next quarter.";
elseif rms_accel < 4.5
    iso_status = "ZONE C: ALERT (Unrestricted Long-Term Operation Restricted)";
    action_item = "Schedule corrective maintenance. Inspect bearing outer race.";
else
    iso_status = "ZONE D: DANGER / CRITICAL (Damage Incurred)";
    action_item = "IMMEDIATE TRIP REQUIRED! Severe vibration hazard.";
end

fprintf('Assessed Health Status : %s\n', iso_status);
fprintf('Recommended Action     : %s\n\n', action_item);

%% 9. Multi-Panel Condition Monitoring Dashboard Visualization
h_dash = figure('Name', 'Electric Powertrain Vibration Telemetry Dashboard', ...
    'NumberTitle', 'off', 'Units', 'normalized', 'Position', [0.1, 0.1, 0.8, 0.8]);

% Panel 1: Raw 12-bit ADC Integer Counts
subplot(2, 2, 1);
plot(t(1:200) * 1000, raw_adc_counts(1:200), 'k-', 'LineWidth', 1.2);
grid on;
title('1. Raw ADC Telemetry (12-bit Quantized)', 'FontSize', 11, 'FontWeight', 'bold');
xlabel('Time [ms]');
ylabel('ADC Counts [0 - 4095]');
ylim([1000, 3200]);

% Panel 2: Calibrated vs. Filtered Acceleration
subplot(2, 2, 2);
plot(t(1:200) * 1000, a_calibrated_g(1:200), 'Color', [0.7, 0.7, 0.7], 'LineWidth', 1.0);
hold on;
plot(t(1:200) * 1000, a_filtered_g(1:200), 'b-', 'LineWidth', 1.8);
hold off;
grid on;
title('2. Calibrated Acceleration & FIR Smoothed Waveform', 'FontSize', 11, 'FontWeight', 'bold');
xlabel('Time [ms]');
ylabel('Acceleration [g]');
legend('Raw Calibrated', '15-pt Smoothed', 'Location', 'northeast');

% Panel 3: FFT Frequency Spectrum (0 to 1000 Hz)
subplot(2, 2, 3);
plot(f_axis, P1, 'r-', 'LineWidth', 1.5);
grid on;
xlim([0, 1000]);
title('3. Single-Sided FFT Amplitude Spectrum', 'FontSize', 11, 'FontWeight', 'bold');
xlabel('Frequency [Hz]');
ylabel('Vibration Amplitude [g]');
% Annotate key peaks
text(30, 2.5, ' \leftarrow 30 Hz (Shaft Unbalance)', 'FontSize', 9, 'FontWeight', 'bold');
text(120, 1.8, ' \leftarrow 120 Hz (Bearing Fault)', 'FontSize', 9, 'FontWeight', 'bold');
text(600, 0.6, ' \leftarrow 600 Hz (Inverter PWM)', 'FontSize', 9, 'FontWeight', 'bold');

% Panel 4: Health Metrics Summary & ISO Barometer
subplot(2, 2, 4);
axis off; % Clean text scorecard display
scorecard_text = {
    '\bf\fontsize{12}CONDITION MONITORING HEALTH SCORECARD', ...
    '-------------------------------------------------------', ...
    sprintf('Peak Vibration Amplitude : %5.2f g', peak_val), ...
    sprintf('RMS Energy Severity      : %5.2f g (%5.2f m/s^2)', rms_accel, rms_accel*9.81), ...
    sprintf('Bearing Crest Factor     : %5.2f', crest_factor), ...
    sprintf('Dominant Shaft Speed     : %5.1f Hz (1800 RPM)', 30.0), ...
    sprintf('Bearing Fault Frequency  : %5.1f Hz (4X Harm)', 120.0), ...
    '-------------------------------------------------------', ...
    sprintf('\\bfISO 10816 Status: \\rm%s', iso_status), ...
    sprintf('\\bfPrescription:    \\rm%s', action_item)
};
text(0.05, 0.5, scorecard_text, 'FontSize', 10, 'VerticalAlignment', 'middle');

fprintf('Dashboard visualization successfully created.\n');
fprintf('=================================================================\n');
fprintf(' mini_project_signal_calc.m execution completed successfully.\n');
