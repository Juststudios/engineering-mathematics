# Linear Algebra Quick Reference Cheat Sheet

A comprehensive, mathematically rigorous reference guide for applied linear algebra in engineering systems, numerical solvers, and modern machine learning architectures.

---

## 1. Vector Operations, Norms & Inner Products

Let $\mathbf{u}, \mathbf{v} \in \mathbb{R}^n$:

| Operation | Mathematical Formula | MATLAB Syntax | NumPy Syntax | Physical / AI Meaning |
| :--- | :--- | :--- | :--- | :--- |
| **$L_1$ Norm (Manhattan)** | $\|\mathbf{u}\|_1 = \sum_{i=1}^n \|u_i\|$ | `norm(u, 1)` | `np.linalg.norm(u, 1)` | Sparsity promotion (Lasso, L1 regularization) |
| **$L_2$ Norm (Euclidean)** | $\|\mathbf{u}\|_2 = \sqrt{\sum_{i=1}^n u_i^2}$ | `norm(u, 2)` or `norm(u)` | `np.linalg.norm(u)` | Physical distance, vector magnitude, energy |
| **$L_\infty$ Norm (Max)** | $\|\mathbf{u}\|_\infty = \max_i \|u_i\|$ | `norm(u, inf)` | `np.linalg.norm(u, np.inf)` | Peak tolerance, worst-case bound |
| **Dot Product** | $\mathbf{u} \cdot \mathbf{v} = \mathbf{u}^T \mathbf{v} = \sum u_i v_i$ | `dot(u, v)` or `u' * v` | `np.dot(u, v)` or `u @ v` | Mechanical work, projection length, cosine similarity |
| **Cosine Similarity** | $\cos\theta = \frac{\mathbf{u}^T \mathbf{v}}{\|\mathbf{u}\|_2 \|\mathbf{v}\|_2}$ | `dot(u, v)/(norm(u)*norm(v))` | `u @ v / (norm(u)*norm(v))` | Semantic angle in embedding spaces |
| **3D Cross Product** | $\mathbf{u} \times \mathbf{v} = \det\begin{bmatrix} \hat{\mathbf{i}} & \hat{\mathbf{j}} & \hat{\mathbf{k}} \\ u_x & u_y & u_z \\ v_x & v_y & v_z \end{bmatrix}$ | `cross(u, v)` | `np.cross(u, v)` | Mechanical torque ($\boldsymbol{\tau} = \mathbf{r} \times \mathbf{F}$), angular momentum |

---

## 2. Orthogonal Projections & Subspaces

For an overdetermined feature matrix $X \in \mathbb{R}^{m \times n}$ with full column rank ($m > n$):

| Concept | Mathematical Formula | MATLAB Implementation |
| :--- | :--- | :--- |
| **Projection Matrix** | $P = X(X^T X)^{-1}X^T$ | `P = X * ((X' * X) \ X');` |
| **Projected Vector** | $\hat{\mathbf{y}} = P\mathbf{y}$ | `y_hat = P * y;` (or `X * (X \ y)`) |
| **Orthogonal Residual** | $\mathbf{e} = (I - P)\mathbf{y} = \mathbf{y} - \hat{\mathbf{y}}$ | `e = y - y_hat;` |
| **Idempotence Property** | $P^2 = P$ | `norm(P*P - P) < 1e-12` |
| **Symmetry Property** | $P^T = P$ | `norm(P' - P) < 1e-12` |
| **Residual Orthogonality** | $X^T \mathbf{e} = \mathbf{0}$ | `norm(X' * e) < 1e-12` |

---

## 3. Matrix Transformations & Kinematics

### 2D Transformations
- **Rotation by $\theta$**: $R(\theta) = \begin{bmatrix} \cos\theta & -\sin\theta \\ \sin\theta & \cos\theta \end{bmatrix}$
- **Scaling by $(s_x, s_y)$**: $S(s_x, s_y) = \begin{bmatrix} s_x & 0 \\ 0 & s_y \end{bmatrix}$
- **Shear by $(k_x, k_y)$**: $H(k_x, k_y) = \begin{bmatrix} 1 & k_x \\ k_y & 1 \end{bmatrix}$

