# AI/ML Linear Algebra Bridge: Embeddings, Attention, Projections & SVD

Welcome to the AI/ML Bridge for Linear Algebra. This lesson connects the foundational concepts of vector spaces, matrix transformations, projections, and decompositions directly to the modern architectures powering Large Language Models (LLMs), Transformer networks, and Vector Databases.

---

## 1. High-Dimensional Vector Spaces & Embeddings

### TERM
High-Dimensional Vector Embeddings

### DEFINITION
A vector embedding is an injective or structure-preserving mapping:
$$f: \mathcal{X} \to \mathbb{R}^d$$
which maps discrete domain objects $x \in \mathcal{X}$ (words, code tokens, entities, documents, images) into a dense, continuous vector space of dimension $d$ (typically $d \in \{768, 1536, 4096\}$), such that semantic similarity in $\mathcal{X}$ corresponds to inner product or cosine similarity in $\mathbb{R}^d$:
$$\text{Sim}(x_1, x_2) \approx \cos\theta = \frac{\mathbf{e}_1^T \mathbf{e}_2}{\|\mathbf{e}_1\|_2 \|\mathbf{e}_2\|_2}$$

### INTUITION
In low dimensions (2D or 3D), space feels crowded. Two random vectors often point in somewhat similar or opposite directions. 

In $768$-dimensional space, however, space is unimaginably vast and almost entirely empty. The "curse of dimensionality" becomes a blessing for semantic representation: two uniformly random vectors in $\mathbb{R}^{768}$ are almost perfectly orthogonal ($\mathbf{u} \cdot \mathbf{v} \approx 0$). 

Because almost everything is orthogonal by default, any small non-zero alignment ($\cos\theta > 0.3$) is statistically meaningful. The vector space organizes into semantic manifolds where words with shared context cluster together, and vector arithmetic reflects relational concepts (e.g., $\mathbf{v}_{\text{King}} - \mathbf{v}_{\text{Man}} + \mathbf{v}_{\text{Woman}} \approx \mathbf{v}_{\text{Queen}}$).

### WHY IT EXISTS
In traditional computing, words are represented as discrete one-hot vectors $\mathbf{e}_i \in \{0, 1\}^{|V|}$ where $|V|$ is the vocabulary size ($50,000+$). One-hot vectors have two fatal defects:
1. **Zero Semantic Relatability**: Every one-hot vector is completely orthogonal to every other: $\mathbf{e}_{\text{cat}} \cdot \mathbf{e}_{\text{feline}} = 0$. The model cannot recognize that "cat" and "feline" are related.
2. **Dimensional Explosion**: A sparse vector of length 100,000 wastes memory and computational bandwidth.

Dense embeddings solve both: they compress vocabulary into a compact space ($\mathbb{R}^{768}$) where distance directly measures semantic relatedness.

### HOW IT WORKS
1. **L2 Normalization**: Raw embeddings $\mathbf{v}$ are normalized onto the unit hypersphere $\mathbb{S}^{d-1}$:
   $$\hat{\mathbf{v}} = \frac{\mathbf{v}}{\|\mathbf{v}\|_2}$$
2. **Cosine Similarity as Dot Product**: Once normalized, cosine similarity reduces to a pure matrix-vector multiplication:
   $$\cos(\hat{\mathbf{u}}, \hat{\mathbf{v}}) = \hat{\mathbf{u}}^T \hat{\mathbf{v}}$$
3. **Batch Similarity Retrieval**: For a query vector $\mathbf{q} \in \mathbb{R}^{1 \times d}$ and an embedding database matrix $E \in \mathbb{R}^{N \times d}$:
   $$\mathbf{s} = \mathbf{q} E^T \in \mathbb{R}^{1 \times N}$$
   Finding the most relevant documents in a Vector DB (RAG) is simply computing $\text{argmax}(\mathbf{s})$.

