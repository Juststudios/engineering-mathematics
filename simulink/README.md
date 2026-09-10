# Simulink for Beginners: Dynamic System Modeling

Welcome to the **Simulink for Beginners** module of the Engineering Mathematics curriculum. In Level 1, you manipulated static arrays and tabular data using Python, NumPy, and Pandas. In earlier Level 2 modules, you analyzed algebraic equations with matrices and integrated differential equations using MATLAB scripts.

In industrial engineering practice, however, systems are rarely analyzed in static isolation. Modern engineering products—such as electric vehicle powertrains, quadcopter flight controllers, robotic manipulators, and biomedical infusion pumps—are complex, multidomain dynamic systems where mechanical, electrical, thermal, and algorithmic subsystems interact continuously in real time.

Simulink is the global standard platform for **Model-Based Design (MBD)**. Instead of writing thousands of lines of low-level procedural code to advance numerical integration loops, Simulink allows engineers to construct graphical signal-flow block diagrams. These graphical models directly represent physical differential equations, feedback control loops, and discrete digital controllers, enabling rapid simulation, automatic C/C++ code generation, and Hardware-in-the-Loop (HIL) verification.

---

## 1. Learning Objectives

By completing this module, you will be able to:

1. **Translate** ordinary differential equations (ODEs) describing physical systems into graphical signal-flow block diagrams using integrators ($1/s$), summing junctions, gains, and feedback loops.
2. **Configure** fundamental Simulink block types: continuous states, time-domain signal sources (Step, Ramp, Sine Wave), sinks (Scope, To Workspace), and non-linear operators (Saturation, Dead Zone).
3. **Analyze** the operational differences between variable-step ODE solvers (`ode45`, `ode23`, `ode15s`) and fixed-step solvers (`ode1`, `ode4`), selecting appropriate algorithms based on system stiffness and real-time execution constraints.
4. **Identify**, **diagnose**, and **resolve** algebraic loops and numerical chattering caused by direct-feedthrough loops without state dynamics.
5. **Formulate** and **simulate** dynamic multi-domain models: first-order electrical RC filters, first-order Newton thermal cooling, and second-order electromechanical DC motors.
6. **Design** and **tune** closed-loop feedback controllers (Proportional-Integral speed control) with anti-windup to achieve target transient metrics (rise time, settling time, overshoot, steady-state error).
7. **Write** standalone MATLAB companion scripts that mirror Simulink block-diagram models using numerical solvers (`ode45`), validating graphical simulations against analytical solutions.

---

## 2. Why Engineers Need This

In modern engineering organizations (aerospace, automotive, robotics, renewable energy), manual hand-coding of low-level differential equation solvers for production controllers is obsolete. The industry relies on **Model-Based Design (MBD)**:

- **Automotive Powertrains:** Modern Electric Vehicles (EVs) coordinate battery management systems (BMS), inverter switching, and electric motor torque within sub-millisecond control loops. Engineers model the entire vehicle dynamics in Simulink to verify braking regeneration, traction control, and thermal limits before fabricating hardware.
- **Flight Control Systems:** Aerospace companies (NASA, Boeing, SpaceX) model aircraft aerodynamics, actuator hydraulics, and atmospheric disturbances as coupled block diagrams. The flight control laws are tuned inside Simulink and then automatically compiled into certified C code for deployment onto the flight computer.
- **Hardware-in-the-Loop (HIL) Testing:** Testing physical prototypes to failure is dangerous and expensive. With Simulink, an Electronic Control Unit (ECU) is connected to a real-time computer running a simulated vehicle or aircraft model at microsecond fixed time steps, validating fault handling under extreme simulated conditions.
- **Bridging Mathematics to Production:** Simulink bridges the gap between pure mathematics (transfer functions, state-space matrices, Laplace transforms) and physical implementation (embedded microcontrollers, DSPs, and FPGAs).

```
Level 1: Python Data Tools (Static Data & Dataframes)
                 │
                 ▼
Level 2: Engineering Mathematics & MATLAB (Differential Equations & ODE Solvers)
                 │
                 ▼
Level 2: Simulink Dynamic Modeling (Graphical Model-Based Design & Feedback Control)
                 │
                 ▼
Level 3: Machine Learning & Optimal Control (Predictive Control, Neural Controllers, HIL)
```

---

## 3. Mathematical Intuition

### From Differential Equations to Signal Flow
Every continuous physical system is governed by differential equations relating input forces, voltages, or heat flows to rates of change of state variables (velocity, charge, temperature).

