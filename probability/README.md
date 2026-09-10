# Probability & Uncertainty in Engineering: Modeling Noise, Variation & Reliability

Welcome to the **Probability & Uncertainty in Engineering** module of the Engineering Mathematics curriculum. In Level 1, you learned how to manipulate deterministic arrays, compute statistical summaries with Pandas/NumPy, and visualize data. In physical engineering, however, no measurement is perfectly deterministic, no manufacturing process is flawless, and no component lasts forever.

Electrical sensors pick up electromagnetic interference and thermal Johnson-Nyquist noise; machined titanium brackets deviate by micrometers from their CAD nominal dimensions; and aerospace pumps degrade over operating hours according to stochastic failure distributions. Engineers do not run from uncertainty—we quantify it, design safety margins around it, filter it out of telemetry streams, and calculate mission failure probabilities down to parts-per-million.

This module provides the computational and statistical foundations needed to model physical randomness in MATLAB: transforming continuous probability density functions into discrete sample distributions, applying Bayes' rule to diagnostic sensor networks, suppressing telemetry noise with digital filters, and simulating complex reliability topologies via Monte Carlo methods.

---

## 1. Learning Objectives

By completing this module, you will be able to:

1. **Calculate** probabilities, expectation (mean), variance, and standard deviation for discrete and continuous engineering random variables.
2. **Apply** Bayes' theorem to solve industrial sensor diagnostic problems, avoiding the common base-rate fallacy in automated fault detection.
3. **Model** manufacturing variability and tolerance stack-up using Uniform, Binomial, and Gaussian (Normal) distributions with the 68-95-99.7 empirical rule.
4. **Implement** Monte Carlo simulations in MATLAB to numerically estimate multidimensional integrals, system clearance failure rates, and non-linear risk metrics.
5. **Formulate** and **synthesize** digital moving-average filters to suppress Gaussian white noise from sensor telemetry streams, quantifying Signal-to-Noise Ratio (SNR) improvements.
6. **Evaluate** system reliability, Mean Time Between Failures (MTBF), and survival curves for redundant (series, parallel, and $k$-out-of-$n$) engineering architectures under exponential failure kinetics.
7. **Diagnose** and **debug** statistical computation errors in MATLAB, including biased variance estimators ($N$ vs $N-1$) and confusing uniform `rand` with Gaussian `randn`.

---

## 2. Why Engineers Need This

In professional engineering practice, deterministic equations ($F = ma$, $V = IR$) describe ideal nominal models. Real-world engineering requires designing systems that operate safely despite environmental noise, manufacturing imperfections, and physical wear:

- **Aerospace & Autonomous Vehicles:** Inertial Measurement Units (IMUs), GPS receivers, and LiDAR sensors produce continuous streams of noisy telemetry. Autopilots and state estimators (such as Kalman filters) continuously blend probabilistic sensor readings with kinematic models to predict vehicle trajectory.
- **Manufacturing & Quality Engineering:** Six Sigma methodology governs semiconductor fabrication and automotive machining. Resistors stamped $100\,\Omega \pm 5\%$ or turbine blade roots machined to $25.00 \pm 0.02\text{ mm}$ follow statistical distributions. Engineers determine whether a production line will produce 1 defective part in 1,000 or 1 in 1,000,000.
- **Structural & Civil Engineering:** Extreme loads from wind gusts, seismic accelerations, and ocean wave heights are random processes. Rather than designing for an impossible "zero failure" condition, bridges, offshore rigs, and buildings are designed to probabilistic 100-year storm thresholds.
- **Systems & Reliability Engineering:** Safety-critical systems (such as commercial fly-by-wire flight control or nuclear reactor cooling pumps) employ active and standby redundancy. Calculating whether a quad-redundant hydraulic actuator meets the FAA safety threshold of less than $10^{-9}$ catastrophic failures per flight hour requires rigorous probability modeling.
- **Machine Learning & Signal Processing (Level 3 Bridge):** Machine learning models are probabilistic estimators. Classifiers output class posteriors $P(Y|X)$ via Bayes' rule; neural network loss functions (cross-entropy, mean squared error) derive from maximum likelihood estimation under Gaussian or Bernoulli noise assumptions.

---

## 3. Mathematical Intuition

