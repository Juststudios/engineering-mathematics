%% 04_scripts_and_functions.m
% =========================================================================
% MATLAB Fundamentals & Computational Environment: Scripts and Functions
% =========================================================================
% Pedagogical Objective:
% This script teaches modular software design in MATLAB. Coming from Python,
% students must understand the distinction between:
%   1. Scripts (which execute in and mutate the base workspace)
%   2. Functions (which operate in private, encapsulated local workspaces)
%   3. Multiple return values ([out1, out2] = func(in1, in2))
%   4. Anonymous functions (@(x) ...) for rapid mathematical modeling
%   5. Input validation and variable argument handling (nargin)
%   6. Local helper functions declared at the bottom of the file
%
% Applied Engineering Context:
% Thermocouple telemetry calibration, thermal transient modeling, and
% statistical signal characterization for an electric vehicle inverter.
% =========================================================================

clearvars;
close all;
clc;

fprintf('====================================================\n');
fprintf(' MODULE 1: SCRIPTS, FUNCTIONS, AND MODULAR DESIGN\n');
fprintf('====================================================\n\n');

%% 1. Anonymous Functions: Quick Mathematical Definitions
% Anonymous functions allow defining inline mathematical models without
% creating separate .m files. Syntax: @(arg1, arg2) expression

% Example A: Steinhart-Hart / Thermistor Resistance-to-Temperature model
% Simplified NTC thermistor linear approximation around 25 deg C:
% T(R) = T0 + (R - R0) * slope
R0 = 10000.0; % 10 kOhm nominal resistance at 25 C
T0 = 25.0;    % Reference temperature [deg C]
temp_model = @(R) T0 - 0.0035 .* (R - R0);

sample_resistances = [12000, 10000, 8000, 6000]; % [Ohms]
computed_temps = temp_model(sample_resistances);

fprintf('--- ANONYMOUS FUNCTION DEMO ---\n');
for k = 1:length(sample_resistances)
    fprintf('  Resistance: %5d Ohms  -->  Temperature: %5.2f deg C\n', ...
        sample_resistances(k), computed_temps(k));
end
fprintf('\n');

%% 2. Calling a User-Defined Function with Multiple Outputs
% In MATLAB, functions can return multiple outputs simultaneously enclosed
% in square brackets: [y1, y2, y3] = my_function(x).
% This is different from Python returning a single tuple that is then unpacked.

% Generate simulated inverter temperature sensor signal (noisy ramp)
N_pts = 100;
time_s = linspace(0, 10, N_pts);
true_temp = 25 + 5.0 .* time_s;              % Temperature ramp from 25 to 75 C
noise = 0.8 .* sin(2*pi*5*time_s) + 0.3*cos(2*pi*12*time_s);
measured_temp = true_temp + noise;

% Call our local helper function: calculate_signal_metrics
[mean_T, std_T, rms_T, peak_to_peak_T] = calculate_signal_metrics(measured_temp);

fprintf('--- FUNCTION WITH MULTIPLE OUTPUTS ---\n');
fprintf('Signal Statistics for Inverter Temperature Telemetry:\n');
fprintf('  Mean Temperature         : %6.2f deg C\n', mean_T);
fprintf('  Standard Deviation       : %6.2f deg C\n', std_T);
fprintf('  Root-Mean-Square (RMS)   : %6.2f deg C\n', rms_T);
fprintf('  Peak-to-Peak Amplitude   : %6.2f deg C\n\n', peak_to_peak_T);

%% 3. Demonstrating Optional Arguments & Default Parameters
% Call calibration function with default reference voltage:
raw_adc = [1000, 2048, 3000, 4000];
calibrated_v_default = calibrate_adc(raw_adc);

% Call calibration function specifying a custom 5.0V ADC reference:
calibrated_v_custom = calibrate_adc(raw_adc, 5.0);

fprintf('--- FUNCTION WITH OPTIONAL ARGUMENTS (nargin) ---\n');
fprintf('Default (3.3V reference) : ');
fprintf('%5.3fV ', calibrated_v_default);
fprintf('\n');
fprintf('Custom  (5.0V reference) : ');
fprintf('%5.3fV ', calibrated_v_custom);
fprintf('\n\n');

%% 4. Workspace Encapsulation: Local vs Base Workspace
% Variables defined inside functions are strictly isolated from the base
% workspace, preventing accidental overwriting of state variables.
caller_variable = 999;
fprintf('Before function call, caller_variable = %d\n', caller_variable);
test_encapsulation(caller_variable);
fprintf('After function call, caller_variable  = %d (Unchanged)\n\n', caller_variable);

fprintf('====================================================\n');
fprintf(' 04_scripts_and_functions.m execution completed successfully.\n');

% =========================================================================
% LOCAL HELPER FUNCTIONS
% In MATLAB scripts, all local functions must be placed at the very end
% of the script file. Each function must conclude with 'end'.
% =========================================================================

function [mu, sigma, rms_val, ptp_val] = calculate_signal_metrics(signal)
    % CALCULATE_SIGNAL_METRICS Computes descriptive statistical metrics.
    %
    % Inputs:
    %   signal  - Numeric vector of time-series measurements
    % Outputs:
    %   mu      - Arithmetic mean
    %   sigma   - Standard deviation
    %   rms_val - Root-mean-square value
    %   ptp_val - Peak-to-peak amplitude (max - min)

    % Validate input is non-empty numeric vector
    if isempty(signal) || ~isnumeric(signal)
        error('Input signal must be a non-empty numeric array.');
    end

    mu      = mean(signal);
    sigma   = std(signal);
    rms_val = sqrt(mean(signal .^ 2));
    ptp_val = max(signal) - min(signal);
end

function voltage = calibrate_adc(counts, v_ref)
    % CALIBRATE_ADC Converts 12-bit ADC integer counts to analog voltage.
    % Demonstrates default parameter handling via nargin.
    %
    % Inputs:
    %   counts - Array of integer ADC counts (0 to 4095)
    %   v_ref  - (Optional) Reference voltage in Volts (Default = 3.3V)

    % Handle optional argument
    if nargin < 2
        v_ref = 3.3; % Standard default microcontroller reference
    end

    max_count = 4095; % 12-bit ADC ceiling
    voltage = (double(counts) ./ max_count) .* v_ref;
end

function test_encapsulation(caller_variable)
    % TEST_ENCAPSULATION Demonstrates local workspace isolation.
    % Modifying caller_variable here has NO effect on the caller's scope.
    caller_variable = -1; 
    fprintf('  Inside test_encapsulation, local variable set to %d\n', caller_variable);
end
