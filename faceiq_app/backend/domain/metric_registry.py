"""Registry for metric implementations."""

from __future__ import annotations

from typing import List, Type

from domain.interfaces import IMetric


_REGISTRY: List[IMetric] = []


def register_metric(metric: IMetric) -> IMetric:
    if not any(
        type(existing) is type(metric) and existing.name == metric.name for existing in _REGISTRY
    ):
        _REGISTRY.append(metric)
    return metric


def register(cls: Type[IMetric]) -> Type[IMetric]:
    register_metric(cls())
    return cls


def get_all() -> List[IMetric]:
    return list(_REGISTRY)


def get_by_category(category: str) -> List[IMetric]:
    return [metric for metric in _REGISTRY if metric.category == category]