### Physical Variability: The Dartboard and the Sensor
Imagine clamping a precision temperature sensor inside a thermal chamber held at exactly $25.00^\circ\text{C}$. The digital display does not output a constant $25.000000^\circ\text{C}$; instead, it fluctuates: $25.04$, $24.97$, $25.01$, $25.08$, $24.95$. 
- The true underlying state is constant ($\mu = 25.00$).
- Microscopic thermal vibrations in the sensor resistors (Johnson-Nyquist noise) superimpose zero-mean Gaussian fluctuations ($\epsilon \sim \mathcal{N}(0, \sigma^2)$).
- A single measurement tells you what the sensor *saw*, not what the true value *is*. To find the truth, we collect an ensemble of samples and estimate the underlying distribution parameters ($\mu, \sigma$).

### The Law of Large Numbers: Why Averages Work
If you flip a fair coin 4 times, getting 3 heads ($75\%$) is not surprising. If you flip it 10,000 times, getting $7,500$ heads is practically impossible ($p < 10^{-100}$). 
- **The Law of Large Numbers (LLN)** guarantees that as the sample size $N \to \infty$, the sample mean $\bar{X}_N = \frac{1}{N}\sum_{i=1}^N X_i$ converges deterministically to the true theoretical expectation $\mathbb{E}[X]$.
- The standard error of this estimate shrinks at the rate $\sigma / \sqrt{N}$. To double our precision (cut uncertainty in half), we must quadruple our simulation sample count or sensor averaging window.

```
Individual Samples: Highly Variable, Unpredictable
[x1, x2, x3, x4, ..., xN]  ──> Each sample has variance σ^2
                  │
                  ▼
Averaging Filter: 1/N * Σ x_i
                  │
                  ▼
Sample Mean Estimate: Variance shrinks to σ^2 / N
```

### Signal-to-Noise Ratio (SNR): Finding Whispers in a Storm
Telemetry consists of two components: the physical signal of interest $s(t)$ and the contaminating noise $w(t)$:
$$x(t) = s(t) + w(t)$$
- If the noise power is much smaller than the signal power ($\text{SNR} \gg 1$), peak detection and thresholding work effortlessly.
- If the noise power equals or exceeds signal power ($\text{SNR} \le 1$), the raw signal is completely masked.
- Because uncorrelated noise tends to have zero mean, averaging adjacent samples across time cancels out random positive and negative spikes while preserving the slowly varying physical signal.

---

## 4. Formal Mathematics & Governing Equations

### 4.1 Sample Spaces, Random Variables & Axioms
A **sample space** $\Omega$ is the set of all possible physical outcomes of a random experiment. An **event** $A \subseteq \Omega$ is a subset of outcomes. Kolmogorov's axioms state:
1. $P(A) \ge 0$ for all $A$.
2. $P(\Omega) = 1$.
3. For mutually exclusive events $A_1, A_2, \dots$ ($A_i \cap A_j = \emptyset$ for $i \ne j$):
   $$P\left(\bigcup_{i=1}^\infty A_i\right) = \sum_{i=1}^\infty P(A_i)$$

A **random variable** $X$ is a function mapping outcomes in $\Omega$ to real numbers $\mathbb{R}$.

### 4.2 Probability Density Functions (PDF) & Cumulative Distribution Functions (CDF)
- **Continuous Random Variables:** The probability of $X$ lying in $[a, b]$ is the integral of its PDF $f_X(x)$:
  $$P(a \le X \le b) = \int_a^b f_X(x) \, dx, \quad \int_{-\infty}^\infty f_X(x) \, dx = 1$$
- **CDF:** The probability that $X$ takes a value less than or equal to $x$:
  $$F_X(x) = P(X \le x) = \int_{-\infty}^x f_X(u) \, du, \quad f_X(x) = \frac{dF_X(x)}{dx}$$

### 4.3 Statistical Moments: Expectation & Variance
- **First Moment (Expectation / Mean):** The balance point of the probability mass:
  $$\mathbb{E}[X] = \mu = \int_{-\infty}^\infty x f_X(x) \, dx \quad (\text{continuous}), \quad \mathbb{E}[X] = \sum_i x_i P(X = x_i) \quad (\text{discrete})$$
