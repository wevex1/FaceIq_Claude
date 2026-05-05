"""Metric implementations for the Eyes & Brows category."""

from __future__ import annotations

from domain.geometry import dist, line_angle_to_horizontal, midpoint
from domain.interfaces import LandmarkMap
from metrics.common import ComputedMetric, register_metrics


def _face_w(lm: LandmarkMap) -> float:
    return dist(lm.get("zy_L"), lm.get("zy_R"))


def _eye_aspect_ratio(lm: LandmarkMap):
    ex_l = lm.get("ex_L")
    en_l = lm.get("en_L")
    eye_top_l = lm.get("eye_top_L")
    eye_bot_l = lm.get("eye_bot_L")
    ex_r = lm.get("ex_R")
    en_r = lm.get("en_R")
    eye_top_r = lm.get("eye_top_R")
    eye_bot_r = lm.get("eye_bot_R")
    if ex_l and en_l and eye_top_l and eye_bot_l and ex_r and en_r and eye_top_r and eye_bot_r:
        w_l = dist(ex_l, en_l)
        h_l = dist(eye_top_l, eye_bot_l)
        w_r = dist(ex_r, en_r)
        h_r = dist(eye_top_r, eye_bot_r)
        if h_l > 0 and h_r > 0:
            return (w_l / h_l + w_r / h_r) / 2
    return None


def _eye_symmetry(lm: LandmarkMap):
    ex_l = lm.get("ex_L")
    en_l = lm.get("en_L")
    eye_top_l = lm.get("eye_top_L")
    eye_bot_l = lm.get("eye_bot_L")
    ex_r = lm.get("ex_R")
    en_r = lm.get("en_R")
    eye_top_r = lm.get("eye_top_R")
    eye_bot_r = lm.get("eye_bot_R")
    if ex_l and en_l and eye_top_l and eye_bot_l and ex_r and en_r and eye_top_r and eye_bot_r:
        w_l = dist(ex_l, en_l)
        h_l = dist(eye_top_l, eye_bot_l)
        w_r = dist(ex_r, en_r)
        h_r = dist(eye_top_r, eye_bot_r)
        if h_l > 0 and h_r > 0:
            return min(w_l / h_l, w_r / h_r) / max(w_l / h_l, w_r / h_r) * 100
    return None


def _eye_separation_ratio(lm: LandmarkMap):
    face_w = _face_w(lm)
    if lm.get("en_L") and lm.get("en_R") and face_w > 0:
        return dist(lm.get("en_L"), lm.get("en_R")) / face_w * 100
    return None


def _one_eye_apart_test(lm: LandmarkMap):
    ex_l = lm.get("ex_L")
    en_l = lm.get("en_L")
    ex_r = lm.get("ex_R")
    en_r = lm.get("en_R")
    if ex_l and en_l and ex_r and en_r:
        c_l = lm.get("pupil_L") if lm.get("pupil_L") else midpoint(ex_l, en_l)
        c_r = lm.get("pupil_R") if lm.get("pupil_R") else midpoint(ex_r, en_r)
        ipd = dist(c_l, c_r)
        eye_w_l = dist(ex_l, en_l)
        if eye_w_l > 0:
            return ipd / eye_w_l
    return None


def _lateral_canthal_tilt(lm: LandmarkMap):
    if lm.get("ex_L") and lm.get("ex_R"):
        return line_angle_to_horizontal(lm.get("ex_L"), lm.get("ex_R"))
    return None


def _eyebrow_tilt(lm: LandmarkMap):
    if lm.get("brow_out_L") and lm.get("brow_out_R"):
        return abs(line_angle_to_horizontal(lm.get("brow_out_L"), lm.get("brow_out_R")))
    return None


def _brow_length_face_width(lm: LandmarkMap):
    face_w = _face_w(lm)
    brow_ol = lm.get("brow_out_L")
    brow_il = lm.get("brow_in_L")
    brow_or = lm.get("brow_out_R")
    brow_ir = lm.get("brow_in_R")
    if brow_ol and brow_il and face_w > 0:
        blen = (dist(brow_ol, brow_il) + (dist(brow_or, brow_ir) if brow_or and brow_ir else dist(brow_ol, brow_il))) / 2
        return blen / face_w
    return None


