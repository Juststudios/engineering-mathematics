# Simulink Model Blueprint: Coupled Electromechanical DC Motor Dynamics

## 1. Physical System Description & Governing Equations

A permanent-magnet DC motor converts electrical power into mechanical rotation through electrodynamic coupling. The system couples electrical dynamics in the armature circuit with mechanical dynamics of the rotor and load shaft.

```
       R_a       L_a
   o──/\/\/\────UUUUU────┬────────o  +
  +                      │
 V_in(t)               ( M ) e_b(t) = K_e * omega(t)
  -                      │
   o─────────────────────┴────────o  -
                         │ (Shaft)
                         ▼
                     [ J, b ] ====> tau_L (Load torque)
```

### Electrical Subsystem (Armature Circuit)
Applying Kirchhoff's Voltage Law (KVL) around the armature loop:
$$V_{\text{in}}(t) - R_a i_a(t) - L_a \frac{di_a}{dt} - e_b(t) = 0$$

where the back-electromotive force (back-EMF) induced by rotor rotation is:
$$e_b(t) = K_e \omega(t)$$

Isolating the electrical state derivative:
$$\frac{di_a}{dt} = \frac{1}{L_a} \big( V_{\text{in}}(t) - R_a i_a(t) - K_e \omega(t) \big)$$

### Mechanical Subsystem (Rotor Dynamics)
Applying Newton's second law for rotational mechanics ($\sum \tau = J \alpha$):
$$J \frac{d\omega}{dt} = \tau_{\text{motor}}(t) - b \omega(t) - \tau_L(t)$$

where electromechanical motor torque is proportional to armature current:
$$\tau_{\text{motor}}(t) = K_t i_a(t)$$

Isolating the mechanical state derivative:
$$\frac{d\omega}{dt} = \frac{1}{J} \big( K_t i_a(t) - b \omega(t) - \tau_L(t) \big)$$

### Coupled State-Space Formulation
Combining the state vector $\mathbf{x}(t) = \begin{bmatrix} i_a(t) \\ \omega(t) \end{bmatrix}$ and input vector $\mathbf{u}(t) = \begin{bmatrix} V_{\text{in}}(t) \\ \tau_L(t) \end{bmatrix}$:
$$\begin{bmatrix} \dot{i}_a \\ \dot{\omega} \end{bmatrix} = \begin{bmatrix} -R_a/L_a & -K_e/L_a \\ K_t/J & -b/J \end{bmatrix} \begin{bmatrix} i_a \\ \omega \end{bmatrix} + \begin{bmatrix} 1/L_a & 0 \\ 0 & -1/J \end{bmatrix} \begin{bmatrix} V_{\text{in}} \\ \tau_L \end{bmatrix}$$

---

## 2. Block Diagram Visual Blueprint

Below is the dual-integrator coupled signal-flow diagram:

```
                      +-----------------------------------------------------------------------+
                      |                   ELECTROMECHANICAL DC MOTOR MODEL                    |
                      +-----------------------------------------------------------------------+

                                 ELECTRICAL LOOP (Armature)
                                 ==========================
                     +┌──────┐   di_a/dt    ┌──────────────┐    i_a(t)
    V_in(t) ─────────►│ Sum  ├─────────────►│ Integrator 1 ├───┬───────►[ Gain: K_t ]─────────┐
                      └▲▲───┬┘  (1/L_a)     │    (1/s)     │   │         (Torque)             │
                      -││   │               └──────────────┘   │                              ▼
         ┌──[ Ra ]─────┘│   +──────────────────────────────────┼───────────► Scope: i_a   +┌──────┐
         │              │  Feedback: -R_a*i_a                  │                          │ Sum  │
         │              │                                      │       ┌──[ b ]───────────►└▲▲───┬┘
         │              │                                      │       │  Damping         -││    │
         │              └──────────────[ K_e ]◄────────────────┼───────┤                   ││    ▼
         │                              Back-EMF               │       │                   ││  domega/dt
         │                                                     │       │                   ││   (1/J)
         │                       MECHANICAL LOOP (Rotor)       │       │                   ││    │
         │                       =======================       │       │                   ││    ▼
         │                                                     │       │            ┌──────┴┴─────┐
         │                                                     │       │            │Integrator 2 │
         │                                                     │       │            │    (1/s)    │
         │                                                     │       │            └──────┬──────┘
         │                                                     │       │                   │ omega(t)
         │                                                     │       │                   ├─────► Scope: omega
         │                                                     │       └───────────────────┤
         │                                                     │                           ├─────► ToWorkspace
         │                                                     │                           │
         │   tau_L(t) (Disturbance Step) ──────────────────────┼───────────────────────────┘
         │
         └─────────────────────────────────────────────────────┘
```

---

## 3. Block Parameter Specifications

Every block in the model is configured according to the following parameter schedule:

