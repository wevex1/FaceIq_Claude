import sys
import unittest
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import patch

import numpy as np


BACKEND_DIR = Path(__file__).resolve().parents[2]
if str(BACKEND_DIR) not in sys.path:
    sys.path.insert(0, str(BACKEND_DIR))


from face_analyzer import MP_INDICES, extract_landmarks
from infrastructure.landmark_detector import MediaPipeDetector


class FakeFaceMesh:
    def __init__(self, result):
        self._result = result
        self.process_calls = []
        self.closed = False

    def process(self, image):
        self.process_calls.append(image)
        return self._result

    def close(self):
        self.closed = True


class MediaPipeDetectorTests(unittest.TestCase):
    def tearDown(self) -> None:
        MediaPipeDetector.reset_instances()

    def test_get_instance_reuses_detector_for_same_refine_mode(self) -> None:
        fake_mesh = FakeFaceMesh(SimpleNamespace(multi_face_landmarks=None))

        with patch(
            "infrastructure.landmark_detector.mp.solutions.face_mesh.FaceMesh",
            return_value=fake_mesh,
        ) as face_mesh_cls:
            first = MediaPipeDetector.get_instance(refine_landmarks=True)
            second = MediaPipeDetector.get_instance(refine_landmarks=True)

        self.assertIs(first, second)
        self.assertEqual(face_mesh_cls.call_count, 1)

    def test_get_instance_keeps_separate_cache_per_refine_mode(self) -> None:
        fake_mesh_true = FakeFaceMesh(SimpleNamespace(multi_face_landmarks=None))
        fake_mesh_false = FakeFaceMesh(SimpleNamespace(multi_face_landmarks=None))

        with patch(
            "infrastructure.landmark_detector.mp.solutions.face_mesh.FaceMesh",
            side_effect=[fake_mesh_true, fake_mesh_false],
        ) as face_mesh_cls:
            refined = MediaPipeDetector.get_instance(refine_landmarks=True)
            unrefined = MediaPipeDetector.get_instance(refine_landmarks=False)

        self.assertIsNot(refined, unrefined)
        self.assertEqual(face_mesh_cls.call_count, 2)

    def test_detect_maps_named_landmarks_and_skips_out_of_range_indices(self) -> None:
        fake_landmarks = [
            SimpleNamespace(x=0.1, y=0.2),
            SimpleNamespace(x=0.3, y=0.4),
        ]
        fake_result = SimpleNamespace(
            multi_face_landmarks=[SimpleNamespace(landmark=fake_landmarks)]
        )
        fake_mesh = FakeFaceMesh(fake_result)

        with patch(
            "infrastructure.landmark_detector.mp.solutions.face_mesh.FaceMesh",
            return_value=fake_mesh,
        ):
            detector = MediaPipeDetector.get_instance(refine_landmarks=True)

        image = np.zeros((100, 200, 3), dtype=np.uint8)
        detected = detector.detect(image, {"a": 0, "b": 1, "missing": 4})

        self.assertEqual(detected, {"a": (20.0, 20.0), "b": (60.0, 40.0)})
        self.assertEqual(len(fake_mesh.process_calls), 1)

    def test_detect_returns_none_when_no_face_found(self) -> None:
        fake_mesh = FakeFaceMesh(SimpleNamespace(multi_face_landmarks=None))

        with patch(
            "infrastructure.landmark_detector.mp.solutions.face_mesh.FaceMesh",
            return_value=fake_mesh,
        ):
            detector = MediaPipeDetector.get_instance(refine_landmarks=True)

        image = np.zeros((100, 200, 3), dtype=np.uint8)
        self.assertIsNone(detector.detect(image, {"a": 0}))

    def test_extract_landmarks_delegates_to_detector_instance(self) -> None:
        image = np.zeros((100, 200, 3), dtype=np.uint8)
        expected = {"nasion": (10.0, 15.0)}

        with patch(
            "face_analyzer.MediaPipeDetector.get_instance",
            return_value=SimpleNamespace(detect=lambda img, indices: expected),
        ) as get_instance:
            actual = extract_landmarks(image, refine=False)

        self.assertEqual(actual, expected)
        get_instance.assert_called_once_with(refine_landmarks=False)
        self.assertIn("nasion", MP_INDICES)


if __name__ == "__main__":
    unittest.main()
