"""Shared helpers for registry-backed metric modules."""

from __future__ import annotations

from dataclasses import dataclass
from typing import Callable, Optional

from domain.interfaces import LandmarkMap
from domain.metric_registry import register_metric


@dataclass(frozen=True)
class ComputedMetric:
    name: str
    category: str
    ideal_min: float
    ideal_max: float
    unit: str
    compute_fn: Callable[[LandmarkMap], Optional[float]]
    interpretation: str | Callable[[float], str]

    def compute(self, lm: LandmarkMap) -> Optional[float]:
        return self.compute_fn(lm)

    def interpret(self, value: float) -> str:
        if callable(self.interpretation):
            return self.interpretation(value)
        return self.interpretation


def register_metrics(*metrics: ComputedMetric) -> tuple[ComputedMetric, ...]:
    for metric in metrics:
        register_metric(metric)
    return metrics
