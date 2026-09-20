%% 07_embeddings_attention_svd.m - Linear Algebra AI/ML Bridge Companion
% =========================================================================
% MODULE: Linear Algebra for Engineers & Machine Learning (Concept 07)
%
% PURPOSE:
%   Demonstrates modern Artificial Intelligence mathematical foundations
%   implemented directly in MATLAB:
%   1. High-dimensional vector embedding geometry & near-orthogonality.
%   2. Orthogonal projection operators and error subspace decomposition.
%   3. Truncated SVD matrix compression & Low-Rank Adaptation (LoRA).
%   4. Scaled Dot-Product Attention mechanism with numerically stable softmax.
%
% PEDAGOGICAL RATIONALE:
%   Connects classical matrix operations (inner products, SVD, projectors)
%   to the computational machinery of modern Transformers and LLMs.
% =========================================================================

function embeddings_attention_svd_demo()
    clc;
    close all;

    fprintf('=================================================================\n');
    fprintf('  LINEAR ALGEBRA AI/ML BRIDGE: EMBEDDINGS, ATTENTION & SVD       \n');
    fprintf('=================================================================\n\n');

    %% Step 1: High-Dimensional Vector Geometry (Near-Orthogonality)
    % Compare random unit vectors in low dimensions (d=3) vs high dimensions (d=768)
    rng(42);
    N_pairs = 1000;

    % Low-dimensional space (d = 3)
    d_low = 3;
    u_low = randn(N_pairs, d_low);
    u_low = u_low ./ sqrt(sum(u_low.^2, 2)); % Normalize to unit sphere
    v_low = randn(N_pairs, d_low);
    v_low = v_low ./ sqrt(sum(v_low.^2, 2));
    cos_low = sum(u_low .* v_low, 2);

    % High-dimensional space (d = 768, standard BERT/Transformer embedding size)
    d_high = 768;
    u_high = randn(N_pairs, d_high);
    u_high = u_high ./ sqrt(sum(u_high.^2, 2));
    v_high = randn(N_pairs, d_high);
    v_high = v_high ./ sqrt(sum(v_high.^2, 2));
    cos_high = sum(u_high .* v_high, 2);

    fprintf('1. High-Dimensional Vector Geometry:\n');
    fprintf('   Mean |cos(theta)| in 3D   : %8.4f\n', mean(abs(cos_low)));
    fprintf('   Mean |cos(theta)| in 768D : %8.4f (Near-orthogonality holds!)\n', mean(abs(cos_high)));
    fprintf('   Empirical Std in 768D     : %8.4f\n', std(cos_high));
    fprintf('   Theoretical 1/sqrt(d)     : %8.4f\n\n', 1.0 / sqrt(d_high));

    %% Step 2: Orthogonal Projection & Subspace Decomposition
    % Construct projection matrix P = X * (X' * X)^(-1) * X'
    m_obs = 100;
    n_feat = 4;
    X = randn(m_obs, n_feat);
    y = randn(m_obs, 1);

    % Orthogonal projection operator
    P = X * ((X' * X) \ X');

    % Verify Idempotence: P^2 == P
    P_idemp_err = norm(P * P - P, 'fro');

    % Verify Symmetry: P' == P
    P_symm_err = norm(P' - P, 'fro');

    % Project observation y onto Col(X)
    y_hat = P * y;
    residual = y - y_hat;

    % Verify residual orthogonality: X' * residual == 0
    orthog_err = max(abs(X' * residual));

    fprintf('2. Orthogonal Projection Properties:\n');
    fprintf('   Idempotence Error ||P^2 - P||_F : %8.2e\n', P_idemp_err);
    fprintf('   Symmetry Error ||P^T - P||_F    : %8.2e\n', P_symm_err);
    fprintf('   Orthogonality Error |X^T e|     : %8.2e\n\n', orthog_err);

    %% Step 3: Singular Value Decomposition (SVD) & LoRA Reparameterization
    % Decompose weight matrix and simulate Low-Rank Adaptation (LoRA)
    d_model = 512;
    r_lora  = 8; % Low-rank bottleneck dimension

    W0 = randn(d_model, d_model) * 0.02;

    % Economy SVD
    [U, S, V] = svd(W0, 'econ');
    s_vals = diag(S);

    % Optimal rank-r truncated SVD approximation (Eckart-Young)
    W_truncated = U(:, 1:r_lora) * S(1:r_lora, 1:r_lora) * (V(:, 1:r_lora)');
    svd_recon_err = norm(W0 - W_truncated, 'fro');

    % LoRA adapter construction: Delta_W = (alpha / r) * B * A
    % A initialized with Gaussian scaling, B initialized with exact zeros
    A_lora = randn(r_lora, d_model) * (1.0 / sqrt(d_model));
    B_lora = zeros(d_model, r_lora);
    alpha_lora = 16.0;

    base_params = d_model * d_model;
    lora_params = (d_model * r_lora) + (r_lora * d_model);
    param_savings = (1.0 - (lora_params / base_params)) * 100.0;

    fprintf('3. SVD Compression & LoRA Adaptation:\n');
    fprintf('   Original Parameter Count        : %d\n', base_params);
    fprintf('   LoRA Adapter Parameter Count    : %d\n', lora_params);
    fprintf('   Parameter Reduction Ratio       : %8.2f%%\n', param_savings);
    fprintf('   Truncated SVD Frobenius Error   : %8.4f\n\n', svd_recon_err);

    %% Step 4: Scaled Dot-Product Attention Mechanism
    % Attention(Q, K, V) = softmax(Q * K' / sqrt(d_k)) * V
    seq_len = 6;
    d_k     = 64;
    d_v     = 64;

    Q = randn(seq_len, d_k);
    K = randn(seq_len, d_k);
    V = randn(seq_len, d_v);

    % Step 4.1: Compute scaled dot-product scores
    scaling_factor = sqrt(d_k);
    scores = (Q * K') / scaling_factor;

    % Step 4.2: Numerically stable row-wise softmax
    scores_max = max(scores, [], 2);
    exp_scores = exp(scores - scores_max);
    attn_weights = exp_scores ./ sum(exp_scores, 2);

    % Step 4.3: Aggregate contextual values
    context_output = attn_weights * V;

    fprintf('4. Scaled Dot-Product Attention:\n');
    fprintf('   Sequence Length                 : %d tokens\n', seq_len);
    fprintf('   Head Dimension (d_k)            : %d\n', d_k);
    fprintf('   Max Row Sum Deviation from 1.0  : %8.2e\n', max(abs(sum(attn_weights, 2) - 1.0)));
    fprintf('   Context Output Matrix Norm      : %8.4f\n\n', norm(context_output, 'fro'));

    fprintf('=================================================================\n');
    fprintf('  LINEAR ALGEBRA AI/ML BRIDGE COMPLETED SUCCESSFULLY             \n');
    fprintf('=================================================================\n');
end
