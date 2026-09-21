"""Trigonometry Solutions"""
import math

# Level 1:
print(f"sin(30°) = {math.sin(math.radians(30)):.4f}")   # 0.5
print(f"cos(60°) = {math.cos(math.radians(60)):.4f}")   # 0.5
print(f"tan(45°) = {math.tan(math.radians(45)):.4f}")   # 1.0

# Level 2:
def polar_to_cartesian(r, theta_deg):
    rad = math.radians(theta_deg)
    return (r * math.cos(rad), r * math.sin(rad))

# Level 3:
def angle_between_vectors(v1, v2):
    dot  = sum(a*b for a, b in zip(v1, v2))
    mag1 = math.sqrt(sum(a**2 for a in v1))
    mag2 = math.sqrt(sum(b**2 for b in v2))
    cos_theta = max(-1.0, min(1.0, dot / (mag1 * mag2)))
    return math.degrees(math.acos(cos_theta))

# Level 4:
def positional_encoding_row(pos, d_model):
    row = []
    for i in range(0, d_model, 2):
        row.append(math.sin(pos / (10000 ** (i / d_model))))
        if i + 1 < d_model:
            row.append(math.cos(pos / (10000 ** (i / d_model))))
    return row
