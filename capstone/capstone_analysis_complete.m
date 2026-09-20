%% capstone_analysis_complete.m - Complete Reference Solution for EV Powertrain Telemetry Capstone
% =========================================================================
% MODULE: Integrated Engineering Capstone Project (Level 2 / R6)
%
% PURPOSE:
%   Complete, fully resolved reference implementation of the multi-physics
%   Electric Vehicle (EV) Powertrain Telemetry analysis pipeline.
%   Ingests high-frequency vehicle telemetry, calculates mechanical and
%   electrical power flows, computes energy accumulation via numerical
%   quadrature, applies digital noise filtering, evaluates thermal gradients
%   via numerical differentiation, and renders a 4-panel diagnostic dashboard.
%
% MULTI-PHYSICS ANALYSIS PHASES:
%   1. Data Ingestion: Ingests and validates 600-sample 10 Hz time-series CSV telemetry.
%   2. Power Flow: Calculates mechanical shaft power and electrical DC battery power.
%   3. Efficiency & Losses: Evaluates instantaneous conversion efficiency and heat dissipation.
%   4. Numerical Quadrature: Trapezoidal integration of net and regenerated energy.
%   5. Digital Filtering: 9-point moving-average noise rejection on temperature.
%   6. Numerical Differentiation: Thermal gradient dT/dt calculation via finite differences.
%   7. Engineering Dashboard: 4-panel diagnostic visualization.
%
% HARDWARE & PHYSICAL CONSTANTS:
%   - Sampling rate: fs = 10 Hz (dt = 0.1 s)
%   - Drive cycle duration: 60 seconds (600 time samples)
%   - Powertrain: Liquid-cooled permanent magnet synchronous motor (PMSM) + inverter
% =========================================================================