- **Second Central Moment (Variance):** The measure of dispersion about the mean:
  $$\text{Var}(X) = \sigma^2 = \mathbb{E}\left[(X - \mu)^2\right] = \mathbb{E}[X^2] - (\mathbb{E}[X])^2$$
- **Standard Deviation:** $\sigma = \sqrt{\text{Var}(X)}$ (shares the physical units of $X$).
- **Sample Statistics (Bessel's Correction):** Given $N$ discrete measurements $x_1, \dots, x_N$:
  $$\bar{x} = \frac{1}{N} \sum_{i=1}^N x_i, \quad s^2 = \frac{1}{N-1} \sum_{i=1}^N (x_i - \bar{x})^2$$
  *The $N-1$ divisor provides an unbiased estimator of population variance.*

### 4.4 Canonical Engineering Distributions
1. **Continuous Uniform Distribution $\mathcal{U}(a, b)$:** Models uncalibrated sensors or quantization round-off error:
   $$f(x) = \frac{1}{b - a}, \quad a \le x \le b; \quad \mu = \frac{a+b}{2}, \quad \sigma^2 = \frac{(b-a)^2}{12}$$
2. **Normal (Gaussian) Distribution $\mathcal{N}(\mu, \sigma^2)$:** The universal model for measurement noise and additive manufacturing tolerances (by the Central Limit Theorem):
   $$f(x) = \frac{1}{\sigma \sqrt{2\pi}} \exp\left(-\frac{(x - \mu)^2}{2\sigma^2}\right)$$
   Standardized variable: $Z = \frac{X - \mu}{\sigma} \sim \mathcal{N}(0, 1)$.
   **The 68-95-99.7 Empirical Rule:**
   - $P(\mu - 1\sigma \le X \le \mu + 1\sigma) \approx 68.27\%$
   - $P(\mu - 2\sigma \le X \le \mu + 2\sigma) \approx 95.45\%$
   - $P(\mu - 3\sigma \le X \le \mu + 3\sigma) \approx 99.73\%$
3. **Exponential Distribution $\text{Exp}(\lambda)$:** Models time between independent random failures with constant hazard rate $\lambda$:
   $$f(t) = \lambda e^{-\lambda t}, \quad F(t) = 1 - e^{-\lambda t}, \quad t \ge 0; \quad \mathbb{E}[T] = \text{MTBF} = \frac{1}{\lambda}$$
   **Reliability Function (Survival Probability):**
   $$R(t) = P(T > t) = 1 - F(t) = e^{-\lambda t}$$

### 4.5 Conditional Probability & Bayes' Theorem
Given two events $A$ and $B$ with $P(B) > 0$, the conditional probability of $A$ given $B$ is:
$$P(A|B) = \frac{P(A \cap B)}{P(B)}$$
By the Law of Total Probability, if $A_1, \dots, A_k$ partition the sample space:
$$P(B) = \sum_{j=1}^k P(B|A_j) P(A_j)$$
Substituting into conditional probability yields **Bayes' Theorem**:
$$P(A_i|B) = \frac{P(B|A_i) P(A_i)}{\sum_{j=1}^k P(B|A_j) P(A_j)} = \frac{\text{Likelihood} \times \text{Prior}}{\text{Evidence}}$$

---

## 5. Worked Engineering Example: Diagnostic Sensor False-Alarm Rate

### Problem Statement
An industrial gas pipeline uses an ultrasonic sensor to monitor for dangerous micro-cracks in valve housings. From historical inspection records across thousands of installations:
- The base prior probability that any given valve has a micro-crack at any inspection is $P(\text{Crack}) = 0.005$ ($0.5\%$).
- If a crack is physically present, the ultrasonic diagnostic sensor correctly triggers an alarm with sensitivity (True Positive Rate) $P(\text{Alarm} | \text{Crack}) = 0.98$ ($98\%$).
- If no crack is present, electrical noise causes a false alarm with probability (False Positive Rate) $P(\text{Alarm} | \text{NoCrack}) = 0.02$ ($2.0\%$).

A remote pipeline telemetry monitor suddenly triggers an alarm on Valve #42.
1. Formulate Bayes' rule to compute the posterior probability that Valve #42 physically has a crack: $P(\text{Crack} | \text{Alarm})$.
2. Compute the probability that the alarm is a false alarm: $P(\text{NoCrack} | \text{Alarm})$.
3. Explain the engineering interpretation: Why is an alarm from a $98\%$ accurate sensor more likely to be false than true?

---

### Step-by-Step Analytical Calculation

#### Step 1: Define Events and Known Probabilities
- Event $C$: Micro-crack is physically present.
- Event $C^c$: Micro-crack is absent (healthy valve).
- Event $A$: Diagnostic sensor triggers an alarm.

Known priors and likelihoods:
- $P(C) = 0.005$
- $P(C^c) = 1 - P(C) = 0.995$
- $P(A|C) = 0.98$ (True Positive Rate)
- $P(A|C^c) = 0.02$ (False Positive Rate)

#### Step 2: Compute Total Probability of an Alarm $P(A)$
Using the Law of Total Probability:
$$P(A) = P(A|C) P(C) + P(A|C^c) P(C^c)$$
$$P(A) = (0.98 \times 0.005) + (0.02 \times 0.995)$$
$$P(A) = 0.00490 + 0.01990 = 0.02480 \quad (2.48\%)$$

Notice that $0.01990$ (alarms caused by healthy valves) is more than four times larger than $0.00490$ (alarms caused by genuine cracks)!

#### Step 3: Compute Posterior Probability $P(C|A)$ via Bayes' Theorem
$$P(C|A) = \frac{P(A|C) P(C)}{P(A)} = \frac{0.00490}{0.02480} = \frac{49}{248} \approx 0.19758 \quad (19.76\%)$$

#### Step 4: False-Alarm Rate
$$P(C^c|A) = 1 - P(C|A) = 1 - 0.19758 \approx 0.80242 \quad (80.24\%)$$

#### Engineering Decision
Even though the sensor has $98\%$ sensitivity and only $2\%$ false-positive rate, when an alarm sounds, there is only a **$19.76\%$ chance** of an actual crack! Over **$80\%$ of sounding alarms are false alarms**.

This phenomenon is the famous **Base-Rate Fallacy**. Because micro-cracks are extremely rare ($0.5\%$), the vast pool of healthy valves ($99.5\%$) generates far more false alarms in absolute numbers than the tiny pool of cracked valves generates true alarms. In an autonomous safety system, an automated emergency shutdown based on a single alarm would cause costly, unnecessary plant downtime. Instead, engineers program a two-stage verification protocol (e.g., secondary sensor confirmation or persistence filtering over multiple sample cycles) before initiating an emergency scram.

---

## 6. MATLAB Implementation

The following self-contained script reproduces the analytical Bayes calculation, verifies it via a Monte Carlo simulation of $1{,}000{,}000$ virtual valve inspections, and prints the verified metrics.

```matlab
% bayes_diagnostic_verification.m
% Verification of sensor diagnostic false-alarm rate via Bayes and Monte Carlo

clear; clc;

% 1. Governing Probabilities
P_crack       = 0.005;   % Prior probability P(Crack) = 0.5%
P_alarm_crack = 0.980;   % Sensitivity P(Alarm | Crack) = 98%
P_alarm_safe  = 0.020;   % False positive rate P(Alarm | Safe) = 2%

% 2. Analytical Bayes' Theorem Formulation
P_safe = 1.0 - P_crack;
P_alarm_total = P_alarm_crack * P_crack + P_alarm_safe * P_safe;
P_crack_given_alarm = (P_alarm_crack * P_crack) / P_alarm_total;
P_safe_given_alarm  = 1.0 - P_crack_given_alarm;

% 3. Large-Scale Monte Carlo Empirical Verification (N = 1,000,000 valves)
N_trials = 1000000;
rng(42); % Set deterministic seed for reproducible results

% Generate physical crack presence across population
has_crack = rand(1, N_trials) < P_crack;

% Generate sensor alarm responses conditional on physical state
alarm_triggered = false(1, N_trials);
alarm_triggered(has_crack)  = rand(1, sum(has_crack))  < P_alarm_crack;
alarm_triggered(~has_crack) = rand(1, sum(~has_crack)) < P_alarm_safe;

% Empirical conditional probabilities
total_alarms = sum(alarm_triggered);
true_positives = sum(alarm_triggered & has_crack);
false_positives = sum(alarm_triggered & ~has_crack);

P_crack_given_alarm_mc = true_positives / total_alarms;
P_safe_given_alarm_mc  = false_positives / total_alarms;

% 4. Display Formatted Verification Table
fprintf('=================================================================\n');
fprintf('  SENSOR FAULT DIAGNOSIS: BAYESIAN INFERENCE VERIFICATION       \n');
fprintf('=================================================================\n');
fprintf('Total Valves Evaluated in Monte Carlo : %d\n', N_trials);
fprintf('Total Sensor Alarms Triggered         : %d (%.2f%% of valves)\n', ...
    total_alarms, (total_alarms / N_trials) * 100);
fprintf('  - True Alarms (Cracks detected)     : %d\n', true_positives);
fprintf('  - False Alarms (Healthy valves)     : %d\n', false_positives);
fprintf('-----------------------------------------------------------------\n');
fprintf('METRIC                       ANALYTICAL       MONTE CARLO   ABS ERROR\n');
fprintf('P(Alarm)                     %10.5f        %10.5f  %10.2e\n', ...
    P_alarm_total, total_alarms / N_trials, abs(P_alarm_total - total_alarms / N_trials));
fprintf('P(Crack | Alarm)             %10.5f        %10.5f  %10.2e\n', ...
    P_crack_given_alarm, P_crack_given_alarm_mc, abs(P_crack_given_alarm - P_crack_given_alarm_mc));
fprintf('P(False Alarm | Alarm)       %10.5f        %10.5f  %10.2e\n', ...
    P_safe_given_alarm, P_safe_given_alarm_mc, abs(P_safe_given_alarm - P_safe_given_alarm_mc));
fprintf('=================================================================\n');
```

---

## 7. Common Student Pitfalls & Debugging Tips

### Pitfall 1: Confusing `rand` with `randn`
- **Symptom:** Your simulated sensor noise or dimensional tolerances have sharp, flat cutoffs and zero bell curve behavior.
- **Root Cause:** `rand(m, n)` generates numbers uniformly distributed on the open interval $(0, 1)$ with mean $0.5$ and variance $1/12$. `randn(m, n)` generates standard normal random numbers $\mathcal{N}(0, 1)$ with mean $0$ and variance $1$.
- **Fix:**
  - For Gaussian noise with mean $\mu$ and standard deviation $\sigma$: use `x = mu + sigma * randn(m, n)`.
  - For uniform variation in range $[a, b]$: use `x = a + (b - a) * rand(m, n)`.

### Pitfall 2: Biased vs Unbiased Sample Variance ($N$ vs $N-1$)
- **Symptom:** Your computed sample variance consistently underestimates the true population variance by $5\%$ to $10\%$ on small batch samples ($N = 10$).
- **Root Cause:** Dividing sum-of-squares by $N$ produces the biased maximum-likelihood estimator $\frac{1}{N}\sum (x_i - \bar{x})^2$. Because the sample mean $\bar{x}$ itself is computed from the data, it minimizes the sum of squared deviations, systematically underestimating dispersion.
- **Fix:** Use MATLAB's default `var(x)` which applies Bessel's correction with denominator $N-1$ (`w = 0`). If you explicitly require the $N$-denominator version, pass `var(x, 1)`.

```matlab
% Unbiased sample variance (default, recommended for engineering samples)
s2_unbiased = var(x, 0); % Denominator is N - 1

% Population / Biased variance
s2_biased = var(x, 1);   % Denominator is N
```

### Pitfall 3: The Base-Rate Fallacy in Conditional Probability
- **Symptom:** Students write $P(\text{Defect} | \text{Alarm}) = P(\text{Alarm} | \text{Defect}) = 98\%$.
- **Root Cause:** Transposing the conditional conditioning argument: $P(A|B) \ne P(B|A)$.
- **Fix:** Always write out Bayes' rule explicitly. When an event is rare (low prior $P(A)$), even small false-positive rates $P(B|A^c)$ dominate the total alarm count.

### Pitfall 4: Misinterpreting Moving-Average Filter Delay
- **Symptom:** After applying `y_filt = filter(ones(1, W)/W, 1, y_noisy)`, the filtered signal appears delayed or lagged compared to the true signal.
- **Root Cause:** A causal finite impulse response (FIR) moving-average filter of length $W$ introduces a physical phase lag of $\frac{W - 1}{2}$ samples.
- **Fix:** For offline telemetry analysis, compensate by time-shifting the output backwards by $(W-1)/2$ samples, or use zero-phase filtering (`filtfilt(ones(1, W)/W, 1, y_noisy)`).

### Pitfall 5: Calling `randi` with 0 or 1-Argument Confusion
- **Symptom:** `randi(10)` generates a $10 \times 10$ matrix instead of a single integer between 1 and 10.
- **Root Cause:** In MATLAB, passing a single scalar dimension argument to `rand`, `randn`, or `zeros` creates a square matrix of size $N \times N$.
- **Fix:** To get a single integer in $[1, \text{imax}]$, pass `randi(imax, 1, 1)` or `randi([imin, imax])`.

---

## 8. Engineering Interpretation

Translating statistical parameters into actionable physical decisions:

| Statistical Metric | MATLAB Command | Physical Engineering Context | Practical Engineering Decision |
| :--- | :--- | :--- | :--- |
| **$3\sigma$ Tolerance Band** | `mu +/- 3*sigma` | Precision CNC machining of bearing diameters | Set allowable machine tool offsets; parts outside $3\sigma$ ($0.27\%$) are quarantined for rework. |
| **Process Capability $C_p$** | `(USL - LSL) / (6*sigma)` | Automotive stamping dimensional quality | $C_p \ge 1.33$ required for production line release; $C_p < 1.0$ triggers tool replacement. |
| **SNR Improvement** | `10*log10(P_sig / P_noise)` | Strain gauge vibration telemetry | Selecting filter window $W$; higher $W$ suppresses noise by $10\log_{10}(W)\text{ dB}$ but limits signal bandwidth. |
| **MTBF ($1/\lambda$)** | `mean(failure_times)` | Aircraft hydraulic actuators, cooling pumps | Establish scheduled preventive overhaul intervals before component reliability drops below $99.9\%$. |
| **Parallel Redundancy** | $R_{\text{sys}} = 1 - (1 - R)^k$ | Quad-redundant flight control computers | Add identical parallel units so total system loss requires all $k$ independent channels to fail simultaneously. |
| **Posterior $P(\text{Fault}|\text{Flag})$** | Bayes' theorem | Wind turbine bearing vibration warning | Avoid immediate emergency shutdown if posterior $< 50\%$; trigger automated secondary oil analysis test. |

---

## 9. Progressive Exercises Overview

The exercises for this module are structured into four progressive pedagogical tiers in [exercises.m](exercises.m):

1. **Level 1: Recall**
   - Generating standard Gaussian white noise vectors with prescribed mean and variance using `randn`.
   - Computing sample statistics (`mean`, `std`, `var`) with Bessel's correction.
   - Verifying the empirical 68-95-99.7% Gaussian probability coverage bands.
2. **Level 2: Understanding & Debugging**
   - Debugging Task 2.1: Diagnosing and correcting a biased sample variance formula ($N$ vs $N-1$) in a quality inspection routine.
   - Debugging Task 2.2: Correcting a diagnostic test calculation afflicted by the base-rate fallacy where the prior defect rate was ignored.
3. **Level 3: Application**
   - Real-world sensor telemetry processing: Given a noisy thermocouple signal corrupted by high-frequency electromagnetic interference, calculate the raw Signal-to-Noise Ratio (SNR in dB), design a moving-average filter of window size $W$, and quantify the noise variance reduction and SNR improvement.
4. **Level 4: Challenge**
   - Reliability engineering simulation of an aircraft quad-redundant hydraulic system: 4 parallel pumps where at least 2 must survive for safe flight (2-out-of-4 system). Components exhibit exponential failure distributions with specified MTBFs. Formulate the analytical survival function $R_{\text{sys}}(t)$, execute a 50,000-trial Monte Carlo simulation over a 5,000-hour mission, estimate system MTBF, and evaluate mission success probability.

Complete, production-grade reference solutions with zero remaining `% TODO` markers are provided in [../solutions/probability_exercises_solution.m](../solutions/probability_exercises_solution.m).

For quick formula and syntax reminders, refer to the central reference sheet `reference/probability_cheat_sheet.md`.
