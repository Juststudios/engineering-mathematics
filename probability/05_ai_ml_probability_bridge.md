# AI/ML Probability Bridge: Continuous Bayes, Entropy, Uncertainty & Sampling

Welcome to the AI/ML Bridge for Probability and Uncertainty. This lesson connects random variables, probability densities, and noise modeling directly to Bayesian machine learning, information-theoretic loss functions, epistemic uncertainty quantification, and stochastic sampling in LLM agents.

---

## 1. Continuous Bayesian Inference & Conjugate Updating

### TERM
Continuous Bayesian Inference & Conjugate Priors

### DEFINITION
Given parameter vector $\boldsymbol{\theta} \in \mathbb{R}^d$ and an observed dataset $\mathcal{D} = \{x_1, \dots, x_N\}$, Bayes' Theorem states:
$$p(\boldsymbol{\theta} | \mathcal{D}) = \frac{p(\mathcal{D} | \boldsymbol{\theta}) p(\boldsymbol{\theta})}{\int p(\mathcal{D} | \boldsymbol{\theta}') p(\boldsymbol{\theta}') d\boldsymbol{\theta}'} = \frac{\mathcal{L}(\boldsymbol{\theta}; \mathcal{D}) p(\boldsymbol{\theta})}{p(\mathcal{D})}$$
where:
- $p(\boldsymbol{\theta})$ is the **Prior** distribution (belief before observing data).
- $p(\mathcal{D} | \boldsymbol{\theta})$ is the **Likelihood** function (how probable the observed data is given $\boldsymbol{\theta}$).
- $p(\boldsymbol{\theta} | \mathcal{D})$ is the **Posterior** distribution (disciplined belief update).
- $p(\mathcal{D})$ is the marginal likelihood (**Evidence**).

For a 1D Gaussian prior $\theta \sim \mathcal{N}(\mu_0, \sigma_0^2)$ and $N$ observations drawn from $\mathcal{N}(\theta, \sigma^2)$ with sample mean $\bar{x}$, the posterior is also Gaussian $\mathcal{N}(\mu_N, \sigma_N^2)$ (conjugacy):
$$\frac{1}{\sigma_N^2} = \frac{1}{\sigma_0^2} + \frac{N}{\sigma^2} \implies \text{Precision accumulates additively!}$$
$$\mu_N = \sigma_N^2 \left(\frac{\mu_0}{\sigma_0^2} + \frac{N \bar{x}}{\sigma^2}\right)$$

### INTUITION
Think of a police detective investigating a crime:
- Before arriving at the crime scene, the detective has an initial suspicion based on historical crime rates (the **Prior**).
- At the scene, forensic evidence is collected: fingerprints, surveillance timestamps, ballistic trajectory (the **Likelihood**).
- The detective does not throw away their initial baseline or blindly follow a single noisy clue; they combine both mathematically to arrive at a revised conviction (the **Posterior**).
- As the volume of forensic evidence grows huge ($N \to \infty$), the initial prior belief is washed away and the truth is dictated entirely by data.

### WHY IT EXISTS
In classical machine learning, point estimation via Maximum Likelihood Estimation (MLE):
$$\hat{\boldsymbol{\theta}}_{\text{MLE}} = \arg\max \log p(\mathcal{D} | \boldsymbol{\theta})$$
is prone to severe overfitting when data is scarce ($N$ small). If you flip a coin once and it lands heads, MLE claims the coin lands heads $100\%$ of the time!

Bayesian inference prevents this through Maximum A Posteriori (MAP) estimation:
$$\hat{\boldsymbol{\theta}}_{\text{MAP}} = \arg\max [\log p(\mathcal{D} | \boldsymbol{\theta}) + \log p(\boldsymbol{\theta})]$$
Placing a zero-mean Gaussian prior $p(W) = \mathcal{N}(0, \sigma_0^2 I)$ over neural network weights is **mathematically identical to $L_2$ Regularization (Weight Decay / Ridge Regression)**:
$$\log p(W) = -\frac{\|W\|_2^2}{2\sigma_0^2} - C \implies \min_W \mathcal{L}_{\text{data}}(W) + \frac{\lambda}{2} \|W\|_2^2, \quad \text{where } \lambda = \frac{\sigma^2}{\sigma_0^2}$$

### HOW IT WORKS
1. Define prior mean $\mu_0$ and prior variance $\sigma_0^2$.
2. For each incoming batch of measurements, compute sample mean $\bar{x}$ and sample size $N$.
3. Compute updated posterior precision: $\tau_N = \tau_0 + N \tau_{\text{data}}$.
4. Compute updated posterior mean: $\mu_N = \frac{\tau_0 \mu_0 + N \tau_{\text{data}} \bar{x}}{\tau_N}$.
5. Notice that posterior uncertainty $\sigma_N = \frac{1}{\sqrt{\tau_N}}$ monotonically shrinks as $O(1/\sqrt{N})$.

### CODE
```python
import numpy as np

# True underlying physical parameter: theta_true = 75.0 deg C
theta_true = 75.0
sensor_noise_sigma = 4.0

# 1. Prior belief: weak prior centered at 20.0 deg C with high variance
mu_0 = 20.0
sigma_0 = 15.0

# 2. Collect sequential observations
np.random.seed(42)
N_obs = [1, 5, 20, 100]
print(f"Prior: mu = {mu_0:.1f}, sigma = {sigma_0:.2f}")

for N in N_obs:
    samples = np.random.normal(loc=theta_true, scale=sensor_noise_sigma, size=N)
    x_bar = np.mean(samples)
    
    # Bayesian Gaussian conjugate update
    prec_0 = 1.0 / (sigma_0**2)
    prec_data = 1.0 / (sensor_noise_sigma**2)
    prec_N = prec_0 + N * prec_data
    sigma_N = np.sqrt(1.0 / prec_N)
    mu_N = (prec_0 * mu_0 + N * prec_data * x_bar) / prec_N
    
    print(f"N = {N:3d} | Sample Mean = {x_bar:6.2f} | Posterior: mu = {mu_N:6.2f}, sigma = {sigma_N:5.2f}")
```

---

## 2. Information Theory: Entropy, Cross-Entropy & KL Divergence

### TERM
Information Theory & Loss Formulations

### DEFINITION
For a discrete probability distribution $P$ with support $\mathcal{X}$:
1. **Shannon Entropy** measures the intrinsic uncertainty or average information content (in nats or bits):
   $$H(P) = -\sum_{x \in \mathcal{X}} P(x) \log P(x)$$
2. **Cross-Entropy** measures the average code length when events from true distribution $P$ are encoded using model distribution $Q$:
   $$H(P, Q) = -\sum_{x \in \mathcal{X}} P(x) \log Q(x)$$
3. **Kullback-Leibler (KL) Divergence** measures the statistical distance / information inefficiency between $P$ and $Q$:
   $$D_{\text{KL}}(P \parallel Q) = \sum_{x \in \mathcal{X}} P(x) \log \frac{P(x)}{Q(x)} \ge 0$$
   with $D_{\text{KL}}(P \parallel Q) = 0 \iff P = Q$.

Fundamental Identity:
$$H(P, Q) = H(P) + D_{\text{KL}}(P \parallel Q)$$

### INTUITION
- **Entropy ($H(P)$)** is how uncertain the weather is:
  - If a city has a $50/50$ chance of rain or sunshine every day, entropy is maximal ($1$ bit): you learn something every morning.
  - If a city is in the Sahara Desert with a $99.9\%$ chance of sunshine, entropy is near zero: checking the forecast yields virtually zero new information.
- **Cross-Entropy ($H(P, Q)$)** is what happens if you pack your suitcase using a weather forecast from an inaccurate meteorologist ($Q$) when the real climate is $P$.
- **KL Divergence ($D_{\text{KL}}(P \parallel Q)$)** is the exact excess penalty you pay (in wasted luggage space or surprise) for using model $Q$ instead of the truth $P$.

### WHY IT EXISTS
In classification problems, students often try using Mean Squared Error (MSE) on output probabilities: $\mathcal{L}_{\text{MSE}} = \frac{1}{2}(\hat{y} - y)^2$. 
MSE is disastrous for classification: when a model makes a confident wrong prediction ($\hat{y} \approx 0$ when $y = 1$), the sigmoid or softmax gradient contains the factor $\hat{y}(1 - \hat{y}) \approx 0$, causing **catastrophic gradient vanishing**! The model gets stuck because the learning signal freezes.

Cross-Entropy loss solves this: for logits $\mathbf{z}$ and softmax $\hat{y}_i = \frac{e^{z_i}}{\sum e^{z_j}}$, the derivative is:
$$\frac{\partial H(P, Q)}{\partial z_i} = \hat{y}_i - y_i$$
The gradient is a clean, non-saturating linear error! When the prediction is wrong ($\hat{y}_i = 0, y_i = 1$), the gradient is $-1.0$ (maximum push), ensuring rapid learning.

### HOW IT WORKS
1. Target distribution $P$: one-hot vector $\mathbf{y} = [0, 1, 0]$.
2. Model logits: $\mathbf{z} = [1.2, 3.5, 0.4]$.
3. Softmax: $Q = \text{softmax}(\mathbf{z})$.
4. Cross-entropy: $\mathcal{L} = -\log Q_2$.
5. Gradient: $\nabla_{\mathbf{z}} \mathcal{L} = Q - P$.

### CODE
```python
import numpy as np

def compute_information_metrics(P, Q):
    """
    Computes Entropy H(P), Cross-Entropy H(P, Q), and KL Divergence D_KL(P || Q).
    """
    eps = 1e-12
    P_safe = np.clip(P, eps, 1.0)
    Q_safe = np.clip(Q, eps, 1.0)
    
    H_P = -np.sum(P * np.log(P_safe))
    H_PQ = -np.sum(P * np.log(Q_safe))
    D_KL = np.sum(P * np.log(P_safe / Q_safe))
    
    return H_P, H_PQ, D_KL

# True distribution vs predicted models
P_true = np.array([0.7, 0.2, 0.1])
Q_good = np.array([0.65, 0.22, 0.13])
Q_bad  = np.array([0.1, 0.2, 0.7])

h_p, h_good, kl_good = compute_information_metrics(P_true, Q_good)
_, h_bad, kl_bad     = compute_information_metrics(P_true, Q_bad)

print(f"True Entropy H(P)         : {h_p:.4f} nats")
print(f"Good Model Cross-Entropy  : {h_good:.4f} (KL = {kl_good:.4f})")
print(f"Bad Model Cross-Entropy   : {h_bad:.4f} (KL = {kl_bad:.4f})")
print(f"Identity Verification     : {h_good:.4f} == {h_p + kl_good:.4f}")
```

---

## 3. Aleatoric vs. Epistemic Uncertainty Estimation

### TERM
Aleatoric vs. Epistemic Uncertainty Decomposition

### DEFINITION
Let $y = f^*(\mathbf{x}) + \epsilon$ be a physical system where $\epsilon \sim \mathcal{N}(0, \sigma_{\text{noise}}^2)$ represents physical measurement noise.

For an ensemble of $M$ trained models or Monte Carlo Dropout passes with parameters $\boldsymbol{\theta}^{(1)}, \dots, \boldsymbol{\theta}^{(M)}$:
1. **Predictive Mean**:
   $$\bar{\mu}(\mathbf{x}) = \frac{1}{M}\sum_{m=1}^M \mu(\mathbf{x}; \boldsymbol{\theta}^{(m)})$$
2. **Law of Total Variance Decomposition**:
   $$\text{Var}(y | \mathbf{x}) = \underbrace{\frac{1}{M}\sum_{m=1}^M \sigma^2(\mathbf{x}; \boldsymbol{\theta}^{(m)})}_{\text{Aleatoric Uncertainty (Data Noise)}} + \underbrace{\frac{1}{M}\sum_{m=1}^M \left(\mu(\mathbf{x}; \boldsymbol{\theta}^{(m)}) - \bar{\mu}(\mathbf{x})\right)^2}_{\text{Epistemic Uncertainty (Model Ignorance)}}$$

### INTUITION
- **Aleatoric Uncertainty (Chance)**: You roll a fair 6-sided die. You know the exact physics and the exact probabilities ($1/6$ for each face), but you cannot predict the next roll with certainty. Collecting a million past rolls will never reduce the randomness of the next roll. It is **irreducible noise**.
- **Epistemic Uncertainty (Ignorance)**: A magician hands you a trick die made of lead. You have never seen it rolled. You have no idea which face is weighted. Because you lack data, your epistemic uncertainty is enormous. But if you roll it 500 times and observe the outcomes, your ignorance vanishes: you determine the true bias with high precision. It is **reducible uncertainty**.

### WHY IT EXISTS
Autonomous engineering agents (self-driving cars, surgical robots, medical diagnostics) must **know what they do not know**. 

If a self-driving perception model encounters heavy rain, aleatoric uncertainty rises, but the model knows it is looking at rain. However, if the car encounters a rare situation not present in the training set (e.g. an inverted semi-truck blocking the highway), **epistemic uncertainty explodes**. 

Detecting high epistemic uncertainty allows the agent to safely disengage and yield control to human intervention rather than making a catastrophically confident mistake.

### HOW IT WORKS
1. Train an ensemble of $M$ diverse models (or apply dropout during inference).
2. For an input $\mathbf{x}$, each model outputs prediction $\mu_m(\mathbf{x})$ and estimated noise $\sigma_m^2(\mathbf{x})$.
3. Inside the training distribution domain ($x \in [x_{\min}, x_{\max}]$), all models agree: epistemic variance is tiny.
4. Outside the training domain ($x \gg x_{\max}$), the models diverge wildly: epistemic variance spikes, triggering safety alerts.

### CODE
```python
import numpy as np

# Simulate training data in domain [-2, +2]
np.random.seed(42)
X_train = np.random.uniform(-2, 2, 50)
true_fn = lambda x: np.sin(1.5 * x)
sigma_noise = 0.2
Y_train = true_fn(X_train) + np.random.normal(0, sigma_noise, len(X_train))

# Train an ensemble of 5 polynomial models
M = 5
models = []
for m in range(M):
    # Bootstrap resample
    boot_idx = np.random.choice(len(X_train), size=len(X_train), replace=True)
    coeffs = np.polyfit(X_train[boot_idx], Y_train[boot_idx], deg=3)
    models.append(coeffs)

# Evaluate on In-Distribution (x = 0.5) vs Out-of-Distribution (x = 4.5)
x_in, x_ood = 0.5, 4.5

preds_in  = np.array([np.polyval(c, x_in) for c in models])
preds_ood = np.array([np.polyval(c, x_ood) for c in models])

epistemic_in  = np.var(preds_in)
epistemic_ood = np.var(preds_ood)

print(f"In-Distribution  (x = 0.5): Mean = {np.mean(preds_in):.3f}, Epistemic Var = {epistemic_in:.6f} (Confident)")
print(f"Out-of-Distribution (x = 4.5): Mean = {np.mean(preds_ood):.3f}, Epistemic Var = {epistemic_ood:.4f} (UNSAFE SPIKE!)")
```

---

## 4. Stochastic Sampling & Monte Carlo in AI Agents

### TERM
Stochastic Decoding & Temperature-Scaled Nucleus (Top-$p$) Sampling

### DEFINITION
Given language model logit vector $\mathbf{z} \in \mathbb{R}^{|V|}$ over vocabulary $V$:
1. **Temperature-Scaled Softmax**:
   $$P(w_i; T) = \frac{\exp(z_i / T)}{\sum_{j=1}^{|V|} \exp(z_j / T)}$$
   where $T > 0$ is the temperature hyperparameter.
2. **Top-$p$ (Nucleus) Truncation**:
   Let sorted indices be $i_1, i_2, \dots$ such that $P(w_{i_1}) \ge P(w_{i_2}) \ge \dots$. The nucleus $V^{(p)}$ is the minimal set of top tokens satisfying:
   $$\sum_{k=1}^{|V^{(p)}|} P(w_{i_k}) \ge p, \quad p \in (0, 1]$$
   Probabilities outside $V^{(p)}$ are set to 0, and the remaining distribution is re-normalized:
   $$\tilde{P}(w) = \begin{cases} \frac{P(w)}{\sum_{u \in V^{(p)}} P(u)} & \text{if } w \in V^{(p)} \\ 0 & \text{otherwise} \end{cases}$$

### INTUITION
Imagine an autonomous AI agent choosing actions:
- **Temperature $T \to 0$ (Freezing)**: The agent always greedily picks the single highest-rated action ($\text{argmax}$). The model becomes rigid, repetitive, and prone to getting stuck in infinite loops.
- **Temperature $T \to \infty$ (Boiling)**: All actions become equally likely ($\text{Uniform}$). The model outputs incoherent gibberish.
- **Top-$p$ (Nucleus)** acts like a dynamic safety net: when the model is confident (e.g. predicting the word "York" after "New"), the top token already has $p = 0.99$, so the nucleus contains only 1 candidate. When the model is in a creative open-ended situation, the top tokens are evenly spread, so the nucleus automatically widens to include 50 valid options.

### WHY IT EXISTS
Greedy search ($T = 0$) degrades generative quality because LLMs are trained to model probabilities, not maximize beam paths. Pure random sampling ($T = 1$) occasionally picks disastrously unlikely tokens from the long tail of the vocabulary ($|V| = 50,000$).

Nucleus sampling dynamically truncates the unreliable long tail while allowing rich, creative exploration among valid alternatives.

### HOW IT WORKS
1. Scale raw logits by $1/T$.
2. Compute softmax probabilities with numerical stability subtraction.
3. Sort candidate tokens descending by probability.
4. Compute cumulative sum of sorted probabilities.
5. Mask out any token whose preceding cumulative sum has already crossed $p$.
6. Re-normalize remaining probabilities and draw a categorical sample via inverse CDF.

### CODE
```python
import numpy as np

def sample_nucleus_top_p(logits, temperature=0.7, top_p=0.9):
    """
    Implements pure NumPy Temperature-Scaled Nucleus (Top-p) Sampling.
    """
    # 1. Temperature scaling
    scaled_logits = logits / temperature
    
    # 2. Stable softmax
    shifted = scaled_logits - np.max(scaled_logits)
    probs = np.exp(shifted) / np.sum(np.exp(shifted))
    
    # 3. Sort descending
    sorted_indices = np.argsort(probs)[::-1]
    sorted_probs = probs[sorted_indices]
    
    # 4. Cumulative sum & nucleus mask
    cum_probs = np.cumsum(sorted_probs)
    # Tokens to remove: where cumulative probability prior to current token exceeded top_p
    mask = cum_probs > top_p
    mask[1:] = mask[:-1].copy()
    mask[0] = False
    
    # 5. Zero out tail & re-normalize
    sorted_probs[mask] = 0.0
    sorted_probs /= np.sum(sorted_probs)
    
    # 6. Sample
    sampled_idx = np.random.choice(sorted_indices, p=sorted_probs)
    return sampled_idx, sorted_indices[~mask]

# Example with vocabulary of 6 candidate tokens
logits = np.array([4.5, 4.1, 2.0, 0.5, -1.0, -3.0])
vocab = ["Action_A", "Action_B", "Action_C", "Action_D", "Action_E", "Action_F"]

np.random.seed(7)
choice_idx, nucleus_pool = sample_nucleus_top_p(logits, temperature=0.8, top_p=0.85)

print(f"Selected Action   : {vocab[choice_idx]}")
print(f"Nucleus Candidates: {[vocab[i] for i in nucleus_pool]} (Tail truncated safely!)")
```