function capstone_analysis_complete()
    clc;
    close all;

    fprintf('=================================================================\n');
    fprintf('  ELECTRIC VEHICLE POWERTRAIN TELEMETRY ANALYSIS (COMPLETE)      \n');
    fprintf('=================================================================\n\n');

    %% Step 1: Ingest Telemetry Dataset
    script_dir = fileparts(mfilename('fullpath'));
    
    % Search for ev_telemetry.csv across candidate repository locations
    candidate_paths = { ...
        fullfile(script_dir, '..', 'data', 'ev_telemetry.csv'), ...
        fullfile(script_dir, 'data', 'ev_telemetry.csv'), ...
        fullfile(script_dir, '..', 'capstone', 'data', 'ev_telemetry.csv'), ...
        fullfile(script_dir, '..', '..', 'data', 'ev_telemetry.csv') ...
    };

    csv_file = '';
    for idx = 1:length(candidate_paths)
        if exist(candidate_paths{idx}, 'file')
            csv_file = candidate_paths{idx};
            break;
        end
    end

    if isempty(csv_file)
        error('Telemetry dataset not found! Please check data/ev_telemetry.csv.');
    end

    telemetry = readtable(csv_file);
    N_records = height(telemetry);
    fprintf('Successfully loaded %d telemetry records from:\n  %s\n\n', ...
        N_records, csv_file);

    % Extract telemetry channels
    t         = telemetry.timestamp_s;
    speed_rpm = telemetry.motor_speed_rpm;
    torque_nm = telemetry.motor_torque_nm;
    voltage_v = telemetry.battery_voltage_v;
    current_a = telemetry.battery_current_a;
    t_inv_raw = telemetry.inverter_temp_c;
    t_amb_raw = telemetry.ambient_temp_c;

    %% Step 2: Mechanical & Electrical Power Computation
    % Angular velocity conversion: omega = RPM * (2 * pi / 60) [rad/s]
    omega_rad_s = speed_rpm .* (2.0 * pi / 60.0);

    % Mechanical shaft power: P_mech = torque * omega [Watts]
    P_mech = torque_nm .* omega_rad_s;

    % Electrical DC battery power: P_elec = Voltage * Current [Watts]
    P_elec = voltage_v .* current_a;

    fprintf('Power Statistics:\n');
    fprintf('  Peak Mechanical Shaft Power  : %8.2f kW\n', max(P_mech) / 1000.0);
    fprintf('  Peak Electrical DC Power     : %8.2f kW\n', max(P_elec) / 1000.0);
    fprintf('  Peak Regenerative Braking    : %8.2f kW\n\n', min(P_elec) / 1000.0);

    %% Step 3: Powertrain Efficiency & Energy Loss
    % Active motoring regime: P_elec >= 1000 W and P_mech > 0
    motoring_mask = (P_elec >= 1000.0) & (P_mech > 0.0);

    % Instantaneous conversion efficiency: eta = P_mech / P_elec
    eta = zeros(size(P_elec));
    eta(motoring_mask) = P_mech(motoring_mask) ./ P_elec(motoring_mask);

    % Power loss dissipated as heat: P_loss = |P_elec - P_mech| [Watts]
    P_loss = abs(P_elec - P_mech);

    fprintf('Efficiency & Losses:\n');
    fprintf('  Mean Motoring Efficiency     : %8.2f%%\n', mean(eta(motoring_mask)) * 100.0);
    fprintf('  Peak Motoring Efficiency     : %8.2f%%\n', max(eta(motoring_mask)) * 100.0);
    fprintf('  Peak Heat Dissipation (Ploss): %8.2f kW\n\n', max(P_loss) / 1000.0);

    %% Step 4: Numerical Quadrature (Energy Accumulation)
    % Net cumulative electrical energy consumed via trapezoidal quadrature:
    % E_net = integral(P_elec * dt) [Joules]
    E_net_joules = trapz(t, P_elec);
    E_net_kwh    = E_net_joules / (3600.0 * 1000.0);

    % Gross motoring energy expended (P_elec > 0)
    P_elec_pos = max(0.0, P_elec);
    E_motoring_joules = trapz(t, P_elec_pos);
    E_motoring_kwh    = E_motoring_joules / (3600.0 * 1000.0);

    % Regenerative braking energy recovered (P_elec < 0)
    P_elec_neg = max(0.0, -P_elec);
    E_regen_joules = trapz(t, P_elec_neg);
    E_regen_kwh    = E_regen_joules / (3600.0 * 1000.0);

    % Regeneration recovery ratio: E_regen / E_motoring
    regen_ratio_pct = (E_regen_joules / E_motoring_joules) * 100.0;

    fprintf('Energy Quadrature (60-second Drive Cycle):\n');
    fprintf('  Net Energy Consumed          : %8.4f kWh (%8.1f kJ)\n', ...
        E_net_kwh, E_net_joules / 1000.0);
    fprintf('  Gross Motoring Energy        : %8.4f kWh (%8.1f kJ)\n', ...
        E_motoring_kwh, E_motoring_joules / 1000.0);
    fprintf('  Regenerated Braking Energy   : %8.4f kWh (%8.1f kJ)\n', ...
        E_regen_kwh, E_regen_joules / 1000.0);
    fprintf('  Regenerative Recovery Ratio  : %8.2f%%\n\n', regen_ratio_pct);

    %% Step 5: Digital Noise Filtering (Sensor Noise Reduction)
    % Moving average filter window width: W = 9 samples (0.9 s window at fs = 10 Hz)
    W = 9;
    kernel = ones(W, 1) / W;
    t_inv_filtered = conv(t_inv_raw, kernel, 'same');

    % Variance of sensor noise residual
    noise_residual = t_inv_raw - t_inv_filtered;
    sigma_noise_empirical = std(noise_residual);

    fprintf('Digital Noise Filtering:\n');
    fprintf('  Filter Window Length (W)     : %d samples\n', W);
    fprintf('  Estimated Sensor Noise Std   : %.4f deg C\n\n', sigma_noise_empirical);

    %% Step 6: Numerical Differentiation (Thermal Rates of Change)
    % Time steps: dt = diff(t)
    dt = diff(t);

    % Finite difference derivative on filtered temperature signal:
    % dT/dt = diff(T_filtered) ./ dt [deg C / s]
    dT_dt = diff(t_inv_filtered) ./ dt;

    % Centered midpoints for matching array dimension: length N - 1
    t_mid = (t(1:end-1) + t(2:end)) / 2.0;

    % Derivative on uninhibited raw noisy signal (for pedagogical contrast)
    dT_dt_raw = diff(t_inv_raw) ./ dt;

    [max_dT_dt, max_dT_idx] = max(dT_dt);
    fprintf('Thermal Gradient Analysis:\n');
    fprintf('  Maximum Thermal Heating Rate : %8.3f deg C/s (at t = %.1f s)\n', ...
        max_dT_dt, t_mid(max_dT_idx));
    fprintf('  Raw Unfiltered Noise Spike   : %8.3f deg C/s\n', max(abs(dT_dt_raw)));
    fprintf('  Initial Inverter Temperature : %8.2f deg C\n', t_inv_filtered(1));
    fprintf('  Peak Inverter Temperature    : %8.2f deg C\n\n', max(t_inv_filtered));

    %% Step 7: Multi-Panel Engineering Dashboard
    figure('Name', 'EV Powertrain Telemetry Diagnostic Dashboard', 'Color', 'w');

    % Subplot 1: Motor Speed (RPM) and Torque (Nm) vs Time
    subplot(2, 2, 1);
    yyaxis left;
    plot(t, speed_rpm, 'b-', 'LineWidth', 1.5);
    ylabel('Motor Speed [RPM]');
    ylim([0, max(speed_rpm) * 1.15]);
    
    yyaxis right;
    plot(t, torque_nm, 'r-', 'LineWidth', 1.5);
    ylabel('Motor Torque [N\cdotm]');
    ylim([min(torque_nm) * 1.15, max(torque_nm) * 1.15]);
    
    grid on;
    xlabel('Time [seconds]');
    title('Drive Cycle Kinematics: Speed & Torque');

    % Subplot 2: Electrical vs Mechanical Power (kW)
    subplot(2, 2, 2);
    plot(t, P_elec / 1000.0, 'r-', 'LineWidth', 1.5, 'DisplayName', 'P_{elec} (DC Battery)');
    hold on;
    plot(t, P_mech / 1000.0, 'b--', 'LineWidth', 1.5, 'DisplayName', 'P_{mech} (Shaft)');
    plot([0, t(end)], [0, 0], 'k:', 'LineWidth', 1.0);
    grid on;
    xlabel('Time [seconds]');
    ylabel('Power [kW]');
    title('Powertrain Power Flow & Regeneration');
    legend('Location', 'northeast');

    % Subplot 3: Inverter Temperature & Thermal Rate of Change
    subplot(2, 2, 3);
    yyaxis left;
    plot(t, t_inv_raw, 'k:', 'LineWidth', 1.0, 'DisplayName', 'Raw Sensor T_{inv}');
    hold on;
    plot(t, t_inv_filtered, 'b-', 'LineWidth', 2.0, 'DisplayName', 'Filtered T_{inv}');
    ylabel('Temperature [^\circC]');
    
    yyaxis right;
    plot(t_mid, dT_dt, 'r-', 'LineWidth', 1.2, 'DisplayName', 'dT/dt (Filtered)');
    ylabel('Heating Rate dT/dt [^\circC/s]');
    
    grid on;
    xlabel('Time [seconds]');
    title('Thermal Management: Inverter Heating Dynamics');

    % Subplot 4: Powertrain Efficiency Sweet Spot
    subplot(2, 2, 4);
    scatter(speed_rpm(motoring_mask), eta(motoring_mask) * 100.0, 25, ...
        torque_nm(motoring_mask), 'filled');
    colormap('jet');
    h_cb = colorbar();
    ylabel(h_cb, 'Torque [N\cdotm]');
    grid on;
    xlabel('Motor Speed [RPM]');
    ylabel('Efficiency \eta [%]');
    title('Efficiency Map & Operating Sweet Spot');
    ylim([70.0, 100.0]);

    fprintf('=================================================================\n');
    fprintf('  CAPSTONE TELEMETRY ANALYSIS COMPLETED SUCCESSFULLY             \n');
    fprintf('=================================================================\n');
end
