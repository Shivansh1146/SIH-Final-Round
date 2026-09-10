"""
SAHAYAK-AI Offline Conversational Companion - Full Knowledge Engine.
Covers: Dementia clinical knowledge, project roles (Patient/Caregiver/Doctor),
NER context, medications, caregiving tips, cognitive games, ESP32 hardware.
Runs locally via Ollama + Gemma with 100% offline on-device fallback.
"""

import os
import re
import json
import random
import logging
from pathlib import Path
from typing import Optional, List, Dict
import httpx
from pydantic import BaseModel, Field

REVIEW_LOG_DIR = Path(__file__).resolve().parent.parent / "logs"
REVIEW_LOG_DIR.mkdir(parents=True, exist_ok=True)
REVIEW_LOG_PATH = REVIEW_LOG_DIR / "companion_review.log"

logger = logging.getLogger("sahayak_companion")

OLLAMA_HOST = os.environ.get("OLLAMA_HOST", "http://localhost:11434")
OLLAMA_MODEL = os.environ.get("OLLAMA_MODEL", "gemma2:2b")

COMPANION_SYSTEM_PROMPT = (
    "You are SAHAYAK-AI (sahayak), a culturally compassionate, medically knowledgeable AI companion "
    "built for the Smart India Hackathon (SIH) under: AI-Based Cognitive Gaming and Memory Assistance "
    "Platform for Elderly Dementia Patients in North Eastern Region (NER).\n\n"
    "DEMENTIA: Alzheimer's most common type (60-80%). India has 8.8 million patients. "
    "NER has 200,000+ undiagnosed cases.\n"
    "7 STAGES: Stage1-No Impairment. Stage2-Very Mild Decline. Stage3-MCI (SAHAYAK early target). "
    "Stage4-Mild Dementia. Stage5-Moderate. Stage6-Moderately Severe. Stage7-Severe full-time care.\n"
    "TYPES: Alzheimers, Vascular, Lewy Body, Frontotemporal, Mixed, Parkinsons Dementia.\n"
    "10 WARNING SIGNS: Memory loss, planning challenges, familiar task difficulty, time/place confusion, "
    "visual problems, word-finding issues, misplacing items, poor judgment, social withdrawal, mood changes.\n"
    "DIAGNOSIS: MMSE, MoCA, CDT Clock Drawing (AI stroke kinematics in SAHAYAK), MRI, PET, SHAP ML.\n"
    "MEDICATIONS: Donepezil all stages. Rivastigmine stages 1-6. Galantamine stages 1-6. "
    "Memantine stages 4-7. Lecanemab 2023 FDA. No cure but treatments slow progression.\n"
    "THERAPIES: Reminiscence, Cognitive Stimulation Games, Validation Therapy, Music Therapy.\n"
    "PREVENTION: Modifiable risks: hypertension, diabetes, obesity, smoking, isolation, poor sleep. "
    "40% of global dementia is preventable.\n"
    "CAREGIVER TIPS: Simple sentences, consistent routine, label items, validate not argue, "
    "7-8 hours sleep, safe environment, prevent burnout. ARDSI helpline 1800-120-3474.\n"
    "DOCTOR FEATURES: Clinical Dashboard, SHAP reports, Random Forest classification Normal/MCI/Moderate/Severe, "
    "remote assessment, treatment notes, telemedicine.\n"
    "PATIENT FEATURES: CDT game, Memory Match, Story Recall, Spot Difference, Companion chat, "
    "Daily Reminders voice readout, Memory Book, Progress Tracker, ESP32 tremor utensils.\n"
    "CAREGIVER FEATURES: Patient Dashboard, Medication Reminders, Memory Book, Low-score Alerts, Doctor chat.\n"
    "NER: Assam Meghalaya Manipur Mizoram Nagaland Tripura Arunachal Pradesh Sikkim. "
    "Languages: Assamese Bodo Meitei Khasi Mizo Nagamese Bengali Hindi. "
    "Less than 10 neurologists per million people. Offline APK at PHCs and ANM sub-centers.\n"
    "TECH: Flutter Android+Web. FastAPI+SQLite backend. Ollama Gemma2B local AI. "
    "Random Forest+SHAP ML. ESP32+MPU6050 IMU 100Hz 20kHz PWM tremor. "
    "GitHub: https://github.com/Shivansh1146/SIH-Final-Round\n"
    "CULTURE: Bihu, Rongali, Brahmaputra, tea gardens, bamboo courtyards, pitha sweets, "
    "Loktak Lake, Dzukou Valley, Hornbill festival.\n"
    "RULES: Never argue or contradict. Validate all feelings warmly. "
    "Give complete structured answers for knowledge queries. "
    "Give gentle 2-4 sentence replies for emotional support."
)

