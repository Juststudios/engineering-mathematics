# Integrated Capstone: Electric Vehicle Powertrain Telemetry Analysis

Welcome to the **Integrated Capstone Project** of the **Engineering Mathematics + MATLAB** curriculum. This project synthesizes the core mathematical competencies developed across the entire Level 2 curriculum—Linear Algebra, Calculus, Probability, and Numerical MATLAB Computing—into a unified, multi-physics investigation of high-frequency electric vehicle (EV) telemetry.

---

## 1. Learning Objectives
By completing this integrated capstone, students will be able to:
- **Synthesize Multi-Physics Telemetry**: Integrate electromechanical power, electrochemical battery storage, transient thermal cooling, and sensor noise into a unified analytical pipeline.
- **Formulate Calculus Operations on Empirical Data**: Apply numerical trapezoidal quadrature (`trapz`) to integrate electrical power into net consumed energy ($E = \int P \, dt$) and apply finite difference schemes (`diff`) to evaluate thermal rates of change ($dT/dt$).
- **Implement Statistical Noise Filtering**: Model additive white Gaussian sensor noise and design moving-average / Gaussian digital smoothing filters to improve telemetry signal-to-noise ratio (SNR) without phase distortion.
- **Execute Linear Calibration & Optimization**: Formulate linear regression and ordinary least-squares matrix equations ($A\mathbf{x} = \mathbf{b}$) to calibrate torque-speed loss maps and identify equivalent circuit parameters.
- **Construct Professional Engineering Dashboards**: Program multi-panel, publication-quality MATLAB visualizations (`subplot`, dual axes, dynamic annotations) communicating engineering insights to cross-functional powertrain teams.

---

## 2. Why Engineers Need This
In modern automotive engineering (e.g., Tesla, Porsche, Rivian, Lucid), vehicle testing generates gigabytes of raw time-series telemetry per drive cycle. Sensor data does not come pre-analyzed; raw signals contain high-frequency electromagnetic interference (EMI) from inverter switching, quantization noise, sensor drift, and thermal transients.

An engineer cannot evaluate battery range, thermal safety, or motor degradation by inspecting raw CSV rows. You must:
1. Parse and synchronize asynchronous sensor streams into structured matrix arrays.
2. Filter physical measurement noise while preserving rapid transient spikes.
3. Compute derived physical quantities that cannot be measured directly (such as mechanical shaft power, instantaneous efficiency, and cumulative energy expenditure).
4. Differentiate discrete thermal signals to assess inverter cooling performance and prevent semiconductor thermal runaway.
5. Provide actionable engineering recommendations regarding powertrain efficiency maps and regenerative braking calibration.

---

## 3. Mathematical Intuition
Why do we combine linear algebra, calculus, and probability for a single powertrain?

### Energy as Calculus Accumulation ($P \to E$)
Power is an instantaneous rate of doing work ($1\text{ Watt} = 1\text{ Joule/second}$). A vehicle battery does not store *power*; it stores a finite quantity of *energy* (measured in Joules or kiloWatt-hours, $\text{kWh}$). To determine how much battery charge a trip requires, or how much energy regenerative braking recovered, we must sum up the continuous sequence of instantaneous power slices over time:
$$E = \int_{t_{\text{start}}}^{t_{\text{end}}} P_{\text{elec}}(t) \, dt$$
On discrete digital sensors sampled every $\Delta t$ seconds, this continuous integral becomes numerical trapezoidal quadrature (`trapz`), where each time interval contributes an area $\frac{P_k + P_{k+1}}{2} \Delta t$.

### Thermal Vulnerability as Rates of Change ($dT/dt$)
Inverter silicon-carbide (SiC) MOSFETs can withstand high temperatures up to $150^\circ\text{C}$, but rapid thermal shocks ($\frac{dT}{dt} \gg 5^\circ\text{C/s}$) cause thermal expansion mismatches between the silicon die and copper baseplate, leading to wire-bond fatigue and catastrophic semiconductor failure.
By differentiating the temperature telemetry via discrete finite differences ($\frac{\Delta T}{\Delta t} = \frac{T_{k+1} - T_k}{t_{k+1} - t_k}$), engineers identify transient thermal stress long before the steady-state temperature limit is violated.

### Sensor Noise and the Averaging Blessing
Sensors operate in harsh electromagnetic environments. Inverter pulse-width modulation (PWM) introduces Gaussian noise $\epsilon \sim \mathcal{N}(0, \sigma^2)$ into analog current transducers and thermistors. If we differentiate noisy data directly, finite differences amplify the high-frequency noise catastrophically:
$$\frac{d}{dt}(y + \epsilon \sin(\omega t)) = \frac{dy}{dt} + \epsilon \omega \cos(\omega t)$$
As frequency $\omega \to \infty$, the noise completely drowns the physical derivative! By filtering the signal with a moving average of width $W$, the noise variance drops by $\frac{1}{W}$, allowing clean, accurate derivatives.

