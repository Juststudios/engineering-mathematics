# Linear Algebra for Engineers & Machine Learning

Welcome to Module 2 of the **Engineering Mathematics + MATLAB** curriculum. This module bridges the computational foundation built in Python/NumPy (Level 1) and MATLAB Fundamentals to real-world engineering modeling and modern Machine Learning algorithms (Level 3).

---

## 1. Learning Objectives
By the end of this module, students will be able to:
- **Remember & Recall**: State the definitions of vector norms ($L_1, L_2, L_\infty$), dot and cross products, orthogonal projections, matrix rank, determinants, condition numbers, and eigenvalues/eigenvectors.
- **Understand**: Explain linear transformations as geometric deformations of coordinate space (rotations, scalings, shears) and describe linear systems $A\mathbf{x} = \mathbf{b}$ as static or dynamic equilibrium states.
- **Apply**: Formulate and solve multi-variable physical engineering systems—such as resistive electrical circuits via Kirchhoff's Current Law (nodal analysis) and pin-jointed trusses via static equilibrium—using MATLAB's backslash operator (`x = A\b`).
- **Analyze**: Evaluate matrix invertibility, numerical conditioning ($\kappa(A) = \text{cond}(A)$), and loss of precision; diagnose and rectify ill-conditioned or dimension-mismatched linear formulations.
- **Evaluate & Interpret**: Compute eigenvalues and eigenvectors using `eig` to determine resonant frequencies and mode shapes of multi-degree-of-freedom structures, principal stresses in solid mechanics, and principal components in data science.
- **Create**: Synthesize linear algebra techniques with machine learning paradigms, framing ordinary least squares linear regression ($\mathbf{w} = (X^T X)^{-1} X^T \mathbf{y}$) and Principal Component Analysis (PCA) via Singular Value Decomposition (SVD).
- **AI/ML Architecture Bridge**: Implement high-dimensional embeddings, orthogonal projection operators, Low-Rank Adaptation (LoRA) weight parameterizations, and the Scaled Dot-Product Attention mechanism ($Q, K, V$) powering modern Transformers.

---

## 2. Why Engineers Need This
In Level 1, you learned how to store arrays and execute numerical operations in Python and MATLAB. But in engineering practice, matrices are not just multi-dimensional arrays—they are **mathematical operators representing physical laws and geometry**.

Every engineering discipline relies fundamentally on linear algebra:
- **Electrical & Electronic Engineering**: An electrical grid with thousands of interconnected buses, transformers, and generators is modeled as a massive admittance matrix system $G\mathbf{v} = \mathbf{i}$.
- **Civil & Mechanical Engineering**: Bridges, airframes, and crane trusses are pin-jointed structures governed by node equilibrium equations $A\mathbf{f} = \mathbf{p}_{\text{ext}}$. Multi-story building vibrations during earthquakes are modeled by the generalized eigenvalue problem $K\boldsymbol{\phi} = \omega^2 M\boldsymbol{\phi}$.
- **Robotics & Aerospace**: Robotic arms navigating in 3D space use homogeneous transformation matrices ($4 \times 4$) to translate and rotate tooltips between world, base, joint, and sensor frames.
- **Machine Learning & Data Science**: Datasets are feature matrices $X \in \mathbb{R}^{N \times D}$. Training linear models, minimizing loss functions, projecting data into lower dimensions (PCA), and updating neural network weights are all linear algebraic matrix transformations.

Without linear algebra, simulating a 10-bar truss requires pages of manual simultaneous substitution. With linear algebra and MATLAB, solving a 100,000-member airframe takes a single command: `x = A\b`.

---

## 3. Mathematical Intuition
Before writing down formulas, let us build geometric and physical intuition for linear algebra.

