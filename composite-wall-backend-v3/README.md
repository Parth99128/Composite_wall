# Composite Wall CFD — Backend v3
### Pentas Insulations Pvt Ltd | Powered by Google Gemini FREE

---

## 🆓 Free AI Setup (2 minutes)

1. Go to **https://aistudio.google.com/app/apikey**
2. Sign in with any **free Google account** — no credit card needed
3. Click **"Create API Key"** → copy the key
4. Add to your `.env` file:
   ```
   GEMINI_API_KEY=AIza...your-key-here
   ```

**Free tier limits:** 15 requests/min · 1,000,000 tokens/day · $0/month

---

## 🚀 Quick Start

```bash
cp .env.example .env
# Paste your Gemini API key into .env

npm install
npm start
```

Server: **http://localhost:3000**

---

## 📡 API Endpoints

### Core
| Method | Route | Description |
|--------|-------|-------------|
| GET | `/` | Service info + AI status |
| GET | `/api/materials` | List all materials |
| POST | `/api/materials` | Add material |
| PUT | `/api/materials/:id` | Update material |
| DELETE | `/api/materials/:id` | Delete material |
| GET | `/api/boundary-conditions` | Get BCs |
| PUT | `/api/boundary-conditions` | Update BCs |
| POST | `/api/calculate` | Run analysis |
| POST | `/api/calculate/custom` | Custom analysis |

### AI (Google Gemini FREE)
| Method | Route | Description |
|--------|-------|-------------|
| GET | `/api/ai/status` | Check if AI is configured |
| POST | `/api/ai/insight` | Engineering analysis of results |
| POST | `/api/ai/chat` | Conversational assistant (with history) |
| POST | `/api/ai/suggest-materials` | Improvement suggestions |
| POST | `/api/ai/optimize` | Optimal wall for target parameters |
| POST | `/api/ai/explain` | Explain a specific parameter |

---

## 🚢 Deploy for Free

### Option 1: Railway (Recommended)
1. Push to GitHub
2. Go to **railway.app** → New Project → Deploy from GitHub
3. Add environment variable: `GEMINI_API_KEY=AIza...`
4. Done! Get URL like `https://composite-wall.up.railway.app`

### Option 2: Render (Free tier)
1. Go to **render.com** → New Web Service → connect repo
2. Build: `npm install` | Start: `node server.js`
3. Add `GEMINI_API_KEY` in Environment tab

### Option 3: Local network (for testing)
```bash
npm start
# Find your IP: ifconfig (Mac/Linux) or ipconfig (Windows)
# Update Flutter app: kBackendBaseUrl = 'http://192.168.X.X:3000'
```

---

## 🔧 After Deploying Backend

Update Flutter app's `lib/services/api_service.dart` line 1:
```dart
const String kBackendBaseUrl = 'https://your-app.up.railway.app';
```