In procedural programming, you might view integration as an active calculation step: $x_{k+1} = x_k + \Delta t \cdot f(x_k, u_k)$. In Simulink, the mental model is reversed:

> **The Central Axiom of Simulink:**
> **Integration is the fundamental operation.**
> You do NOT differentiate signals to find rates; you compute the highest-order derivative by summing known forces, and then pass that derivative through an **Integrator block ($1/s$)** to produce the physical state.

```
                  ┌───────────────────────────────┐
                  │    Physics: Newton's Law      │
Forces / Inputs ──► Sum of Forces: ΣF = m · a    ├──► Acceleration a(t)
                  └───────────────────────────────┘           │
                                                              ▼
                                                        ┌───────────┐
                                                        │ Integrator│
                                                        │   (1/s)   │
                                                        └─────┬─────┘
                                                              ▼
                                                        Velocity v(t)
                                                              │
                                                              ▼
                                                        ┌───────────┐
                                                        │ Integrator│
                                                        │   (1/s)   │
                                                        └─────┬─────┘
                                                              ▼
                                                        Position s(t)
```

### The Water Tank (Integrator) Metaphor
Think of an Integrator block as a water tank:
- The **input signal** is the net water inflow rate $\dot{V}(t) = \frac{dV}{dt}$ (liters per second).
- The **Integrator block ($1/s$)** accumulates this liquid over time.
- The **output signal** is the current water volume $V(t)$ (liters).
- The **initial condition ($x_0$)** is the water level already in the tank at $t = 0$.

If the tank has a leak at the bottom proportional to the water pressure (height), the outflow rate is $-k \cdot V(t)$. We feed the output $V(t)$ back through a negative gain $-k$ and sum it into the net flow rate input. This creates a **negative feedback loop** representing physical dissipation!

### The Feedback Loop
In open-loop systems, an input command travels strictly forward to produce an output. In closed-loop systems, the measured output is fed back and subtracted from the desired setpoint, forming an **error signal**:
$$e(t) = r(t) - y(t)$$
This error drives the controller to adjust the physical actuators until the error is driven to zero.

---

## 4. Formal Mathematics & Governing Equations

### 4.1 The Laplace Transform and the Integrator Operator $1/s$
In control engineering, linear time-invariant (LTI) systems are analyzed in the frequency domain using the Laplace transform:
$$\mathcal{L}\{f(t)\} = F(s) = \int_0^\infty f(t) e^{-st} \, dt$$

The differentiation property of the Laplace transform states that for zero initial conditions:
$$\mathcal{L}\left\{\frac{dx}{dt}\right\} = s X(s)$$

Inverting this relationship gives the integration property:
$$\mathcal{L}\left\{\int_0^t x(\tau) \, d\tau\right\} = \frac{1}{s} X(s)$$

Thus, in Simulink block diagrams, the label **$\frac{1}{s}$** designates an ideal continuous-time integrator.

### 4.2 First-Order Dynamic Systems
A standard first-order linear system with input $u(t)$ and output $y(t)$ is characterized by a time constant $\tau$ and steady-state gain $K$:
$$\tau \frac{dy}{dt} + y(t) = K u(t)$$

Solving for the state derivative:
$$\frac{dy}{dt} = \frac{1}{\tau} \big( K u(t) - y(t) \big)$$

In the Laplace domain, the transfer function is:
$$G(s) = \frac{Y(s)}{U(s)} = \frac{K}{\tau s + 1}$$

For a unit step input $u(t) = 1$ ($t \ge 0$) with initial condition $y(0) = 0$, the analytical time response is:
$$y(t) = K \left(1 - e^{-t / \tau}\right)$$

Key milestones of the first-order step response:
- At $t = \tau$: $y(\tau) = K(1 - e^{-1}) \approx 0.632 K$ ($63.2\%$ of final value).
- At $t = 2\tau$: $y(2\tau) \approx 0.865 K$ ($86.5\%$).
- At $t = 3\tau$: $y(3\tau) \approx 0.950 K$ ($95.0\%$).
- At $t = 4\tau$: $y(4\tau) \approx 0.982 K$ ($98.2\%$, standard engineering settling time $t_s$).

### 4.3 Second-Order Dynamic Systems
Many physical systems (RLC circuits, mass-spring-damper suspensions, DC motor shafts) involve two energy storage elements, resulting in a second-order differential equation:
$$\frac{d^2 y}{dt^2} + 2 \zeta \omega_n \frac{dy}{dt} + \omega_n^2 y(t) = K \omega_n^2 u(t)$$

