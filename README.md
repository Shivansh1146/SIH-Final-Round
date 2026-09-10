# 🌿 SAHAYAK—AI (सहायक)
> **Cognitive & Memory Support Companion for Elderly Dementia Patients, Family Caregivers, and Clinicians**
> 
> *Offline-First · Multilingual · On-Device Ollama LLM Companion · ML Biomarker Analysis & SHAP Explainability · Active Kinematic ESP32 Stabilization*

---

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.24.5-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter"/>
  <img src="https://img.shields.io/badge/FastAPI-0.109.0-009688?style=for-the-badge&logo=fastapi&logoColor=white" alt="FastAPI"/>
  <img src="https://img.shields.io/badge/Ollama-Gemma_2B_LLM-000000?style=for-the-badge&logo=ollama&logoColor=white" alt="Ollama"/>
  <img src="https://img.shields.io/badge/SQLite3-Persistence-003B57?style=for-the-badge&logo=sqlite&logoColor=white" alt="SQLite"/>
  <img src="https://img.shields.io/badge/ESP32-FreeRTOS-000000?style=for-the-badge&logo=espressif&logoColor=white" alt="ESP32"/>
  <img src="https://img.shields.io/badge/SHAP-Explainable_AI-FF6F00?style=for-the-badge&logo=scikit-learn&logoColor=white" alt="SHAP"/>
  <img src="https://img.shields.io/badge/Licence-MIT-green?style=for-the-badge" alt="License"/>
</p>

---

## 📌 Executive Summary

**SAHAYAK—AI** is a holistic ecosystem built to bridge the gap between elderly dementia patients, family caregivers, and clinical neurologists across India. Featuring **on-device neural conversational AI (Ollama + Gemma 2B)**, **offline-first local persistence**, adaptive difficulty scaling, real-time kinematic tremor stabilization, and explainable ML risk assessments, SAHAYAK—AI delivers compassionate care tailored to multi-generational accessibility.

---

## 🏛️ System Architecture

```mermaid
graph TD
    subgraph Edge Hardware & Sensors
        HW[ESP32 Smart Utensil] -->|100Hz MPU6050 IMU / BLE GATT| APP[Sahayak Mobile & Web App]
    end

    subgraph Client & On-Device AI
        APP -->|Local Patient Exercises & Hive Store| DB[(Local Hive & SQLite Cache)]
        APP -->|Talk to me: Offline Chatbot| OLLAMA[Local Ollama / Gemma 2B Neural LLM]
        APP -->|Clinical Sync| API[FastAPI Clinical Backend]
    end

    subgraph Backend Core Engine
        API -->|Local SQLite Storage| SQL[(shayak.db)]
        API -->|Companion Service| CS[Reminiscence & Validation Engine]
        API -->|Sub-50ms Ensemble ML| ML[Calibrated Random Forest]
        ML -->|TreeExplainer Attribution| SHAP[SHAP Explainability Engine]
    end

    subgraph Role Workspaces
        APP --> P[Patient Workspace: Calming Exercises, Reminders & AI Companion]
        APP --> C[Caregiver Workspace: Telemetry & Doctor Appointments]
        APP --> D[Doctor Portal: Directives, Medical Notes & SHAP Reports]
    end
```

---

## ✨ Key Features & Tri-Role Design System

### 🧑‍🦳 1. Patient Workspace (Serene Sage & Calming Visuals)
* **On-Device Real-Time AI Companion ("Talk to me")**:
  * **Neural Conversation**: Powered locally via Ollama and Gemma 2B LLM.
  * **Validation & Reminiscence Therapy**: Validates emotions without reality-checking or argument.
  * **Audio Read-Aloud (TTS)**: One-tap voice playback for all conversational responses.
  * **Zero External API Dependency**: Runs completely offline.
* **Gentle Cognitive Exercises**:
  * **Clock Drawing Test (CDT)**: Canvas capturing stroke kinematics and hesitation.
  * **Memory Match & Story Recall**: Working memory games with adaptive difficulty.
  * **Spot the Difference & Local Language Naming**: Culturally familiar multi-lingual prompts.
* **Routine & Reminders**: High-contrast, large-touch target checklist with voice audio read-aloud.

### 👥 2. Caregiver Dashboard (Mint & Warm Terracotta)
* **Clinical Appointment Booking**: Direct scheduling with specialty choice, format (In-Person / Telehealth), preferred date, time slots, and symptom notes.
* **Live Telemetry & Motor Trends**: Virtual 3D attitude indicator (Roll, Pitch, Yaw), vertical acceleration ($a_z$), and 20 kHz PWM counter-thrust active stabilization monitoring.
* **Doctor Directive Sync**: Instant access to doctor prescriptions, medical feedback, and care plans.

### 🩺 3. Doctor Portal (Clinical Blue)
* **Patient Selection & Medical History**: Longitudinal tracking with persistent doctor notes.
* **Prescribe Directives & Adaptive Difficulty**: Set custom action items (e.g., daily 15-min Memory Story, hydration targets) and lock cognitive difficulty levels.
* **ML Risk Evaluation & SHAP Analysis**: Sub-50ms diagnostic classification with SHAP feature attribution waterfall.

