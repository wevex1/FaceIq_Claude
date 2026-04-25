# FaceIQ Labs — Facial Ratio Analysis App

A full-stack application that analyzes facial harmony using **40+ anthropometric ratios** from the FaceIQ Labs research guide. Built with a **Python/FastAPI backend** and a **Flutter mobile frontend**.

---

## Architecture

```
faceiq_app/
├── backend/               ← Python FastAPI server
│   ├── face_analyzer.py   ← Core logic: MediaPipe + ratio formulas
│   ├── main.py            ← REST API endpoints
│   ├── requirements.txt
│   └── run.sh
└── frontend/              ← Flutter mobile app
    ├── lib/
    │   ├── main.dart
    │   ├── models/        ← Data models (API response types)
    │   ├── services/      ← HTTP API client
    │   ├── screens/       ← Home + Results screens
    │   └── widgets/       ← ScoreGauge, MetricCard, CategorySection
    ├── pubspec.yaml
    ├── android/           ← Android permissions
    └── ios/               ← iOS permissions
```

---

## Metrics Implemented

### Frontal Analysis (25+ metrics)
| Category         | Metrics |
|-----------------|---------|
| Facial Thirds    | Upper/Middle/Lower third proportions |
| Face Shape       | FWHR, Total W/H, Midface Ratio, Bitemporal Width, Bigonial Width |
| Eyes & Brows     | Eye Aspect Ratio, Eye Separation, One-Eye-Apart, Canthal Tilt, Brow Tilt, Brow/Face Width |
| Nose (Frontal)   | Intercanthal/Nasal Width, Nose Bridge/Width, Nasal Width%, Nose Tip Deviation |
| Mouth & Lips     | Lower/Upper Lip Ratio, Mouth/Eye Width, Mouth/Nose Width, Chin/Philtrum, Jaw Frontal Angle, Jaw Slope |

### Profile Analysis (20+ metrics)
| Category              | Metrics |
|----------------------|---------|
| Upper Face           | Nasofrontal Angle |
| Facial Convexity     | Glabella/Nasion convexity, Total Facial Convexity |
| Nose (Profile)       | Nasolabial Angle, Nasomental Angle, Nasofacial Angle, Nasal Projection |
| Lips (Profile)       | E-Line (upper/lower), S-Line (upper/lower), Mentolabial Angle |
| Jaw (Profile)        | Mandibular Plane Angle, Gonial Angle, Ramus/Mandible Ratio, Chin Projection |

All metrics include:
- Computed value
- Ideal range (from FaceIQ data + anthropometric literature)
- 0–10 harmony score
- Clinical interpretation

---

## Setup Instructions

### 1. Backend (Python)

**Requirements:** Python 3.10+

```bash
cd backend

# Option A: Use the script (creates venv automatically)
chmod +x run.sh
./run.sh

# Option B: Manual setup
python3 -m venv venv
source venv/bin/activate          # Windows: venv\Scripts\activate
pip install -r requirements.txt
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

The API will be available at:
- `http://localhost:8000` — Root
- `http://localhost:8000/docs` — Swagger UI (test endpoints)
- `http://localhost:8000/health` — Health check

#### API Endpoints
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/analyze/frontal` | Analyze a frontal face photo |
| POST | `/analyze/profile` | Analyze a side profile photo |
| POST | `/analyze/combined` | Analyze both at once (recommended) |

---

### 2. Flutter Frontend

**Requirements:** Flutter 3.19+ (Dart 3.3+)

```bash
cd frontend

# Install dependencies
flutter pub get

# Run on Android emulator or device
flutter run

# Build APK
flutter build apk --release

# Build iOS (macOS only)
flutter build ios --release
```

#### Configure Server URL

In `lib/services/api_service.dart`, update `_baseUrl`:

```dart
// For Android emulator
static const String _baseUrl = 'http://10.0.2.2:8000';

// For iOS simulator
static const String _baseUrl = 'http://localhost:8000';

// For real device (replace with your machine's LAN IP)
static const String _baseUrl = 'http://192.168.1.X:8000';
```

---

## Usage

1. **Launch the app** and see the home screen
2. **Tap "Front View"** to select a frontal face photo from your gallery
3. **Tap "Side Profile"** to select a profile photo (optional but recommended)
4. **Tap "Analyze Face"** — the app sends images to the backend
5. View results on the **Results screen**:
   - **Overview tab:** Combined score + category breakdown radar chart
   - **Frontal tab:** All 25+ frontal metrics grouped by category
   - **Profile tab:** All 20+ profile metrics grouped by category
6. **Tap any metric card** to expand and read the clinical interpretation

---

## Photo Guidelines

For accurate results:
- **Lighting:** Bright, even diffused light; avoid harsh shadows or backlighting
- **Expression:** Neutral, relaxed face; mouth closed; no squinting
- **Front view:** Camera at eye level, face perfectly centered, head level
- **Profile view:** Exactly 90° from camera; chin parallel to ground
- **Resolution:** At least 800×600 pixels; face occupying 60%+ of frame
- **Avoid:** Glasses (if possible), hair covering face, extreme make-up

---

## Technology Stack

| Component | Technology |
|-----------|-----------|
| Landmark detection | MediaPipe FaceMesh (468 points + iris refinement) |
| Image processing | OpenCV |
| Maths | NumPy, SciPy |
| API server | FastAPI + Uvicorn |
| Mobile UI | Flutter 3 |
| Charts | fl_chart |
| Fonts | Google Fonts (Inter + Space Grotesk) |

---

## Extending

### Add a New Metric
1. Open `backend/face_analyzer.py`
2. In `compute_frontal_ratios()` or `compute_profile_ratios()`, call `add()`:
```python
add(
    name="My New Ratio",
    val=some_distance / another_distance,
    imin=0.8, imax=1.2,
    unit="×",
    interp="Description of what this measures and means.",
    cat="Category Name",
)
```

### Change Server Port
Edit `run.sh` and update `_baseUrl` in the Flutter app.

---

## References

- FaceIQ Labs research: `research_Facial_Ratio.md`  
- Farkas et al. — *Anthropometry of the Head and Face*  
- MediaPipe FaceMesh documentation  
- Aesthetic surgery guides (Nasolabial angle, Nasofrontal angle norms)  
- Ricketts' Z-angle and cephalometric references  


## Run app

### Backend

```bash
cd C:\FaceIQ\faceiq_app\backend
venv\Scripts\activate
python -m uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

### Frontend

```bash
cd C:\FaceIQ\faceiq_app\frontend
flutter clean
flutter pub get
flutter run -d chrome
```