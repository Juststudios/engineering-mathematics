# Electric Vehicle Powertrain Telemetry Dataset Schema

This document defines the schema, physical dimensions, sensor characteristics, and multi-physics governing equations for the high-frequency Electric Vehicle (EV) Powertrain Telemetry dataset (`ev_telemetry.csv`).

---

## 1. Overview & Dataset Context

The dataset represents time-series telemetry collected from an electric vehicle powertrain undergoing a dynamic test-track drive cycle. The vehicle powertrain comprises:
- **Traction Motor**: High-performance Permanent Magnet Synchronous Motor (PMSM).
- **Inverter**: Three-phase silicon-carbide (SiC) variable-frequency power inverter.
- **Battery Pack**: Lithium-ion pack with nominal $400\text{ V}$ terminal rating.
- **Thermal Management**: Liquid cooling loop monitoring inverter junction temperature against ambient air.

The drive cycle spans $t = 0.0\text{ s}$ to $t = 60.0\text{ s}$ sampled at $f_s = 10\text{ Hz}$ ($\Delta t = 0.1\text{ s}$), containing exactly $601$ synchronized telemetry records. The cycle exercises all operational regimes: standstill, rapid highway acceleration, sustained cruise, high-speed passing, regenerative braking energy recovery, and final stop.

---

## 2. Telemetry Column Specifications

| Column Name | Data Type | Physical Unit | Measurement Range | Sensor Type | Description & Physical Meaning |
|:---|:---:|:---:|:---:|:---:|:---|
| `timestamp_s` | Float | Seconds ($\text{s}$) | $[0.0, 60.0]$ | Hardware Clock | Time elapsed since drive cycle start ($\Delta t = 0.1\text{ s}$). |
| `motor_speed_rpm` | Float | Revolutions per minute ($\text{RPM}$) | $[0.0, 5200.0]$ | Digital Optical Encoder | Rotational velocity of the motor rotor shaft. |
| `motor_torque_nm` | Float | Newton-meters ($\text{N}\cdot\text{m}$) | $[-140.0, 260.0]$ | In-line Strain Torque Transducer | Mechanical shaft torque. Positive indicates motoring propulsion; negative indicates regenerative braking. |
| `battery_voltage_v` | Float | Volts ($\text{V}$) | $[360.0, 415.0]$ | High-Voltage Hall Effect Sensor | Battery pack DC bus terminal voltage under dynamic load. |
| `battery_current_a` | Float | Amperes ($\text{A}$) | $[-120.0, 240.0]$ | Current Shunt Transducer | Pack DC current. Positive indicates discharge (motoring); negative indicates charge (regeneration). |
| `inverter_temp_c` | Float | Degrees Celsius ($^\circ\text{C}$) | $[30.0, 85.0]$ | Embedded NTC Thermistor | SiC power inverter module heatsink temperature. |
| `ambient_temp_c` | Float | Degrees Celsius ($^\circ\text{C}$) | $[20.0, 25.0]$ | External RTD Probe | Outside ambient air temperature surrounding the vehicle chassis. |

---

## 3. Multi-Physics Governing Equations

Students and automated analysis pipelines synthesize multiple engineering physics disciplines using these governing formulas:

### A. Mechanical Power ($P_{\text{mech}}$)
Mechanical power delivered by the motor shaft into the single-speed reduction transmission:
$$\omega = \text{motor\_speed\_rpm} \times \frac{2\pi}{60} \quad [\text{rad/s}]$$
$$P_{\text{mech}} = \text{motor\_torque\_nm} \times \omega \quad [\text{Watts}]$$

- In motoring mode ($\tau > 0$, $\omega > 0$): $P_{\text{mech}} > 0$.
- In regenerative braking mode ($\tau < 0$, $\omega > 0$): $P_{\text{mech}} < 0$.

### B. Electrical Power ($P_{\text{elec}}$)
Total DC electrical power drawn from (or injected into) the high-voltage traction battery:
$$P_{\text{elec}} = \text{battery\_voltage\_v} \times \text{battery\_current\_a} \quad [\text{Watts}]$$

- Positive $P_{\text{elec}}$ denotes net energy discharge from the battery pack into the inverter.
- Negative $P_{\text{elec}}$ denotes net energy recovery during regenerative braking.

### C. Powertrain Efficiency ($\eta$)
During active motoring ($P_{\text{mech}} > 0$ and $P_{\text{elec}} > 0$ above an operational threshold $P_{\text{elec}} \ge 1000\text{ W}$):
$$\eta = \frac{P_{\text{mech}}}{P_{\text{elec}}}$$

