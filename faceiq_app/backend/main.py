"""
FaceIQ Labs API Server
Run with: uvicorn main:app --host 0.0.0.0 --port 8000 --reload
"""

import io
import base64
import logging
import json
from typing import Optional, List, Dict, Any
from fastapi import FastAPI, File, UploadFile, HTTPException, Form
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

from face_analyzer import analyze_image, RatioResult, AnalysisOutput, detect_landmarks_only, analyze_with_custom_landmarks
from infrastructure.landmark_detector import MediaPipeDetector

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(
    title="FaceIQ Labs API",
    description="Facial Ratio Analysis — 40+ metrics for frontal and profile views",
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["GET", "POST", "OPTIONS"],
    allow_headers=["*"],
    expose_headers=["*"],
)


# ─── Pydantic models ──────────────────────────────────────────────────────────

class RatioResultOut(BaseModel):
    name: str
    value: float
    ideal_min: Optional[float]
    ideal_max: Optional[float]
    unit: str
    score: float
    interpretation: str
    category: str


class CategoryResult(BaseModel):
    category: str
    average_score: float
    metrics: List[RatioResultOut]


class AnalysisResponse(BaseModel):
    success: bool
    error: Optional[str] = None
    image_type: str
    overall_score: float
    landmark_count: int
    categories: List[CategoryResult]
    total_metrics: int
    landmarks: Dict[str, List[float]] = {}


class CombinedAnalysisResponse(BaseModel):
    frontal: Optional[AnalysisResponse] = None
    profile: Optional[AnalysisResponse] = None
    combined_score: float = 0.0



class DetectResponse(BaseModel):
    success: bool
    error: Optional[str] = None
    landmarks: Dict[str, List[float]] = {}


# ─── Helpers ──────────────────────────────────────────────────────────────────

def build_response(output: AnalysisOutput) -> AnalysisResponse:
    if not output.success:
        return AnalysisResponse(
            success=False,
            error=output.error,
            image_type=output.image_type,
            overall_score=0,
            landmark_count=0,
            categories=[],
            total_metrics=0,
        )

    # Group by category
    cat_map: dict[str, List[RatioResult]] = {}
    for r in output.ratios:
        cat_map.setdefault(r.category, []).append(r)

    categories = []
    all_scores = []
    for cat_name, metrics in cat_map.items():
        scores = [m.score for m in metrics]
        avg = sum(scores) / len(scores) if scores else 0.0
        all_scores.extend(scores)
        categories.append(CategoryResult(
            category=cat_name,
            average_score=round(avg, 1),
            metrics=[RatioResultOut(**vars(m)) for m in metrics],
        ))

    overall = round(sum(all_scores) / len(all_scores), 1) if all_scores else 0.0

    return AnalysisResponse(
        success=True,
        image_type=output.image_type,
        overall_score=overall,
        landmark_count=output.landmark_count,
        categories=categories,
        total_metrics=len(output.ratios),
        landmarks=output.landmarks,
    )


# ─── Routes ───────────────────────────────────────────────────────────────────

@app.get("/")
async def root():
    return {"message": "FaceIQ Labs API", "docs": "/docs", "version": "1.0.0"}


@app.get("/health")
async def health():
    return {"status": "healthy"}


@app.on_event("startup")
async def startup_event():
    MediaPipeDetector.get_instance(refine_landmarks=True)
    logger.info("MediaPipe FaceMesh loaded.")


@app.post("/analyze/frontal", response_model=AnalysisResponse)
async def analyze_frontal(image: UploadFile = File(...)):
    """Analyze a front-facing photo for all frontal facial ratios."""
    if not image.content_type or not image.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="File must be an image.")

    data = await image.read()
    logger.info(f"Received frontal image: {image.filename}, size={len(data)}")

    output = analyze_image(data, "frontal")
    return build_response(output)


