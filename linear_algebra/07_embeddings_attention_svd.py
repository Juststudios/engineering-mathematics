#!/usr/bin/env python3
"""
================================================================================
LINEAR ALGEBRA AI/ML BRIDGE: EMBEDDINGS, ATTENTION, PROJECTIONS & SVD
================================================================================
Zero-Dependency Pure-NumPy Implementation demonstrating:
1. High-Dimensional Embedding Geometry & Near-Orthogonality
2. Orthogonal Projection Operator (Idempotence, Symmetry, Residual Orthogonality)
3. SVD Matrix Truncation & Low-Rank Adaptation (LoRA) Reparameterization
4. Scaled Dot-Product Attention & Multi-Head Attention Layer from Scratch
================================================================================
"""

import numpy as np
from typing import Dict, Tuple, Optional


def analyze_high_dim_geometry(d_low: int = 3, d_high: int = 768, n_samples: int = 2000) -> Dict[str, float]:
    """
    Demonstrates the geometric curse/blessing of dimensionality:
    Uniform random unit vectors in high dimensions are nearly orthogonal.
    """
    rng = np.random.default_rng(42)
    
    # Generate random unit vectors in low dimensions
    u_low = rng.standard_normal((n_samples, d_low))
    u_low /= np.linalg.norm(u_low, axis=1, keepdims=True)
    v_low = rng.standard_normal((n_samples, d_low))
    v_low /= np.linalg.norm(v_low, axis=1, keepdims=True)
    cos_low = np.sum(u_low * v_low, axis=1)
    
    # Generate random unit vectors in high dimensions
    u_high = rng.standard_normal((n_samples, d_high))
    u_high /= np.linalg.norm(u_high, axis=1, keepdims=True)
    v_high = rng.standard_normal((n_samples, d_high))
    v_high /= np.linalg.norm(v_high, axis=1, keepdims=True)
    cos_high = np.sum(u_high * v_high, axis=1)
    
    return {
        "d_low": float(d_low),
        "d_high": float(d_high),
        "mean_abs_cos_low": float(np.mean(np.abs(cos_low))),
        "mean_abs_cos_high": float(np.mean(np.abs(cos_high))),
        "std_cos_high": float(np.std(cos_high)),
        "theoretical_std_high": float(1.0 / np.sqrt(d_high)),
    }


def compute_orthogonal_projection(X: np.ndarray, y: np.ndarray) -> Dict[str, Any]:
    """
    Constructs the orthogonal projection operator P = X (X^T X)^(-1) X^T
    and verifies fundamental linear algebraic invariance properties.
    """
    m, n = X.shape
    assert m >= n, "Row dimension m must be >= column dimension n"
    
    # Projection matrix P
    XtX = X.T @ X
    XtX_inv = np.linalg.inv(XtX)
    P = X @ XtX_inv @ X.T
    
    # Verify idempotence: P^2 == P
    P_sq = P @ P
    idempotence_error = float(np.linalg.norm(P_sq - P, ord='fro'))
    
    # Verify symmetry: P^T == P
    symmetry_error = float(np.linalg.norm(P.T - P, ord='fro'))
    
    # Project y onto Col(X)
    y_hat = P @ y
    residual = y - y_hat
    
    # Verify residual orthogonality: X^T (y - y_hat) == 0
    orthogonality_error = float(np.max(np.abs(X.T @ residual)))
    
    # Compute least squares weights directly: w = (X^T X)^(-1) X^T y
    w = XtX_inv @ X.T @ y
    direct_y_hat = X @ w
    equivalence_error = float(np.linalg.norm(y_hat - direct_y_hat))
    
    return {
        "P": P,
        "y_hat": y_hat,
        "residual": residual,
        "weights": w,
        "idempotence_error": idempotence_error,
        "symmetry_error": symmetry_error,
        "orthogonality_error": orthogonality_error,
        "equivalence_error": equivalence_error,
    }


