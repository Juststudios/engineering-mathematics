%% 01_environment_and_variables.m
% =========================================================================
% MATLAB Fundamentals & Computational Environment: Environment & Variables
% =========================================================================
% Pedagogical Objective:
% This script introduces the MATLAB desktop and execution environment to
% engineering students transitioning from Python/NumPy (Level 1) to Level 2.
% We explore workspace memory management, fundamental data types, memory
% sizing calculations for large telemetry buffers, console output formatting,
% and the critical role of semicolon output suppression.
%
% Key Engineering Topics Covered:
%   1. Computational Environment & Desktop Architecture
%   2. Workspace Cleanliness: clear, clc, close all, whos
%   3. Fundamental Numeric & Text Types (double, single, integer, logical)
%   4. Memory Footprint Calculation for High-Frequency Telemetry
%   5. Output Suppression, Display Modes, and Formatted I/O (fprintf)
%   6. Applied Sensor Buffer Casting (ADC integer counts to physical units)
% =========================================================================

%% 1. Workspace Cleanliness & Best Practices
% In engineering scripts, beginning with a clean state guarantees repeatability.
% Without this, residual variables from earlier sessions can silently contaminate
% subsequent simulations or mask missing variable definitions.

clearvars;   % Clears all variables from the base workspace memory
close all;   % Closes all open figure visualization windows
clc;         % Clears the Command Window text screen

fprintf('====================================================\n');
fprintf(' MODULE 1: MATLAB ENVIRONMENT & DATA TYPES DEMO\n');
fprintf('====================================================\n\n');

%% 2. Fundamental Data Types in Engineering Computing
% In Python, variable types are dynamically inferred and scalar values (like int
% or float) are distinct objects. In MATLAB, the DEFAULT type for all numbers
% is a 64-bit IEEE 754 double-precision floating-point 2D matrix (1x1).

% --- 2.1 Double Precision (Standard for scientific computing) ---
% 64 bits = 8 bytes per element. ~15 to 17 significant decimal digits.
gravitational_accel = 9.80665;    % Standard gravity [m/s^2]
fprintf('gravitational_accel (double): %7.5f m/s^2, Class: %s\n', ...
    gravitational_accel, class(gravitational_accel));

% --- 2.2 Single Precision (Used in GPU kernels & embedded DSP) ---
% 32 bits = 4 bytes per element. ~7 significant decimal digits.
density_air_single = single(1.225); % Air density at sea level [kg/m^3]
fprintf('density_air_single  (single): %7.3f kg/m^3, Class: %s\n', ...
    density_air_single, class(density_air_single));

% --- 2.3 Fixed-Point / Integer Types (Hardware DAQ & ADC Channels) ---
% Standard microcontrollers and ADC chips output discrete integer counts:
%   - uint8  (8-bit unsigned:  0 to 255)
%   - uint16 (16-bit unsigned: 0 to 65535) - Common for 10-bit/12-bit/16-bit ADCs
%   - int32  (32-bit signed:   -2^31 to 2^31 - 1)
raw_adc_reading = uint16(32768);  % 16-bit midpoint reading (e.g. 1.65V on a 3.3V range)
sample_counter  = int32(1048576); % 32-bit frame counter
fprintf('raw_adc_reading     (uint16): %d counts, Class: %s\n', ...
    raw_adc_reading, class(raw_adc_reading));

% --- 2.4 Logical Arrays (Boolean flags for thresholding & masks) ---
% 1 byte per element. Can take values true (1) or false (0).
is_safety_interlock_active = true;
over_temperature_alarm     = false;
fprintf('safety_interlock   (logical): %d, Class: %s\n', ...
    is_safety_interlock_active, class(is_safety_interlock_active));

% --- 2.5 Text Representations: Character Vector vs String Object ---
% MATLAB supports legacy char vectors (enclosed in single quotes '')
% and modern string scalars/arrays (enclosed in double quotes "").
sensor_tag_char   = 'PRESS_SEN_01';      % 1x12 char array (character vector)
sensor_desc_str   = "Turbine Inlet Barometer"; % 1x1 string object
fprintf('sensor_tag_char       (char): %s, Length: %d\n', ...
    sensor_tag_char, length(sensor_tag_char));
fprintf('sensor_desc_str     (string): %s\n\n', sensor_desc_str);