def _eyebrow_height_left(lm: LandmarkMap):
    brow_al = lm.get("brow_apex_L")
    ex_l = lm.get("ex_L")
    en_l = lm.get("en_L")
    eye_top_l = lm.get("eye_top_L")
    eye_bot_l = lm.get("eye_bot_L")
    if brow_al and ex_l and en_l and eye_top_l:
        brow_eye_dist = dist(brow_al, eye_top_l)
        eye_h = dist(eye_top_l, eye_bot_l) if eye_bot_l else 1
        if eye_h > 0:
            return brow_eye_dist / eye_h
    return None


def _brow_arch_height_ratio(lm: LandmarkMap):
    brow_il = lm.get("brow_in_L")
    brow_al = lm.get("brow_apex_L")
    brow_ol = lm.get("brow_out_L")
    if brow_il and brow_al:
        arch = abs(brow_il[1] - brow_al[1])
        brow_len_l = dist(brow_il, brow_ol) if brow_ol else dist(brow_il, brow_al) * 2
        if brow_len_l > 0:
            return arch / brow_len_l
    return None


def _intercanthal_eye_width(lm: LandmarkMap):
    en_l = lm.get("en_L")
    en_r = lm.get("en_R")
    ex_l = lm.get("ex_L")
    if en_l and en_r and ex_l and en_l:
        ic = dist(en_l, en_r)
        ew = dist(ex_l, en_l)
        if ew > 0:
            return ic / ew
    return None


register_metrics(
    ComputedMetric("Eye Aspect Ratio", "Eyes & Brows", 2.8, 3.5, "Ã—", _eye_aspect_ratio, "Eye width / height. 2.8â€“3.5 = almond-shaped. Lower = rounder eyes."),
    ComputedMetric("Eye Symmetry", "Eyes & Brows", 90, 100, "%", _eye_symmetry, "Left vs right eye aspect ratio similarity. 100% = perfectly symmetric eyes."),
    ComputedMetric("Eye Separation Ratio", "Eyes & Brows", 38, 50, "%", _eye_separation_ratio, "Inner eye span as % of face width. ~44% is the classical ideal."),
    ComputedMetric("One-Eye-Apart Test", "Eyes & Brows", 0.9, 1.2, "Ã—", _one_eye_apart_test, "Interpupillary distance / one eye width. ~1.0 = classical 'one eye apart' rule."),
    ComputedMetric("Lateral Canthal Tilt", "Eyes & Brows", -5, 5, "Â°", _lateral_canthal_tilt, "Eye axis angle. Positive = upward cant (hunter eyes). Ideal near 0Â°."),
    ComputedMetric("Eyebrow Tilt", "Eyes & Brows", 5, 20, "Â°", _eyebrow_tilt, "Eyebrow inclination. Mild upward arch (5â€“20Â°) is considered attractive."),
    ComputedMetric("Brow Length / Face Width", "Eyes & Brows", 0.65, 0.80, "Ã—", _brow_length_face_width, "Eyebrow length as ratio of face width. 0.70â€“0.80 is ideal; lower = short brows."),
    ComputedMetric("Eyebrow Height (L)", "Eyes & Brows", 0.5, 1.5, "Ã—", _eyebrow_height_left, "Distance from brow apex to upper eyelid, normalised by eye height. Lower = closer brows."),
    ComputedMetric("Brow Arch Height Ratio", "Eyes & Brows", 0.1, 0.3, "Ã—", _brow_arch_height_ratio, "Vertical rise of brow arch / brow length. Higher = more peaked, dramatic arch."),
    ComputedMetric("Intercanthal / Eye Width", "Eyes & Brows", 0.9, 1.1, "Ã—", _intercanthal_eye_width, "Inner eye span vs one eye width. ~1.0 aligns with the 'one eye apart' golden rule."),
)
