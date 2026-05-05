"""Metric implementations for the Face Shape category."""

from __future__ import annotations

from domain.geometry import dist
from domain.interfaces import LandmarkMap
from metrics.common import ComputedMetric, register_metrics


def _face_w(lm: LandmarkMap) -> float:
    return dist(lm.get("zy_L"), lm.get("zy_R"))


def _face_h(lm: LandmarkMap) -> float:
    return dist(lm.get("nasion"), lm.get("pogonion"))


def _fwhr(lm: LandmarkMap):
    face_w = _face_w(lm)
    upper_h = dist(lm.get("nasion"), lm.get("ls"))
    if face_w > 0 and upper_h > 0:
        return face_w / upper_h
    return None


def _total_width_height_ratio(lm: LandmarkMap):
    face_w = _face_w(lm)
    face_h = _face_h(lm)
    if face_w > 0 and face_h > 0:
        return face_w / face_h
    return None


def _midface_ratio(lm: LandmarkMap):
    nasion = lm.get("nasion")
    subnasale = lm.get("subnasale")
    pogonion = lm.get("pogonion")
    if nasion and subnasale and pogonion:
        upper_m = dist(nasion, subnasale)
        lower_m = dist(subnasale, pogonion)
        if lower_m > 0:
            return upper_m / lower_m
    return None


def _bitemporal_width(lm: LandmarkMap):
    face_w = _face_w(lm)
    if lm.get("temp_L") and lm.get("temp_R") and face_w > 0:
        return dist(lm.get("temp_L"), lm.get("temp_R")) / face_w * 100
    return None


def _bigonial_width(lm: LandmarkMap):
    face_w = _face_w(lm)
    if lm.get("go_L") and lm.get("go_R") and face_w > 0:
        return dist(lm.get("go_L"), lm.get("go_R")) / face_w * 100
    return None


def _facial_index(lm: LandmarkMap):
    face_w = _face_w(lm)
    face_h = _face_h(lm)
    if face_w > 0 and face_h > 0:
        return face_h / face_w * 100
    return None


register_metrics(
    ComputedMetric(
        name="Face Width-to-Height Ratio (FWHR)",
        category="Face Shape",
        ideal_min=1.6,
        ideal_max=2.0,
        unit="Ã—",
        compute_fn=_fwhr,
        interpretation="Bizygomatic width / nasion-to-upper-lip. Higher = broader face.",
    ),
    ComputedMetric(
        name="Total Facial Width/Height Ratio",
        category="Face Shape",
        ideal_min=1.2,
        ideal_max=1.5,
        unit="Ã—",
        compute_fn=_total_width_height_ratio,
        interpretation="Overall face width vs nasion-to-chin height. ~1.3Ã— is balanced.",
    ),
    ComputedMetric(
        name="Midface Ratio",
        category="Face Shape",
        ideal_min=0.85,
        ideal_max=1.15,
        unit="Ã—",
        compute_fn=_midface_ratio,
        interpretation="Nasion-subnasale vs subnasale-chin. 1.0 = balanced mid and lower face.",
    ),
    ComputedMetric(
        name="Bitemporal Width",
        category="Face Shape",
        ideal_min=78,
        ideal_max=92,
        unit="%",
        compute_fn=_bitemporal_width,
        interpretation="Temple width as % of bizygomatic width.",
    ),
    ComputedMetric(
        name="Bigonial Width",
        category="Face Shape",
        ideal_min=75,
        ideal_max=90,
        unit="%",
        compute_fn=_bigonial_width,
        interpretation="Jaw angle width as % of cheekbone width. Lower = more tapered jaw.",
    ),
    ComputedMetric(
        name="Facial Index",
        category="Face Shape",
        ideal_min=75,
        ideal_max=90,
        unit="%",
        compute_fn=_facial_index,
        interpretation="Face height / width Ã— 100. 75â€“85 = mesoprosopic (average); >90 = leptoprosopic (narrow).",
    ),
)