where:
- $\omega_n$ is the **undamped natural frequency** ($\text{rad/s}$), dictating the response speed.
- $\zeta$ is the **damping ratio** (dimensionless), dictating the oscillatory behavior:
  - $\zeta > 1$: **Overdamped** (no oscillations, sluggish response).
  - $\zeta = 1$: **Critically damped** (fastest response without overshoot).
  - $0 < \zeta < 1$: **Underdamped** (oscillatory transient with peak overshoot).
  - $\zeta = 0$: **Undamped** (sustained harmonic oscillation at frequency $\omega_n$).

The corresponding Laplace transfer function is:
$$G(s) = \frac{Y(s)}{U(s)} = \frac{K \omega_n^2}{s^2 + 2\zeta\omega_n s + \omega_n^2}$$

For an underdamped system ($0 < \zeta < 1$), the transient step response metrics are:
- **Damped Natural Frequency:** $\omega_d = \omega_n \sqrt{1 - \zeta^2}$
- **Peak Time:** $t_p = \frac{\pi}{\omega_d}$
- **Percentage Overshoot:** $\%OS = 100 \times \exp\left(-\frac{\pi \zeta}{\sqrt{1 - \zeta^2}}\right)$
- **Settling Time ($2\%$ criterion):** $t_s \approx \frac{4}{\zeta \omega_n}$

### 4.4 State-Space Representation
For multi-input, multi-output (MIMO) or higher-order systems, Simulink evaluates dynamics using the canonical continuous-time state-space matrix formulation:
$$\dot{\mathbf{x}}(t) = \mathbf{A}\mathbf{x}(t) + \mathbf{B}\mathbf{u}(t)$$
$$\mathbf{y}(t) = \mathbf{C}\mathbf{x}(t) + \mathbf{D}\mathbf{u}(t)$$

where:
- $\mathbf{x}(t) \in \mathbb{R}^n$ is the state vector (energy storage variables: capacitor voltages, inductor currents, positions, velocities).
- $\mathbf{u}(t) \in \mathbb{R}^m$ is the external input vector (source voltages, external torques).
- $\mathbf{y}(t) \in \mathbb{R}^p$ is the output vector (sensor measurements).
- $\mathbf{A}, \mathbf{B}, \mathbf{C}, \mathbf{D}$ are constant system matrices.

---

## 5. Worked Engineering Example: Step Response of an RC Low-Pass Filter

### Problem Statement
Consider a first-order RC low-pass filter circuit commonly used for anti-aliasing in sensor telemetry acquisition:
- Resistor: $R = 10\text{ k}\Omega = 10{,}000\ \Omega$
- Capacitor: $C = 100\ \mu\text{F} = 100 \times 10^{-6}\text{ F}$
- Input Voltage: Step from $0\text{ V}$ to $V_0 = 5.0\text{ V}$ at $t = 0.1\text{ s}$
- Initial Capacitor Voltage: $v_C(0) = 0\text{ V}$

Determine:
1. The governing ordinary differential equation.
2. The circuit time constant $\tau$.
3. The block diagram topology required in Simulink.
4. The exact time required for the capacitor voltage to reach $63.2\%$ ($3.16\text{ V}$) and $98.0\%$ ($4.90\text{ V}$) of the steady-state supply voltage.

---

### Step-by-Step Mathematical Derivation

#### 1. Governing Differential Equation
Applying Kirchhoff's Current Law (KCL) at the capacitor node:
$$i_R(t) = i_C(t)$$

From Ohm's law and the capacitor constitutive equation ($i_C = C \frac{dv_C}{dt}$):
$$\frac{v_{\text{in}}(t) - v_C(t)}{R} = C \frac{dv_C}{dt}$$

Rearranging to isolate the state derivative $\frac{dv_C}{dt}$:
$$\frac{dv_C}{dt} = \frac{1}{RC} \big( v_{\text{in}}(t) - v_C(t) \big)$$

#### 2. Time Constant Calculation
$$\tau = R \cdot C = (10{,}000\ \Omega) \times (100 \times 10^{-6}\text{ F}) = 1.0\text{ second}$$

The steady-state DC gain is $K = 1.0\text{ V/V}$.

