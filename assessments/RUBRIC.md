# Final Assessment Evaluation Rubric & Remediation Guide

This rubric defines the scoring criteria, diagnostic error taxonomy, and remediation pathways for [`FINAL_ASSESSMENT.md`](FINAL_ASSESSMENT.md) (100 Total Points).

---

## 1. Overall Scoring & Competency Bands

| Score Range | Achievement Level | Description | Recommendation |
| :--- | :--- | :--- | :--- |
| **90 – 100** | **Exemplary (Mastery)** | Flawless mathematical derivations, rigorous physical intuition, optimal vectorized code, zero syntax or dimension errors. | Ready for Level 3 (Machine Learning & AI Agent Engineering). |
| **75 – 89** | **Competent** | Sound mathematical derivations with minor algebraic slips; correct MATLAB/Python logic with minor optimization oversights. | Review specific remediation sections before advancing to Level 3. |
| **60 – 74** | **Developing** | Basic conceptual understanding present, but struggles with multi-variable proofs, condition number interpretation, or array boundary handling. | Repeat Tier 3 and 4 exercises in weak modules; revisit Cheat Sheets. |
| **< 60** | **Remediation Required** | Severe gaps in linear algebra foundations, calculus chain rules, probability distributions, or basic 1-based MATLAB indexing. | Mandatory re-study of Level 2 core modules before retaking assessment. |

---

## 2. Section-by-Section Scoring Keys

### Section 1: Conceptual Foundations (25 Points Max)
- **Q1.1 (5 pts)**:
  - 2 pts: Correct mathematical definitions of inner product ($C = AB$) and Hadamard product ($C_{ij} = A_{ij}B_{ij}$).
  - 1 pt: Proper notation of dimension compatibility ($(m \times k)(k \times n)$ vs $(m \times n)$).
  - 2 pts: Accurate ML mapping (linear projection layer vs activation gating / element-wise dropout).
- **Q1.2 (5 pts)**:
  - 2 pts: Formal definition $\kappa(A) = \|A\| \cdot \|A^{-1}\|$.
  - 1 pt: Relative error bound inequality $\frac{\|\Delta \mathbf{x}\|}{\|\mathbf{x}\|} \le \kappa(A) \frac{\|\Delta \mathbf{b}\|}{\|\mathbf{b}\|}$.
  - 2 pts: Calculation of lost precision ($15.9 - 11 \approx 4.9$ digits remaining) with IEEE 754 explanation.
- **Q1.3 (5 pts)**:
  - 2 pts: Continuous derivative vs discrete finite difference formulation.
  - 1 pt: Correct truncation error orders: Forward/Backward $= O(h)$, Central $= O(h^2)$.
  - 2 pts: Mathematical proof/explanation of noise amplification in differentiation vs noise attenuation in integration.
- **Q1.4 (5 pts)**:
  - 2 pts: Definitions of sample mean and sample variance.
  - 2 pts: Mathematical explanation of Bessel's correction ($N-1$) resolving degrees of freedom consumed by estimating the mean.
  - 1 pt: Distinction between `var(x, 0)` ($N-1$) and `var(x, 1)` ($N$).
- **Q1.5 (5 pts)**:
  - 3 pts: Proof/argument that expected inner product of independent zero-mean unit vectors in $\mathbb{R}^d$ has variance $1/d \to 0$.
  - 2 pts: High-D geometry explanation: near-orthogonality allows dense semantic storage without interference.

### Section 2: Mathematical Derivations & Proofs (25 Points Max)
- **Q2.1 (5 pts)**:
  - 2 pts: Derivation of normal equations $X^T(y - Xw) = 0 \implies P = X(X^TX)^{-1}X^T$.
  - 1 pt: Algebraic proof of idempotence: $P^2 = P$.
  - 1 pt: Algebraic proof of symmetry: $P^T = P$.
  - 1 pt: Proof of residual orthogonality $X^T e = 0$.