### CODE
```python
import numpy as np

# Demonstrate high-dimensional near-orthogonality
np.random.seed(42)
d_low, d_high = 3, 768
N_pairs = 1000

# 3D random unit vectors
u_low = np.random.randn(N_pairs, d_low)
u_low /= np.linalg.norm(u_low, axis=1, keepdims=True)
v_low = np.random.randn(N_pairs, d_low)
v_low /= np.linalg.norm(v_low, axis=1, keepdims=True)
cos_low = np.sum(u_low * v_low, axis=1)

# 768D random unit vectors
u_high = np.random.randn(N_pairs, d_high)
u_high /= np.linalg.norm(u_high, axis=1, keepdims=True)
v_high = np.random.randn(N_pairs, d_high)
v_high /= np.linalg.norm(v_high, axis=1, keepdims=True)
cos_high = np.sum(u_high * v_high, axis=1)

print(f"Mean |cos(theta)| in 3D   : {np.mean(np.abs(cos_low)):.4f}")
print(f"Mean |cos(theta)| in 768D : {np.mean(np.abs(cos_high)):.4f} (Nearly orthogonal!)")
```

---

## 2. Orthogonal Projection & Subspace Filtering

### TERM
Orthogonal Projection Operator

### DEFINITION
Let $X \in \mathbb{R}^{m \times n}$ be a feature matrix with full column rank ($m > n$). The orthogonal projection matrix $P$ onto the column space $\text{Col}(X) \subset \mathbb{R}^m$ is:
$$P = X(X^T X)^{-1} X^T \in \mathbb{R}^{m \times m}$$
For any vector $\mathbf{y} \in \mathbb{R}^m$, the projected vector $\hat{\mathbf{y}} = P\mathbf{y}$ is the unique point in $\text{Col}(X)$ that minimizes the Euclidean distance $\|\mathbf{y} - \hat{\mathbf{y}}\|_2$.

The operator satisfies two fundamental linear algebraic properties:
1. **Idempotence**: $P^2 = P$ (projecting twice does not change the result).
2. **Symmetry**: $P^T = P$ (self-adjoint).

The residual projector onto the orthogonal complement $\text{Col}(X)^\perp$ is:
$$P^\perp = I - P, \quad \text{such that } \mathbf{e} = (I - P)\mathbf{y} \implies X^T \mathbf{e} = \mathbf{0}$$

### INTUITION
Think of standing outside on a sunny day. Your body casts a shadow on the flat lawn. The ground is a 2D subspace embedded in 3D space. 

No matter how complex your 3D shape is, the light rays shining directly perpendicular down drop your 3D coordinates onto the closest possible 2D point on the grass. 
- The point on the grass is the projection $\hat{\mathbf{y}} = P\mathbf{y}$.
- The vertical distance from your head down to your shadow is the orthogonal residual error $\mathbf{e}$.
- Because the shadow is already flat on the ground, dropping another vertical shadow onto the ground changes nothing: $P(P\mathbf{y}) = P\mathbf{y}$, which is idempotence ($P^2 = P$).

### WHY IT EXISTS
In real-world data science and physical engineering, systems are almost always **overdetermined**: we have $m = 10,000$ telemetry observations but only $n = 5$ physical parameters to calibrate ($m \gg n$). 

Because real sensors have noise, the target vector $\mathbf{y}$ does NOT live in the subspace spanned by our model features $X$: $X\mathbf{w} = \mathbf{y}$ has no exact solution!

The orthogonal projection operator solves this fundamental impossibility: it finds the best possible compromise $\hat{\mathbf{y}}$ that the model *can* represent, guaranteeing that the error vector is completely uncorrelated with all our features ($X^T \mathbf{e} = \mathbf{0}$).

### HOW IT WORKS
1. **Formulate the Residual**: Define error $\mathbf{e} = \mathbf{y} - X\mathbf{w}$.
2. **Enforce Orthogonality**: The error must be orthogonal to every column $\mathbf{x}_j$ of $X$:
   $$X^T \mathbf{e} = \mathbf{0} \implies X^T(\mathbf{y} - X\mathbf{w}) = \mathbf{0}$$
