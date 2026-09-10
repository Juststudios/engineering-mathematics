# Simulink Block Diagram Basics: Signals, Operations & Feedback

## Overview

Simulink is a graphical modeling environment built on top of MATLAB for modeling, simulating, and analyzing multidomain dynamic systems. At its core, Simulink translates differential and difference equations into intuitive **signal-flow block diagrams**.

In procedural programming, you write step-by-step algorithms that update numerical arrays in memory. In Simulink, you create an interconnected graph where:
1. **Blocks** represent mathematical operations, dynamic state storage, or physical transfer functions.
2. **Lines (Signals)** represent time-varying quantities (voltages, temperatures, velocities, currents) propagating continuously or discretely from output ports to input ports.

---

## 1. Anatomy of a Block Diagram

A Simulink model consists of four fundamental structural elements:

```
┌──────────┐   Signal Line (Time-Series)   ┌──────────────┐                  ┌──────────┐
│  Source  ├──────────────────────────────►│ Mathematical │─────────────────►│   Sink   │
│  (Input) │                               │ Block (Gain) │                  │ (Output) │
└──────────┘                               └──────┬───────┘                  └──────────┘
                                                  │ Feedback Loop
                                                  ▼
                                           ┌──────────────┐
                                           │  Integrator  │
                                           │    (1/s)     │
                                           └──────────────┘
```

### 1.1 Blocks
Blocks are computational elements. Every block has:
- **Input Ports (Left):** Receive signals from upstream blocks.
- **Output Ports (Right):** Broadcast computed signals to downstream blocks.
- **Block Parameters:** Internal constants (e.g., gain values, step times, initial conditions) configured via double-clicking the block.
- **Internal States:** Blocks like Integrators ($1/s$) or Unit Delays ($z^{-1}$) maintain continuous or discrete memory across time steps.

### 1.2 Signals
Signals are the directed lines connecting blocks. A signal represents a dynamic variable $x(t)$ defined over simulation time $t \in [0, t_{\text{final}}]$. Signals can be:
- **Scalar Signals:** A single 1D time-series (e.g., scalar voltage $V(t)$).
- **Vector Signals:** Multiple parallel physical quantities (e.g., 3-axis acceleration $[a_x, a_y, a_z]^T$).
- **Bus Signals:** Bundled heterogeneous signals (analogous to a C `struct` or MATLAB `struct`) carrying telemetry data.

---

## 2. Fundamental Block Categories

### 2.1 Sources (Signal Generators)
Sources inject excitation into the dynamic model. They have only output ports and no input ports.

| Block Name | Mathematical Equivalent | Key Parameters | Engineering Use Case |
| :--- | :--- | :--- | :--- |
| **Constant** | $u(t) = C$ | `Value` (e.g., $12.0$) | Regulated DC voltage, constant ambient temperature $T_{\text{amb}}$. |
| **Step** | $u(t) = \begin{cases} u_0 & t < t_{\text{step}} \\ u_f & t \ge t_{\text{step}} \end{cases}$ | `Step time`, `Initial value`, `Final value` | Transient step response testing (throttle tip-in, load switch). |
| **Ramp** | $u(t) = \text{Slope} \cdot (t - t_{\text{start}})$ | `Slope`, `Start time` | Gradual torque ramp to prevent mechanical jerk. |
| **Sine Wave** | $u(t) = A \sin(\omega t + \phi) + B$ | `Amplitude`, `Frequency (rad/s)`, `Phase`, `Bias` | AC line excitation, harmonic vibration testing, Bode frequency response. |
| **Clock** | $u(t) = t$ | `Decimation` | Driving time-dependent parametric functions. |
| **From Workspace** | $u(t) = \text{interp1}(t_{\text{data}}, u_{\text{data}}, t)$ | `Data`, `Interpolate` | Replaying recorded experimental telemetry (e.g. drive cycles). |

### 2.2 Sinks (Output Capture & Visualization)
Sinks terminate signal paths, recording data or rendering visual plots. They have input ports and no output ports.

