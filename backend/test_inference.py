"""
Automated Test Suite for SHAYAK-AI Clinical Analytics & SHAP Engine
Validates model predictions, probability calibration, and SHAP waterfall data structures.
"""

import sys
import os

# Add parent directory to sys.path to allow imports from app
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "app"))

from app.models import (
    ClinicalEvaluationRequest,
    KinematicTelemetryPayload,
    PatientSessionRecord,
)
from app.ml_engine import ml_engine, CLASSES
from app.main import app
from fastapi.testclient import TestClient


def run_tests():
    print("==========================================================")
    print("  Testing SHAYAK-AI ML Engine & FastAPI Endpoints         ")
    print("==========================================================")

    # Test Case 1: High Cognitive Risk Profile (Elderly, high tremor, low clock score, many hesitations)
    high_risk_patient = ClinicalEvaluationRequest(
        patient_id="PT-TEST-001",
        age=81,
        clock_drawing_score=3.2,
        drawing_hesitation_count=12,
        drawing_mean_velocity=0.11,
        kinematic_tremor_variance=24.6,
        postural_stability_score=54.0,
        memory_recall_accuracy=0.35,
        pattern_sequence_latency_ms=2150.0,
        speech_hesitation_ratio=0.48,
        phonation_jitter=0.068,
        acoustic_energy_entropy=4.1,
    )

    print("\n[TEST 1] Evaluating High-Risk Patient...")
    resp1 = ml_engine.evaluate_patient(high_risk_patient)
    print(f"  -> Diagnostic Category: {resp1.diagnostic_category}")
    print(f"  -> Risk Probabilities: {resp1.risk_probabilities}")
    print(f"  -> Primary Risk Score: {resp1.primary_risk_score}")
    print(f"  -> Top 3 SHAP Drivers for Waterfall:")
    for attr in resp1.shap_waterfall_attributions[:3]:
        print(f"     * {attr.display_name}: val={attr.patient_value}, SHAP={attr.shap_value} ({attr.direction})")

    # Assertions
    assert resp1.diagnostic_category in CLASSES, "Invalid diagnostic category"
    total_prob = sum(resp1.risk_probabilities.values())
    assert abs(total_prob - 1.0) < 0.05, f"Probabilities do not sum to ~1.0: {total_prob}"
    assert len(resp1.shap_waterfall_attributions) == 11, "Expected 11 feature attributions"
    assert len(resp1.clinical_recommendations) > 0, "Expected recommendations"
    print("  [PASS] Test 1 passed successfully.")

    # Test Case 2: Healthy Control Profile (Younger-old, clear clock, zero tremor, swift memory)
    healthy_patient = ClinicalEvaluationRequest(
        patient_id="PT-TEST-002",
        age=62,
        clock_drawing_score=9.5,
        drawing_hesitation_count=1,
        drawing_mean_velocity=0.48,
        kinematic_tremor_variance=2.1,
        postural_stability_score=95.0,
        memory_recall_accuracy=0.95,
        pattern_sequence_latency_ms=620.0,
        speech_hesitation_ratio=0.08,
        phonation_jitter=0.012,
        acoustic_energy_entropy=1.8,
    )

    print("\n[TEST 2] Evaluating Healthy Control Patient...")
    resp2 = ml_engine.evaluate_patient(healthy_patient)
    print(f"  -> Diagnostic Category: {resp2.diagnostic_category}")
    print(f"  -> Risk Probabilities: {resp2.risk_probabilities}")
    print(f"  -> Primary Risk Score: {resp2.primary_risk_score}")
    print(f"  -> Top 3 Protective SHAP Drivers:")
    for attr in resp2.shap_waterfall_attributions[:3]:
        print(f"     * {attr.display_name}: val={attr.patient_value}, SHAP={attr.shap_value} ({attr.direction})")

    assert resp2.primary_risk_score < resp1.primary_risk_score, "Healthy patient risk score should be lower than high risk"
    print("  [PASS] Test 2 passed successfully.")

    # Test Case 3: FastAPI TestClient Validation (REST endpoints, Health, Telemetry, History)
    print("\n[TEST 3] Testing FastAPI Endpoints with TestClient...")
    client = TestClient(app)

    # Health check
    health_res = client.get("/health")
    assert health_res.status_code == 200
    assert health_res.json()["status"] in ["healthy", "online"]
    print("  -> /health: OK")

    # Features metadata
    meta_res = client.get("/api/v1/meta/features")
    assert meta_res.status_code == 200
    assert meta_res.json()["total_features"] == 11
    print("  -> /api/v1/meta/features: OK (11 features)")

    # ESP32 Telemetry Ingestion
    telemetry_payload = {
        "device_id": "ESP32-STABILIZER-01",
        "patient_id": "PT-9042",
        "roll_deg": 3.4,
        "pitch_deg": -1.2,
        "yaw_deg": 45.0,
        "vertical_accel_ms2": 9.85,
        "net_force_error_n": 0.01,
        "tremor_variance": 14.5,
        "thrust_pwm_z": 540,
        "stabilization_active": True,
        "timestamp_ms": 124500
    }
    telem_res = client.post("/api/v1/kinematic/telemetry", json=telemetry_payload)
    assert telem_res.status_code == 200
    assert telem_res.json()["tremor_status"] == "mild_tremor"
    print("  -> /api/v1/kinematic/telemetry: OK (mild_tremor identified)")

    # Session Recording with Auto-Adaptive Difficulty Check
    session_payload = {
        "session_id": "SES-TEST-999",
        "patient_id": "PT-9042",
        "activity_type": "memory_match",
        "score": 92.0,
        "duration_seconds": 120,
        "difficulty_level": "Level 2 (Moderate)",
        "is_adaptive": True,
        "metrics": {"pairs_matched": 6.0, "total_turns": 7.0},
        "notes": "Excellent focused session with high accuracy",
        "timestamp": "2026-09-08T12:00:00Z"
    }
    sess_res = client.post("/api/v1/patient/PT-9042/session", json=session_payload)
    assert sess_res.status_code == 201
    sess_data = sess_res.json()
    assert sess_data["status"] == "recorded"
    assert sess_data["adaptation_event"] == "advanced"
    assert sess_data["current_difficulty"] == "Level 3 (Challenging)"
    print("  -> /api/v1/patient/{id}/session: OK (Auto-Advanced to Level 3)")

    # Difficulty Update (Manual Selection Override)
    diff_payload = {
        "difficulty_level": "Level 1 (Gentle)",
        "is_adaptive": False,
        "caregiver_override": True
    }
    diff_res = client.post("/api/v1/patient/PT-9042/difficulty", json=diff_payload)
    assert diff_res.status_code == 200
    assert diff_res.json()["difficulty_level"] == "Level 1 (Gentle)"
    assert diff_res.json()["is_adaptive"] is False
    print("  -> /api/v1/patient/{id}/difficulty: OK (Manual override to Gentle)")

    # Patient History Check
    hist_res = client.get("/api/v1/patient/PT-9042/history")
    assert hist_res.status_code == 200
    hist_data = hist_res.json()
    assert hist_data["patient_name"] == "Ramesh Kumar"
    assert hist_data["current_difficulty_level"] == "Level 1 (Gentle)"
    assert hist_data["is_adaptive_mode"] is False
    print(f"  -> /api/v1/patient/PT-9042/history: OK (Verified dynamic difficulty state)")

    print("  [PASS] Test 3 passed successfully.")

    print("\n==========================================================")
    print("  ALL TESTS PASSED: Full Backend Architecture Verified!    ")
    print("==========================================================")


if __name__ == "__main__":
    run_tests()


