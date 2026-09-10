"""
================================================================================
E2E TEST SUITE: MATHEMATICAL & PHYSICAL INTEGRITY VERIFICATION
================================================================================
Numerical validation of core engineering algorithms and physical models:
1. Ohm's Law Nodal Solver (Linear systems, conductance matrix, KCL, power)
2. Structural Truss Balance (Static equilibrium, stiffness matrix, member forces)
3. Differential Equations: Euler vs RK4 vs ODE45 (Newton cooling, transient physics)
4. Probability & Noise Modeling (Distributions, statistical moments, MTBF)
5. Sensor Signal Filtering (Moving-average variance reduction, SNR improvement)
6. Capstone EV Powertrain Telemetry Math (Power, efficiency, energy quadrature)
================================================================================
"""

import numpy as np
import pytest
from scipy import linalg, integrate


# ==============================================================================
# 1. OHM'S LAW NODAL SOLVER (LINEAR SYSTEMS & CIRCUIT ANALYSIS)
# ==============================================================================

class TestCircuitNodalSolver:
    """Numerical verification of nodal conductance matrix equations G * V = I."""

    def test_bridge_circuit_nodal_admittance_solver(self):
        """
        Verify nodal analysis for a 4-node resistive bridge circuit.
        Node 0 is reference ground (V_0 = 0V).
        Nodes 1, 2, 3 have unknown node voltages V = [V1, V2, V3]^T.
        Independent current source of 5.0 A injected into Node 1.
        """
        # Circuit parameters (Conductances in Siemens = 1 / Ohms)
        # Resistors: R01 = 10, R12 = 5, R13 = 10, R23 = 20 (bridge), R20 = 15, R30 = 25
        g01 = 1.0 / 10.0
        g12 = 1.0 / 5.0
        g13 = 1.0 / 10.0
        g23 = 1.0 / 20.0
        g20 = 1.0 / 15.0
        g30 = 1.0 / 25.0

        # Construct symmetric nodal conductance matrix G
        # Node 1: (g01 + g12 + g13)*V1 - g12*V2 - g13*V3 = I_s
        # Node 2: -g12*V1 + (g12 + g23 + g20)*V2 - g23*V3 = 0
        # Node 3: -g13*V1 - g23*V2 + (g13 + g23 + g30)*V3 = 0
        G = np.array([
            [g01 + g12 + g13, -g12,           -g13],
            [-g12,            g12 + g23 + g20, -g23],
            [-g13,           -g23,            g13 + g23 + g30]
        ], dtype=float)

        I_sources = np.array([5.0, 0.0, 0.0], dtype=float)

        # 1. Verify G is symmetric positive-definite (physical realizability)
        eigvals = linalg.eigvalsh(G)
        assert np.all(eigvals > 0), "Conductance matrix must be strictly positive-definite"

        # 2. Check condition number (must be well-conditioned)
        cond_G = np.linalg.cond(G)
        assert cond_G < 50.0, f"Matrix is ill-conditioned: cond(G) = {cond_G}"

        # 3. Solve for node voltages V using Gaussian elimination / LU
        V = linalg.solve(G, I_sources)
        V1, V2, V3 = V[0], V[1], V[2]

        # 4. Verify nodal residual ||G*V - I|| < 1e-13
        residual = np.max(np.abs(G @ V - I_sources))
        assert residual < 1e-13, f"Nodal equation residual exceeds tolerance: {residual}"

        # 5. Verify Kirchhoff's Current Law (KCL) at each node
        # Node 1 currents:
        i01 = g01 * V1
        i12 = g12 * (V1 - V2)
        i13 = g13 * (V1 - V3)
        assert np.isclose(i01 + i12 + i13, 5.0, atol=1e-12), "KCL violated at Node 1"

        # Node 2 currents:
        i23 = g23 * (V2 - V3)
        i20 = g20 * V2
        assert np.isclose(i12, i23 + i20, atol=1e-12), "KCL violated at Node 2"

        # Node 3 currents:
        i30 = g30 * V3
        assert np.isclose(i13 + i23, i30, atol=1e-12), "KCL violated at Node 3"

        # 6. Conservation of Power (Tellegen's Theorem)
        P_supplied = I_sources[0] * V1
        P_dissipated = (
            g01 * (V1**2) +
            g12 * ((V1 - V2)**2) +
            g13 * ((V1 - V3)**2) +
            g23 * ((V2 - V3)**2) +
            g20 * (V2**2) +
            g30 * (V3**2)
        )
        assert np.isclose(P_supplied, P_dissipated, rtol=1e-12), \
            f"Power conservation violated: supplied {P_supplied} W vs dissipated {P_dissipated} W"


