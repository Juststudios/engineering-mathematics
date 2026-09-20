# Level 2 Engineering Mathematics + MATLAB: Comprehensive Final Assessment

## Examination Overview
- **Curriculum**: Level 2 — Engineering Mathematics + MATLAB
- **Target Audience**: Students bridging foundational Python/NumPy (Level 1) to Applied Machine Learning & AI Agent Engineering (Level 3)
- **Duration**: 3 Hours
- **Total Marks**: 100 Points
- **Grading Standard**: Refer to [`RUBRIC.md`](RUBRIC.md) for grading criteria and diagnostic remediation standards.

---

## Instructions for Examinees
1. Write all mathematical derivations step-by-step showing governing formulas, physical units, and intermediate algebraic simplifications.
2. Code snippets may be written in standard MATLAB syntax or runnable Python/NumPy where specified.
3. Clearly state all engineering assumptions (e.g., linear elastic deformation, steady-state thermal behavior, additive white Gaussian noise).
4. All 4 sections are mandatory.

---

## Section 1: Conceptual Foundations & Computational Representations (25 Points)

### Question 1.1: Linear Operators vs. Array Arithmetic (5 Points)
In MATLAB, explain why matrix multiplication (`*`) and element-wise array multiplication (`.*`) are fundamentally separated:
1. Provide the mathematical formula for $C = A * B$ where $A \in \mathbb{R}^{m \times k}$ and $B \in \mathbb{R}^{k \times n}$.
2. Provide the mathematical formula for $C = A .* B$ where $A, B \in \mathbb{R}^{m \times n}$.
3. In machine learning architectures, identify where each operation is used (e.g., dense linear layer projections vs. activation function gating).

### Question 1.2: Matrix Conditioning and Numerical Precision (5 Points)
For a system of linear equations $A\mathbf{x} = \mathbf{b}$:
1. Define the condition number $\kappa(A) = \|A\| \cdot \|A^{-1}\|$.
2. State the condition number inequality relating the relative perturbation in the output $\frac{\|\Delta \mathbf{x}\|}{\|\mathbf{x}\|}$ to the relative perturbation in the input $\frac{\|\Delta \mathbf{b}\|}{\|\mathbf{b}\|}$.
3. If an engineer solves a system where $\kappa(A) \approx 10^{11}$ using standard IEEE 754 double precision ($53$ bits of mantissa, $\approx 15.9$ decimal digits), how many significant decimal digits of precision remain trustworthy in $\mathbf{x}$? Explain why.

### Question 1.3: Continuous Dynamics vs. Discrete Sampling in Calculus (5 Points)
1. Contrast the continuous derivative $\frac{dy}{dt} = \lim_{\Delta t \to 0} \frac{y(t + \Delta t) - y(t)}{\Delta t}$ with the discrete backward and central difference operators used on digitized sensor telemetry.
2. What are the truncation error orders ($O(h)$ vs $O(h^2)$) of forward difference, backward difference, and central difference?
3. Why does numerical differentiation amplify high-frequency sensor noise, while numerical integration (`trapz`) suppresses it?

### Question 1.4: Statistical Estimation and Sample Variance Bias (5 Points)
1. Define the sample mean $\bar{x}$ and the sample variance $s^2$ of $N$ i.i.d. observations drawn from $\mathcal{N}(\mu, \sigma^2)$.
2. Explain Bessel's correction: why must the denominator of the unbiased sample variance be $N - 1$ instead of $N$?
3. In MATLAB, what does `var(x, 0)` compute versus `var(x, 1)`?

### Question 1.5: The Geometric Bridge to Modern AI (5 Points)
1. In high-dimensional vector spaces ($\mathbb{R}^d$ where $d = 768$ or $1536$), what happens to the angle between two uniformly drawn random vectors? Prove that their expected cosine similarity approaches 0 as $d \to \infty$.
2. How does this geometric property enable dense embedding spaces to store millions of distinct semantic concepts without catastrophic interference?

---

## Section 2: Mathematical Derivations & Analytical Proofs (25 Points)