Real PMSM powertrain efficiency typically spans $88\%$ to $95\%$ under loaded conditions, accounting for combined copper ($I^2 R$) losses, inverter switching losses, core iron losses, and mechanical bearing friction.

### D. Total Energy Consumed ($E$) via Numerical Quadrature
The total net electrical energy consumed over the duration of the cycle $[t_0, t_{\text{end}}]$ is the definite time integral of instantaneous electrical power:
$$E = \int_{t_0}^{t_{\text{end}}} P_{\text{elec}}(t) \, dt \quad [\text{Joules}]$$

In MATLAB, this accumulation is computed via numerical trapezoidal integration:
```matlab
E_joules = trapz(timestamp_s, P_elec);
E_kwh = E_joules / (3600 * 1000); % Convert J -> kWh
```

### E. Inverter Thermal Dissipation Rate ($dT/dt$) via Numerical Differentiation
Power losses in the inverter silicon switches manifest as heat dissipation:
$$P_{\text{loss}} = |P_{\text{elec}} - P_{\text{mech}}| \quad [\text{Watts}]$$

The temperature change rate of the inverter heatsink is governed by Newton's law of cooling combined with heat generation:
$$\frac{dT_{\text{inv}}}{dt} = \frac{P_{\text{loss}}}{C_{\text{th}}} - \frac{T_{\text{inv}} - T_{\text{amb}}}{R_{\text{th}}}$$

Numerically, the time derivative is approximated via finite differences using MATLAB's `diff`:
```matlab
dt = diff(timestamp_s);
dT_dt = diff(inverter_temp_c) ./ dt; % [deg C / s]
t_mid = (timestamp_s(1:end-1) + timestamp_s(2:end)) / 2;
```

### F. Sensor Noise & Digital Signal Filtering
Real-world physical sensors capture high-frequency electromagnetic noise (EMI) from the inverter's PWM switching. The measured signals are modeled as true physical values corrupted by zero-mean additive white Gaussian noise (AWGN):
$$y_{\text{measured}}(t) = y_{\text{true}}(t) + \epsilon(t), \quad \epsilon(t) \sim \mathcal{N}(0, \sigma^2)$$

To extract smooth derivative curves and clean telemetry without amplifying high-frequency noise, a symmetrical moving average filter of window width $W = 9$ is applied:
$$\bar{y}[k] = \frac{1}{W} \sum_{j=-(W-1)/2}^{(W-1)/2} y_{\text{measured}}[k+j]$$
This reduces sensor noise variance by a factor of $1/W$.

---

## 4. Drive Cycle Regimes & Phase Breakdown

| Phase | Time Window ($s$) | Operational State | Target Speed | Target Torque | Power Regime |
|:---|:---:|:---|:---:|:---:|:---|
| **Phase 1: Launch** | $0.0 - 15.0$ | Heavy Acceleration | $0 \to 3800\text{ RPM}$ | $+180 \to +240\text{ N}\cdot\text{m}$ | Motoring ($0 \to 85\text{ kW}$) |
| **Phase 2: Cruise** | $15.0 - 35.0$ | Highway Cruising | $3600 - 4000\text{ RPM}$ | $+60 \to +90\text{ N}\cdot\text{m}$ | Steady Motoring ($\sim 25 - 35\text{ kW}$) |
| **Phase 3: Sprint** | $35.0 - 45.0$ | Passing Acceleration | $4000 \to 5100\text{ RPM}$ | $+220 \to +250\text{ N}\cdot\text{m}$ | Peak Motoring ($\sim 115\text{ kW}$) |
| **Phase 4: Regen** | $45.0 - 55.0$ | Regenerative Braking | $5100 \to 1200\text{ RPM}$ | $-80 \to -130\text{ N}\cdot\text{m}$ | Energy Recovery ($-40 \to -15\text{ kW}$) |
| **Phase 5: Rest** | $55.0 - 60.0$ | Decel to Standstill | $1200 \to 0\text{ RPM}$ | $0\text{ N}\cdot\text{m}$ | Idle Draw ($\sim 0.3\text{ kW}$ aux) |

---

## 5. File Location and Access

The active telemetry file is stored at:
- Repository root: `data/ev_telemetry.csv`
- Generator scripts: `capstone/generate_capstone_data.py` and `capstone/generate_capstone_data.m`
- Capstone starter template: `capstone/capstone_analysis_template.m`
- Full reference solution: `capstone/capstone_analysis_complete.m` (also mirrored at `solutions/capstone_solution.m`)
