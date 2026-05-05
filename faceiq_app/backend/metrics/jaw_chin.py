"""Metric implementations for the Jaw & Chin category."""

from __future__ import annotations

import math

from domain.geometry import dist
from domain.interfaces import LandmarkMap
from metrics.common import ComputedMetric, register_metrics


def _face_w(lm: LandmarkMap) -> float:
    return dist(lm.get("zy_L"), lm.get("zy_R"))


def _face_h(lm: LandmarkMap) -> float:
    return dist(lm.get("nasion"), lm.get("pogonion"))


def _lower_third_proportion(lm: LandmarkMap):
    face_h = _face_h(lm)
    if lm.get("subnasale") and lm.get("pogonion") and lm.get("nasion") and face_h > 0:
        return dist(lm.get("subnasale"), lm.get("pogonion")) / face_h * 100
    return None


def _jaw_slope_angle(lm: LandmarkMap):
    go_l = lm.get("go_L")
    pogonion = lm.get("pogonion")
    go_r = lm.get("go_R")
    if go_l and pogonion and go_r:
        dx_l = abs(pogonion[0] - go_l[0])
        dy_l = abs(pogonion[1] - go_l[1])
        dx_r = abs(go_r[0] - pogonion[0])
        dy_r = abs(go_r[1] - pogonion[1])
        ang_l = math.degrees(math.atan2(dy_l, dx_l)) if dx_l > 0 else 90
        ang_r = math.degrees(math.atan2(dy_r, dx_r)) if dx_r > 0 else 90
        return (ang_l + ang_r) / 2
    return None


def _bigonial_bizygomatic_ratio(lm: LandmarkMap):
    face_w = _face_w(lm)
    if lm.get("go_L") and lm.get("go_R") and face_w > 0:
        return dist(lm.get("go_L"), lm.get("go_R")) / face_w
    return None


def _face_taper_index(lm: LandmarkMap):
    if lm.get("zy_L") and lm.get("zy_R") and lm.get("go_L") and lm.get("go_R"):
        taper = dist(lm.get("zy_L"), lm.get("zy_R")) - dist(lm.get("go_L"), lm.get("go_R"))
        face_w_ref = dist(lm.get("zy_L"), lm.get("zy_R"))
        if face_w_ref > 0:
            return taper / face_w_ref * 100
    return None


def _neck_width_face_width(lm: LandmarkMap):
    face_w = _face_w(lm)
    if lm.get("neck_L") and lm.get("neck_R") and face_w > 0:
        return dist(lm.get("neck_L"), lm.get("neck_R")) / face_w * 100
    return None


def _chin_height_lower_third(lm: LandmarkMap):
    if lm.get("li") and lm.get("pogonion") and lm.get("subnasale"):
        chin_h = dist(lm.get("li"), lm.get("pogonion"))
        lower3 = dist(lm.get("subnasale"), lm.get("pogonion"))
        if lower3 > 0:
            return chin_h / lower3 * 100
    return None


def _gonion_position_percent(lm: LandmarkMap):
    face_h = _face_h(lm)
    go_l = lm.get("go_L")
    go_r = lm.get("go_R")
    nasion = lm.get("nasion")
    pogonion = lm.get("pogonion")
    if go_l and go_r and nasion and pogonion and face_h > 0:
        go_mid_y = (go_l[1] + go_r[1]) / 2
        return (go_mid_y - nasion[1]) / face_h * 100
    return None


register_metrics(
    ComputedMetric("Lower Third Proportion", "Jaw & Chin", 30, 38, "%", _lower_third_proportion, "Lower face from subnasale to chin as % of total face. ~33% ideal."),
    ComputedMetric("Jaw Slope Angle", "Jaw & Chin", 20, 40, "Â°", _jaw_slope_angle, "Inclination of jawline from horizontal. Higher = steeper, more angular jaw."),
    ComputedMetric("Bigonial / Bizygomatic Ratio", "Jaw & Chin", 0.75, 0.90, "Ã—", _bigonial_bizygomatic_ratio, "Jaw width / cheekbone width. Lower ratio = more tapered (feminine) jaw."),
    ComputedMetric("Face Taper Index", "Jaw & Chin", 8, 20, "%", _face_taper_index, "Cheekbone vs jaw width difference as % of face width. Higher = more V-shaped face."),
    ComputedMetric("Neck Width / Face Width", "Jaw & Chin", 55, 75, "%", _neck_width_face_width, "Neck width as % of face width. Lower = slender neck relative to face."),
    ComputedMetric("Chin Height / Lower Third", "Jaw & Chin", 40, 55, "%", _chin_height_lower_third, "Chin height (below lower lip) as % of lower third. Ideal chin is ~50% of lower third."),
    ComputedMetric("Gonion Position (% from nasion)", "Jaw & Chin", 70, 85, "%", _gonion_position_percent, "Jaw angle vertical position as % down from nasion. Lower % = higher jaw angles."),
)
