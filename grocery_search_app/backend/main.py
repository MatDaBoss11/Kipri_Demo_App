from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional
import os
from dotenv import load_dotenv
import logging

from services.gemini_service import GeminiService
from services.database_service import DatabaseService
from services.cache_service import CacheService
from models.product import Product

# Load environment variables
load_dotenv()

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize FastAPI app
app = FastAPI(title="Grocery Search API", version="1.0.0")

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, specify your Flutter app's URL
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize services
gemini_service = GeminiService()
db_service = DatabaseService()
cache_service = CacheService()

# Request/Response models
class SearchRequest(BaseModel):
    query: str

class SearchResponse(BaseModel):
    products: List[dict]

@app.on_event("startup")
async def startup_event():
    """Initialize connections on startup"""
    try:
        await db_service.connect()
        await cache_service.connect()
        logger.info("All services initialized successfully")
    except Exception as e:
        logger.error(f"Failed to initialize services: {e}")

@app.on_event("shutdown")
async def shutdown_event():
    """Clean up connections on shutdown"""
    await db_service.disconnect()
    await cache_service.disconnect()

@app.get("/")
async def root():
    """Health check endpoint"""
    return {"status": "healthy", "service": "Grocery Search API"}

@app.post("/search", response_model=SearchResponse)
async def search_products(request: SearchRequest):
    """
    Search for products using AI-powered multilingual query understanding
    """
    try:
        query = request.query.strip()
        
        if not query:
            return SearchResponse(products=[])
        
        # Check cache first
        cached_results = await cache_service.get_cached_results(query)
        if cached_results:
            logger.info(f"Cache hit for query: {query}")
            return SearchResponse(products=cached_results)
        
        # Get normalized query from Gemini
        normalized_query = await gemini_service.normalize_query(query)
        logger.info(f"Normalized query: '{query}' -> '{normalized_query}'")
        
        # Search database with normalized query
        products = await db_service.search_products(normalized_query)
        
        # Cache the results
        await cache_service.cache_results(query, products)
        
        return SearchResponse(products=products)
        
    except Exception as e:
        logger.error(f"Search error: {e}")
        raise HTTPException(status_code=500, detail="Search service temporarily unavailable")

@app.get("/products/popular")
async def get_popular_products():
    """Get popular/featured products"""
    try:
        products = await db_service.get_popular_products(limit=20)
        return {"products": products}
    except Exception as e:
        logger.error(f"Failed to get popular products: {e}")
        raise HTTPException(status_code=500, detail="Failed to fetch products")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        app,
        host=os.getenv("API_HOST", "0.0.0.0"),
        port=int(os.getenv("API_PORT", 8000))
    )