DISALLOWED_TERMS = [
    "you are going to die",
    "you have terminal",
    "kill yourself",
    "suicide",
]

CORRECTION_PATTERNS = [
    r"\byou are stupid\b",
    r"\byou are crazy\b",
]

_conversation_memory: Dict[str, List[Dict[str, str]]] = {}


class CompanionChatRequest(BaseModel):
    patientId: str = Field(..., description="Patient Identifier", example="PT-9042")
    message: Optional[str] = Field(None, description="Text message from patient or transcript")
    audioBase64: Optional[str] = Field(None, description="Native audio input base64 encoded")
    conversationId: str = Field(..., description="Unique ID for conversation session")


class CompanionChatResponse(BaseModel):
    text: str
    audioUrl: Optional[str] = None
    available: bool = True


class CompanionStatusResponse(BaseModel):
    available: bool
    model: str
    ollama_host: str


def log_rejected_response(conversation_id: str, raw_output: str, reason: str):
    try:
        entry = {"conversation_id": conversation_id, "reason": reason, "raw_output": raw_output}
        with open(REVIEW_LOG_PATH, "a", encoding="utf-8") as f:
            f.write(json.dumps(entry) + "\n")
    except Exception as e:
        logger.error(f"Failed to log rejected response: {e}")


def passes_safety_filter(text: str):
    if not text or not text.strip():
        return False, "Empty output"
    lower = text.lower()
    for term in DISALLOWED_TERMS:
        if term in lower:
            return False, f"Contains restricted term: {term}"
    for pat in CORRECTION_PATTERNS:
        if re.search(pat, lower):
            return False, f"Contains correction pattern: {pat}"
    return True, "Passed"


async def check_ollama_availability() -> bool:
    try:
        async with httpx.AsyncClient(timeout=1.0) as client:
            res = await client.get(f"{OLLAMA_HOST}/api/tags")
            return res.status_code == 200
    except Exception:
        return False


def get_rolling_history(conversation_id: str) -> List[Dict[str, str]]:
    return _conversation_memory.get(conversation_id, [])


def append_to_history(conversation_id: str, user_text: str, assistant_text: str):
    history = _conversation_memory.setdefault(conversation_id, [])
    history.append({"role": "user", "content": user_text})
    history.append({"role": "assistant", "content": assistant_text})
    if len(history) > 8:
        _conversation_memory[conversation_id] = history[-8:]


async def call_ollama_generate(messages: List[Dict[str, str]]) -> Optional[str]:
    try:
        async with httpx.AsyncClient(timeout=12.0) as client:
            model_to_use = OLLAMA_MODEL
            try:
                tags_res = await client.get(f"{OLLAMA_HOST}/api/tags")
                if tags_res.status_code == 200:
                    models = [m.get("name", "") for m in tags_res.json().get("models", [])]
                    if models:
                        gemma_match = next((m for m in models if "gemma" in m), models[0])
                        model_to_use = gemma_match
            except Exception:
                pass
            payload = {
                "model": model_to_use,
                "messages": messages,
                "stream": False,
                "options": {"temperature": 0.65, "top_p": 0.9, "num_predict": 220},
            }
            res = await client.post(f"{OLLAMA_HOST}/api/chat", json=payload)
            if res.status_code == 200:
                return res.json().get("message", {}).get("content", "").strip()
            return None
    except Exception as e:
        logger.warning(f"Ollama call failed: {e}")
        return None


