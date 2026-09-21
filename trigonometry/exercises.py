"""Trigonometry Exercises"""
import math

# Level 1: Calculate
# What is sin(30°)? cos(60°)? tan(45°)?
# Verify: sin²(60°) + cos²(60°) == 1

# Level 2: TODO — write a function `polar_to_cartesian(r, theta_deg)`
# that converts polar coordinates to (x, y).
def polar_to_cartesian(r: float, theta_deg: float) -> tuple[float, float]:
    raise NotImplementedError

# Level 3: TODO — write a function `angle_between_vectors(v1, v2)`
# using the dot product formula: cos(θ) = (v1·v2) / (|v1|·|v2|)
def angle_between_vectors(v1: list[float], v2: list[float]) -> float:
    """Returns angle in degrees."""
    raise NotImplementedError

# Level 4: TODO — generate a positional encoding row for position `pos`
# with embedding dimension `d_model` using the Transformer formula.
def positional_encoding_row(pos: int, d_model: int) -> list[float]:
    raise NotImplementedError
