# Calculus for Engineers: Change, Accumulation & Optimization

Welcome to the **Calculus for Engineers** module of the Engineering Mathematics curriculum. In Level 1, you learned how to manipulate tabular data and static arrays using Python, NumPy, and Pandas. In engineering practice, however, physical reality is rarely static. Fluids flow, mechanical linkages accelerate, electrical charges migrate across junctions, and chemical reactions exchange heat continuously over time.

Calculus provides the universal mathematical language required to describe, simulate, and optimize these dynamic systems. In MATLAB, we transition from symbolic continuous formulas to robust numerical approximations: derivatives become finite differences and gradients, integrals become numerical accumulation and quadrature, and differential equations are integrated using state-of-the-art adaptive solvers such as `ode45`.

---

## 1. Learning Objectives

By completing this module, you will be able to:

1. **Calculate** rates of change and acceleration from discrete sensor telemetry using finite differences (`diff`, `gradient`).
2. **Analyze** truncation error and understand the numerical trade-offs between forward, backward, and central difference approximations.
3. **Evaluate** total energy, charge, and displacement accumulation from dynamic telemetry streams using numerical quadrature (`trapz`, `cumtrapz`, `integral`).
4. **Identify** critical operating points and formulate gradient-based optimization schemes for engineering loss functions.
5. **Formulate** and **solve** first-order ordinary differential equations (ODEs) modeling thermal dissipation and RC electrical circuits using `ode45`.
6. **Diagnose** and **debug** common computational pitfalls in MATLAB, such as array-length truncation in `diff` and step-size discretization errors.
7. **Design** an engineering system (such as an optimal heat sink cooling profile) balancing physical constraints, settling time, and energy dissipation.

---

## 2. Why Engineers Need This

In professional engineering, physical systems are defined by dynamic equations:

- **Mechanical & Aerospace Engineers** analyze vehicle telemetry, flight paths, and structural vibrations. Accelerometers measure second derivatives of position; integrating velocity profiles determines stopping distances and fuel consumption.
- **Electrical & Computer Engineers** model transient responses in circuits. Current is the rate of change of charge ($I = dq/dt$), capacitor voltage depends on charge accumulation ($V = \frac{1}{C}\int I dt$), and inductors resist changes in current ($V = L di/dt$).
- **Thermal & Chemical Engineers** manage heat dissipation in high-performance processors and battery packs. Newton's Law of Cooling is a differential equation dictating how rapidly thermal energy leaves a silicon die.
- **Machine Learning & Control Engineers** rely on calculus as the optimization backbone. Gradient descent adjusts algorithmic weights by calculating the derivative (slope) of an objective loss surface.

Bridging Level 1 (discrete data manipulation) to Level 3 (machine learning and predictive control) requires mastering how continuous physical processes are digitized, integrated, and optimized computationally.

---

## 3. Mathematical Intuition

Calculus boils down to two complementary operations: **differentiation** (breaking a process down into instantaneous rates of change) and **integration** (accumulating instantaneous rates back into a net total).

### The Speedometer and the Odometer
Imagine driving a car along a highway:
- **Derivatives as Instantaneous Rate:** Look down at your speedometer. At any single split-second, your speedometer reads $90\text{ km/h}$. You have not traveled $90\text{ km}$ in that second; rather, the speedometer reports the *instantaneous slope* of your distance-versus-time curve.
- **Integrals as Accumulation:** Now look at your trip odometer. Even if your velocity fluctuates through traffic, construction zones, and red lights, your total displacement is the continuous *summation* of all infinitesimal distance slices ($v(t) \cdot dt$).
- **The Fundamental Theorem:** Differentiation and integration are inverse operations. If you differentiate your odometer reading over time, you recover your speedometer reading. If you integrate your speedometer curve over time, you recover the distance shown on your odometer.

```
       Differentiation (Rate of Change: d/dt)
Position s(t) ──────────────────────────────────> Velocity v(t) ──> Acceleration a(t)
     ▲                                                 │
     └─────────────────────────────────────────────────┘
         Integration (Accumulation: ∫ dt)
```

