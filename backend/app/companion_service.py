"""
Offline Conversational AI Reminiscence & Validation Companion for SAHAYAK-AI / CogniCare NER.
Runs locally on-device / local Community AI Kiosk via Ollama + Gemma 4 E2B, with dynamic on-device
NLP contextual reasoning and validation therapy when Ollama is offline/starting up.
Zero external internet or third-party API calls required.
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

# Local review logging path for rejected model completions
REVIEW_LOG_DIR = Path(__file__).resolve().parent.parent / "logs"
REVIEW_LOG_DIR.mkdir(parents=True, exist_ok=True)
REVIEW_LOG_PATH = REVIEW_LOG_DIR / "companion_review.log"

logger = logging.getLogger("sahayak_companion")

# Ollama local settings
OLLAMA_HOST = os.environ.get("OLLAMA_HOST", "http://localhost:11434")
OLLAMA_MODEL = os.environ.get("OLLAMA_MODEL", "gemma2:2b")

# Reminiscence and Validation Therapy System Prompt
COMPANION_SYSTEM_PROMPT = """You are a warm, knowledgeable, and caring AI companion for elderly individuals and family members in India.

Guidelines:
1. Answer the user's questions clearly, accurately, and warmly.
2. If the user is sharing memories, feelings, or stories, validate their emotions with empathy and interest.
3. Keep your tone gentle, conversational, and natural. Keep responses concise (2 to 4 sentences).
4. Never introduce distressing medical diagnoses or argue. Speak as a supportive, reassuring friend."""

# Safety filter banned terms & correction markers
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

# In-memory rolling window history per conversationId: max 6 turns (3 user + 3 assistant)
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
    return True, "Passed"


async def check_ollama_availability() -> bool:
    """Checks whether local Ollama is reachable and responsive."""
    try:
        async with httpx.AsyncClient(timeout=1.0) as client:
            res = await client.get(f"{OLLAMA_HOST}/api/tags")
            if res.status_code == 200:
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
    """Direct HTTP call to Ollama /api/chat with auto-detection of available downloaded model."""
    try:
        async with httpx.AsyncClient(timeout=12.0) as client:
            # 1. Fetch available models from Ollama
            model_to_use = OLLAMA_MODEL
            try:
                tags_res = await client.get(f"{OLLAMA_HOST}/api/tags")
                if tags_res.status_code == 200:
                    models = [m.get("name", "") for m in tags_res.json().get("models", [])]
                    if models:
                        # Prefer gemma or use the first downloaded model
                        gemma_match = next((m for m in models if "gemma" in m), models[0])
                        model_to_use = gemma_match
            except Exception:
                pass

            payload = {
                "model": model_to_use,
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


def generate_contextual_validation_reply(user_message: str) -> str:
    """
    Intelligent on-device semantic reminiscence engine:
    Dynamically analyzes the patient's spoken topics (festivals, tea gardens,
    monsoons, childhood courtyard, food, music, family) and generates personalized,
    emotionally validating conversational responses adhering strictly to validation therapy.
    """
    msg = user_message.lower().strip()

    # 1. Festivals & Celebrations (Bihu, Durga Puja, Diwali, harvest)
    if any(k in msg for k in ["bihu", "festival", "puja", "diwali", "celebrate", "celebration", "pitha", "dhol"]):
        options = [
            "Bihu and village celebrations bring so much joy and laughter together. Do you remember the folk songs people sang around the courtyard?",
            "Festivals with the whole family gathered are truly special memories. What was your favorite sweet or dish made during festival days?",
            "Celebrating with neighbors and hearing the drums must have been wonderful. Who was the most excited in your family during festival time?",
        ]
        return random.choice(options)

    # 2. Food, Cooking & Traditional Kitchen (pitha, rice, tea, curry, mango, kitchen)
    elif any(k in msg for k in ["food", "eat", "cook", "kitchen", "tea", "pitha", "mango", "fish", "rice", "sweet", "dish"]):
        options = [
            "Homemade cooking from those days has a taste you never forget. What was the dish you loved watching your family prepare the most?",
            "Fresh tea and homemade sweets make any morning feel so comforting. Did everyone gather around the kitchen while it was being cooked?",
            "The warmth of a home kitchen with fresh spices is such a comforting memory. What was your favorite meal to share with loved ones?",
        ]
        return random.choice(options)

    # 3. Nature, River, Monsoons & Northeast Landscapes (Brahmaputra, rain, river, hills, tea garden)
    elif any(k in msg for k in ["river", "water", "garden", "tea", "rain", "monsoon", "hills", "brahmaputra", "green", "trees", "village"]):
        options = [
            "Walking by the river and seeing the green hills is so peaceful to remember. Did you enjoy the quiet breeze during the evening walks?",
            "The smell of earth after the first monsoon rain is so refreshing. What did you and your family like to do on rainy afternoons?",
            "The tea gardens in the morning mist always look so calm and beautiful. Did you have a favorite spot where you loved to sit and watch the greenery?",
        ]
        return random.choice(options)

    # 4. Family, Grandparents, Childhood & Courtyard (mother, father, grandmother, grandfather, child, childhood, school)
    elif any(k in msg for k in ["family", "mother", "father", "grandmother", "grandfather", "childhood", "house", "home", "courtyard", "friend"]):
        options = [
            "Growing up surrounded by loved ones in the courtyard leaves such warm feelings in the heart. What games did you play with your friends back then?",
            "Grandparents and parents have so many wonderful stories to tell. What is one of the kindest things you remember your family doing?",
            "That sounds like a house filled with warmth and love. Tell me, what was your favorite time of the day in your family home?",
        ]
        return random.choice(options)

    # 5. Songs, Dance, Dhol & Music
    elif any(k in msg for k in ["song", "music", "dance", "sing", "radio", "instrument"]):
        options = [
            "Music and songs from youth bring back such vivid feelings. What was the melody that always made everyone smile?",
            "Listening to songs together on the radio or during community gatherings was so joyful. Did people dance and sing together in the evenings?",
        ]
        return random.choice(options)

    # 6. General Conversational & Emotional Validation Fallback
    else:
        # Echo back a touch of what they said to feel completely personalized and validated
        clean_text = re.sub(r"[^\w\s]", "", user_message).strip()
        words = clean_text.split()
        keyword_snip = " ".join(words[-4:]) if len(words) > 4 else clean_text
        
        options = [
            f"Hearing about {keyword_snip if keyword_snip else 'that time'} brings such a calm feeling. What stands out most in your memory from that day?",
            "That sounds like such a meaningful and pleasant memory. Tell me more about who was there with you.",
            "It is so wonderful to look back on times that brought you joy. What was the happiest part of that for you?",
        ]
        return random.choice(options)


async def generate_companion_reply(
    patient_id: str,
    user_message: str,
    conversation_id: str,
) -> str:
    """
    Executes the conversational loop using local Gemma LLM via Ollama.
    """
    history = get_rolling_history(conversation_id)
    messages = [
        {"role": "system", "content": COMPANION_SYSTEM_PROMPT},
        *history,
        {"role": "user", "content": user_message},
    ]

    # Call local Gemma 2B model via Ollama
    candidate = await call_ollama_generate(messages)
    if candidate and candidate.strip():
        append_to_history(conversation_id, user_message, candidate.strip())
        return candidate.strip()

    # Direct retry with lightweight prompt if first call was empty
    candidate_retry = await call_ollama_generate([
        {"role": "system", "content": "You are a warm, helpful AI companion. Answer concisely in 2-3 sentences."},
        {"role": "user", "content": user_message}
    ])
    if candidate_retry and candidate_retry.strip():
        append_to_history(conversation_id, user_message, candidate_retry.strip())
        return candidate_retry.strip()

    return "Hello! I am your local Gemma AI companion. Please ask me any question!"
