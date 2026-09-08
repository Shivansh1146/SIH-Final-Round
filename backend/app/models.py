"""
SHAYAK-AI: Pydantic Data Models & Schema Contracts
Defines validated input schemas for multi-modal clinical biomarkers
and structured output schemas optimized for React 19 + Recharts dashboards.
"""

from datetime import datetime, timezone
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


class KinematicTelemetryPayload(BaseModel):
    """
    ESP32 Real-Time Kinematic & Tremor IMU Telemetry Packet.
    """
    device_id: str = Field(default="ESP32-STABILIZER-01", description="Hardware identifier")
    patient_id: str = Field(default="PT-9042", description="Patient identifier")
    roll_deg: float = Field(..., description="Roll angle in degrees (-180 to +180)")
    pitch_deg: float = Field(..., description="Pitch angle in degrees (-90 to +90)")
    yaw_deg: float = Field(..., description="Yaw angle in degrees (0 to 360)")
    vertical_accel_ms2: float = Field(..., description="Inertial earth-frame vertical acceleration (m/s^2)")
    net_force_error_n: float = Field(..., description="Net force error F_net along vertical axis (N)")
    tremor_variance: float = Field(..., description="Sliding window micro-jitter variance in 4-12 Hz band")
    thrust_pwm_z: int = Field(..., ge=0, le=1023, description="Active PWM duty cycle on counter-thrust")
    stabilization_active: bool = Field(default=True, description="Active PID stabilization status")
    timestamp_ms: int = Field(..., description="ESP32 monotonic timestamp")


class PatientSessionRecord(BaseModel):
    """
    Completed cognitive assessment session record (Clock Drawing, Memory Match, or Multi-modal).
    """
    session_id: str = Field(default_factory=lambda: f"session-{int(datetime.now().timestamp())}", description="Unique session identifier")
    patient_id: str = Field(default="PT-9042", description="Patient identifier")
    activity_type: str = Field(default="routine_sequencer", description="Activity name")
    score: float = Field(default=80.0, ge=0.0, le=100.0, description="Normalized score 0-100")
    duration_seconds: int = Field(default=30, ge=0, description="Duration of session in seconds")
    difficulty_level: str = Field(default="Level 2 (Moderate)", description="Difficulty level during session")
    is_adaptive: bool = Field(default=True, description="Whether adaptive difficulty was enabled")
    metrics: Dict[str, float] = Field(default_factory=dict, description="Detailed biomarker metric dictionary")
    notes: str = Field(default="", description="Optional caregiver or system notes")
    timestamp: str = Field(default_factory=lambda: datetime.now(timezone.utc).isoformat(), description="ISO 8601 timestamp")


class PatientDifficultyUpdateRequest(BaseModel):
    """
    Manual or algorithmic difficulty configuration request.
    """
    difficulty_level: Literal["Level 1 (Gentle)", "Level 2 (Moderate)", "Level 3 (Challenging)", "Level 4 (Master)"]
    is_adaptive: bool = True
    caregiver_override: bool = False


class LongitudinalPatientHistory(BaseModel):
    """
    Longitudinal summary of patient assessment sessions and risk progression over time.
    """
    patient_id: str
    patient_name: str
    age: int
    caregiver_name: str
    total_sessions_completed: int
    average_accuracy: float
    current_difficulty_level: str
    is_adaptive_mode: bool = True
    recent_sessions: List[PatientSessionRecord]
    latest_evaluation: ClinicalEvaluationResponse | None = None


class DoctorAppointmentModel(BaseModel):
    id: str
    patient_id: str
    patient_name: str
    doctor_name: str
    clinic_or_hospital: str
    appointment_type: str
    scheduled_date: str
    time_slot: str
    caregiver_name: str
    caregiver_phone: str
    reason_for_visit: str
    status: str = "Confirmed"
    doctor_feedback_for_caregiver: str | None = None
    booked_at: str = Field(default_factory=lambda: datetime.now(timezone.utc).isoformat())


class AppointmentFeedbackRequest(BaseModel):
    doctor_feedback_for_caregiver: str
    status: str | None = None


class DoctorFeedbackModel(BaseModel):
    id: str
    patient_id: str
    doctor_name: str
    hospital_or_clinic: str
    specialty: str
    clinical_impression: str
    feedback_notes: str
    prescribed_directives: List[str] = Field(default_factory=list)
    recommended_difficulty: str = "Level 2 (Moderate)"
    submitted_at: str = Field(default_factory=lambda: datetime.now(timezone.utc).isoformat())


class MedicalNotesRequest(BaseModel):
    medical_notes: str