3. **Derive Normal Equations**:
   $$X^T X \mathbf{w} = X^T \mathbf{y}$$
4. **Solve for Weights & Projection**:
   $$\mathbf{w} = (X^T X)^{-1} X^T \mathbf{y} \implies \hat{\mathbf{y}} = X\mathbf{w} = \underbrace{X(X^T X)^{-1} X^T}_{P} \mathbf{y}$$

### CODE
```python
import numpy as np

# Generate overdetermined linear problem: m = 100, n = 3
np.random.seed(10)
m, n = 100, 3
X = np.random.randn(m, n)
y = np.random.randn(m)

# 1. Compute projection matrix P
P = X @ np.linalg.inv(X.T @ X) @ X.T

# 2. Verify idempotence: P^2 == P
P_sq = P @ P
print("Idempotence error ||P^2 - P||_F :", np.linalg.norm(P_sq - P))

# 3. Verify symmetry: P^T == P
print("Symmetry error ||P^T - P||_F   :", np.linalg.norm(P.T - P))

# 4. Project y and verify residual orthogonality
y_hat = P @ y
residual = y - y_hat
print("Orthogonality max |X^T e|      :", np.max(np.abs(X.T @ residual)))
```

---

## 3. Singular Value Decomposition (SVD) & Low-Rank Adaptation (LoRA)

### TERM
Singular Value Decomposition (SVD) and Low-Rank Adaptation (LoRA)

### DEFINITION
Every matrix $A \in \mathbb{R}^{m \times n}$ factorizes into the product of three canonical matrices:
$$A = U \Sigma V^T = \sum_{i=1}^r \sigma_i \mathbf{u}_i \mathbf{v}_i^T$$
where:
- $U \in \mathbb{R}^{m \times m}$ is an orthogonal matrix of left-singular vectors (eigenvectors of $A A^T$).
- $\Sigma \in \mathbb{R}^{m \times n}$ is a rectangular diagonal matrix containing singular values $\sigma_1 \ge \sigma_2 \ge \dots \ge \sigma_r \ge 0$.
- $V \in \mathbb{R}^{n \times n}$ is an orthogonal matrix of right-singular vectors (eigenvectors of $A^T A$).

By the **Eckart-Young-Mirsky Theorem**, the optimal rank-$k$ approximation ($k < r$) minimizing Frobenius norm error $\|A - A_k\|_F$ is obtained by truncating to the top $k$ components:
$$A_k = \sum_{i=1}^k \sigma_i \mathbf{u}_i \mathbf{v}_i^T$$

**Low-Rank Adaptation (LoRA)** applies this principle to neural network weight updates:
$$W = W_0 + \Delta W = W_0 + \frac{\alpha}{r} B A$$
where frozen base weights are $W_0 \in \mathbb{R}^{d \times k}$, and trainable adapters are $B \in \mathbb{R}^{d \times r}$ and $A \in \mathbb{R}^{r \times k}$ with rank $r \ll \min(d, k)$.

### INTUITION
Any geometric deformation of space—no matter how skewed or rotated—can be dissected into three simple consecutive actions:
1. **Rotate** coordinates using orthonormal basis $V^T$.
2. **Scale** coordinates along independent axes using singular values $\sigma_i$.
3. **Rotate** again using orthonormal basis $U$.

When inspecting the singular values $\sigma_i$, we notice that the first few values are huge, while the rest plummet toward zero. The matrix contains massive redundancy! 

In an LLM with 7 billion parameters, adapting the model to a new task (e.g., medical diagnoses or Python coding) does not require changing all billions of degrees of freedom. The necessary changes lie in a narrow, low-rank subspace. LoRA captures this change by training two tiny skinny matrices ($B$ and $A$) sandwiched together, creating a bottleneck that forces the network to learn only the principal directions of adaptation.

