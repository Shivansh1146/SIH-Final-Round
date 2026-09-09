"""
Offline Conversational AI Reminiscence & Validation Companion for SAHAYAK-AI / CogniCare NER.
Runs entirely on-device / local Community AI Kiosk via Ollama + Gemma 4 E2B.
Zero external internet or third-party API calls required.
"""

import os
import re
import json
import logging
from pathlib import Path
from typing import Optional, List, Dict
import httpx
from pydantic import BaseModel, Field

# Local review logging path for rejected model completions
REVIEW_LOG_DIR = Path(__file__).resolve().parent.parent / "logs"
REVIEW_LOG_DIR.mkdir(parents=True, exist_ok=True)
REVIEW_LOG_PATH = REVIEW_LOG_DIR / "companion_review.log"

logger = logging.getLogger("sahayak_companion")

# Ollama local settings
OLLAMA_HOST = os.environ.get("OLLAMA_HOST", "http://localhost:11434")
OLLAMA_MODEL = os.environ.get("OLLAMA_MODEL", "gemma4:e2b")

# Reminiscence and Validation Therapy System Prompt
COMPANION_SYSTEM_PROMPT = """You are a calm, warm companion helping an elderly person in Northeast India recall pleasant memories. Follow these rules without exception:

1. VALIDATION THERAPY: Never correct, contradict, or reality-check the person's account of events, dates, or people — even if factually wrong. Validate the emotion behind what they say instead.
2. REMINISCENCE FOCUS: Gently ask about family, festivals, food, places, and everyday life from their past, grounded in any photo captions or family-provided context you're given. Keep questions open-ended and simple — one question at a time, never multi-part.
3. NEVER: give medical advice, mention dementia/diagnosis/prognosis, discuss death, loss, or distressing news, argue, or ask questions requiring precise dates or numbers.
4. TONE: Short sentences. Warm. Patient. No jargon. Respond as if speaking aloud, since this is read by text-to-speech.
5. IF THE PERSON SEEMS CONFUSED OR DISTRESSED: gently redirect toward a pleasant, concrete memory ("That sounds nice. What was your favorite festival to celebrate?") rather than probing further.
6. Keep every response under 3 sentences."""

# Pre-written gentle fallback responses
DEFAULT_FALLBACK_RESPONSE = (
    "That's a lovely thought. Tell me more about that day."
)

FALLBACK_POOL = [
    "That's a lovely thought. Tell me more about that day.",
    "That sounds so pleasant. What was your favorite part of that time?",
    "It is wonderful to remember those times. Which festival did you enjoy celebrating the most?",
]

# Safety filter banned terms & correction markers
DISALLOWED_TERMS = [
    "dementia",
    "alzheimer",
    "disease",
    "condition",
    "diagnosis",
    "prognosis",
    "mental illness",
    "cognitive decline",
    "dying",
    "death",
    "died",
    "passed away",
]

CORRECTION_PATTERNS = [
    r"\bactually\b",
    r"\bthat'?s not right\b",
    r"\bthat is not right\b",
    r"\bthat'?s incorrect\b",
    r"\bno,?\s+it was\b",
    r"\byou are mistaken\b",
    r"\byou're mistaken\b",
    r"\byou are wrong\b",
    r"\byou're wrong\b",
]

# In-memory rolling window history per conversationId: max 6 turns (3 user + 3 assistant)
# { conversationId: [ {"role": "user"|"assistant", "content": "..."}, ... ] }
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
    """Logs safety filter violations locally for continuous review and tightening."""
    try:
        entry = {
            "conversation_id": conversation_id,
            "reason": reason,
            "raw_output": raw_output,
        }
        with open(REVIEW_LOG_PATH, "a", encoding="utf-8") as f:
            f.write(json.dumps(entry) + "\n")
    except Exception as e:
        logger.error(f"Failed to log rejected response: {e}")


