#!/usr/bin/env python3
"""
================================================================================
PROBABILITY AI/ML BRIDGE: BAYESIAN INFERENCE, ENTROPY & AGENT SAMPLING
================================================================================
Zero-Dependency Pure-NumPy Implementation demonstrating:
1. Continuous Gaussian-Gaussian Bayesian Conjugate Updating & Precision Accumulation
2. Information Theory: Shannon Entropy, Cross-Entropy & KL Divergence Identity
3. Softmax Cross-Entropy Non-Saturating Gradient (y_hat - y)
4. Predictive Uncertainty Decomposition: Aleatoric (Data Noise) vs Epistemic (Ignorance)
5. Stochastic AI Agent Sampling: Temperature Scaling & Top-p (Nucleus) Truncation
================================================================================
"""

import numpy as np
from typing import Dict, Tuple, List, Any


def run_sequential_bayes_update(
    prior_mu: float,
    prior_sigma: float,
    true_theta: float,
    sensor_sigma: float,
    n_samples: int = 100,
    seed: int = 42
) -> Dict[str, Any]:
    """
    Simulates sequential Gaussian-Gaussian Bayesian updating:
    Precision accumulates additively: 1/sigma_N^2 = 1/sigma_0^2 + N / sigma_data^2
    """
    rng = np.random.default_rng(seed)
    observations = rng.normal(loc=true_theta, scale=sensor_sigma, size=n_samples)
    
    tau_0 = 1.0 / (prior_sigma ** 2)
    tau_data = 1.0 / (sensor_sigma ** 2)
    
    # Batch statistics
    sample_mean = float(np.mean(observations))
    tau_N = tau_0 + n_samples * tau_data
    posterior_sigma = float(np.sqrt(1.0 / tau_N))
    posterior_mu = float((tau_0 * prior_mu + n_samples * tau_data * sample_mean) / tau_N)
    
    # Verify asymptotic convergence to MLE as N grows
    discrepancy_with_mle = abs(posterior_mu - sample_mean)
    
    return {
        "prior_mu": prior_mu,
        "prior_sigma": prior_sigma,
        "true_theta": true_theta,
        "sample_mean": sample_mean,
        "posterior_mu": posterior_mu,
        "posterior_sigma": posterior_sigma,
        "discrepancy_with_mle": discrepancy_with_mle,
        "precision_gain_ratio": tau_N / tau_0,
    }


def compute_information_metrics(
    P: np.ndarray,
    Q: np.ndarray
) -> Dict[str, float]:
    """
    Calculates Shannon Entropy H(P), Cross-Entropy H(P, Q), and KL Divergence D_KL(P || Q).
    Verifies the fundamental information-theoretic theorem:
    H(P, Q) = H(P) + D_KL(P || Q)
    """
    assert np.allclose(np.sum(P), 1.0), "P must be a valid probability distribution"
    assert np.allclose(np.sum(Q), 1.0), "Q must be a valid probability distribution"
    
    eps = 1e-15
    P_safe = np.clip(P, eps, 1.0)
    Q_safe = np.clip(Q, eps, 1.0)
    
    H_P = float(-np.sum(P * np.log(P_safe)))
    H_PQ = float(-np.sum(P * np.log(Q_safe)))
    D_KL = float(np.sum(P * np.log(P_safe / Q_safe)))
    
    identity_error = abs(H_PQ - (H_P + D_KL))
    
    return {
        "entropy_P": H_P,
        "cross_entropy_PQ": H_PQ,
        "kl_divergence": D_KL,
        "identity_error": identity_error,
    }


def compute_softmax_cross_entropy_grad(
    logits: np.ndarray,
    target_class: int
) -> Dict[str, Any]:
    """
    Evaluates stable softmax cross-entropy loss and verifies the exact analytical gradient:
    dL / dz_i = q_i - p_i (linear non-saturating error signal).
    """
    # 1. Numerically stable softmax
    shifted_logits = logits - np.max(logits)
    exp_z = np.exp(shifted_logits)
    probs = exp_z / np.sum(exp_z)
    
    # 2. Cross-entropy loss
    loss = float(-np.log(np.clip(probs[target_class], 1e-15, 1.0)))
    
    # 3. Analytical gradient
    p_onehot = np.zeros_like(probs)
    p_onehot[target_class] = 1.0
    grad_analytical = probs - p_onehot
    
    # 4. Numerical gradient verification
    eps = 1e-6
    grad_numerical = np.zeros_like(logits)
    for i in range(len(logits)):
        z_plus = logits.copy()
        z_minus = logits.copy()
        z_plus[i] += eps
        z_minus[i] -= eps
        
        # Plus loss
        s_p = z_plus - np.max(z_plus)
        p_p = np.exp(s_p) / np.sum(np.exp(s_p))
        lp = -np.log(np.clip(p_p[target_class], 1e-15, 1.0))
        
        # Minus loss
        s_m = z_minus - np.max(z_minus)
        p_m = np.exp(s_m) / np.sum(np.exp(s_m))
        lm = -np.log(np.clip(p_m[target_class], 1e-15, 1.0))
        
        grad_numerical[i] = (lp - lm) / (2.0 * eps)
        
    rel_error = float(np.linalg.norm(grad_analytical - grad_numerical) / np.linalg.norm(grad_analytical))
    
    return {
        "probs": probs,
        "loss": loss,
        "grad_analytical": grad_analytical,
        "grad_numerical": grad_numerical,
        "gradient_rel_error": rel_error,
    }


