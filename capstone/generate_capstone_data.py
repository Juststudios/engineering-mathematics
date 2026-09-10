#!/usr/bin/env python3
"""
================================================================================
EV POWERTRAIN TELEMETRY DATA GENERATOR
================================================================================
Simulates realistic, multi-physics high-frequency telemetry for an electric
vehicle powertrain over a 60-second dynamic drive cycle.

Governing Physics:
- Drive cycle kinematics: Acceleration, cruise, passing sprint, regenerative braking, stop.
- Electromechanical conversion: P_mech = torque * omega [W]
- Battery electrical model: Terminal voltage drop V_term = V_oc - I * R_int
- Inverter/Motor efficiency: P_elec = P_mech / eta + P_aux (motoring)
                             P_elec = P_mech * eta_regen + P_aux (regeneration)
- Inverter thermal dynamics: dT_inv/dt = P_loss / C_th - (T_inv - T_amb) / R_th
- Sensor noise: Additive Gaussian sensor noise modeling transducer EMI.

Output:
Writes clean CSV dataset with 601 rows to 'data/ev_telemetry.csv'.
================================================================================
"""

import os
from pathlib import Path
import numpy as np


def generate_ev_telemetry(output_csv: Path, seed: int = 42) -> Path:
    """
    Generates realistic EV powertrain telemetry and saves it to a CSV file.

    Parameters
    ----------
    output_csv : Path
        Target path where the CSV dataset will be saved.
    seed : int
        Pseudorandom seed for deterministic sensor noise generation.

    Returns
    -------
    Path
        Absolute path to the saved CSV file.
    """
    rng = np.random.default_rng(seed)

    # Time base: 60 seconds at 10 Hz (0.1 s step) -> 601 sample points
    fs = 10.0
    t_end = 60.0
    dt = 1.0 / fs
    t = np.arange(0.0, t_end + dt / 2.0, dt)
    n_samples = len(t)

    # Preallocate base physical arrays
    speed_rpm = np.zeros(n_samples, dtype=float)
    torque_nm = np.zeros(n_samples, dtype=float)

    # Drive cycle profiles across 5 distinct operational regimes:
    # 1. Launch & Acceleration (0 <= t < 15 s)
    # 2. Highway Cruise (15 <= t < 35 s)
    # 3. Passing Sprint (35 <= t < 45 s)
    # 4. Regenerative Braking (45 <= t < 55 s)
    # 5. Deceleration & Standstill (55 <= t <= 60 s)
    for i, ti in enumerate(t):
        if ti < 15.0:
            # Smooth S-curve acceleration 0 -> 3800 RPM
            progress = ti / 15.0
            s_curve = 3.0 * (progress ** 2) - 2.0 * (progress ** 3)
            speed_rpm[i] = 3800.0 * s_curve
            # Peak launch torque decaying slightly as back-EMF rises
            torque_nm[i] = 210.0 - 40.0 * progress
        elif ti < 35.0:
            # Steady cruising around 3800 RPM with gentle road grade variation
            speed_rpm[i] = 3800.0 + 35.0 * np.sin(2.0 * np.pi * 0.1 * (ti - 15.0))
            # Road load torque: rolling resistance + aerodynamic drag ~ 70 Nm
            torque_nm[i] = 72.0 + 8.0 * np.cos(2.0 * np.pi * 0.15 * (ti - 15.0))
        elif ti < 45.0:
            # Hard passing sprint 3800 -> 5050 RPM
            progress = (ti - 35.0) / 10.0
            s_curve = 3.0 * (progress ** 2) - 2.0 * (progress ** 3)
            speed_rpm[i] = 3800.0 + (5050.0 - 3800.0) * s_curve
            # High acceleration torque
            torque_nm[i] = 245.0 - 25.0 * progress
        elif ti < 55.0:
            # Regenerative braking: rapid deceleration 5050 -> 1200 RPM
            progress = (ti - 45.0) / 10.0
            s_curve = 3.0 * (progress ** 2) - 2.0 * (progress ** 3)
            speed_rpm[i] = 5050.0 - (5050.0 - 1200.0) * s_curve
            # Negative torque (motor acts as generator)
            torque_nm[i] = -115.0 + 30.0 * progress
        else:
            # Final friction braking to full stop 1200 -> 0 RPM
            progress = (ti - 55.0) / 5.0
            speed_rpm[i] = max(0.0, 1200.0 * (1.0 - progress))
            torque_nm[i] = 0.0

    # Angular velocity in rad/s
    omega_rad_s = speed_rpm * (2.0 * np.pi / 60.0)

    # Mechanical shaft power: P_mech = torque * omega (Watts)
    p_mech = torque_nm * omega_rad_s

    # Electrical and powertrain efficiency parameters
    eta_motoring = 0.935     # 93.5% motor + inverter efficiency
    eta_regen = 0.885        # 88.5% recovery efficiency
    p_aux = 350.0            # 350 W auxiliary systems (pumps, fans, ECU)

    p_elec = np.zeros(n_samples, dtype=float)
    for i in range(n_samples):
        if p_mech[i] >= 0.0:
            p_elec[i] = (p_mech[i] / eta_motoring) + p_aux
        else:
            p_elec[i] = (p_mech[i] * eta_regen) + p_aux

    # High-Voltage Battery Pack Equivalent Circuit Model
    # V_terminal = V_oc - I_pack * R_internal
    # P_elec = V_terminal * I_pack = V_oc * I_pack - R_internal * I_pack^2
    # Quadratic solve for I_pack: R_int * I^2 - V_oc * I + P_elec = 0
    v_oc = 398.0             # Open circuit voltage (Volts)
    r_int = 0.048            # Internal resistance (Ohms)

    battery_current_a = np.zeros(n_samples, dtype=float)
    battery_voltage_v = np.zeros(n_samples, dtype=float)

    for i in range(n_samples):
        disc = (v_oc ** 2) - 4.0 * r_int * p_elec[i]
        if disc < 0:
            disc = 0.0
        i_pack = (v_oc - np.sqrt(disc)) / (2.0 * r_int)
        v_pack = v_oc - i_pack * r_int
        battery_current_a[i] = i_pack
        battery_voltage_v[i] = v_pack

    # Thermal Model (Inverter Heatsink Dynamics)
    # dT_inv/dt = P_loss / C_th - (T_inv - T_amb) / R_th
    c_th = 1600.0            # Thermal capacitance [J / Kelvin]
    r_th = 0.78              # Thermal resistance to ambient [Kelvin / Watt]

    t_amb = 22.0 + 0.4 * np.sin(2.0 * np.pi * t / 120.0)
    inverter_temp_c = np.zeros(n_samples, dtype=float)
    t_inv_current = 35.0     # Initial inverter temperature 35 deg C

    p_loss = np.abs(p_elec - p_mech)

    for i in range(n_samples):
        inverter_temp_c[i] = t_inv_current
        d_temp_dt = (p_loss[i] / c_th) - ((t_inv_current - t_amb[i]) / r_th)
        t_inv_current += d_temp_dt * dt

    # Add realistic sensor measurement noise (EMI, quantization, thermal noise)
    noise_speed = rng.normal(loc=0.0, scale=4.5, size=n_samples)
    noise_torque = rng.normal(loc=0.0, scale=0.55, size=n_samples)
    noise_voltage = rng.normal(loc=0.0, scale=0.12, size=n_samples)
    noise_current = rng.normal(loc=0.0, scale=0.35, size=n_samples)
    noise_t_inv = rng.normal(loc=0.0, scale=0.08, size=n_samples)
    noise_t_amb = rng.normal(loc=0.0, scale=0.04, size=n_samples)

    meas_speed = np.maximum(0.0, speed_rpm + noise_speed)
    meas_torque = torque_nm + noise_torque
    meas_voltage = battery_voltage_v + noise_voltage
    meas_current = battery_current_a + noise_current
    meas_t_inv = inverter_temp_c + noise_t_inv
    meas_t_amb = t_amb + noise_t_amb

    # Format and save CSV
    output_csv.parent.mkdir(parents=True, exist_ok=True)
    with open(output_csv, "w", encoding="utf-8") as f:
        f.write("timestamp_s,motor_speed_rpm,motor_torque_nm,battery_voltage_v,battery_current_a,inverter_temp_c,ambient_temp_c\n")
        for i in range(n_samples):
            f.write(
                f"{t[i]:.2f},"
                f"{meas_speed[i]:.2f},"
                f"{meas_torque[i]:.2f},"
                f"{meas_voltage[i]:.2f},"
                f"{meas_current[i]:.2f},"
                f"{meas_t_inv[i]:.2f},"
                f"{meas_t_amb[i]:.2f}\n"
            )

    print(f"[+] Successfully generated EV telemetry dataset with {n_samples} rows -> {output_csv}")
    return output_csv


if __name__ == "__main__":
    script_dir = Path(__file__).resolve().parent
    repo_root = script_dir.parent
    target_csv = repo_root / "data" / "ev_telemetry.csv"
    generate_ev_telemetry(target_csv, seed=42)
