"""MediaPipe landmark detection service."""

from __future__ import annotations

from typing import Dict, Optional, Tuple

import cv2
import mediapipe as mp
import numpy as np


class MediaPipeDetector:
    """Singleton-backed MediaPipe FaceMesh detector."""

    _instances: dict[bool, "MediaPipeDetector"] = {}

    def __init__(self, refine_landmarks: bool = True):
        self.refine_landmarks = refine_landmarks
        self._face_mesh = mp.solutions.face_mesh.FaceMesh(
            static_image_mode=True,
            max_num_faces=1,
            refine_landmarks=refine_landmarks,
            min_detection_confidence=0.5,
        )

    @classmethod
    def get_instance(cls, refine_landmarks: bool = True) -> "MediaPipeDetector":
        if refine_landmarks not in cls._instances:
            cls._instances[refine_landmarks] = cls(refine_landmarks=refine_landmarks)
        return cls._instances[refine_landmarks]

    @classmethod
    def reset_instances(cls) -> None:
        for detector in cls._instances.values():
            close = getattr(detector._face_mesh, "close", None)
            if callable(close):
                close()
        cls._instances.clear()

    def detect(
        self,
        image_bgr: np.ndarray,
        landmark_indices: Dict[str, int],
    ) -> Optional[Dict[str, Tuple[float, float]]]:
        h, w = image_bgr.shape[:2]
        rgb = cv2.cvtColor(image_bgr, cv2.COLOR_BGR2RGB)
        result = self._face_mesh.process(rgb)
        if not result.multi_face_landmarks:
            return None

        raw = result.multi_face_landmarks[0].landmark
        named: Dict[str, Tuple[float, float]] = {}
        for name, idx in landmark_indices.items():
            if idx < len(raw):
                lm = raw[idx]
                named[name] = (lm.x * w, lm.y * h)

        return named