def simulate_svd_and_lora(d_in: int = 1024, d_out: int = 1024, rank: int = 8) -> Dict[str, Any]:
    """
    Simulates matrix compression via Truncated SVD and Low-Rank Adaptation (LoRA).
    """
    rng = np.random.default_rng(101)
    
    # Base weight matrix with exponential singular value spectrum decay
    W0 = rng.standard_normal((d_out, d_in)) * 0.02
    U, s, Vt = np.linalg.svd(W0, full_matrices=False)
    
    # Optimal rank-k SVD approximation (Eckart-Young)
    W_svd_k = (U[:, :rank] * s[:rank]) @ Vt[:rank, :]
    svd_frobenius_error = float(np.linalg.norm(W0 - W_svd_k, ord='fro'))
    
    # LoRA Adapter construction: Delta W = (alpha / r) * B @ A
    # A is Gaussian initialized, B is initialized to zeros
    A = rng.standard_normal((rank, d_in)) * (1.0 / np.sqrt(d_in))
    B = np.zeros((d_out, rank))
    alpha = 16.0
    
    # Initial forward pass with zero Delta W
    x = rng.standard_normal((4, d_in))  # batch of 4 token vectors
    h_base = x @ W0.T
    h_lora_init = h_base + (alpha / rank) * ((x @ A.T) @ B.T)
    initial_divergence = float(np.linalg.norm(h_base - h_lora_init))
    
    # Parameter counts
    base_params = d_out * d_in
    lora_params = (d_out * rank) + (rank * d_in)
    reduction_pct = float((1.0 - lora_params / base_params) * 100.0)
    
    return {
        "base_params": base_params,
        "lora_params": lora_params,
        "reduction_pct": reduction_pct,
        "svd_frobenius_error": svd_frobenius_error,
        "initial_divergence": initial_divergence,
        "rank": rank,
    }


def scaled_dot_product_attention(
    Q: np.ndarray,
    K: np.ndarray,
    V: np.ndarray,
    mask: Optional[np.ndarray] = None
) -> Tuple[np.ndarray, np.ndarray]:
    """
    Vectorized Scaled Dot-Product Attention:
    Attention(Q, K, V) = softmax(Q K^T / sqrt(d_k)) V
    """
    d_k = Q.shape[-1]
    
    # 1. Scaled dot-product scores
    scores = (Q @ K.swapaxes(-1, -2)) / np.sqrt(float(d_k))
    
    # Optional mask (e.g. causal attention or padding)
    if mask is not None:
        scores = np.where(mask == 0, -1e9, scores)
    
    # 2. Numerically stable softmax along last axis
    scores_max = np.max(scores, axis=-1, keepdims=True)
    exp_scores = np.exp(scores - scores_max)
    weights = exp_scores / np.sum(exp_scores, axis=-1, keepdims=True)
    
    # 3. Aggregate values
    context = weights @ V
    return context, weights


def multi_head_attention_layer(
    X: np.ndarray,
    d_model: int = 128,
    num_heads: int = 4
) -> Tuple[np.ndarray, np.ndarray]:
    """
    Pure NumPy Multi-Head Attention layer with projection weights.
    X: (batch_size, seq_len, d_model)
    """
    assert d_model % num_heads == 0, "d_model must be divisible by num_heads"
    d_k = d_model // num_heads
    batch_size, seq_len, _ = X.shape
    
    rng = np.random.default_rng(2024)
    # Projection weight matrices
    W_q = rng.standard_normal((d_model, d_model)) / np.sqrt(d_model)
    W_k = rng.standard_normal((d_model, d_model)) / np.sqrt(d_model)
    W_v = rng.standard_normal((d_model, d_model)) / np.sqrt(d_model)
    W_o = rng.standard_normal((d_model, d_model)) / np.sqrt(d_model)
    
    # Linear projections
    Q = X @ W_q
    K = X @ W_k
    V = X @ W_v
    
    # Split into heads: (batch_size, num_heads, seq_len, d_k)
    Q_heads = Q.reshape(batch_size, seq_len, num_heads, d_k).swapaxes(1, 2)
    K_heads = K.reshape(batch_size, seq_len, num_heads, d_k).swapaxes(1, 2)
    V_heads = V.reshape(batch_size, seq_len, num_heads, d_k).swapaxes(1, 2)
    
    # Execute attention across all heads simultaneously
    context_heads, weights = scaled_dot_product_attention(Q_heads, K_heads, V_heads)
    
    # Recombine heads: (batch_size, seq_len, d_model)
    context = context_heads.swapaxes(1, 2).reshape(batch_size, seq_len, d_model)
    
    # Output projection
    output = context @ W_o
    return output, weights


