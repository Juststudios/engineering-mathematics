%% 04_thermal_cooling_companion.m - Dynamic Thermal Dissipation & Cooling
% =========================================================================
% MODULE: Simulink Dynamic System Modeling (Level 2 / R5)
%
% PURPOSE:
%   Standalone MATLAB companion script modeling lumped Newton thermal
%   dissipation with convective feedback and pulse power heating.
%   Integrates the 1st-order thermal ODE using ode45 and compares numerical
%   trajectories with piecewise analytical solutions.
%
% GOVERNING DIFFERENTIAL EQUATION:
%   Energy conservation across thermal boundary:
%     C_th * (dT / dt) = P_in(t) - h * A * (T(t) - T_amb)
%     dT / dt = (P_in(t) - h * A * (T(t) - T_amb)) / C_th
%   Thermal Time Constant: tau_th = C_th / (h * A) [seconds]
%
% PHYSICAL PARAMETERS:
%   - Thermal Capacitance (C_th)     : 180.0 J/K
%   - Convective Conductance (h*A)   : 4.5 W/K
%   - Ambient Air Temperature (T_amb): 25.0 deg C
%   - Thermal Time Constant (tau_th) : 40.0 s
%   - Inverter Power Pulse (P_in)    : 150.0 W (from t = 100 s to 300 s)
%   - Theoretical Peak Temperature   : T_amb + P_in / (h*A) = 58.33 deg C
% =========================================================================

clear;
close all;
clc;

fprintf('=================================================================\n');
fprintf('  SIMULINK COMPANION: THERMAL DISSIPATION & COOLING DYNAMICS     \n');
fprintf('=================================================================\n\n');

%% 1. Thermal System Physical Constants
C_th  = 180.0;     % Thermal capacitance of heatsink [J/K]
hA    = 4.5;       % Lumped convective heat transfer coefficient [W/K]
T_amb = 25.0;      % Ambient environmental temperature [deg C]

% Thermal time constant: tau_th = C_th / hA
tau_th = C_th / hA; % [seconds] (180.0 / 4.5 = 40.0 s)

% Power pulse heating profile timing
P_pulse = 150.0;   % Inverter thermal dissipation [Watts]
t_on    = 100.0;   % Heating activation timestamp [s]
t_off   = 300.0;   % Heating deactivation timestamp [s]
t_final = 600.0;   % Total simulation duration [s]

fprintf('Thermal Parameters:\n');
fprintf('  Lumped Thermal Mass (C_th)    : %.1f J/K\n', C_th);
fprintf('  Convective Conductance (h*A)  : %.2f W/K\n', hA);
fprintf('  Ambient Temperature (T_amb)   : %.2f deg C\n', T_amb);
fprintf('  Thermal Time Constant (tau_th): %.2f seconds\n', tau_th);
fprintf('  Inverter Dissipation (P_in)   : %.1f W (Active: %.1f s to %.1f s)\n\n', ...
    P_pulse, t_on, t_off);

%% 2. ODE Formulation & Numerical Solution
% Piecewise continuous power input function
p_in_func = @(t) (t >= t_on && t < t_off) * P_pulse;

% 1st-order thermal differential equation
% dT/dt = (P_in(t) - hA * (T - T_amb)) / C_th
thermal_ode = @(t, T) (p_in_func(t) - hA * (T - T_amb)) / C_th;

% Initial condition: system at ambient thermal equilibrium
T_0 = T_amb;

% Numerical solver configuration
ode_opts = odeset('RelTol', 1e-6, 'AbsTol', 1e-8, 'MaxStep', 0.5);

% Execute numerical integration
[t_sim, T_sim] = ode45(thermal_ode, [0.0, t_final], T_0, ode_opts);

%% 3. Piecewise Analytical Solution & Solver Audit
% Analytical evaluation:
%   Interval 1 [0, t_on):       T(t) = T_amb
%   Interval 2 [t_on, t_off):   T(t) = T_amb + (P_pulse / hA) * (1 - exp(-(t - t_on)/tau_th))
%   Interval 3 [t_off, t_final]:T(t) = T_amb + (T_peak - T_amb) * exp(-(t - t_off)/tau_th)
T_analytical = zeros(size(t_sim));
T_peak_theoretical = T_amb + (P_pulse / hA) * (1.0 - exp(-(t_off - t_on) / tau_th));

for idx = 1:length(t_sim)
    t_val = t_sim(idx);
    if t_val < t_on
        T_analytical(idx) = T_amb;
    elseif t_val < t_off
        T_analytical(idx) = T_amb + (P_pulse / hA) * (1.0 - exp(-(t_val - t_on) / tau_th));
    else
        T_analytical(idx) = T_amb + (T_peak_theoretical - T_amb) * exp(-(t_val - t_off) / tau_th);
    end
end

% Pointwise solver accuracy verification
thermal_error = abs(T_sim - T_analytical);
max_thermal_error = max(thermal_error);

