"""Trigonometry Demo — angles, sin, cos, tan, unit circle."""
import math

print("=== Degrees ↔ Radians ===")
for deg in [0, 30, 45, 60, 90, 180, 270, 360]:
    rad = math.radians(deg)
    print(f"  {deg:3}° = {rad:.4f} rad  |  sin={math.sin(rad):+.4f}  cos={math.cos(rad):+.4f}")

print("\n=== Pythagorean Identity: sin²+cos²=1 ===")
for deg in [0, 30, 60, 90]:
    r = math.radians(deg)
    check = math.sin(r)**2 + math.cos(r)**2
    print(f"  {deg}°: sin²+cos² = {check:.10f}")

print("\n=== tan derivation check: tan=sin/cos ===")
for deg in [30, 45, 60]:
    r = math.radians(deg)
    tan_formula  = math.sin(r) / math.cos(r)
    tan_builtin  = math.tan(r)
    print(f"  {deg}°: sin/cos={tan_formula:.6f}  math.tan={tan_builtin:.6f}")

print("\n=== 2D movement from angle ===")
speed = 10
for deg in [0, 45, 90, 135, 180]:
    r  = math.radians(deg)
    vx = speed * math.cos(r)
    vy = speed * math.sin(r)
    print(f"  angle={deg:3}° → vx={vx:+6.2f}  vy={vy:+6.2f}")
