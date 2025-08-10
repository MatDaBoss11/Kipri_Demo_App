from typing import List, Optional
import os
import json
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from dotenv import load_dotenv

from .gemini_client import normalize_query_with_gemini
from .db import ProductRecord, DatabaseClient
from .cache import query_cache


class SearchRequest(BaseModel):
    query: str
    limit: Optional[int] = 10


# Load env for local dev
load_dotenv()

app = FastAPI(title="Grocery Search API", version="0.1.0")

# CORS for local dev and mobile clients. Adjust origins as needed.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


db_client: Optional[DatabaseClient] = None

def get_db_client() -> DatabaseClient:
    global db_client
    if db_client is None:
        db_client = DatabaseClient()
    return db_client


@app.get("/health")
def health() -> dict:
    return {"status": "ok"}


@app.post("/search")
def search(request: SearchRequest) -> List[ProductRecord]:
    if not request.query or not request.query.strip():
        raise HTTPException(status_code=400, detail="Query must not be empty")

    original_query = request.query.strip()
    limit = max(1, min(50, request.limit or 10))

    # Cache by the original user query to include normalization step result
    cached = query_cache.get(original_query)
    if cached is not None:
        # Return a shallow copy limited to current limit to avoid over-serving
        return cached[:limit]

    database = get_db_client()

    # Pull a small set of product names to prime Gemini with context
    context_product_names = database.fetch_product_names(limit=50)

    normalized = normalize_query_with_gemini(
        user_query=original_query,
        context_product_names=context_product_names,
    )

    if not normalized:
        normalized = original_query

    # Prefer embedding similarity if enabled, fallback to trigram fuzzy
    try:
        if database.embeddings_enabled:
            products = database.search_by_embedding(normalized, limit=limit)
        else:
            products = database.search_by_fuzzy(normalized, limit=limit)
    except Exception as exc:
        # Fallback to fuzzy if embedding path fails
        products = database.search_by_fuzzy(normalized, limit=limit)

    # Cache the full list under the original query
    query_cache[original_query] = products
    return products[:limit]