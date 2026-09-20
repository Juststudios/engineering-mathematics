# AI/ML Calculus Bridge: Gradients, Jacobians, Hessians, Backprop & Adam

Welcome to the AI/ML Bridge for Calculus. This lesson connects rates of change, slopes, optimization, and differential equations directly to deep neural network training, computational graphs, and adaptive optimizer dynamics.

---

## 1. The Multivariable Gradient Vector

### TERM
Multivariable Gradient Vector & Steepest Descent

### DEFINITION
Let $f: \mathbb{R}^n \to \mathbb{R}$ be a continuously differentiable scalar loss function. The gradient vector $\nabla f(\mathbf{x})$ is the vector of all $n$ first-order partial derivatives:
$$\nabla f(\mathbf{x}) = \begin{bmatrix} \frac{\partial f}{\partial x_1}, & \frac{\partial f}{\partial x_2}, & \dots, & \frac{\partial f}{\partial x_n} \end{bmatrix}^T \in \mathbb{R}^n$$
For any unit direction $\mathbf{u} \in \mathbb{R}^n$ ($\|\mathbf{u}\|_2 = 1$), the directional derivative is:
$$D_{\mathbf{u}} f(\mathbf{x}) = \nabla f(\mathbf{x})^T \mathbf{u} = \|\nabla f(\mathbf{x})\|_2 \cos\theta$$
By the Cauchy-Schwarz inequality, the directional derivative is maximized when $\mathbf{u} = \frac{\nabla f}{\|\nabla f\|}$ ($\cos\theta = 1$) and minimized (most negative) when $\mathbf{u} = -\frac{\nabla f}{\|\nabla f\|}$ ($\cos\theta = -1$).

The **Gradient Descent Update Rule** is:
$$\mathbf{x}_{k+1} = \mathbf{x}_k - \alpha \nabla f(\mathbf{x}_k)$$
where $\alpha > 0$ is the learning rate.

### INTUITION
Imagine standing blindfolded on a foggy mountain in a dense mist. You cannot see the summit or the valley floor below. How do you find your way down to the bottom?

You feel the ground beneath your boots in every direction:
- The direction where the terrain tilts up most steeply is the **gradient** $\nabla f(\mathbf{x})$.
- The direction directly opposite—where the terrain drops away most steeply—is the **negative gradient** $-\nabla f(\mathbf{x})$.
- By taking a disciplined step downhill in that direction, you are guaranteed to decrease your altitude locally.

### WHY IT EXISTS
In classical 1D calculus, finding a minimum is trivial: solve $f'(x) = 0$. 

In deep learning, neural networks have millions or billions of parameters ($\mathbf{x} \in \mathbb{R}^{10^9}$). Setting all $10^9$ partial derivatives to zero yields an intractable, coupled non-linear system of equations with no closed-form solution. 

Random guessing fails catastrophically due to the combinatorial volume of high dimensions. The gradient vector is the only tractable local compass available to guide an algorithm toward minimal loss.

### HOW IT WORKS
1. **Compute Analytical Partials**: For loss $\mathcal{L}(\mathbf{w}) = \frac{1}{2}\|X\mathbf{w} - \mathbf{y}\|_2^2$, evaluate:
   $$\nabla \mathcal{L}(\mathbf{w}) = X^T(X\mathbf{w} - \mathbf{y})$$
2. **Verify via Finite Differences (Gradient Checking)**:
   $$\left[\nabla f_{\text{num}}(\mathbf{x})\right]_i = \frac{f(\mathbf{x} + \epsilon \mathbf{e}_i) - f(\mathbf{x} - \epsilon \mathbf{e}_i)}{2\epsilon}, \quad \epsilon = 10^{-5}$$
3. **Take Descent Step**:
   $$\mathbf{w} \leftarrow \mathbf{w} - \alpha \nabla \mathcal{L}(\mathbf{w})$$

### CODE
```python
import numpy as np

# Define quadratic loss surface: f(x) = 0.5 * x^T A x - b^T x
A = np.array([[3.0, 1.0], [1.0, 2.0]])
b = np.array([5.0, 4.0])

def loss_fn(x):
    return 0.5 * float(x.T @ A @ x) - float(b.T @ x)

def grad_analytical(x):
    return A @ x - b

# Numerical gradient checking
x_test = np.array([1.5, -2.0])
eps = 1e-5
grad_num = np.zeros_like(x_test)
for i in range(len(x_test)):
    x_plus, x_minus = x_test.copy(), x_test.copy()
    x_plus[i] += eps
    x_minus[i] -= eps
    grad_num[i] = (loss_fn(x_plus) - loss_fn(x_minus)) / (2.0 * eps)

rel_err = np.linalg.norm(grad_analytical(x_test) - grad_num) / np.linalg.norm(grad_analytical(x_test))
print(f"Analytical Gradient : {grad_analytical(x_test)}")
print(f"Numerical Gradient  : {grad_num}")
print(f"Relative Check Error: {rel_err:.2e} (Passes < 1e-7!)")
```

