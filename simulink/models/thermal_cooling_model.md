# Simulink Model Blueprint: Lumped Thermal Cooling with Convective Dissipation

## 1. Physical System Description & Governing Equations

Power electronics devices (such as IGBT inverters, power MOSFETs, and battery packs) generate internal resistive and switching power losses $P_{\text{in}}(t)$ during operation. This thermal energy accumulates within the thermal capacitance $C_{\text{th}}$ of the heatsink, driving temperature $T(t)$ above ambient temperature $T_{\text{amb}}$.

Convective cooling transfers heat to the surrounding fluid according to Newton's Law of Cooling:
$$q_{\text{out}}(t) = h A \big( T(t) - T_{\text{amb}} \big) \quad [\text{Watts}]$$

where:
- $C_{\text{th}}$: Thermal capacity of the device / heat sink $[\text{J/K}]$ (or $[\text{W}\cdot\text{s/K}]$)
- $h$: Convective heat transfer coefficient $[\text{W}/(\text{m}^2\cdot\text{K})]$
- $A$: Effective convective surface area $[\text{m}^2]$
- $h A$: Lumped thermal conductance $[\text{W/K}]$
- $T_{\text{amb}}$: Ambient environment temperature $[^\circ\text{C}]$

### Governing Differential Equation
Applying the first law of thermodynamics (energy conservation):
$$\dot{Q}_{\text{stored}} = \dot{Q}_{\text{in}} - \dot{Q}_{\text{out}}$$
$$C_{\text{th}} \frac{dT}{dt} = P_{\text{in}}(t) - h A \big( T(t) - T_{\text{amb}} \big)$$

Isolating the state derivative:
$$\frac{dT}{dt} = \frac{1}{C_{\text{th}}} \Big( P_{\text{in}}(t) - h A \big( T(t) - T_{\text{amb}} \big) \Big)$$

Thermal time constant:
$$\tau_{\text{th}} = \frac{C_{\text{th}}}{h A} \quad [\text{seconds}]$$

---

## 2. Block Diagram Visual Blueprint

Below is the complete signal-flow topology for the thermal dissipation model:

```
                      +-----------------------------------------------------------------------+
                      |                   THERMAL COOLING & DISSIPATION MODEL                 |
                      +-----------------------------------------------------------------------+

                                                                        T(t)
                                                         ┌─────────────────────────────────────┐
                                                         │                                     ▼
        P_in(t)        +┌──────┐   dT/dt             ┌───┴──────────┐    T(t)                  ┌─────────┐
    [ Pulse Generator ]►│ Sum  ├────────────►[ Gain ]►│  Integrator  ├───┬────────────────────►│  Scope  │
                        └▲────┬┘ (P_net)    (1/C_th) │    (1/s)     │   │                     └─────────┘
                        -│    │                      └──────────────┘   │
                         │    +─────────────────────────────────────────┼─────────────────────┐
                         │                                              │                     │
                         │                                              │ T(t)                │
                         │      ┌──────┐    q_conv       ┌──────────┐   │                     │
                         └──────┤ Gain ◄─────────────────┤   Sum    ◄───┘                     │
                                │ (hA) │                 └▲────────┬┘                         │
                                └──────┘                 -│        │                          ▼
                                                          │        │                     ┌─────────┐
                                          T_amb           │        └────────────────────►│   To    │
                                      [ Constant ]────────┘                              │Workspace│
                                                                                         └─────────┘
```

---

## 3. Block Parameter Specifications

Every block in the model is configured according to the following engineering parameter schedule:

| Block Label | Library Path | Parameter | Value | Engineering Rationale |
| :--- | :--- | :--- | :--- | :--- |
| **`Pulse_Heat_Source`** | `simulink/Sources/Pulse Generator` | `Pulse type`<br>`Amplitude`<br>`Period`<br>`Pulse width`<br>`Phase delay` | `Time based`<br>`150.0`<br>`600.0`<br>`33.333`<br>`100.0` | Injects $150\text{ W}$ inverter heat pulse between $t = 100\text{ s}$ and $t = 300\text{ s}$ ($200\text{ s}$ duration). |
| **`Constant_Tamb`** | `simulink/Sources/Constant` | `Constant value`<br>`Sample time` | `25.0`<br>`0` | Constant ambient air temperature $T_{\text{amb}} = 25.0^\circ\text{C}$. |
| **`Sum_DeltaT`** | `simulink/Math Operations/Sum` | `List of signs`<br>`Icon shape` | `+-`<br>`rectangular` | Computes temperature differential across heatsink boundary: $\Delta T = T(t) - T_{\text{amb}}$. |
| **`Gain_hA`** | `simulink/Math Operations/Gain` | `Gain`<br>`Multiplication` | `4.5`<br>`Element-wise(K.*u)` | Converts thermal gradient into convective heat rejection rate $q_{\text{conv}} = h A \cdot \Delta T\ [\text{W}]$. |
| **`Sum_Pnet`** | `simulink/Math Operations/Sum` | `List of signs`<br>`Icon shape` | `+-`<br>`rectangular` | Calculates net heat accumulation: $P_{\text{net}} = P_{\text{in}} - q_{\text{conv}}\ [\text{W}]$. |
| **`Gain_InvCth`** | `simulink/Math Operations/Gain` | `Gain`<br>`Multiplication` | `1 / 180.0`<br>`Element-wise(K.*u)` | Divides net power by thermal capacity to produce temperature rate $\frac{dT}{dt}\ [^\circ\text{C/s}]$. |
| **`Integrator_T`** | `simulink/Continuous/Integrator` | `Initial condition`<br>`Limit output` | `25.0`<br>`off` | Integrates $\frac{dT}{dt}$ starting from thermal equilibrium at ambient $T(0) = 25.0^\circ\text{C}$. |
| **`Scope_Thermal`** | `simulink/Sinks/Scope` | `Number of input ports`<br>`Time span` | `1`<br>`600.0` | Displays heating transient, asymptotic peak, and subsequent convective cooldown. |
| **`ToWorkspace_T`** | `simulink/Sinks/To Workspace` | `Variable name`<br>`Save format` | `T_sim`<br>`Timeseries` | Exports simulated temperature trajectory to MATLAB workspace for validation. |

