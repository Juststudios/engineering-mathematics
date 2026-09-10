# MATLAB Fundamentals & Computational Environment

Welcome to Module 1 of the **Engineering Mathematics + MATLAB Teaching Package (Level 2)**. This curriculum bridges the gap between introductory scientific scripting (Level 1: Python, NumPy, Pandas, Matplotlib) and advanced predictive modeling and control (Level 3: Machine Learning, Deep Learning, and Advanced Robotics).

In this module, you will master MATLAB as a high-performance matrix-first computational laboratory designed specifically for physical engineering systems.

---

## 1. Learning Objectives

By the end of this module, you will be able to:
- **Remember (Recall):** Define core MATLAB data types (`double`, `single`, `uint16`, `logical`), memory management primitives (`clear`, `clc`, `close all`, `whos`), and 1-based indexing rules.
- **Understand (Comprehend):** Contrast matrix algebraic operations (`*`, `/`, `^`) with element-wise array operations (`.*`, `./`, `.^`), articulating the exact mathematical and physical reasons for their distinction.
- **Apply:** Construct row/column vectors, 2D/3D matrices, and multi-channel engineering telemetry arrays using uniform generation routines (`linspace`, `zeros`, `ones`, `eye`, `rand`).
- **Analyze:** Diagnose and resolve common runtime errors, dimension mismatches, silent broadcasting bugs, and un-preallocated dynamic memory slowdowns in engineering scripts.
- **Evaluate:** Compare computational paradigms between Python/NumPy (row-major, 0-based, explicit `@` matrix operator) and MATLAB (column-major, 1-based, implicit 2D matrix model), choosing the appropriate toolchain for simulation vs production deployment.
- **Create:** Build robust, vectorized user-defined functions with input validation, local helpers, and publication-ready multi-axis visualization dashboards (`plot`, `subplot`, `surf`, `contour`).

---

## 2. Why Engineers Need This

In real-world engineering—across aerospace (NASA, Boeing), automotive powertrain (Tesla, Bosch, GM), robotics (Boston Dynamics), and medical instrumentation—MATLAB is not just a programming language; it is the industry standard environment for modeling physical reality.

### From General Scripting (Level 1) to Matrix Laboratory (Level 2)
In Level 1, you learned Python, NumPy, and Pandas. While Python is an expressive, general-purpose software language, MATLAB was engineered from the silicon up for **Matrix Laboratory** operations. 
1. **Hardware & Physics Native:** In MATLAB, everything is a double-precision floating-point matrix by default. A single number like `42` is not a scalar object; it is a $1 \times 1$ matrix. This design eliminates boilerplate array wrappers when formulating equations of motion, structural stiffness matrices, or state-space models.
2. **Deterministic Embedded Deployment:** MATLAB algorithms directly synthesize into hardware-in-the-loop (HIL) systems, C/C++ code via MATLAB Coder, and FPGA bitstreams via HDL Coder. Understanding MATLAB's strict memory and data type conventions is mandatory for aerospace flight software and automotive ECU firmware.
3. **High-Integrity Toolboxes:** From aerospace flight dynamics to RF communications and SIMULINK dynamic system simulation, MATLAB provides mathematically verified, deterministic algorithms certified for safety-critical systems.

Transitioning from Python to MATLAB requires adjusting your mental model: moving from 0-based, row-major, pointer-based container thinking to 1-based, column-major, vector-field thinking.

---

## 3. Mathematical Intuition

### The Mental Model: Thinking in Vector Fields Instead of Loops
Classical procedural programming teaches you to process data one scalar at a time inside a `for` loop:
$$\text{For each time step } t_k: \quad v[t_k] = a \cdot t_k$$

In physics and engineering mathematics, however, physical fields do not exist as isolated sequential events; they exist as **continuous continuum states** sampled simultaneously across time or space:
$$\vec{v} = a \vec{t}$$

When you write vectorized MATLAB code:
```matlab
v = a * t; % t is a 1xN vector of timestamps
```
you are directly commanding the CPU’s Single Instruction, Multiple Data (SIMD) vector registers (AVX-512, NEON) to perform arithmetic across contiguous blocks of memory in parallel. The loop is pushed down into highly optimized BLAS (Basic Linear Algebra Subprograms) and LAPACK libraries written in Fortran and C. 