### Optimization: The Rolling Marble
Finding optimal designs (minimum cost, maximum efficiency, minimum error) is equivalent to placing a marble on a continuous surface:
- Where the terrain slopes downward ($f'(x) < 0$), the marble accelerates to the right.
- Where the terrain slopes upward ($f'(x) > 0$), the marble decelerates or rolls left.
- When the marble settles at the bottom of a valley, the slope is perfectly flat: $f'(x) = 0$.
- By checking curvature ($f''(x) > 0$), we verify whether we have found a valley bottom (minimum loss) or a precarious peak ($f''(x) < 0$).

---

## 4. Formal Mathematics & Governing Equations

### 4.1 Kinematics & Higher-Order Rates
For a scalar position trajectory $s(t)$:
$$\text{Velocity: } v(t) = \frac{ds}{dt} = \dot{s}(t)$$
$$\text{Acceleration: } a(t) = \frac{d^2s}{dt^2} = \frac{dv}{dt} = \ddot{s}(t)$$
$$\text{Jerk: } j(t) = \frac{da}{dt} = \frac{d^3s}{dt^3}$$

### 4.2 Numerical Differentiation via Taylor Series
In computational engineering, sensor telemetry arrives at discrete time steps $t_1, t_2, \dots, t_N$ separated by sample interval $h = \Delta t$. Expanding $f(t)$ via Taylor series:
$$f(t + h) = f(t) + h f'(t) + \frac{h^2}{2} f''(t) + \mathcal{O}(h^3)$$
$$f(t - h) = f(t) - h f'(t) + \frac{h^2}{2} f''(t) - \mathcal{O}(h^3)$$

Rearranging yields three standard finite difference approximations:
1. **Forward Difference:**
   $$f'(t) \approx \frac{f(t + h) - f(t)}{h}, \quad \text{Truncation Error: } \mathcal{O}(h)$$
2. **Backward Difference:**
   $$f'(t) \approx \frac{f(t) - f(t - h)}{h}, \quad \text{Truncation Error: } \mathcal{O}(h)$$
3. **Central Difference:**
   $$f'(t) \approx \frac{f(t + h) - f(t - h)}{2h}, \quad \text{Truncation Error: } \mathcal{O}(h^2)$$

*Pedagogical Insight:* Central differences cancel out the first-order error terms, yielding second-order accuracy ($\mathcal{O}(h^2)$) for internal points at no additional computational cost.

### 4.3 Accumulation & Numerical Quadrature
For an instantaneous rate $r(t)$ from $t = a$ to $t = b$, the accumulated quantity $Q$ is:
$$Q = \int_a^b r(t) \, dt = \lim_{N \to \infty} \sum_{i=1}^N r(t_i) \Delta t$$

- **Trapezoidal Rule:** Linear interpolation between adjacent discrete samples:
  $$\int_a^b f(t) \, dt \approx \sum_{i=1}^{N-1} \frac{f(t_i) + f(t_{i+1})}{2} (t_{i+1} - t_i)$$
  In MATLAB, `trapz(t, y)` executes this summation directly across arbitrary (even non-uniform) grids.
- **Continuous Quadrature:** For analytic functions $f(t)$, MATLAB's `integral(fun, a, b)` applies adaptive Gauss-Kronrod quadrature, adjusting internal node density until absolute/relative tolerance thresholds are met.

### 4.4 First-Order Ordinary Differential Equations (ODEs)
Many fundamental engineering phenomena follow first-order relaxation kinetics:
$$\frac{dy}{dt} = f(t, y)$$

- **Newton's Law of Cooling:**
  $$\frac{dT}{dt} = -k \big(T(t) - T_{\text{env}}\big), \quad \text{Analytical Solution: } T(t) = T_{\text{env}} + (T_0 - T_{\text{env}}) e^{-kt}$$
  where $k = \frac{h A}{C_{\text{th}}}$ is the cooling rate constant ($\text{s}^{-1}$), and $\tau = 1/k$ is the thermal time constant.
- **RC Circuit Transient Charging:**
  $$R C \frac{dv_C}{dt} + v_C(t) = V_{\text{in}}(t) \implies \frac{dv_C}{dt} = \frac{V_{\text{in}} - v_C}{RC}$$
  where $\tau = RC$ is the electrical time constant.

MATLAB's workhorse solver for non-stiff initial value problems is `ode45`, implementing the explicit Dormand-Prince $(4,5)$ Runge-Kutta pair with adaptive step-size control.

---

## 5. Worked Engineering Example: Braking Vehicle Dynamics

### Problem Statement
An electric test vehicle of mass $m = 1800\text{ kg}$ traveling at $v_0 = 30\text{ m/s}$ ($108\text{ km/h}$) initiates emergency braking at $t = 0$. The onboard brake controller applies a time-decaying velocity profile until coming to a complete stop at $t_b = 4.0\text{ s}$:
$$v(t) = v_0 \left(1 - \frac{t}{t_b}\right)^2, \quad 0 \le t \le t_b$$

Determine:
1. The instantaneous deceleration profile $a(t)$ and peak braking deceleration.
2. The total stopping distance $d_{\text{stop}}$.
3. The total kinetic energy dissipated by the friction brakes.

---

### Step-by-Step Hand Calculation

#### 1. Instantaneous Acceleration
Differentiating velocity with respect to time using the chain rule:
$$a(t) = \frac{dv}{dt} = \frac{d}{dt}\left[v_0 \left(1 - \frac{t}{t_b}\right)^2\right] = 2 v_0 \left(1 - \frac{t}{t_b}\right) \left(-\frac{1}{t_b}\right) = -\frac{2 v_0}{t_b} \left(1 - \frac{t}{t_b}\right)$$

Evaluating at key time points:
- At $t = 0$: $a(0) = -\frac{2(30)}{4.0} (1 - 0) = -15.0\text{ m/s}^2$ (peak deceleration: $\approx 1.53\text{ g}$).
- At $t = 4\text{ s}$: $a(t_b) = -\frac{60}{4.0} (1 - 1) = 0\text{ m/s}^2$ (smooth stop, zero jerk at rest).

#### 2. Total Stopping Distance
Accumulating velocity over the braking interval $[0, t_b]$:
$$d_{\text{stop}} = \int_0^{t_b} v(t) \, dt = \int_0^{t_b} v_0 \left(1 - \frac{t}{t_b}\right)^2 dt$$

Let substitution $u = 1 - \frac{t}{t_b}$, with $du = -\frac{1}{t_b} dt \implies dt = -t_b du$:
- When $t = 0 \implies u = 1$
- When $t = t_b \implies u = 0$

$$d_{\text{stop}} = \int_1^0 v_0 u^2 (-t_b du) = v_0 t_b \int_0^1 u^2 du = v_0 t_b \left[ \frac{u^3}{3} \right]_0^1 = \frac{v_0 t_b}{3}$$

Substituting numerical values:
$$d_{\text{stop}} = \frac{30 \times 4.0}{3} = 40.0\text{ meters}$$

#### 3. Energy Dissipated
Total kinetic energy dissipated during the braking event:
$$\Delta E_k = \frac{1}{2} m v_0^2 - \frac{1}{2} m v(t_b)^2 = \frac{1}{2} (1800)(30)^2 - 0 = 810{,}000\text{ Joules} = 810\text{ kJ}$$

Now we verify this in MATLAB using discrete numerical methods.

---

## 6. MATLAB Implementation

```matlab
% vehicle_braking_verification.m
% Verification of analytical braking model using numerical calculus

clear; clc;

% 1. Physical Parameters
m = 1800;         % Vehicle mass [kg]
v0 = 30;          % Initial velocity [m/s]
tb = 4.0;         % Total braking duration [s]
dt = 0.01;        % Telemetry sample time [s]
t = 0:dt:tb;      % Discrete time vector [s]

% 2. Discrete Velocity Profile
v = v0 * (1 - t / tb).^2;

% 3. Numerical Differentiation: Acceleration
% Note: gradient() preserves array length and applies 2nd-order central differences
a_numerical = gradient(v, dt);
a_analytical = - (2 * v0 / tb) * (1 - t / tb);

% 4. Numerical Integration: Distance Traveled
d_trapz = trapz(t, v);                     % Total stopping distance
d_cum = cumtrapz(t, v);                    % Continuous trajectory s(t)
d_analytical = (v0 * tb) / 3;

% 5. Instantaneous Power & Energy Dissipation
% Mechanical braking force F = m * a
F_brake = m * abs(a_numerical);            % Braking force [N]
P_brake = F_brake .* v;                    % Instantaneous brake power [W]
E_dissipated = trapz(t, P_brake);          % Total energy [J]

% 6. Display Comparison Metrics
fprintf('--- VEHICLE BRAKING SIMULATION RESULTS ---\n');
fprintf('Analytical Stopping Distance : %.4f m\n', d_analytical);
fprintf('Numerical Stopping Distance  : %.4f m (Error: %.2e m)\n', ...
    d_trapz, abs(d_trapz - d_analytical));
fprintf('Peak Deceleration            : %.2f m/s^2 (%.2f g)\n', ...
    max(abs(a_numerical)), max(abs(a_numerical))/9.81);
fprintf('Total Energy Dissipated      : %.2f kJ (Expected: 810.00 kJ)\n', ...
    E_dissipated / 1000);
```

---

## 7. Common Student Pitfalls & Debugging Tips

### Pitfall 1: Array Truncation with `diff`
- **Symptom:** MATLAB throws `Error using plot: Vectors must be the same length` when executing `plot(t, diff(y))`.
- **Root Cause:** If $y$ has $N$ elements, `diff(y)` computes differences between adjacent pairs, resulting in $N - 1$ elements.
- **Fix:** Either evaluate time midpoints `t_mid = (t(1:end-1) + t(2:end)) / 2`, or use `gradient(y, dt)` which uses central differences for interior points and forward/backward differences at the boundaries, returning an exact $N$-element vector.

### Pitfall 2: Forgetting to Divide by $\Delta t$
- **Symptom:** Calculated velocity or acceleration is two to three orders of magnitude too small.
- **Root Cause:** `diff(y)` returns $\Delta y$, NOT $\frac{dy}{dt}$.
- **Fix:** Always divide by the time step: `dydt = diff(y) ./ diff(t)` or `dydt = gradient(y, dt)`.

### Pitfall 3: Assuming Unit Spacing in `trapz`
- **Symptom:** Integrated value is wildly off (e.g. 100x too large when $\Delta t = 0.01$).
- **Root Cause:** Calling `trapz(y)` assumes unit spacing ($\Delta t = 1.0$).
- **Fix:** Always pass the coordinate grid as the first argument: `area = trapz(t, y)`.

### Pitfall 4: Noise Amplification in Numerical Differentiation
- **Symptom:** Taking `diff` of experimental sensor data yields an unreadable, violently oscillating signal.
- **Root Cause:** If signal has noise amplitude $\epsilon$, $\frac{d}{dt}(y + \epsilon \sin(\omega t)) = y' + \epsilon \omega \cos(\omega t)$. High-frequency noise is multiplied by frequency $\omega$.
- **Fix:** Low-pass filter or smooth data before differentiation (e.g., `smoothdata(y, 'movmean', 5)`), or fit a spline before taking derivatives.

### Pitfall 5: Misunderstanding `ode45` Time Spanning
- **Symptom:** Solver returns very coarse results or unexpected row/column orientations.
- **Root Cause:** Passing `tspan = [t0, tf]` allows `ode45` to choose its own adaptive time steps. Passing a multi-element vector `tspan = t0:dt:tf` forces output at those exact timestamps (though internal steps remain adaptive).
- **Fix:** Ensure the ODE derivative function returns a **column vector** ($N \times 1$), e.g., `dydt = [dydt; ...];`.

---

## 8. Engineering Interpretation

Connecting numerical outputs to physical engineering decisions:

| Calculus Concept | Computational Tool | Physical Engineering System | Practical Engineering Decision |
| :--- | :--- | :--- | :--- |
| **First Derivative** | `diff(y) ./ dt`, `gradient` | Velocity, thermal change rate, strain rate | Limit mechanical jerk, prevent thermal shock in ceramic substrates. |
| **Critical Point ($f'=0$)** | `roots`, `fminbnd`, optimization | Peak stress, minimum aerodynamic drag, optimal gear ratio | Select operating point minimizing energy loss or maximizing structural strength. |
| **Second Derivative ($f''>0$)** | `gradient(gradient(y))` | System stability, curvature, spring stiffness | Confirm whether a critical point is a true stable minimum vs. unstable saddle point. |
| **Definite Integral** | `trapz(t, y)` | Energy accumulated ($E = \int P dt$), total fluid discharge | Dimension battery capacity (kWh), size hydraulic expansion tanks. |
| **Time Constant ($\tau$)** | `ode45`, relaxation decay | Thermal cooling settling time, RC circuit filter bandwidth | Determine minimum dwell time before thermal equilibrium is reached ($4\tau = 98\%$). |

---

## 9. Progressive Exercises Overview

The exercises for this module are structured into four progressive pedagogical tiers in [exercises.m](exercises.m):

1. **Level 1: Recall**
   - Direct reproduction of core calculus operations: numerical differentiation of position trajectories using `diff`, and numerical accumulation of electric charge and mechanical work using `trapz`.
2. **Level 2: Understanding & Debugging**
   - Identifying and resolving dimensionality errors caused by `diff(y)`, correcting missing $\Delta t$ scaling factors, and adjusting `trapz` for non-uniform sampling grids.
3. **Level 3: Application**
   - Modeling complete braking dynamics for an electric transit vehicle: computing stopping distance, deceleration profiles, identifying peak deceleration, and evaluating energy dissipated under varying initial conditions.
4. **Level 4: Challenge**
   - High-performance heat sink design: formulating a coupled ODE for an electronic transistor subjected to cyclic thermal power pulses, integrating with `ode45`, and determining the minimal convective heat transfer coefficient $h A$ needed to keep junction temperature below $85^\circ\text{C}$.

Complete, production-grade reference solutions with zero remaining `% TODO` markers are provided in [../solutions/calculus_exercises_solution.m](../solutions/calculus_exercises_solution.m).

For quick syntax reminders during problem solving, refer to the central reference sheet `reference/calculus_cheat_sheet.md`.
