%% 05_plotting_and_visualization.m
% =========================================================================
% MATLAB Fundamentals & Computational Environment: Plotting and Visualization
% =========================================================================
% Pedagogical Objective:
% In engineering, data visualization is the bridge between raw numerical
% computation and physical insight. This script guides students through:
%   1. 2D line plotting with standard engineering annotations (labels, title, grid, legend)
%   2. Multi-channel telemetry visualization using subplots
%   3. Dual-axis or overlay plotting (hold on / hold off)
%   4. 3D spatial trajectory curves (plot3)
%   5. 3D surface and contour visualization (meshgrid, surf, contour)
%   6. Styling best practices for engineering reports and publications
%
% Applied Engineering Context:
% Multi-channel telemetry from an electric vehicle powertrain dynamometer test:
% Motor speed, electromagnetic torque, mechanical power, and 2D/3D thermal maps.
% =========================================================================

clearvars;
close all;
clc;

fprintf('====================================================\n');
fprintf(' MODULE 1: 2D & 3D SCIENTIFIC VISUALIZATION\n');
fprintf('====================================================\n\n');

%% 1. Synthesizing Realistic Dynamometer Telemetry Data
% Test duration: 10 seconds of aggressive acceleration and regenerative braking
fs = 100;                    % 100 Hz logging rate
t = 0 : (1/fs) : 10;         % Time vector [s]
N = length(t);

% Speed profile: Motor accelerates from 0 to 6000 RPM, then slows down
rpm_speed = 6000 .* (1 ./ (1 + exp(-1.5 .* (t - 3.5)))) .* (1 - 0.5 .* (1 ./ (1 + exp(-2.0 .* (t - 8.0)))));

% Electromagnetic Torque: High positive torque during acceleration, negative during regen
% Torque [N*m]
torque_nm = 250 .* exp(-0.5 .* ((t - 3.0) ./ 1.5) .^ 2) - 150 .* exp(-0.5 .* ((t - 8.2) ./ 1.0) .^ 2);

% Instantaneous Mechanical Power: P_mech = Torque * Angular Velocity
% omega = RPM * 2*pi / 60 [rad/s]
omega_rad_s = rpm_speed .* (2 * pi / 60);
p_mech_kw   = (torque_nm .* omega_rad_s) ./ 1000; % Power in Kilowatts [kW]

fprintf('Synthesized %d dynamometer telemetry points (10 s at %d Hz)\n', N, fs);
fprintf('Peak Motor Speed : %7.1f RPM\n', max(rpm_speed));
fprintf('Peak Torque      : %7.1f N*m\n', max(torque_nm));
fprintf('Peak Mech Power  : %7.1f kW\n\n', max(p_mech_kw));

%% 2. Figure 1: Multi-Channel Engineering Telemetry Dashboard (subplot)
% Subplots are essential for comparing synchronized time-series signals
% sharing a common time axis.

h_fig1 = figure('Name', 'EV Dynamometer Telemetry Dashboard', 'NumberTitle', 'off');

% --- Panel 1: Motor Speed ---
subplot(3, 1, 1);
plot(t, rpm_speed, 'b-', 'LineWidth', 1.8);
title('EV Powertrain Dynamometer Test: Transient Acceleration & Regen', ...
    'FontSize', 12, 'FontWeight', 'bold');
ylabel('Speed [RPM]', 'FontSize', 10);
grid on;
xlim([0, 10]);
legend('Motor Speed', 'Location', 'northwest');

% --- Panel 2: Motor Torque ---
subplot(3, 1, 2);
plot(t, torque_nm, 'r-', 'LineWidth', 1.8);
ylabel('Torque [N\cdotm]', 'FontSize', 10);
grid on;
xlim([0, 10]);
% Draw reference zero line indicating acceleration vs braking
hold on;
plot([0, 10], [0, 0], 'k--', 'LineWidth', 1.0);
hold off;
legend('Electromagnetic Torque', 'Zero Boundary', 'Location', 'northeast');

% --- Panel 3: Instantaneous Mechanical Power ---
subplot(3, 1, 3);
plot(t, p_mech_kw, 'Color', [0.1, 0.7, 0.2], 'LineWidth', 1.8);
xlabel('Elapsed Time [s]', 'FontSize', 10);
ylabel('Power [kW]', 'FontSize', 10);
grid on;
xlim([0, 10]);
legend('Mechanical Power (P_{mech})', 'Location', 'northwest');

