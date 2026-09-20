# Calculus & Optimization Quick Reference Cheat Sheet

A comprehensive, mathematically rigorous reference guide for applied calculus, rates of change, numerical integration, differential equations, and deep learning optimization dynamics.

---

## 1. Numerical Differentiation & Finite Differences

Given discrete samples $(t_k, y_k)$ with uniform spacing $h = \Delta t$:

| Method | Difference Formula | Truncation Error | MATLAB Syntax | NumPy Syntax |
| :--- | :--- | :--- | :--- | :--- |
| **Forward Difference** | $f'(t_k) \approx \frac{y_{k+1} - y_k}{h}$ | $O(h)$ (1st order) | `diff(y) ./ h` | `np.diff(y) / h` |
| **Backward Difference** | $f'(t_k) \approx \frac{y_k - y_{k-1}}{h}$ | $O(h)$ (1st order) | `diff(y) ./ h` | `np.diff(y) / h` |
| **Central Difference** | $f'(t_k) \approx \frac{y_{k+1} - y_{k-1}}{2h}$ | $O(h^2)$ (2nd order) | `gradient(y, h)` | `np.gradient(y, h)` |
| **Second Derivative** | $f''(t_k) \approx \frac{y_{k+1} - 2y_k + y_{k-1}}{h^2}$ | $O(h^2)$ (2nd order) | `diff(diff(y)) ./ (h^2)` | `np.diff(np.diff(y)) / h**2` |

> ⚠️ **Array Truncation Warning**: `diff(y)` yields an array of length $N - 1$. Pair with midpoints `t_mid = (t(1:end-1) + t(2:end)) / 2` or use `gradient(y, h)` to preserve $N$ points.

---

## 2. Numerical Accumulation & Quadrature

| Operation | Mathematical Definition | MATLAB Implementation | Physical Meaning |
| :--- | :--- | :--- | :--- |
| **Trapezoidal Rule** | $\int_a^b f(t) dt \approx \sum_{k=1}^{N-1} \frac{y_k + y_{k+1}}{2} \Delta t_k$ | `area = trapz(t, y);` | Cumulative energy ($E = \int P dt$), electric charge ($Q = \int I dt$) |
| **Cumulative Integral** | $S(t) = \int_{t_0}^t f(\tau) d\tau$ | `S = cumtrapz(t, y);` | Instantaneous distance trajectory $s(t) = \int v(t) dt$ |
| **Adaptive Quadrature** | $\int_a^b f(t) dt$ with error control | `q = integral(@(t) f(t), a, b);` | High-precision continuous functional quadrature |

---

## 3. Ordinary Differential Equations (ODEs)

Standard first-order physical system: $\frac{d\mathbf{y}}{dt} = \mathbf{f}(t, \mathbf{y})$

```matlab
% Example: Newton's Law of Cooling dT/dt = -k * (T - T_ambient)
k_cooling = 0.05;
T_ambient = 22.0;
dydt = @(t, T) -k_cooling * (T - T_ambient);

tspan = [0, 120];       % Simulation interval [0, 120] seconds
T0 = 95.0;              % Initial temperature [deg C]

[t_sol, T_sol] = ode45(dydt, tspan, T0);
```

---

## 4. Multivariable Calculus & Loss Surfaces

Let $f: \mathbb{R}^n \to \mathbb{R}$ be a scalar objective (loss function) and $\mathbf{x} \in \mathbb{R}^n$:

### Gradient Vector $\nabla f(\mathbf{x})$
Direction of steepest ascent:
$$\nabla f(\mathbf{x}) = \begin{bmatrix} \frac{\partial f}{\partial x_1}, & \frac{\partial f}{\partial x_2}, & \dots, & \frac{\partial f}{\partial x_n} \end{bmatrix}^T$$
- **Gradient Descent Step**: $\mathbf{x}_{k+1} = \mathbf{x}_k - \alpha \nabla f(\mathbf{x}_k)$

### Jacobian Matrix $J(\mathbf{x})$
For vector-valued mapping $\mathbf{f}: \mathbb{R}^n \to \mathbb{R}^m$, the Jacobian represents optimal local linear sensitivity:
$$J \in \mathbb{R}^{m \times n}, \quad J_{ij} = \frac{\partial f_i}{\partial x_j}, \quad \Delta \mathbf{y} \approx J \Delta \mathbf{x}$$

### Hessian Matrix $H(\mathbf{x})$ & Curvature
Second partial derivatives matrix quantifying surface curvature:
$$H_{ij} = \frac{\partial^2 f}{\partial x_i \partial x_j}, \quad f(\mathbf{x} + \mathbf{v}) \approx f(\mathbf{x}) + \nabla f^T \mathbf{v} + \frac{1}{2}\mathbf{v}^T H \mathbf{v}$$

| Eigendecomposition of $H$ | Curvature Characterization | Landscape Geometry |
| :--- | :--- | :--- |
| All $\lambda_i > 0$ | Positive Definite ($H \succ 0$) | Strict Local Minimum (convex bowl) |
| All $\lambda_i < 0$ | Negative Definite ($H \prec 0$) | Strict Local Maximum (concave dome) |
| Mixed signs ($\lambda_{\min} < 0 < \lambda_{\max}$) | Indefinite | **Saddle Point** (inflection in high-D) |
| $\kappa(H) = \frac{\lambda_{\max}}{\lambda_{\min}} \gg 1$ | Ill-conditioned | **Ravine / Canyon** (SGD oscillates wildly) |

---

## 5. Computational Graphs & Backpropagation

For a layer $Z = W X + \mathbf{b}, \quad A = \sigma(Z), \quad \text{Loss } L$:
1. **Output Sensitivity**: $\delta = \frac{\partial L}{\partial Z} = \frac{\partial L}{\partial A} \odot \sigma'(Z)$
2. **Weight Gradient**: $\frac{\partial L}{\partial W} = \delta X^T$
3. **Bias Gradient**: $\frac{\partial L}{\partial \mathbf{b}} = \sum \delta$
4. **Input Sensitivity Propagation**: $\frac{\partial L}{\partial X} = W^T \delta$

---

## 6. Optimizer Dynamics: Momentum & Adam

### Classical Momentum (Polyak Heavy-Ball)
Builds velocity along flat ravine valleys while canceling perpendicular oscillations:
$$\mathbf{v}_t = \beta \mathbf{v}_{t-1} + (1 - \beta) \mathbf{g}_t, \quad \boldsymbol{\theta}_{t+1} = \boldsymbol{\theta}_t - \alpha \mathbf{v}_t$$

### Adam (Adaptive Moment Estimation)
Maintains exponentially decaying averages of past gradients ($m_t$) and squared gradients ($v_t$):
$$m_t = \beta_1 m_{t-1} + (1 - \beta_1) g_t, \quad v_t = \beta_2 v_{t-1} + (1 - \beta_2) g_t^2$$
$$\hat{m}_t = \frac{m_t}{1 - \beta_1^t}, \quad \hat{v}_t = \frac{v_t}{1 - \beta_2^t} \quad \text{(Bias Corrections)}$$
$$\boldsymbol{\theta}_{t+1} = \boldsymbol{\theta}_t - \frac{\alpha}{\sqrt{\hat{v}_t} + \epsilon} \hat{m}_t$$

```python
# Pure NumPy Adam Optimizer Step
m = beta1 * m + (1.0 - beta1) * grad
v = beta2 * v + (1.0 - beta2) * (grad ** 2)
m_hat = m / (1.0 - beta1 ** t)
v_hat = v / (1.0 - beta2 ** t)
param -= alpha * m_hat / (np.sqrt(v_hat) + eps)
```
