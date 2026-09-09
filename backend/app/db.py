"""
SHAYAK-AI: SQLite Database Engine & Repository
Manages local SQLite database (shayak.db) for patients, appointments,
clinical feedback, game sessions, difficulty tiers, and kinematic telemetry.
"""

import sqlite3
import json
from pathlib import Path
from datetime import datetime, timezone

DB_PATH = Path(__file__).resolve().parent.parent / "shayak.db"


def get_connection() -> sqlite3.Connection:
    """Returns a SQLite connection with row factory enabled."""
    conn = sqlite3.connect(str(DB_PATH), check_same_thread=False)
    conn.row_factory = sqlite3.Row
    return conn


def init_db():
    """Initializes tables and seeds baseline clinical records."""
    conn = get_connection()
    cursor = conn.cursor()

    # 1. Patients table
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS patients (
            id TEXT PRIMARY KEY,
            full_name TEXT NOT NULL,
            age INTEGER NOT NULL,
            gender TEXT NOT NULL,
            city TEXT,
            diagnosis TEXT,
            preferred_language TEXT DEFAULT 'english',
            caregiver_name TEXT,
            caregiver_phone TEXT,
            caregiver_relation TEXT,
            medical_notes TEXT,
            link_code TEXT,
            registered_at TEXT
        )
    """)

    # 2. Patient difficulty state
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS difficulty_settings (
            patient_id TEXT PRIMARY KEY,
            difficulty_level TEXT NOT NULL,
            is_adaptive INTEGER NOT NULL DEFAULT 1,
            last_updated TEXT,
            caregiver_override INTEGER DEFAULT 0
        )
    """)

    # 3. Appointments table
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS appointments (
            id TEXT PRIMARY KEY,
            patient_id TEXT NOT NULL,
            patient_name TEXT NOT NULL,
            doctor_name TEXT NOT NULL,
            clinic_or_hospital TEXT NOT NULL,
            appointment_type TEXT NOT NULL,
            scheduled_date TEXT NOT NULL,
            time_slot TEXT NOT NULL,
            caregiver_name TEXT,
            caregiver_phone TEXT,
            reason_for_visit TEXT,
            status TEXT DEFAULT 'Confirmed',
            doctor_feedback_for_caregiver TEXT,
            booked_at TEXT
        )
    """)

    # 4. Clinical feedback & directives table
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS clinical_feedback (
            id TEXT PRIMARY KEY,
            patient_id TEXT NOT NULL,
            doctor_name TEXT NOT NULL,
            hospital_or_clinic TEXT NOT NULL,
            specialty TEXT,
            clinical_impression TEXT,
            feedback_notes TEXT,
            prescribed_directives TEXT, -- JSON array of strings
            recommended_difficulty TEXT,
            submitted_at TEXT
        )
    """)

    # 5. Patient game sessions table
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS patient_sessions (
            session_id TEXT PRIMARY KEY,
            patient_id TEXT NOT NULL,
            game_type TEXT NOT NULL,
            score REAL NOT NULL,
            response_latency_sec REAL,
            hesitations_count INTEGER DEFAULT 0,
            tremor_variance REAL DEFAULT 0.0,
            difficulty_level TEXT,
            is_adaptive INTEGER DEFAULT 1,
            completed_at TEXT
        )
    """)

    # 6. Kinematic telemetry log table
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS kinematic_telemetry (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            device_id TEXT NOT NULL,
            patient_id TEXT NOT NULL,
            vertical_accel_ms2 REAL,
            tremor_variance REAL,
            thrust_pwm_z INTEGER,
            timestamp_ms INTEGER,
            server_time TEXT
        )
    """)

    conn.commit()

    # Seed baseline data if empty
    _seed_initial_data(cursor, conn)
    conn.close()


