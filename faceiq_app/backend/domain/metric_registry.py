"""Registry for metric implementations."""

from __future__ import annotations

from typing import List, Type

from domain.interfaces import IMetric


_REGISTRY: List[IMetric] = []


def register(cls: Type[IMetric]) -> Type[IMetric]:
    if not any(type(metric) is cls for metric in _REGISTRY):
        _REGISTRY.append(cls())
    return cls


def get_all() -> List[IMetric]:
    return list(_REGISTRY)


def get_by_category(category: str) -> List[IMetric]:
    return [metric for metric in _REGISTRY if metric.category == category]