### Question 2.1: Orthogonal Projection Operator (5 Points)
Given a dataset matrix $X \in \mathbb{R}^{m \times n}$ with full column rank ($m > n$) and a target observation vector $\mathbf{y} \in \mathbb{R}^m$:
1. Derive the projection matrix $P = X(X^T X)^{-1} X^T$ that projects $\mathbf{y}$ onto the column space $\text{Col}(X)$, minimizing the squared Euclidean error $\|\mathbf{y} - X\mathbf{w}\|_2^2$.
2. Prove algebraically that $P$ is idempotent: $P^2 = P$.
3. Prove algebraically that $P$ is symmetric: $P^T = P$.
4. Prove that the residual vector $\mathbf{e} = (I - P)\mathbf{y}$ is strictly orthogonal to every column of $X$ (i.e., $X^T \mathbf{e} = \mathbf{0}$).

### Question 2.2: Second-Order Curvature & The Hessian Matrix (5 Points)
Let $f(\mathbf{x}): \mathbb{R}^n \to \mathbb{R}$ be a twice continuously differentiable loss function.
1. Write the second-order multivariable Taylor expansion of $f(\mathbf{x} + \mathbf{v})$ around $\mathbf{x}$ in terms of gradient $\nabla f(\mathbf{x})$ and Hessian $H(\mathbf{x})$.
2. Explain how the eigenvalues $\lambda_1, \dots, \lambda_n$ of $H(\mathbf{x}^*)$ at a critical point where $\nabla f(\mathbf{x}^*) = \mathbf{0}$ classify the geometry into:
   - Strict local minimum
   - Strict local maximum
   - Saddle point
3. In high-dimensional deep learning loss landscapes ($n \gg 10^6$), explain why saddle points are exponentially more prevalent than true local minima.

### Question 2.3: Backpropagation Tensor Chain Rule (5 Points)
Consider a two-layer feedforward network:
$$\mathbf{z}^{(1)} = W^{(1)} \mathbf{x} + \mathbf{b}^{(1)}, \quad \mathbf{a}^{(1)} = \sigma(\mathbf{z}^{(1)}), \quad \hat{y} = \mathbf{w}^{(2)T} \mathbf{a}^{(1)} + b^{(2)}, \quad L = \frac{1}{2}(\hat{y} - y)^2$$
where $\sigma(z)$ is the element-wise sigmoid activation function $\sigma(z) = \frac{1}{1 + e^{-z}}$.
1. Derive the exact analytical expressions for the partial derivatives:
   $$\frac{\partial L}{\partial \mathbf{w}^{(2)}}, \quad \frac{\partial L}{\partial b^{(2)}}, \quad \frac{\partial L}{\partial W^{(1)}}, \quad \frac{\partial L}{\partial \mathbf{b}^{(1)}}$$
2. Show that $\sigma'(z) = \sigma(z)(1 - \sigma(z))$.
3. Write the computational graph sequence illustrating the forward pass and backward sensitivity signal propagation.

### Question 2.4: Continuous Gaussian-Gaussian Bayesian Conjugate Updating (5 Points)
An autonomous vehicle temperature sensor measures unknown engine block temperature $\theta \in \mathbb{R}$.
1. Prior belief is Gaussian: $p(\theta) = \mathcal{N}(\mu_0, \sigma_0^2)$.
2. We observe $N$ independent sensor measurements $x_1, \dots, x_N \sim \mathcal{N}(\theta, \sigma^2)$ with sample mean $\bar{x} = \frac{1}{N}\sum_{i=1}^N x_i$.
3. Prove that the posterior distribution $p(\theta | x_1, \dots, x_N)$ is also Gaussian $\mathcal{N}(\mu_N, \sigma_N^2)$, and derive the exact formulas for posterior precision $\frac{1}{\sigma_N^2}$ and posterior mean $\mu_N$.
4. Show that as $N \to \infty$, the maximum a posteriori (MAP) estimate converges to the maximum likelihood estimate (MLE).

### Question 2.5: Softmax Cross-Entropy Loss Gradient (5 Points)
For a $K$-class classification problem with logit vector $\mathbf{z} \in \mathbb{R}^K$:
$$q_i = \frac{e^{z_i}}{\sum_{j=1}^K e^{z_j}}, \quad L = -\sum_{k=1}^K p_k \log q_k$$
where $\mathbf{p}$ is a one-hot true target vector ($p_c = 1$ for true class $c$, and $0$ otherwise).
1. Show that the derivative of the softmax output with respect to logits is:
   $$\frac{\partial q_i}{\partial z_j} = \begin{cases} q_i(1 - q_i) & \text{if } i = j \\ -q_i q_j & \text{if } i \neq j \end{cases}$$
