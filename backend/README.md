# Grocery Search Backend (FastAPI + Gemini + Supabase)

## Quickstart

1. Create and fill `.env` from `.env.example`.
2. Install deps:
   ```bash
   python -m venv .venv && source .venv/bin/activate
   pip install -r requirements.txt
   ```
3. Run DB migrations (Supabase):
   - Ensure extensions and table exist using `supabase/migrations/001_init.sql`.
4. (Optional) Index embeddings for existing products:
   ```bash
   python -m scripts.index_embeddings
   ```
5. Start API:
   ```bash
   uvicorn app.main:app --host 0.0.0.0 --port 8000 --workers 2
   ```

## Docker (recommended for dev)
```bash
# From repo root
docker compose up -d --build
# Run migration in the db container
docker exec -i $(docker ps -qf name=_db_) psql -U postgres -d postgres < supabase/migrations/001_init.sql
# Health check
curl http://localhost:8000/health | jq
```

## API
- POST `/search`
  - Body: `{ "query": "lait bleu 2l", "limit": 10 }`
  - Returns: `[{"id": 1, "name": "Blue Milk 2L", "price": 3.49, "store_name": "Store A", "category": "dairy"}, ...]`

## Notes
- Secrets are only on the server. Flutter app calls this API.
- If embeddings are unavailable, the API falls back to trigram fuzzy search.
- Frequent queries are cached in-memory (10 minutes).