---

## 2. The Jacobian Matrix

### TERM
The Jacobian Matrix of Vector-Valued Mappings

### DEFINITION
For a vector-valued function mapping an $n$-dimensional input to an $m$-dimensional output:
$$\mathbf{f}: \mathbb{R}^n \to \mathbb{R}^m, \quad \mathbf{y} = \mathbf{f}(\mathbf{x}) = \begin{bmatrix} f_1(\mathbf{x}) \\ f_2(\mathbf{x}) \\ \vdots \\ f_m(\mathbf{x}) \end{bmatrix}$$
the **Jacobian matrix** $J \in \mathbb{R}^{m \times n}$ is the matrix of all first-order partial derivatives:
$$J_{ij} = \frac{\partial f_i}{\partial x_j}, \quad J = \begin{bmatrix}
\frac{\partial f_1}{\partial x_1} & \frac{\partial f_1}{\partial x_2} & \dots & \frac{\partial f_1}{\partial x_n} \\
\frac{\partial f_2}{\partial x_1} & \frac{\partial f_2}{\partial x_2} & \dots & \frac{\partial f_2}{\partial x_n} \\
\vdots & \vdots & \ddots & \vdots \\
\frac{\partial f_m}{\partial x_1} & \frac{\partial f_m}{\partial x_2} & \dots & \frac{\partial f_m}{\partial x_n}
\end{bmatrix}$$

The first-order multivariable Taylor approximation is:
$$\mathbf{f}(\mathbf{x} + \Delta \mathbf{x}) \approx \mathbf{f}(\mathbf{x}) + J(\mathbf{x}) \Delta \mathbf{x}$$

### INTUITION
When you pull or twist a rubber sheet in multiple directions at once, every point moves. A small horizontal nudge $\Delta x_1$ at the input causes ripples across all $m$ outputs. 

The Jacobian matrix is the **local sensitivity transformation**. It tells you: if you perturb the input vector by a tiny nudge $\Delta \mathbf{x}$, exactly how does each output component $\Delta y_i$ respond? The $i$-th row of $J$ is the gradient of the $i$-th output feature, and the absolute determinant $|\det(J)|$ (for $m=n$) measures the local volumetric distortion.

### WHY IT EXISTS
Every neural network layer is a vector-to-vector mapping (e.g., from 512 hidden activations to 1024 hidden activations). 

To train a deep network, we must understand how changing the activations at layer $l$ changes the activations at layer $l+1$. The Jacobian matrix formalizes this layer-to-layer linear sensitivity.

