import sys
import unittest
from pathlib import Path


BACKEND_DIR = Path(__file__).resolve().parents[2]
if str(BACKEND_DIR) not in sys.path:
    sys.path.insert(0, str(BACKEND_DIR))


from domain.metric_registry import get_by_category
from face_analyzer import compute_frontal_ratios
from metrics.facial_thirds import LowerThird, MiddleThird, UpperThird


SYMMETRIC_THIRDS = {
    "glabella": (100.0, 40.0),
    "nasion": (100.0, 130.0),
    "subnasale": (100.0, 220.0),
    "pogonion": (100.0, 310.0),
}


class FacialThirdMetricTests(unittest.TestCase):
    def test_metric_registry_returns_migrated_facial_thirds(self) -> None:
        metrics = get_by_category("Facial Thirds")

        self.assertEqual(
            [metric.name for metric in metrics],
            ["Upper Third", "Middle Third", "Lower Third"],
        )

    def test_facial_third_metrics_compute_expected_balanced_values(self) -> None:
        self.assertAlmostEqual(UpperThird().compute(SYMMETRIC_THIRDS), 100.0 / 3.0, places=6)
        self.assertAlmostEqual(MiddleThird().compute(SYMMETRIC_THIRDS), 100.0 / 3.0, places=6)
        self.assertAlmostEqual(LowerThird().compute(SYMMETRIC_THIRDS), 100.0 / 3.0, places=6)

    def test_facial_third_metrics_return_none_when_landmarks_missing(self) -> None:
        self.assertIsNone(UpperThird().compute({}))
        self.assertIsNone(MiddleThird().compute({}))
        self.assertIsNone(LowerThird().compute({}))

    def test_compute_frontal_ratios_preserves_facial_thirds_output_order(self) -> None:
        ratios = compute_frontal_ratios(SYMMETRIC_THIRDS)

        self.assertEqual(
            [ratio.name for ratio in ratios[:5]],
            [
                "Upper Third",
                "Middle Third",
                "Lower Third",
                "Upper-to-Lower Third Ratio",
                "Mid-to-Lower Third Ratio",
            ],
        )
        self.assertAlmostEqual(ratios[0].value, 33.333, places=3)
        self.assertAlmostEqual(ratios[1].value, 33.333, places=3)
        self.assertAlmostEqual(ratios[2].value, 33.333, places=3)
        self.assertAlmostEqual(ratios[3].value, 1.0, places=3)
        self.assertAlmostEqual(ratios[4].value, 1.0, places=3)


if __name__ == "__main__":
    unittest.main()
