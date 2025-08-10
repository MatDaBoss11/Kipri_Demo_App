import os
from typing import List

from psycopg_pool import ConnectionPool
from psycopg.rows import dict_row

from app.gemini_client import embed_text


def main() -> None:
    dsn = os.getenv("DATABASE_URL")
    if not dsn:
        host = os.getenv("DB_HOST")
        port = os.getenv("DB_PORT", "5432")
        name = os.getenv("DB_NAME")
        user = os.getenv("DB_USER")
        password = os.getenv("DB_PASSWORD")
        dsn = f"postgresql://{user}:{password}@{host}:{port}/{name}"

    pool = ConnectionPool(dsn, kwargs={"row_factory": dict_row}, open=True)

    select_sql = "SELECT id, name FROM products WHERE embedding IS NULL LIMIT 2000"
    update_sql = "UPDATE products SET embedding = %s::vector WHERE id = %s"

    total = 0
    with pool.connection() as conn:
        with conn.cursor() as cur:
            cur.execute(select_sql)
            rows = cur.fetchall()

        for row in rows:
            text = row["name"]
            emb = embed_text(text)
            if not emb:
                continue
            with conn.cursor() as cur:
                cur.execute(update_sql, (emb, row["id"]))
                total += 1
        conn.commit()

    print(f"Updated embeddings for {total} products")


if __name__ == "__main__":
    main()