### HOW IT WORKS
1. For an affine transformation followed by element-wise activation $\mathbf{y} = \sigma(W \mathbf{x} + \mathbf{b})$:
2. Pre-activation linear mapping: $\frac{\partial \mathbf{z}}{\partial \mathbf{x}} = W$.
3. Activation sensitivity: $\frac{\partial \mathbf{y}}{\partial \mathbf{z}} = \text{diag}(\sigma'(\mathbf{z}))$.
4. By the multivariable chain rule, the layer Jacobian is:
   $$J = \frac{\partial \mathbf{y}}{\partial \mathbf{x}} = \text{diag}(\sigma'(\mathbf{z})) W$$

### CODE
```python
import numpy as np

# Layer mapping: y = tanh(W x + b), n = 3, m = 2
np.random.seed(3)
n, m = 3, 2
W = np.random.randn(m, n)
b = np.random.randn(m)

def layer_forward(x):
    z = W @ x + b
    return np.tanh(z)

x0 = np.array([0.5, -1.0, 2.0])
z0 = W @ x0 + b
y0 = np.tanh(z0)

# Analytical Jacobian: J = diag(1 - tanh(z)^2) @ W
diag_dtanh = np.diag(1.0 - y0**2)
J_analytical = diag_dtanh @ W

# Verify with a small perturbation dx
dx = np.array([1e-4, -2e-4, 1.5e-4])
y_perturbed = layer_forward(x0 + dx)
actual_dy = y_perturbed - y0
predicted_dy = J_analytical @ dx

lin_err = np.linalg.norm(actual_dy - predicted_dy) / np.linalg.norm(actual_dy)
print("Actual dy    :", actual_dy)
print("Predicted dy :", predicted_dy)
print(f"Linearization Relative Error: {lin_err:.2e} (First-order accuracy confirmed!)")
```

---

## 3. The Hessian Matrix, Curvature & Saddle Points

### TERM
The Hessian Matrix & Loss Curvature

### DEFINITION
Let $f: \mathbb{R}^n \to \mathbb{R}$ be a twice continuously differentiable scalar function. The **Hessian matrix** $H \in \mathbb{R}^{n \times n}$ is the symmetric square matrix of second-order partial derivatives:
$$H_{ij} = \frac{\partial^2 f}{\partial x_i \partial x_j}, \quad H = \nabla^2 f(\mathbf{x})$$

The second-order Taylor expansion around $\mathbf{x}$ is:
$$f(\mathbf{x} + \mathbf{v}) \approx f(\mathbf{x}) + \nabla f(\mathbf{x})^T \mathbf{v} + \frac{1}{2} \mathbf{v}^T H(\mathbf{x}) \mathbf{v}$$

At a critical point ($\nabla f(\mathbf{x}^*) = \mathbf{0}$), the local geometry is classified by the eigenvalues $\lambda_1 \le \dots \le \lambda_n$ of $H(\mathbf{x}^*)$:
1. **Strict Local Minimum**: All $\lambda_i > 0$ ($H \succ 0$, positive definite).
2. **Strict Local Maximum**: All $\lambda_i < 0$ ($H \prec 0$, negative definite).
3. **Saddle Point**: Mixed signs ($\lambda_{\min} < 0 < \lambda_{\max}$, indefinite).
4. **Condition Number of Curvature**: $\kappa(H) = \frac{\lambda_{\max}}{\lambda_{\min}}$ measures canyon anisotropy.

### INTUITION
The gradient $\nabla f$ tells you which way is downhill, but it does NOT tell you how the slope is changing. 
- Is the valley flattening out into a wide plain?
- Is it curving upward into a sharp bowl?
- Or is it sloping downward in one direction while sloping upward in another, like a Pringles potato chip or a horse saddle?

The Hessian matrix measures **curvature**. In a high-dimensional loss landscape ($n = 10^6$), the chance that all $10^6$ independent eigenvalues are positive is vanishingly small ($2^{-10^6} \approx 0$). Therefore, almost all zero-gradient flat points in deep learning are **saddle points**, not local minima!

### WHY IT EXISTS
Vanilla gradient descent assumes the terrain has isotropic curvature (equal stiffness in all directions). 

When $\kappa(H) \gg 1$ (e.g. $\kappa(H) = 10^4$), the loss surface forms an **ill-conditioned ravine**: steep, vertical canyon walls with a nearly flat riverbed flowing gently downhill. Gradient descent bounces uncontrollably back and forth between the canyon walls while making virtually zero forward progress along the ravine floor!

Newton's method solves this by taking $\Delta \mathbf{x} = -H^{-1} \nabla f$, scaling each direction by its exact inverse curvature.

### HOW IT WORKS
1. Compute the second partial derivatives matrix $H$.
2. Eigendecomposition: $H = Q \Lambda Q^T$.
3. Compute the condition number: $\kappa(H) = \frac{\lambda_{\max}}{\lambda_{\min}}$.
4. Evaluate Newton-Raphson update step:
   $$\mathbf{x}_{k+1} = \mathbf{x}_k - H(\mathbf{x}_k)^{-1} \nabla f(\mathbf{x}_k)$$

### CODE
```python
import numpy as np

# Saddle surface: f(x, y) = x^2 - y^2
def saddle_fn(v):
    return v[0]**2 - v[1]**2

def saddle_grad(v):
    return np.array([2.0 * v[0], -2.0 * v[1]])

def saddle_hessian(v):
    return np.array([[2.0, 0.0], [0.0, -2.0]])

# Evaluate at origin (critical point)
v0 = np.array([0.0, 0.0])
g0 = saddle_grad(v0)
H0 = saddle_hessian(v0)
eigenvals, eigenvecs = np.linalg.eigh(H0)

print(f"Gradient at Origin : {g0} (Critical Point)")
print(f"Hessian Eigenvalues: {eigenvals}")
if np.any(eigenvals > 0) and np.any(eigenvals < 0):
    print("Geometry Diagnostic: Confirmed SADDLE POINT (Curvature slopes up along x, down along y)")
```

---

## 4. Computational Graphs & Backpropagation

### TERM
Reverse-Mode Automatic Differentiation & Backpropagation

### DEFINITION
Let a composite computational graph compute loss $\mathcal{L} \in \mathbb{R}$ from inputs $\mathbf{x}$ through intermediate node variables $\mathbf{v}_1, \dots, \mathbf{v}_K$.

The **Chain Rule of Multivariable Calculus** dictates that the sensitivity of the loss to any intermediate variable $\mathbf{v}_i$ is:
$$\frac{\partial \mathcal{L}}{\partial \mathbf{v}_i} = \sum_{j \in \text{Children}(i)} \left(\frac{\partial \mathbf{v}_j}{\partial \mathbf{v}_i}\right)^T \frac{\partial \mathcal{L}}{\partial \mathbf{v}_j}$$

In **Reverse-Mode Automatic Differentiation (Backpropagation)**:
1. **Forward Sweep**: Compute and cache intermediate activations:
   $$Z^{[1]} = W^{[1]} X + \mathbf{b}^{[1]}, \quad A^{[1]} = \sigma(Z^{[1]})$$
   $$Z^{[2]} = W^{[2]} A^{[1]} + \mathbf{b}^{[2]}, \quad \hat{Y} = Z^{[2]}, \quad \mathcal{L} = \frac{1}{2N}\|\hat{Y} - Y\|_F^2$$
2. **Backward Sweep**: Propagate sensitivity adjoints ($\delta = \frac{\partial \mathcal{L}}{\partial Z}$):
   $$\delta^{[2]} = \frac{1}{N}(\hat{Y} - Y)$$
   $$\nabla_{W^{[2]}} \mathcal{L} = \delta^{[2]} (A^{[1]})^T, \quad \nabla_{\mathbf{b}^{[2]}} \mathcal{L} = \sum \delta^{[2]}$$
   $$\delta^{[1]} = \left((W^{[2]})^T \delta^{[2]}\right) \odot \sigma'(Z^{[1]})$$
   $$\nabla_{W^{[1]}} \mathcal{L} = \delta^{[1]} X^T, \quad \nabla_{\mathbf{b}^{[1]}} \mathcal{L} = \sum \delta^{[1]}$$

### INTUITION
Forward propagation is like shooting an arrow: you release the input parameters, and they travel through layer after layer until they strike the target (loss). 

Backward propagation is like tracing a laser pointer backward from the point of impact. The error signal flows in reverse along the exact wires and nodes that produced it. Each weight is held accountable in direct proportion to how much it contributed to the final error.

### WHY IT EXISTS
Suppose a model has $D = 10^8$ weights. 
- Using numerical finite differences requires evaluating the forward model $D + 1$ times ($10^8$ passes).
- Forward-mode automatic differentiation similarly tracks $D$ directional derivatives.
- **Reverse-mode backpropagation computes exact gradients for ALL $D$ weights in a single backward pass**, taking roughly $2\times$ the time of a single forward evaluation. It is the single algorithmic breakthrough that made modern Deep Learning computationally viable!

### HOW IT WORKS
1. Execute forward computation, saving all tensors required for backward derivatives.
2. Initialize root gradient $\frac{\partial \mathcal{L}}{\partial \mathcal{L}} = 1$.
3. Traverse graph nodes in reverse topological order.
4. Multiply incoming adjoint signals by local Jacobian matrices.

### CODE
```python
import numpy as np

# Implement 2-layer MLP with exact analytical backpropagation
np.random.seed(42)
N, d_in, d_hidden, d_out = 8, 4, 16, 2

X = np.random.randn(d_in, N)
Y = np.random.randn(d_out, N)

W1 = np.random.randn(d_hidden, d_in) * 0.1
b1 = np.zeros((d_hidden, 1))
W2 = np.random.randn(d_out, d_hidden) * 0.1
b2 = np.zeros((d_out, 1))

# Forward Pass
Z1 = W1 @ X + b1
A1 = np.maximum(0, Z1)  # ReLU
Z2 = W2 @ A1 + b2
loss = 0.5 * np.mean(np.sum((Z2 - Y)**2, axis=0))

# Backward Pass (Chain Rule)
dZ2 = (Z2 - Y) / N
dW2 = dZ2 @ A1.T
db2 = np.sum(dZ2, axis=1, keepdims=True)

dA1 = W2.T @ dZ2
dZ1 = dA1 * (Z1 > 0)
dW1 = dZ1 @ X.T
db1 = np.sum(dZ1, axis=1, keepdims=True)

# Numerical gradient check on W2[0, 0]
eps = 1e-6
W2_plus = W2.copy()
W2_plus[0, 0] += eps
Z2_plus = W2_plus @ A1 + b2
loss_plus = 0.5 * np.mean(np.sum((Z2_plus - Y)**2, axis=0))

num_grad = (loss_plus - loss) / eps
print(f"Analytical dW2[0,0] : {dW2[0, 0]:.6f}")
print(f"Numerical dW2[0,0]  : {num_grad:.6f}")
print(f"Abs Difference      : {abs(dW2[0, 0] - num_grad):.2e} (Matches!)")
```

---

## 5. Optimization Dynamics: Momentum & Adam

### TERM
Adaptive Moment Estimation (Adam) Optimizer Dynamics

### DEFINITION
Let $\mathbf{g}_t = \nabla_{\boldsymbol{\theta}} \mathcal{L}(\boldsymbol{\theta}_t)$ be the gradient at step $t$. The **Adam optimizer** maintains exponential moving averages of both the first moment (mean) and second raw moment (uncentered variance) of the gradients:
1. **Biased First Moment (Momentum)**:
   $$\mathbf{m}_t = \beta_1 \mathbf{m}_{t-1} + (1 - \beta_1) \mathbf{g}_t$$
2. **Biased Second Moment (RMSProp)**:
   $$\mathbf{v}_t = \beta_2 \mathbf{v}_{t-1} + (1 - \beta_2) \mathbf{g}_t^2$$
3. **Bias Corrections** (compensating for zero initialization at $t=1$):
   $$\hat{\mathbf{m}}_t = \frac{\mathbf{m}_t}{1 - \beta_1^t}, \quad \hat{\mathbf{v}}_t = \frac{\mathbf{v}_t}{1 - \beta_2^t}$$
4. **Parameter Update**:
   $$\boldsymbol{\theta}_{t+1} = \boldsymbol{\theta}_t - \frac{\alpha}{\sqrt{\hat{\mathbf{v}}_t} + \epsilon} \hat{\mathbf{m}}_t$$
Standard default hyperparameters: $\beta_1 = 0.9, \beta_2 = 0.999, \epsilon = 10^{-8}$.

### INTUITION
Think of navigating a canyon with steep, slippery rocky walls and a muddy, flat floor:
- **Vanilla SGD** acts like a lightweight ping-pong ball: it bounces wildly from canyon wall to canyon wall.
- **Momentum** acts like a heavy bowling ball: its accumulated velocity pushes it straight down the valley floor, smoothing out sideways bounces.
- **RMSProp** acts like adaptive suspension: it dampens motion along directions with huge gradient variance (the canyon walls) while stiffening motion along flat directions.
- **Adam** combines both: a heavy bowling ball with an adaptive active suspension system!

### WHY IT EXISTS
Loss surfaces in deep learning are severely ill-conditioned and noisy (stochastic minibatches). 

Setting a single universal scalar learning rate $\alpha$ fails: a step size large enough to make progress along the flat valley will cause catastrophic explosions on the steep canyon walls. Adam calculates an individual, adaptive learning rate for every single parameter dynamically.

### HOW IT WORKS
1. Track direction using momentum $\hat{\mathbf{m}}_t$.
2. Track magnitude/noise using second moment $\hat{\mathbf{v}}_t$.
3. Scale step size: if a parameter has had large gradients, $\sqrt{\hat{\mathbf{v}}}$ is large, scaling down the effective step. If gradients have been small, step size is scaled up.

### CODE
```python
import numpy as np

# Compare Vanilla SGD vs Adam on an ill-conditioned anisotropic valley:
# f(x, y) = 0.5 * (100 * x^2 + y^2) -> kappa(H) = 100!
def anisotropic_grad(w):
    return np.array([100.0 * w[0], 1.0 * w[1]])

w_sgd = np.array([1.0, 1.0])
w_adam = np.array([1.0, 1.0])

lr = 0.01
m = np.zeros(2)
v = np.zeros(2)
beta1, beta2, eps = 0.9, 0.999, 1e-8

for t in range(1, 101):
    # Vanilla SGD
    g_sgd = anisotropic_grad(w_sgd)
    w_sgd -= lr * g_sgd
    
    # Adam
    g_adam = anisotropic_grad(w_adam)
    m = beta1 * m + (1.0 - beta1) * g_adam
    v = beta2 * v + (1.0 - beta2) * (g_adam**2)
    m_hat = m / (1.0 - beta1**t)
    v_hat = v / (1.0 - beta2**t)
    w_adam -= (lr * m_hat) / (np.sqrt(v_hat) + eps)

print(f"Initial Position   : [1.0, 1.0], Optimal: [0.0, 0.0]")
print(f"SGD Position (t=100) : [{w_sgd[0]:.4f}, {w_sgd[1]:.4f}] (Stuck or oscillating on x!)")
print(f"Adam Position (t=100): [{w_adam[0]:.4f}, {w_adam[1]:.4f}] (Smoothly converged along both axes!)")
```
