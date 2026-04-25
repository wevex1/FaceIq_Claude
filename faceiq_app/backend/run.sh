#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────────────
# FaceIQ Labs — Backend Setup & Run Script
# ──────────────────────────────────────────────────────────────────────────────
set -e

echo "🔬 FaceIQ Labs — Backend Server"
echo "================================"

# Check Python
if ! command -v python3 &>/dev/null; then
    echo "❌  Python 3 is required but not found."
    exit 1
fi
echo "✅  Python3 found: $(python3 --version)"

# Create virtual environment if not exists
if [ ! -d "venv" ]; then
    echo "📦  Creating virtual environment..."
    python3 -m venv venv
fi

source venv/bin/activate

echo "📦  Installing dependencies..."
pip install --upgrade pip -q
pip install -r requirements.txt -q

echo ""
echo "🚀  Starting FaceIQ API server on http://localhost:8000"
echo "📚  API docs available at http://localhost:8000/docs"
echo ""
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