2. Prove that the gradient of the cross-entropy loss with respect to logit $z_i$ simplifies to the elegant linear error:
   $$\frac{\partial L}{\partial z_i} = q_i - p_i = \hat{y}_i - y_i$$
3. Contrast this gradient behavior with Mean Squared Error (MSE) on probabilities, explaining why softmax cross-entropy prevents gradient vanishing when predictions are incorrect.

---

## Section 3: Code Reading, Output Prediction & Bug Hunt (25 Points)

### Question 3.1: Calculus Array Length & Sampling Grid Bug (5 Points)
A student attempts to compute vehicle acceleration from 100 Hz GPS velocity telemetry using the following MATLAB code:
```matlab
% Ingestion: t is 1x1000 vector (seconds), v is 1x1000 vector (m/s)
t = linspace(0, 10, 1000);
v = 15 * sin(0.5 * t);

% Calculate acceleration
a = diff(v);

% Plot acceleration over time
figure;
plot(t, a);
xlabel('Time [s]');
ylabel('Acceleration [m/s^2]');
```
1. Identify two critical bugs in this script.
2. Explain the exact MATLAB error message or physical distortion caused by each bug.
3. Write the corrected MATLAB code using both `diff` (with midpoint time adjustment) and `gradient`.

### Question 3.2: 0-Based Indexing & Negative Slicing Pitfall (5 Points)
A Python programmer transitioning to MATLAB writes the following script to inspect an electric vehicle battery voltage telemetry array:
```matlab
function check_battery_voltage(V_cell)
    % Check initial rest voltage
    v_initial = V_cell(0);
    
    % Check last reading
    v_final = V_cell(-1);
    
    % Extract first 5 readings
    v_start = V_cell(0:4);
    
    fprintf('Initial: %.2f V, Final: %.2f V\n', v_initial, v_final);
end
```
1. Identify all syntax and runtime errors in this code.
2. Explain MATLAB's native array indexing rules (base index, boundary inclusion, negative index policy).
3. Rewrite the function with correct, idiomatic MATLAB syntax.

### Question 3.3: Inverting Ill-Conditioned Linear System (5 Points)
Inspect the following MATLAB calculation solving a structural truss system:
```matlab
A = [ 1.0000, 1.0000;
      1.0000, 1.0001 ];
b = [ 2.0000; 2.0001 ];

% Student formulation
x1 = inv(A) * b;

% Engineering formulation
x2 = A \ b;
```
1. Compute the condition number $\kappa_\infty(A)$ analytically or numerically.
2. If `b` is perturbed by measurement noise to `b_noisy = [2.0000; 2.0000]`, calculate the true solution $\mathbf{x}_{\text{noisy}}$.
3. Explain why `A\b` is preferred over `inv(A)*b` in terms of numerical stability and algorithmic complexity ($O(n^3)$ comparison).

### Question 3.4: Monte Carlo Pi Integration Convergence (5 Points)
Examine this vectorized MATLAB script estimating $\pi$:
```matlab
N = 10000;
x = rand(N, 1);
y = rand(N, 1);

in_circle = (x.^2 + y.^2) <= 1.0;
pi_est = 4 * sum(in_circle) / N;
error_pct = abs(pi_est - pi) / pi * 100;
```
1. Explain the geometric and probabilistic principle underlying this calculation.
2. According to the Central Limit Theorem, what is the standard error of `pi_est` as a function of $N$?
3. How many samples $N$ are required to achieve a standard error of $\le 10^{-4}$?

### Question 3.5: Scaled Dot-Product Attention Code Audit (5 Points)
An engineer writes the following Python/NumPy implementation of the Attention mechanism:
```python
import numpy as np

def buggy_attention(Q, K, V):
    # Q: (seq_len, d_k)
    # K: (seq_len, d_k)
    # V: (seq_len, d_v)
    scores = Q @ K
    weights = np.exp(scores) / np.sum(np.exp(scores))
    output = weights @ V
    return output
```
1. Identify three mathematical and algorithmic flaws in this implementation.
2. Explain the numerical catastrophe (overflow/underflow) that will occur if logits in `scores` exceed $+1000$.
3. Write the fully corrected, numerically stable NumPy implementation using temperature/dimension scaling $\frac{1}{\sqrt{d_k}}$, correct 2D matrix multiplication (`K.T`), axis-specific softmax normalization, and log-sum-exp stabilization.