@app.post("/analyze/profile", response_model=AnalysisResponse)
async def analyze_profile(image: UploadFile = File(...)):
    """Analyze a side-profile photo for all profile facial ratios."""
    if not image.content_type or not image.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="File must be an image.")

    data = await image.read()
    logger.info(f"Received profile image: {image.filename}, size={len(data)}")

    output = analyze_image(data, "profile")
    return build_response(output)


@app.post("/analyze/combined", response_model=CombinedAnalysisResponse)
async def analyze_combined(
    frontal: Optional[UploadFile] = File(None),
    profile: Optional[UploadFile] = File(None),
):
    """Analyze both frontal and profile images in one request."""
    if frontal is None and profile is None:
        raise HTTPException(status_code=400, detail="At least one image required.")

    frontal_resp = None
    profile_resp = None

    if frontal is not None:
        data_f = await frontal.read()
        out_f = analyze_image(data_f, "frontal")
        frontal_resp = build_response(out_f)

    if profile is not None:
        data_p = await profile.read()
        out_p = analyze_image(data_p, "profile")
        profile_resp = build_response(out_p)

    scores = []
    if frontal_resp and frontal_resp.success:
        scores.append(frontal_resp.overall_score)
    if profile_resp and profile_resp.success:
        scores.append(profile_resp.overall_score)

    combined = round(sum(scores) / len(scores), 1) if scores else 0.0

    return CombinedAnalysisResponse(
        frontal=frontal_resp,
        profile=profile_resp,
        combined_score=combined,
    )



@app.post("/detect/frontal", response_model=DetectResponse)
async def detect_frontal(image: UploadFile = File(...)):
    """Detect face landmarks on a frontal image without computing ratios."""
    data = await image.read()
    lm = detect_landmarks_only(data)
    if lm is None:
        return DetectResponse(success=False, error="No face detected. Ensure face is clearly visible.")
    return DetectResponse(success=True, landmarks=lm)


@app.post("/detect/profile", response_model=DetectResponse)
async def detect_profile(image: UploadFile = File(...)):
    """Detect face landmarks on a profile image without computing ratios."""
    data = await image.read()
    lm = detect_landmarks_only(data)
    if lm is None:
        return DetectResponse(success=False, error="No face detected. Ensure face is clearly visible.")
    return DetectResponse(success=True, landmarks=lm)


@app.post("/analyze/combined_custom", response_model=CombinedAnalysisResponse)
async def analyze_combined_custom(
    frontal: Optional[UploadFile] = File(None),
    profile: Optional[UploadFile] = File(None),
    frontal_landmarks: Optional[str] = Form(None),
    profile_landmarks: Optional[str] = Form(None),
):
    """Analyze with optionally user-edited landmark coordinates."""
    if frontal is None and profile is None:
        raise HTTPException(status_code=400, detail="At least one image required.")

    frontal_resp = None
    profile_resp = None

    if frontal is not None:
        data_f = await frontal.read()
        if frontal_landmarks:
            lm_f = json.loads(frontal_landmarks)
            out_f = analyze_with_custom_landmarks(data_f, "frontal", lm_f)
        else:
            out_f = analyze_image(data_f, "frontal")
        frontal_resp = build_response(out_f)

    if profile is not None:
        data_p = await profile.read()
        if profile_landmarks:
            lm_p = json.loads(profile_landmarks)
            out_p = analyze_with_custom_landmarks(data_p, "profile", lm_p)
        else:
            out_p = analyze_image(data_p, "profile")
        profile_resp = build_response(out_p)

    scores = []
    if frontal_resp and frontal_resp.success:
        scores.append(frontal_resp.overall_score)
    if profile_resp and profile_resp.success:
        scores.append(profile_resp.overall_score)

    combined = round(sum(scores) / len(scores), 1) if scores else 0.0
    return CombinedAnalysisResponse(
        frontal=frontal_resp,
        profile=profile_resp,
        combined_score=combined,
    )


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
