"""Metric implementations for the Facial Convexity category."""

from __future__ import annotations

import math

from domain.geometry import angle_at_vertex, dist
from domain.interfaces import LandmarkMap
from metrics.common import ComputedMetric, register_metrics


def _face_h(lm: LandmarkMap) -> float:
    return dist(lm.get("nasion"), lm.get("pogonion"))


def _facial_convexity_glabella(lm: LandmarkMap):
    if lm.get("glabella") and lm.get("subnasale") and lm.get("pogonion"):
        return angle_at_vertex(lm.get("glabella"), lm.get("subnasale"), lm.get("pogonion"))
    return None


def _facial_convexity_nasion(lm: LandmarkMap):
    if lm.get("nasion") and lm.get("subnasale") and lm.get("pogonion"):
        return angle_at_vertex(lm.get("nasion"), lm.get("subnasale"), lm.get("pogonion"))
    return None


def _total_facial_convexity(lm: LandmarkMap):
    if lm.get("glabella") and lm.get("pronasale") and lm.get("pogonion"):
        return angle_at_vertex(lm.get("glabella"), lm.get("pronasale"), lm.get("pogonion"))
    return None


def _anterior_facial_depth_ratio(lm: LandmarkMap):
    face_h = _face_h(lm)
    if lm.get("nasion") and lm.get("pogonion") and face_h > 0:
        return abs(lm.get("nasion")[0] - lm.get("pogonion")[0]) / face_h
    return None


def _facial_depth_height_ratio(lm: LandmarkMap):
    face_h = _face_h(lm)
    if lm.get("glabella") and lm.get("pogonion") and lm.get("nasion") and face_h > 0:
        return dist(lm.get("glabella"), lm.get("pogonion")) / face_h
    return None


def _z_angle(lm: LandmarkMap):
    if lm.get("ex_L") and lm.get("pogonion") and lm.get("pronasale"):
        return angle_at_vertex(lm.get("ex_L"), lm.get("pogonion"), lm.get("pronasale"))
    return None


def _interior_midface_projection_angle(lm: LandmarkMap):
    nasion = lm.get("nasion")
    pronasale = lm.get("pronasale")
    if nasion and pronasale:
        dx = pronasale[0] - nasion[0]
        dy = abs(pronasale[1] - nasion[1])
        if dy > 0:
            return math.degrees(math.atan2(abs(dx), dy))
    return None


register_metrics(
    ComputedMetric("Facial Convexity (Glabella)", "Facial Convexity", 160, 175, "Â°", _facial_convexity_glabella, "Profile angle at subnasale. ~180Â° = flat profile; lower = more convex/protruding face."),
    ComputedMetric("Facial Convexity (Nasion)", "Facial Convexity", 155, 175, "Â°", _facial_convexity_nasion, "Profile convexity from nasion. Lower = more convex face profile."),
    ComputedMetric("Total Facial Convexity", "Facial Convexity", 130, 155, "Â°", _total_facial_convexity, "Overall profile curvature. ~145Â° is harmonious balance between brow, nose and chin."),
    ComputedMetric("Anterior Facial Depth Ratio", "Facial Convexity", 0.15, 0.35, "Ã—", _anterior_facial_depth_ratio, "Horizontal projection of chin relative to nasion, normalised by face height."),
    ComputedMetric("Facial Depth / Height Ratio", "Facial Convexity", 1.1, 1.4, "Ã—", _facial_depth_height_ratio, "Diagonal face depth vs face height. ~1.3Ã— indicates well-projected profile."),
    ComputedMetric("Z Angle", "Facial Convexity", 70, 85, "Â°", _z_angle, "Ricketts' Z-angle. ~80Â° is the aesthetic ideal. Lower = retruded chin."),
    ComputedMetric("Interior Midface Projection Angle", "Facial Convexity", 15, 35, "Â°", _interior_midface_projection_angle, "Nose projection angle from vertical. Higher = more protruding nose in profile."),
)