| Block Name | Purpose | Configuration Options | Engineering Value |
| :--- | :--- | :--- | :--- |
| **Scope** | Real-time oscilloscope display | Number of input axes, time range, trigger | Instant visual inspection of transient oscillations and overshoot. |
| **To Workspace** | Logs time-series data directly to MATLAB | `Variable name`, `Save format` (`Timeseries` or `Array`) | Post-simulation statistical analysis, FFT spectral processing, reporting. |
| **Display** | Shows numerical value at the current time step | `Format` (`short`, `long`, `bank`) | Quick monitoring of steady-state final values. |
| **Outport** | Exposes an output port to a parent subsystem | `Port number` | Hierarchical modular subsystem encapsulation. |

### 2.3 Mathematical Operations
These blocks perform algebraic manipulations on incoming signals.

```
Summing Junction (+ -):               Gain Block (K):
      u1(t) ───►(+)                          u(t) ───►[  K  ]───► y(t) = K · u(t)
                 │───► e(t) = u1 - u2
      u2(t) ───►(-)
```

- **Sum Block:** Computes the algebraic sum of inputs. Configured via the `List of signs` parameter (e.g., `|+-` for error subtraction $e = r - y$, or `|+++` for multi-force summation).
- **Gain Block:** Multiplies the input signal by a scalar or matrix constant $y(t) = K \cdot u(t)$. In matrix mode, supports `Matrix (K*u)` or `Matrix (u*K)`.
- **Product Block:** Computes element-wise multiplication or division ($y = u_1 \times u_2$ or $y = u_1 / u_2$).
- **Math Function:** Performs transcendental math: $\exp(u)$, $\log(u)$, $u^2$, $\sqrt{u}$.

### 2.4 Dynamic Continuous Blocks
Continuous blocks hold internal states governed by differential equations.

- **Integrator ($1/s$):**
  $$y(t) = y(0) + \int_0^t u(\tau) \, d\tau \iff \dot{y}(t) = u(t)$$
  *Crucial Parameters:*
  - `Initial condition`: $y(0)$ (starting voltage, starting speed, starting position).
  - `Limit output`: Lower and upper clamping limits to model physical saturation (e.g. tank volume $0 \le V \le 100\text{ L}$).
  - `External reset`: Allows an external trigger signal to reset the accumulated state to zero.
- **Transfer Fcn:**
  Represents linear time-invariant differential equations in the Laplace domain:
  $$G(s) = \frac{\text{Numerator}}{\text{Denominator}} = \frac{b_m s^m + \dots + b_0}{a_n s^n + \dots + a_0}$$
  *Example:* A first-order low-pass filter with $\tau = 0.5\text{ s}$ has `Numerator = [1]`, `Denominator = [0.5, 1]`.
- **State-Space:**
  Executes $\dot{\mathbf{x}} = \mathbf{A}\mathbf{x} + \mathbf{B}\mathbf{u}$, $\mathbf{y} = \mathbf{C}\mathbf{x} + \mathbf{D}\mathbf{u}$ using predefined system matrices.

---

## 3. Feedback Loops: The Cornerstone of Control

Dynamic systems are divided into two fundamental architectures:

### 3.1 Open-Loop Systems
In an open-loop architecture, the control input $u(t)$ is applied without measuring the actual output $y(t)$:

```
Set-Point r(t) ──────►[ Controller ]──────►[ Plant: G(s) ]──────► Output y(t)
```

- **Limitation:** Open-loop systems cannot correct for external disturbances, load changes, or parameter drift (e.g., a motor slows down when going uphill).

### 3.2 Closed-Loop (Feedback) Systems
Negative feedback measures the actual output $y(t)$ via a sensor, compares it against the set-point $r(t)$, and uses the resulting error $e(t) = r(t) - y(t)$ to drive the system:

```
        r(t)        e(t)             u(t)
Target ─────►(+)───────►[ Controller ]───►[ Plant G(s) ]───┬───► Actual y(t)
              ▲ -                                          │
              │             Measured y_m(t)                │
              └─────────[ Sensor H(s) ]◄───────────────────┘
```

The closed-loop transfer function is derived algebraically in the Laplace domain:
$$E(s) = R(s) - H(s) Y(s)$$
$$Y(s) = G(s) C(s) E(s) = G(s) C(s) [R(s) - H(s) Y(s)]$$
$$Y(s) [1 + C(s) G(s) H(s)] = C(s) G(s) R(s)$$
$$T(s) = \frac{Y(s)}{R(s)} = \frac{C(s) G(s)}{1 + C(s) G(s) H(s)}$$