fprintf('Solver Precision & Convergence:\n');
fprintf('  Integration Steps Taken       : %d\n', length(t_sim));
fprintf('  Maximum Numerical Error       : %.2e deg C\n', max_thermal_error);

%% 4. Engineering Thermal Audit
[T_max_sim, max_idx] = max(T_sim);
t_at_max = t_sim(max_idx);

% Asymptotic steady-state temperature if heating continued indefinitely:
T_asymptotic = T_amb + P_pulse / hA;

% Final temperature at end of cooldown (t = 600 s):
T_final_sim = T_sim(end);
delta_T_recovered = (T_max_sim - T_final_sim) / (T_max_sim - T_amb) * 100.0;

fprintf('\nThermal Performance Audit:\n');
fprintf('  Asymptotic Steady-State Limit : %.2f deg C\n', T_asymptotic);
fprintf('  Peak Junction Temperature     : %.2f deg C (Occurred at t = %.1f s)\n', ...
    T_max_sim, t_at_max);
fprintf('  Theoretical Peak at Shutdown  : %.2f deg C\n', T_peak_theoretical);
fprintf('  Cooldown Dwell Duration       : %.1f s (%.1f time constants)\n', ...
    t_final - t_off, (t_final - t_off) / tau_th);
fprintf('  Final Temperature at 600 s    : %.2f deg C\n', T_final_sim);
fprintf('  Thermal Recovery Fraction     : %.1f%% dissipated back to ambient\n', ...
    delta_T_recovered);

%% 5. Thermal Energy Balance Check
% Total electrical heat energy injected:
% Q_in = P_pulse * (t_off - t_on) = 150 W * 200 s = 30,000 Joules
Q_in_total = P_pulse * (t_off - t_on);

% Numerical trapezoidal integration of convective cooling power:
% q_conv(t) = hA * (T(t) - T_amb)
q_conv_sim = hA * (T_sim - T_amb);
Q_dissipated_total = trapz(t_sim, q_conv_sim);

% Thermal energy remaining stored in heatsink at t_final:
Q_stored_final = C_th * (T_final_sim - T_amb);

% First Law Conservation Check: Q_in = Q_dissipated + Q_stored
energy_balance_error = abs(Q_in_total - (Q_dissipated_total + Q_stored_final));

fprintf('\nThermal Energy Conservation Audit:\n');
fprintf('  Total Heat Injected (Q_in)    : %8.1f J\n', Q_in_total);
fprintf('  Total Convective Dissipation  : %8.1f J\n', Q_dissipated_total);
fprintf('  Stored Thermal Energy at End  : %8.1f J\n', Q_stored_final);
fprintf('  Energy Conservation Discrepancy: %8.4f J (%.4f%%)\n', ...
    energy_balance_error, (energy_balance_error / Q_in_total) * 100.0);

%% 6. Visualization Dashboard
figure('Name', 'Thermal Cooling Dynamics', 'Color', 'w');

% Top panel: Temperature transient
subplot(2, 1, 1);
plot(t_sim, T_sim, 'b-', 'LineWidth', 2.0, 'DisplayName', 'ODE45 Numerical');
hold on;
plot(t_sim, T_analytical, 'r--', 'LineWidth', 1.5, 'DisplayName', 'Piecewise Analytical');
yline(T_amb, 'k:', 'LineWidth', 1.0, 'DisplayName', 'Ambient (25 C)');
yline(T_asymptotic, 'm:', 'LineWidth', 1.0, 'DisplayName', 'Asymptotic Max (58.33 C)');
xline(t_on, 'g--', 'LineWidth', 1.0, 'DisplayName', 'Heat Pulse ON');
xline(t_off, 'r--', 'LineWidth', 1.0, 'DisplayName', 'Heat Pulse OFF');
grid on;
xlabel('Time [seconds]');
ylabel('Temperature T(t) [deg C]');
title('Inverter Thermal Management: Heating Pulse & Convective Cooldown');
legend('Location', 'east');

% Bottom panel: Dissipation power and rate of change
subplot(2, 1, 2);
p_in_plot = zeros(size(t_sim));
for idx = 1:length(t_sim)
    p_in_plot(idx) = p_in_func(t_sim(idx));
end
plot(t_sim, p_in_plot, 'r-', 'LineWidth', 1.5, 'DisplayName', 'Heat Input P_{in}(t) [W]');
hold on;
plot(t_sim, q_conv_sim, 'b-', 'LineWidth', 1.5, 'DisplayName', 'Convective Heat Out q_{conv}(t) [W]');
grid on;
xlabel('Time [seconds]');
ylabel('Power [Watts]');
title('Instantaneous Thermal Power Flow: Input vs Convective Dissipation');
legend('Location', 'northeast');

fprintf('\n=================================================================\n');
fprintf('  THERMAL COOLING COMPANION COMPLETED SUCCESSFULLY               \n');
fprintf('=================================================================\n');
