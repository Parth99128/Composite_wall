# Composite_wall

## Project Overview

A monorepo containing both the backend server and Flutter mobile app for the Composite Wall CFD analysis tool.

## Project Structure

```
composite-wall/
├── composite-wall-backend-v3/      # Node.js Express API
│   ├── server.js                   # Main server entry point
│   ├── package.json                # Backend dependencies
│   └── .env.example                # Environment template
│
├── flutter-composite-wall-app-v3/  # Flutter mobile application
│   ├── lib/                        # Dart code
│   ├── assets/                     # Images and resources
│   └── pubspec.yaml                # Flutter dependencies
│
└── README.md                       # This file
```

## Backend Deployment (Railway)

### Prerequisites
- Node.js >= 18.0.0
- Railway account

### Local Setup
```bash
cd composite-wall-backend-v3
npm install
npm start
```

### Railway Setup
1. Connect your GitHub repo to Railway
2. Create a new service pointing to the `composite-wall-backend-v3` folder
3. Set environment variables in Railway dashboard (from `.env.example`)
4. Deploy

### Environment Variables
Create a `.env` file based on `.env.example` with:
- Port configuration
- API credentials
- Database URLs

## Flutter App Development

### Prerequisites
- Flutter SDK
- Android Studio / Xcode (for emulator)

### Setup
```bash
cd flutter-composite-wall-app-v3
flutter pub get
flutter run
```

## Key Technologies
- **Backend**: Express.js, Node.js, Google Gemini AI
- **Frontend**: Flutter, Dart
- **Hosting**: Railway (backend)