"""
SHAYAK-AI: Pydantic Data Models & Schema Contracts
Defines validated input schemas for multi-modal clinical biomarkers
and structured output schemas optimized for React 19 + Recharts dashboards.
"""

from typing import List, Dict, Literal
from pydantic import BaseModel, Field


class ClinicalEvaluationRequest(BaseModel):
    """
    Multimodal clinical observation payload capturing cognitive game results,
    kinematic stabilization IMU telemetry, and regional acoustic biomarkers.
    """
    patient_id: str = Field(..., description="Unique patient or assessment identifier", example="PT-9042")
    age: int = Field(..., ge=40, le=115, description="Patient age in years", example=74)
    
    # Module 2 Game & Drawing Kinematics
    clock_drawing_score: float = Field(
        ..., ge=0.0, le=10.0, description="On-device TFLite clock contour score (0 to 10)", example=6.5
    )
    drawing_hesitation_count: int = Field(
        ..., ge=0, description="Number of pauses > 500ms during drawing assessment", example=7
    )
    drawing_mean_velocity: float = Field(
        ..., ge=0.0, description="Average stylus stroke velocity (pixels/ms)", example=0.18
    )
    
    # Module 1 ESP32 Microcontroller Kinematics & Tremor
    kinematic_tremor_variance: float = Field(
        ..., ge=0.0, description="Sliding window micro-jitter variance in 4-12 Hz band", example=18.4
    )
    postural_stability_score: float = Field(
        ..., ge=0.0, le=100.0, description="Closed-loop thrust-vector counter-balance index", example=72.0
    )
    
    # Cognitive Game Performance
    memory_recall_accuracy: float = Field(
        ..., ge=0.0, le=1.0, description="Memory recall accuracy (pairs matched ratio)", example=0.62
    )
    pattern_sequence_latency_ms: float = Field(
        ..., ge=0.0, description="Average response latency on cultural pattern sequences (ms)", example=1420.0
    )
    
    # Acoustic & Regional Voice Biomarkers
    speech_hesitation_ratio: float = Field(
        ..., ge=0.0, le=1.0, description="Acoustic silence/hesitation proportion during speech", example=0.34
    )
    phonation_jitter: float = Field(
        ..., ge=0.0, le=1.0, description="Cycle-to-cycle frequency variation of vocal cords", example=0.052
    )
    acoustic_energy_entropy: float = Field(
        ..., ge=0.0, description="Spectral entropy indicating speech energy variation", example=3.85
    )

    class Config:
        json_schema_extra = {
            "example": {
                "patient_id": "PT-9042",
                "age": 74,
                "clock_drawing_score": 6.5,
                "drawing_hesitation_count": 7,
                "drawing_mean_velocity": 0.18,
                "kinematic_tremor_variance": 18.4,
                "postural_stability_score": 72.0,
                "memory_recall_accuracy": 0.62,
                "pattern_sequence_latency_ms": 1420.0,
                "speech_hesitation_ratio": 0.34,
                "phonation_jitter": 0.052,
                "acoustic_energy_entropy": 3.85,
            }
        }


class FeatureSHAPAttribution(BaseModel):
    """
    Individual feature attribution record tailored for React 19 + Recharts waterfall charts.
    """
    feature: str = Field(..., description="Machine-readable feature key")
    display_name: str = Field(..., description="Human-readable clinical label")
    patient_value: float = Field(..., description="Actual value measured for this patient")
    shap_value: float = Field(..., description="Local SHAP value contribution toward risk")
    direction: Literal["elevates_risk", "reduces_risk"] = Field(
        ..., description="Direction of impact on cognitive impairment probability"
    )
    baseline_reference: float = Field(..., description="Population baseline reference value")


class ClinicalEvaluationResponse(BaseModel):
    """
    Diagnostic assessment response including class probabilities,
    primary risk tier, and sorted SHAP explainability attributions.
    """
    patient_id: str
    diagnostic_category: Literal[
        "Normal Cognition", "Mild Cognitive Impairment (MCI)", "Probable Dementia"
    ]
    primary_risk_score: float = Field(
        ..., ge=0.0, le=1.0, description="Aggregated impairment risk probability (MCI + Dementia)"
    )
    risk_probabilities: Dict[str, float] = Field(
        ..., description="Calibrated posterior probability distribution over diagnostic classes"
    )
    expected_base_value: float = Field(
        ..., description="Base model expected value prior to SHAP feature adjustments"
    )
    shap_waterfall_attributions: List[FeatureSHAPAttribution] = Field(
        ..., description="Feature SHAP attributions sorted by absolute magnitude for Recharts rendering"
    )
    clinical_recommendations: List[str] = Field(
        ..., description="Contextual recommendations for caregivers and clinicians"
    )
    evaluated_at: str
