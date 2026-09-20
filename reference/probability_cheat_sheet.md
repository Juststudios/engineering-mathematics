# Probability, Information Theory & Sampling Cheat Sheet

A comprehensive, mathematically rigorous reference guide for applied probability, sensor noise filtering, Bayesian inference, information theory, and generative AI sampling dynamics.

---

## 1. Random Variables, Distributions & Moments

| Distribution | Probability Density Function (PDF) / PMF | Expected Value $\mathbb{E}[X]$ | Variance $\text{Var}(X)$ | Engineering / AI Use Case |
| :--- | :--- | :--- | :--- | :--- |
| **Uniform** $\mathcal{U}(a, b)$ | $f(x) = \frac{1}{b - a}$ for $x \in [a, b]$ | $\frac{a + b}{2}$ | $\frac{(b - a)^2}{12}$ | Quantization noise, random initialization |
| **Gaussian** $\mathcal{N}(\mu, \sigma^2)$ | $f(x) = \frac{1}{\sigma \sqrt{2\pi}} \exp\left(-\frac{(x - \mu)^2}{2\sigma^2}\right)$ | $\mu$ | $\sigma^2$ | Sensor thermal noise, Central Limit Theorem, weights prior |
| **Exponential** $\text{Exp}(\lambda)$ | $f(x) = \lambda e^{-\lambda x}$ for $x \ge 0$ | $\frac{1}{\lambda}$ | $\frac{1}{\lambda^2}$ | Time between component failures (MTBF $= 1/\lambda$) |
| **Bernoulli** $\text{Bern}(p)$ | $P(X=1) = p, \quad P(X=0) = 1-p$ | $p$ | $p(1 - p)$ | Binary classification, token bit modeling |

