# Solvers and Simulation: The Numerical Integration Engine

## Overview

A Simulink model is a graphical representation of a coupled set of differential and algebraic equations:
$$\dot{\mathbf{x}}(t) = \mathbf{f}\big(t, \mathbf{x}(t), \mathbf{u}(t)\big)$$
$$\mathbf{y}(t) = \mathbf{g}\big(t, \mathbf{x}(t), \mathbf{u}(t)\big)$$

Simulink does not solve these equations symbolically; it executes a **numerical integration solver** that advances time in discrete increments from $t = 0$ to $t = t_{\text{final}}$. The fidelity, numerical stability, and execution speed of your simulation depend directly on your choice of solver and its configuration parameters.

---

## 1. The Numerical Integration Challenge

Numerical solvers approximate the continuous integral of the state derivative:
$$\mathbf{x}(t_{k+1}) = \mathbf{x}(t_k) + \int_{t_k}^{t_{k+1}} \mathbf{f}(t, \mathbf{x}, \mathbf{u}) \, dt$$

The fundamental engineering trade-off is:
1. **Accuracy:** Smaller time steps ($\Delta t = t_{k+1} - t_k$) reduce truncation error.
2. **Computational Cost:** Smaller time steps require more function evaluations, dramatically slowing simulation throughput.

Simulink provides two fundamentally different classes of solvers to manage this trade-off: **Variable-Step Solvers** and **Fixed-Step Solvers**.

---

## 2. Variable-Step Solvers (Desktop Analysis & Design)

Variable-step solvers dynamically adjust the time step $\Delta t_k$ at every single point in time:
- During **rapid transients** (switch closures, impact forces, step inputs), the solver automatically shrinks $\Delta t$ down to picoseconds to capture steep slopes without losing accuracy.
- During **quiescent, steady-state periods**, the solver increases $\Delta t$ to hundreds of milliseconds, accelerating simulation execution.

```
State x(t)
   ▲          Rapid Transient                  Smooth Steady-State
   │         (Step size shrinks)              (Step size expands)
   │               │││││││                      │       │       │
   │            * * * * *                       *       *       *
   │          *           *
   │        *               *───────────────────────────────────────
   │      *
   │    *
   └────┴──┴─┴─┴─┴─┴─┴─┴─┴─┴─┴───┴───────┴───────┴───────┴───────┴──► Time (t)
        Coarse    Dense Steps                 Wide Step Intervals
```

### 2.1 The Workhorse: `ode45` (Dormand-Prince 4, 5)
- **Algorithm:** Explicit Runge-Kutta pair of orders 4 and 5. At each time step, it computes two estimates of the state: a 4th-order estimate $x^{(4)}$ and a 5th-order estimate $x^{(5)}$.
- **Local Error Estimation:**
  $$e_k = \big| x_k^{(5)} - x_k^{(4)} \big|$$
- **Step-Size Adaptation:**
  The estimated local truncation error $e_k$ is compared against an acceptable tolerance threshold:
  $$\text{Tol}_k = \text{RelTol} \cdot |x_k| + \text{AbsTol}$$
  - If $e_k \le \text{Tol}_k$: The step is accepted, and the next step size is expanded:
    $$\Delta t_{\text{next}} = 0.9 \cdot \Delta t_k \left(\frac{\text{Tol}_k}{e_k}\right)^{0.2}$$
  - If $e_k > \text{Tol}_k$: The step is rejected, the state is rewound, and the calculation is repeated with a smaller $\Delta t$.
- **Best For:** Most continuous physical systems (suspensions, simple motors, non-stiff circuits). It is the default solver in Simulink.

### 2.2 `ode23` (Bogacki-Shampine 2, 3)
- **Algorithm:** Explicit Runge-Kutta pair of orders 2 and 3.
- **Best For:** Systems with moderate stiffness or systems where crude error tolerance is acceptable and high-frequency noise would cause `ode45` to take excessively tiny steps.

---