- **Q2.2 (5 pts)**:
  - 2 pts: Multivariable Taylor expansion formula with $\nabla f$ and $H$.
  - 2 pts: Eigenvalue classification of critical points (all $\lambda > 0 \implies$ min, all $\lambda < 0 \implies$ max, mixed $\implies$ saddle).
  - 1 pt: High-dimensional probability explanation: probability that all $n$ independent eigenvalues are positive is $2^{-n} \to 0$, making saddles dominate.
- **Q2.3 (5 pts)**:
  - 2 pts: Correct partial derivatives with respect to $w^{(2)}$ and $b^{(2)}$.
  - 2 pts: Matrix chain rule derivation for $W^{(1)}$ and $b^{(1)}$ with outer product $\delta X^T$.
  - 1 pt: Verification that $\sigma'(z) = \sigma(z)(1 - \sigma(z))$.
- **Q2.4 (5 pts)**:
  - 2 pts: Complete likelihood and prior product formulation in exponential form.
  - 2 pts: Completing the square to yield precision $\frac{1}{\sigma_N^2} = \frac{1}{\sigma_0^2} + \frac{N}{\sigma^2}$ and posterior mean $\mu_N$.
  - 1 pt: Limit proof as $N \to \infty$, showing $\mu_N \to \bar{x} = \hat{\theta}_{\text{MLE}}$.
- **Q2.5 (5 pts)**:
  - 2 pts: Derivative of softmax $\frac{\partial q_i}{\partial z_j}$ for cases $i = j$ and $i \neq j$.
  - 2 pts: Chain rule showing $\frac{\partial L}{\partial z_i} = q_i - p_i$.
  - 1 pt: Contrast with MSE showing lack of saturation when $q_i \approx 0$ and $p_i = 1$.

### Section 3: Code Reading & Bug Hunt (25 Points Max)
- **Q3.1 (5 pts)**:
  - 2 pts: Bug 1 identified (array dimension mismatch between `t` of length $N$ and `diff(v)` of length $N-1$).
  - 2 pts: Bug 2 identified (missing division by time step $dt = \Delta t$).
  - 1 pt: Clean corrected code with both `diff` and `gradient`.
- **Q3.2 (5 pts)**:
  - 2 pts: Identified all 0-based indexing attempts (`V_cell(0)`, `V_cell(0:4)`) and negative indexing (`V_cell(-1)`).
  - 1 pt: Clear explanation of MATLAB's 1-based indexing and `end` keyword.
  - 2 pts: Fully corrected idiomatic MATLAB code.
- **Q3.3 (5 pts)**:
  - 2 pts: Calculation of $\kappa(A) \approx 4 \times 10^4$.
  - 1 pt: Perturbed solution showing massive shift in $\mathbf{x}$ ($x_1 = 2, x_2 = 0$).
  - 2 pts: Detailed $O(n^3)$ comparison: Gaussian elimination with partial pivoting in `A\b` vs matrix inversion.
- **Q3.4 (5 pts)**:
  - 2 pts: Geometric explanation of ratio of quadrant area ($\pi/4$) to unit square area ($1$).
  - 1 pt: Standard error formula $\text{SE} = \frac{\sqrt{p(1-p)}}{\sqrt{N}}$ where $p = \pi/4$.
  - 2 pts: Calculation of required sample size $N \approx \frac{0.7854 \times 0.2146}{(10^{-4}/4)^2} \approx 2.7 \times 10^8$ samples.
- **Q3.5 (5 pts)**:
  - 2 pts: Three flaws identified: missing transpose `K.T`, missing $\sqrt{d_k}$ scaling, missing numerical stability subtraction $\max(scores)$.
  - 1 pt: Explanation of overflow in $\exp(1000) \to \text{inf}$ resulting in `NaN` weights.
  - 2 pts: Numerically stable, fully functional NumPy code provided.

