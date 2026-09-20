# MATLAB Quick Reference Cheat Sheet

A concise, high-density reference guide for engineering computation in MATLAB, contrasting syntax with Python/NumPy for students transitioning from Level 1 to Level 2.

---

## 1. Environment & Workspace Commands

| Command | Description | Python / Bash Equivalent |
| :--- | :--- | :--- |
| `clc` | Clears Command Window text display | `clear` (terminal) |
| `clear` / `clearvars` | Purges all variables from workspace memory | `del var` / restart kernel |
| `close all` | Closes all open figure graphics windows | `plt.close('all')` |
| `whos` | Lists workspace variables, dimensions, bytes, class | `%whos` (IPython) |
| `help <func>` | Displays header documentation for `<func>` | `help(func)` / `?func` |
| `doc <func>` | Launches HTML documentation in Help browser | Web documentation |
| `format long` / `short` | Toggles display precision (15 vs 4 decimal digits) | `np.set_printoptions(precision=...)` |
| `tic; ...; toc;` | Times elapsed wall-clock execution in seconds | `time.perf_counter()` |

> **Memory Rule**: Semicolon `;` at the end of a statement suppresses automatic Command Window echoing. Omit `;` only when interactively inspecting intermediate variable values.

---

## 2. Array Creation & Data Structures

MATLAB treats the two-dimensional matrix of double-precision floating-point numbers (`double`) as its fundamental native type.

| Concept | MATLAB Syntax | Python / NumPy Equivalent | Notes |
| :--- | :--- | :--- | :--- |
| **Row Vector** | `r = [1, 2, 3];` or `[1 2 3]` | `np.array([1, 2, 3])` | $1 \times 3$ matrix |
| **Column Vector** | `c = [1; 2; 3];` | `np.array([[1], [2], [3]])` | $3 \times 1$ matrix |
| **2D Matrix** | `A = [1, 2; 3, 4];` | `np.array([[1, 2], [3, 4]])` | Rows delimited by `;` |
| **Linear Grid** | `x = linspace(0, 10, 101);` | `np.linspace(0, 10, 101)` | 101 points inclusive |
| **Range / Step** | `t = 0:0.1:10;` | `np.arange(0, 10.05, 0.1)` | `start:step:end` |
| **Zeros Matrix** | `Z = zeros(m, n);` | `np.zeros((m, n))` | All elements 0.0 |
| **Ones Matrix** | `O = ones(m, n);` | `np.ones((m, n))` | All elements 1.0 |
| **Identity Matrix** | `I = eye(n);` | `np.eye(n)` | Diagonal of 1s |
| **Uniform Random** | `U = rand(m, n);` | `np.random.rand(m, n)` | $\mathcal{U}[0, 1)$ |
| **Gaussian Random** | `G = randn(m, n);` | `np.random.randn(m, n)` | $\mathcal{N}(0, 1)$ |
| **Diagonal Matrix** | `D = diag([1, 2, 3]);` | `np.diag([1, 2, 3])` | Embed vector on diagonal |

---

## 3. Indexing & Slicing (1-Based)

> ⚠️ **CRITICAL DIFFERENCE**: MATLAB indexing is **1-based** ($1, 2, \dots, N$). Indexing at 0 (`A(0)`) throws a runtime error. Ranges are **closed/inclusive** on both boundaries (`1:5` includes both 1 and 5).

| Slicing Operation | MATLAB Syntax | Python / NumPy Syntax | Meaning |
| :--- | :--- | :--- | :--- |
| **Single Element** | `val = A(row, col);` | `val = A[row - 1, col - 1]` | Row, column lookup |
| **Entire Row** | `r1 = A(1, :);` | `r1 = A[0, :]` | First row |
| **Entire Column** | `c2 = A(:, 2);` | `c2 = A[:, 1]` | Second column |
| **Submatrix** | `sub = A(1:3, 2:4);` | `sub = A[0:3, 1:4]` | Rows 1 to 3, cols 2 to 4 |
| **Last Element** | `last = x(end);` | `last = x[-1]` | `end` keyword resolves to size |
| **Second to Last** | `pen = x(end - 1);` | `pen = x[-2]` | Arithmetic with `end` |
| **Strided Slicing** | `s = x(1:2:end);` | `s = x[::2]` | Every 2nd element |
| **Logical Masking** | `pos = x(x > 0);` | `pos = x[x > 0]` | Conditional boolean filtering |
| **Flatten to Column** | `col = A(:);` | `col = A.flatten('F')` | Column-major (Fortran) order |

---

## 4. Matrix Math vs Element-Wise Operations