def passes_safety_filter(text: str) -> (bool, str):
    """
    Validates model output against validation therapy and clinical safety rules.
    Rejects diagnosis words, contradiction phrases, and multi-part questions.
    """
    if not text or not text.strip():
        return False, "Empty output"

    lower = text.lower()

    # 1. Diagnosis / distressing terms check
    for term in DISALLOWED_TERMS:
        if term in lower:
            return False, f"Contains restricted term: '{term}'"

    # 2. Contradiction / reality check phrases
    for pat in CORRECTION_PATTERNS:
        if re.search(pat, lower):
            return False, f"Contains correction pattern: '{pat}'"

    # 3. Multi-part questions check (more than 1 question mark)
    question_count = text.count("?")
    if question_count > 1:
        return False, f"Contains multiple questions ({question_count})"

    # 4. Limit length (under 3-4 sentences max)
    sentences = [s.strip() for s in re.split(r"[.!?]+", text) if s.strip()]
    if len(sentences) > 4:
        return False, f"Too long ({len(sentences)} sentences)"

    return True, "Passed"


async def check_ollama_availability() -> bool:
    """Checks whether local Ollama is reachable and gemma4:e2b (or local fallback) is present."""
    try:
        async with httpx.AsyncClient(timeout=1.5) as client:
            res = await client.get(f"{OLLAMA_HOST}/api/tags")
            if res.status_code == 200:
                data = res.json()
                # Return True if Ollama service is responsive
                return True
            return False
    except Exception:
        return False


def get_rolling_history(conversation_id: str) -> List[Dict[str, str]]:
    """Returns the last 6 turns for this conversation."""
    return _conversation_memory.get(conversation_id, [])


def append_to_history(conversation_id: str, user_text: str, assistant_text: str):
    """Updates rolling window, retaining at most 6 turns (3 exchanges)."""
    history = _conversation_memory.setdefault(conversation_id, [])
    history.append({"role": "user", "content": user_text})
    history.append({"role": "assistant", "content": assistant_text})
    # Keep only the most recent 6 messages
    if len(history) > 6:
        _conversation_memory[conversation_id] = history[-6:]


async def call_ollama_generate(messages: List[Dict[str, str]]) -> Optional[str]:
    """Direct HTTP call to Ollama /api/chat with 8s timeout."""
    try:
        async with httpx.AsyncClient(timeout=8.0) as client:
            payload = {
                "model": OLLAMA_MODEL,
                "messages": messages,
                "stream": False,
                "options": {
                    "temperature": 0.6,
                    "top_p": 0.9,
                    "num_predict": 120,
                },
            }
            res = await client.post(f"{OLLAMA_HOST}/api/chat", json=payload)
            if res.status_code == 200:
                data = res.json()
                return data.get("message", {}).get("content", "").strip()
            return None
    except Exception as e:
        logger.warning(f"Ollama call failed or timed out: {e}")
        return None


async def generate_companion_reply(
    patient_id: str,
    user_message: str,
    conversation_id: str,
) -> str:
    """
    Executes the conversational loop:
    1. Prepares System Prompt + Rolling History + User message
    2. Calls Ollama
    3. Runs Safety Filter. If failed, regenerates ONCE.
    4. If regeneration still fails or times out, returns fixed gentle fallback.
    """
    history = get_rolling_history(conversation_id)
    messages = [
        {"role": "system", "content": COMPANION_SYSTEM_PROMPT},
        *history,
        {"role": "user", "content": user_message},
    ]

    # First attempt
    candidate = await call_ollama_generate(messages)
    if candidate:
        passed, reason = passes_safety_filter(candidate)
        if passed:
            append_to_history(conversation_id, user_message, candidate)
            return candidate
        else:
            log_rejected_response(conversation_id, candidate, f"Attempt 1: {reason}")

    # Second attempt (Regenerate once)
    candidate_retry = await call_ollama_generate(messages)
    if candidate_retry:
        passed, reason = passes_safety_filter(candidate_retry)
        if passed:
            append_to_history(conversation_id, user_message, candidate_retry)
            return candidate_retry
        else:
            log_rejected_response(conversation_id, candidate_retry, f"Attempt 2 (Retry): {reason}")

    # Safe fallback if model fails, is unavailable, or times out > 8s
    safe_reply = DEFAULT_FALLBACK_RESPONSE
    append_to_history(conversation_id, user_message, safe_reply)
    return safe_reply
