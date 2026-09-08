"""
Automated Test Suite for SHAYAK-AI Clinical Analytics & SHAP Engine
Validates model predictions, probability calibration, and SHAP waterfall data structures.
"""

import sys
import os

# Add parent directory to sys.path to allow imports from app
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "app"))

from app.models import ClinicalEvaluationRequest
from app.ml_engine import ml_engine, CLASSES


def run_tests():
    print("==========================================================")
    print("  Testing SHAYAK-AI ML Engine & SHAP TreeExplainer        ")
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
    print(f"  -> Top 3 SHAP Drivers for Recharts Waterfall:")
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

    print("\n==========================================================")
    print("  ALL TESTS PASSED: Scikit-learn + SHAP Engine Verified!   ")
    print("==========================================================")


if __name__ == "__main__":
    run_tests()
