"""Metric implementations for the Jaw & Chin (Profile) category."""

from __future__ import annotations

from domain.geometry import angle_at_vertex, dist, line_angle_to_horizontal
from domain.interfaces import LandmarkMap
from metrics.common import ComputedMetric, register_metrics


def _face_h(lm: LandmarkMap) -> float:
    return dist(lm.get("nasion"), lm.get("pogonion"))


def _mandibular_plane_angle(lm: LandmarkMap):
    if lm.get("go_L") and lm.get("pogonion"):
        return abs(line_angle_to_horizontal(lm.get("go_L"), lm.get("pogonion")))
    return None


def _gonial_angle(lm: LandmarkMap):
    if lm.get("nasion") and lm.get("go_L") and lm.get("pogonion"):
        return angle_at_vertex(lm.get("nasion"), lm.get("go_L"), lm.get("pogonion"))
    return None


def _ramus_mandible_ratio(lm: LandmarkMap):
    if lm.get("go_L") and lm.get("pogonion") and lm.get("nasion"):
        ramus = dist(lm.get("nasion"), lm.get("go_L"))
        mandible = dist(lm.get("go_L"), lm.get("pogonion"))
        if mandible > 0:
            return ramus / mandible
    return None


def _chin_projection_vs_nasion(lm: LandmarkMap):
    face_h = _face_h(lm)
    if lm.get("nasion") and lm.get("pogonion") and face_h > 0:
        return (lm.get("pogonion")[0] - lm.get("nasion")[0]) / face_h * 100
    return None


def _chin_height_lower_third_profile(lm: LandmarkMap):
    face_h = _face_h(lm)
    if lm.get("li") and lm.get("pogonion") and lm.get("subnasale") and face_h > 0:
        chin_h = dist(lm.get("li"), lm.get("pogonion"))
        lower3 = dist(lm.get("subnasale"), lm.get("pogonion"))
        if lower3 > 0:
            return chin_h / lower3 * 100
    return None


def _submental_angle(lm: LandmarkMap):
    if lm.get("subnasale") and lm.get("pogonion") and lm.get("go_L"):
        return angle_at_vertex(lm.get("subnasale"), lm.get("pogonion"), lm.get("go_L"))
    return None


def _gonion_to_mouth_distance(lm: LandmarkMap):
    face_h = _face_h(lm)
    if lm.get("go_L") and lm.get("ch_L") and face_h > 0:
        return dist(lm.get("go_L"), lm.get("ch_L")) / face_h * 100
    return None


def _chin_recession_vs_eye_vertical(lm: LandmarkMap):
    face_h = _face_h(lm)
    if lm.get("ex_L") and lm.get("pogonion") and face_h > 0:
        return (lm.get("pogonion")[0] - lm.get("ex_L")[0]) / face_h * 100
    return None


register_metrics(
    ComputedMetric("Mandibular Plane Angle", "Jaw & Chin (Profile)", 10, 25, "Â°", _mandibular_plane_angle, "Jaw floor inclination from horizontal. Lower = more horizontal jaw (often more aesthetic)."),
    ComputedMetric("Gonial Angle", "Jaw & Chin (Profile)", 100, 130, "Â°", _gonial_angle, "Jaw angle. ~115Â° is balanced. >130Â° = open bite / weak jaw profile."),
    ComputedMetric("Ramus / Mandible Ratio", "Jaw & Chin (Profile)", 0.6, 0.9, "Ã—", _ramus_mandible_ratio, "Ramus height vs mandible body. ~0.75Ã— is balanced jaw structure."),
    ComputedMetric("Chin Projection vs Nasion", "Jaw & Chin (Profile)", -5, 5, "%", _chin_projection_vs_nasion, "Horizontal chin offset from nasion vertical. Negative = recessed chin."),
    ComputedMetric("Chin Height / Lower Third (Profile)", "Jaw & Chin (Profile)", 40, 55, "%", _chin_height_lower_third_profile, "Chin height (below lower lip) as % of lower face. ~50% = balanced chin."),
    ComputedMetric("Submental Angle", "Jaw & Chin (Profile)", 100, 140, "Â°", _submental_angle, "Chin-neck angle. ~120Â° ideal. Lower (<90Â°) = recessed chin; higher = double chin."),
    ComputedMetric("Gonion-to-Mouth Distance", "Jaw & Chin (Profile)", 15, 30, "%", _gonion_to_mouth_distance, "Distance from jaw angle to mouth corner, normalised by face height."),
    ComputedMetric("Chin Recession vs Eye Vertical", "Jaw & Chin (Profile)", -8, 2, "%", _chin_recession_vs_eye_vertical, "Chin position relative to vertical dropped from outer eye. Negative = behind (recessed)."),
)
