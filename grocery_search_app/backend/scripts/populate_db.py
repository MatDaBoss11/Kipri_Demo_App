import os
import sys
from pathlib import Path
from dotenv import load_dotenv
from supabase import create_client

# Add parent directory to path
sys.path.append(str(Path(__file__).parent.parent))

# Load environment variables
load_dotenv()

# Sample product data
SAMPLE_PRODUCTS = [
    # Dairy
    {"name": "Blue Milk 2L", "price": 3.99, "store_name": "SuperMart", "category": "Dairy"},
    {"name": "Whole Milk 1L", "price": 2.49, "store_name": "FreshCo", "category": "Dairy"},
    {"name": "Greek Yogurt Plain 500g", "price": 4.99, "store_name": "SuperMart", "category": "Dairy"},
    {"name": "Cheddar Cheese Block 400g", "price": 6.99, "store_name": "FreshCo", "category": "Dairy"},
    {"name": "Unsalted Butter 454g", "price": 5.49, "store_name": "SuperMart", "category": "Dairy"},
    
    # Bread & Bakery
    {"name": "Whole Wheat Bread", "price": 2.99, "store_name": "BakeryPlus", "category": "Bakery"},
    {"name": "White Bread Sliced", "price": 2.49, "store_name": "SuperMart", "category": "Bakery"},
    {"name": "Sourdough Loaf", "price": 4.99, "store_name": "BakeryPlus", "category": "Bakery"},
    {"name": "Croissants 6 Pack", "price": 5.99, "store_name": "BakeryPlus", "category": "Bakery"},
    
    # Fruits
    {"name": "Red Apples 1kg", "price": 3.99, "store_name": "FreshCo", "category": "Fruits"},
    {"name": "Bananas 1kg", "price": 1.99, "store_name": "SuperMart", "category": "Fruits"},
    {"name": "Oranges 2kg Bag", "price": 4.99, "store_name": "FreshCo", "category": "Fruits"},
    {"name": "Strawberries 454g", "price": 5.99, "store_name": "SuperMart", "category": "Fruits"},
    {"name": "Blueberries 125g", "price": 3.99, "store_name": "FreshCo", "category": "Fruits"},
    
    # Vegetables
    {"name": "Tomatoes on Vine 1kg", "price": 4.49, "store_name": "FreshCo", "category": "Vegetables"},
    {"name": "Potatoes 5lb Bag", "price": 3.99, "store_name": "SuperMart", "category": "Vegetables"},
    {"name": "Yellow Onions 3lb", "price": 2.99, "store_name": "FreshCo", "category": "Vegetables"},
    {"name": "Carrots 2lb Bag", "price": 2.49, "store_name": "SuperMart", "category": "Vegetables"},
    {"name": "Broccoli Crown", "price": 2.99, "store_name": "FreshCo", "category": "Vegetables"},
    
    # Meat & Seafood
    {"name": "Chicken Breast Boneless 1kg", "price": 12.99, "store_name": "MeatMaster", "category": "Meat"},
    {"name": "Ground Beef Lean 500g", "price": 7.99, "store_name": "SuperMart", "category": "Meat"},
    {"name": "Pork Chops 4 Pack", "price": 9.99, "store_name": "MeatMaster", "category": "Meat"},
    {"name": "Atlantic Salmon Fillet 500g", "price": 14.99, "store_name": "SeafoodPlus", "category": "Seafood"},
    {"name": "Shrimp Frozen 454g", "price": 11.99, "store_name": "SeafoodPlus", "category": "Seafood"},
    
    # Pantry
    {"name": "Basmati Rice 2kg", "price": 7.99, "store_name": "SuperMart", "category": "Pantry"},
    {"name": "Pasta Spaghetti 500g", "price": 1.99, "store_name": "FreshCo", "category": "Pantry"},
    {"name": "All Purpose Flour 2.5kg", "price": 4.99, "store_name": "SuperMart", "category": "Pantry"},
    {"name": "Granulated Sugar 2kg", "price": 3.49, "store_name": "FreshCo", "category": "Pantry"},
    {"name": "Table Salt 1kg", "price": 1.29, "store_name": "SuperMart", "category": "Pantry"},
    {"name": "Black Pepper Ground 100g", "price": 4.99, "store_name": "FreshCo", "category": "Pantry"},
    {"name": "Olive Oil Extra Virgin 1L", "price": 12.99, "store_name": "SuperMart", "category": "Pantry"},
    
    # Beverages
    {"name": "Coffee Ground Medium Roast 300g", "price": 7.99, "store_name": "CoffeeCo", "category": "Beverages"},
    {"name": "Green Tea Bags 25 Pack", "price": 3.99, "store_name": "SuperMart", "category": "Beverages"},
    {"name": "Orange Juice 1.75L", "price": 4.49, "store_name": "FreshCo", "category": "Beverages"},
    {"name": "Sparkling Water 12 Pack", "price": 5.99, "store_name": "SuperMart", "category": "Beverages"},
    {"name": "Cola 2L", "price": 2.49, "store_name": "FreshCo", "category": "Beverages"},
    
    # Personal Care
    {"name": "Shampoo Anti-Dandruff 400ml", "price": 6.99, "store_name": "PharmacyPlus", "category": "Personal Care"},
    {"name": "Body Wash Moisturizing 500ml", "price": 5.49, "store_name": "SuperMart", "category": "Personal Care"},
    {"name": "Toothpaste Whitening 100ml", "price": 3.99, "store_name": "PharmacyPlus", "category": "Personal Care"},
    {"name": "Toilet Paper 12 Roll", "price": 9.99, "store_name": "SuperMart", "category": "Household"},
    {"name": "Paper Towels 6 Roll", "price": 11.99, "store_name": "FreshCo", "category": "Household"},
]

def populate_database():
    """Populate the database with sample products"""
    # Initialize Supabase client
    supabase_url = os.getenv("SUPABASE_URL")
    supabase_key = os.getenv("SUPABASE_KEY")
    
    if not supabase_url or not supabase_key:
        print("Error: Missing Supabase credentials in environment variables")
        return
    
    client = create_client(supabase_url, supabase_key)
    
    print(f"Populating database with {len(SAMPLE_PRODUCTS)} sample products...")
    
    try:
        # Insert products
        response = client.table('products').insert(SAMPLE_PRODUCTS).execute()
        print(f"Successfully inserted {len(response.data)} products")
    except Exception as e:
        print(f"Error inserting products: {e}")
        return
    
    # Verify insertion
    try:
        count_response = client.table('products').select('*', count='exact').execute()
        print(f"Total products in database: {count_response.count}")
    except Exception as e:
        print(f"Error counting products: {e}")

if __name__ == "__main__":
    populate_database()