import sys
import unittest
from pathlib import Path


BACKEND_DIR = Path(__file__).resolve().parents[2]
if str(BACKEND_DIR) not in sys.path:
    sys.path.insert(0, str(BACKEND_DIR))


from face_analyzer import score_from_range


class ScoreFromRangeTests(unittest.TestCase):
    def test_score_is_ten_at_ideal_midpoint(self) -> None:
        self.assertAlmostEqual(score_from_range(50.0, 40.0, 60.0), 10.0)

    def test_score_is_eight_at_ideal_edges(self) -> None:
        self.assertAlmostEqual(score_from_range(40.0, 40.0, 60.0), 8.0)
        self.assertAlmostEqual(score_from_range(60.0, 40.0, 60.0), 8.0)

    def test_score_decreases_linearly_inside_ideal_range(self) -> None:
        self.assertAlmostEqual(score_from_range(55.0, 40.0, 60.0), 9.0)

    def test_score_decreases_outside_ideal_range(self) -> None:
        self.assertAlmostEqual(
            score_from_range(62.0, 40.0, 60.0),
            16.0 / 3.0,
            places=6,
        )

    def test_score_bottoms_out_at_zero_when_far_outside_range(self) -> None:
        self.assertEqual(score_from_range(100.0, 40.0, 60.0), 0.0)

    def test_score_handles_collapsed_ideal_range(self) -> None:
        self.assertEqual(score_from_range(10.0, 10.0, 10.0), 10.0)
        self.assertEqual(score_from_range(12.0, 10.0, 10.0), 5.0)

    def test_score_returns_neutral_when_ideal_range_missing(self) -> None:
        self.assertEqual(score_from_range(10.0, None, 10.0), 5.0)
        self.assertEqual(score_from_range(10.0, 10.0, None), 5.0)


if __name__ == "__main__":
    unittest.main()