---

## 🎨 Visual System & Tokens

* **Primary Forest Green**: `#124E3C` *(Headings, primary CTAs, active indicators)*
* **Primary Dark**: `#12302A` *(Hover and active states)*
* **Accent Orange**: `#D87236` *(Hero highlights, used sparingly)*
* **Page Background**: `#F0F6F0` *(Soft mint-white)*
* **Card Surface**: `#FCFCFC` *(Clean elevated surfaces)*
* **Clinical Accent (Doctor)**: Text `#184ED8` on `#BAD8FC` chip

---

## 📁 Repository Structure

```
SIH-main/
├── backend/                        # FastAPI Backend & ML Pipeline
│   ├── app/
│   │   ├── main.py                 # REST API Endpoints & FastAPI App
│   │   ├── companion_service.py    # Offline Ollama + Gemma Conversational AI & Validation Engine
│   │   ├── db.py                   # SQLite Schema, Repositories & Seeding
│   │   └── ml_engine.py            # Scikit-Learn ML Model & SHAP Explainability
│   ├── shayak.db                   # SQLite Persistent Database
│   └── requirements.txt            # Python Dependencies
├── shayak_mobile/                  # Cross-Platform Flutter Frontend
│   ├── lib/
│   │   ├── models/                 # Data Models & Persistence (Patient, Feedback, Appointments)
│   │   ├── screens/                # Patient, Caregiver, Doctor & Registration Screens
│   │   ├── services/               # API Config, Companion Service, Database & Audio Narration
│   │   ├── theme/                  # Design Tokens & Typography System
│   │   └── widgets/                # Companion Modal, Top Bar, Sidebar, Cards & Action Components
│   └── pubspec.yaml                # Flutter Dependencies
└── firmware/                       # Hardware Firmware
    └── esp32_stabilization/        # Dual-Core FreeRTOS MPU6050 Stabilization Firmware
```

---

## ⚡ Quick Start Guide

### 1. 🐍 Backend API (FastAPI + SQLite + Ollama)
```bash
# Navigate to backend
cd backend

# Install dependencies
pip install -r requirements.txt

# Start FastAPI server
python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```
* **Interactive API Docs (Swagger UI)**: Open `http://localhost:8000/docs`

### 2. 🤖 Offline Local LLM (Ollama + Gemma)
```bash
# Start Ollama service
ollama serve

# Pull local Gemma LLM model
ollama pull gemma2:2b
```

### 3. 📱 Mobile & Web App (Flutter)
```bash
# Navigate to mobile app
cd shayak_mobile

# Install packages
flutter pub get

# Run on Web (Chrome)
flutter run -d chrome

# Build Debug APK for Android Phone
flutter build apk --debug --android-skip-build-dependency-validation

# Install directly on Connected Android Device via USB Debugging
flutter run -d <device_id>
```

---

## 🔄 Recent Updates

| Date | Change |
|------|--------|
| Sep 2026 | ✅ Implemented **Instant On-Device Validation Therapy Engine** (`companion_service.dart`) with zero timeout failure; provides immediate empathetic conversational replies both online and 100% offline |
| Sep 2026 | ✅ Added **Local Wi-Fi Network Resolution** (`192.168.29.29:8000` + ADB reverse `127.0.0.1:8000`) enabling seamless mobile app access to backend over Wi-Fi without USB cables |
| Sep 2026 | ✅ Resolved Flutter compilation errors: updated `CardThemeData` in `app_theme.dart`, promoted box variable before awaits in `app_sidebar.dart`, and upgraded `google_fonts` to `^8.2.1` |
| Sep 2026 | ✅ Built and packaged standalone debug APK (`SAHAYAK_AI.apk`) with NDK 25.1, Android SDK Platform 36, and CMake 3.22 |
| Sep 2026 | ✅ Fixed **100% of RenderFlex yellow overflow spots** across all mobile screens (`companion_modal.dart`, `patient_home_screen.dart`, `doctor_dashboard_screen.dart`, `caregiver_workspace_screen.dart`, `patient_progress_dashboard.dart`) |
| Sep 2026 | ✅ Enabled `android:usesCleartextTraffic="true"` and added **Dual-IP Fallback** (`127.0.0.1` + local Wi-Fi) for instant mobile-to-LLM communication |
| Sep 2026 | ✅ Bound FastAPI Uvicorn backend to `0.0.0.0:8000` to serve both USB ADB bridge and Wi-Fi network requests |
| Sep 2026 | ✅ Installed and launched native Android app on physical device (`f6c6031d`) via USB Debugging |
| Sep 2026 | ✅ Integrated live **Ollama + Gemma 2B LLM** real-time neural conversational companion ("Talk to me") with audio narration |
| Sep 2026 | ✅ Implemented real-time multi-turn chat UI with text-to-speech voice playback in `companion_modal.dart` |
| Sep 2026 | ✅ Bypassed service worker caching to guarantee immediate UI updates on web |
| Sep 2026 | ✅ Restored original **Landing Screen** design ("Support for memory. Made human.") |

---

## 📄 License

Distributed under the **MIT License**. See `LICENSE` for details.