fprintf('Figure 1: 3-panel time-series dashboard generated.\n');

%% 3. Figure 2: 3D Flight / Motion Trajectory Curve (plot3)
% In aerospace and robotics, 3D parametric curves represent the spatial path
% of an autonomous vehicle or projectile over time.

t_traj = linspace(0, 4*pi, 400); % Parametric flight parameter
% Ascending helical flight path of an inspection quadrotor
x_pos = 15 .* cos(t_traj);       % East position [m]
y_pos = 15 .* sin(t_traj);       % North position [m]
z_pos = 2.5 .* t_traj;           % Altitude [m]

h_fig2 = figure('Name', '3D Quadrotor Inspection Trajectory', 'NumberTitle', 'off');
plot3(x_pos, y_pos, z_pos, 'm-', 'LineWidth', 2.0);
grid on;
xlabel('East Displacement X [m]', 'FontSize', 10);
ylabel('North Displacement Y [m]', 'FontSize', 10);
zlabel('Altitude Z [m]', 'FontSize', 10);
title('Autonomous Quadrotor Spiral Ascent Trajectory', 'FontSize', 12, 'FontWeight', 'bold');

% Highlight initial takeoff point and final target point
hold on;
plot3(x_pos(1), y_pos(1), z_pos(1), 'go', 'MarkerSize', 10, 'MarkerFaceColor', 'g');
plot3(x_pos(end), y_pos(end), z_pos(end), 'rs', 'MarkerSize', 10, 'MarkerFaceColor', 'r');
hold off;
legend('Flight Path', 'Takeoff', 'Waypoint Target', 'Location', 'best');
view(45, 30); % Azimuth 45 deg, Elevation 30 deg

fprintf('Figure 2: 3D spatial trajectory curve generated.\n');

%% 4. Figure 3: 2D Spatial Mesh and 3D Thermal Surface (meshgrid, surf, contour)
% Engineering heat transfer: Steady-state 2D temperature distribution across
% an inverter insulated-gate bipolar transistor (IGBT) cold plate.
% T(x, y) = T_ambient + DeltaT * exp(-(x^2 + y^2)/(2*sigma^2)) + thermal gradient

x_plate = linspace(-0.1, 0.1, 50); % Plate width [-100 mm to +100 mm]
y_plate = linspace(-0.1, 0.1, 50); % Plate length [-100 mm to +100 mm]
[X_grid, Y_grid] = meshgrid(x_plate, y_plate); % 2D Cartesian coordinate grid

% Thermal model: Two localized IGBT semiconductor heat spots
spot1 = 45.0 .* exp(-((X_grid - 0.03).^2 + (Y_grid - 0.02).^2) ./ (2 * 0.025^2));
spot2 = 40.0 .* exp(-((X_grid + 0.03).^2 + (Y_grid - 0.02).^2) ./ (2 * 0.025^2));
ambient_t = 25.0;
temp_field_c = ambient_t + spot1 + spot2;

h_fig3 = figure('Name', 'Inverter Cold Plate Thermal Distribution', 'NumberTitle', 'off');

% Panel A: 3D Surface Plot
subplot(1, 2, 1);
surf(X_grid .* 1000, Y_grid .* 1000, temp_field_c); % Dimensions in mm
shading interp; % Smooth surface color interpolation
colormap('jet');
colorbar;
title('3D Thermal Surface', 'FontSize', 11, 'FontWeight', 'bold');
xlabel('X Position [mm]');
ylabel('Y Position [mm]');
zlabel('Temperature [^\circC]');
grid on;
view(-35, 40);

% Panel B: 2D Isothermal Contour Map
subplot(1, 2, 2);
[C_contour, h_contour] = contour(X_grid .* 1000, Y_grid .* 1000, temp_field_c, 15, 'LineWidth', 1.2);
clabel(C_contour, h_contour); % Label isotherm temperatures on contours
title('2D Isothermal Contours', 'FontSize', 11, 'FontWeight', 'bold');
xlabel('X Position [mm]');
ylabel('Y Position [mm]');
grid on;
axis equal; % Maintain physical geometric aspect ratio

fprintf('Figure 3: 3D thermal surface and 2D isothermal contours generated.\n');
fprintf('Peak Plate Temperature: %6.2f deg C\n\n', max(temp_field_c(:)));

fprintf('====================================================\n');
fprintf(' 05_plotting_and_visualization.m execution completed successfully.\n');
