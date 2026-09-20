# Engineering Mathematics & Computation: Foundations for Modern Engineering & AI

Welcome to **Engineering Mathematics & Computation**, the comprehensive Level 2 curriculum in our engineering education pipeline.

This course bridges foundational Python programming and numerical arrays (Level 1) to modern Machine Learning, Deep Neural Networks, Transformers, and Autonomous AI Agents (Level 3). It equips engineers and computer scientists with the mathematical machinery, physical intuition, and computational tools required to model dynamic systems, filter sensor noise, optimize multi-variable designs, and implement from-scratch AI algorithms.

---

## 1. Curriculum Architecture & Roadmap

The curriculum pipeline follows a progressive 3-level progression:

```
┌─────────────────────────────────────────────────────────────────────────┐
│ LEVEL 1: COMPUTATIONAL FOUNDATIONS                                      │
│ Python Syntax, NumPy Arrays, Pandas DataFrames, Matplotlib Visuals     │
└────────────────────────────────────┬────────────────────────────────────┘
                                     │
                                     ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ LEVEL 2: ENGINEERING MATHEMATICS & MATLAB (THIS PACKAGE)                 │
│                                                                         │
│  ┌───────────────────────┐   ┌───────────────────────┐                  │
│  │ MATLAB Fundamentals   │   │ Linear Algebra        │                  │
│  │ • Environment & Memory│   │ • Vectors & Spaces    │                  │
│  │ • Matrix vs Dot Ops   │   │ • Systems: A\b        │                  │
│  │ • Plotting Dashboards │   │ • Eigenvalues & Modes │                  │
│  └───────────┬───────────┘   └───────────┬───────────┘                  │
│              │                           │                              │
│  ┌───────────┴───────────┐   ┌───────────┴───────────┐                  │
│  │ Applied Calculus      │   │ Probability & Noise   │                  │
│  │ • Rates & Kinematics  │   │ • Distributions (PDF) │                  │
│  │ • Quadrature (trapz)  │   │ • Discrete/Cont Bayes │                  │
│  │ • ODEs (ode45)        │   │ • Moving Avg Filtering│                  │
│  └───────────┬───────────┘   └───────────┬───────────┘                  │
│              │                           │                              │
│  ┌───────────┴───────────┐   ┌───────────┴───────────┐                  │
│  │ Dynamic Simulink      │   │ Integrated Capstone   │                  │
│  │ • Block Diagrams      │   │ • Multi-Physics EV    │                  │
│  │ • Solvers & Feedback  │   │ • Power, Thermal, SNR │                  │
│  │ • RC & Thermal Models │   │ • 4-Panel Dashboard   │                  │
│  └───────────┬───────────┘   └───────────┬───────────┘                  │
│              │                           │                              │
│              └─────────────┬─────────────┘                              │
│                            │                                            │
│                            ▼                                            │
│              ┌───────────────────────────┐                              │
│              │   AI/ML MATHEMATIC BRIDGE │                              │
│              │ • High-D Embeddings & Attn│                              │
│              │ • Backprop & Adam Dynamics│                              │
│              │ • Entropy & Agent Sampling│                              │
│              └─────────────┬─────────────┘                              │
└────────────────────────────┼────────────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ LEVEL 3: MACHINE LEARNING, DEEP LEARNING & AI AGENTS                    │
│ Scikit-Learn, PyTorch, Transformers, LLMs, Tool-Calling Agents          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Module Directory & Syllabus

The repository is structured into modular learning directories:

| Module Directory | Primary Topics & Engineering Focus | Core Artifacts |
| :--- | :--- | :--- |
| [`matlab/`](matlab/) | Computational environment, 1-based indexing, row vs column vectors, matrix math (`*`) vs element-wise (`.*`), functions, 2D/3D visualization, Python/NumPy comparison. | `01_environment_and_variables.m` to `06_python_numpy_bridge.m`, `exercises.m`, `mini_project_signal_calc.m` |
| [`linear_algebra/`](linear_algebra/) | Vectors, norms ($L_1, L_2, L_\infty$), projections, matrix transformations (rot, scale, shear), systems solving ($A\mathbf{x} = \mathbf{b}$, `x = A\b`), condition numbers, eigenvalues/eigenvectors, truss analysis, and AI Bridge (embeddings, attention, SVD/LoRA). | `01_vectors_and_spaces.m` to `07_ai_ml_linear_algebra_bridge.md`, `07_embeddings_attention_svd.py`, `exercises.m` |
| [`calculus/`](calculus/) | Rates of change, truncation errors ($O(h)$ vs $O(h^2)$), numerical quadrature (`trapz`), 1st-order differential equations (`ode45`), thermal dissipation, and AI Bridge (multivariable gradients, Jacobians, Hessians, backprop, Adam). | `01_derivatives_and_rates.m` to `05_ai_ml_calculus_bridge.md`, `05_optimization_gradients_backprop.py`, `exercises.m` |
| [`probability/`](probability/) | Random variables, continuous/discrete PDFs & CDFs, moments (mean, variance, Bessel's $N-1$), Gaussian distributions, discrete/continuous Bayes, Monte Carlo methods, digital noise filtering, and AI Bridge (entropy, KL, epistemic uncertainty, nucleus sampling). | `01_probability_foundations.m` to `05_ai_ml_probability_bridge.md`, `05_bayesian_entropy_sampling.py`, `exercises.m` |
| [`simulink/`](simulink/) | Graphical dynamic modeling, signal flow, solvers (Euler vs Runge-Kutta), feedback loops, and script companions for RC circuits, thermal cooling, and DC motors. | `01_block_diagram_basics.md`, `02_solvers_and_simulation.md`, companion `.m` scripts, models, `exercises.m` |
| [`capstone/`](capstone/) | Multi-physics Electric Vehicle (EV) powertrain telemetry analysis pipeline: ingesting 10 Hz real telemetry, computing mechanical/electrical power flows, numerical energy integration, digital filtering, and thermal rate evaluation. | [`README.md`](capstone/README.md), `capstone_analysis_template.m`, `capstone_analysis_complete.m`, data generators |
| [`ml_bridge/`](ml_bridge/) | Central synthesis bridging Linear Algebra, Calculus, and Probability directly into modern AI architectures, Transformers, and LLM Agents. | [`README.md`](ml_bridge/README.md) |
| [`reference/`](reference/) | Concise, high-density quick-reference cheat sheets for all core domains. | [`matlab_cheat_sheet.md`](reference/matlab_cheat_sheet.md), [`linear_algebra_cheat_sheet.md`](reference/linear_algebra_cheat_sheet.md), [`calculus_cheat_sheet.md`](reference/calculus_cheat_sheet.md), [`probability_cheat_sheet.md`](reference/probability_cheat_sheet.md) |
| [`assessments/`](assessments/) | Rigorous 100-point final assessment and diagnostic evaluation rubric. | [`FINAL_ASSESSMENT.md`](assessments/FINAL_ASSESSMENT.md), [`RUBRIC.md`](assessments/RUBRIC.md) |
| [`solutions/`](solutions/) | Complete, fully resolved reference implementations for all module exercises and capstone challenges with zero remaining `% TODO` markers. | `matlab_exercises_solution.m`, `linear_algebra_exercises_solution.m`, `calculus_exercises_solution.m`, `probability_exercises_solution.m`, `simulink_exercises_solution.m`, `capstone_solution.m` |

---

## 3. Pedagogical Standard

Every concept in this curriculum is designed under two non-negotiable pedagogical standards:

### 1. "Explain WHY Before HOW"
Before presenting formulas or code, lessons establish:
1. **The Real Engineering Problem**: Why does an electrical, aerospace, or software engineer encounter this challenge?
2. **The Intuitive Mental Model**: A geometric, physical, or visual intuition devoid of impenetrable notation.
3. **The Governing Mathematics**: Precise algebraic definitions and boundary conditions.
4. **The Computational Implementation**: Idiomatic MATLAB or Python/NumPy code.
5. **The Engineering Interpretation**: Translating numbers into real design decisions.

### 2. The 6-Element Structured Learning Pattern
All new instructional lessons strictly follow:
`TERM -> DEFINITION -> INTUITION -> WHY IT EXISTS -> HOW IT WORKS -> CODE`

### 3. The 4-Tier Progressive Exercise Model
Every module contains an `exercises.m` workbook structured into four progressive skill tiers:
- **Tier 1: Recall**: Direct reproduction of foundational formulas, syntax, and operator definitions.
- **Tier 2: Understanding & Debugging**: Diagnosing and rectifying real-world computational errors (dimension mismatches, ill-conditioning, array length drops, indexing violations).
- **Tier 3: Application**: Multi-step engineering implementations solving complete physical subsystems (circuits, thermal heatsinks, vehicle braking).
- **Tier 4: Challenge**: Open-ended, high-rigor design problems combining multiple mathematical principles with real-world physical constraints.

---

## 4. Environment Setup & Verification

### Prerequisites
- Python 3.9+ with `numpy`, `scipy`, `matplotlib`, `pytest`
- MATLAB R2022b+ or GNU Octave (for `.m` script execution)
  - *Note: All AI/ML bridge scripts include pure-NumPy runnable companions that execute standalone without requiring MATLAB!*

### Installation
```bash
cd /home/settings/Documents/pearl/engineering-mathematics
pip install -r requirements.txt
```

### Running Automated Package Verification
The repository includes a zero-proprietary-dependency automated audit harness (`scripts/verify_package.py`) that checks:
- Directory structure, file existence, and minimum content size thresholds
- Markdown relative links, anchor slugs, and cross-references
- MATLAB syntax (block balancing, delimiter matching, 0-based indexing detection, comment ratios)
- 4-Tier exercise structures and decoupled solution completeness
- Capstone telemetry CSV schema integrity

To verify the entire package:
```bash
python3 scripts/verify_package.py
```
Expected output:
```text
>>> VERIFICATION STATUS: SUCCESS (Package meets specification)
```

To run individual module verifications:
```bash
python3 scripts/verify_package.py --module linear_algebra
python3 scripts/verify_package.py --module calculus
python3 scripts/verify_package.py --module probability
```

### Running Pytest Test Suite
```bash
pytest tests/ -v
```

### Executing Standalone Python AI/ML Bridge Scripts
```bash
# Linear Algebra -> ML (Embeddings, Orthogonal Projections, SVD/LoRA, Attention)
python3 linear_algebra/07_embeddings_attention_svd.py

# Calculus -> ML (Gradients, Jacobians, Hessians, Backpropagation, Adam)
python3 calculus/05_optimization_gradients_backprop.py

# Probability -> ML (Continuous Bayes, Entropy/KL, Epistemic Uncertainty, Top-p Sampling)
python3 probability/05_bayesian_entropy_sampling.py
```
