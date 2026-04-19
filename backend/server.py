"""FastAPI Digital Twin API (Week 2 pattern: OpenAI + file-backed session memory)."""

from __future__ import annotations

import json
import os
import uuid
from pathlib import Path
from typing import Any, Dict, List, Optional

from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from openai import OpenAI
from pydantic import BaseModel

load_dotenv(override=True)

app = FastAPI(title="Digital Twin API")

_origins = os.getenv("CORS_ORIGINS", "http://localhost:3000").split(",")
app.add_middleware(
    CORSMiddleware,
    allow_origins=[o.strip() for o in _origins if o.strip()],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

MEMORY_DIR = Path(__file__).resolve().parent.parent / "memory"
MEMORY_DIR.mkdir(parents=True, exist_ok=True)

_client = OpenAI()


def _personality() -> str:
    me_path = Path(__file__).resolve().parent / "me.txt"
    return me_path.read_text(encoding="utf-8").strip()


PERSONALITY = _personality()


def _load_conversation(session_id: str) -> List[Dict[str, Any]]:
    path = MEMORY_DIR / f"{session_id}.json"
    if not path.is_file():
        return []
    return json.loads(path.read_text(encoding="utf-8"))


def _save_conversation(session_id: str, messages: List[Dict[str, Any]]) -> None:
    path = MEMORY_DIR / f"{session_id}.json"
    path.write_text(json.dumps(messages, indent=2, ensure_ascii=False), encoding="utf-8")


class ChatRequest(BaseModel):
    message: str
    session_id: Optional[str] = None


class ChatResponse(BaseModel):
    response: str
    session_id: str


@app.get("/")
async def root() -> dict[str, str]:
    return {"message": "AI Digital Twin API with Memory"}


@app.get("/health")
async def health() -> dict[str, str]:
    return {"status": "healthy"}


@app.post("/chat", response_model=ChatResponse)
async def chat(request: ChatRequest) -> ChatResponse:
    try:
        session_id = request.session_id or str(uuid.uuid4())
        history = _load_conversation(session_id)
        messages: List[Dict[str, Any]] = [{"role": "system", "content": PERSONALITY}]
        messages.extend(history)
        messages.append({"role": "user", "content": request.message})

        model = os.getenv("OPENAI_CHAT_MODEL", "gpt-4o-mini")
        completion = _client.chat.completions.create(model=model, messages=messages)
        assistant_text = completion.choices[0].message.content or ""

        history.append({"role": "user", "content": request.message})
        history.append({"role": "assistant", "content": assistant_text})
        _save_conversation(session_id, history)

        return ChatResponse(response=assistant_text, session_id=session_id)
    except Exception as exc:  # noqa: BLE001
        raise HTTPException(status_code=500, detail=str(exc)) from exc


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=int(os.getenv("PORT", "8000")))
