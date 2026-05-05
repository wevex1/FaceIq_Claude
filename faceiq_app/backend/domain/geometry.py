"""Pure geometry and scoring helpers used by the analyzer."""

import math


def dist(p1, p2) -> float:
    if p1 is None or p2 is None:
        return 0.0
    return math.hypot(p1[0] - p2[0], p1[1] - p2[1])


def angle_at_vertex(A, B, C) -> float:
    """Angle in degrees at vertex B in triangle A-B-C."""
    if A is None or B is None or C is None:
        return 0.0
    BA = (A[0] - B[0], A[1] - B[1])
    BC = (C[0] - B[0], C[1] - B[1])
    dot = BA[0] * BC[0] + BA[1] * BC[1]
    mag = math.hypot(*BA) * math.hypot(*BC)
    if mag == 0:
        return 0.0
    return math.degrees(math.acos(max(-1.0, min(1.0, dot / mag))))


def signed_dist_to_line(point, line_start, line_end) -> float:
    """Signed perpendicular distance from point to line."""
    if point is None or line_start is None or line_end is None:
        return 0.0
    dx = line_end[0] - line_start[0]
    dy = line_end[1] - line_start[1]
    length = math.hypot(dx, dy)
    if length == 0:
        return 0.0
    return (dy * (point[0] - line_start[0]) - dx * (point[1] - line_start[1])) / length


def line_angle_to_horizontal(p1, p2) -> float:
    """Angle of line p1→p2 relative to horizontal, in degrees."""
    if p1 is None or p2 is None:
        return 0.0
    dx = p2[0] - p1[0]
    dy = p2[1] - p1[1]
    return math.degrees(math.atan2(-dy, dx))  # flip y (image coords)


def midpoint(p1, p2):
    if p1 is None or p2 is None:
        return None
    return ((p1[0] + p2[0]) / 2, (p1[1] + p2[1]) / 2)


def score_from_range(
    value: float,
    ideal_min: float,
    ideal_max: float,
    tolerance: float = 0.3,
) -> float:
    if ideal_min is None or ideal_max is None:
        return 5.0
    mid = (ideal_min + ideal_max) / 2.0
    half = (ideal_max - ideal_min) / 2.0
    if half == 0:
        return 10.0 if abs(value - mid) < 1e-9 else 5.0
    if ideal_min <= value <= ideal_max:
        deviation = abs(value - mid) / half
        return 10.0 - 2.0 * deviation
    outer = min(abs(value - ideal_min), abs(value - ideal_max))
    max_outer = tolerance * (ideal_max - ideal_min)
    penalty = min(1.0, outer / max(max_outer, 1e-9))
    return max(0.0, 8.0 - 8.0 * penalty)
