import google.generativeai as genai
import os
import logging
from typing import List, Optional
import json

logger = logging.getLogger(__name__)

class GeminiService:
    def __init__(self):
        api_key = os.getenv("GEMINI_API_KEY")
        if not api_key:
            raise ValueError("GEMINI_API_KEY not found in environment variables")
        
        genai.configure(api_key=api_key)
        self.model = genai.GenerativeModel('gemini-pro')
        
        # Sample product names for context (in production, load from database)
        self.product_context = [
            "milk", "bread", "eggs", "butter", "cheese", "yogurt",
            "apple", "banana", "orange", "tomato", "potato", "onion",
            "chicken", "beef", "pork", "fish", "salmon", "tuna",
            "rice", "pasta", "flour", "sugar", "salt", "pepper",
            "coffee", "tea", "juice", "water", "soda", "beer",
            "shampoo", "soap", "toothpaste", "toilet paper",
            "blue milk 2L", "whole wheat bread", "organic eggs",
            "unsalted butter", "cheddar cheese", "greek yogurt"
        ]
    
    async def normalize_query(self, query: str) -> str:
        """
        Normalize user query using Gemini AI for multilingual support
        """
        try:
            prompt = self._build_prompt(query)
            response = await self._generate_response(prompt)
            normalized = self._extract_normalized_query(response)
            
            return normalized or query  # Fallback to original query if normalization fails
            
        except Exception as e:
            logger.error(f"Gemini normalization error: {e}")
            return query  # Return original query on error
    
    def _build_prompt(self, query: str) -> str:
        """Build the prompt for Gemini"""
        product_list = ", ".join(self.product_context[:50])  # Use top 50 products
        
        return f"""You are a product search normalizer for a grocery store app. 
Your task is to understand the user's search query in any language and normalize it to the closest matching product name in English.

Available product examples: {product_list}

Instructions:
1. Translate the query to English if it's in another language
2. Fix any spelling mistakes
3. Normalize to the most likely product name
4. Return ONLY the normalized product name, nothing else
5. If unsure, return the closest match

User query: "{query}"

Normalized query:"""
    
    async def _generate_response(self, prompt: str) -> str:
        """Generate response from Gemini"""
        response = self.model.generate_content(prompt)
        return response.text.strip()
    
    def _extract_normalized_query(self, response: str) -> Optional[str]:
        """Extract and clean the normalized query from Gemini response"""
        # Remove quotes and extra whitespace
        normalized = response.strip().strip('"\'').strip()
        
        # Validate response (should be relatively short)
        if len(normalized) > 100:
            logger.warning(f"Gemini response too long: {normalized}")
            return None
        
        return normalized
    
    async def get_product_suggestions(self, partial_query: str, limit: int = 5) -> List[str]:
        """Get product suggestions for autocomplete"""
        try:
            prompt = f"""Given the partial search query "{partial_query}", 
suggest up to {limit} likely product names the user might be searching for.
Return as a comma-separated list.

Suggestions:"""
            
            response = await self._generate_response(prompt)
            suggestions = [s.strip() for s in response.split(',')]
            return suggestions[:limit]
            
        except Exception as e:
            logger.error(f"Failed to get suggestions: {e}")
            return []