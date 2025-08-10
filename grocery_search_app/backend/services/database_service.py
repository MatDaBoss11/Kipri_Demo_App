import os
import logging
from typing import List, Dict, Any, Optional
from supabase import create_client, Client
from rapidfuzz import fuzz, process
import asyncio

logger = logging.getLogger(__name__)

class DatabaseService:
    def __init__(self):
        self.supabase_url = os.getenv("SUPABASE_URL")
        self.supabase_key = os.getenv("SUPABASE_KEY")
        
        if not self.supabase_url or not self.supabase_key:
            raise ValueError("Supabase credentials not found in environment variables")
        
        self.client: Optional[Client] = None
        self._product_cache: List[Dict[str, Any]] = []
        self._cache_loaded = False
    
    async def connect(self):
        """Initialize Supabase connection"""
        try:
            self.client = create_client(self.supabase_url, self.supabase_key)
            await self._load_product_cache()
            logger.info("Connected to Supabase successfully")
        except Exception as e:
            logger.error(f"Failed to connect to Supabase: {e}")
            raise
    
    async def disconnect(self):
        """Cleanup connection"""
        # Supabase client doesn't need explicit disconnection
        pass
    
    async def _load_product_cache(self):
        """Load all products into memory for fuzzy searching"""
        try:
            response = self.client.table('products').select('*').execute()
            self._product_cache = response.data
            self._cache_loaded = True
            logger.info(f"Loaded {len(self._product_cache)} products into cache")
        except Exception as e:
            logger.error(f"Failed to load product cache: {e}")
            self._product_cache = []
    
    async def search_products(self, query: str, limit: int = 20) -> List[Dict[str, Any]]:
        """
        Search products using fuzzy matching
        """
        if not self._cache_loaded:
            await self._load_product_cache()
        
        if not query:
            return []
        
        try:
            # Prepare product names for fuzzy matching
            product_names = [(p['name'], p) for p in self._product_cache]
            
            # Perform fuzzy search
            results = process.extract(
                query,
                [name for name, _ in product_names],
                scorer=fuzz.token_sort_ratio,
                limit=limit
            )
            
            # Get products that match above threshold
            threshold = 60  # Minimum similarity score
            matched_products = []
            
            for match, score, idx in results:
                if score >= threshold:
                    product = product_names[idx][1]
                    matched_products.append({
                        'id': product['id'],
                        'name': product['name'],
                        'price': product['price'],
                        'store_name': product.get('store_name', 'Unknown Store'),
                        'category': product.get('category'),
                        'image_url': product.get('image_url'),
                        'similarity_score': score
                    })
            
            # Sort by similarity score (highest first)
            matched_products.sort(key=lambda x: x['similarity_score'], reverse=True)
            
            # Remove similarity score from results
            for product in matched_products:
                del product['similarity_score']
            
            return matched_products
            
        except Exception as e:
            logger.error(f"Search error: {e}")
            return []
    
    async def get_product_by_id(self, product_id: str) -> Optional[Dict[str, Any]]:
        """Get a single product by ID"""
        try:
            response = self.client.table('products').select('*').eq('id', product_id).execute()
            if response.data:
                return response.data[0]
            return None
        except Exception as e:
            logger.error(f"Failed to get product {product_id}: {e}")
            return None
    
    async def get_popular_products(self, limit: int = 20) -> List[Dict[str, Any]]:
        """Get popular/featured products"""
        try:
            # In a real app, you might have a 'popularity' field or order by sales
            response = self.client.table('products').select('*').limit(limit).execute()
            return response.data
        except Exception as e:
            logger.error(f"Failed to get popular products: {e}")
            return []
    
    async def get_products_by_category(self, category: str, limit: int = 50) -> List[Dict[str, Any]]:
        """Get products by category"""
        try:
            response = self.client.table('products').select('*').eq('category', category).limit(limit).execute()
            return response.data
        except Exception as e:
            logger.error(f"Failed to get products by category: {e}")
            return []
    
    async def refresh_cache(self):
        """Manually refresh the product cache"""
        await self._load_product_cache()