| Block Label | Library Path | Parameter | Value | Engineering Rationale |
| :--- | :--- | :--- | :--- | :--- |
| **`Step_Vin`** | `simulink/Sources/Step` | `Step time`<br>`Initial value`<br>`Final value` | `0.0`<br>`0.0`<br>`24.0` | Applies $24\text{ V}$ rated terminal voltage at $t = 0\text{ s}$. |
| **`Step_LoadTorque`** | `simulink/Sources/Step` | `Step time`<br>`Initial value`<br>`Final value` | `3.0`<br>`0.0`<br>`0.5` | Injects $0.5\text{ N}\cdot\text{m}$ mechanical shaft disturbance at $t = 3.0\text{ s}$. |
| **`Sum_Armature`** | `simulink/Math Operations/Sum` | `List of signs`<br>`Icon shape` | `+--`<br>`rectangular` | Computes net voltage: $V_{\text{in}} - R_a i_a - e_b$. |
| **`Gain_InvLa`** | `simulink/Math Operations/Gain` | `Gain` | `1 / 0.5` ($2.0$) | Yields current rate of change $\frac{di_a}{dt}\ [\text{A/s}]$. |
| **`Integrator_ia`** | `simulink/Continuous/Integrator` | `Initial condition` | `0.0` | Integrates $\frac{di_a}{dt}$ from zero initial armature current. |
| **`Gain_Ra`** | `simulink/Math Operations/Gain` | `Gain` | `2.0` | Armature resistance voltage drop $v_{Ra} = R_a i_a\ [\text{V}]$. |
| **`Gain_Kt`** | `simulink/Math Operations/Gain` | `Gain` | `0.1` | Motor electromagnetic torque $\tau_{\text{motor}} = K_t i_a\ [\text{N}\cdot\text{m}]$. |
| **`Sum_Shaft`** | `simulink/Math Operations/Sum` | `List of signs` | `+--` | Net accelerating shaft torque: $\tau_{\text{motor}} - b\omega - \tau_L$. |
| **`Gain_InvJ`** | `simulink/Math Operations/Gain` | `Gain` | `1 / 0.02` ($50.0$) | Yields angular acceleration $\frac{d\omega}{dt}\ [\text{rad/s}^2]$. |
| **`Integrator_omega`** | `simulink/Continuous/Integrator` | `Initial condition` | `0.0` | Integrates angular acceleration to produce rotor speed $\omega(t)\ [\text{rad/s}]$. |
| **`Gain_Ke`** | `simulink/Math Operations/Gain` | `Gain` | `0.1` | Generates back-EMF feedback $e_b = K_e \omega\ [\text{V}]$. |
| **`Gain_b`** | `simulink/Math Operations/Gain` | `Gain` | `0.01` | Viscous damping friction torque $\tau_b = b \omega\ [\text{N}\cdot\text{m}]$. |
| **`Scope_Motor`** | `simulink/Sinks/Scope` | `Number of input ports` | `2` | Plots current $i_a(t)$ (inrush transient) and rotor speed $\omega(t)$ (droop response). |
| **`ToWorkspace_Motor`** | `simulink/Sinks/To Workspace` | `Variable name` | `motor_sim` | Exports multidimensional time-series to base workspace. |

---

## 4. Signal Connection & Wiring Schedule

| Connection # | Source Block & Port | Destination Block & Port | Signal Name | Physical Units |
| :--- | :--- | :--- | :--- | :--- |
| **Wire 1** | `Step_Vin / 1` | `Sum_Armature / 1` | `V_in` | $\text{Volts (V)}$ |
| **Wire 2** | `Sum_Armature / 1` | `Gain_InvLa / 1` | `V_ind` | $\text{Volts (V)}$ |
| **Wire 3** | `Gain_InvLa / 1` | `Integrator_ia / 1` | `dia_dt` | $\text{Amperes / second (A/s)}$ |
| **Wire 4** | `Integrator_ia / 1` | `Gain_Ra / 1` | `i_a` | $\text{Amperes (A)}$ |
| **Wire 5** | `Gain_Ra / 1` | `Sum_Armature / 2` | `V_Ra` | $\text{Volts (V)}$ |
| **Wire 6** | `Integrator_ia / 1` | `Gain_Kt / 1` | `i_a` | $\text{Amperes (A)}$ |
| **Wire 7** | `Gain_Kt / 1` | `Sum_Shaft / 1` | `tau_motor` | $\text{N}\cdot\text{m}$ |
| **Wire 8** | `Step_LoadTorque / 1` | `Sum_Shaft / 2` | `tau_L` | $\text{N}\cdot\text{m}$ |
| **Wire 9** | `Sum_Shaft / 1` | `Gain_InvJ / 1` | `tau_net` | $\text{N}\cdot\text{m}$ |
| **Wire 10** | `Gain_InvJ / 1` | `Integrator_omega / 1` | `domega_dt`| $\text{rad/s}^2$ |
| **Wire 11** | `Integrator_omega / 1` | `Gain_Ke / 1` | `omega` | $\text{rad/s}$ |
| **Wire 12** | `Gain_Ke / 1` | `Sum_Armature / 3` | `e_b` | $\text{Volts (V)}$ |
| **Wire 13** | `Integrator_omega / 1` | `Gain_b / 1` | `omega` | $\text{rad/s}$ |
| **Wire 14** | `Gain_b / 1` | `Sum_Shaft / 3` | `tau_friction` | $\text{N}\cdot\text{m}$ |
| **Wire 15** | `Integrator_ia / 1` | `Scope_Motor / 1` | `i_a` | $\text{Amperes (A)}$ |
| **Wire 16** | `Integrator_omega / 1` | `Scope_Motor / 2` | `omega` | $\text{rad/s}$ |