### WHY IT EXISTS
Full parameter fine-tuning of modern LLMs requires storing optimizer states (Adam requires 8 bytes per parameter), gradients, and activations for tens of billions of weights. For a 70B parameter model, full fine-tuning demands hundreds of gigabytes of VRAM across multiple expensive enterprise GPUs.

LoRA slashes trainable parameter counts by $95\%$ to $99\%$. For example, fine-tuning a $4096 \times 4096$ matrix ($16,777,216$ parameters) with rank $r = 8$ requires training only:
$$\text{Params}_{\text{LoRA}} = 4096 \times 8 + 8 \times 4096 = 65,536 \quad (\mathbf{99.61\%\text{ parameter reduction!}})$$

### HOW IT WORKS
1. **Freeze Base Weights**: Keep pre-trained weights $W_0 \in \mathbb{R}^{d \times k}$ permanently fixed.
2. **Initialize Adapter Matrices**:
   - Initialize $A \sim \mathcal{N}(0, \sigma^2)$ to break symmetry.
   - Initialize $B = \mathbf{0}$ so that $\Delta W = B \cdot A = \mathbf{0}$ at step 0 (ensuring the model starts with exactly zero behavioral divergence).
3. **Forward Pass**:
   $$\mathbf{h} = W_0 \mathbf{x} + \frac{\alpha}{r} B (A \mathbf{x})$$
4. **Deploy / Merge**: At inference time, compute $\Delta W = \frac{\alpha}{r} B A$ and add it directly into $W_0$. The model has zero latency penalty during production deployment!

### CODE
```python
import numpy as np

# Simulate a 1024x1024 attention projection matrix
d, k = 1024, 1024
r = 8  # LoRA rank

# Pre-trained base weights
W0 = np.random.randn(d, k) * 0.02

# LoRA adapters
A = np.random.randn(r, k) * (1.0 / np.sqrt(k))
B = np.zeros((d, r))  # Zero initialization guarantees Delta W = 0 at start

# Compute parameter reduction
orig_params = d * k
lora_params = (d * r) + (r * k)
reduction_pct = (1.0 - lora_params / orig_params) * 100

print(f"Original Weight Parameters : {orig_params:,}")
print(f"LoRA Adapter Parameters    : {lora_params:,}")
print(f"Parameter Reduction        : {reduction_pct:.2f}%")

# Forward pass simulation on batch of 16 tokens
x = np.random.randn(16, k)
# Efficient bottleneck computation: x @ A^T (16x8) -> then @ B^T (16x1024)
delta_h = (x @ A.T) @ B.T
h_total = x @ W0.T + (16.0 / r) * delta_h
print(f"Output Activation Shape    : {h_total.shape}")
```

---

## 4. Scaled Dot-Product Attention Mechanism

### TERM
Scaled Dot-Product Attention

### DEFINITION
Given query matrix $Q \in \mathbb{R}^{N \times d_k}$, key matrix $K \in \mathbb{R}^{M \times d_k}$, and value matrix $V \in \mathbb{R}^{M \times d_v}$:
$$\text{Attention}(Q, K, V) = \text{softmax}\left(\frac{Q K^T}{\sqrt{d_k}}\right) V$$
where row-wise softmax is defined as:
$$\text{softmax}(S)_{ij} = \frac{\exp(S_{ij})}{\sum_{l=1}^M \exp(S_{il})}$$

### INTUITION
Attention is a **differentiable fuzzy dictionary lookup**:
- **Queries ($Q$)**: The questions each token is asking ("What adjective describes me?").
- **Keys ($K$)**: The tags or labels each token offers ("I am an adjective").
- **Values ($V$)**: The actual informational content to be retrieved.

When you multiply $Q$ by $K^T$, you take the dot product between every query and every key. Large dot products mean high alignment. Softmax converts these alignment scores into a set of probability weights summing to $1.0$ across each row. Finally, multiplying by $V$ computes a weighted blend of all value vectors in the sequence.

