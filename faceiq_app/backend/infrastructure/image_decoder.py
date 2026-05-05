"""Image byte decoding and validation helpers."""

import cv2
import numpy as np


MAX_FILE_SIZE = 20 * 1024 * 1024  # 20 MB
MIN_DIMENSION = 100
MAX_DIMENSION = 8000


class ImageDecodeError(Exception):
    """Raised when uploaded image bytes cannot be safely decoded."""


class ImageTooLargeError(ImageDecodeError):
    """Raised when image bytes or dimensions exceed limits."""


class ImageTooSmallError(ImageDecodeError):
    """Raised when image dimensions are too small for analysis."""


def decode_image(data: bytes) -> np.ndarray:
    """Decode uploaded bytes into a BGR image after basic validation."""
    if len(data) > MAX_FILE_SIZE:
        raise ImageTooLargeError(
            f"Image exceeds {MAX_FILE_SIZE // (1024 * 1024)} MB limit."
        )

    arr = np.frombuffer(data, dtype=np.uint8)
    img = cv2.imdecode(arr, cv2.IMREAD_COLOR)
    if img is None:
        raise ImageDecodeError("Could not decode image. Ensure it is a valid JPEG or PNG.")

    h, w = img.shape[:2]
    if w < MIN_DIMENSION or h < MIN_DIMENSION:
        raise ImageTooSmallError(
            f"Image must be at least {MIN_DIMENSION}px in each dimension."
        )
    if w > MAX_DIMENSION or h > MAX_DIMENSION:
        raise ImageTooLargeError(
            f"Image must be at most {MAX_DIMENSION}px in each dimension."
        )

    return img
