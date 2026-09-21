# Trigonometry

**Where it fits:** After the basic algebra of `linear_algebra/` and before the
rates-of-change in `calculus/`. Trigonometry provides the geometric intuition
behind vectors, oscillations, and periodic functions.

---

## 1. What is an Angle?

An angle describes a rotation or a direction.

```
         *
        /|
 hyp   / |  opposite
      /  |
     /θ  |
    *----*
     adjacent
```

### Degrees vs Radians

| Unit | Full circle | Formula |
|------|------------|---------|
| Degrees | 360° | — |
| Radians | 2π ≈ 6.283 | rad = deg × π/180 |

**Why radians in calculus?** The derivative of sin(x) is cos(x) *only when x is in radians*.
In degrees, you'd need a correction factor of π/180 everywhere.

---

## 2. Right-Triangle Definitions

For angle θ in a right triangle:

```
sin(θ) = opposite / hypotenuse
cos(θ) = adjacent / hypotenuse
tan(θ) = opposite / adjacent
```

### Deriving tan from sin and cos (step by step)

```
tan(θ) = sin(θ) / cos(θ)
       = (opposite / hypotenuse) / (adjacent / hypotenuse)
       = (opposite / hypotenuse) × (hypotenuse / adjacent)
       = opposite / adjacent   ✓
```

---

## 3. The Unit Circle

A circle with radius 1 centred at the origin.
For a point at angle θ:

```
x = cos(θ)   ← horizontal component
y = sin(θ)   ← vertical component
```

Key values:

| θ (degrees) | θ (radians) | cos(θ) | sin(θ) |
|------------|------------|--------|--------|
| 0° | 0 | 1 | 0 |
| 30° | π/6 | √3/2 ≈ 0.866 | 1/2 = 0.5 |
| 45° | π/4 | √2/2 ≈ 0.707 | √2/2 ≈ 0.707 |
| 60° | π/3 | 1/2 = 0.5 | √3/2 ≈ 0.866 |
| 90° | π/2 | 0 | 1 |

---

## 4. Identities

```
sin²(θ) + cos²(θ) = 1          ← Pythagorean identity (from unit circle)
sin(-θ) = -sin(θ)              ← sine is odd
cos(-θ) =  cos(θ)              ← cosine is even
```

---

## 5. Connections

### 5a. Pygame / Game AI — 2D Movement
```python
import math
vx = speed * math.cos(angle_rad)
vy = speed * math.sin(angle_rad)
```
This translates a direction angle into x/y velocity components.

### 5b. Engineering — AC Signals
A sinusoidal voltage: `V(t) = A·sin(2πft + φ)`
where f = frequency (Hz), φ = phase offset.

### 5c. Machine Learning — Positional Encoding (Transformers)
```
PE(pos, 2i)   = sin(pos / 10000^(2i/d_model))
PE(pos, 2i+1) = cos(pos / 10000^(2i/d_model))
```
Allows the Transformer to distinguish token positions using periodic functions.

---

## Files

| File | Purpose |
|------|---------|
| `trig_demo.py` | Interactive Python demos |
| `unit_circle.py` | Visualise the unit circle with Matplotlib |
| `trig_applications.py` | Engineering & ML applications |
| `trig_basics.m` | MATLAB companion |
| `exercises.py` | Practice problems |
| `solutions.py` | Reference solutions |