### WHY IT EXISTS
Before the Transformer (2017), sequence modeling relied on Recurrent Neural Networks (RNNs) and LSTMs. RNNs suffered from two structural failures:
1. **Sequential Bottleneck**: To process token 500, you had to sequentially step through tokens 1 through 499. No parallelization was possible.
2. **Vanishing Gradient Over Long Distances**: Information decayed exponentially across long sequences.

Scaled Dot-Product Attention connects **every token to every other token in a single matrix multiplication ($O(1)$ path length)**, enabling massive GPU parallelization.

Furthermore, **the scaling factor $\frac{1}{\sqrt{d_k}}$ is mathematically necessary**:
If components of $\mathbf{q}$ and $\mathbf{k}$ are independent random variables with zero mean and unit variance ($\mathbb{E}[q_i] = 0, \text{Var}(q_i) = 1$):
$$\mathbf{q} \cdot \mathbf{k} = \sum_{i=1}^{d_k} q_i k_i$$
$$\mathbb{E}[\mathbf{q} \cdot \mathbf{k}] = 0, \quad \text{Var}(\mathbf{q} \cdot \mathbf{k}) = \sum_{i=1}^{d_k} \text{Var}(q_i k_i) = d_k$$
For large key dimensions ($d_k = 64$ or $128$), the variance of the dot product is $64$ or $128$! Unscaled scores would routinely exceed $\pm 20$. In these extreme regions, the softmax function saturates into $1$ and $0$, with derivatives $\sigma'(z) \approx 0$. 

Dividing by $\sqrt{d_k}$ normalizes the variance back to $1.0$, keeping gradients alive and allowing deep networks to train!

### HOW IT WORKS
1. **Compute Inner Products**: $S_{\text{raw}} = Q K^T \in \mathbb{R}^{N \times M}$.
2. **Scale**: $S_{\text{scaled}} = \frac{S_{\text{raw}}}{\sqrt{d_k}}$.
3. **Numerically Stable Softmax**:
   $$S_{\text{shift}} = S_{\text{scaled}} - \max(S_{\text{scaled}}, \text{axis}=-1)$$
   $$W = \frac{\exp(S_{\text{shift}})}{\sum \exp(S_{\text{shift}})}$$
4. **Context Aggregation**: $\text{Context} = W V \in \mathbb{R}^{N \times d_v}$.

### CODE
```python
import numpy as np

def scaled_dot_product_attention(Q, K, V, mask=None):
    """
    Computes Scaled Dot-Product Attention from scratch using pure NumPy.
    Q: (seq_len_q, d_k)
    K: (seq_len_kv, d_k)
    V: (seq_len_kv, d_v)
    """
    d_k = Q.shape[-1]
    
    # 1. Dot product similarity scores
    scores = (Q @ K.T) / np.sqrt(d_k)
    
    # Optional causal masking (for autoregressive decoders)
    if mask is not None:
        scores = np.where(mask == 0, -1e9, scores)
    
    # 2. Numerically stable softmax
    scores_shifted = scores - np.max(scores, axis=-1, keepdims=True)
    exp_scores = np.exp(scores_shifted)
    attention_weights = exp_scores / np.sum(exp_scores, axis=-1, keepdims=True)
    
    # 3. Contextual value aggregation
    output = attention_weights @ V
    return output, attention_weights

# Verification test
seq_len, d_k, d_v = 4, 64, 64
np.random.seed(0)
Q = np.random.randn(seq_len, d_k)
K = np.random.randn(seq_len, d_k)
V = np.random.randn(seq_len, d_v)

context, weights = scaled_dot_product_attention(Q, K, V)
print("Attention weights shape :", weights.shape)
print("Row sums (must be 1.0)  :", np.sum(weights, axis=-1))
print("Context output shape    :", context.shape)
```