---

## 5. Model Configuration Parameters (`Ctrl+E`)

- **Solver Selection:**
  - `Type:` `Variable-step`
  - `Solver:` `ode45 (Dormand-Prince)`
  - `Relative tolerance:` `1e-6`
  - `Absolute tolerance:` `1e-8`
- **Simulation Time:**
  - `Start time:` `0.0`
  - `Stop time:` `6.0` (provides $3.0\text{ s}$ of no-load run and $3.0\text{ s}$ of loaded settling).

---

## 6. Programmatic Model Generator Script

Run this script inside MATLAB to build the block diagram automatically:

```matlab
% build_dc_motor_model.m
% Programmatically constructs the electromechanical DC motor model in Simulink

model_name = 'dc_motor_blueprint';
if bdIsLoaded(model_name)
    close_system(model_name, 0);
end
new_system(model_name);
open_system(model_name);

% 1. Armature Circuit Blocks
add_block('simulink/Sources/Step', [model_name, '/Step_Vin'], ...
    'Time', '0.0', 'Before', '0', 'After', '24', 'Position', [50, 70, 90, 110]);

add_block('simulink/Math Operations/Sum', [model_name, '/Sum_Armature'], ...
    'Inputs', '+--', 'Position', [140, 75, 170, 125]);

add_block('simulink/Math Operations/Gain', [model_name, '/Gain_InvLa'], ...
    'Gain', '1 / 0.5', 'Position', [200, 85, 245, 115]);

add_block('simulink/Continuous/Integrator', [model_name, '/Integrator_ia'], ...
    'InitialCondition', '0.0', 'Position', [280, 85, 310, 115]);

add_block('simulink/Math Operations/Gain', [model_name, '/Gain_Ra'], ...
    'Gain', '2.0', 'Position', [230, 150, 270, 180]);

% 2. Mechanical Shaft Blocks
add_block('simulink/Math Operations/Gain', [model_name, '/Gain_Kt'], ...
    'Gain', '0.1', 'Position', [350, 85, 390, 115]);

add_block('simulink/Sources/Step', [model_name, '/Step_LoadTorque'], ...
    'Time', '3.0', 'Before', '0', 'After', '0.5', 'Position', [340, 170, 380, 210]);

add_block('simulink/Math Operations/Sum', [model_name, '/Sum_Shaft'], ...
    'Inputs', '+--', 'Position', [430, 85, 460, 135]);

add_block('simulink/Math Operations/Gain', [model_name, '/Gain_InvJ'], ...
    'Gain', '1 / 0.02', 'Position', [490, 95, 535, 125]);

add_block('simulink/Continuous/Integrator', [model_name, '/Integrator_omega'], ...
    'InitialCondition', '0.0', 'Position', [570, 95, 600, 125]);

add_block('simulink/Math Operations/Gain', [model_name, '/Gain_b'], ...
    'Gain', '0.01', 'Position', [520, 180, 560, 210]);

add_block('simulink/Math Operations/Gain', [model_name, '/Gain_Ke'], ...
    'Gain', '0.1', 'Position', [380, 260, 420, 290]);

% 3. Sinks
add_block('simulink/Sinks/Scope', [model_name, '/Scope_Motor'], ...
    'NumInputPorts', '2', 'Position', [670, 75, 710, 135]);

% 4. Wire Connections
add_line(model_name, 'Step_Vin/1', 'Sum_Armature/1');
add_line(model_name, 'Sum_Armature/1', 'Gain_InvLa/1');
add_line(model_name, 'Gain_InvLa/1', 'Integrator_ia/1');
add_line(model_name, 'Integrator_ia/1', 'Gain_Ra/1');
add_line(model_name, 'Gain_Ra/1', 'Sum_Armature/2');
add_line(model_name, 'Integrator_ia/1', 'Gain_Kt/1');
add_line(model_name, 'Gain_Kt/1', 'Sum_Shaft/1');
add_line(model_name, 'Step_LoadTorque/1', 'Sum_Shaft/2');
add_line(model_name, 'Sum_Shaft/1', 'Gain_InvJ/1');
add_line(model_name, 'Gain_InvJ/1', 'Integrator_omega/1');
add_line(model_name, 'Integrator_omega/1', 'Gain_b/1');
add_line(model_name, 'Gain_b/1', 'Sum_Shaft/3');
add_line(model_name, 'Integrator_omega/1', 'Gain_Ke/1');
add_line(model_name, 'Gain_Ke/1', 'Sum_Armature/3');
add_line(model_name, 'Integrator_ia/1', 'Scope_Motor/1');
add_line(model_name, 'Integrator_omega/1', 'Scope_Motor/2');

save_system(model_name);
fprintf('Electromechanical DC motor blueprint created: %s.slx\n', model_name);
```
