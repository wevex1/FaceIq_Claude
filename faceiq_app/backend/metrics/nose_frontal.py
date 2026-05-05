"""Metric implementations for the Nose (Frontal) category."""

from __future__ import annotations

from domain.geometry import angle_at_vertex, dist, signed_dist_to_line
from domain.interfaces import LandmarkMap
from metrics.common import ComputedMetric, register_metrics


def _face_w(lm: LandmarkMap) -> float:
    return dist(lm.get("zy_L"), lm.get("zy_R"))


def _face_h(lm: LandmarkMap) -> float:
    return dist(lm.get("nasion"), lm.get("pogonion"))


def _intercanthal_nasal_width_ratio(lm: LandmarkMap):
    if lm.get("en_L") and lm.get("en_R") and lm.get("al_L") and lm.get("al_R"):
        return dist(lm.get("en_L"), lm.get("en_R")) / dist(lm.get("al_L"), lm.get("al_R"))
    return None


def _nose_bridge_width_ratio(lm: LandmarkMap):
    if lm.get("nasion") and lm.get("pronasale") and lm.get("al_L") and lm.get("al_R"):
        nw = dist(lm.get("al_L"), lm.get("al_R"))
        if nw > 0:
            return dist(lm.get("nasion"), lm.get("pronasale")) / nw
    return None


def _nasal_width_face_width(lm: LandmarkMap):
    face_w = _face_w(lm)
    if lm.get("al_L") and lm.get("al_R") and face_w > 0:
        return dist(lm.get("al_L"), lm.get("al_R")) / face_w * 100
    return None


def _nose_tip_deviation(lm: LandmarkMap):
    face_w = _face_w(lm)
    if lm.get("pronasale") and lm.get("nasion") and lm.get("pogonion") and face_w > 0:
        dev = abs(signed_dist_to_line(lm.get("pronasale"), lm.get("nasion"), lm.get("pogonion")))
        return dev / face_w * 100
    return None


def _ipsilateral_alar_angle_left(lm: LandmarkMap):
    if lm.get("al_L") and lm.get("subnasale") and lm.get("pronasale"):
        return angle_at_vertex(lm.get("al_L"), lm.get("subnasale"), lm.get("pronasale"))
    return None


def _ipsilateral_alar_angle_right(lm: LandmarkMap):
    if lm.get("al_R") and lm.get("subnasale") and lm.get("pronasale"):
        return angle_at_vertex(lm.get("al_R"), lm.get("subnasale"), lm.get("pronasale"))
    return None


def _iaa_left_right_deviation(lm: LandmarkMap):
    if lm.get("al_L") and lm.get("al_R") and lm.get("subnasale") and lm.get("pronasale"):
        iaa_l = angle_at_vertex(lm.get("al_L"), lm.get("subnasale"), lm.get("pronasale"))
        iaa_r = angle_at_vertex(lm.get("al_R"), lm.get("subnasale"), lm.get("pronasale"))
        return abs(iaa_l - iaa_r)
    return None


def _jaw_frontal_angle(lm: LandmarkMap):
    if lm.get("go_L") and lm.get("pogonion") and lm.get("go_R"):
        return angle_at_vertex(lm.get("go_L"), lm.get("pogonion"), lm.get("go_R"))
    return None


def _nose_height_face_height(lm: LandmarkMap):
    face_h = _face_h(lm)
    if lm.get("nasion") and lm.get("subnasale") and face_h > 0:
        return dist(lm.get("nasion"), lm.get("subnasale")) / face_h * 100
    return None


register_metrics(
    ComputedMetric("Intercanthal / Nasal Width Ratio", "Nose (Frontal)", 0.85, 1.15, "Ã—", _intercanthal_nasal_width_ratio, "Inner eye span vs alar width. ~1.0 = nose as wide as eye spacing (ideal harmony)."),
    ComputedMetric("Nose Bridge / Width Ratio", "Nose (Frontal)", 2.2, 3.2, "Ã—", _nose_bridge_width_ratio, "Nose height vs width. Higher = narrow prominent nose; lower = wide flat nose."),
    ComputedMetric("Nasal Width / Face Width", "Nose (Frontal)", 22, 28, "%", _nasal_width_face_width, "Nose width as % of face width. Classical ideal ~25%."),
    ComputedMetric("Nose Tip Deviation", "Nose (Frontal)", 0, 2, "%", _nose_tip_deviation, "Lateral offset of nose tip from face midline. Ideal = 0 (centred)."),
    ComputedMetric("Ipsilateral Alar Angle (Left)", "Nose (Frontal)", 80, 100, "Â°", _ipsilateral_alar_angle_left, "Angle at subnasale between left ala and nose tip. ~90Â° = well-defined nostril."),
    ComputedMetric("Ipsilateral Alar Angle (Right)", "Nose (Frontal)", 80, 100, "Â°", _ipsilateral_alar_angle_right, "Angle at subnasale between right ala and nose tip. ~90Â° = well-defined nostril."),
    ComputedMetric("IAA Left-Right Deviation", "Nose (Frontal)", 0, 5, "Â°", _iaa_left_right_deviation, "Asymmetry between left and right alar angles. Lower = more symmetric nose."),
    ComputedMetric("Jaw Frontal Angle", "Nose (Frontal)", 80, 100, "Â°", _jaw_frontal_angle, "Angle at chin between jaw lines. ~90Â° = well-defined square chin."),
    ComputedMetric("Nose Height / Face Height", "Nose (Frontal)", 28, 35, "%", _nose_height_face_height, "Vertical nose span as % of face height. ~33% aligns with the middle facial third."),
)
