# Simulink Model Blueprint: 1st-Order RC Circuit Low-Pass Filter

## 1. Physical System Description & Governing Equations

An electrical low-pass filter consists of a series resistor $R$ and shunt capacitor $C$. When driven by an input voltage source $v_{\text{in}}(t)$, charge accumulates across the capacitor dielectric, establishing capacitor voltage $v_C(t)$.

```
          R
  o─────/\/\/\─────┬────────o  +
 +                 │
v_in(t)          ===== C      v_C(t)
 -                 │
  o────────────────┴────────o  -
```

### Governing Equations
Applying Kirchhoff's Current Law (KCL) at the node between $R$ and $C$:
$$i_R(t) = i_C(t)$$

Substituting Ohm's Law and the constitutive differential relationship for capacitance ($i_C = C \frac{dv_C}{dt}$):
$$\frac{v_{\text{in}}(t) - v_C(t)}{R} = C \frac{dv_C}{dt}$$

Isolating the state derivative:
$$\frac{dv_C}{dt} = \frac{1}{RC} \big( v_{\text{in}}(t) - v_C(t) \big)$$

The circuit time constant is:
$$\tau = R \cdot C \quad [\text{seconds}]$$

---

## 2. Block Diagram Visual Blueprint

Below is the complete signal-flow topology for the RC circuit model:

```
                      +-----------------------------------------------------------------------+
                      |                      RC CIRCUIT LOW-PASS FILTER                       |
                      +-----------------------------------------------------------------------+

                                                                        v_C(t)
                                                         ┌─────────────────────────────────────┐
                                                         │                                     ▼
                     v_in(t)   +┌──────┐   dv_C/dt   ┌───┴──────────┐   v_C(t)             ┌─────────┐
    [ Step Source ]────────────►│ Sum  ├────────────►│  Integrator  ├────────┬────────────►│  Scope  │
                                └▲────┬┘  (1/(R*C))  │    (1/s)     │        │             └─────────┘
                                -│    │              └──────────────┘        │
                                 │    +--------------------------------------+             ┌─────────┐
                                 │               Feedback Branch                           │   To    │
                                 └────────────────────────────────────────────────────────►│Workspace│
                                                                                           └─────────┘
```

---

## 3. Block Parameter Specifications

Every block in the model must be configured according to this specification:

| Block Label | Library Path | Parameter | Value | Engineering Rationale |
| :--- | :--- | :--- | :--- | :--- |
| **`Step_Voltage`** | `simulink/Sources/Step` | `Step time`<br>`Initial value`<br>`Final value`<br>`Sample time` | `0.1`<br>`0.0`<br>`5.0`<br>`0` | Evaluates circuit transient response from zero initial state to a $5\text{ V}$ step applied at $t = 0.1\text{ s}$. |
| **`Sum_Error`** | `simulink/Math Operations/Sum` | `Icon shape`<br>`List of signs` | `round` or `rectangular`<br>`|+-` | Computes the net voltage drop across resistor: $v_R = v_{\text{in}} - v_C$. |
| **`Gain_InvTau`** | `simulink/Math Operations/Gain` | `Gain`<br>`Multiplication` | `1 / (R * C)`<br>`Element-wise(K.*u)` | Scales resistor voltage drop by inverse time constant to yield state rate $\frac{dv_C}{dt}$. |
| **`Integrator_vC`** | `simulink/Continuous/Integrator` | `Initial condition`<br>`Limit output`<br>`Upper limit`<br>`Lower limit` | `0.0`<br>`off` (or `on`)<br>`5.0`<br>`0.0` | Integrates $\frac{dv_C}{dt}$ to produce capacitor voltage state $v_C(t)$. |
| **`Scope_vC`** | `simulink/Sinks/Scope` | `Number of input ports`<br>`Time span`<br>`Y-limits` | `1`<br>`5.0`<br>`[-0.5, 6.0]` | Visual inspection of capacitor charging transient and exponential relaxation. |
| **`ToWorkspace_vC`** | `simulink/Sinks/To Workspace` | `Variable name`<br>`Save format`<br>`Decimation` | `vc_sim`<br>`Timeseries`<br>`1` | Exports time-series object to MATLAB base workspace for post-processing and metric calculation. |

