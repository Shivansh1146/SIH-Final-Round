"""
SHAYAK-AI: FastAPI Clinical Cognitive Health & Explainability Backend
Provides sub-50ms cognitive impairment risk scoring, multimodal kinematic
fusion, and real-time SHAP feature attribution formatted for React 19 + Recharts.
"""

import sys
from pathlib import Path

# Enable direct script execution from IDE Run button
_parent_dir = str(Path(__file__).resolve().parent.parent)
if _parent_dir not in sys.path:
    sys.path.insert(0, _parent_dir)

from fastapi import FastAPI, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from datetime import datetime, timezone

from app.models import ClinicalEvaluationRequest, ClinicalEvaluationResponse
from app.ml_engine import ml_engine, FEATURE_METADATA

app = FastAPI(
    title="SHAYAK-AI Clinical Engine API",
    version="1.0.0",
    description=(
        "Production-ready backend API for SHAYAK-AI: active kinematic stabilization "
        "and clinical cognitive health assessment using scikit-learn and SHAP explainability."
    ),
    docs_url="/docs",
    redoc_url="/redoc",
)

# Enable CORS for React 19 Caregiver Portal and Flutter client access
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Production: configure specific caregiver portal origin
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get(
    "/health",
    tags=["System"],
    summary="Health check & ML model status",
)
def health_check():
    """
    Returns server uptime status and verification that the ML ensemble
    and SHAP TreeExplainer are loaded in memory.
    """
    is_ready = ml_engine.model is not None and ml_engine.explainer is not None
    return {
        "status": "online" if is_ready else "degraded",
        "service": "SHAYAK-AI Clinical Analytics & SHAP Engine",
        "model_loaded": is_ready,
        "base_expected_value": ml_engine.base_expected_value,
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }


@app.get(
    "/api/v1/meta/features",
    tags=["Metadata"],
    summary="Get feature metadata & baseline population metrics",
)
def get_features_metadata():
    """
    Returns the feature catalog, clinical labels, and baseline reference values
    for dynamic axis configuration in the React + Recharts caregiver portal.
    """
    return {
        "features": FEATURE_METADATA,
        "total_features": len(FEATURE_METADATA),
    }


@app.post(
    "/api/v1/clinical/evaluate",
    response_model=ClinicalEvaluationResponse,
    status_code=status.HTTP_200_OK,
    tags=["Clinical Analytics"],
    summary="Evaluate patient biomarkers and compute SHAP explainability attribution",
)
def evaluate_clinical_biomarkers(request: ClinicalEvaluationRequest):
    """
    Ingests patient game metrics, ESP32 kinematic tremor variance, and regional
    voice acoustic parameters. Computes calibrated diagnostic risk probabilities
    and real-time local SHAP values formatted for Recharts waterfall visualizations.
    """
    try:
        response = ml_engine.evaluate_patient(request)
        return response
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Clinical evaluation pipeline encountered an error: {str(exc)}",
        ) from exc


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("app.main:app", host="0.0.0.0", port=8000, reload=True)
