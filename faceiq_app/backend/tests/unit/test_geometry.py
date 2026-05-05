import math
import sys
import unittest
from pathlib import Path


BACKEND_DIR = Path(__file__).resolve().parents[2]
if str(BACKEND_DIR) not in sys.path:
    sys.path.insert(0, str(BACKEND_DIR))


from face_analyzer import (
    angle_at_vertex,
    dist,
    line_angle_to_horizontal,
    midpoint,
    signed_dist_to_line,
)


class GeometryHelpersTests(unittest.TestCase):
    def test_dist_returns_euclidean_distance(self) -> None:
        self.assertAlmostEqual(dist((0.0, 0.0), (3.0, 4.0)), 5.0)

    def test_dist_returns_zero_when_point_missing(self) -> None:
        self.assertEqual(dist(None, (3.0, 4.0)), 0.0)
        self.assertEqual(dist((3.0, 4.0), None), 0.0)

    def test_angle_at_vertex_returns_right_angle(self) -> None:
        angle = angle_at_vertex((1.0, 0.0), (0.0, 0.0), (0.0, 1.0))
        self.assertAlmostEqual(angle, 90.0, places=6)

    def test_angle_at_vertex_returns_zero_for_missing_point(self) -> None:
        self.assertEqual(angle_at_vertex(None, (0.0, 0.0), (1.0, 0.0)), 0.0)

    def test_angle_at_vertex_returns_zero_for_degenerate_vectors(self) -> None:
        self.assertEqual(angle_at_vertex((0.0, 0.0), (0.0, 0.0), (1.0, 1.0)), 0.0)

    def test_signed_dist_to_line_keeps_current_sign_convention(self) -> None:
        self.assertAlmostEqual(
            signed_dist_to_line((1.0, 1.0), (0.0, 0.0), (2.0, 0.0)),
            -1.0,
            places=6,
        )
        self.assertAlmostEqual(
            signed_dist_to_line((1.0, -1.0), (0.0, 0.0), (2.0, 0.0)),
            1.0,
            places=6,
        )

    def test_signed_dist_to_line_returns_zero_for_degenerate_line(self) -> None:
        self.assertEqual(
            signed_dist_to_line((1.0, 1.0), (0.0, 0.0), (0.0, 0.0)),
            0.0,
        )

    def test_line_angle_to_horizontal_uses_image_coordinate_system(self) -> None:
        self.assertAlmostEqual(
            line_angle_to_horizontal((0.0, 0.0), (1.0, -1.0)),
            45.0,
            places=6,
        )
        self.assertAlmostEqual(
            line_angle_to_horizontal((0.0, 0.0), (1.0, 1.0)),
            -45.0,
            places=6,
        )

    def test_midpoint_returns_average_point(self) -> None:
        self.assertEqual(midpoint((0.0, 0.0), (2.0, 4.0)), (1.0, 2.0))

    def test_midpoint_returns_none_when_point_missing(self) -> None:
        self.assertIsNone(midpoint(None, (2.0, 4.0)))


if __name__ == "__main__":
    unittest.main()
