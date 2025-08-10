import os
import json
import logging
from typing import List, Dict, Any, Optional
import aioredis
from datetime import timedelta

logger = logging.getLogger(__name__)

class CacheService:
    def __init__(self):
        self.redis_host = os.getenv("REDIS_HOST", "localhost")
        self.redis_port = int(os.getenv("REDIS_PORT", 6379))
        self.redis_db = int(os.getenv("REDIS_DB", 0))
        self.redis_client: Optional[aioredis.Redis] = None
        self.cache_ttl = timedelta(hours=1)  # Cache for 1 hour
        self.enabled = True  # Can be disabled if Redis is not available
    
    async def connect(self):
        """Initialize Redis connection"""
        try:
            self.redis_client = await aioredis.create_redis_pool(
                f'redis://{self.redis_host}:{self.redis_port}/{self.redis_db}',
                encoding='utf-8'
            )
            logger.info("Connected to Redis successfully")
        except Exception as e:
            logger.warning(f"Failed to connect to Redis: {e}. Caching disabled.")
            self.enabled = False
    
    async def disconnect(self):
        """Close Redis connection"""
        if self.redis_client:
            self.redis_client.close()
            await self.redis_client.wait_closed()
    
    def _get_cache_key(self, query: str) -> str:
        """Generate cache key for a query"""
        # Normalize the query for caching
        normalized = query.lower().strip()
        return f"search:{normalized}"
    
    async def get_cached_results(self, query: str) -> Optional[List[Dict[str, Any]]]:
        """Get cached search results"""
        if not self.enabled or not self.redis_client:
            return None
        
        try:
            key = self._get_cache_key(query)
            cached_data = await self.redis_client.get(key)
            
            if cached_data:
                return json.loads(cached_data)
            
            return None
        except Exception as e:
            logger.error(f"Cache get error: {e}")
            return None
    
    async def cache_results(self, query: str, results: List[Dict[str, Any]]):
        """Cache search results"""
        if not self.enabled or not self.redis_client:
            return
        
        try:
            key = self._get_cache_key(query)
            data = json.dumps(results)
            
            # Set with expiration
            await self.redis_client.setex(
                key,
                int(self.cache_ttl.total_seconds()),
                data
            )
            
            # Also maintain a list of recent searches
            await self._add_to_recent_searches(query)
            
        except Exception as e:
            logger.error(f"Cache set error: {e}")
    
    async def _add_to_recent_searches(self, query: str):
        """Maintain a list of recent searches for analytics"""
        try:
            key = "recent_searches"
            await self.redis_client.lpush(key, query)
            # Keep only last 1000 searches
            await self.redis_client.ltrim(key, 0, 999)
        except Exception as e:
            logger.error(f"Failed to add to recent searches: {e}")
    
    async def get_recent_searches(self, limit: int = 10) -> List[str]:
        """Get recent search queries"""
        if not self.enabled or not self.redis_client:
            return []
        
        try:
            searches = await self.redis_client.lrange("recent_searches", 0, limit - 1)
            return searches
        except Exception as e:
            logger.error(f"Failed to get recent searches: {e}")
            return []
    
    async def clear_cache(self):
        """Clear all cached data"""
        if not self.enabled or not self.redis_client:
            return
        
        try:
            await self.redis_client.flushdb()
            logger.info("Cache cleared successfully")
        except Exception as e:
            logger.error(f"Failed to clear cache: {e}")
    
    async def get_cache_stats(self) -> Dict[str, Any]:
        """Get cache statistics"""
        if not self.enabled or not self.redis_client:
            return {"enabled": False}
        
        try:
            info = await self.redis_client.info()
            return {
                "enabled": True,
                "keys": await self.redis_client.dbsize(),
                "memory_used": info.get("used_memory_human", "Unknown"),
                "hits": info.get("keyspace_hits", 0),
                "misses": info.get("keyspace_misses", 0)
            }
        except Exception as e:
            logger.error(f"Failed to get cache stats: {e}")
            return {"enabled": False, "error": str(e)}