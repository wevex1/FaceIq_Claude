"""Domain interfaces for metric-based analysis."""

from __future__ import annotations

from typing import Dict, Optional, Protocol, Tuple


LandmarkPoint = Tuple[float, float]
LandmarkMap = Dict[str, LandmarkPoint]


class IMetric(Protocol):
    name: str
    category: str
    ideal_min: float
    ideal_max: float
    unit: str

    def compute(self, lm: LandmarkMap) -> Optional[float]:
        ...

    def interpret(self, value: float) -> str:
        ...