# ==============================================================================
# 2. STRUCTURAL TRUSS BALANCE (LINEAR EQUILIBRIUM)
# ==============================================================================

class TestTrussForceBalance:
    """Numerical verification of static equilibrium in a pin-jointed truss."""

    def test_triangular_truss_equilibrium(self):
        """
        Verify static force balance for a planar equilateral triangular truss.
        Joint 1: (0, 0), pinned (R1x, R1y)
        Joint 2: (L, 0), roller (R2y)
        Joint 3: (L/2, sqrt(3)/2 * L), apex with applied load P = -10,000 N downward.
        Members:
        - Member 1: Joint 1 -> Joint 2 (T1)
        - Member 2: Joint 1 -> Joint 3 (T2)
        - Member 3: Joint 2 -> Joint 3 (T3)
        """
        P = 10000.0  # Applied load magnitude (N)
        # Equilibrium Matrix A * x = b, where x = [T1, T2, T3, R1x, R1y, R2y]^T
        cos60 = 0.5
        sin60 = np.sqrt(3.0) / 2.0
        cos120 = -0.5
        sin120 = np.sqrt(3.0) / 2.0

        # Equilibrium equations [sum Fx = 0, sum Fy = 0 for Joint 1, Joint 2, Joint 3]
        A = np.array([
            # T1,    T2,     T3,     R1x, R1y, R2y
            [ 1.0,  cos60,   0.0,    1.0, 0.0, 0.0],  # Joint 1, Fx
            [ 0.0,  sin60,   0.0,    0.0, 1.0, 0.0],  # Joint 1, Fy
            [-1.0,   0.0,   cos120,  0.0, 0.0, 0.0],  # Joint 2, Fx
            [ 0.0,   0.0,   sin120,  0.0, 0.0, 1.0],  # Joint 2, Fy
            [ 0.0, -cos60, -cos120,  0.0, 0.0, 0.0],  # Joint 3, Fx
            [ 0.0, -sin60, -sin120,  0.0, 0.0, 0.0],  # Joint 3, Fy
        ], dtype=float)

        b = np.array([0.0, 0.0, 0.0, 0.0, 0.0, P], dtype=float)

        # 1. Determinant and rank
        rank = np.linalg.matrix_rank(A)
        assert rank == 6, f"Equilibrium matrix must be full rank, got {rank}"

        # 2. Solve for member forces and reactions
        x = linalg.solve(A, b)
        T1, T2, T3, R1x, R1y, R2y = x

        # 3. Analytical comparisons
        # By symmetry: T2 = T3 = -P / (2 * sin60) = -P / sqrt(3)
        expected_T2 = -P / np.sqrt(3.0)
        expected_T3 = -P / np.sqrt(3.0)
        # T1 = -T3 * cos120 = (P / sqrt(3)) * 0.5 = P / (2 * sqrt(3))
        expected_T1 = P / (2.0 * np.sqrt(3.0))

        assert np.isclose(T1, expected_T1, atol=1e-10), f"T1 force mismatch: {T1} vs {expected_T1}"
        assert np.isclose(T2, expected_T2, atol=1e-10), f"T2 force mismatch: {T2} vs {expected_T2}"
        assert np.isclose(T3, expected_T3, atol=1e-10), f"T3 force mismatch: {T3} vs {expected_T3}"
        assert T2 < 0 and T3 < 0, "Top chords must be in compression (negative tension)"
        assert T1 > 0, "Bottom chord must be in tension (positive)"

        # 4. Global equilibrium checks
        assert np.isclose(R1x, 0.0, atol=1e-10), "Net horizontal reaction must be 0"
        assert np.isclose(R1y + R2y, P, atol=1e-10), "Vertical reactions must support load P"
        assert np.isclose(R1y, R2y, atol=1e-10), "Reactions must be equal by symmetry"


# ==============================================================================
# 3. CALCULUS: EULER VS RK4 VS ODE45 (TRANSIENT THERMAL COOLING)
# ==============================================================================

