%% trig_basics.m — MATLAB Trigonometry Companion
% Demonstrates sin, cos, tan, unit circle, and signal analysis.

clear; clc;

%% 1. Basic trig values
fprintf('=== Trig Values ===\n');
angles_deg = [0, 30, 45, 60, 90];
for k = 1:length(angles_deg)
    deg = angles_deg(k);
    rad = deg * pi / 180;
    fprintf('  %3d deg | sin=%.4f | cos=%.4f | tan=%.4f\n', ...
            deg, sin(rad), cos(rad), tan(rad));
end

%% 2. Unit circle plot
theta = linspace(0, 2*pi, 300);
figure(1);
plot(cos(theta), sin(theta), 'b-', 'LineWidth', 2); hold on;
axis equal; grid on;
xlabel('cos(theta)'); ylabel('sin(theta)');
title('Unit Circle');
key = [0, pi/6, pi/4, pi/3, pi/2];
for k = 1:length(key)
    plot([0 cos(key(k))], [0 sin(key(k))], 'r--', 'LineWidth', 1);
    plot(cos(key(k)), sin(key(k)), 'ro', 'MarkerSize', 8);
end

%% 3. Sin and Cos waves
t = linspace(0, 2*pi, 300);
figure(2);
plot(t, sin(t), 'b-', 'LineWidth', 2, 'DisplayName', 'sin'); hold on;
plot(t, cos(t), 'r-', 'LineWidth', 2, 'DisplayName', 'cos');
xlabel('theta (rad)'); ylabel('Value');
title('sin and cos Waves'); legend; grid on;

%% 4. Pythagorean identity verification
check = sin(theta).^2 + cos(theta).^2;
fprintf('\nMax deviation from sin^2+cos^2=1: %.2e\n', max(abs(check - 1)));
