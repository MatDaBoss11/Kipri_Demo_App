from cachetools import TTLCache

# Cache up to 1000 queries for 10 minutes
query_cache: TTLCache = TTLCache(maxsize=1000, ttl=600)