def decompose_predictive_uncertainty(
    x_in_dist: float = 0.5,
    x_out_dist: float = 4.5,
    n_ensemble: int = 8
) -> Dict[str, Any]:
    """
    Decomposes total predictive variance into Aleatoric (noise) and Epistemic (ignorance).
    Demonstrates that epistemic variance explodes out-of-distribution (OOD).
    """
    rng = np.random.default_rng(2024)
    
    # Ground truth: y = 0.8 * x + noise, trained on [-2, 2]
    X_train = rng.uniform(-2.0, 2.0, 60)
    sigma_noise = 0.25
    y_train = 0.8 * X_train + rng.normal(0.0, sigma_noise, size=len(X_train))
    
    # Train bootstrap ensemble of models
    ensemble_slopes = []
    ensemble_intercepts = []
    for _ in range(n_ensemble):
        boot_idx = rng.choice(len(X_train), size=len(X_train), replace=True)
        slope, intercept = np.polyfit(X_train[boot_idx], y_train[boot_idx], deg=1)
        ensemble_slopes.append(slope)
        ensemble_intercepts.append(intercept)
        
    slopes = np.array(ensemble_slopes)
    intercepts = np.array(ensemble_intercepts)
    
    # Evaluate at in-distribution vs out-of-distribution
    preds_in = slopes * x_in_dist + intercepts
    preds_ood = slopes * x_out_dist + intercepts
    
    epistemic_in = float(np.var(preds_in, ddof=1))
    epistemic_ood = float(np.var(preds_ood, ddof=1))
    aleatoric_var = float(sigma_noise ** 2)
    
    return {
        "aleatoric_var": aleatoric_var,
        "epistemic_in": epistemic_in,
        "epistemic_ood": epistemic_ood,
        "ood_epistemic_inflation_ratio": epistemic_ood / max(epistemic_in, 1e-12),
    }


def sample_top_p_nucleus(
    logits: np.ndarray,
    temperature: float = 0.7,
    top_p: float = 0.9,
    seed: Optional[int] = 42
) -> Dict[str, Any]:
    """
    Simulates stochastic LLM token / agent action decoding:
    Applies temperature scaling followed by Top-p (Nucleus) cumulative probability truncation.
    """
    rng = np.random.default_rng(seed)
    
    # 1. Temperature scaling
    assert temperature > 0.0, "Temperature must be strictly positive"
    scaled_logits = logits / temperature
    
    # 2. Stable softmax
    shifted = scaled_logits - np.max(scaled_logits)
    probs = np.exp(shifted) / np.sum(np.exp(shifted))
    
    # 3. Sort descending
    sorted_indices = np.argsort(probs)[::-1]
    sorted_probs = probs[sorted_indices]
    
    # 4. Cumulative probability truncation (Nucleus)
    cum_probs = np.cumsum(sorted_probs)
    mask = cum_probs > top_p
    # Keep the first token that crosses the threshold
    mask[1:] = mask[:-1].copy()
    mask[0] = False
    
    nucleus_indices = sorted_indices[~mask]
    nucleus_probs = sorted_probs[~mask]
    # Re-normalize across nucleus candidate pool
    renormalized_probs = nucleus_probs / np.sum(nucleus_probs)
    
    # 5. Draw categorical sample
    chosen_token_idx = int(rng.choice(nucleus_indices, p=renormalized_probs))
    
    return {
        "raw_probs": probs,
        "nucleus_indices": nucleus_indices,
        "nucleus_probs": renormalized_probs,
        "chosen_token": chosen_token_idx,
        "nucleus_size": len(nucleus_indices),
        "total_vocab_size": len(logits),
    }


