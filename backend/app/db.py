from __future__ import annotations

import os
from typing import List, Optional

from pydantic import BaseModel
import psycopg
from psycopg.rows import dict_row
from psycopg_pool import ConnectionPool

from .gemini_client import embed_text


class ProductRecord(BaseModel):
    id: int
    name: str
    price: float
    store_name: str
    category: Optional[str]


class DatabaseClient:
    def __init__(self) -> None:
        dsn = os.getenv("DATABASE_URL") or self._build_dsn()
        if not dsn:
            raise RuntimeError("DATABASE_URL or DB_* env vars must be set")

        self.pool = ConnectionPool(dsn, kwargs={"row_factory": dict_row}, open=True, min_size=1, max_size=10)
        self.embeddings_enabled = os.getenv("EMBEDDINGS_ENABLED", "true").lower() in {"1", "true", "yes"}

    def _build_dsn(self) -> Optional[str]:
        host = os.getenv("DB_HOST")
        port = os.getenv("DB_PORT", "5432")
        name = os.getenv("DB_NAME")
        user = os.getenv("DB_USER")
        password = os.getenv("DB_PASSWORD")
        if not all([host, port, name, user, password]):
            return None
        return f"postgresql://{user}:{password}@{host}:{port}/{name}"

    def fetch_product_names(self, limit: int = 50) -> List[str]:
        sql = "SELECT name FROM products ORDER BY name ASC LIMIT %s"
        with self.pool.connection() as conn:
            with conn.cursor() as cur:
                cur.execute(sql, (limit,))
                rows = cur.fetchall()
        return [r["name"] for r in rows]

    def search_by_fuzzy(self, query: str, limit: int = 10) -> List[ProductRecord]:
        sql = (
            "SELECT id, name, price, store_name, category "
            "FROM products "
            "WHERE name %% %s OR name ILIKE '%' || %s || '%' "
            "ORDER BY similarity(name, %s) DESC, name ASC "
            "LIMIT %s"
        )
        with self.pool.connection() as conn:
            with conn.cursor() as cur:
                cur.execute(sql, (query, query, query, limit))
                rows = cur.fetchall()
        return [ProductRecord(**row) for row in rows]

    def search_by_embedding(self, query: str, limit: int = 10) -> List[ProductRecord]:
        query_vector = embed_text(query)
        if not query_vector:
            return self.search_by_fuzzy(query, limit)

        sql = (
            "SELECT id, name, price, store_name, category "
            "FROM products "
            "WHERE embedding IS NOT NULL "
            "ORDER BY embedding <-> %s::vector "
            "LIMIT %s"
        )
        with self.pool.connection() as conn:
            with conn.cursor() as cur:
                cur.execute(sql, (query_vector, limit))
                rows = cur.fetchall()
        return [ProductRecord(**row) for row in rows]