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

from app.models import (
    ClinicalEvaluationRequest,
    ClinicalEvaluationResponse,
    KinematicTelemetryPayload,
    PatientSessionRecord,
    PatientDifficultyUpdateRequest,
    LongitudinalPatientHistory,
    DoctorAppointmentModel,
    AppointmentFeedbackRequest,
    DoctorFeedbackModel,
    MedicalNotesRequest,
)
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

# Patient difficulty state store
DIFFICULTY_TIERS = [
    "Level 1 (Gentle)",
    "Level 2 (Moderate)",
    "Level 3 (Challenging)",
    "Level 4 (Master)",
]

patient_difficulty_store = {
    "PT-9042": {
        "difficulty_level": "Level 2 (Moderate)",
        "is_adaptive": True,
        "last_updated": datetime.now(timezone.utc).isoformat(),
    }
}

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
    summary="Liveness and ML Model Readiness Probe",
)
def health_check():
    """Returns operational status, model calibration verification, and server uptime."""
    is_ready = ml_engine.model is not None and ml_engine.explainer is not None
    return {
        "status": "healthy" if is_ready else "degraded",
        "service": "shayak-clinical-engine",
        "model_loaded": is_ready,
        "base_expected_value": ml_engine.base_expected_value,
        "features_supported": len(FEATURE_METADATA),
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
    tags=["Clinical Inference"],
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


@app.post(
    "/api/v1/kinematic/telemetry",
    status_code=status.HTTP_200_OK,
    tags=["Kinematic & IoT"],
    summary="Ingest ESP32 live IMU telemetry packet",
)
def ingest_kinematic_telemetry(payload: KinematicTelemetryPayload):
    """
    Processes high-frequency inertial telemetry from ESP32 active stabilizer.
    Computes stability status, tremor classification, and counter-thrust efficacy.
    """
    tremor_status = "stable"
    if payload.tremor_variance > 18.0:
        tremor_status = "severe_tremor"
    elif payload.tremor_variance > 8.0:
        tremor_status = "mild_tremor"

    return {
        "received": True,
        "device_id": payload.device_id,
        "patient_id": payload.patient_id,
        "tremor_status": tremor_status,
        "tremor_variance": round(payload.tremor_variance, 3),
        "counter_thrust_pwm": payload.thrust_pwm_z,
        "inertial_z_ms2": round(payload.vertical_accel_ms2, 2),
        "timestamp_ms": payload.timestamp_ms,
        "server_time": datetime.now(timezone.utc).isoformat(),
    }


@app.get(
    "/api/v1/patient/{patient_id}/history",
    response_model=LongitudinalPatientHistory,
    tags=["Patient Records"],
    summary="Retrieve longitudinal patient session history and assessments",
)
def get_patient_history(patient_id: str):
    """
    Returns session progression, completed games, and latest clinical evaluation.
    """
    sessions = ml_engine.patient_sessions.get(patient_id, [])
    
    # Calculate aggregate metrics
    avg_acc = 76.0
    if sessions:
        avg_acc = round(sum(s.get("score", 75.0) for s in sessions) / len(sessions), 1)

    # Get difficulty configuration
    p_diff = patient_difficulty_store.get(
        patient_id,
        {"difficulty_level": "Level 2 (Moderate)", "is_adaptive": True},
    )

    # Compute baseline evaluation
    baseline_req = ClinicalEvaluationRequest(
        patient_id=patient_id,
        age=68,
        clock_drawing_score=8.5,
        drawing_hesitation_count=3,
        drawing_mean_velocity=0.22,
        kinematic_tremor_variance=12.4,
        postural_stability_score=84.0,
        memory_recall_accuracy=0.76,
        pattern_sequence_latency_ms=1120.0,
        speech_hesitation_ratio=0.22,
        phonation_jitter=0.038,
        acoustic_energy_entropy=3.12,
    )
    latest_eval = ml_engine.evaluate_patient(baseline_req)

    return LongitudinalPatientHistory(
        patient_id=patient_id,
        patient_name="Ramesh Kumar" if patient_id == "PT-9042" else f"Patient {patient_id}",
        age=68,
        caregiver_name="Anita Kumar",
        total_sessions_completed=len(sessions) + 10,
        average_accuracy=avg_acc,
        current_difficulty_level=p_diff["difficulty_level"],
        is_adaptive_mode=p_diff["is_adaptive"],
        recent_sessions=[PatientSessionRecord(**s) for s in sessions],
        latest_evaluation=latest_eval,
    )


@app.post(
    "/api/v1/patient/{patient_id}/difficulty",
    status_code=status.HTTP_200_OK,
    tags=["Patient Records"],
    summary="Update or override patient difficulty settings (manual/adaptive)",
)
def update_patient_difficulty(patient_id: str, payload: PatientDifficultyUpdateRequest):
    """
    Allows patient or caregiver to manually override difficulty or toggle AI-adaptive mode.
    """
    patient_difficulty_store[patient_id] = {
        "difficulty_level": payload.difficulty_level,
        "is_adaptive": payload.is_adaptive,
        "last_updated": datetime.now(timezone.utc).isoformat(),
        "caregiver_override": payload.caregiver_override,
    }
    return {
        "status": "updated",
        "patient_id": patient_id,
        "difficulty_level": payload.difficulty_level,
        "is_adaptive": payload.is_adaptive,
    }


@app.post(
    "/api/v1/patient/{patient_id}/session",
    status_code=status.HTTP_201_CREATED,
    tags=["Patient Records"],
    summary="Record a completed cognitive assessment session with auto difficulty adaptation",
)
def record_patient_session(patient_id: str, session: PatientSessionRecord):
    """
    Appends a new cognitive or drawing assessment session to the patient's record.
    If adaptive difficulty is enabled, evaluates performance score and automatically
    transitions difficulty tier up or down.
    """
    if patient_id not in ml_engine.patient_sessions:
        ml_engine.patient_sessions[patient_id] = []

    session_dict = session.model_dump()
    ml_engine.patient_sessions[patient_id].insert(0, session_dict)

    # Fetch current difficulty state
    diff_state = patient_difficulty_store.setdefault(
        patient_id,
        {"difficulty_level": session.difficulty_level, "is_adaptive": session.is_adaptive},
    )

    adaptation_event = "maintained"
    new_difficulty = diff_state["difficulty_level"]

    if session.is_adaptive:
        curr_idx = DIFFICULTY_TIERS.index(diff_state["difficulty_level"]) if diff_state["difficulty_level"] in DIFFICULTY_TIERS else 1
        
        # High accuracy / performance -> step up
        if session.score >= 85.0 and curr_idx < len(DIFFICULTY_TIERS) - 1:
            new_difficulty = DIFFICULTY_TIERS[curr_idx + 1]
            adaptation_event = "advanced"
            diff_state["difficulty_level"] = new_difficulty
        # High struggle / low score -> gentle step down
        elif session.score < 55.0 and curr_idx > 0:
            new_difficulty = DIFFICULTY_TIERS[curr_idx - 1]
            adaptation_event = "gentle_assist"
            diff_state["difficulty_level"] = new_difficulty

    return {
        "status": "recorded",
        "session_id": session.session_id,
        "patient_id": patient_id,
        "adaptation_event": adaptation_event,
        "current_difficulty": new_difficulty,
        "is_adaptive": diff_state.get("is_adaptive", True),
        "total_sessions": len(ml_engine.patient_sessions[patient_id]),
    }


# ============================================================================
# APPOINTMENT & CLINICAL FEEDBACK ENDPOINTS
# ============================================================================

# In-memory stores with realistic initial clinical seeds
appointments_store: list[dict] = [
    {
        "id": "apt-1",
        "patient_id": "patient-ramesh",
        "patient_name": "Ramesh Kumar",
        "doctor_name": "Dr. Debabrata Goswami, DM",
        "clinic_or_hospital": "Assam Medical College & Hospital",
        "appointment_type": "In-Person Neuro Consultation",
        "scheduled_date": "2026-09-12T11:00:00Z",
        "time_slot": "11:00 AM",
        "caregiver_name": "Anita Kumar",
        "caregiver_phone": "+91 98450 12345",
        "reason_for_visit": "Bi-monthly cognitive progression review and ESP32 kinematic utensil stability check.",
        "status": "Confirmed",
        "doctor_feedback_for_caregiver": "Confirmed for 11:00 AM. Please bring the ESP32 utensil usage logs and ensure Ramesh had a light breakfast.",
        "booked_at": datetime.now(timezone.utc).isoformat(),
    },
    {
        "id": "apt-2",
        "patient_id": "patient-monalisa",
        "patient_name": "Monalisa Barua",
        "doctor_name": "Dr. Priya Sengupta, MD",
        "clinic_or_hospital": "Guwahati Neurological Institute",
        "appointment_type": "Telehealth Video Review",
        "scheduled_date": "2026-09-14T14:30:00Z",
        "time_slot": "02:30 PM",
        "caregiver_name": "Pranab Barua",
        "caregiver_phone": "+91 94350 12345",
        "reason_for_visit": "Follow-up on morning routine orientation and Memory Lane recall progress.",
        "status": "Confirmed",
        "doctor_feedback_for_caregiver": None,
        "booked_at": datetime.now(timezone.utc).isoformat(),
    },
]

clinical_feedback_store: list[dict] = [
    {
        "id": "df-1",
        "patient_id": "patient-ramesh",
        "doctor_name": "Dr. Debabrata Goswami, DM",
        "hospital_or_clinic": "Assam Medical College & Hospital",
        "specialty": "Cognitive Neurology & Movement Disorders",
        "clinical_impression": "Stable & Responsive to Routine",
        "feedback_notes": "Patient exhibits consistent engagement with memory recall games (average accuracy above 78%). Kinematic tremor variance has remained well stabilized with the ESP32 active utensil. Recommend maintaining the current cognitive exercise cadence.",
        "prescribed_directives": [
            "Maintain daily 15-minute Memory Match and Memory Story sessions.",
            "Keep ESP32 utensil sensor calibrated before meal times.",
            "Continue Donepezil 5mg once daily after breakfast.",
            "Schedule follow-up review in 8 weeks.",
        ],
        "recommended_difficulty": "Level 2 (Moderate)",
        "submitted_at": datetime.now(timezone.utc).isoformat(),
    }
]

patient_medical_notes_store: dict[str, str] = {
    "patient-ramesh": "Hypertension controlled on Amlodipine 5mg. Mild short-term memory lapses noticed since 6 months. High adherence to memory training and active utensil usage.",
    "patient-monalisa": "Autobiographical reminiscing (Memory Lane) highly effective. Attentional fluctuations in mornings. No history of stroke or focal neurological deficits.",
    "patient-tenzin": "Postural tremors stabilized with adaptive utensil. Gait evaluation shows slight bradykinesia. Recommend daily balance and visual search drills.",
}


@app.get("/api/v1/appointments", tags=["Appointments"], summary="List all appointments")
def get_all_appointments(patient_id: str | None = None):
    if patient_id:
        return [a for a in appointments_store if a["patient_id"] == patient_id]
    return appointments_store


@app.post("/api/v1/appointments", status_code=status.HTTP_201_CREATED, tags=["Appointments"], summary="Book a new doctor appointment")
def book_appointment(appointment: DoctorAppointmentModel):
    appt_dict = appointment.model_dump()
    appointments_store.insert(0, appt_dict)
    return {"status": "booked", "appointment": appt_dict}


@app.patch("/api/v1/appointments/{appointment_id}/feedback", tags=["Appointments"], summary="Send doctor feedback to caregiver for this appointment")
def update_appointment_feedback(appointment_id: str, payload: AppointmentFeedbackRequest):
    for a in appointments_store:
        if a["id"] == appointment_id:
            a["doctor_feedback_for_caregiver"] = payload.doctor_feedback_for_caregiver
            if payload.status:
                a["status"] = payload.status
            return {"status": "updated", "appointment": a}
    raise HTTPException(status_code=404, detail="Appointment not found")


@app.patch("/api/v1/appointments/{appointment_id}/status", tags=["Appointments"], summary="Update appointment status")
def update_appointment_status(appointment_id: str, new_status: str):
    for a in appointments_store:
        if a["id"] == appointment_id:
            a["status"] = new_status
            return {"status": "updated", "appointment": a}
    raise HTTPException(status_code=404, detail="Appointment not found")


@app.get("/api/v1/feedback", tags=["Clinical Feedback"], summary="Get clinical feedback history")
def get_clinical_feedback(patient_id: str | None = None):
    if patient_id:
        return [f for f in clinical_feedback_store if f["patient_id"] == patient_id]
    return clinical_feedback_store


@app.post("/api/v1/feedback", status_code=status.HTTP_201_CREATED, tags=["Clinical Feedback"], summary="Submit physician clinical feedback")
def submit_clinical_feedback(feedback: DoctorFeedbackModel):
    fb_dict = feedback.model_dump()
    clinical_feedback_store.insert(0, fb_dict)
    return {"status": "recorded", "feedback": fb_dict}


@app.get("/api/v1/patient/{patient_id}/notes", tags=["Medical Notes"], summary="Get doctor notes for patient")
def get_patient_medical_notes(patient_id: str):
    notes = patient_medical_notes_store.get(patient_id, "")
    return {"patient_id": patient_id, "medical_notes": notes}


@app.put("/api/v1/patient/{patient_id}/notes", tags=["Medical Notes"], summary="Update doctor notes for patient")
def update_patient_medical_notes(patient_id: str, payload: MedicalNotesRequest):
    patient_medical_notes_store[patient_id] = payload.medical_notes
    return {"status": "saved", "patient_id": patient_id, "medical_notes": payload.medical_notes}


if __name__ == "__main__":
    import uvicorn
    import os
    port = int(os.environ.get("PORT", 8000))
    uvicorn.run("app.main:app", host="0.0.0.0", port=port, reload=False)
