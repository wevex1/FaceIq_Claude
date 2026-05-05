"""Metric implementations for the Upper Face (Profile) category."""

from __future__ import annotations

from domain.geometry import angle_at_vertex, dist, line_angle_to_horizontal
from domain.interfaces import LandmarkMap
from metrics.common import ComputedMetric, register_metrics


def _face_h(lm: LandmarkMap) -> float:
    return dist(lm.get("nasion"), lm.get("pogonion"))


def _upper_forehead_slope(lm: LandmarkMap):
    if lm.get("glabella") and lm.get("trichion"):
        slope = abs(line_angle_to_horizontal(lm.get("glabella"), lm.get("trichion")))
        return abs(90 - slope)
    return None


def _browridge_inclination(lm: LandmarkMap):
    if lm.get("glabella") and lm.get("brow_apex_L"):
        return abs(line_angle_to_horizontal(lm.get("glabella"), lm.get("brow_apex_L")))
    return None


def _nasofrontal_angle(lm: LandmarkMap):
    if lm.get("glabella") and lm.get("nasion") and lm.get("pronasale"):
        return angle_at_vertex(lm.get("glabella"), lm.get("nasion"), lm.get("pronasale"))
    return None


def _forehead_height_face_height(lm: LandmarkMap):
    face_h = _face_h(lm)
    if lm.get("glabella") and lm.get("nasion") and face_h > 0:
        return dist(lm.get("glabella"), lm.get("nasion")) / face_h * 100
    return None


register_metrics(
    ComputedMetric("Upper Forehead Slope", "Upper Face (Profile)", 0, 10, "Â°", _upper_forehead_slope, "Tilt of forehead from vertical. ~0Â° = perfectly upright forehead."),
    ComputedMetric("Browridge Inclination", "Upper Face (Profile)", 8, 20, "Â°", _browridge_inclination, "Angle of browridge slope. Higher = more pronounced brow ridge prominence."),
    ComputedMetric("Nasofrontal Angle", "Upper Face (Profile)", 115, 135, "Â°", _nasofrontal_angle, "Forehead-nose junction angle. ~125Â° = smooth balanced transition. <115Â° = deep set nasion."),
    ComputedMetric("Forehead Height / Face Height", "Upper Face (Profile)", 28, 38, "%", _forehead_height_face_height, "Forehead segment as % of total face. ~33% is the ideal upper third."),
)