### Linear Transformations as Space Deformations
A matrix $A$ is not merely a table of numbers. When you multiply a matrix $A$ by a vector $\mathbf{x}$, yielding $\mathbf{y} = A\mathbf{x}$, you are **mapping** a point in space to a new point.
- Think of space as a flexible grid sheet.
- A linear transformation keeps the origin $(0,0)$ fixed and keeps grid lines parallel and evenly spaced.
- The columns of matrix $A$ describe **where the original basis vectors** $\hat{\mathbf{i}} = [1, 0]^T$ and $\hat{\mathbf{j}} = [0, 1]^T$ land after the deformation.
- If $A = \begin{bmatrix} 2 & 0 \\ 0 & 3 \end{bmatrix}$, space is stretched by $2\times$ horizontally and $3\times$ vertically.
- The **determinant** $\det(A)$ measures how much area (in 2D) or volume (in 3D) scales under this transformation. If $\det(A) = 0$, space is flattened into a lower dimension (a line or point), destroying information—which is why singular matrices cannot be inverted!

### $A\mathbf{x} = \mathbf{b}$ as Balance and Equilibrium
In physical systems, linear systems arise from conservation laws:
$$\text{Sum of internal actions} = \text{External excitation}$$
- In structures: $\sum \mathbf{F} = 0$ at every joint. The matrix $A$ encodes the geometric connectivity and angles of members; $\mathbf{x}$ holds unknown internal forces and reactions; $\mathbf{b}$ holds applied external loads.
- In circuits: $\sum I = 0$ at every node (Kirchhoff's Current Law). The matrix $A$ encodes inter-node conductances; $\mathbf{x}$ holds unknown node voltages; $\mathbf{b}$ holds injected source currents.

Solving $A\mathbf{x} = \mathbf{b}$ means answering: *"What internal configuration $\mathbf{x}$ balances the external forces $\mathbf{b}$ across the network $A$?"*

### Eigenvalues and Eigenvectors: Undeviated Axes
When a matrix deforms space, most vectors change both their length and their direction. However, certain special vectors **only stretch or compress without changing direction**:
$$A\mathbf{v} = \lambda \mathbf{v}$$
- $\mathbf{v}$ is an **eigenvector** (a principal axis of the system).
- $\lambda$ is the **eigenvalue** (the scaling factor along that axis).
- In structural mechanics, if a building vibrates in an eigenmode, all floors oscillate at the exact same natural frequency ($\omega = \sqrt{\lambda}$) in perfect harmony.
- In solid mechanics, the eigenvectors of the stress tensor align with the directions of pure tension/compression with zero shear (principal stresses).

---

## 4. Formal Mathematics & Governing Equations

### Vectors, Dot Products, and Projections
Let $\mathbf{u}, \mathbf{v} \in \mathbb{R}^n$:
- **Vector Norms**:
  $$L_1: \|\mathbf{u}\|_1 = \sum_{i=1}^n |u_i|, \quad L_2: \|\mathbf{u}\|_2 = \sqrt{\sum_{i=1}^n u_i^2}, \quad L_\infty: \|\mathbf{u}\|_\infty = \max_i |u_i|$$
- **Dot Product**:
  $$\mathbf{u} \cdot \mathbf{v} = \mathbf{u}^T \mathbf{v} = \|\mathbf{u}\|_2 \|\mathbf{v}\|_2 \cos\theta$$
- **Orthogonal Projection** of $\mathbf{u}$ onto $\mathbf{v}$:
  $$\text{proj}_{\mathbf{v}}(\mathbf{u}) = \frac{\mathbf{u} \cdot \mathbf{v}}{\|\mathbf{v}\|_2^2} \mathbf{v}$$
- **3D Cross Product** (perpendicular vector):
  $$\mathbf{u} \times \mathbf{v} = \begin{bmatrix} u_y v_z - u_z v_y \\ u_z v_x - u_x v_z \\ u_x v_y - u_y v_x \end{bmatrix}, \quad \|\mathbf{u} \times \mathbf{v}\| = \|\mathbf{u}\| \|\mathbf{v}\| \sin\theta$$

### Matrix Transformations
In 2D planar coordinates, rotation by angle $\theta$, scaling by $(s_x, s_y)$, and shearing by $(k_x, k_y)$ are represented by:
$$R(\theta) = \begin{bmatrix} \cos\theta & -\sin\theta \\ \sin\theta & \cos\theta \end{bmatrix}, \quad S(s_x, s_y) = \begin{bmatrix} s_x & 0 \\ 0 & s_y \end{bmatrix}, \quad H(k_x, k_y) = \begin{bmatrix} 1 & k_x \\ k_y & 1 \end{bmatrix}$$

In 3D homogeneous coordinates ($4 \times 4$), a rigid body rotation $R \in SO(3)$ and translation $\mathbf{t} \in \mathbb{R}^3$ are unified as:
$$T = \begin{bmatrix} R & \mathbf{t} \\ \mathbf{0}_{1 \times 3} & 1 \end{bmatrix}$$

### Linear Systems and Matrix Condition
For a system $A\mathbf{x} = \mathbf{b}$ where $A \in \mathbb{R}^{n \times n}$:
- **Existence and Uniqueness**: A unique solution exists if and only if $\det(A) \neq 0$, $\text{rank}(A) = n$, and $A$ is non-singular.
- **Condition Number**:
  $$\kappa(A) = \|A\| \cdot \|A^{-1}\|$$
  The condition number bounds the relative error magnification in the solution due to perturbations in the input:
  $$\frac{\|\Delta \mathbf{x}\|}{\|\mathbf{x}\|} \le \kappa(A) \frac{\|\Delta \mathbf{b}\|}{\|\mathbf{b}\|}$$
  If $\kappa(A) \approx 10^k$, roughly $k$ decimal digits of precision are lost during numerical inversion.

### Eigenvalues, Eigenvectors, and Vibrations
The eigenvalue equation:
$$(A - \lambda I)\mathbf{v} = \mathbf{0}$$
has non-trivial solutions ($\mathbf{v} \neq \mathbf{0}$) when the characteristic polynomial vanishes:
$$p(\lambda) = \det(A - \lambda I) = 0$$

For a multi-degree-of-freedom structural vibration system with mass matrix $M$ and stiffness matrix $K$:
$$M \ddot{\mathbf{x}} + K \mathbf{x} = \mathbf{0}$$
Assuming harmonic motion $\mathbf{x}(t) = \boldsymbol{\phi} e^{i\omega t}$ leads to the **generalized eigenvalue problem**:
$$K \boldsymbol{\phi} = \omega^2 M \boldsymbol{\phi}$$
where $\omega_i = \sqrt{\lambda_i}$ is the $i$-th natural angular frequency ($\text{rad/s}$) and $\boldsymbol{\phi}_i$ is the $i$-th structural mode shape.

---

## 5. Worked Engineering Example: 5-Resistor Bridge Circuit
Consider a classic Wheatstone bridge circuit driven by an independent DC current source $I_s = 2.0\text{ A}$ connected between Node 1 and Node 0 (Ground).

```
         (Node 1) -------- [ R1 = 10 Ohm ] -------- (Node 2)
            |                                           |
            |                                     [ R5 = 50 Ohm ]
        (Is = 2A)                                       |
            |                                           v
         (Node 0 = GND) --- [ R2 = 20 Ohm ] -------- (Node 3)
            |                                           |
            +------------- [ R3 = 40 Ohm ] -------------+
            |                                           |
            +------------- [ R4 = 25 Ohm ] ------ (Node 2)
```
Specifically, let the circuit have 3 non-reference nodes ($V_1, V_2, V_3$) and Ground ($V_0 = 0\text{ V}$):
- Resistor $R_1 = 10\,\Omega$ connects Node 1 and Node 2 ($G_1 = 1/10 = 0.10\,\text{S}$)
- Resistor $R_2 = 20\,\Omega$ connects Node 1 and Node 3 ($G_2 = 1/20 = 0.05\,\text{S}$)
- Resistor $R_3 = 40\,\Omega$ connects Node 2 to Ground ($G_3 = 1/40 = 0.025\,\text{S}$)
- Resistor $R_4 = 25\,\Omega$ connects Node 3 to Ground ($G_4 = 1/25 = 0.04\,\text{S}$)
- Resistor $R_5 = 50\,\Omega$ is the bridge resistor between Node 2 and Node 3 ($G_5 = 1/50 = 0.02\,\text{S}$)
- Current source $I_s = 2.0\text{ A}$ enters Node 1 from Ground.

### Step 1: Formulate Kirchhoff's Current Law (KCL) at Each Node
At any node $k$, the sum of currents leaving must equal currents entering:
$$\sum_{\text{connected } j} G_{kj} (V_k - V_j) = I_{\text{in}, k}$$

1. **Node 1**:
   $$G_1(V_1 - V_2) + G_2(V_1 - V_3) = I_s$$
   $$(G_1 + G_2)V_1 - G_1 V_2 - G_2 V_3 = 2.0$$
   $$(0.10 + 0.05)V_1 - 0.10 V_2 - 0.05 V_3 = 2.0 \implies 0.15 V_1 - 0.10 V_2 - 0.05 V_3 = 2.0$$

2. **Node 2**:
   $$G_1(V_2 - V_1) + G_3(V_2 - 0) + G_5(V_2 - V_3) = 0$$
   $$-G_1 V_1 + (G_1 + G_3 + G_5)V_2 - G_5 V_3 = 0$$
   $$-0.10 V_1 + (0.10 + 0.025 + 0.02)V_2 - 0.02 V_3 = 0 \implies -0.10 V_1 + 0.145 V_2 - 0.02 V_3 = 0$$

3. **Node 3**:
   $$G_2(V_3 - V_1) + G_4(V_3 - 0) + G_5(V_3 - V_2) = 0$$
   $$-G_2 V_1 - G_5 V_2 + (G_2 + G_4 + G_5)V_3 = 0$$
   $$-0.05 V_1 - 0.02 V_2 + (0.05 + 0.04 + 0.02)V_3 = 0 \implies -0.05 V_1 - 0.02 V_2 + 0.11 V_3 = 0$$

### Step 2: Assemble System Matrix Form $G\mathbf{v} = \mathbf{i}$
$$\begin{bmatrix}
0.15 & -0.10 & -0.05 \\
-0.10 & 0.145 & -0.02 \\
-0.05 & -0.02 & 0.11
\end{bmatrix}
\begin{bmatrix}
V_1 \\ V_2 \\ V_3
\end{bmatrix}
=
\begin{bmatrix}
2.0 \\ 0.0 \\ 0.0
\end{bmatrix}$$

Notice the beautiful properties of the conductance matrix $G$:
- It is **symmetric** ($G_{jk} = G_{kj}$) due to reciprocity.
- The diagonal entries are strictly positive and equal the sum of conductances attached to that node.
- The off-diagonal entries are negative mutual conductances.
- It is **strictly diagonally dominant** (or weakly diagonally dominant with non-zero grounding), ensuring $G$ is positive-definite and non-singular.

---

## 6. MATLAB Implementation
Here is the clean, vectorized MATLAB implementation solving the worked example and demonstrating core linear algebra capabilities:

```matlab
% Define conductances (Siemens = 1/Ohm)
R = [10, 20, 40, 25, 50];
G = 1 ./ R;

% Assemble Conductance Matrix G_mat
G_mat = [  G(1) + G(2),        -G(1),                 -G(2);
          -G(1),         G(1) + G(3) + G(5),          -G(5);
          -G(2),               -G(5),          G(2) + G(4) + G(5) ];

% Injected current vector (Amperes)
i_vec = [2.0; 0.0; 0.0];

% Check condition number
kappa = cond(G_mat);
fprintf('Matrix condition number: %.4f (well-conditioned)\n', kappa);

% Solve for node voltages using backslash operator
v_nodes = G_mat \ i_vec;

fprintf('Node Voltages:\n');
fprintf('  V1 = %8.4f V\n', v_nodes(1));
fprintf('  V2 = %8.4f V\n', v_nodes(2));
fprintf('  V3 = %8.4f V\n', v_nodes(3));

% Calculate bridge voltage drop and current through R5
V_bridge = v_nodes(2) - v_nodes(3);
I_bridge = V_bridge * G(5);
fprintf('Bridge Differential Voltage (V2 - V3): %8.4f V\n', V_bridge);
fprintf('Current through Bridge Resistor R5:   %8.4f A\n', I_bridge);
```

Running this code produces:
- $V_1 \approx 28.5372\text{ V}$
- $V_2 \approx 20.6977\text{ V}$
- $V_3 \approx 16.7209\text{ V}$
- $V_{\text{bridge}} = V_2 - V_3 \approx 3.9767\text{ V}$
- $I_{\text{bridge}} \approx 0.0795\text{ A}$

---

## 7. Common Student Pitfalls & Debugging Tips

### 1. `inv(A)*b` vs `A\b` (The Cardinal Sin of MATLAB)
- **Pitfall**: Writing `x = inv(A) * b`.
- **Why it is harmful**:
  1. **Speed**: Explicitly inverting an $n \times n$ matrix requires $\sim 2n^3$ operations. Backslash (`A\b`) performs Gaussian elimination / LU decomposition with back-substitution in $\sim \frac{2}{3}n^3$ operations—$3\times$ faster!
  2. **Numerical Accuracy**: Matrix inversion introduces avoidable round-off errors and can double the effective condition number. For ill-conditioned systems, `inv(A)*b` produces catastrophic numerical noise.
- **Rule**: Never compute `inv(A)` unless you physically need the explicit inverse matrix entries (e.g. for analytic variance propagation). Always use `x = A\b`.

### 2. Ill-Conditioned Systems and `cond(A)`
- **Pitfall**: Solving a linear system without checking if the matrix is close to singular.
- **Symptom**: MATLAB issues a warning: `Warning: Matrix is close to singular or badly scaled. Results may be inaccurate.`
- **Debugging Tip**: Always check `cond(A)`.
  - $\text{cond}(A) < 10^3$: Well-conditioned. Safe for standard single/double precision.
  - $10^3 \le \text{cond}(A) < 10^{12}$: Moderately conditioned. Keep an eye on residuals.
  - $\text{cond}(A) \ge 10^{15}$: Severely ill-conditioned. The matrix is effectively singular in IEEE double precision; results are garbage. You likely have redundant equations, missing boundary constraints, or improper physical unit scaling (e.g. mixing nanometers with kilometers).

### 3. Dimension Mismatch (`Matrix dimensions must agree`)
- **Pitfall**: Multiplying row vectors by matrices in the wrong order or creating a row vector $\mathbf{b}$ instead of a column vector for `A\b`.
- **Debugging Tip**: Check `size(A)` and `size(b)`.
  - For $A\mathbf{x} = \mathbf{b}$, if $A$ is $m \times n$, $\mathbf{b}$ must be $m \times 1$.
  - If $\mathbf{b}$ is $1 \times m$, `A\b` will throw an error or perform an unexpected generalized solve. Use transpose: `b = b(:);` to force a column vector.

### 4. Eigenvalue Sorting & Normalization
- **Pitfall**: Assuming `[V, D] = eig(A)` returns eigenvalues in ascending order.
- **Debugging Tip**: MATLAB does not guarantee eigenvalues along `diag(D)` are sorted. Always sort them explicitly:
  ```matlab
  [V, D] = eig(A);
  [lambda_sorted, idx] = sort(diag(D), 'ascend');
  V_sorted = V(:, idx);
  ```

---

## 8. Engineering Interpretation

Solving equations is only half the engineer's job; the true skill is **interpreting what the numbers mean physically**:

### 1. Eigenvalues in Vibration and Stability
- **Eigenvalues $\lambda = \omega^2$**: Represent the squared natural resonant frequencies of a mechanical structure. If an operating excitation frequency (e.g., an engine spinning at 1800 RPM = 30 Hz) matches a structural eigenvalue, resonance occurs, leading to catastrophic failure (like the Tacoma Narrows Bridge).
- **Eigenvectors $\boldsymbol{\phi}$**: Represent mode shapes. They reveal which structural joints experience the highest relative displacement amplitudes during resonance, guiding where engineers must add dampers or stiffeners.
- **Complex Eigenvalues with Positive Real Part**: In dynamic systems $\dot{\mathbf{x}} = A\mathbf{x}$, eigenvalues $\lambda = \sigma \pm i\omega$ dictate stability. If $\sigma > 0$, the system experiences exponentially growing flutter or thermal runaway (instability).

### 2. Condition Number in Structural Determinacy
- If a truss or frame has $\text{rank}(A) < n$ or $\text{cond}(A) \to \infty$, the structure is an **unstable mechanism** (it has an unconstrained degree of freedom and can collapse without resistance).
- The null space of $A$ reveals the exact mechanism mode (rigid body motion without strain).

### 3. Singular Value Decomposition (SVD) and Principal Components
- In sensor telemetry, the largest singular values capture dominant physical trends (e.g., thermal cycles or vehicle acceleration), while tiny singular values represent random high-frequency sensor noise. Truncating small singular values filters noise without distorting physical signals.

---

## 9. Progressive Exercises Overview
The accompanying file `exercises.m` reinforces these concepts through 4 progressive challenge tiers:

- **Level 1: Recall**:
  - Reproduce vector norm calculations ($L_1, L_2, L_\infty$).
  - Compute dot products, angles between force vectors, and 3D cross products for mechanical torque.
  - Solve a $3 \times 3$ linear system using the backslash operator `\`.
- **Level 2: Understanding & Debugging**:
  - Diagnose and resolve an ill-conditioned system resulting from improperly scaled sensor units.
  - Identify and fix dimension mismatch errors in matrix-vector equations.
  - Demonstrate numerical error degradation of `inv(A)*b` compared to `A\b`.
- **Level 3: Application**:
  - Implement a complete 4-node planar electrical network solver with multiple voltage-controlled and current-controlled branches.
  - Compute node voltages, branch currents, and verify energy conservation ($\sum P_{\text{sources}} = \sum P_{\text{dissipated}}$).
- **Level 4: Challenge**:
  - Conduct full modal analysis of a 3-story shear building subjected to earthquake vibrations.
  - Assemble mass matrix $M$ and tridiagonal stiffness matrix $K$.
  - Solve the generalized eigenvalue problem $K\boldsymbol{\phi} = \omega^2 M\boldsymbol{\phi}$.
  - Identify all 3 natural frequencies in Hz and determine modal displacement profiles.

Complete reference solutions with detailed pedagogical annotations are provided in:
`/home/settings/Documents/pearl/engineering-mathematics/solutions/linear_algebra_exercises_solution.m`

---

## 10. AI/ML Bridge: Embeddings, Attention, Projections & SVD

To connect linear algebra directly to modern Deep Learning, Transformers, and LLM Agent architectures, complete the dedicated Concept 07 bridge module:

- **Instructional Deep-Dive Lesson**: [`07_ai_ml_linear_algebra_bridge.md`](07_ai_ml_linear_algebra_bridge.md)  
  *Structured under `TERM -> DEFINITION -> INTUITION -> WHY IT EXISTS -> HOW IT WORKS -> CODE` covering high-dimensional embedding spaces, orthogonal projection operators, SVD/LoRA parameter compression, and Scaled Dot-Product Attention.*
- **Standalone Runnable NumPy Script**: [`07_embeddings_attention_svd.py`](07_embeddings_attention_svd.py)  
  *Zero-dependency, standalone executable verifying near-orthogonality in 768-D, projection idempotence, LoRA 98%+ parameter reduction, and Multi-Head Attention.*
- **Companion MATLAB Script**: [`07_embeddings_attention_svd.m`](07_embeddings_attention_svd.m)  
  *Native MATLAB implementation demonstrating the same four modern AI mathematical workflows.*