---

## 4. Formal Mathematics & Governing Equations

### A. Electromechanical Powertrain Conversion
The motor rotor shaft angular velocity $\omega$ is converted from revolutions per minute ($\text{RPM}$) to radians per second:
$$\omega(t) = \text{motor\_speed\_rpm}(t) \times \frac{2\pi}{60} \quad [\text{rad/s}]$$

Mechanical shaft power delivered to the drivetrain:
$$P_{\text{mech}}(t) = \text{motor\_torque\_nm}(t) \times \omega(t) \quad [\text{Watts}]$$

### B. High-Voltage Electrical Power
Instantaneous electrical DC power at the high-voltage battery terminals:
$$P_{\text{elec}}(t) = \text{battery\_voltage\_v}(t) \times \text{battery\_current\_a}(t) \quad [\text{Watts}]$$

- **Motoring Mode ($P_{\text{mech}} > 0$)**: Current flows out of the battery ($I > 0$), discharging energy.
- **Regenerative Braking Mode ($P_{\text{mech}} < 0$)**: Kinetic energy drives the motor as a generator, forcing current into the pack ($I < 0$), recharging the cells.

### C. Instantaneous Powertrain Efficiency ($\eta$)
During active motoring under significant load ($P_{\text{elec}} \ge 1000\text{ W}$):
$$\eta(t) = \frac{P_{\text{mech}}(t)}{P_{\text{elec}}(t)}$$
Powertrain energy losses dissipated as heat:
$$P_{\text{loss}}(t) = |P_{\text{elec}}(t) - P_{\text{mech}}(t)| \quad [\text{Watts}]$$

### D. Cumulative Energy Quadrature
Total net electrical energy consumed over the drive cycle $[0, T]$:
$$E_{\text{total}} = \int_{0}^{T} P_{\text{elec}}(t) \, dt \quad [\text{Joules}]$$
Converted to commercial electrical units:
$$E_{\text{kWh}} = \frac{E_{\text{total}}}{3.6 \times 10^6} \quad [\text{kWh}]$$

Separating into gross driving energy expended ($P_{\text{elec}} > 0$) and regenerative energy recovered ($P_{\text{elec}} < 0$):
$$E_{\text{motoring}} = \int_{P_{\text{elec}} > 0} P_{\text{elec}}(t) \, dt, \quad E_{\text{regen}} = \int_{P_{\text{elec}} < 0} |P_{\text{elec}}(t)| \, dt$$
$$\text{Regeneration Recovery Ratio} = \frac{E_{\text{regen}}}{E_{\text{motoring}}} \times 100\%$$

### E. Numerical Differentiation and Thermal Transients
The finite-difference time derivative of heatsink temperature:
$$\left.\frac{dT}{dt}\right|_{t_{k+1/2}} \approx \frac{T_{k+1} - T_k}{t_{k+1} - t_k} \quad [^\circ\text{C/s}]$$

Governed physically by the lumped thermal parameter equation:
$$C_{\text{th}} \frac{dT_{\text{inv}}}{dt} = P_{\text{loss}}(t) - \frac{T_{\text{inv}}(t) - T_{\text{amb}}(t)}{R_{\text{th}}}$$

---

## 5. Worked Engineering Example
Let us compute a sample telemetry state at $t = 10.0\text{ s}$ during launch acceleration:
- $\text{Speed} = 3600.0\text{ RPM}$
- $\text{Torque} = 180.0\text{ N}\cdot\text{m}$
- $\text{Voltage} = 380.0\text{ V}$
- $\text{Current} = 190.0\text{ A}$

**Step 1: Mechanical Power**
$$\omega = 3600 \times \frac{2\pi}{60} = 120\pi \approx 376.991\text{ rad/s}$$
$$P_{\text{mech}} = 180.0 \times 376.991 \approx 67,858.4\text{ W} \quad (67.86\text{ kW})$$

**Step 2: Electrical Power**
$$P_{\text{elec}} = 380.0 \times 190.0 = 72,200.0\text{ W} \quad (72.20\text{ kW})$$

**Step 3: Instantaneous Efficiency & Power Loss**
$$\eta = \frac{67,858.4}{72,200.0} \approx 0.9399 \quad (93.99\%)$$
$$P_{\text{loss}} = 72,200.0 - 67,858.4 = 4,341.6\text{ W} \quad (4.34\text{ kW})$$

**Step 4: Thermal Rate of Change**
With $C_{\text{th}} = 1600\text{ J/K}$, $R_{\text{th}} = 0.78\text{ K/W}$, $T_{\text{inv}} = 42.0^\circ\text{C}$, $T_{\text{amb}} = 22.0^\circ\text{C}$:
$$\frac{dT}{dt} = \frac{4341.6}{1600} - \frac{42.0 - 22.0}{1600 \times 0.78} = 2.7135 - 0.0160 \approx 2.698^\circ\text{C/s}$$