---

## Section 4: Applied Engineering & AI Architecture Challenge (25 Points)

### Scenario: Autonomous Electric Vehicle (EV) Telemetry & Predictive Control System
You are the lead controls and machine learning engineer for an autonomous electric vehicle. The vehicle powertrain consists of a high-voltage battery pack, traction inverter, and permanent magnet motor monitored at $10\text{ Hz}$ ($dt = 0.1\text{ s}$).

```
[Battery Pack] ──(V_dc, I_dc)──> [Inverter] ──(T_inv)──> [Traction Motor] ──(Torque, Speed)──> Wheels
                                      │
                                      ▼
                      [AI Supervisory Control Agent]
```

### Subtask A: Powertrain Power Flow & Quadrature (7 Points)
Given $N = 600$ telemetry samples over a 60-second highway test:
- $V_{\text{dc}}(t)$ [Volts], $I_{\text{dc}}(t)$ [Amperes]
- $\omega(t)$ [RPM], $\tau(t)$ [$\text{N}\cdot\text{m}$]
- $T_{\text{inv}}(t)$ [${}^\circ\text{C}$]
1. Write the mathematical formula for instantaneous electrical power $P_{\text{elec}}(t)$ and mechanical power $P_{\text{mech}}(t)$ in Watts.
2. Write the trapezoidal quadrature equation to calculate total net energy consumed in kilowatt-hours ($\text{kWh}$).
3. Distinguish motoring energy ($P_{\text{elec}} > 0$) from regenerative braking energy ($P_{\text{elec}} < 0$). Formulate the regeneration efficiency ratio $\eta_{\text{regen}}$.

### Subtask B: Digital Filtering & Thermal Dynamics (6 Points)
Sensor telemetry for inverter temperature $T_{\text{inv}}$ is corrupted by additive zero-mean Gaussian noise $\epsilon \sim \mathcal{N}(0, \sigma^2)$ with $\sigma \approx 0.75^\circ\text{C}$.
1. Formulate a 9-point moving-average digital filter kernel $\mathbf{h}$.
2. Prove that applying this filter reduces the variance of white Gaussian noise by a factor of $9$ (reducing standard deviation by $3\times$).
3. Formulate the finite difference equation to evaluate the thermal heating rate $\frac{dT_{\text{inv}}}{dt}$ [${}^\circ\text{C/s}$] on the filtered signal.

### Subtask C: Low-Rank Parameter Adaptation (LoRA) (6 Points)
The vehicle's autonomous vision system uses a transformer with projection weight matrix $W_0 \in \mathbb{R}^{1024 \times 1024}$. To adapt the model to nocturnal foggy conditions without fine-tuning all $1024^2 \approx 1,048,576$ parameters, you apply Low-Rank Adaptation (LoRA) with rank $r = 8$:
$$W = W_0 + \Delta W = W_0 + \frac{\alpha}{r} (B \cdot A)$$
where $B \in \mathbb{R}^{1024 \times 8}$ and $A \in \mathbb{R}^{8 \times 1024}$.
1. Calculate the exact parameter count of the LoRA adapter ($B$ and $A$) and the percentage parameter reduction compared to full fine-tuning.
2. How should $A$ and $B$ be initialized at the start of training to ensure $\Delta W = 0$ at step 0?
3. Using the Eckart-Young SVD theorem, explain why rank $r = 8$ can capture over $90\%$ of the variance of full weight adaptation.

### Subtask D: Agent Action Selection & Nucleus Sampling (6 Points)
The vehicle's high-level route planner agent evaluates $K = 5$ discrete driving maneuvers (1: Maintain Lane, 2: Accelerate, 3: Decelerate, 4: Lane Change Left, 5: Lane Change Right) with predicted utility logits $\mathbf{z} = [4.2, 3.8, 1.5, 0.2, 0.1]$.
1. Calculate the softmax action probabilities at Temperature $T = 1.0$.
2. Calculate the softmax action probabilities at Temperature $T = 0.5$ (cold/exploitative) and Temperature $T = 2.0$ (warm/exploratory).
3. Apply Top-$p$ (nucleus) truncation with $p = 0.85$ to the $T = 1.0$ distribution: identify which maneuvers remain in the candidate set and calculate their re-normalized selection probabilities.