---

## 4. Signal Connection & Wiring Schedule

| Connection # | Source Block & Port | Destination Block & Port | Signal Name | Physical Units |
| :--- | :--- | :--- | :--- | :--- |
| **Wire 1** | `Step_Voltage / 1` | `Sum_Error / 1` | `v_in` | $\text{Volts (V)}$ |
| **Wire 2** | `Sum_Error / 1` | `Gain_InvTau / 1` | `v_R` | $\text{Volts (V)}$ |
| **Wire 3** | `Gain_InvTau / 1` | `Integrator_vC / 1` | `dvc_dt` | $\text{Volts / second (V/s)}$ |
| **Wire 4** | `Integrator_vC / 1` | `Scope_vC / 1` | `v_C` | $\text{Volts (V)}$ |
| **Wire 5** | `Integrator_vC / 1` | `ToWorkspace_vC / 1`| `v_C` | $\text{Volts (V)}$ |
| **Wire 6 (Feedback)** | `Integrator_vC / 1` | `Sum_Error / 2` | `v_C_fb` | $\text{Volts (V)}$ |

---

## 5. Model Configuration Parameters (`Ctrl+E`)

- **Solver Selection:**
  - `Type:` `Variable-step`
  - `Solver:` `ode45 (Dormand-Prince)`
  - `Relative tolerance:` `1e-6`
  - `Absolute tolerance:` `1e-8`
- **Simulation Time:**
  - `Start time:` `0.0`
  - `Stop time:` `6.0` (provides $5.9\text{ s} \approx 6\tau$ of dwell time after step onset).

---

## 6. Programmatic Model Generator Script

Run this MATLAB script to automatically construct and wire the model in Simulink:

```matlab
% build_rc_circuit_model.m
% Programmatically creates and connects the RC low-pass filter model in Simulink

model_name = 'rc_circuit_blueprint';
if bdIsLoaded(model_name)
    close_system(model_name, 0);
end
new_system(model_name);
open_system(model_name);

% 1. Add Blocks
add_block('simulink/Sources/Step', [model_name, '/Step_Voltage'], ...
    'Time', '0.1', 'Before', '0', 'After', '5', 'Position', [50, 80, 90, 120]);

add_block('simulink/Math Operations/Sum', [model_name, '/Sum_Error'], ...
    'Inputs', '+-', 'Position', [150, 85, 175, 115]);

add_block('simulink/Math Operations/Gain', [model_name, '/Gain_InvTau'], ...
    'Gain', '1 / (10e3 * 100e-6)', 'Position', [225, 80, 275, 120]);

add_block('simulink/Continuous/Integrator', [model_name, '/Integrator_vC'], ...
    'InitialCondition', '0', 'Position', [330, 80, 365, 120]);

add_block('simulink/Sinks/Scope', [model_name, '/Scope_vC'], ...
    'Position', [450, 70, 485, 105]);

add_block('simulink/Sinks/To Workspace', [model_name, '/ToWorkspace_vC'], ...
    'VariableName', 'sim_vc', 'SaveFormat', 'Timeseries', ...
    'Position', [450, 130, 500, 165]);

% 2. Add Forward Connections
add_line(model_name, 'Step_Voltage/1', 'Sum_Error/1');
add_line(model_name, 'Sum_Error/1', 'Gain_InvTau/1');
add_line(model_name, 'Gain_InvTau/1', 'Integrator_vC/1');
add_line(model_name, 'Integrator_vC/1', 'Scope_vC/1');
add_line(model_name, 'Integrator_vC/1', 'ToWorkspace_vC/1');

% 3. Add Feedback Connection
add_line(model_name, 'Integrator_vC/1', 'Sum_Error/2');

% 4. Set Simulation Parameters
set_param(model_name, 'StopTime', '6.0', 'Solver', 'ode45', ...
    'RelTol', '1e-6', 'AbsTol', '1e-8');

save_system(model_name);
fprintf('Successfully generated and saved %s.slx\n', model_name);
```

This completes the structural specification for the 1st-order RC circuit filter model.
