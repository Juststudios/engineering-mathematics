%% 05_bayesian_entropy_sampling.m - Probability AI/ML Bridge Companion
% =========================================================================
% MODULE: Probability & Uncertainty in Engineering (Concept 05)
%
% PURPOSE:
%   Demonstrates modern Artificial Intelligence mathematical foundations
%   implemented directly in MATLAB:
%   1. Continuous Gaussian-Gaussian Bayesian conjugate inference.
%   2. Information theory: Shannon Entropy, Cross-Entropy & KL Divergence.
%   3. Softmax Cross-Entropy non-saturating linear error gradients.
%   4. Predictive uncertainty decomposition: Aleatoric vs Epistemic variance.
%   5. Stochastic AI agent action sampling: Temperature scaling & Top-p.
%
% PEDAGOGICAL RATIONALE:
%   Connects classical probability distributions and noise filtering to
%   loss function formulation, uncertainty estimation, and LLM decoding.
% =========================================================================

function bayesian_entropy_sampling_demo()
    clc;
    close all;

    fprintf('=================================================================\n');
    fprintf('  PROBABILITY AI/ML BRIDGE: BAYES, ENTROPY & AGENT SAMPLING      \n');
    fprintf('=================================================================\n\n');

    %% Step 1: Continuous Gaussian Bayesian Conjugate Updating
    % Prior: theta ~ N(mu_0, sigma_0^2)
    mu_0 = 25.0;
    sigma_0 = 10.0;
    theta_true = 80.0;
    sigma_noise = 3.0;

    % Generate N noisy telemetry observations
    rng(42);
    N_obs = 100;
    x_samples = theta_true + sigma_noise * randn(N_obs, 1);
    x_bar = mean(x_samples);

    % Conjugate precision updating: tau_N = tau_0 + N * tau_noise
    tau_0 = 1.0 / (sigma_0^2);
    tau_noise = 1.0 / (sigma_noise^2);
    tau_N = tau_0 + N_obs * tau_noise;

    sigma_N = sqrt(1.0 / tau_N);
    mu_N = (tau_0 * mu_0 + N_obs * tau_noise * x_bar) / tau_N;

    fprintf('1. Continuous Gaussian Bayesian Updating:\n');
    fprintf('   Prior Distribution       : N(%.1f, %.1f^2)\n', mu_0, sigma_0);
    fprintf('   Sample Mean (MLE)        : %8.4f\n', x_bar);
    fprintf('   Posterior Distribution   : N(%.4f, %.4f^2)\n', mu_N, sigma_N);
    fprintf('   Posterior Std Shrinkage  : %8.2fx precision increase\n\n', sigma_0 / sigma_N);

    %% Step 2: Information Theory Metrics & Identity Verification
    % P: True distribution, Q: Model prediction
    P = [0.60; 0.30; 0.10];
    Q = [0.50; 0.35; 0.15];

    % Shannon Entropy: H(P) = -sum(P .* log(P))
    H_P = -sum(P .* log(P));

    % Cross-Entropy: H(P, Q) = -sum(P .* log(Q))
    H_PQ = -sum(P .* log(Q));

    % KL Divergence: D_KL(P || Q) = sum(P .* log(P ./ Q))
    D_KL = sum(P .* log(P ./ Q));

    identity_error = abs(H_PQ - (H_P + D_KL));

    fprintf('2. Information Theory Metrics:\n');
    fprintf('   Shannon Entropy H(P)     : %8.4f nats\n', H_P);
    fprintf('   Cross-Entropy H(P, Q)    : %8.4f nats\n', H_PQ);
    fprintf('   KL Divergence D_KL(P||Q) : %8.4f nats\n', D_KL);
    fprintf('   Identity Check Error     : %8.2e (Strictly zero)\n\n', identity_error);

    %% Step 3: Softmax Cross-Entropy Loss & Linear Gradient
    % Logits: z, True target class: 1 (one-hot: [1, 0, 0])
    logits = [3.0; 1.0; -1.0];
    target_class = 1;

    % Numerically stable softmax
    shifted_z = logits - max(logits);
    probs = exp(shifted_z) ./ sum(exp(shifted_z));

    loss_ce = -log(probs(target_class));

    % Analytical gradient: grad = q - p
    p_onehot = zeros(size(probs));
    p_onehot(target_class) = 1.0;
    grad_ce = probs - p_onehot;

    fprintf('3. Softmax Cross-Entropy Gradient:\n');
    fprintf('   Predicted Class Probs    : [%.4f, %.4f, %.4f]\n', probs(1), probs(2), probs(3));
    fprintf('   Cross-Entropy Loss       : %8.4f\n', loss_ce);
    fprintf('   Analytical Gradient (q-p): [%.4f, %.4f, %.4f]\n\n', grad_ce(1), grad_ce(2), grad_ce(3));

    %% Step 4: Predictive Uncertainty Decomposition (Aleatoric vs Epistemic)
    % Train an ensemble of polynomial fits on domain [-2, 2]
    X_train = linspace(-2.0, 2.0, 50)';
    Y_train = 0.8 * X_train + 0.25 * randn(size(X_train));

    n_ensemble = 6;
    ensemble_coeffs = zeros(n_ensemble, 2);
    for e_idx = 1:n_ensemble
        boot_idx = randi(length(X_train), length(X_train), 1);
        ensemble_coeffs(e_idx, :) = polyfit(X_train(boot_idx), Y_train(boot_idx), 1);
    end

    % Evaluate in-distribution (x = 0.5) vs out-of-distribution (x = 4.5)
    preds_in = polyval(ensemble_coeffs', 0.5);
    preds_ood = polyval(ensemble_coeffs', 4.5);

    var_epistemic_in = var(preds_in);
    var_epistemic_ood = var(preds_ood);

    fprintf('4. Uncertainty Quantification:\n');
    fprintf('   Epistemic Var (In-Dist x=0.5)  : %8.6f (High confidence)\n', var_epistemic_in);
    fprintf('   Epistemic Var (Out-Dist x=4.5) : %8.6f (Uncertainty explosion!)\n', var_epistemic_ood);
    fprintf('   OOD Epistemic Inflation Ratio  : %8.1fx\n\n', var_epistemic_ood / var_epistemic_in);

    %% Step 5: Stochastic Nucleus (Top-p) Sampling for Agents
    % Agent action logits over 5 candidate strategies
    agent_logits = [4.5; 3.8; 1.5; 0.2; -2.0];
    temp = 0.7;
    top_p = 0.85;

    % Temperature scaling
    scaled_z = agent_logits ./ temp;
    p_temp = exp(scaled_z - max(scaled_z)) ./ sum(exp(scaled_z - max(scaled_z)));

    % Sort descending
    [sorted_p, sort_idx] = sort(p_temp, 'descend');
    cum_p = cumsum(sorted_p);

    % Retain minimal set crossing top_p threshold
    nucleus_mask = false(size(sorted_p));
    nucleus_mask(1) = true;
    for k = 2:length(sorted_p)
        if cum_p(k - 1) < top_p
            nucleus_mask(k) = true;
        end
    end

    nucleus_indices = sort_idx(nucleus_mask);
    nucleus_probs = sorted_p(nucleus_mask) ./ sum(sorted_p(nucleus_mask));

    fprintf('5. AI Agent Stochastic Top-p Sampling:\n');
    fprintf('   Vocabulary Candidate Count     : %d\n', length(agent_logits));
    fprintf('   Nucleus Candidate Pool Count   : %d (Tail safely pruned)\n', length(nucleus_indices));
    fprintf('   Selected Candidate Indices     : %s\n', mat2str(nucleus_indices'));
    fprintf('   Re-normalized Nucleus Probs    : %s\n\n', mat2str(nucleus_probs', 3));

    fprintf('=================================================================\n');
    fprintf('  PROBABILITY AI/ML BRIDGE COMPLETED SUCCESSFULLY                \n');
    fprintf('=================================================================\n');
end
