"""Metric implementations for the Facial Thirds category."""

from __future__ import annotations

from typing import Optional, Tuple

from domain.geometry import dist
from domain.interfaces import LandmarkMap
from domain.metric_registry import register


def _third_segments(lm: LandmarkMap) -> Optional[Tuple[float, float, float]]:
    glabella = lm.get("glabella")
    nasion = lm.get("nasion")
    subnasale = lm.get("subnasale")
    pogonion = lm.get("pogonion")
    if not all((glabella, nasion, subnasale, pogonion)):
        return None

    gl_me = dist(glabella, pogonion)
    if gl_me <= 0:
        return None

    top = dist(glabella, nasion) / gl_me * 100
    mid = dist(nasion, subnasale) / gl_me * 100
    low = dist(subnasale, pogonion) / gl_me * 100
    return top, mid, low


class _BaseFacialThirdMetric:
    category = "Facial Thirds"
    unit = "%"


@register
class UpperThird(_BaseFacialThirdMetric):
    name = "Upper Third"
    ideal_min = 28.0
    ideal_max = 38.0

    def compute(self, lm: LandmarkMap) -> Optional[float]:
        segments = _third_segments(lm)
        return segments[0] if segments else None

    def interpret(self, value: float) -> str:
        return "Forehead height as % of total face height. ~33% is the classical ideal."


@register
class MiddleThird(_BaseFacialThirdMetric):
    name = "Middle Third"
    ideal_min = 28.0
    ideal_max = 36.0

    def compute(self, lm: LandmarkMap) -> Optional[float]:
        segments = _third_segments(lm)
        return segments[1] if segments else None

    def interpret(self, value: float) -> str:
        return "Midface height (nasion to subnasale) as % of total face. ~33% ideal."


@register
class LowerThird(_BaseFacialThirdMetric):
    name = "Lower Third"
    ideal_min = 30.0
    ideal_max = 38.0

    def compute(self, lm: LandmarkMap) -> Optional[float]:
        segments = _third_segments(lm)
        return segments[2] if segments else None

    def interpret(self, value: float) -> str:
        return "Lower face height (subnasale to chin) as % of total. ~33% ideal."


@register
class UpperToLowerThirdRatio:
    name = "Upper-to-Lower Third Ratio"
    category = "Facial Thirds"
    ideal_min = 0.85
    ideal_max = 1.15
    unit = "Ã—"

    def compute(self, lm: LandmarkMap) -> Optional[float]:
        segments = _third_segments(lm)
        if not segments or segments[2] <= 0:
            return None
        return segments[0] / segments[2]

    def interpret(self, value: float) -> str:
        return "Balance between forehead and lower face. 1.0 = perfect symmetry."


@register
class MidToLowerThirdRatio:
    name = "Mid-to-Lower Third Ratio"
    category = "Facial Thirds"
    ideal_min = 0.80
    ideal_max = 1.10
    unit = "Ã—"

    def compute(self, lm: LandmarkMap) -> Optional[float]:
        segments = _third_segments(lm)
        if not segments or segments[2] <= 0:
            return None
        return segments[1] / segments[2]

    def interpret(self, value: float) -> str:
        return "Midface to lower face balance. 1.0 = harmonious proportion."