For unity feedback ($H(s) = 1$):
$$T(s) = \frac{C(s) G(s)}{1 + C(s) G(s)}$$

---

## 4. Sample Time Concepts ($T_s$)

Every block in Simulink operates under a specific timing schedule called **Sample Time**:

1. **Continuous Sample Time ($T_s = 0$):**
   - The state updates continuously at infinitesimal time steps determined by the variable-step ODE solver.
   - Used for physical plants: circuits, mechanical linkages, thermal bodies.
   - Display color in Simulink: **Black**.
2. **Discrete Sample Time ($T_s > 0$):**
   - The block executes periodically at fixed intervals (e.g., $T_s = 0.01\text{ s}$ for a $100\text{ Hz}$ control loop).
   - Used for digital controllers, Kalman filters, software tasks running on a microcontroller.
   - Display color in Simulink: **Red** (fastest), **Green**, or **Blue**.
3. **Inherited Sample Time ($T_s = -1$):**
   - The block inherits its rate from the driving upstream block.
   - Used for generic math blocks (Gain, Sum, Product).
   - Display color in Simulink: **Yellow**.

```
Physical Continuous World              Digital Software World
    [ RC Circuit Plant ]   ◄─── ZOH ─── [ Digital PI Controller ]
         (Ts = 0)            (Ts = 0.01)       (Ts = 0.01 s)
```

---

## 5. Signal Routing & Hierarchical Organization

As models grow to thousands of blocks, proper signal routing is essential:

- **Mux & Demux:** The `Mux` block bundles scalar signals into a virtual vector; `Demux` unpacks vectors back into individual scalar signals.
- **Bus Creator & Bus Selector:** Bundles named signals into a structured bus, making large models legible.
- **Subsystems (`Ctrl+G`):** Encapsulates a cluster of blocks into a single modular block with distinct inputs and outputs.
- **Goto & From Blocks:** Transfers signals wirelessly across a subsystem without cluttering the diagram with intersecting visual lines.

---

## 6. Programmatic Model Construction in MATLAB

While models are usually built interactively in the Simulink graphical editor, MATLAB scripts can programmatically construct and configure models using the Simulink API:

```matlab
% programmatic_model_demo.m
% Demonstrates creating a 1st-order Simulink model via MATLAB script commands

% 1. Create a new empty model
model_name = 'rc_programmatic_model';
new_system(model_name);
open_system(model_name);

% 2. Add blocks from standard libraries
add_block('simulink/Sources/Step', [model_name, '/Step_Input'], ...
    'Time', '0.1', 'Before', '0', 'After', '5', 'Position', [50, 100, 80, 130]);

add_block('simulink/Math Operations/Sum', [model_name, '/Sum'], ...
    'Inputs', '+-', 'Position', [140, 105, 160, 125]);

add_block('simulink/Math Operations/Gain', [model_name, '/Gain_InvTau'], ...
    'Gain', '1.0', 'Position', [210, 100, 250, 130]);

add_block('simulink/Continuous/Integrator', [model_name, '/Integrator'], ...
    'InitialCondition', '0', 'Position', [300, 100, 330, 130]);

add_block('simulink/Sinks/Scope', [model_name, '/Scope'], ...
    'Position', [400, 90, 430, 120]);

add_block('simulink/Sinks/To Workspace', [model_name, '/ToWorkspace'], ...
    'VariableName', 'sim_out', 'SaveFormat', 'Timeseries', ...
    'Position', [400, 140, 450, 170]);

% 3. Connect blocks with signal lines
add_line(model_name, 'Step_Input/1', 'Sum/1');
add_line(model_name, 'Sum/1', 'Gain_InvTau/1');
add_line(model_name, 'Gain_InvTau/1', 'Integrator/1');
add_line(model_name, 'Integrator/1', 'Scope/1');
add_line(model_name, 'Integrator/1', 'ToWorkspace/1');

% Negative feedback branch
add_line(model_name, 'Integrator/1', 'Sum/2');

% 4. Configure simulation parameters and save
set_param(model_name, 'StopTime', '5.0', 'Solver', 'ode45');
save_system(model_name);
```

This establishes the foundational block diagram vocabulary used throughout dynamic system modeling.
