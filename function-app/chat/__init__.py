"""POST /api/chat — Azure OpenAI + optional blob memory (Week 2–style contract)."""

from __future__ import annotations

import json
import logging
import os
import uuid
from pathlib import Path
from typing import Any, Dict, List, Optional

import azure.functions as func
from azure.core.exceptions import HttpResponseError
from azure.identity import DefaultAzureCredential
from azure.storage.blob import BlobClient, BlobServiceClient
from openai import AzureOpenAI

logger = logging.getLogger(__name__)

_PERSONA_PATH = Path(__file__).resolve().parent.parent / "persona.txt"


def _personality() -> str:
    try:
        return _PERSONA_PATH.read_text(encoding="utf-8").strip()
    except OSError:
        return "You are a helpful professional assistant."


def _blob_client(blob_name: str) -> Optional[BlobClient]:
    raw = os.environ.get("AZURE_STORAGE_ACCOUNT_URL", "").strip()
    container = os.environ.get("MEMORY_BLOB_CONTAINER", "memory")
    if not raw:
        return None
    account_url = raw if raw.endswith("/") else raw + "/"
    try:
        cred = DefaultAzureCredential(exclude_interactive_browser_credential=True)
        svc = BlobServiceClient(account_url=account_url, credential=cred)
        return svc.get_container_client(container).get_blob_client(blob_name)
    except Exception as exc:  # noqa: BLE001
        logger.warning("Blob client unavailable: %s", exc)
        return None


def _load_history(session_id: str) -> List[Dict[str, Any]]:
    client = _blob_client(f"{session_id}.json")
    if not client or not client.exists():
        return []
    try:
        raw = client.download_blob().readall().decode("utf-8")
        return json.loads(raw)
    except (HttpResponseError, json.JSONDecodeError, OSError):
        return []


def _save_history(session_id: str, history: List[Dict[str, Any]]) -> None:
    client = _blob_client(f"{session_id}.json")
    if not client:
        return
    try:
        data = json.dumps(history, ensure_ascii=False, indent=2).encode("utf-8")
        client.upload_blob(data, overwrite=True)
    except HttpResponseError as exc:
        logger.warning("Blob save failed: %s", exc)


def main(req: func.HttpRequest) -> func.HttpResponse:
    try:
        payload = req.get_json()
    except ValueError:
        return func.HttpResponse('{"detail":"Invalid JSON"}', status_code=400, mimetype="application/json")

    message = (payload or {}).get("message")
    if not message or not isinstance(message, str):
        return func.HttpResponse('{"detail":"message required"}', status_code=400, mimetype="application/json")

    session_id = (payload or {}).get("session_id") or str(uuid.uuid4())
    if not isinstance(session_id, str):
        session_id = str(uuid.uuid4())

    endpoint = os.environ.get("AZURE_OPENAI_ENDPOINT", "").rstrip("/")
    api_key = os.environ.get("AZURE_OPENAI_API_KEY", "")
    deployment = os.environ.get("AZURE_OPENAI_DEPLOYMENT", "gpt-4o")
    if not endpoint or not api_key:
        return func.HttpResponse(
            '{"detail":"OpenAI not configured"}',
            status_code=503,
            mimetype="application/json",
        )

    client = AzureOpenAI(
        api_version="2024-02-01",
        azure_endpoint=endpoint,
        api_key=api_key,
    )

    history = _load_history(session_id)
    messages: List[Dict[str, Any]] = [{"role": "system", "content": _personality()}]
    messages.extend(history)
    messages.append({"role": "user", "content": message})

    try:
        completion = client.chat.completions.create(model=deployment, messages=messages)
        assistant = completion.choices[0].message.content or ""
    except Exception as exc:  # noqa: BLE001
        logger.exception("OpenAI call failed")
        return func.HttpResponse(
            json.dumps({"detail": str(exc)}),
            status_code=500,
            mimetype="application/json",
        )

    history.append({"role": "user", "content": message})
    history.append({"role": "assistant", "content": assistant})
    _save_history(session_id, history)

    return func.HttpResponse(
        json.dumps({"response": assistant, "session_id": session_id}),
        status_code=200,
        mimetype="application/json",
    )
