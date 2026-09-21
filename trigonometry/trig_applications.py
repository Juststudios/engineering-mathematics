"""
Trigonometry Applications
  1. Pygame-style 2D movement
  2. AC signal (engineering)
  3. Positional Encoding (Transformer / ML)
"""
import math, matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
from pathlib import Path

OUT = Path(__file__).parent / "output"
OUT.mkdir(exist_ok=True)

# ── Application 1: 2D game movement ─────────────────────────────────────────
print("=== 1. 2D Movement (Pygame-style) ===")
speed = 5.0
for deg in range(0, 361, 45):
    rad = math.radians(deg)
    vx  = speed * math.cos(rad)
    vy  = speed * math.sin(rad)
    print(f"  {deg:3}° → dx={vx:+.2f}  dy={vy:+.2f}")

# ── Application 2: AC voltage signal ────────────────────────────────────────
print("\n=== 2. AC Voltage Signal V(t) = A·sin(2πft) ===")
A, f = 120.0, 60.0   # 120V amplitude, 60Hz
t_vals = np.linspace(0, 1/f, 200)
V = A * np.sin(2 * np.pi * f * t_vals)

fig, axes = plt.subplots(1, 2, figsize=(12, 4))
axes[0].plot(t_vals * 1000, V, 'b-', linewidth=2)
axes[0].set_xlabel("Time (ms)"); axes[0].set_ylabel("Voltage (V)")
axes[0].set_title(f"AC Signal: {A}V @ {f}Hz")
axes[0].axhline(0, color='k', linewidth=0.5); axes[0].grid(True, alpha=0.3)
print(f"  Peak: {V.max():.1f}V, RMS: {np.sqrt(np.mean(V**2)):.1f}V")

# ── Application 3: Positional Encoding (Transformer) ────────────────────────
print("\n=== 3. Positional Encoding (Transformer) ===")
d_model, max_len = 16, 50
PE = np.zeros((max_len, d_model))
for pos in range(max_len):
    for i in range(0, d_model, 2):
        PE[pos, i]   = math.sin(pos / (10000 ** (i / d_model)))
        if i+1 < d_model:
            PE[pos, i+1] = math.cos(pos / (10000 ** (i / d_model)))

im = axes[1].imshow(PE, aspect='auto', cmap='RdBu')
axes[1].set_title("Positional Encoding Matrix (Transformer)")
axes[1].set_xlabel("Embedding dimension"); axes[1].set_ylabel("Token position")
plt.colorbar(im, ax=axes[1])
print(f"  PE shape: {PE.shape}")
print(f"  PE[0,:4] = {PE[0,:4].round(4)}")

plt.tight_layout()
path = OUT / "trig_applications.png"
plt.savefig(path, dpi=150, bbox_inches='tight')
print(f"\nSaved: {path}")
