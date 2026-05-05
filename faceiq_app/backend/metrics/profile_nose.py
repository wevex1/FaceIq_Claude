"""Metric implementations for the Nose (Profile) category."""

from __future__ import annotations

import math

from domain.geometry import angle_at_vertex, dist, line_angle_to_horizontal
from domain.interfaces import LandmarkMap
from metrics.common import ComputedMetric, register_metrics


def _face_h(lm: LandmarkMap) -> float:
    return dist(lm.get("nasion"), lm.get("pogonion"))


def _nasolabial_angle(lm: LandmarkMap):
    if lm.get("pronasale") and lm.get("subnasale") and lm.get("ls"):
        return angle_at_vertex(lm.get("pronasale"), lm.get("subnasale"), lm.get("ls"))
    return None


def _nasomental_angle(lm: LandmarkMap):
    if lm.get("nasion") and lm.get("pronasale") and lm.get("pogonion"):
        return angle_at_vertex(lm.get("nasion"), lm.get("pronasale"), lm.get("pogonion"))
    return None


def _nasofacial_angle(lm: LandmarkMap):
    if lm.get("glabella") and lm.get("nasion") and lm.get("pronasale"):
        nfa = angle_at_vertex(lm.get("glabella"), lm.get("nasion"), lm.get("pronasale"))
        return 180 - nfa
    return None


def _nasal_projection_ratio(lm: LandmarkMap):
    face_h = _face_h(lm)
    if lm.get("nasion") and lm.get("pronasale") and face_h > 0:
        return dist(lm.get("nasion"), lm.get("pronasale")) / face_h
    return None


def _nose_tip_rotation_angle(lm: LandmarkMap):
    if lm.get("subnasale") and lm.get("pronasale"):
        return line_angle_to_horizontal(lm.get("subnasale"), lm.get("pronasale"))
    return None


def _nasal_tip_angle(lm: LandmarkMap):
    if lm.get("nasion") and lm.get("pronasale") and lm.get("subnasale"):
        return angle_at_vertex(lm.get("nasion"), lm.get("pronasale"), lm.get("subnasale"))
    return None


def _frankfort_tip_angle(lm: LandmarkMap):
    if lm.get("ex_L") and lm.get("nasion") and lm.get("pronasale"):
        return angle_at_vertex(lm.get("ex_L"), lm.get("nasion"), lm.get("pronasale"))
    return None


def _nasal_bridge_inclination(lm: LandmarkMap):
    nasion = lm.get("nasion")
    pronasale = lm.get("pronasale")
    if nasion and pronasale:
        dx = abs(pronasale[0] - nasion[0])
        dy = abs(pronasale[1] - nasion[1])
        if dy > 0:
            return math.degrees(math.atan2(dx, dy))
    return None


register_metrics(
    ComputedMetric("Nasolabial Angle", "Nose (Profile)", 95, 115, "Â°", _nasolabial_angle, "Columella-lip angle. ~105Â° feminine ideal; ~95Â° masculine ideal."),
    ComputedMetric("Nasomental Angle", "Nose (Profile)", 120, 132, "Â°", _nasomental_angle, "Nose-to-chin angle. ~128Â° is the classic aesthetic ideal."),
    ComputedMetric("Nasofacial Angle", "Nose (Profile)", 28, 42, "Â°", _nasofacial_angle, "Nose projection from facial plane. 30â€“40Â° is classical rhinoplasty ideal."),
    ComputedMetric("Nasal Projection Ratio", "Nose (Profile)", 0.55, 0.75, "Ã—", _nasal_projection_ratio, "Nose length (bridge to tip) as fraction of face height. ~0.65Ã— is proportionate."),
    ComputedMetric("Nose Tip Rotation Angle", "Nose (Profile)", 15, 30, "Â°", _nose_tip_rotation_angle, "Upward rotation of nose tip. 15â€“30Â° is ideal. <15Â° = drooping; >30Â° = overly upturned."),
    ComputedMetric("Nasal Tip Angle", "Nose (Profile)", 70, 100, "Â°", _nasal_tip_angle, "Sharpness of nasal tip. Higher = more obtuse (bulbous) tip; lower = more refined tip."),
    ComputedMetric("Frankfort-Tip Angle", "Nose (Profile)", 30, 45, "Â°", _frankfort_tip_angle, "Angle between eye level and nose bridge-to-tip line. ~35â€“40Â° is balanced."),
    ComputedMetric("Nasal Bridge Inclination", "Nose (Profile)", 20, 40, "Â°", _nasal_bridge_inclination, "Angle of nose bridge from vertical. Higher = more curved/projected bridge."),
)