### 3D Homogeneous Coordinates ($4 \times 4$)
Unified rotation $R \in SO(3)$ and translation $\mathbf{t} \in \mathbb{R}^3$:
$$T = \begin{bmatrix} R & \mathbf{t} \\ \mathbf{0}_{1 \times 3} & 1 \end{bmatrix}, \quad \begin{bmatrix} \mathbf{x}_{\text{world}} \\ 1 \end{bmatrix} = T \begin{bmatrix} \mathbf{x}_{\text{body}} \\ 1 \end{bmatrix}$$

---

## 4. Solving Linear Systems $A\mathbf{x} = \mathbf{b}$

| Property | Condition / Value | Engineering Significance |
| :--- | :--- | :--- |
| **Determinant $\det(A)$** | $\det(A) \neq 0 \iff$ Invertible | Ratio of transformed to original spatial volume; $\det=0$ flattens space |
| **Matrix Rank** | $\text{rank}(A) = n$ (full rank) | Number of independent physical constraints / degrees of freedom |
| **Condition Number** | $\kappa(A) = \|A\| \cdot \|A^{-1}\| = \frac{\sigma_{\max}}{\sigma_{\min}}$ | $\kappa < 10^3$: well-conditioned.<br>$\kappa \ge 10^{15}$: numerically singular. Precision loss: $\Delta \text{digits} \approx \log_{10}\kappa(A)$ |
| **Backslash Solver** | `x = A \ b` | Uses LU (square), Cholesky (Hermitian positive-definite), or QR (rectangular). $3\times$ faster than `inv(A)*b` |

---

## 5. Eigendecomposition & Physical Vibrations

For square matrix $A \in \mathbb{R}^{n \times n}$:
$$A \mathbf{v} = \lambda \mathbf{v} \implies (A - \lambda I)\mathbf{v} = \mathbf{0}, \quad \det(A - \lambda I) = 0$$

- **Structural Dynamic Vibrations**: $M \ddot{\mathbf{x}} + K \mathbf{x} = \mathbf{0} \implies K \boldsymbol{\phi} = \omega^2 M \boldsymbol{\phi}$
  ```matlab
  [Phi, D] = eig(K, M);                 % Generalized eigenvalue solver
  omega = sqrt(diag(D));                 % Natural angular frequencies [rad/s]
  freq_hz = omega / (2 * pi);            % Natural frequencies [Hz]
  ```

---

## 6. SVD, Attention & AI/ML Architecture Bridges

### Singular Value Decomposition (SVD)
Any matrix $A \in \mathbb{R}^{m \times n}$ decomposes into orthogonal rotations $U, V$ and singular values $\Sigma$:
$$A = U \Sigma V^T = \sum_{i=1}^r \sigma_i \mathbf{u}_i \mathbf{v}_i^T, \quad \sigma_1 \ge \sigma_2 \ge \dots \ge \sigma_r \ge 0$$
- **Eckart-Young Optimal Low-Rank Approximation**: $A_k = \sum_{i=1}^k \sigma_i \mathbf{u}_i \mathbf{v}_i^T$ minimizes $\|A - A_k\|_F$.
- **Low-Rank Adaptation (LoRA)**: Approximates full weight update $W \in \mathbb{R}^{d \times k}$ with low-rank bottleneck:
  $$\Delta W = B \cdot A, \quad B \in \mathbb{R}^{d \times r}, \quad A \in \mathbb{R}^{r \times k}, \quad r \ll \min(d, k)$$

### Scaled Dot-Product Attention (Transformer Core)
Maps Queries $Q \in \mathbb{R}^{N \times d_k}$, Keys $K \in \mathbb{R}^{M \times d_k}$, and Values $V \in \mathbb{R}^{M \times d_v}$:
$$\text{Attention}(Q, K, V) = \text{softmax}\left(\frac{Q K^T}{\sqrt{d_k}}\right) V$$
- **Why $\sqrt{d_k}$ Scaling?** If components of $\mathbf{q}, \mathbf{k}$ are i.i.d. with unit variance, the variance of their dot product is $d_k$. Dividing by $\sqrt{d_k}$ keeps variance at $1$, preventing softmax saturation and vanishing gradients!

```python
# Pure NumPy Attention
scores = (Q @ K.T) / np.sqrt(d_k)
attention_weights = np.exp(scores - np.max(scores, axis=-1, keepdims=True))
attention_weights /= np.sum(attention_weights, axis=-1, keepdims=True)
context = attention_weights @ V
```