%% 3. Memory Footprint Calculation for High-Frequency Telemetry
% Aerospace and automotive engineers frequently stream sensor telemetry at
% high sample rates (e.g. 10 kHz for vibration, 1 kHz for electric motor current).
% Understanding memory consumption prevents Out-Of-Memory (OOM) crashes.

sampling_rate_hz   = 10000;   % 10 kHz sampling frequency
duration_sec       = 60;      % 60 seconds acquisition duration
num_channels       = 8;       % 8 parallel strain gauge channels
total_samples_per_chan = sampling_rate_hz * duration_sec;
total_data_points      = total_samples_per_chan * num_channels;

% Calculation 1: Memory footprint as double precision (8 bytes/sample)
bytes_double = total_data_points * 8;
mb_double    = bytes_double / (1024^2);

% Calculation 2: Memory footprint as uint16 ADC counts (2 bytes/sample)
bytes_uint16 = total_data_points * 2;
mb_uint16    = bytes_uint16 / (1024^2);

fprintf('--- TELEMETRY MEMORY FOOTPRINT ANALYSIS ---\n');
fprintf('Sampling Rate       : %d Hz\n', sampling_rate_hz);
fprintf('Total Samples/Chan  : %d samples\n', total_samples_per_chan);
fprintf('Total Data Points   : %d measurements\n', total_data_points);
fprintf('Memory as double    : %7.2f MB (64 bits per sample)\n', mb_double);
fprintf('Memory as uint16    : %7.2f MB (16 bits per sample)\n', mb_uint16);
fprintf('Memory Savings      : %7.1f%% reduction by logging raw ADC uint16\n\n', ...
    (1 - bytes_uint16/bytes_double) * 100);

%% 4. Examining Workspace State: whos Command
% The 'whos' command inspects all active variables in memory, reporting their
% name, dimensions, byte footprint, and class.
fprintf('--- ACTIVE BASE WORKSPACE VARIABLES (whos) ---\n');
whos;
fprintf('\n');

%% 5. Semicolon Output Suppression & Console Performance
% In MATLAB, terminating a statement with a semicolon (;) suppresses its
% printed echo in the Command Window.
%
% PITFALL DEMONSTRATION:
% Writing 'x = 1:100000' WITHOUT a semicolon attempts to write 100,000 lines
% of text to stdout, freezing the user interface for seconds or minutes.
% Always end computational lines with a semicolon!

tic; % Start performance stopwatch timer
suppressed_vector = (1:50000) .^ 2; % Semicolon prevents printing 50,000 values
elapsed_time_suppressed = toc;
fprintf('Calculation with semicolon (suppressed): %9.6f seconds\n\n', elapsed_time_suppressed);

%% 6. Applied Engineering Scenario: ADC Integer to Physical Voltage Conversion
% Hardware scenario: A 12-bit Analog-to-Digital Converter (ADC) samples
% battery pack voltage telemetry. Raw counts range from 0 to 4095.
% We cast the integer buffer to double, apply the hardware scaling factor,
% and print out statistical summaries.

% Simulated 12-bit ADC raw readings from 5 battery cell voltage taps
adc_counts = uint16([2605, 2618, 2598, 2640, 2612]); % 12-bit ADC counts
v_ref = 3.3;             % ADC full-scale reference voltage [V]
adc_resolution = 4095;   % 2^12 - 1
voltage_divider_ratio = 5.0; % Scaling factor from hardware resistor divider (0-16.5V)

% Convert uint16 counts to double-precision physical voltages
% Note: In MATLAB, arithmetic between uint16 and double requires explicit casting
% or MATLAB promotes the result according to strict conversion rules.
cell_voltages = double(adc_counts) * (v_ref / adc_resolution) * voltage_divider_ratio;

fprintf('--- BATTERY CELL TELEMETRY CONVERSION ---\n');
for i = 1:length(cell_voltages)
    fprintf('  Cell %d: Raw ADC = %5d counts  -->  Physical Voltage = %6.3f V\n', ...
        i, adc_counts(i), cell_voltages(i));
end

mean_voltage = mean(cell_voltages);
pack_voltage = sum(cell_voltages);
fprintf('-----------------------------------------\n');
fprintf('  Mean Cell Voltage : %6.3f V\n', mean_voltage);
fprintf('  Total Pack Voltage: %6.3f V\n', pack_voltage);
fprintf('====================================================\n');
fprintf(' 01_environment_and_variables.m execution completed successfully.\n');