### Section 4: Applied Engineering Challenge (25 Points Max)
- **Subtask A (7 pts)**:
  - 2 pts: Formulas for $P_{\text{elec}} = V_{\text{dc}} I_{\text{dc}}$ and $P_{\text{mech}} = \tau \omega \frac{2\pi}{60}$.
  - 3 pts: Trapezoidal quadrature equation in kWh: $\frac{1}{3.6 \times 10^6}\int P(t) dt$.
  - 2 pts: Motoring vs regeneration partitioning and ratio $\eta_{\text{regen}} = \frac{E_{\text{regen}}}{E_{\text{motoring}}} \times 100\%$.
- **Subtask B (6 pts)**:
  - 2 pts: Filter kernel $\mathbf{h} = \frac{1}{9}[1, 1, \dots, 1]^T$.
  - 2 pts: Variance proof $\text{Var}\left(\frac{1}{W}\sum \epsilon_i\right) = \frac{1}{W^2}\sum \sigma^2 = \frac{\sigma^2}{W} = \frac{\sigma^2}{9}$.
  - 2 pts: Finite difference on filtered signal with boundary handling.
- **Subtask C (6 pts)**:
  - 2 pts: LoRA parameter count: $2 \times 1024 \times 8 = 16,384$ vs $1,048,576$ ($98.44\%$ reduction).
  - 2 pts: Initialization scheme: $A \sim \mathcal{N}(0, \sigma^2)$ and $B = 0$ so that $BA = 0$ at step 0.
  - 2 pts: Eckart-Young theorem explanation: dominant singular values capture principal task variation.
- **Subtask D (6 pts)**:
  - 2 pts: Softmax probabilities calculated at $T = 1.0$: $\mathbf{p} \approx [0.551, 0.370, 0.037, 0.010, 0.009]$.
  - 2 pts: Effect of temperature scaling analyzed at $T = 0.5$ (more peaked) and $T = 2.0$ (more uniform).
  - 2 pts: Top-$p$ filtering at $p = 0.85$: selects maneuvers 1 and 2 (sum $= 0.921$), re-normalizes to $[0.598, 0.402]$.

---

## 3. Diagnostic Error Taxonomy & Targeted Remediation

| Diagnostic Code | Error Pattern | Remediation Pathway |
| :--- | :--- | :--- |
| **ERR-LA-01** | Confusing matrix multiplication with Hadamard product | Review [`reference/linear_algebra_cheat_sheet.md`](../reference/linear_algebra_cheat_sheet.md) §1 & [`linear_algebra/02_matrix_transformations.m`](../linear_algebra/02_matrix_transformations.m) |
| **ERR-LA-02** | Using `inv(A)*b` on ill-conditioned systems | Review [`linear_algebra/README.md`](../linear_algebra/README.md) §7.1 and [`linear_algebra/03_solving_linear_systems.m`](../linear_algebra/03_solving_linear_systems.m) |
| **ERR-CALC-01** | Array length truncation error with `diff` | Review [`reference/calculus_cheat_sheet.md`](../reference/calculus_cheat_sheet.md) §1 & [`calculus/01_derivatives_and_rates.m`](../calculus/01_derivatives_and_rates.m) |
| **ERR-CALC-02** | Omitting $\Delta t$ scaling in numerical differentiation | Review [`calculus/README.md`](../calculus/README.md) §7.2 |
| **ERR-PROB-01** | Biased sample variance ($N$ vs $N-1$) | Review [`reference/probability_cheat_sheet.md`](../reference/probability_cheat_sheet.md) §1 & [`probability/01_probability_foundations.m`](../probability/01_probability_foundations.m) |
| **ERR-AI-01** | Softmax numerical overflow / missing $\sqrt{d_k}$ | Review [`ml_bridge/README.md`](../ml_bridge/README.md) & [`linear_algebra/07_ai_ml_linear_algebra_bridge.md`](../linear_algebra/07_ai_ml_linear_algebra_bridge.md) |
| **ERR-AI-02** | Confusing Aleatoric and Epistemic uncertainty | Review [`probability/05_ai_ml_probability_bridge.md`](../probability/05_ai_ml_probability_bridge.md) §3 |
