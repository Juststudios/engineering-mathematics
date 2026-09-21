"""Visualise the unit circle and key trig values."""
import math, matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
from pathlib import Path

OUT = Path(__file__).parent / "output"
OUT.mkdir(exist_ok=True)

fig, axes = plt.subplots(1, 2, figsize=(12, 5))

# ── Panel 1: Unit Circle ────────────────────────────────────────────────────
ax = axes[0]
theta = np.linspace(0, 2*np.pi, 300)
ax.plot(np.cos(theta), np.sin(theta), 'b-', linewidth=2, label="Unit circle")
ax.axhline(0, color='k', linewidth=0.5)
ax.axvline(0, color='k', linewidth=0.5)

key_angles = [0, 30, 45, 60, 90, 120, 135, 150, 180]
for deg in key_angles:
    r = math.radians(deg)
    x, y = math.cos(r), math.sin(r)
    ax.plot([0, x], [0, y], 'g--', alpha=0.5, linewidth=1)
    ax.plot(x, y, 'ro', markersize=6)
    ax.annotate(f"{deg}°", (x*1.15, y*1.15), ha='center', va='center', fontsize=8)

ax.set_xlim(-1.4, 1.4); ax.set_ylim(-1.4, 1.4)
ax.set_aspect('equal'); ax.set_title("Unit Circle")
ax.set_xlabel("cos(θ)"); ax.set_ylabel("sin(θ)")
ax.grid(True, alpha=0.3)

# ── Panel 2: sin and cos waves ──────────────────────────────────────────────
ax2 = axes[1]
t = np.linspace(0, 2*np.pi, 300)
ax2.plot(np.degrees(t), np.sin(t), 'b-', label='sin(θ)', linewidth=2)
ax2.plot(np.degrees(t), np.cos(t), 'r-', label='cos(θ)', linewidth=2)
ax2.axhline(0, color='k', linewidth=0.5)
ax2.set_xlabel("θ (degrees)"); ax2.set_ylabel("Value")
ax2.set_title("sin and cos Waves")
ax2.legend(); ax2.grid(True, alpha=0.3)
ax2.set_xticks([0, 90, 180, 270, 360])

plt.tight_layout()
path = OUT / "unit_circle.png"
plt.savefig(path, dpi=150, bbox_inches='tight')
print(f"Saved: {path}")