class TestDifferentialEquationsPhysics:
    """Numerical verification of ODE solvers: Euler, RK4, and ODE45 (Dormand-Prince)."""

    @staticmethod
    def newton_cooling_ode(t: float, T: float, k: float, T_env: float) -> float:
        return -k * (T - T_env)

    @staticmethod
    def analytical_cooling(t: np.ndarray, T0: float, T_env: float, k: float) -> np.ndarray:
        return T_env + (T0 - T_env) * np.exp(-k * t)

    def test_euler_rk4_ode45_convergence(self):
        """
        Verify convergence order:
        - Euler global error is O(h)
        - RK4 global error is O(h^4)
        - Scipy solve_ivp('RK45') achieves high-precision benchmark
        """
        T0 = 95.0       # Initial temperature (deg C)
        T_env = 22.0    # Ambient temperature (deg C)
        k = 0.08        # Cooling coefficient (s^-1)
        t_final = 30.0  # Simulation duration (s)

        # 1. Forward Euler Implementation
        def run_euler(h: float) -> float:
            steps = int(t_final / h)
            t = 0.0
            T = T0
            for _ in range(steps):
                dTdt = -k * (T - T_env)
                T += h * dTdt
                t += h
            exact = self.analytical_cooling(np.array([t]), T0, T_env, k)[0]
            return abs(T - exact)

        # 2. Classical 4th-order Runge-Kutta Implementation
        def run_rk4(h: float) -> float:
            steps = int(t_final / h)
            t = 0.0
            T = T0
            for _ in range(steps):
                k1 = -k * (T - T_env)
                k2 = -k * ((T + 0.5 * h * k1) - T_env)
                k3 = -k * ((T + 0.5 * h * k2) - T_env)
                k4 = -k * ((T + h * k3) - T_env)
                T += (h / 6.0) * (k1 + 2.0 * k2 + 2.0 * k3 + k4)
                t += h
            exact = self.analytical_cooling(np.array([t]), T0, T_env, k)[0]
            return abs(T - exact)

        # Test convergence rates with step sizes h1 = 1.0, h2 = 0.5
        h1, h2 = 1.0, 0.5
        euler_err1 = run_euler(h1)
        euler_err2 = run_euler(h2)
        euler_order = np.log2(euler_err1 / euler_err2)
        assert 0.8 < euler_order < 1.2, f"Euler should be ~1st order, observed order {euler_order:.2f}"

        rk4_err1 = run_rk4(h1)
        rk4_err2 = run_rk4(h2)
        rk4_order = np.log2(rk4_err1 / rk4_err2)
        assert 3.8 < rk4_order < 4.2, f"RK4 should be ~4th order, observed order {rk4_order:.2f}"
        assert rk4_err2 < 1e-6, f"RK4 at h=0.5 should have error < 1e-6, got {rk4_err2}"

        # 3. ODE45 (solve_ivp method='RK45') verification
        sol = integrate.solve_ivp(
            fun=lambda t, T: -k * (T - T_env),
            t_span=(0.0, t_final),
            y0=[T0],
            method='RK45',
            rtol=1e-7,
            atol=1e-9
        )
        exact_curve = self.analytical_cooling(sol.t, T0, T_env, k)
        max_ode45_err = np.max(np.abs(sol.y[0] - exact_curve))
        assert max_ode45_err < 1e-5, f"ODE45 maximum error exceeded: {max_ode45_err}"

    def test_numerical_accumulation_quadrature(self):
        """
        Verify numerical integration (trapz) matches analytical accumulation.
        Heat dissipated: Q(t) = integral_0^T h_c * (T(t) - T_env) dt
        """
        T0 = 90.0
        T_env = 20.0
        k = 0.1
        t_vec = np.linspace(0.0, 20.0, 201)  # dt = 0.1
        delta_T = (T0 - T_env) * np.exp(-k * t_vec)

        # Numerical integration using trapezoidal rule
        q_num = integrate.trapezoid(delta_T, t_vec)

        # Analytical integral: integral_0^20 (T0 - T_env)*e^(-k*t) dt = (T0 - T_env)/k * (1 - e^(-20*k))
        q_exact = ((T0 - T_env) / k) * (1.0 - np.exp(-k * 20.0))

        rel_error = abs(q_num - q_exact) / q_exact
        assert rel_error < 1e-4, f"Trapezoidal accumulation relative error too high: {rel_error}"


# ==============================================================================
# 4. PROBABILITY & UNCERTAINTY IN ENGINEERING
# ==============================================================================