MATLAB distinguishes linear algebraic matrix operators from element-wise array operators by prefixing a dot (`.`):

| Mathematical Intent | Linear Algebraic Operator | Element-Wise Operator | Example & Behavior |
| :--- | :--- | :--- | :--- |
| **Multiplication** | `C = A * B;` | `C = A .* B;` | `*`: Matrix inner product $(m \times k)(k \times n)$<br>`.*`: Hadamard product $C_{ij} = A_{ij} B_{ij}$ |
| **Right Division** | `X = B / A;` ($B A^{-1}$) | `C = A ./ B;` | `./`: Element-wise division $C_{ij} = A_{ij} / B_{ij}$ |
| **Left Division** | `X = A \ B;` ($A^{-1} B$) | `C = A .\ B;` | `\`: Gaussian elimination backslash solver! |
| **Exponentiation** | `M = A ^ 2;` ($A \cdot A$) | `M = A .^ 2;` | `^`: Matrix power (square matrices only)<br>`.^`: Element-wise power $M_{ij} = A_{ij}^2$ |
| **Transpose** | `T = A';` (Conjugate) | `T = A.';` (Unconjugated) | `'`: Complex conjugate transpose $A^H$<br>`.'`: Non-conjugate array transpose $A^T$ |

---

## 5. Control Flow & Functions

### Conditional Statements
```matlab
if temperature > 85.0
    status = "OVERHEAT";
    cooling_pump = true;
elseif temperature > 60.0
    status = "NOMINAL";
    cooling_pump = false;
else
    status = "COLD";
    cooling_pump = false;
end
```

### Iteration Loops
```matlab
% For loop over sequence
for k = 1:N
    state(k) = state(k) + alpha * error(k);
end

% While loop with convergence condition
tolerance = 1e-6;
while norm(residual) > tolerance
    residual = A * x - b;
    x = x - alpha * (A' * residual);
end
```

### User-Defined Functions with Multiple Outputs
```matlab
function [mean_val, std_val, snr_db] = analyze_sensor(raw_data)
    % ANALYZE_SENSOR Computes descriptive statistics and SNR of telemetry.
    % Inputs:  raw_data (Nx1 double vector)
    % Outputs: mean_val, std_val, snr_db
    
    mean_val = mean(raw_data);
    std_val  = std(raw_data);
    
    signal_power = mean_val^2;
    noise_power  = std_val^2;
    snr_db       = 10 * log10(signal_power / noise_power);
end
```

### Anonymous Functions (Function Handles)
```matlab
% Syntax: handle = @(arg1, arg2) expression
f_loss = @(w) 0.5 * sum((X * w - y).^2) + 0.5 * lambda * norm(w)^2;
dydt   = @(t, y) -k_cooling * (y - T_ambient);
```

---

## 6. Plotting & Engineering Dashboards

```matlab
figure('Name', 'Telemetry Dashboard', 'Color', 'w');

% 2x2 Subplot Layout
subplot(2, 2, 1);
plot(t, speed_rpm, 'b-', 'LineWidth', 1.5);
hold on;
plot(t, speed_setpoint, 'r--', 'LineWidth', 1.2);
xlabel('Time [seconds]');
ylabel('Motor Speed [RPM]');
title('Kinematic Tracking');
grid on;
legend('Actual Speed', 'Setpoint', 'Location', 'northeast');

% Dual Y-Axis Plotting
subplot(2, 2, 2);
yyaxis left;
plot(t, voltage_v, 'g-', 'LineWidth', 1.5);
ylabel('Bus Voltage [V]');

yyaxis right;
plot(t, current_a, 'm-', 'LineWidth', 1.5);
ylabel('Battery Current [A]');
xlabel('Time [seconds]');
title('DC Electrical Bus');
grid on;
```

---

## 7. Golden Debugging Rules

1. **Backslash over Inverse**: Never write `x = inv(A) * b`. Always write `x = A \ b`. It is $3\times$ faster and numerically stable.
2. **Dimension Consistency**: For $A\mathbf{x} = \mathbf{b}$, if $A$ is $m \times n$, then $\mathbf{b}$ must be $m \times 1$. If $\mathbf{b}$ is $1 \times m$, use `b = b(:);` to force a column.
3. **Array Bounds**: Check `length(diff(y))` vs `length(y)`. `diff` drops 1 element ($N-1$). Use `gradient(y, dt)` or align midpoints `t_mid = (t(1:end-1) + t(2:end)) / 2`.
4. **Vectorization**: Replace explicit element-wise `for` loops with vectorized matrix multiplications and logical indexing for $10\times$ to $100\times$ speedups.