def main() -> None:
    print("=" * 80)
    print("  PROBABILITY AI/ML BRIDGE VERIFICATION HARNESS")
    print("=" * 80)
    
    # 1. Sequential Bayesian Conjugate Updating
    bayes = run_sequential_bayes_update(
        prior_mu=25.0, prior_sigma=10.0,
        true_theta=80.0, sensor_sigma=3.0,
        n_samples=100
    )
    print(f"\n[1] Continuous Gaussian Bayesian Updating (100 Sensor Samples):")
    print(f"    - Prior Distribution       : N({bayes['prior_mu']:.1f}, {bayes['prior_sigma']:.1f}^2)")
    print(f"    - Sample Mean (MLE)        : {bayes['sample_mean']:.4f}")
    print(f"    - Posterior Distribution   : N({bayes['posterior_mu']:.4f}, {bayes['posterior_sigma']:.4f}^2)")
    print(f"    - Discrepancy with MLE     : {bayes['discrepancy_with_mle']:.4f} (Asymptotically converges)")
    assert bayes['posterior_sigma'] < 0.5, "Posterior variance failed to shrink with N=100"
    assert bayes['discrepancy_with_mle'] < 0.5, "Posterior mean did not converge near sample mean"
    
    # 2. Information Theory Identity
    P = np.array([0.6, 0.3, 0.1])
    Q = np.array([0.5, 0.35, 0.15])
    info = compute_information_metrics(P, Q)
    print(f"\n[2] Information Theory Metrics & Fundamental Identity:")
    print(f"    - Shannon Entropy H(P)     : {info['entropy_P']:.6f} nats")
    print(f"    - Cross-Entropy H(P, Q)    : {info['cross_entropy_PQ']:.6f} nats")
    print(f"    - KL Divergence D_KL(P||Q) : {info['kl_divergence']:.6f} nats")
    print(f"    - Identity Error           : {info['identity_error']:.2e} (Strictly 0.0)")
    assert info['identity_error'] < 1e-12, "Information theory identity H(P,Q) = H(P) + D_KL failed"
    
    # 3. Softmax Cross-Entropy Gradient
    logits = np.array([3.0, 1.0, -1.0])
    target = 0
    grad_res = compute_softmax_cross_entropy_grad(logits, target_class=target)
    print(f"\n[3] Softmax Cross-Entropy Gradient (q - p):")
    print(f"    - Predicted Probabilities  : {grad_res['probs']}")
    print(f"    - Cross-Entropy Loss       : {grad_res['loss']:.4f}")
    print(f"    - Analytical Gradient      : {grad_res['grad_analytical']}")
    print(f"    - Gradient Relative Error  : {grad_res['gradient_rel_error']:.2e}")
    assert grad_res['gradient_rel_error'] < 1e-7, "Softmax cross-entropy gradient check failed"
    
    # 4. Aleatoric vs Epistemic Uncertainty Decomposition
    unc = decompose_predictive_uncertainty(x_in_dist=0.5, x_out_dist=4.5, n_ensemble=10)
    print(f"\n[4] Uncertainty Quantification (In-Distribution vs Out-of-Distribution):")
    print(f"    - Constant Aleatoric Noise : {unc['aleatoric_var']:.4f}")
    print(f"    - Epistemic Var (x = 0.5)  : {unc['epistemic_in']:.6f} (Low uncertainty)")
    print(f"    - Epistemic Var (x = 4.5)  : {unc['epistemic_ood']:.6f} (High OOD uncertainty)")
    print(f"    - Epistemic Inflation      : {unc['ood_epistemic_inflation_ratio']:.1f}x spike!")
    assert unc['epistemic_ood'] > 10.0 * unc['epistemic_in'], "Epistemic uncertainty failed to spike OOD"
    
    # 5. Stochastic Agent Sampling
    agent_logits = np.array([5.0, 4.2, 2.5, 0.5, -2.0, -5.0])
    sample_res = sample_top_p_nucleus(agent_logits, temperature=0.7, top_p=0.85, seed=123)
    print(f"\n[5] AI Agent Stochastic Nucleus Sampling (Top-p = 0.85, Temp = 0.7):")
    print(f"    - Total Vocabulary Size    : {sample_res['total_vocab_size']}")
    print(f"    - Nucleus Candidate Pool   : {sample_res['nucleus_indices']} (Size: {sample_res['nucleus_size']})")
    print(f"    - Nucleus Probabilities    : {sample_res['nucleus_probs']}")
    print(f"    - Chosen Sampled Action    : {sample_res['chosen_token']}")
    assert sample_res['nucleus_size'] < sample_res['total_vocab_size'], "Nucleus failed to truncate low tail"
    
    print("\n" + "=" * 80)
    print("  ALL PROBABILITY AI/ML BRIDGE TESTS PASSED (100% OPERATIONAL)")
    print("=" * 80)


if __name__ == "__main__":
    main()