#### 3. Block Diagram Formulation
To construct this in Simulink:
1. **Source Block:** A `Step` block generating $v_{\text{in}}(t)$ ($5\text{ V}$ at $t = 0.1\text{ s}$).
2. **Summing Junction:** A `Sum` block with signs `|+ -|` computing error voltage $\Delta v = v_{\text{in}} - v_C$.
3. **Gain Block:** A `Gain` block multiplying by $K_{\text{gain}} = \frac{1}{RC} = \frac{1}{1.0} = 1.0\text{ s}^{-1}$ to produce $\frac{dv_C}{dt}$.
4. **Integrator Block:** An `Integrator` block ($\frac{1}{s}$) with initial condition $v_C(0) = 0\text{ V}$ integrating $\frac{dv_C}{dt}$ to yield $v_C(t)$.
5. **Feedback Loop:** Connect the output $v_C(t)$ back to the negative input terminal of the `Sum` block.
6. **Sink Blocks:** Connect $v_C(t)$ to a `Scope` for visualization and a `To Workspace` block for numerical analysis in MATLAB.

```
          v_in(t)   +┌─────┐  dv_C/dt  ┌───────────┐  v_C(t)
 Step ──────────────►│ Sum │──────────►│Integrator ├─────────┬──► Scope
                     └▲───┬┘           │   (1/s)   │         │
                     -│   │            └───────────┘         └──► To Workspace
                      └───┴──────────────────────────────────┘
                              Negative Feedback Loop
```

#### 4. Analytical Verification
For $t \ge 0.1\text{ s}$, the analytical voltage response is:
$$v_C(t) = 5.0 \cdot \left(1 - e^{-(t - 0.1) / 1.0}\right)$$

- At $t = 0.1 + 1\tau = 1.1\text{ s}$:
  $$v_C(1.1) = 5.0 \cdot (1 - e^{-1}) = 5.0 \times 0.63212 = 3.1606\text{ V}$$
- At $t = 0.1 + 4\tau = 4.1\text{ s}$:
  $$v_C(4.1) = 5.0 \cdot (1 - e^{-4}) = 5.0 \times 0.98168 = 4.9084\text{ V}$$

---

## 6. MATLAB Implementation

Every Simulink dynamic block diagram can be directly mirrored in a standalone MATLAB script using `ode45`. This companion script simulates the exact low-pass RC filter, solves the ODE, evaluates the transient response metrics, and compares the numerical output against the analytical solution.

```matlab
% rc_filter_standalone_verification.m
% Standalone numerical simulation of RC filter step response using ode45.
% Mirrors the Simulink block diagram: Step -> Sum -> Gain -> Integrator.

clear; close all; clc;

% 1. Physical Circuit Parameters
R = 10e3;              % Resistance [Ohms] (10 kOhm)
C = 100e-6;            % Capacitance [Farads] (100 uF)
tau = R * C;           % Time constant [seconds] (tau = 1.0 s)
V_step = 5.0;          % Input step voltage [Volts]
t_step = 0.1;          % Step onset time [seconds]
t_final = 6.0;         % Simulation end time [seconds]

% 2. System ODE Formulation: dvC/dt = (v_in(t) - vC) / (R * C)
rc_ode = @(t, vc) ((t >= t_step) * V_step - vc) / (R * C);

% 3. Numerical Integration via ode45 (Dormand-Prince variable-step)
opts = odeset('RelTol', 1e-6, 'AbsTol', 1e-8);
[t, v_numerical] = ode45(rc_ode, [0, t_final], 0.0, opts);

% 4. Exact Analytical Solution for Validation
v_analytical = zeros(size(t));
v_analytical(t >= t_step) = V_step * (1.0 - exp(-(t(t >= t_step) - t_step) / tau));

% 5. Metric Extraction: Rise Time and Settling Time
idx_10 = find(v_numerical >= 0.10 * V_step, 1, 'first');
idx_90 = find(v_numerical >= 0.90 * V_step, 1, 'first');
t_rise = t(idx_90) - t(idx_10);

idx_settle = find(abs(v_numerical - V_step) <= 0.02 * V_step, 1, 'first');
t_settle = t(idx_settle) - t_step;

max_error = max(abs(v_numerical - v_analytical));

% 6. Engineering Output Report
fprintf('====================================================\n');
fprintf('  RC LOW-PASS FILTER TRANSIENT SIMULATION RESULTS   \n');
fprintf('====================================================\n');
fprintf('Circuit Time Constant (tau)     : %.4f s\n', tau);
fprintf('10%% to 90%% Rise Time (t_r)      : %.4f s (Expected: %.4f s)\n', ...
    t_rise, tau * log(9));
fprintf('2%% Settling Time (t_s)          : %.4f s (Expected: %.4f s)\n', ...
    t_settle, -tau * log(0.02));
fprintf('Voltage at t = t_step + tau     : %.4f V (Expected: %.4f V)\n', ...
    interp1(t, v_numerical, t_step + tau), V_step * (1 - exp(-1)));
fprintf('Maximum Absolute Solver Error   : %.2e V\n', max_error);
fprintf('====================================================\n');
```