### Sample Moments & Estimators
- **Sample Mean**: $\bar{x} = \frac{1}{N}\sum_{i=1}^N x_i$
- **Unbiased Sample Variance (Bessel's correction)**: $s^2 = \frac{1}{N - 1}\sum_{i=1}^N (x_i - \bar{x})^2$ (`var(x)` in MATLAB defaults to $N-1$)
- **Empirical Rule ($\mathcal{N}(\mu, \sigma^2)$)**:
  - $\mu \pm 1\sigma$: $68.27\%$ of observations
  - $\mu \pm 2\sigma$: $95.45\%$ of observations
  - $\mu \pm 3\sigma$: $99.73\%$ of observations (Six Sigma standard)

---

## 2. Bayesian Inference & Conjugate Updating

### Discrete Bayes' Theorem
$$P(A | B) = \frac{P(B | A) P(A)}{P(B)} = \frac{P(B | A) P(A)}{P(B | A)P(A) + P(B | \neg A)P(\neg A)}$$

### Continuous Bayesian Inference
$$\text{Posterior } p(\boldsymbol{\theta} | \mathcal{D}) = \frac{p(\mathcal{D} | \boldsymbol{\theta}) p(\boldsymbol{\theta})}{\int p(\mathcal{D} | \boldsymbol{\theta}') p(\boldsymbol{\theta}') d\boldsymbol{\theta}'} \propto \text{Likelihood} \times \text{Prior}$$

### Gaussian-Gaussian Conjugate Update (1D Parameter Estimation)
Given prior $\theta \sim \mathcal{N}(\mu_0, \sigma_0^2)$ and $N$ independent observations $x_i \sim \mathcal{N}(\theta, \sigma^2)$ with sample mean $\bar{x}$:
$$\frac{1}{\sigma_N^2} = \frac{1}{\sigma_0^2} + \frac{N}{\sigma^2} \implies \text{Precision accumulates additively!}$$
$$\mu_N = \sigma_N^2 \left(\frac{\mu_0}{\sigma_0^2} + \frac{N \bar{x}}{\sigma^2}\right)$$
- **MLE vs MAP**:
  - Maximum Likelihood Estimation: $\hat{\theta}_{\text{MLE}} = \arg\max \log p(\mathcal{D}|\theta) = \bar{x}$
  - Maximum A Posteriori: $\hat{\theta}_{\text{MAP}} = \arg\max [\log p(\mathcal{D}|\theta) + \log p(\theta)] = \mu_N$
  - Gaussian prior on weights is algebraically equivalent to **$L_2$ Regularization (Ridge)**:
    $$\log p(W) \propto -\frac{\|W\|_2^2}{2\sigma_0^2} \implies \min_W \mathcal{L}_{\text{data}}(W) + \lambda \|W\|_2^2$$

---

## 3. Information Theory & Loss Functions

| Metric | Mathematical Definition | Physical / AI Meaning |
| :--- | :--- | :--- |
| **Shannon Entropy** | $H(P) = -\sum_{i} P(x_i) \log_2 P(x_i)$ | Average surprise / uncertainty (in bits or nats) |
| **Cross-Entropy** | $H(P, Q) = -\sum_{i} P(x_i) \log Q(x_i)$ | Expected code length using predicted model $Q$ for true distribution $P$ |
| **Kullback-Leibler (KL) Divergence** | $D_{\text{KL}}(P \parallel Q) = \sum_{i} P(x_i) \log \frac{P(x_i)}{Q(x_i)}$ | Relative entropy; excess penalty for approximating $P$ with $Q$ ($D_{\text{KL}} \ge 0$) |

### Fundamental Relation
$$H(P, Q) = H(P) + D_{\text{KL}}(P \parallel Q)$$
Minimizing cross-entropy loss directly minimizes the KL divergence between true targets and model predictions!

### Softmax Cross-Entropy Loss Gradient
For logits $\mathbf{z}$, prediction $q_i = \frac{e^{z_i}}{\sum e^{z_j}}$, and one-hot true label $p_i$:
$$\frac{\partial H(P, Q)}{\partial z_i} = q_i - p_i = \hat{y}_i - y_i$$
Linear error signal that prevents gradient vanishing (unlike Mean Squared Error on sigmoid probabilities).

---

## 4. Uncertainty Quantification: Aleatoric vs Epistemic

$$\text{Total Predictive Variance } \text{Var}(y^* | \mathbf{x}^*) = \underbrace{\mathbb{E}_{\boldsymbol{\theta}}[\sigma^2(\mathbf{x}^*)]}_{\text{Aleatoric Uncertainty}} + \underbrace{\text{Var}_{\boldsymbol{\theta}}[\mu(\mathbf{x}^*)]}_{\text{Epistemic Uncertainty}}$$

- **Aleatoric Uncertainty (Data Noise)**: Inherent randomness in the physical measurement (e.g. sensor thermal noise). Irreducible even with infinite training data.
- **Epistemic Uncertainty (Model Ignorance)**: Uncertainty in model parameter estimates due to lack of training data in that region. Reducible by gathering additional data near $\mathbf{x}^*$. Evaluated via deep ensembles or Monte Carlo Dropout.

---

## 5. Stochastic Sampling & Monte Carlo in Generative Agents

Let logits be $\mathbf{z} = [z_1, z_2, \dots, z_V]$ over vocabulary $V$:

### Temperature Scaling
$$P(x_i; T) = \frac{\exp(z_i / T)}{\sum_{j=1}^V \exp(z_j / T)}$$
- $T \to 0$: Argmax greedy decoding (zero entropy, deterministic).
- $T = 1.0$: Standard categorical distribution from raw model logits.
- $T \to \infty$: Uniform random distribution (maximum entropy).

### Top-$k$ and Top-$p$ (Nucleus) Sampling
- **Top-$k$**: Retains only the $k$ tokens with highest probabilities, setting others to 0 and re-normalizing.
- **Top-$p$ (Nucleus)**: Finds the smallest set of tokens $V^{(p)}$ whose cumulative probability exceeds $p \in (0, 1]$:
  $$\sum_{i \in V^{(p)}} P(x_i) \ge p$$
  Adapts the candidate pool size dynamically: narrows when model is confident, widens when uncertain.

```python
# Pure NumPy Top-p (Nucleus) Sampling Implementation
def sample_top_p(logits, temperature=0.7, top_p=0.9):
    scaled_logits = logits / temperature
    exp_logits = np.exp(scaled_logits - np.max(scaled_logits))
    probs = exp_logits / np.sum(exp_logits)
    
    sorted_indices = np.argsort(probs)[::-1]
    sorted_probs = probs[sorted_indices]
    
    cumulative_probs = np.cumsum(sorted_probs)
    # Cutoff tokens beyond nucleus threshold
    cutoff = cumulative_probs > top_p
    cutoff[1:] = cutoff[:-1].copy()
    cutoff[0] = False
    
    sorted_probs[cutoff] = 0.0
    sorted_probs /= np.sum(sorted_probs)
    
    choice = np.random.choice(sorted_indices, p=sorted_probs)
    return choice
```
