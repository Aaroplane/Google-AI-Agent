# Google-AI-Agent

## Setup Instructions

### 1. Install Dependencies
```bash
python3 -m venv .venv
source .venv/bin/activate  # On Windows: .venv\Scripts\activate
pip install -r requirements.txt
```

### 2. Configure API Key (Security Important)
1. Copy `.env.example` to `.env`:
   ```bash
   cp .env.example .env
   ```
2. Get your Google Gemini API key from [Google Cloud Console](https://console.cloud.google.com/apis/credentials)
3. Add your key to `.env`:
   ```
   GOOGLE_API_KEY=your_actual_key_here
   ```
4. **NEVER commit `.env` to git** (it's in `.gitignore` for security)

### 3. Run the API Test
```bash
python API_test.py
```

## Security Notes
- ⚠️ **Never commit `.env` files** with real credentials
- ⚠️ **Keep API keys private** — rotate them if exposed
- ⚠️ **Use `.env.example`** to document required variables
- ⚠️ **Enable API rate limiting** in Google Cloud Console to prevent abuse

