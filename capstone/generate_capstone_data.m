% GENERATE_CAPSTONE_DATA Reproducible EV powertrain telemetry generator.
%
% Syntax:
%   generate_capstone_data()
%
% Description:
%   Simulates realistic, multi-physics high-frequency telemetry for an
%   electric vehicle powertrain over a 60-second dynamic drive cycle.
%   The model couples vehicle kinematics, electromechanical conversion,
%   high-voltage battery equivalent circuit dynamics, inverter thermal
%   transients, and electromagnetic sensor noise.
%
% Physics Formulations:
%   - Mechanical Power: P_mech = torque * omega (Watts)
%   - Electrical Power: P_elec = P_mech / eta + P_aux (motoring)
%   - Battery Terminal: V_term = V_oc - I * R_int (Volts)
%   - Thermal Dynamics: dT_inv/dt = P_loss / C_th - (T_inv - T_amb) / R_th
%   - Sensor Noise: AWGN added to all channels (Gaussian distribution)
%
% Output:
%   Writes CSV file to '../data/ev_telemetry.csv' with exactly 601 rows.

function generate_capstone_data()
    % Initialize random number generator for exact deterministic reproducibility
    rng(42, 'twister');

    % Time configuration: 60-second cycle at 10 Hz sampling frequency
    fs = 10.0;                       % Sampling frequency in Hertz [Hz]
    t_end = 60.0;                    % Total cycle duration in seconds [s]
    dt = 1.0 / fs;                   % Sampling interval [s]
    t = (0.0:dt:t_end)';             % Column time vector: 601 samples
    n_samples = length(t);           % Total telemetry records

    % Preallocate physical telemetry arrays
    speed_rpm = zeros(n_samples, 1);
    torque_nm = zeros(n_samples, 1);

    % Drive Cycle Profiles across 5 Distinct Regimes
    % Regime 1: Launch & Acceleration (0 <= t < 15 s)
    % Regime 2: Highway Cruising      (15 <= t < 35 s)
    % Regime 3: Passing Sprint        (35 <= t < 45 s)
    % Regime 4: Regenerative Braking  (45 <= t < 55 s)
    % Regime 5: Deceleration & Stop   (55 <= t <= 60 s)
    for i = 1:n_samples
        ti = t(i);
        if ti < 15.0
            % Smooth cubic S-curve acceleration profile 0 -> 3800 RPM
            progress = ti / 15.0;
            s_curve = 3.0 * (progress^2) - 2.0 * (progress^3);
            speed_rpm(i) = 3800.0 * s_curve;
            torque_nm(i) = 210.0 - 40.0 * progress;
        elseif ti < 35.0
            % Highway cruising with sinusoidal grade perturbations
            speed_rpm(i) = 3800.0 + 35.0 * sin(2.0 * pi * 0.1 * (ti - 15.0));
            torque_nm(i) = 72.0 + 8.0 * cos(2.0 * pi * 0.15 * (ti - 15.0));
        elseif ti < 45.0
            % High-power passing maneuver 3800 -> 5050 RPM
            progress = (ti - 35.0) / 10.0;
            s_curve = 3.0 * (progress^2) - 2.0 * (progress^3);
            speed_rpm(i) = 3800.0 + (5050.0 - 3800.0) * s_curve;
            torque_nm(i) = 245.0 - 25.0 * progress;
        elseif ti < 55.0
            % Regenerative braking deceleration 5050 -> 1200 RPM
            progress = (ti - 45.0) / 10.0;
            s_curve = 3.0 * (progress^2) - 2.0 * (progress^3);
            speed_rpm(i) = 5050.0 - (5050.0 - 1200.0) * s_curve;
            torque_nm(i) = -115.0 + 30.0 * progress;
        else
            % Mechanical friction braking to standstill 1200 -> 0 RPM
            progress = (ti - 55.0) / 5.0;
            speed_rpm(i) = max(0.0, 1200.0 * (1.0 - progress));
            torque_nm(i) = 0.0;
        end
    end

    % Angular shaft velocity in radians per second
    omega_rad_s = speed_rpm .* (2.0 * pi / 60.0);

    % Mechanical power delivered at rotor shaft: P_mech = torque * omega
    p_mech = torque_nm .* omega_rad_s;

    % Powertrain efficiency and auxiliary parameters
    eta_motoring = 0.935;            % Traction motor + inverter efficiency
    eta_regen = 0.885;               % Kinetic energy recovery efficiency
    p_aux = 350.0;                   % Auxiliary DC load (pumps, fans, sensors) [W]

    p_elec = zeros(n_samples, 1);
    for i = 1:n_samples
        if p_mech(i) >= 0.0
            p_elec(i) = (p_mech(i) / eta_motoring) + p_aux;
        else
            p_elec(i) = (p_mech(i) * eta_regen) + p_aux;
        end
    end

    % Battery Equivalent Circuit Model: V_term = V_oc - I * R_int
    v_oc = 398.0;                    % Open-circuit battery voltage [V]
    r_int = 0.048;                   % Total internal pack resistance [Ohms]

    battery_current_a = zeros(n_samples, 1);
    battery_voltage_v = zeros(n_samples, 1);

    for i = 1:n_samples
        % Solve quadratic circuit equation: R_int * I^2 - V_oc * I + P_elec = 0
        discriminant = (v_oc^2) - 4.0 * r_int * p_elec(i);
        if discriminant < 0
            discriminant = 0.0;
        end
        i_pack = (v_oc - sqrt(discriminant)) / (2.0 * r_int);
        v_pack = v_oc - i_pack * r_int;
        battery_current_a(i) = i_pack;
        battery_voltage_v(i) = v_pack;
    end

    % Thermal Lumped-Capacitance Model (Inverter Power Electronics)
    c_th = 1600.0;                   % Thermal capacitance [J/K]
    r_th = 0.78;                     % Thermal resistance to ambient [K/W]
    t_amb = 22.0 + 0.4 * sin(2.0 * pi * t ./ 120.0);
    inverter_temp_c = zeros(n_samples, 1);
    t_inv = 35.0;                    % Initial junction temperature [deg C]

    p_loss = abs(p_elec - p_mech);

    for i = 1:n_samples
        inverter_temp_c(i) = t_inv;
        dT_dt = (p_loss(i) / c_th) - ((t_inv - t_amb(i)) / r_th);
        t_inv = t_inv + dT_dt * dt;
    end

    % Add zero-mean Gaussian sensor measurement noise
    noise_speed = 4.5 * randn(n_samples, 1);
    noise_torque = 0.55 * randn(n_samples, 1);
    noise_voltage = 0.12 * randn(n_samples, 1);
    noise_current = 0.35 * randn(n_samples, 1);
    noise_t_inv = 0.08 * randn(n_samples, 1);
    noise_t_amb = 0.04 * randn(n_samples, 1);

    meas_speed = max(0.0, speed_rpm + noise_speed);
    meas_torque = torque_nm + noise_torque;
    meas_voltage = battery_voltage_v + noise_voltage;
    meas_current = battery_current_a + noise_current;
    meas_t_inv = inverter_temp_c + noise_t_inv;
    meas_t_amb = t_amb + noise_t_amb;

    % Construct target file path
    script_dir = fileparts(mfilename('fullpath'));
    out_dir = fullfile(script_dir, '..', 'data');
    if ~exist(out_dir, 'dir')
        mkdir(out_dir);
    end
    csv_file = fullfile(out_dir, 'ev_telemetry.csv');

    % Write CSV dataset with formatted header
    fid = fopen(csv_file, 'w');
    if fid == -1
        error('Failed to open output file for writing: %s', csv_file);
    end

    fprintf(fid, 'timestamp_s,motor_speed_rpm,motor_torque_nm,battery_voltage_v,battery_current_a,inverter_temp_c,ambient_temp_c\n');
    for i = 1:n_samples
        fprintf(fid, '%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f\n', ...
            t(i), meas_speed(i), meas_torque(i), meas_voltage(i), ...
            meas_current(i), meas_t_inv(i), meas_t_amb(i));
    end
    fclose(fid);

    fprintf('Successfully generated EV telemetry data (%d samples): %s\n', n_samples, csv_file);
end