## 3. Stiff Systems & Implicit Solvers

### 3.1 What is System Stiffness?
A differential equation is mathematically **stiff** if it contains widely disparate time constants:
$$\tau_{\text{fast}} \ll \tau_{\text{slow}}$$
$$\frac{\lambda_{\max}}{\lambda_{\min}} \gg 10^3$$

#### Real-World Example: Electric Powertrain Inverter
- **Fast Dynamic:** Inverter MOSFET gate capacitance charging ($\tau_{\text{fast}} \approx 10^{-8}\text{ s} = 10\text{ ns}$).
- **Slow Dynamic:** Electric vehicle motor stator heating ($\tau_{\text{slow}} \approx 100\text{ s}$).

If you attempt to simulate this system using an explicit solver like `ode45`, the stability limit forces $\Delta t < 2 \tau_{\text{fast}} = 20\text{ ns}$, even when the electrical transient has died out and only the slow thermal dynamic is changing! Simulating $60\text{ seconds}$ of driving would require over $3 \times 10^9$ steps, freezing MATLAB.

### 3.2 Implicit Stiff Solvers: `ode15s` and `ode23tb`
Implicit solvers evaluate derivatives at the *future* state $t_{k+1}$, solving an algebraic system at each step via Newton-Raphson iteration:
$$\mathbf{x}_{k+1} = \mathbf{x}_k + \Delta t \cdot \mathbf{f}(t_{k+1}, \mathbf{x}_{k+1})$$

Because their stability regions encompass the entire left half of the complex plane ($A$-stable or $L$-stable), implicit solvers can take large time steps matching the *slow* dynamics without becoming numerically unstable.

- **`ode15s`:** Numerical Differentiation Formulas (NDF / BDF) of variable order (1 to 5). Workhorse for highly stiff physical chemical kinetics, complex hydraulic valves, and coupled thermal-electrical systems.
- **`ode23tb`:** Trapezoidal Rule with Backward Differentiation Formula (TR-BDF2). Excellent for circuits with non-linear saturation, power electronics, and switching diodes.

---

## 4. Fixed-Step Solvers (Real-Time & Embedded Target Deployment)

Fixed-step solvers advance time by a strictly uniform increment $\Delta t = h$. They **cannot** adapt their step size.

### 4.1 Why Use Fixed-Step Solvers?
Variable-step solvers cannot be compiled onto real-time microcontrollers (ECUs, DSPs, FPGAs) because their execution time per step is non-deterministic (a rejected step could cause a deadline overrun, crashing a car or drone).

Fixed-step solvers are mandatory for:
1. **Automatic C/C++ Code Generation** via Simulink Coder / Embedded Coder.
2. **Hardware-in-the-Loop (HIL)** real-time testing rigs.
3. **Discrete digital controllers** running on physical microprocessors at periodic clock rates.

### 4.2 Fixed-Step Algorithms

| Solver | Name | Order | Evaluation Cost | Stability Limit ($\Delta t$) |
| :--- | :--- | :--- | :--- | :--- |
| **`ode1`** | Forward Euler | 1 | 1 evaluation / step | $\Delta t \le \frac{2}{\|\lambda_{\max}\|}$ |
| **`ode2`** | Heun's Method | 2 | 2 evaluations / step | Improved over Euler |
| **`ode3`** | Bogacki-Shampine | 3 | 3 evaluations / step | Moderate stability |
| **`ode4`** | Runge-Kutta 4th Order | 4 | 4 evaluations / step | Industry standard for real-time HIL |

### 4.3 Forward Euler Instability (`ode1`)
Consider the linear decay equation:
$$\dot{x} = -\lambda x \quad (\lambda > 0)$$
Using `ode1`:
$$x_{k+1} = x_k + \Delta t (-\lambda x_k) = (1 - \lambda \Delta t) x_k$$

For stability, the amplification factor must satisfy $|1 - \lambda \Delta t| < 1$:
$$-1 < 1 - \lambda \Delta t < 1 \implies 0 < \Delta t < \frac{2}{\lambda}$$