def _seed_initial_data(cursor: sqlite3.Cursor, conn: sqlite3.Connection):
    """Seeds realistic default clinical demo data if database is fresh."""
    now_iso = datetime.now(timezone.utc).isoformat()

    # Seed patients
    cursor.execute("SELECT COUNT(*) FROM patients")
    if cursor.fetchone()[0] == 0:
        patients = [
            (
                "patient-ramesh", "Ramesh Kumar", 68, "male", "Guwahati, Assam",
                "Mild Cognitive Impairment (MCI) & Parkinsonian Resting Tremor",
                "english", "Anita Kumar", "+91 98450 12345", "Daughter",
                "Patient experiences morning executive hesitation and resting tremor in dominant hand. Prescribed Donepezil 5mg with daily Memory Match & Clock Drawing cadence.",
                "SAH-9042-RAM", now_iso
            ),
            (
                "patient-monalisa", "Monalisa Barua", 65, "female", "Jorhat, Assam",
                "Early-Stage Alzheimer's & Procedural Sequence Hesitation",
                "assamese", "Pranab Barua", "+91 94350 12345", "Son",
                "Memory Lane reminiscence therapy and chai-making sequencer show strong emotional grounding and autobiographical recall.",
                "SAH-4819-MONA", now_iso
            ),
            (
                "patient-tenzin", "Tenzin Dorjee", 72, "male", "Tawang, Arunachal Pradesh",
                "Postural & Kinematic Stability Monitoring",
                "english", "Pema Dorjee", "+91 98620 12345", "Spouse",
                "Postural tremors stabilized with adaptive utensil. Gait evaluation shows slight bradykinesia. Recommend daily balance and visual search drills.",
                "SAH-7631-TENZ", now_iso
            ),
        ]
        cursor.executemany("""
            INSERT INTO patients (
                id, full_name, age, gender, city, diagnosis, preferred_language,
                caregiver_name, caregiver_phone, caregiver_relation, medical_notes, link_code, registered_at
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, patients)

    # Seed difficulty settings
    cursor.execute("SELECT COUNT(*) FROM difficulty_settings")
    if cursor.fetchone()[0] == 0:
        difficulties = [
            ("patient-ramesh", "Level 2 (Moderate)", 1, now_iso, 0),
            ("PT-9042", "Level 2 (Moderate)", 1, now_iso, 0),
            ("patient-monalisa", "Level 1 (Gentle)", 1, now_iso, 0),
            ("patient-tenzin", "Level 2 (Moderate)", 1, now_iso, 0),
        ]
        cursor.executemany("""
            INSERT INTO difficulty_settings (patient_id, difficulty_level, is_adaptive, last_updated, caregiver_override)
            VALUES (?, ?, ?, ?, ?)
        """, difficulties)

    # Seed appointments
    cursor.execute("SELECT COUNT(*) FROM appointments")
    if cursor.fetchone()[0] == 0:
        apts = [
            (
                "apt-1", "patient-ramesh", "Ramesh Kumar", "Dr. Debabrata Goswami, DM",
                "Assam Medical College & Hospital", "In-Person Neuro Consultation",
                "2026-09-12T11:00:00Z", "11:00 AM", "Anita Kumar", "+91 98450 12345",
                "Bi-monthly cognitive progression review and ESP32 kinematic utensil stability check.",
                "Confirmed",
                "Confirmed for 11:00 AM. Please bring the ESP32 utensil usage logs and ensure Ramesh had a light breakfast.",
                now_iso
            ),
            (
                "apt-2", "patient-monalisa", "Monalisa Barua", "Dr. Priya Sengupta, MD",
                "Guwahati Neurological Institute", "Telehealth Video Review",
                "2026-09-14T14:30:00Z", "02:30 PM", "Pranab Barua", "+91 94350 12345",
                "Follow-up on morning routine orientation and Memory Lane recall progress.",
                "Confirmed", None, now_iso
            ),
            (
                "apt-3", "patient-tenzin", "Tenzin Dorjee", "Dr. Tashi Norbu, MD",
                "Arunachal Neuro-Geriatric Institute", "Kinematic Tremor & Gait Review",
                "2026-09-13T10:00:00Z", "10:00 AM", "Pema Dorjee", "+91 98620 12345",
                "Kinematic bio-feedback sensor calibration and postural stability follow-up.",
                "Confirmed",
                "Confirmed for 10:00 AM. Please bring the smart utensil sensor log and recent gait notes.",
                now_iso
            ),
        ]
        cursor.executemany("""
            INSERT INTO appointments (
                id, patient_id, patient_name, doctor_name, clinic_or_hospital, appointment_type,
                scheduled_date, time_slot, caregiver_name, caregiver_phone, reason_for_visit,
                status, doctor_feedback_for_caregiver, booked_at
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, apts)

    # Seed clinical feedback
    cursor.execute("SELECT COUNT(*) FROM clinical_feedback")
    if cursor.fetchone()[0] == 0:
        feedback = [
            (
                "df-1", "patient-ramesh", "Dr. Debabrata Goswami, DM", "Assam Medical College & Hospital",
                "Cognitive Neurology & Movement Disorders", "Stable & Responsive to Routine",
                "Patient exhibits consistent engagement with memory recall games (average accuracy above 78%). Kinematic tremor variance has remained well stabilized with the ESP32 active utensil. Recommend maintaining the current cognitive exercise cadence.",
                json.dumps([
                    "Maintain daily 15-minute Memory Match and Memory Story sessions.",
                    "Keep ESP32 utensil sensor calibrated before meal times.",
                    "Continue Donepezil 5mg once daily after breakfast.",
                    "Schedule follow-up review in 8 weeks.",
                ]),
                "Level 2 (Moderate)", now_iso
            ),
            (
                "df-2", "patient-monalisa", "Dr. Priya Sengupta, MD", "Guwahati Neurological Institute",
                "Geriatric Psychiatry", "Mild Attentional Fluctuations",
                "Mild procedural sequence hesitations observed in morning routines. Reminiscence therapy (Memory Lane) shows strong emotional grounding and positive autobiographical speech recall.",
                json.dumps([
                    "Prioritize Memory Lane and Local Language Naming games in the morning hours.",
                    "Ensure caregiver assistance during complex procedural sequences.",
                    "Hydration check: at least 1.8 liters daily.",
                ]),
                "Level 1 (Gentle)", now_iso
            ),
            (
                "df-3", "patient-tenzin", "Dr. Tashi Norbu, MD", "Arunachal Neuro-Geriatric Institute",
                "Neuro-Geriatrics", "Satisfactory Motor Compensation",
                "Kinematic IMU readings indicate the active thrust loop effectively attenuates tremor amplitudes by ~62%. Patient maintains positive engagement with clock drawing tasks.",
                json.dumps([
                    "Recharge ESP32 utensil battery nightly.",
                    "Continue gentle daily motor-visual tracking exercises.",
                    "Review video consultation in 4 weeks.",
                ]),
                "Level 2 (Moderate)", now_iso
            ),
        ]
        cursor.executemany("""
            INSERT INTO clinical_feedback (
                id, patient_id, doctor_name, hospital_or_clinic, specialty, clinical_impression,
                feedback_notes, prescribed_directives, recommended_difficulty, submitted_at
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, feedback)

    # Seed initial sessions for ramesh, monalisa, tenzin
    cursor.execute("SELECT COUNT(*) FROM patient_sessions")
    if cursor.fetchone()[0] == 0:
        sessions = [
            ("sess-1", "patient-ramesh", "memory_match", 78.0, 2.4, 2, 11.2, "Level 2 (Moderate)", 1, now_iso),
            ("sess-2", "patient-ramesh", "clock_drawing", 82.0, 3.1, 1, 10.5, "Level 2 (Moderate)", 1, now_iso),
            ("sess-3", "patient-ramesh", "memory_match", 85.0, 2.1, 1, 9.8, "Level 2 (Moderate)", 1, now_iso),
            ("sess-4", "patient-monalisa", "memory_story", 75.0, 3.2, 4, 14.1, "Level 1 (Gentle)", 1, now_iso),
            ("sess-5", "patient-tenzin", "clock_drawing", 80.0, 2.2, 2, 12.0, "Level 2 (Moderate)", 1, now_iso),
        ]
        cursor.executemany("""
            INSERT INTO patient_sessions (
                session_id, patient_id, game_type, score, response_latency_sec,
                hesitations_count, tremor_variance, difficulty_level, is_adaptive, completed_at
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, sessions)

    conn.commit()


# Repository functions
def get_all_appointments(patient_id: str | None = None) -> list[dict]:
    conn = get_connection()
    cursor = conn.cursor()
    if patient_id:
        # Match both patient_id and generic alias
        alias = "patient-ramesh" if patient_id == "PT-9042" else patient_id
        cursor.execute("SELECT * FROM appointments WHERE patient_id = ? OR patient_id = ? ORDER BY scheduled_date ASC", (patient_id, alias))
    else:
        cursor.execute("SELECT * FROM appointments ORDER BY scheduled_date ASC")
    rows = cursor.fetchall()
    conn.close()
    return [dict(row) for row in rows]


def insert_appointment(apt_data: dict) -> dict:
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute("""
        INSERT INTO appointments (
            id, patient_id, patient_name, doctor_name, clinic_or_hospital, appointment_type,
            scheduled_date, time_slot, caregiver_name, caregiver_phone, reason_for_visit,
            status, doctor_feedback_for_caregiver, booked_at
        ) VALUES (:id, :patient_id, :patient_name, :doctor_name, :clinic_or_hospital, :appointment_type,
                  :scheduled_date, :time_slot, :caregiver_name, :caregiver_phone, :reason_for_visit,
                  :status, :doctor_feedback_for_caregiver, :booked_at)
    """, apt_data)
    conn.commit()
    conn.close()
    return apt_data


def update_appointment_feedback(appointment_id: str, feedback: str, new_status: str) -> dict | None:
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute("""
        UPDATE appointments
        SET doctor_feedback_for_caregiver = ?, status = ?
        WHERE id = ?
    """, (feedback, new_status, appointment_id))
    conn.commit()
    cursor.execute("SELECT * FROM appointments WHERE id = ?", (appointment_id,))
    row = cursor.fetchone()
    conn.close()
    return dict(row) if row else None


def get_clinical_feedback(patient_id: str | None = None) -> list[dict]:
    conn = get_connection()
    cursor = conn.cursor()
    if patient_id:
        alias = "patient-ramesh" if patient_id == "PT-9042" else patient_id
        cursor.execute("SELECT * FROM clinical_feedback WHERE patient_id = ? OR patient_id = ? ORDER BY submitted_at DESC", (patient_id, alias))
    else:
        cursor.execute("SELECT * FROM clinical_feedback ORDER BY submitted_at DESC")
    rows = cursor.fetchall()
    conn.close()
    result = []
    for r in rows:
        d = dict(r)
        if isinstance(d.get("prescribed_directives"), str):
            try:
                d["prescribed_directives"] = json.loads(d["prescribed_directives"])
            except Exception:
                d["prescribed_directives"] = []
        result.append(d)
    return result


def insert_clinical_feedback(feedback_data: dict) -> dict:
    conn = get_connection()
    cursor = conn.cursor()
    data = dict(feedback_data)
    if isinstance(data.get("prescribed_directives"), list):
        data["prescribed_directives"] = json.dumps(data["prescribed_directives"])
    cursor.execute("""
        INSERT INTO clinical_feedback (
            id, patient_id, doctor_name, hospital_or_clinic, specialty, clinical_impression,
            feedback_notes, prescribed_directives, recommended_difficulty, submitted_at
        ) VALUES (:id, :patient_id, :doctor_name, :hospital_or_clinic, :specialty, :clinical_impression,
                  :feedback_notes, :prescribed_directives, :recommended_difficulty, :submitted_at)
    """, data)
    conn.commit()
    conn.close()
    if isinstance(data.get("prescribed_directives"), str):
        data["prescribed_directives"] = json.loads(data["prescribed_directives"])
    return data


def get_difficulty(patient_id: str) -> dict:
    conn = get_connection()
    cursor = conn.cursor()
    alias = "patient-ramesh" if patient_id == "PT-9042" else patient_id
    cursor.execute("SELECT * FROM difficulty_settings WHERE patient_id = ? OR patient_id = ?", (patient_id, alias))
    row = cursor.fetchone()
    conn.close()
    if row:
        d = dict(row)
        d["is_adaptive"] = bool(d["is_adaptive"])
        return d
    return {
        "difficulty_level": "Level 2 (Moderate)",
        "is_adaptive": True,
        "last_updated": datetime.now(timezone.utc).isoformat(),
        "caregiver_override": 0,
    }


def set_difficulty(patient_id: str, difficulty_level: str, is_adaptive: bool, caregiver_override: bool = False):
    conn = get_connection()
    cursor = conn.cursor()
    now_iso = datetime.now(timezone.utc).isoformat()
    cursor.execute("""
        INSERT INTO difficulty_settings (patient_id, difficulty_level, is_adaptive, last_updated, caregiver_override)
        VALUES (?, ?, ?, ?, ?)
        ON CONFLICT(patient_id) DO UPDATE SET
            difficulty_level = excluded.difficulty_level,
            is_adaptive = excluded.is_adaptive,
            last_updated = excluded.last_updated,
            caregiver_override = excluded.caregiver_override
    """, (patient_id, difficulty_level, 1 if is_adaptive else 0, now_iso, 1 if caregiver_override else 0))
    conn.commit()
    conn.close()


def insert_session(session_dict: dict):
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute("""
        INSERT INTO patient_sessions (
            session_id, patient_id, game_type, score, response_latency_sec,
            hesitations_count, tremor_variance, difficulty_level, is_adaptive, completed_at
        ) VALUES (:session_id, :patient_id, :game_type, :score, :response_latency_sec,
                  :hesitations_count, :tremor_variance, :difficulty_level, :is_adaptive, :completed_at)
    """, {
        "session_id": session_dict.get("session_id"),
        "patient_id": session_dict.get("patient_id"),
        "game_type": session_dict.get("game_type", "memory_match"),
        "score": session_dict.get("score", 75.0),
        "response_latency_sec": session_dict.get("response_latency_sec", 2.5),
        "hesitations_count": session_dict.get("hesitations_count", 0),
        "tremor_variance": session_dict.get("tremor_variance", 0.0),
        "difficulty_level": session_dict.get("difficulty_level", "Level 2 (Moderate)"),
        "is_adaptive": 1 if session_dict.get("is_adaptive", True) else 0,
        "completed_at": session_dict.get("timestamp", datetime.now(timezone.utc).isoformat()),
    })
    conn.commit()
    conn.close()


def get_patient_sessions(patient_id: str) -> list[dict]:
    conn = get_connection()
    cursor = conn.cursor()
    alias = "patient-ramesh" if patient_id == "PT-9042" else patient_id
    cursor.execute("SELECT * FROM patient_sessions WHERE patient_id = ? OR patient_id = ? ORDER BY completed_at DESC", (patient_id, alias))
    rows = cursor.fetchall()
    conn.close()
    return [dict(r) for r in rows]


def update_patient_notes(patient_id: str, medical_notes: str) -> bool:
    conn = get_connection()
    cursor = conn.cursor()
    alias = "patient-ramesh" if patient_id == "PT-9042" else patient_id
    cursor.execute("UPDATE patients SET medical_notes = ? WHERE id = ? OR id = ?", (medical_notes, patient_id, alias))
    updated = cursor.rowcount > 0
    conn.commit()
    conn.close()
    return updated


def get_patient_profile(patient_id: str) -> dict | None:
    conn = get_connection()
    cursor = conn.cursor()
    alias = "patient-ramesh" if patient_id == "PT-9042" else patient_id
    cursor.execute("SELECT * FROM patients WHERE id = ? OR id = ?", (patient_id, alias))
    row = cursor.fetchone()
    conn.close()
    return dict(row) if row else None


def get_all_patients() -> list[dict]:
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM patients ORDER BY full_name ASC")
    rows = cursor.fetchall()
    conn.close()
    return [dict(r) for r in rows]
