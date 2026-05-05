"""Metric implementations for the Mouth & Lips category."""

from __future__ import annotations

from domain.geometry import dist, line_angle_to_horizontal, midpoint
from domain.interfaces import LandmarkMap
from metrics.common import ComputedMetric, register_metrics


def _face_w(lm: LandmarkMap) -> float:
    return dist(lm.get("zy_L"), lm.get("zy_R"))


def _face_h(lm: LandmarkMap) -> float:
    return dist(lm.get("nasion"), lm.get("pogonion"))


def _lower_upper_lip_ratio(lm: LandmarkMap):
    if lm.get("subnasale") and lm.get("ls") and lm.get("li"):
        upper_h = dist(lm.get("subnasale"), lm.get("ls"))
        lower_h = dist(lm.get("ls"), lm.get("li"))
        if upper_h > 0:
            return lower_h / upper_h
    return None


def _mouth_width_ipd(lm: LandmarkMap):
    ch_l = lm.get("ch_L")
    ch_r = lm.get("ch_R")
    if ch_l and ch_r:
        mw = dist(ch_l, ch_r)
        ex_l = lm.get("ex_L")
        en_l = lm.get("en_L")
        ex_r = lm.get("ex_R")
        en_r = lm.get("en_R")
        c_l = lm.get("pupil_L") if lm.get("pupil_L") else (midpoint(ex_l, en_l) if ex_l and en_l else None)
        c_r = lm.get("pupil_R") if lm.get("pupil_R") else (midpoint(ex_r, en_r) if ex_r and en_r else None)
        if c_l and c_r:
            ipd2 = dist(c_l, c_r)
            if ipd2 > 0:
                return mw / ipd2
    return None


def _mouth_width_nose_width(lm: LandmarkMap):
    if lm.get("ch_L") and lm.get("ch_R") and lm.get("al_L") and lm.get("al_R"):
        nw = dist(lm.get("al_L"), lm.get("al_R"))
        if nw > 0:
            return dist(lm.get("ch_L"), lm.get("ch_R")) / nw
    return None


def _mouth_width_face_width(lm: LandmarkMap):
    face_w = _face_w(lm)
    if lm.get("ch_L") and lm.get("ch_R") and face_w > 0:
        return dist(lm.get("ch_L"), lm.get("ch_R")) / face_w * 100
    return None


def _chin_philtrum_ratio(lm: LandmarkMap):
    if lm.get("subnasale") and lm.get("pogonion") and lm.get("ls"):
        phil = dist(lm.get("subnasale"), lm.get("ls"))
        if phil > 0:
            return dist(lm.get("subnasale"), lm.get("pogonion")) / phil
    return None


def _philtrum_height_face_height(lm: LandmarkMap):
    face_w = _face_w(lm)
    face_h = _face_h(lm)
    if lm.get("subnasale") and lm.get("ls") and face_w > 0:
        phil_h = dist(lm.get("subnasale"), lm.get("ls"))
        return phil_h / face_h * 100 if face_h > 0 else 0
    return None


def _mouth_corner_tilt(lm: LandmarkMap):
    if lm.get("ch_L") and lm.get("ch_R"):
        return line_angle_to_horizontal(lm.get("ch_L"), lm.get("ch_R"))
    return None


def _upper_vermilion_height_face_height(lm: LandmarkMap):
    face_h = _face_h(lm)
    if lm.get("ls") and lm.get("upper_lip_top"):
        uv_h = dist(lm.get("ls"), lm.get("upper_lip_top"))
        if face_h > 0:
            return uv_h / face_h * 100
    return None


def _lower_lip_chin_height_ratio(lm: LandmarkMap):
    if lm.get("li") and lm.get("pogonion") and lm.get("ls"):
        ll_h = dist(lm.get("li"), lm.get("ls"))
        chin_h = dist(lm.get("li"), lm.get("pogonion"))
        if chin_h > 0:
            return ll_h / chin_h
    return None


register_metrics(
    ComputedMetric("Lower / Upper Lip Ratio", "Mouth & Lips", 1.0, 1.4, "Ã—", _lower_upper_lip_ratio, "Lower lip height vs upper lip height. ~1.2Ã— = fuller lower lip (classical ideal)."),
    ComputedMetric("Mouth Width / Interpupillary Distance", "Mouth & Lips", 0.75, 0.90, "Ã—", _mouth_width_ipd, "Mouth width vs eye spacing. ~0.8Ã— is the classical proportion."),
    ComputedMetric("Mouth Width / Nose Width", "Mouth & Lips", 1.3, 1.6, "Ã—", _mouth_width_nose_width, "Mouth width vs nose width. ~1.4Ã— is proportionate."),
    ComputedMetric("Mouth Width / Face Width", "Mouth & Lips", 40, 50, "%", _mouth_width_face_width, "Mouth width as % of face width. ~45% is balanced."),
    ComputedMetric("Chin / Philtrum Ratio", "Mouth & Lips", 1.7, 2.3, "Ã—", _chin_philtrum_ratio, "Subnasale-chin vs philtrum. ~2.0Ã— is harmonious lower face."),
    ComputedMetric("Philtrum Height / Face Height", "Mouth & Lips", 8, 14, "%", _philtrum_height_face_height, "Philtrum length as % of face height. Shorter = more youthful."),
    ComputedMetric("Mouth Corner Tilt", "Mouth & Lips", -3, 3, "Â°", _mouth_corner_tilt, "Horizontal alignment of mouth corners. Negative = downturned corners."),
    ComputedMetric("Upper Vermilion Height / Face Height", "Mouth & Lips", 3, 7, "%", _upper_vermilion_height_face_height, "Upper lip vermilion height as % of face. Higher = fuller upper lip."),
    ComputedMetric("Lower Lip / Chin Height Ratio", "Mouth & Lips", 0.4, 0.7, "Ã—", _lower_lip_chin_height_ratio, "Lower lip vs chin height. Higher = prominent lower lip relative to chin."),
)