---

## 4. Signal Connection & Wiring Schedule

| Connection # | Source Block & Port | Destination Block & Port | Signal Name | Physical Units |
| :--- | :--- | :--- | :--- | :--- |
| **Wire 1** | `Pulse_Heat_Source / 1` | `Sum_Pnet / 1` | `P_in` | $\text{Watts (W)}$ |
| **Wire 2** | `Integrator_T / 1` | `Sum_DeltaT / 1` | `T_junction` | $^\circ\text{C}$ |
| **Wire 3** | `Constant_Tamb / 1` | `Sum_DeltaT / 2` | `T_amb` | $^\circ\text{C}$ |
| **Wire 4** | `Sum_DeltaT / 1` | `Gain_hA / 1` | `delta_T` | $^\circ\text{C}$ |
| **Wire 5** | `Gain_hA / 1` | `Sum_Pnet / 2` | `q_conv` | $\text{Watts (W)}$ |
| **Wire 6** | `Sum_Pnet / 1` | `Gain_InvCth / 1` | `P_net` | $\text{Watts (W)}$ |
| **Wire 7** | `Gain_InvCth / 1` | `Integrator_T / 1` | `dT_dt` | $^\circ\text{C/s}$ |
| **Wire 8** | `Integrator_T / 1` | `Scope_Thermal / 1` | `T_junction` | $^\circ\text{C}$ |
| **Wire 9** | `Integrator_T / 1` | `ToWorkspace_T / 1` | `T_junction` | $^\circ\text{C}$ |

---

## 5. Model Configuration Parameters (`Ctrl+E`)

- **Solver Selection:**
  - `Type:` `Variable-step`
  - `Solver:` `ode45 (Dormand-Prince)`
  - `Relative tolerance:` `1e-6`
  - `Absolute tolerance:` `1e-8`
- **Simulation Time:**
  - `Start time:` `0.0`
  - `Stop time:` `600.0` (allows $300\text{ s} = 7.5\tau_{\text{th}}$ cooldown observation).

---

## 6. Programmatic Model Generator Script

Run this script inside MATLAB to build the block diagram automatically:

```matlab
% build_thermal_cooling_model.m
% Programmatically creates the Newton thermal cooling model in Simulink

model_name = 'thermal_cooling_blueprint';
if bdIsLoaded(model_name)
    close_system(model_name, 0);
end
new_system(model_name);
open_system(model_name);

% 1. Add Blocks
add_block('simulink/Sources/Pulse Generator', [model_name, '/Pulse_Heat_Source'], ...
    'PulseType', 'Time based', 'Amplitude', '150', 'Period', '600', 'PulseWidth', '33.333', 'PhaseDelay', '100', ...
    'Position', [50, 60, 90, 100]);

add_block('simulink/Math Operations/Sum', [model_name, '/Sum_Pnet'], ...
    'Inputs', '+-', 'Position', [150, 70, 175, 100]);

add_block('simulink/Math Operations/Gain', [model_name, '/Gain_InvCth'], ...
    'Gain', '1 / 180', 'Position', [220, 65, 270, 105]);

add_block('simulink/Continuous/Integrator', [model_name, '/Integrator_T'], ...
    'InitialCondition', '25.0', 'Position', [315, 70, 345, 100]);

add_block('simulink/Sources/Constant', [model_name, '/Constant_Tamb'], ...
    'Value', '25.0', 'Position', [200, 200, 240, 230]);

add_block('simulink/Math Operations/Sum', [model_name, '/Sum_DeltaT'], ...
    'Inputs', '+-', 'Position', [320, 170, 345, 200]);

add_block('simulink/Math Operations/Gain', [model_name, '/Gain_hA'], ...
    'Gain', '4.5', 'Position', [220, 165, 260, 205]);

add_block('simulink/Sinks/Scope', [model_name, '/Scope_Thermal'], ...
    'Position', [420, 45, 450, 85]);

add_block('simulink/Sinks/To Workspace', [model_name, '/ToWorkspace_T'], ...
    'VariableName', 'T_sim', 'SaveFormat', 'Timeseries', 'Position', [420, 105, 460, 135]);

% 2. Add Signal Connections
add_line(model_name, 'Pulse_Heat_Source/1', 'Sum_Pnet/1');
add_line(model_name, 'Sum_Pnet/1', 'Gain_InvCth/1');
add_line(model_name, 'Gain_InvCth/1', 'Integrator_T/1');
add_line(model_name, 'Integrator_T/1', 'Scope_Thermal/1');
add_line(model_name, 'Integrator_T/1', 'ToWorkspace_T/1');
add_line(model_name, 'Integrator_T/1', 'Sum_DeltaT/1');
add_line(model_name, 'Constant_Tamb/1', 'Sum_DeltaT/2');
add_line(model_name, 'Sum_DeltaT/1', 'Gain_hA/1');
add_line(model_name, 'Gain_hA/1', 'Sum_Pnet/2');

save_system(model_name);
fprintf('Thermal cooling blueprint successfully created: %s.slx\n', model_name);
```