### Why MATLAB Distinguishes Matrix Math vs Element-Wise Math
In pure mathematics, the symbol "$\times$" or juxtaposition $AB$ is reserved strictly for the linear transformation of vectors and vector spaces:
- Matrix multiplication ($C = A B$) represents the composition of linear maps. The $(i, j)$-th entry is the inner product of the $i$-th row of $A$ and the $j$-th column of $B$.
- In contrast, physical sensors often collect parallel independent time-series signals. If vector $\vec{v}$ represents voltage across a resistor over 1,000 milliseconds, and vector $\vec{i}$ represents current through that resistor over the same 1,000 milliseconds, what is the instantaneous power $p(t)$?
  $$p(t_k) = v(t_k) \cdot i(t_k)$$
  This is NOT an inner product (which would sum all power across all time into a single scalar); it is an **element-by-element Hadamard product**. 

MATLAB enforces this distinction cleanly:
- `*` is the linear algebra transformation operator.
- `.*` is the physical point-by-point Hadamard operator.
Forgetting the dot (`.`) is not merely a syntax error; it is a category error confusing linear coordinate transformations with point-by-point physical observations!

---

## 4. Formal Mathematics & Governing Equations

### 4.1 Matrix Representation and Dimensionality
A matrix $A \in \mathbb{R}^{m \times n}$ has $m$ rows and $n$ columns:
$$A = \begin{bmatrix} 
a_{1,1} & a_{1,2} & \cdots & a_{1,n} \\
a_{2,1} & a_{2,2} & \cdots & a_{2,n} \\
\vdots & \vdots & \ddots & \vdots \\
a_{m,1} & a_{m,2} & \cdots & a_{m,n}
\end{bmatrix}$$

In MATLAB:
- Row indices $i$ run from $1$ to $m$ ($1 \le i \le m$).
- Column indices $j$ run from $1$ to $n$ ($1 \le j \le n$).
- Size query: `[m, n] = size(A);`

### 4.2 Memory Mapping: Column-Major Storage (Fortran Order)
In computer memory (RAM), data is stored in a 1-dimensional array of addresses. MATLAB stores matrices in **column-major order**, meaning elements of column 1 are stored contiguously, followed by column 2, and so on.

The 1D linear index $k$ of element $A_{i,j}$ in an $m \times n$ matrix is governed by:
$$\text{Index}(i, j) = (j - 1) \cdot m + i \quad \text{where } 1 \le i \le m, \, 1 \le j \le n$$

Conversely, given a linear index $k \in \{1, 2, \dots, m \cdot n\}$:
$$j = \left\lfloor \frac{k - 1}{m} \right\rfloor + 1, \qquad i = ((k - 1) \pmod m) + 1$$

*Engineering Impact:* Accessing matrix elements down columns (`A(:, j)`) is dramatically faster than across rows (`A(i, :)`) for large matrices because column-wise access maximizes CPU cache line hits. (NumPy defaults to row-major/C-order, where accessing rows is faster).

### 4.3 Matrix Multiplication vs. Hadamard (Element-Wise) Product
Given $A \in \mathbb{R}^{m \times p}$ and $B \in \mathbb{R}^{p \times n}$:

1. **Matrix Product** $C = A * B \in \mathbb{R}^{m \times n}$:
   $$C_{i,j} = \sum_{k=1}^p A_{i,k} B_{k,j} = A_{i,:} \cdot B_{:,j}$$
   *Requirement:* Number of columns in $A$ must equal number of rows in $B$ ($p$).

2. **Hadamard (Element-Wise) Product** $D = A .* B \in \mathbb{R}^{m \times n}$ (where $A, B \in \mathbb{R}^{m \times n}$):
   $$D_{i,j} = A_{i,j} \cdot B_{i,j}$$
   *Requirement:* Dimensions of $A$ and $B$ must match exactly (or be singleton-expandable via implicit broadcasting).

