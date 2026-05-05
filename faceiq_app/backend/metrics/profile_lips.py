"""Metric implementations for the Lips (Profile) category."""

from __future__ import annotations

from domain.geometry import angle_at_vertex, dist, signed_dist_to_line
from domain.interfaces import LandmarkMap
from metrics.common import ComputedMetric, register_metrics


def _face_h(lm: LandmarkMap) -> float:
    return dist(lm.get("nasion"), lm.get("pogonion"))


def _upper_lip_eline_position(lm: LandmarkMap):
    face_h = _face_h(lm)
    if lm.get("pronasale") and lm.get("pogonion") and lm.get("ls") and lm.get("li") and face_h > 0:
        return signed_dist_to_line(lm.get("ls"), lm.get("pronasale"), lm.get("pogonion")) / face_h * 100
    return None


def _lower_lip_eline_position(lm: LandmarkMap):
    face_h = _face_h(lm)
    if lm.get("pronasale") and lm.get("pogonion") and lm.get("ls") and lm.get("li") and face_h > 0:
        return signed_dist_to_line(lm.get("li"), lm.get("pronasale"), lm.get("pogonion")) / face_h * 100
    return None


def _upper_lip_sline_position(lm: LandmarkMap):
    face_h = _face_h(lm)
    if lm.get("subnasale") and lm.get("pogonion") and lm.get("ls") and lm.get("li") and face_h > 0:
        return signed_dist_to_line(lm.get("ls"), lm.get("subnasale"), lm.get("pogonion")) / face_h * 100
    return None


def _lower_lip_sline_position(lm: LandmarkMap):
    face_h = _face_h(lm)
    if lm.get("subnasale") and lm.get("pogonion") and lm.get("ls") and lm.get("li") and face_h > 0:
        return signed_dist_to_line(lm.get("li"), lm.get("subnasale"), lm.get("pogonion")) / face_h * 100
    return None


def _upper_lip_burstone_position(lm: LandmarkMap):
    face_h = _face_h(lm)
    if lm.get("subnasale") and lm.get("pogonion") and lm.get("ls") and lm.get("li") and face_h > 0:
        return signed_dist_to_line(lm.get("ls"), lm.get("subnasale"), lm.get("pogonion")) / face_h * 100
    return None


def _lower_lip_burstone_position(lm: LandmarkMap):
    face_h = _face_h(lm)
    if lm.get("subnasale") and lm.get("pogonion") and lm.get("ls") and lm.get("li") and face_h > 0:
        return signed_dist_to_line(lm.get("li"), lm.get("subnasale"), lm.get("pogonion")) / face_h * 100
    return None


def _holdaway_h_line_position(lm: LandmarkMap):
    face_h = _face_h(lm)
    if lm.get("ls") and lm.get("pogonion") and lm.get("subnasale") and face_h > 0:
        h_dist = signed_dist_to_line(lm.get("subnasale"), lm.get("ls"), lm.get("pogonion"))
        return h_dist / face_h * 100
    return None


def _mentolabial_angle(lm: LandmarkMap):
    if lm.get("ls") and lm.get("li") and lm.get("pogonion"):
        return angle_at_vertex(lm.get("ls"), lm.get("li"), lm.get("pogonion"))
    return None


def _upper_lip_projection(lm: LandmarkMap):
    face_h = _face_h(lm)
    if lm.get("ls") and lm.get("subnasale") and lm.get("nasion"):
        u_proj = signed_dist_to_line(lm.get("ls"), lm.get("nasion"), lm.get("pogonion")) if lm.get("pogonion") else 0
        if face_h > 0:
            return u_proj / face_h * 100
    return None


register_metrics(
    ComputedMetric("Upper Lip E-Line Position", "Lips (Profile)", -3, 3, "%", _upper_lip_eline_position, "Upper lip position relative to E-line. Negative = behind (retruded); positive = in front."),
    ComputedMetric("Lower Lip E-Line Position", "Lips (Profile)", -5, 2, "%", _lower_lip_eline_position, "Lower lip position relative to E-line. Negative = behind; positive = protrusive."),
    ComputedMetric("Upper Lip S-Line Position", "Lips (Profile)", -3, 3, "%", _upper_lip_sline_position, "Upper lip relative to Steiner's S-line. Negative = retruded."),
    ComputedMetric("Lower Lip S-Line Position", "Lips (Profile)", -3, 3, "%", _lower_lip_sline_position, "Lower lip relative to Steiner's S-line."),
    ComputedMetric("Upper Lip Burstone Position", "Lips (Profile)", -4, 0, "%", _upper_lip_burstone_position, "Upper lip to Burstone line. Negative = retruded; ideal is slightly behind the line."),
    ComputedMetric("Lower Lip Burstone Position", "Lips (Profile)", -4, 0, "%", _lower_lip_burstone_position, "Lower lip to Burstone line. Both lips should be at or slightly behind."),
    ComputedMetric("Holdaway H-Line Position", "Lips (Profile)", -1, 1, "%", _holdaway_h_line_position, "Upper lip prominence relative to H-line (Holdaway). Near 0 = ideal lip-chin balance."),
    ComputedMetric("Mentolabial Angle", "Lips (Profile)", 120, 150, "Â°", _mentolabial_angle, "Chin-lip sulcus angle. ~134Â° ideal. Lower = deep sulcus; higher = flat (weak chin)."),
    ComputedMetric("Upper Lip Projection", "Lips (Profile)", -2, 4, "%", _upper_lip_projection, "Upper lip forward projection relative to face plane. Positive = protrusive."),
)
