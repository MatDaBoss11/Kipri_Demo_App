import os
import logging
from typing import List, Optional

import google.generativeai as genai

logger = logging.getLogger(__name__)


_GEMINI_MODEL = os.getenv("GEMINI_MODEL", "gemini-1.5-flash")
_EMBED_MODEL = os.getenv("GEMINI_EMBED_MODEL", "text-embedding-004")
_GEMINI_API_KEY = os.getenv("GOOGLE_API_KEY")

if not _GEMINI_API_KEY:
    logger.warning("GOOGLE_API_KEY not set; Gemini calls will fail.")

if _GEMINI_API_KEY:
    genai.configure(api_key=_GEMINI_API_KEY)


def _build_normalization_prompt(user_query: str, context_product_names: List[str]) -> str:
    product_list = "\n".join(f"- {name}" for name in context_product_names)
    system = (
        "You are a product search normalizer. Given a user's query in any language, "
        "translate and normalize it into the closest matching product keyword from the database list. "
        "Return only the normalized keyword, nothing else."
    )
    prompt = (
        f"{system}\n\n"
        f"Database product examples (partial list):\n{product_list}\n\n"
        f"User query: {user_query}\n"
        f"Normalized keyword:"
    )
    return prompt


def normalize_query_with_gemini(user_query: str, context_product_names: List[str]) -> Optional[str]:
    if not _GEMINI_API_KEY:
        return None

    prompt = _build_normalization_prompt(user_query, context_product_names)
    try:
        model = genai.GenerativeModel(_GEMINI_MODEL)
        response = model.generate_content(prompt, request_options={"timeout": 8})
        text = (response.text or "").strip()
        # Clean extra quotes or punctuation
        normalized = text.strip('\"\'\n\r\t .,')
        return normalized
    except Exception as exc:
        logger.exception("Gemini normalization failed: %s", exc)
        return None


def embed_text(text: str) -> Optional[List[float]]:
    if not _GEMINI_API_KEY:
        return None
    try:
        resp = genai.embed_content(model=_EMBED_MODEL, content=text)
        embedding = resp["embedding"]["values"] if isinstance(resp, dict) else resp.embedding.values
        return embedding
    except Exception as exc:
        logger.exception("Gemini embedding failed: %s", exc)
        return None