### 4.4 Vector Inner Product vs Outer Product
Let $\vec{u}, \vec{v} \in \mathbb{R}^{n \times 1}$ be column vectors:
- **Inner Product (Dot Product):** A scalar reflecting alignment / projection:
  $$\langle \vec{u}, \vec{v} \rangle = \vec{u}^T \vec{v} = \sum_{k=1}^n u_k v_k \quad (\text{MATLAB: } u' * v \text{ or } \text{dot}(u, v))$$
- **Outer Product:** A rank-1 matrix representing cross-space interactions:
  $$M = \vec{u} \vec{v}^T \in \mathbb{R}^{n \times n}, \quad M_{i,j} = u_i v_j \quad (\text{MATLAB: } u * v')$$

---

## 5. Worked Engineering Example: Accelerometer Calibration & Signal Energy

### Problem Formulation
An aerospace test bench monitors an industrial piezoelectric accelerometer attached to a turbofan engine casing. 
- The sensor outputs a raw analog voltage $V_{\text{raw}}$ through a 12-bit Analog-to-Digital Converter (ADC).
- The ADC quantizes $0\text{ V} \dots 3.3\text{ V}$ into integer counts $D \in [0, 4095]$.
- Sensor calibration equation:
  $$a(t) = S \cdot \left( V(t) - V_{\text{bias}} \right)$$
  where:
  - $S = 50.0 \text{ m/s}^2/\text{V}$ (Sensitivity slope)
  - $V_{\text{bias}} = 1.650 \text{ V}$ (Zero-g bias offset)
- Sampling rate: $f_s = 1000 \text{ Hz}$, sampled over $N = 5$ time steps for manual verification:
  $$t = [0.000, 0.001, 0.002, 0.003, 0.004] \text{ s}$$
- Recorded ADC counts:
  $$D = [2048, 2296, 2668, 2296, 1800]$$

### Step-by-Step Hand Calculations

1. **Convert ADC counts to Voltage:**
   $$V_k = D_k \cdot \left( \frac{3.300 \text{ V}}{4095} \right)$$
   - $V_1 = 2048 \cdot \frac{3.3}{4095} = 1.6500 \text{ V}$
   - $V_2 = 2296 \cdot \frac{3.3}{4095} = 1.8499 \text{ V}$
   - $V_3 = 2668 \cdot \frac{3.3}{4095} = 2.1493 \text{ V}$
   - $V_4 = 2296 \cdot \frac{3.3}{4095} = 1.8499 \text{ V}$
   - $V_5 = 1800 \cdot \frac{3.3}{4095} = 1.4505 \text{ V}$

2. **Compute Physical Acceleration $a_k = 50.0 \cdot (V_k - 1.650)$:**
   - $a_1 = 50.0 \cdot (1.6500 - 1.650) = 0.000 \text{ m/s}^2$
   - $a_2 = 50.0 \cdot (1.8499 - 1.650) = 9.995 \text{ m/s}^2$
   - $a_3 = 50.0 \cdot (2.1493 - 1.650) = 24.965 \text{ m/s}^2$
   - $a_4 = 50.0 \cdot (1.8499 - 1.650) = 9.995 \text{ m/s}^2$
   - $a_5 = 50.0 \cdot (1.4505 - 1.650) = -9.975 \text{ m/s}^2$

3. **Compute Root-Mean-Square (RMS) Vibration Severity:**
   The RMS metric quantifies total vibration power:
   $$a_{\text{RMS}} = \sqrt{ \frac{1}{N} \sum_{k=1}^N a_k^2 }$$
   - Squared accelerations:
     $$a^2 = [0.000, 99.90, 623.25, 99.90, 99.50] \text{ m}^2/\text{s}^4$$
   - Sum of squares:
     $$\sum a_k^2 = 922.55 \text{ m}^2/\text{s}^4$$
   - Mean square:
     $$\frac{922.55}{5} = 184.51 \text{ m}^2/\text{s}^4$$
   - Square root:
     $$a_{\text{RMS}} = \sqrt{184.51} \approx 13.583 \text{ m/s}^2$$

---

## 6. MATLAB Implementation

Here is how this entire physical calibration is written in idiomatic, vectorized MATLAB:

```matlab
% Accelerometer Telemetry Calibration and Metric Calculation
clear; clc;

% 1. Parameters & Constants
fs = 1000;              % Sampling frequency (Hz)
dt = 1 / fs;            % Time step (s)
V_ref = 3.3;            % ADC reference voltage (V)
ADC_max = 4095;         % 12-bit ADC ceiling
sensitivity = 50.0;     % Sensitivity (m/s^2 per Volt)
V_bias = 1.650;         % Null bias voltage (V)

% 2. Telemetry Vectors
D = [2048, 2296, 2668, 2296, 1800]; % Raw ADC integer counts
N = length(D);
t = (0:N-1) * dt;                   % Time vector [s]

% 3. Vectorized Calibration Pipeline
V = D .* (V_ref / ADC_max);         % Element-wise voltage scaling
a = sensitivity .* (V - V_bias);    % Physical acceleration (m/s^2)

% 4. Statistical Energy Metrics
a_mean = mean(a);                   % Mean acceleration (bias check)
a_rms  = sqrt(mean(a .^ 2));        % RMS vibration power (m/s^2)
a_peak = max(abs(a));               % Peak shock load (m/s^2)

% 5. Print Formatted Engineering Report
fprintf('--- Telemetry Calibration Report ---\n');
fprintf('Sample Count    : %d samples\n', N);
fprintf('Mean Offset     : %7.3f m/s^2\n', a_mean);
fprintf('RMS Vibration   : %7.3f m/s^2\n', a_rms);
fprintf('Peak Acceleration: %7.3f m/s^2\n', a_peak);
```

Notice how clean the vectorized statements are: zero `for` loops, maximum execution speed, and direct mathematical correspondence to our governing equations.

---

## 7. Common Student Pitfalls & Debugging Tips

### Pitfall 1: 1-Based Indexing vs 0-Based Indexing
In Python/C, arrays start at index `0`. In MATLAB, arrays start at index `1`.
- **Bug:** `first_val = a(0);`
- **MATLAB Error:** `Index in position 1 is invalid. Array indices must be positive integers or logical values.`
- **Fix:** Always index starting from `1`: `first_val = a(1);`. The last element is `a(end)`.

### Pitfall 2: Omitting the Dot (`.`) in Element-Wise Math
- **Bug:** `power = v * i;` where `v` and `i` are $1 \times 1000$ row vectors.
- **MATLAB Error:** `Error using  *  Incorrect dimensions for matrix multiplication. Check that the number of columns in the first matrix matches the number of rows in the second matrix.`
- **Fix:** Use `.*` for element-wise multiplication: `power = v .* i;`. Similarly, use `a .^ 2` instead of `a ^ 2`.

### Pitfall 3: Semicolon Suppression
MATLAB displays the result of any statement that does not terminate with a semicolon `;`.
- If you generate an audio waveform vector of $1{,}000{,}000$ samples without a semicolon:
  ```matlab
  t = 0:1e-6:1  % NO SEMICOLON!
  ```
  MATLAB will attempt to dump 1 million numbers to the Command Window, freezing your terminal and consuming gigabytes of console buffer memory.
- **Rule:** Always end calculation lines with a semicolon `;`. Use explicit `disp()` or `fprintf()` when you wish to present data.

### Pitfall 4: Dynamic Array Growth (No Preallocation)
Growing an array inside a loop causes memory thrashing:
```matlab
% BAD: MATLAB re-allocates and copies the entire array on every iteration!
for k = 1:100000
    y(k) = sin(k * 0.01); 
end

% GOOD: Preallocate the exact memory block once:
y = zeros(1, 100000);
for k = 1:100000
    y(k) = sin(k * 0.01);
end
```

### Pitfall 5: Row Vector vs Column Vector Concatenation
- Comma `,` or space concatenates horizontally (adds columns): `[ [1, 2], [3, 4] ] -> 1x4`
- Semicolon `;` concatenates vertically (adds rows): `[ [1, 2]; [3, 4] ] -> 2x2`
- Attempting to vertically concatenate mismatched lengths `[ [1, 2]; [3, 4, 5] ]` throws: `Dimensions of arrays being concatenated are not consistent.`

---

## 8. Engineering Interpretation

When analyzing numerical outputs in MATLAB:
1. **Precision & Condition:** All calculations use IEEE 754 double precision (64 bits, ~15-17 significant decimal digits) unless cast otherwise. Small round-off residuals like `1.4211e-16` are numerical zeros caused by floating-point truncation, not real physical signals.
2. **Memory Footprint:** Each double-precision value requires 8 bytes of RAM. A $1000 \times 1000$ double matrix consumes:
   $$\text{RAM} = 1000 \times 1000 \times 8 \text{ bytes} \approx 8 \text{ Megabytes (MB)}$$
   Use `whos` to monitor your workspace memory when working with large sensory datasets or image frames.
3. **Execution Profiling:** In engineering simulation, compute time directly translates to design turnaround time. Vectorized operations run 20x to 100x faster than interpreted `for` loops because they leverage compiled AVX SIMD instructions and bypass MATLAB interpreter overhead.

---

## 9. Progressive Exercises Overview

To cement your understanding, navigate to `exercises.m` in this directory. The exercises follow a 4-tier progressive mastery model:

| Level | Name | Objective | Description |
|---|---|---|---|
| **Level 1** | **Recall** | Syntax & Primitives | Construct row/col vectors, generate test grids, perform element-wise transformations, and practice 1-based indexing. |
| **Level 2** | **Understanding & Debugging** | Diagnosing Pitfalls | Identify and fix 4 real-world broken MATLAB scripts containing dimension mismatches, missing dots, and indexing traps. |
| **Level 3** | **Application** | Sensor Calibration | Implement a complete multi-channel thermocouple and strain-gauge telemetry calibration pipeline with outlier rejection. |
| **Level 4** | **Challenge** | Telemetry Pipeline | Design an asynchronous dual-rate sensor fusion calculation: compute instantaneous electrical and mechanical motor power, power factor, and thermal gradients. |

*Self-Assessment:* Work through `exercises.m` independently using the `% TODO` prompts. Once complete, verify your solutions against the complete reference implementations in `solutions/matlab_exercises_solution.m`.