---

## 7. Common Student Pitfalls & Debugging Tips

### Pitfall 1: The Dreaded Algebraic Loop
- **Symptom:** Simulink halts with: `Cannot solve algebraic loop containing '...' because it contains a cycle with only direct feedthrough blocks.` Or simulation runs agonizingly slowly with warning messages.
- **Root Cause:** An algebraic loop occurs when the input of a block depends directly on its own output at the current time step without passing through a dynamic state (an Integrator $\frac{1}{s}$ or Unit Delay $z^{-1}$). For example, feeding a `Gain` block output directly into a `Sum` block that feeds the same `Gain` ($y = 2(u - y)$).
- **Fix:** 
  1. Solve the algebraic equation analytically before modeling: $y + 2y = 2u \implies 3y = 2u \implies y = \frac{2}{3}u$.
  2. If modeling physical feedback, ensure an **Integrator block** exists in the loop (physical inertia or capacitance prevents instantaneous feedback).
  3. In discrete systems, insert a `Unit Delay` block ($z^{-1}$) to break direct feedthrough.

### Pitfall 2: Selecting the Wrong Solver (Fixed vs Variable Step)
- **Symptom:** Simulation is either inaccurate with spurious oscillations, or runs 1,000 times slower than real time.
- **Root Cause:** 
  - Using `ode45` on a **stiff system** (e.g., power electronics with fast PWM switching combined with slow thermal dynamics) forces the variable-step solver to shrink its step size to $10^{-12}\text{ s}$, hanging the computer.
  - Using a fixed-step solver (`ode1` Euler) with too large a time step ($\Delta t > 2/\lambda_{\max}$) causes catastrophic numerical instability.
- **Fix:**
  - For general non-stiff continuous systems: use `ode45` (Dormand-Prince).
  - For stiff systems (circuits, thermal kinetics, switching converters): use `ode15s` (Gear/NDF) or `ode23tb`.
  - For embedded target deployment: use `ode4` (Runge-Kutta 4th order) with step size $\Delta t \le \tau_{\min} / 10$.

### Pitfall 3: Sample Time Mismatches in Hybrid Models
- **Symptom:** Simulink throws: `Continuous state cannot depend on discrete sample time.`
- **Root Cause:** Connecting a continuous plant (Integrator with $T_s = 0$) directly to a discrete digital microcontroller block ($T_s = 0.01\text{ s}$) without proper signal conditioning.
- **Fix:** Place a **Zero-Order Hold (ZOH)** block between continuous and discrete blocks to properly model the digital-to-analog converter (DAC), and rate transitions where necessary.

### Pitfall 4: Integrator Windup in Closed-Loop Controllers
- **Symptom:** A physical motor or actuator overshoots violently and takes seconds to recover after a transient step command.
- **Root Cause:** Physical actuators have saturation limits (e.g., maximum supply voltage $\pm 24\text{ V}$). When the error persists, the integral term continues accumulating (winding up) to hundreds of volts. Even when the error reverses sign, the integrator takes a long time to unwind.
- **Fix:** Enable **Limit output** directly in the Integrator block parameters, or implement a **PI Controller with anti-windup clamping** (see `simulink/mini_project_motor_control.m`).

### Pitfall 5: Default Solver Tolerances Masking High-Frequency Dynamics
- **Symptom:** High-frequency resonant ringing in an RLC circuit or mechanical beam is completely smoothed out, looking falsely stable.
- **Root Cause:** The default `RelTol = 1e-3` allows the adaptive step-size algorithm to take steps that span across several oscillation periods.
- **Fix:** Tighten `RelTol` to `1e-6` or set `MaxStep = T_period / 20` in Model Configuration Parameters (`Ctrl+E`).

---

## 8. Engineering Interpretation

Connecting dynamic time-series outputs to physical engineering specifications:

| Transient Metric | Mathematical Definition | Physical System Impact | Practical Engineering Decision |
| :--- | :--- | :--- | :--- |
| **Rise Time ($t_r$)** | Time to rise from $10\%$ to $90\%$ of setpoint | Responsiveness and bandwidth | Size motor torque and battery peak current; avoid sluggish response in emergency braking. |
| **Peak Time ($t_p$)** | Time at which maximum peak occurs | Speed of first overshoot | Determines how quickly an actuator reaches maximum mechanical travel. |
| **Percentage Overshoot ($\%OS$)** | $\frac{y_{\max} - y_{ss}}{y_{ss}} \times 100\%$ | Mechanical shock, electrical over-voltage | Enforce $\%OS < 10\%$ to prevent gear tooth shear, hydraulic cavitation, or dielectric breakdown. |
| **Settling Time ($t_s$)** | Time after which $|y(t) - y_{ss}| \le 0.02 y_{ss}$ | System stability and dwell time | Determines maximum throughput in pick-and-place robots or CNC milling operations. |
| **Steady-State Error ($e_{ss}$)** | $\lim_{t \to \infty} (r(t) - y(t))$ | Accuracy and calibration | Add integral action ($K_i$) in controller to eliminate steady-state error caused by friction or gravity. |
| **Actuator Saturation** | $\max(|u(t)|) \ge U_{\max}$ | Thermal runaway, motor burnout | Select larger actuator or implement feedforward/anti-windup control to operate within linear limits. |

---

## 9. Progressive Exercises Overview

The exercises for this module are structured into four progressive pedagogical tiers in [exercises.m](exercises.m):

1. **Level 1: Recall**
   - Signal tracing in basic block diagrams: determine equivalent closed-loop transfer functions, derive time constants $\tau$, and compute expected steady-state values from block parameter configurations.
2. **Level 2: Understanding & Debugging**
   - Diagnosing and resolving an algebraic loop caused by direct feedthrough feedback without state dynamics; identifying forward Euler numerical instability (`ode1`) and calculating the maximum stable step size $\Delta t_{\text{crit}}$.
3. **Level 3: Application**
   - Formulating and simulating a second-order RLC resonant circuit ($L \ddot{q} + R \dot{q} + \frac{1}{C}q = V_{\text{in}}$) via companion state-space ODE integration: compare underdamped, critically damped, and overdamped regimes, and compute resonant damping metrics.
4. **Level 4: Challenge**
   - High-performance closed-loop DC motor speed controller design: implementing a proportional-integral (PI) controller with anti-windup saturation limits, tuning control gains ($K_p, K_i$) to meet stringent rise time ($t_r < 0.5\text{ s}$), low overshoot ($\%OS < 10\%$), and zero steady-state error under full load torque disturbance.

Complete, production-grade reference solutions with zero remaining `% TODO` markers are provided in [../solutions/simulink_exercises_solution.m](../solutions/simulink_exercises_solution.m).

### Related Module Resources
- [01_block_diagram_basics.md](01_block_diagram_basics.md) — Comprehensive guide to blocks, signals, sources, sinks, feedback, and sample times.
- [02_solvers_and_simulation.md](02_solvers_and_simulation.md) — Deep dive into ODE solvers, variable vs fixed step sizes, and stiff system handling.
- [models/rc_circuit_model.md](models/rc_circuit_model.md) — Block-diagram blueprint and parameter specification for the 1st-order RC circuit.
- [models/thermal_cooling_model.md](models/thermal_cooling_model.md) — Block-diagram blueprint for Newton thermal dissipation with ambient feedback.
- [models/dc_motor_model.md](models/dc_motor_model.md) — Block-diagram blueprint for the electromechanical DC motor.
- [03_rc_circuit_companion.m](03_rc_circuit_companion.m) — Executable standalone MATLAB script for RC circuit simulation.
- [04_thermal_cooling_companion.m](04_thermal_cooling_companion.m) — Executable standalone MATLAB script for thermal cooling simulation.
- [05_dc_motor_companion.m](05_dc_motor_companion.m) — Executable standalone MATLAB script for coupled DC motor simulation.
- [mini_project_motor_control.m](mini_project_motor_control.m) — Closed-loop PI speed control mini-project with disturbance rejection.
- [exercises.m](exercises.m) — 4-tier progressive exercises template.
- [../solutions/simulink_exercises_solution.m](../solutions/simulink_exercises_solution.m) — Decoupled reference solutions.
- `reference/simulink_cheat_sheet.md` — Central quick reference cheat sheet (M6).