If an engineer chooses $\Delta t > \frac{2}{\lambda}$, the numerical solution diverges to $\pm \infty$, even though the physical system is completely stable!

```
x(t)
 ▲              Stable Simulation (dt < 2/lambda)
 │              *
 │                *
 │                  *
 │                     * ─── * ─── * ─── * ─── Steady State
 └────────────────────────────────────────────────────────► Time (t)

x(t)
 ▲              Unstable Simulation (dt > 2/lambda)
 │                    *
 │                                          *
 │                                 *
 │             *
 └─────────────┴──────┴──────┴─────┴────────┴─────────────► Time (t)
                      *
                                   *
```

---

## 5. Solver Tolerances & Configuration Parameters

In Simulink, press `Ctrl+E` to open **Model Configuration Parameters**:

### 5.1 Relative Tolerance (`RelTol`)
- **Default:** `1e-3` ($0.1\%$).
- **Meaning:** Maximum relative error allowed relative to the state magnitude.
- **Rule of Thumb:** For high-precision control or resonant systems (Bode plots, eigenvalue identification), tighten to `1e-6`.

### 5.2 Absolute Tolerance (`AbsTol`)
- **Default:** `auto` (typically initialized to `1e-6`).
- **Meaning:** Lower error floor active when states approach zero (where relative error is mathematically ill-conditioned).
- **Rule of Thumb:** Set `AbsTol` to $10^{-4} \times$ the minimum physical state value you care about (e.g., if measuring motor currents of $1\text{ mA} = 10^{-3}\text{ A}$, set `AbsTol = 1e-7`).

### 5.3 Maximum Step Size (`MaxStep`)
- **Default:** `auto` (computed as $\frac{t_{\text{final}} - t_0}{50}$).
- **The Danger of `auto`:** If an input pulse or resonant frequency happens between sample points, a variable-step solver might step right over the peak!
- **Engineering Fix:** Explicitly cap `MaxStep`:
  $$\text{MaxStep} \le \frac{T_{\text{period}}}{20} = \frac{1}{20 \cdot f_{\max}}$$

---

## 6. Zero-Crossing Detection & Discontinuities

Physical models often contain non-smooth discontinuities:
- Coulomb friction sign changes: $\text{sign}(\omega)$
- Mechanical hard stops and limits: Saturation blocks
- Diode switching: Ideal switch conduction transitions

When a signal crosses a threshold, Simulink invokes **Zero-Crossing Detection**:
1. The solver detects that a sign change occurred during interval $[t_k, t_{k+1}]$.
2. The solver uses a root-finding algorithm (bisection/secant) to locate the exact instant $t^*$ where the zero crossing happened.
3. The solver resets the state derivatives at $t^*$ and resumes integration.

*Warning: Solver Chattering!* If a signal chatters infinitely across a threshold (e.g., high-frequency PWM or undamped contact chatter), the solver can freeze. In Model Configuration Parameters, set **Zero-crossing control** to `Adaptive` or insert a small hysteresis/dead zone to break the chattering cycle.

---

## 7. Master Solver Selection Flowchart

```
                          Is the model deployed to real-time hardware
                                   (ECU, DSP, FPGA, HIL)?
                                        │
                      ┌─────────────────┴─────────────────┐
                     YES                                 NO
                      │                                   │
              Fixed-Step Solver                  Variable-Step Solver
                      │                                   │
         Is computational time limited?          Does the model have fast switching,
               │                               hydraulic valves, or stiff kinetics?
        ┌──────┴──────┐                                   │
       YES            NO                          ┌───────┴───────┐
        │              │                         YES              NO
      ode1           ode4                         │                │
 (Forward Euler)  (Runge-Kutta 4th)             ode15s           ode45
                                              (NDF/BDF)      (Dormand-Prince)
```

With this theoretical foundation, you can select the correct solver for any physical engineering system.