---

## 6. MATLAB Implementation
The core numerical pipeline in MATLAB is executed as follows:

```matlab
% 1. Read CSV Telemetry
data = readtable('../data/ev_telemetry.csv');
t = data.timestamp_s;
speed_rpm = data.motor_speed_rpm;
torque_nm = data.motor_torque_nm;
voltage_v = data.battery_voltage_v;
current_a = data.battery_current_a;
t_inv = data.inverter_temp_c;

% 2. Multi-Physics Calculations
omega_rad_s = speed_rpm .* (2 * pi / 60);
P_mech = torque_nm .* omega_rad_s;             % Mechanical Power [W]
P_elec = voltage_v .* current_a;               % Electrical Power [W]

% 3. Numerical Quadrature: Net Energy Consumed
E_total_joules = trapz(t, P_elec);
E_total_kwh = E_total_joules / (3600 * 1000);

% 4. Digital Noise Filtering: Moving Average
window_size = 9;
kernel = ones(window_size, 1) / window_size;
t_inv_filtered = conv(t_inv, kernel, 'same');

% 5. Numerical Differentiation: Thermal Rate of Change
dt = diff(t);
dT_dt = diff(t_inv_filtered) ./ dt;
t_mid = (t(1:end-1) + t(2:end)) / 2;
```

---

## 7. Common Student Pitfalls & Debugging Tips
1. **RPM vs Radians per Second**: Multiplying torque directly by RPM yields units of $\text{N}\cdot\text{m}\cdot\text{RPM}$, which is **not** Watts! Always multiply RPM by $\frac{2\pi}{60} \approx 0.10472$ to obtain true angular velocity $\omega$ in $\text{rad/s}$.
2. **Differentiating Raw vs Filtered Signals**: Taking `diff(t_inv)` on raw sensor data amplifies quantization steps and thermistor noise by $\frac{1}{\Delta t} = 10\times$, resulting in wild, unphysical oscillations. Always filter the temperature signal before differentiation.
3. **Array Length in Differentiation**: `diff(x)` returns an array of length $N - 1$. If you attempt to plot `plot(t, dT_dt)`, MATLAB throws an error: `Vectors must be the same length.` Always pair `dT_dt` with midpoints: `t_mid = (t(1:end-1) + t(2:end)) / 2;` or slice `t(2:end)`.
4. **Efficiency in Low-Power or Regen Regimes**: When $P_{\text{elec}} \approx 0$, dividing $P_{\text{mech}} / P_{\text{elec}}$ produces numerical singularities ($\pm \infty$ or $\text{NaN}$). During regenerative braking, both $P_{\text{mech}}$ and $P_{\text{elec}}$ are negative, reversing the ratio. Filter your efficiency calculations to only include loaded motoring regimes ($P_{\text{elec}} \ge 1000\text{ W}$).

---

## 8. Engineering Interpretation
Once calculations are complete, engineers translate figures into vehicle design decisions:
- **Regenerative Braking Recovery**: In this 60-second cycle, the powertrain regenerates approximately $18\%$ to $24\%$ of the total acceleration energy back into the battery pack, extending electric driving range.
- **Thermal Heatsink Sizing**: The maximum observed $\frac{dT}{dt}$ occurs during the passing sprint ($t = 35 - 45\text{ s}$), reaching $\sim 2.8^\circ\text{C/s}$. Because the total temperature remains under $65^\circ\text{C}$, the liquid cooling pump flow rate is verified as sufficient for high-speed continuous highway driving.
- **Powertrain Efficiency Sweet Spot**: Peak efficiency ($\eta \ge 94\%$) is achieved at motor speeds between $3200\text{ RPM}$ and $4400\text{ RPM}$ and torques above $120\text{ N}\cdot\text{m}$. Transmission gear ratios should be selected to hold motor operation within this sweet spot during cruising.

---

## 9. Progressive Exercises Overview
The capstone resources are divided into guided development and reference solutions:

1. **Student Starter Template**: [`capstone_analysis_template.m`](capstone_analysis_template.m)
   - Pre-structured skeleton containing data ingestion, guided calculation steps, visualization subplots, and `% TODO` markers for student completion.
2. **Reference Implementation**: [`capstone_analysis_complete.m`](capstone_analysis_complete.m)
   - Fully resolved, end-to-end operational script with zero `% TODO` markers, professional plotting, and diagnostic console summaries.
3. **Decoupled Solution**: [`../solutions/capstone_solution.m`](../solutions/capstone_solution.m)
   - Mirrored reference solution residing in the central courseware `solutions/` directory.
4. **Dataset Specification & Schema**: [`../data/dataset_schema.md`](../data/dataset_schema.md)
   - Full sensor catalog and governing physical units.
