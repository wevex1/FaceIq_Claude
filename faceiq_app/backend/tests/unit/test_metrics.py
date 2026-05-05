import sys
import unittest
from pathlib import Path


BACKEND_DIR = Path(__file__).resolve().parents[2]
if str(BACKEND_DIR) not in sys.path:
    sys.path.insert(0, str(BACKEND_DIR))


from domain.metric_registry import get_by_category
from face_analyzer import compute_frontal_ratios, compute_profile_ratios
from metrics.facial_thirds import LowerThird, MiddleThird, UpperThird


SYMMETRIC_THIRDS = {
    "glabella": (100.0, 40.0),
    "nasion": (100.0, 130.0),
    "subnasale": (100.0, 220.0),
    "pogonion": (100.0, 310.0),
}

COMPREHENSIVE_LANDMARKS = {
    "glabella": (100.0, 80.0),
    "trichion": (100.0, 50.0),
    "nasion": (100.0, 120.0),
    "pronasale": (100.0, 180.0),
    "subnasale": (100.0, 220.0),
    "pogonion": (100.0, 340.0),
    "zy_L": (30.0, 180.0),
    "zy_R": (170.0, 180.0),
    "temp_L": (40.0, 130.0),
    "temp_R": (160.0, 130.0),
    "go_L": (45.0, 300.0),
    "go_R": (155.0, 302.0),
    "neck_L": (55.0, 360.0),
    "neck_R": (145.0, 360.0),
    "en_L": (75.0, 140.0),
    "en_R": (125.0, 140.0),
    "ex_L": (55.0, 138.0),
    "ex_R": (145.0, 142.0),
    "eye_top_L": (75.0, 136.0),
    "eye_bot_L": (75.0, 144.0),
    "eye_top_R": (125.0, 138.0),
    "eye_bot_R": (125.0, 146.0),
    "pupil_L": (78.0, 140.0),
    "pupil_R": (122.0, 140.0),
    "brow_out_L": (50.0, 120.0),
    "brow_in_L": (85.0, 118.0),
    "brow_apex_L": (68.0, 112.0),
    "brow_out_R": (150.0, 120.0),
    "brow_in_R": (115.0, 118.0),
    "brow_apex_R": (132.0, 112.0),
    "al_L": (85.0, 195.0),
    "al_R": (115.0, 195.0),
    "ls": (100.0, 250.0),
    "li": (100.0, 270.0),
    "ch_L": (70.0, 260.0),
    "ch_R": (130.0, 258.0),
    "upper_lip_top": (100.0, 245.0),
    "lower_lip_bot": (100.0, 280.0),
    "philtrum_top": (100.0, 235.0),
}


class FacialThirdMetricTests(unittest.TestCase):
    def test_metric_registry_returns_migrated_facial_thirds(self) -> None:
        metrics = get_by_category("Facial Thirds")

        self.assertEqual(
            [metric.name for metric in metrics],
            [
                "Upper Third",
                "Middle Third",
                "Lower Third",
                "Upper-to-Lower Third Ratio",
                "Mid-to-Lower Third Ratio",
            ],
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

    def test_compute_frontal_ratios_emits_all_migrated_frontal_metrics(self) -> None:
        ratios = compute_frontal_ratios(COMPREHENSIVE_LANDMARKS)

        self.assertEqual(len(ratios), 46)
        self.assertEqual(ratios[0].category, "Facial Thirds")
        self.assertEqual(ratios[0].name, "Upper Third")
        self.assertEqual(ratios[-1].category, "Jaw & Chin")
        self.assertEqual(ratios[-1].name, "Gonion Position (% from nasion)")

    def test_compute_profile_ratios_emits_all_migrated_profile_metrics(self) -> None:
        ratios = compute_profile_ratios(COMPREHENSIVE_LANDMARKS)

        self.assertEqual(len(ratios), 36)
        self.assertEqual(ratios[0].category, "Upper Face (Profile)")
        self.assertEqual(ratios[0].name, "Upper Forehead Slope")
        self.assertEqual(ratios[-1].category, "Jaw & Chin (Profile)")
        self.assertEqual(ratios[-1].name, "Chin Recession vs Eye Vertical")


if __name__ == "__main__":
    unittest.main()