class TestProbabilityMomentsAndNoise:
    """Numerical validation of Gaussian distributions, sample moments, and reliability."""

    def test_gaussian_statistical_moments(self):
        """
        Verify that Monte Carlo generated Gaussian samples satisfy:
        - Mean E[X] = mu within Central Limit Theorem bounds
        - Variance Var[X] = sigma^2
        - Skewness = 0
        - Excess kurtosis = 0
        - 68-95-99.7 empirical rule
        """
        rng = np.random.default_rng(seed=42)
        mu = 50.0
        sigma = 3.0
        N = 250_000

        samples = rng.normal(loc=mu, scale=sigma, size=N)

        # 1. Sample mean and variance
        sample_mean = np.mean(samples)
        sample_var = np.var(samples, ddof=1)
        sample_std = np.std(samples, ddof=1)

        # CLT 99.7% confidence bound for mean: 3 * sigma / sqrt(N)
        mean_bound = 3.0 * sigma / np.sqrt(N)
        assert abs(sample_mean - mu) < mean_bound, f"Sample mean {sample_mean} drifted beyond 3-sigma CLT bound {mean_bound}"

        # Variance confidence bound
        var_bound = 3.0 * (sigma**2) * np.sqrt(2.0 / N)
        assert abs(sample_var - sigma**2) < var_bound, f"Sample variance {sample_var} drifted beyond bound"

        # 2. Higher order moments: skewness and kurtosis
        central_moments = samples - sample_mean
        skewness = np.mean(central_moments**3) / (sample_std**3)
        excess_kurtosis = (np.mean(central_moments**4) / (sample_std**4)) - 3.0

        assert abs(skewness) < 0.02, f"Excess skewness: {skewness}"
        assert abs(excess_kurtosis) < 0.03, f"Excess kurtosis: {excess_kurtosis}"

        # 3. Empirical 68-95-99.7% rule
        p_1sigma = np.mean(np.abs(samples - mu) <= 1.0 * sigma)
        p_2sigma = np.mean(np.abs(samples - mu) <= 2.0 * sigma)
        p_3sigma = np.mean(np.abs(samples - mu) <= 3.0 * sigma)

        assert np.isclose(p_1sigma, 0.6827, atol=0.005), f"1-sigma probability {p_1sigma} deviates from 0.6827"
        assert np.isclose(p_2sigma, 0.9545, atol=0.003), f"2-sigma probability {p_2sigma} deviates from 0.9545"
        assert np.isclose(p_3sigma, 0.9973, atol=0.001), f"3-sigma probability {p_3sigma} deviates from 0.9973"

    def test_exponential_reliability_and_mtbf(self):
        """
        Verify component reliability modeling with exponential distribution:
        R(t) = exp(-lambda * t), MTBF = 1 / lambda.
        """
        rng = np.random.default_rng(seed=123)
        mtbf = 4000.0  # hours
        lambd = 1.0 / mtbf
        N = 50_000

        # Generate component time-to-failure via inverse CDF: T = -ln(U) / lambda
        u = rng.uniform(0.0, 1.0, size=N)
        failure_times = -np.log(u) / lambd

        # Sample mean MTBF
        sample_mtbf = np.mean(failure_times)
        assert np.isclose(sample_mtbf, mtbf, rtol=0.02), f"Simulated MTBF {sample_mtbf} deviates from {mtbf}"

        # Check reliability at t = MTBF: R(MTBF) = exp(-1) = 0.367879
        empirical_r_at_mtbf = np.mean(failure_times > mtbf)
        expected_r = np.exp(-1.0)
        assert np.isclose(empirical_r_at_mtbf, expected_r, atol=0.01), f"Reliability at MTBF deviated: {empirical_r_at_mtbf}"


# ==============================================================================
# 5. SENSOR NOISE FILTERING & MOVING AVERAGE
# ==============================================================================