def generate_contextual_validation_reply(user_message: str) -> str:
    """100% offline on-device knowledge engine covering all dementia and project topics."""
    msg = user_message.lower().strip()

    # GREETINGS
    if any(k in msg for k in ["hello", "hi", "namaste", "good morning", "good evening", "start", "greet", "hey"]):
        opts = [
            "Namaste! I am SAHAYAK-AI, your compassionate companion. I know everything about dementia "
            "care, the SAHAYAK-AI project, patient/caregiver/doctor roles, medications, cognitive games, "
            "and NER context. How can I help you today?",
            "Hello! You can ask me anything — dementia stages, symptoms, medications, caregiving tips, "
            "project features, or just share a memory. I am always here for you!",
            "Namaste! Welcome to SAHAYAK-AI. What would you like to know about dementia or our project?",
        ]
        return random.choice(opts)

    # PROJECT IDENTITY
    if any(k in msg for k in ["who are you", "what are you", "sahayak", "sih", "hackathon",
                               "problem statement", "about project", "what is this app", "about you"]):
        opts = [
            "I am SAHAYAK-AI built for Smart India Hackathon — 'AI-Based Cognitive Gaming and Memory "
            "Assistance Platform for Elderly Dementia Patients in NER.' I serve Patients with cognitive "
            "games, Caregivers with monitoring dashboards, and Doctors with SHAP-explainable ML diagnostics. "
            "Fully offline-first!",
            "SAHAYAK-AI is a comprehensive dementia care platform for North East India (Assam, Meghalaya, "
            "Manipur, Mizoram, Nagaland, Tripura, Arunachal Pradesh, Sikkim). Features include Clock "
            "Drawing AI, Memory Match, ESP32 tremor stabilization, FastAPI backend, Random Forest + SHAP.",
            "Our SIH platform addresses the critical shortage of dementia care in NER. Offline APK "
            "deployable at Primary Health Centers. GitHub: https://github.com/Shivansh1146/SIH-Final-Round",
        ]
        return random.choice(opts)

    # WHAT IS DEMENTIA
    if any(k in msg for k in ["what is dementia", "dementia kya", "dementia meaning",
                               "define dementia", "explain dementia", "about dementia"]):
        return (
            "Dementia is NOT normal aging. It is an umbrella term for symptoms affecting memory, "
            "thinking, and daily functioning severely enough to interfere with life. "
            "Alzheimer's Disease is the most common type (60-80% of cases). "
            "India has approximately 8.8 million dementia patients. "
            "NER has 200,000+ undiagnosed cases. "
            "SAHAYAK-AI provides early detection and cognitive care for elderly patients in North East India."
        )

    # TYPES
    if any(k in msg for k in ["types of dementia", "kinds of dementia", "different dementia",
                               "alzheimer", "vascular dementia", "lewy body", "frontotemporal"]):
        return (
            "Types of Dementia:\n"
            "1. Alzheimer's Disease — most common (60-80%), gradual memory loss and personality changes.\n"
            "2. Vascular Dementia — caused by strokes or reduced brain blood flow.\n"
            "3. Lewy Body Dementia — visual hallucinations and Parkinson's-like movement problems.\n"
            "4. Frontotemporal Dementia — affects personality, behavior, and language.\n"
            "5. Mixed Dementia — combination of Alzheimer's and Vascular.\n"
            "6. Parkinson's Disease Dementia — occurs in advanced Parkinson's.\n"
            "SAHAYAK-AI primarily targets early Alzheimer's and MCI detection in NER elderly patients."
        )

    # 7 STAGES
    if any(k in msg for k in ["stages", "stage", "progression", "how does dementia progress",
                               "levels", "phases", "7 stage", "seven stage"]):
        return (
            "7 Stages of Alzheimer's and Dementia (Reisberg Scale):\n"
            "Stage 1 — No Impairment: No symptoms, silent brain changes.\n"
            "Stage 2 — Very Mild Decline: Minor forgetfulness (misplacing keys, forgetting names).\n"
            "Stage 3 — Mild Cognitive Impairment MCI: Memory issues — SAHAYAK-AI early detection target.\n"
            "Stage 4 — Mild Dementia: Difficulty with complex tasks, forgetting recent events.\n"
            "Stage 5 — Moderate Dementia: Needs help choosing clothes, confused about time and place.\n"
            "Stage 6 — Moderately Severe: Needs help with bathing and toileting, may forget spouse name.\n"
            "Stage 7 — Severe Dementia: Loss of speech, cannot walk, full-time care needed."
        )

    # SYMPTOMS
    if any(k in msg for k in ["symptom", "warning sign", "signs of dementia", "how to know",
                               "identify dementia", "recognize", "early signs", "early detection"]):
        return (
            "10 Warning Signs of Dementia:\n"
            "1. Memory loss disrupting daily life (especially recent events)\n"
            "2. Challenges in planning or problem solving\n"
            "3. Difficulty completing familiar tasks\n"
            "4. Confusion with time or place\n"
            "5. Trouble with visual images and spatial relationships\n"
            "6. New problems with words in speaking or writing\n"
            "7. Misplacing things and unable to retrace steps\n"
            "8. Decreased or poor judgment\n"
            "9. Withdrawal from social activities\n"
            "10. Changes in mood, personality, or behavior\n"
            "Tip: If 3+ signs are present, consult a neurologist. SAHAYAK-AI enables digital "
            "screening via Clock Drawing and Memory tests."
        )

    # DIAGNOSIS
    if any(k in msg for k in ["diagnosis", "diagnose", "test", "mmse", "moca", "clock drawing",
                               "cdt", "mri", "brain scan", "detect", "screening"]):
        return (
            "Dementia Diagnostic Tools:\n"
            "* MMSE (Mini-Mental State Examination) — 30-point cognitive screening.\n"
            "* MoCA (Montreal Cognitive Assessment) — sensitive for MCI detection.\n"
            "* CDT (Clock Drawing Test) — used in SAHAYAK with AI stroke kinematics and tremor analysis.\n"
            "* Brain MRI / CT Scan — detects structural brain changes.\n"
            "* PET Scan — detects amyloid plaques (Alzheimer's biomarker).\n"
            "* Blood Tests — rules out reversible causes (thyroid, B12 deficiency).\n"
            "* SAHAYAK SHAP Analysis — explainable ML feature attribution for doctors.\n"
            "SAHAYAK enables digital screening without hospital visits — crucial for remote NER areas."
        )

    # MEDICATIONS
    if any(k in msg for k in ["medication", "medicine", "drug", "treatment", "cure", "donepezil",
                               "memantine", "rivastigmine", "galantamine", "aricept", "therapy",
                               "lecanemab", "dementia medicine"]):
        return (
            "Dementia Medications and Treatments:\n"
            "FDA-Approved Drugs:\n"
            "* Donepezil (Aricept) — All stages, cholinesterase inhibitor, improves memory.\n"
            "* Rivastigmine (Exelon) — Stages 1-6, available as patch or capsule.\n"
            "* Galantamine (Razadyne) — Stages 1-6, boosts acetylcholine levels.\n"
            "* Memantine (Namenda) — Stages 4-7, NMDA receptor antagonist.\n"
            "* Lecanemab (Leqembi) — 2023 FDA approval, anti-amyloid antibody for early AD.\n"
            "Non-Drug Therapies in SAHAYAK:\n"
            "* Reminiscence Therapy, Cognitive Stimulation Games, Validation Therapy, Music Therapy.\n"
            "Note: No cure exists for Alzheimer's currently, but these treatments significantly slow progression."
        )

    # CAREGIVER
    if any(k in msg for k in ["caregiver", "caregiving", "family care", "care tips", "helping patient",
                               "burnout", "caretaker", "how to care", "care for dementia"]):
        return (
            "Caregiver Guide for SAHAYAK-AI:\n"
            "In-App Features: View Patient Progress Dashboard, Set Medication Reminders, "
            "Update Memory Book, Receive Low-Score Alerts, Communicate with Doctor in-app.\n\n"
            "Top Caregiving Tips:\n"
            "1. Use simple clear sentences — avoid multiple questions at once.\n"
            "2. Maintain consistent daily routine — reduces confusion and anxiety.\n"
            "3. Label household items with pictures and text.\n"
            "4. Do NOT argue or correct the patient — validate feelings and redirect gently.\n"
            "5. Ensure 7-8 hours of sleep — sleep loss worsens dementia symptoms.\n"
            "6. Keep environment safe — remove trip hazards, install grab bars.\n"
            "7. Take care of your own health — caregiver burnout is a serious risk.\n"
            "Burnout Signs: exhaustion, depression, social withdrawal.\n"
            "Contact ARDSI helpline: 1800-120-3474."
        )

    # DOCTOR
    if any(k in msg for k in ["doctor", "clinician", "neurologist", "physician", "clinical",
                               "shap", "random forest", "doctor dashboard", "clinical report",
                               "doctor features", "ml model"]):
        return (
            "Doctor and Clinician Features in SAHAYAK-AI:\n"
            "* Clinical Dashboard — All assigned patients, CDT scores, cognitive trend graphs.\n"
            "* SHAP Explainability — Which features (stroke hesitation, word recall, reaction time) "
            "drove each patient's cognitive score.\n"
            "* Auto-Classification — Normal / MCI / Moderate / Severe using Calibrated Random Forest.\n"
            "* Remote Assessments — Digital neurological exams without patient travel.\n"
            "* Treatment Notes — Add clinical notes, update treatment plans, flag high-risk cases.\n"
            "* Telemedicine — Schedule and conduct video consultations within the platform.\n"
            "Clinical Tests: CDT Analysis, Story Recall, Memory Match, Spot the Difference, "
            "Local Language Naming (Assamese, Bodo, Meitei, Khasi, Mizo), Daily Routine Adherence."
        )

    # PATIENT ROLE
    if any(k in msg for k in ["patient", "patient role", "what can patient", "patient dashboard",
                               "patient games", "patient features", "patient workspace"]):
        return (
            "Patient Features in SAHAYAK-AI:\n"
            "* Cognitive Games: Clock Drawing Test with AI analysis, Memory Match, "
            "Spot the Difference, Story Recall.\n"
            "* SAHAYAK Companion — Emotional support, reminiscence therapy, dementia Q&A (that's me!).\n"
            "* Daily Reminders — Medication, meals, and appointment alerts with voice read-aloud.\n"
            "* Memory Book — Record and revisit personal memories and family stories.\n"
            "* Progress Tracker — View your own cognitive scores over time.\n"
            "* Active Tremor Stabilization — ESP32 hardware module assists with dining utensils.\n"
            "Every patient deserves dignity and autonomy. Cultural and local language preferences "
            "are fully respected across all NER states."
        )

    # NER CONTEXT
    if any(k in msg for k in ["ner", "north east", "assam", "meghalaya", "manipur", "mizoram",
                               "nagaland", "tripura", "arunachal", "sikkim", "northeast india",
                               "north eastern"]):
        return (
            "SAHAYAK-AI for North Eastern India (NER):\n"
            "States Served: Assam, Meghalaya, Manipur, Mizoram, Nagaland, Tripura, "
            "Arunachal Pradesh, Sikkim.\n"
            "Languages Supported: Assamese, Bodo, Meitei, Khasi, Mizo, Nagamese, Bengali, Hindi.\n"
            "Key Challenges:\n"
            "* Less than 10 neurologists per million people in NER.\n"
            "* Dementia mistaken for normal aging — low awareness and high stigma.\n"
            "* Geographic isolation — remote hilly terrains, poor road and internet connectivity.\n"
            "SAHAYAK Solution: Offline-first APK at PHCs, ANM sub-centers, and patient phones. "
            "Zero cloud dependency. Works with zero internet."
        )

    # ESP32 HARDWARE (checked before generic tech to catch 'tremor'/'hardware' first)
    if any(k in msg for k in ["esp32", "tremor", "stabilization", "utensil",
                               "spoon", "imu", "mpu6050", "pwm", "tremor filter"]):
        return (
            "SAHAYAK-AI Active Tremor Stabilization Hardware:\n"
            "* Microcontroller: ESP32 with MPU6050 IMU sensor.\n"
            "* Sampling Rate: 100Hz continuous tremor measurement.\n"
            "* Compensation: 20kHz PWM active counter-thrust stabilization.\n"
            "* Application: Built into dining utensils (spoon/fork) for patients with tremor.\n"
            "* Sub-50ms latency: Real-time stabilization response.\n"
            "This preserves patient dignity and independence at mealtimes — critical for "
            "dementia and Parkinson's patients in NER."
        )

    # TECHNICAL ARCHITECTURE
    if any(k in msg for k in ["architecture", "technical", "flutter", "fastapi", "sqlite",
                               "ollama", "gemma", "hardware", "backend", "tech stack",
                               "how does it work", "github", "technology"]):
        return (
            "SAHAYAK-AI Technical Architecture:\n"
            "* Frontend: Flutter (Android + Web) — one codebase for phone and laptop.\n"
            "* Backend: FastAPI (Python) + SQLite — lightweight, offline-capable.\n"
            "* AI Engine: Ollama + Gemma 2B LLM — runs 100% locally, no internet needed.\n"
            "* Cognitive ML: Calibrated Random Forest + SHAP — explainable clinical scoring.\n"
            "* Hardware: ESP32 + MPU6050 IMU (100Hz) — 20kHz PWM active tremor stabilization.\n"
            "* Connectivity: Phone to Laptop via Wi-Fi on same network.\n"
            "* Offline Fallback: Full on-device AI companion (no backend needed).\n"
            "* GitHub: https://github.com/Shivansh1146/SIH-Final-Round"
        )

    # COGNITIVE GAMES
    if any(k in msg for k in ["game", "games", "cognitive game", "clock drawing", "memory match",
                               "story recall", "spot the difference", "exercise", "activities",
                               "brain game"]):
        return (
            "SAHAYAK-AI Cognitive Games:\n"
            "1. Clock Drawing Test (CDT) — AI analyzes stroke kinematics, tremor, hesitation. "
            "Key dementia screening tool.\n"
            "2. Memory Story Recall — story read aloud, patient answers questions to test episodic memory.\n"
            "3. Memory Match — card-matching game testing spatial and visual memory.\n"
            "4. Spot the Difference — two images compared to test attention and perceptual speed.\n"
            "5. Local Language Naming — patient names objects in native language (Assamese, Meitei, etc.).\n"
            "6. Daily Routine Reminders — tap-response and voice-confirmation for medication adherence.\n"
            "All games use large fonts, voice guidance, and culturally familiar imagery for elderly users."
        )

    # PREVENTION

    if any(k in msg for k in ["prevent", "prevention", "risk factor", "risk", "avoid dementia",
                               "reduce risk", "cause of dementia", "cause", "why dementia"]):
        return (
            "Dementia Risk Factors and Prevention:\n"
            "Non-Modifiable Risks: Age (risk doubles every 5 years after 65), "
            "family history, genetics (APOE-e4 gene).\n"
            "Modifiable Risks (can be reduced):\n"
            "* High blood pressure, Diabetes, Obesity, Physical inactivity.\n"
            "* Smoking, Excessive alcohol consumption.\n"
            "* Social isolation and depression.\n"
            "* Poor sleep (7-8 hours per night is protective).\n"
            "* Low education level (lifelong learning is protective).\n"
            "Key fact: 40% of global dementia cases are preventable through lifestyle changes!"
        )

    # STATISTICS
    if any(k in msg for k in ["statistics", "stats", "how many people", "global", "india dementia",
                               "prevalence", "numbers", "data", "facts", "dementia facts"]):
        return (
            "Global and India Dementia Statistics:\n"
            "* 55 million people worldwide live with dementia (WHO 2023).\n"
            "* New dementia case every 3 seconds globally.\n"
            "* India: approximately 8.8 million dementia patients (ARDSI estimate).\n"
            "* Cost of dementia care globally: USD 1.3 trillion per year.\n"
            "* NER India: Estimated 200,000+ undiagnosed dementia patients.\n"
            "* Only 1 in 10 dementia cases is formally diagnosed in India.\n"
            "* Risk doubles every 5 years after age 65.\n"
            "* Women are 2 times more likely to develop Alzheimer's than men."
        )

    # SUPPORT
    if any(k in msg for k in ["support", "resources", "ardsi", "support group", "helpline",
                               "where to get help", "contact", "help for dementia"]):
        return (
            "Dementia Support Resources in India:\n"
            "* ARDSI (Alzheimer's and Related Disorders Society of India): "
            "www.ardsi.org | Helpline: 1800-120-3474\n"
            "* NIMHANS Dementia Clinic — Bangalore.\n"
            "* AIIMS Memory Clinic — New Delhi.\n"
            "* NER Specific: GMCH (Gauhati Medical College Hospital) neurology department.\n"
            "* Caregiver Support Groups available through ARDSI regional chapters.\n"
            "* SAHAYAK-AI: Available offline on your phone anytime, anywhere in NER."
        )

    # FESTIVALS (reminiscence therapy)
    if any(k in msg for k in ["bihu", "festival", "puja", "diwali", "celebrate",
                               "rongali", "pitha", "dhol", "eid", "celebration"]):
        opts = [
            "Bihu and village celebrations bring so much joy! Do you remember the folk songs sung "
            "around the courtyard, and the sweet smell of pitha being made?",
            "Festivals with the whole family gathered are truly special memories. What was your "
            "favorite sweet or dish made during festival days?",
            "Rongali Bihu is the spirit of Assam — music, dance, and togetherness. "
            "Who in your family was most excited during festival time?",
        ]
        return random.choice(opts)

    # FOOD
    if any(k in msg for k in ["food", "eat", "cook", "kitchen", "rice", "fish",
                               "sweet", "dish", "chai", "tea", "pitha", "mango"]):
        opts = [
            "Homemade pitha and fresh Assam chai have a taste that brings such deep comfort. "
            "Did everyone gather around the kitchen while it was being made?",
            "The warmth of a home kitchen with fresh spices and steaming rice is a beautiful memory. "
            "What was your favorite meal to share with loved ones?",
        ]
        return random.choice(opts)

    # NATURE
    if any(k in msg for k in ["river", "brahmaputra", "garden", "rain", "monsoon",
                               "hills", "village", "loktak", "dzukou", "green", "trees"]):
        opts = [
            "The morning mist over the tea gardens and the gentle Brahmaputra breeze are so peaceful. "
            "Did you have a favorite spot where you loved to sit and watch the greenery?",
            "The smell of earth after the first monsoon rain over the hills of the North East is so "
            "refreshing. What did your family like to do on rainy afternoons?",
        ]
        return random.choice(opts)

    # FAMILY
    if any(k in msg for k in ["family", "mother", "father", "grandmother", "grandfather",
                               "childhood", "home", "courtyard", "friend", "school", "child"]):
        opts = [
            "Growing up surrounded by loved ones in the courtyard leaves such warm feelings. "
            "What games did you play with your friends back then?",
            "That sounds like a home filled with warmth and love. "
            "Tell me, what was your favorite time of the day in your family home?",
        ]
        return random.choice(opts)

    # MUSIC
    if any(k in msg for k in ["song", "music", "dance", "sing", "radio", "instrument", "bihu geet"]):
        return (
            "Music from our youth carries such vivid feelings! "
            "What was the melody or Bihu geet that always made everyone in your family smile and sing along?"
        )

    # GENERAL FALLBACK
    clean_text = re.sub(r"[^\w\s]", "", user_message).strip()
    words = clean_text.split()
    keyword_snip = " ".join(words[-4:]) if len(words) > 4 else clean_text
    opts = [
        "Thank you for sharing that. You can also ask me anything about dementia — stages, "
        "symptoms, medications, or caregiving tips. Or ask about SAHAYAK-AI features for "
        "patients, caregivers, and doctors. I know everything!",
        "That is a meaningful topic. Feel free to also ask me about dementia types, 7 stages, "
        "treatment options, or how SAHAYAK-AI works for patients, caregivers, and doctors in NER.",
        f"Hearing about {keyword_snip if keyword_snip else 'that'} is wonderful. "
        "You can ask me about dementia clinical knowledge, project features, NER context, "
        "medications, or just share a warm memory — I am always here!",
    ]
    return random.choice(opts)


async def generate_companion_reply(
    patient_id: str,
    user_message: str,
    conversation_id: str,
) -> str:
    """
    1. If Ollama/Gemma is running locally — uses full LLM with domain system prompt.
    2. If Ollama is offline — instantly uses on-device Knowledge and Validation Engine.
    Both paths are fully offline and contain complete domain knowledge.
    """
    is_ollama_up = await check_ollama_availability()
    if is_ollama_up:
        history = get_rolling_history(conversation_id)
        messages = [
            {"role": "system", "content": COMPANION_SYSTEM_PROMPT},
            *history,
            {"role": "user", "content": user_message},
        ]
        candidate = await call_ollama_generate(messages)
        if candidate and candidate.strip():
            append_to_history(conversation_id, user_message, candidate.strip())
            return candidate.strip()

    fallback_reply = generate_contextual_validation_reply(user_message)
    append_to_history(conversation_id, user_message, fallback_reply)
    return fallback_reply
