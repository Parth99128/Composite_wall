# Composite Wall CFD — Flutter Mobile App
### Pentas Insulations Pvt Ltd | v2.0 with AI Features

---

## 📱 Screens

| Screen | Features |
|--------|----------|
| **Dashboard** | Live analysis, wall schematic, temperature chart, layer cards, resistance breakdown, AI insight card |
| **Materials** | Full CRUD, color picker, API sync, offline fallback |
| **AI Assistant** | Chat-based thermal engineering assistant powered by Claude |
| **Settings** | Boundary conditions, derived parameter preview, real-time sync |

---

## ✨ AI Features

- **Auto AI Insight** — after every calculation, Claude analyzes results
- **AI Engineering Chat** — ask anything about insulation, CFD, materials
- **Quick Suggestions** — tap pre-built questions for instant answers
- **Fallback heuristics** — works offline with smart rule-based responses

---

## 🚀 Setup

### Prerequisites
- Flutter SDK 3.0+: https://docs.flutter.dev/get-started/install
- Android Studio or VS Code with Flutter plugin

### Run
```bash
flutter pub get
flutter run
```

### Connect to Backend
Edit `lib/services/api_service.dart`:
```dart
const String kBackendBaseUrl = 'http://192.168.X.X:3000'; // local dev
// OR
const String kBackendBaseUrl = 'https://your-api.railway.app'; // production
```

> App works **fully offline** — built-in thermal engine runs locally.

---

## 📦 Build APK

```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

## Build iOS
```bash
flutter build ios --release
# Requires Xcode + Apple Developer Account
```

## Build for Play Store
```bash
flutter build appbundle --release
```

---

## 🗂 Project Structure

```
lib/
├── main.dart                     # App entry + navigation shell
├── theme/
│   └── app_theme.dart            # Colors, typography, design tokens
├── models/
│   └── models.dart               # WallMaterial, BoundaryConditions, results
├── services/
│   └── api_service.dart          # Backend API client (Dio)
├── utils/
│   └── thermal_engine.dart       # Offline CFD engine + AI prompt builder
├── widgets/
│   ├── common_widgets.dart       # MetricCard, GradientButton, AiInsightCard, etc.
│   └── wall_schematic.dart       # Wall diagram, thermal gradient strip
└── screens/
    ├── dashboard_screen.dart     # Main analysis dashboard
    ├── materials_screen.dart     # Material library CRUD
    ├── ai_assistant_screen.dart  # Claude-powered chat
    └── settings_screen.dart      # Boundary conditions
```

---

## 🎨 Design System

- **Font**: Space Grotesk (headings) + Inter (body) + JetBrains Mono (data)
- **Theme**: Dark — deep navy `#080D1A` backgrounds
- **Accent**: Thermal orange `#FF6B35` (primary), Cyan `#00D4FF` (AI)
- **Animations**: flutter_animate — fade, slide, shimmer loading states
- **Charts**: fl_chart for temperature profile visualization

 