class TestSensorSignalFiltering:
    """Numerical verification of sensor signal noise reduction and moving average filter."""

    def test_moving_average_variance_reduction(self):
        """
        Verify that a moving average filter of window size W reduces Gaussian noise variance by exactly 1/W:
        Var(y_noise) = sigma^2 / W.
        """
        rng = np.random.default_rng(seed=999)
        W = 16  # Window size
        sigma_noise = 2.0
        N = 50_000

        # Generate zero-mean Gaussian noise
        noise = rng.normal(loc=0.0, scale=sigma_noise, size=N)

        # Apply moving average filter via convolution
        kernel = np.ones(W) / W
        filtered_noise = np.convolve(noise, kernel, mode='valid')

        # Theoretical output variance
        expected_var = (sigma_noise**2) / W
        actual_var = np.var(filtered_noise, ddof=1)

        assert np.isclose(actual_var, expected_var, rtol=0.05), \
            f"Filtered noise variance {actual_var} did not match expected sigma^2/W ({expected_var})"

    def test_moving_average_snr_improvement(self):
        """
        Verify moving average filtering improves SNR on a sinusoidal sensor telemetry signal.
        """
        rng = np.random.default_rng(seed=777)
        fs = 100.0  # 100 Hz sampling rate
        t = np.linspace(0.0, 10.0, int(10.0 * fs), endpoint=False)
        clean_signal = 10.0 * np.sin(2.0 * np.pi * 1.5 * t)  # 1.5 Hz sine wave

        # Add sensor noise
        noise = rng.normal(loc=0.0, scale=2.5, size=len(t))
        noisy_signal = clean_signal + noise

        # Filter with W = 9
        W = 9
        kernel = np.ones(W) / W
        # Use mode='same' or account for delay
        filtered_signal = np.convolve(noisy_signal, kernel, mode='same')

        # Trim boundary edge effects for interior RMSE
        pad = W
        raw_rmse = np.sqrt(np.mean((noisy_signal[pad:-pad] - clean_signal[pad:-pad])**2))
        filtered_rmse = np.sqrt(np.mean((filtered_signal[pad:-pad] - clean_signal[pad:-pad])**2))

        assert filtered_rmse < 0.5 * raw_rmse, \
            f"Filtering did not significantly reduce RMSE: raw={raw_rmse}, filtered={filtered_rmse}"


# ==============================================================================
# 6. CAPSTONE EV POWERTRAIN TELEMETRY EQUATIONS
# ==============================================================================

class TestCapstoneTelemetryMath:
    """Numerical validation of multi-disciplinary EV Powertrain telemetry equations."""

    def test_ev_powertrain_governing_equations(self):
        """
        Verify:
        1. Mechanical power: P_mech = torque * rpm * (2*pi / 60)
        2. Electrical power: P_elec = V * I
        3. Powertrain efficiency: eta = P_mech / P_elec
        4. Energy consumed: E = integral P_elec dt via trapz
        5. Thermal rate of change: dT/dt via diff
        """
        # Telemetry sample point
        rpm = 3600.0        # motor speed
        torque = 180.0      # motor torque (Nm)
        voltage = 380.0     # battery voltage (V)
        current = 190.0     # battery current (A)

        # 1. Mechanical power calculation
        omega_rad_s = rpm * (2.0 * np.pi / 60.0)
        P_mech = torque * omega_rad_s
        # P_mech = 180 * (3600 * 2 * pi / 60) = 180 * 120 * pi = 21600 * pi ~ 67,858.4 W
        expected_P_mech = 21600.0 * np.pi
        assert np.isclose(P_mech, expected_P_mech, rtol=1e-12)

        # 2. Electrical power calculation
        P_elec = voltage * current
        # P_elec = 380 * 190 = 72,200 W
        assert np.isclose(P_elec, 72200.0, rtol=1e-12)

        # 3. Efficiency calculation
        eta = P_mech / P_elec
        # eta = 67858.4 / 72200 ~ 93.987%
        assert 0.90 < eta < 0.96, f"EV powertrain efficiency outside realistic physical bounds: {eta:.2%}"

        # 4. Numerical trapezoidal energy integration over a drive cycle
        t_cycle = np.linspace(0.0, 60.0, 601)  # 60 s cycle
        # Constant electrical power 72.2 kW
        P_vec = np.full_like(t_cycle, P_elec)
        total_energy_joules = integrate.trapezoid(P_vec, t_cycle)
        expected_energy_joules = 72200.0 * 60.0  # 4,332,000 J
        assert np.isclose(total_energy_joules, expected_energy_joules, rtol=1e-12)

        energy_kwh = total_energy_joules / (3600.0 * 1000.0)
        assert np.isclose(energy_kwh, 1.203333333, rtol=1e-6)

        # 5. Temperature rate of change (thermal finite difference)
        temp_series = 25.0 + 0.15 * t_cycle + 2.0 * np.sin(0.05 * t_cycle)
        dt = t_cycle[1] - t_cycle[0]
        dT_dt = np.diff(temp_series) / dt

        # Analytical derivative: 0.15 + 2.0 * 0.05 * cos(0.05 * t) = 0.15 + 0.1 * cos(0.05 * t)
        mid_t = 0.5 * (t_cycle[:-1] + t_cycle[1:])
        analytical_dT_dt = 0.15 + 0.10 * np.cos(0.05 * mid_t)
        max_diff_err = np.max(np.abs(dT_dt - analytical_dT_dt))
        assert max_diff_err < 1e-4, f"Finite difference temperature derivative error too high: {max_diff_err}"
