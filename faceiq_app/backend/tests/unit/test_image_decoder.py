import io
import sys
import unittest
from pathlib import Path
from unittest.mock import patch

import numpy as np
from PIL import Image


BACKEND_DIR = Path(__file__).resolve().parents[2]
if str(BACKEND_DIR) not in sys.path:
    sys.path.insert(0, str(BACKEND_DIR))


from face_analyzer import analyze_image
from infrastructure import image_decoder
from infrastructure.image_decoder import (
    ImageDecodeError,
    ImageTooLargeError,
    ImageTooSmallError,
    decode_image,
)


def make_jpeg_bytes(width: int = 200, height: int = 200) -> bytes:
    image = Image.new("RGB", (width, height), color=(200, 180, 160))
    buffer = io.BytesIO()
    image.save(buffer, format="JPEG")
    return buffer.getvalue()


class ImageDecoderTests(unittest.TestCase):
    def test_decode_image_returns_numpy_array_for_valid_image(self) -> None:
        decoded = decode_image(make_jpeg_bytes())

        self.assertIsInstance(decoded, np.ndarray)
        self.assertEqual(decoded.shape[:2], (200, 200))

    def test_decode_image_rejects_invalid_bytes(self) -> None:
        with self.assertRaisesRegex(
            ImageDecodeError,
            "Could not decode image. Ensure it is a valid JPEG or PNG.",
        ):
            decode_image(b"not an image")

    def test_decode_image_rejects_small_images(self) -> None:
        with self.assertRaisesRegex(
            ImageTooSmallError,
            "Image must be at least 100px in each dimension.",
        ):
            decode_image(make_jpeg_bytes(width=50, height=50))

    def test_decode_image_rejects_large_payloads(self) -> None:
        with patch.object(image_decoder, "MAX_FILE_SIZE", 1024 * 1024):
            with self.assertRaisesRegex(ImageTooLargeError, "Image exceeds 1 MB limit."):
                decode_image(b"0" * (image_decoder.MAX_FILE_SIZE + 1))

    def test_decode_image_rejects_large_dimensions(self) -> None:
        with patch.object(image_decoder, "MAX_DIMENSION", 150):
            with self.assertRaisesRegex(
                ImageTooLargeError,
                "Image must be at most 150px in each dimension.",
            ):
                decode_image(make_jpeg_bytes(width=200, height=200))


class AnalyzeImageDecoderIntegrationTests(unittest.TestCase):
    def test_analyze_image_surfaces_decoder_validation_errors(self) -> None:
        output = analyze_image(make_jpeg_bytes(width=50, height=50), "frontal")

        self.assertFalse(output.success)
        self.assertEqual(output.image_type, "frontal")
        self.assertEqual(output.error, "Image must be at least 100px in each dimension.")


if __name__ == "__main__":
    unittest.main()
