# AI-Powered Multilingual Grocery Search App

A Flutter mobile app with a FastAPI backend that provides intelligent, multilingual search capabilities for grocery products using Google Gemini AI.

## Features

- 🌍 **Multilingual Search**: Search in any language - the AI translates and normalizes queries
- 🔍 **Fuzzy Search**: Handles misspellings and variations in product names
- ⚡ **Fast Response**: Sub-1.5 second search results with Redis caching
- 🎨 **Modern UI**: Beautiful, responsive Flutter interface
- 🔐 **Secure**: API keys stored securely on backend only

## Architecture

```
┌─────────────────┐
│  Flutter App    │
│  (Frontend)     │
└────────┬────────┘
         │ HTTPS
         ▼
┌─────────────────┐
│  FastAPI        │
│  (Backend)      │
├─────────────────┤
│ • Gemini AI     │
│ • Fuzzy Search  │
│ • Redis Cache   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   Supabase      │
│  (PostgreSQL)   │
└─────────────────┘
```

## Setup Instructions

### Prerequisites

- Flutter SDK (3.0+)
- Python 3.8+
- Redis (optional, for caching)
- Supabase account
- Google Gemini API key

### Backend Setup

1. Navigate to the backend directory:
   ```bash
   cd backend
   ```

2. Create a virtual environment:
   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

3. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```

4. Create `.env` file from `.env.example`:
   ```bash
   cp .env.example .env
   ```

5. Update `.env` with your credentials:
   - `GEMINI_API_KEY`: Your Google Gemini API key
   - `SUPABASE_URL`: Your Supabase project URL
   - `SUPABASE_KEY`: Your Supabase anon key

6. Set up your Supabase database with a `products` table:
   ```sql
   CREATE TABLE products (
     id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
     name TEXT NOT NULL,
     price DECIMAL(10,2) NOT NULL,
     store_name TEXT NOT NULL,
     category TEXT,
     image_url TEXT,
     created_at TIMESTAMP DEFAULT NOW()
   );
   ```

7. Run the backend:
   ```bash
   uvicorn main:app --reload
   ```

### Flutter App Setup

1. Navigate to the Flutter app directory:
   ```bash
   cd flutter_app
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Update the API URL in `lib/services/search_service.dart`:
   ```dart
   static const String _baseUrl = 'http://your-backend-url:8000';
   ```

4. Run the app:
   ```bash
   flutter run
   ```

## API Endpoints

### POST /search
Search for products with multilingual support.

**Request:**
```json
{
  "query": "lait bleu 2l"
}
```

**Response:**
```json
{
  "products": [
    {
      "id": "123",
      "name": "Blue Milk 2L",
      "price": 3.99,
      "store_name": "SuperMart",
      "category": "Dairy",
      "image_url": "https://..."
    }
  ]
}
```

### GET /products/popular
Get popular/featured products.

## Configuration

### Performance Optimization

1. **Caching**: Redis caches search results for 1 hour
2. **Product Cache**: All products loaded in memory for fast fuzzy searching
3. **Debouncing**: Search queries debounced by 500ms in Flutter

### Security

- API keys stored only on backend
- CORS configured for production domains
- Environment variables for sensitive data

## Development

### Adding New Features

1. **New Search Algorithms**: Modify `services/database_service.py`
2. **AI Prompt Tuning**: Update prompts in `services/gemini_service.py`
3. **UI Components**: Add widgets in `flutter_app/lib/widgets/`

### Testing

Backend:
```bash
pytest tests/
```

Flutter:
```bash
flutter test
```

## Deployment

### Backend (using Docker)

```dockerfile
FROM python:3.9
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

### Flutter (Android/iOS)

```bash
flutter build apk --release  # Android
flutter build ios --release  # iOS
```

## License

MIT License - see LICENSE file for details