def main() -> None:
    print("=" * 80)
    print("  LINEAR ALGEBRA AI/ML BRIDGE VERIFICATION HARNESS")
    print("=" * 80)
    
    # 1. High-Dimensional Geometry
    geo = analyze_high_dim_geometry(d_low=3, d_high=768, n_samples=2000)
    print(f"\n[1] High-Dimensional Vector Geometry:")
    print(f"    - Mean |cos(theta)| in {int(geo['d_low'])}D   : {geo['mean_abs_cos_low']:.4f}")
    print(f"    - Mean |cos(theta)| in {int(geo['d_high'])}D : {geo['mean_abs_cos_high']:.4f}")
    print(f"    - Empirical std in {int(geo['d_high'])}D     : {geo['std_cos_high']:.4f}")
    print(f"    - Theoretical 1/sqrt(d)       : {geo['theoretical_std_high']:.4f}")
    assert geo['mean_abs_cos_high'] < 0.05, "High-D vectors failed near-orthogonality check"
    
    # 2. Orthogonal Projection Operator
    rng = np.random.default_rng(7)
    X = rng.standard_normal((100, 5))
    y = rng.standard_normal(100)
    proj = compute_orthogonal_projection(X, y)
    print(f"\n[2] Orthogonal Projection Operator (100x5 feature matrix):")
    print(f"    - Idempotence Error ||P^2 - P||_F : {proj['idempotence_error']:.2e}")
    print(f"    - Symmetry Error ||P^T - P||_F    : {proj['symmetry_error']:.2e}")
    print(f"    - Max Orthogonal Residual |X^T e| : {proj['orthogonality_error']:.2e}")
    print(f"    - Direct LS Equivalence Error     : {proj['equivalence_error']:.2e}")
    assert proj['idempotence_error'] < 1e-10, "Projection failed idempotence test"
    assert proj['symmetry_error'] < 1e-10, "Projection failed symmetry test"
    assert proj['orthogonality_error'] < 1e-10, "Residual failed orthogonality test"
    
    # 3. SVD & LoRA
    lora = simulate_svd_and_lora(d_in=1024, d_out=1024, rank=8)
    print(f"\n[3] SVD & LoRA Weight Adaptation (1024x1024 layer, rank=8):")
    print(f"    - Original Parameters             : {lora['base_params']:,}")
    print(f"    - LoRA Adapter Parameters         : {lora['lora_params']:,}")
    print(f"    - Parameter Reduction             : {lora['reduction_pct']:.2f}%")
    print(f"    - Initial Behavioral Divergence   : {lora['initial_divergence']:.2e} (Strictly 0.0)")
    assert lora['reduction_pct'] > 98.0, "LoRA parameter reduction below expected threshold"
    assert lora['initial_divergence'] < 1e-12, "LoRA zero initialization failed"
    
    # 4. Scaled Dot-Product & Multi-Head Attention
    batch_size, seq_len, d_model, num_heads = 2, 8, 128, 4
    X_tokens = rng.standard_normal((batch_size, seq_len, d_model))
    mha_out, attn_weights = multi_head_attention_layer(X_tokens, d_model=d_model, num_heads=num_heads)
    row_sums = np.sum(attn_weights, axis=-1)
    print(f"\n[4] Multi-Head Attention Layer (Batch={batch_size}, SeqLen={seq_len}, Heads={num_heads}, Dim={d_model}):")
    print(f"    - Output Activation Tensor Shape  : {mha_out.shape}")
    print(f"    - Attention Weights Tensor Shape  : {attn_weights.shape}")
    print(f"    - Max Deviation in Softmax Sum    : {np.max(np.abs(row_sums - 1.0)):.2e}")
    assert np.allclose(row_sums, 1.0, atol=1e-12), "Attention weights do not sum to 1.0"
    assert mha_out.shape == (batch_size, seq_len, d_model), "Attention output shape mismatch"
    
    print("\n" + "=" * 80)
    print("  ALL LINEAR ALGEBRA AI/ML BRIDGE TESTS PASSED (100% OPERATIONAL)")
    print("=" * 80)


if __name__ == "__main__":
    from typing import Any
    main()
