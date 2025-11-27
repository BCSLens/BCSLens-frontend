# BCS Lens – Flutter Frontend

[Security Report (Google Doc)](https://docs.google.com/document/d/1RtrmbFcaiZi72WzOgnSiMr-Jw3lnkgoW9ZzoYCQyq9g/edit?usp=sharing)

BCS Lens is a portrait-only Flutter app that helps pet owners and veterinary experts capture multi-angle photos, run AI-powered body condition scoring (BCS 1‑9), and manage health records.

---

## 📋 At a Glance

| Topic | Details |
| --- | --- |
| **Target platforms** | Android, iOS, Web (Flutter stable 3.35.0) |
| **Primary stack** | Flutter, Riverpod/Provider (state), REST APIs, Google Sign-In |
| **Security** | Tokens stored via `flutter_secure_storage`, session auto-logout, dotenv-managed secrets |
| **CI/CD** | GitHub Actions (`flutter_tests.yml`, `security-scan.yml`) run analyzer, tests, and dependency audits on each push/PR |

---

## 🗂 Project Structure

```
BCSLens-frontend/
├── lib/
│   ├── config/         Theme + localization
│   ├── models/         DTOs & parsing helpers
│   ├── navigation/     Global navigator & dialogs
│   ├── screens/        Feature screens (records, history, etc.)
│   ├── services/       API, auth, secure storage, AI calls
│   └── widgets/        Reusable UI components
├── test/               Widget/unit tests
├── test_logs/          CI + local analyzer/test logs
├── .github/workflows/  Flutter tests & security scans
└── README.md
```

---

## ✅ Prerequisites

- macOS/Linux/Windows with Flutter **3.35.0** (includes Dart ≥ 3.7.2)
- Android Studio or Xcode command-line tools
- `fvm` (optional but recommended) to lock Flutter version
- Access to backend API + AI service endpoints

---

## ⚙️ Setup & Run

1. **Clone the repo**
   ```bash
   git clone <repo-url>
   cd BCS-L/BCSLens-frontend
   ```

2. **Install Flutter dependencies**
   ```bash
   fvm flutter pub get
   ```

3. **Configure environment variables**  
   Create a file named `.env` in the project root (same level as `pubspec.yaml`).  
   Use the table below to fill in the required values:

   | Key | Description |
   | --- | --- |
   | `API_BASE_URL` | Base REST URL for authenticated API calls (`https://<backend-host>/api`) |
   | `UPLOAD_BASE_URL` | Direct file-serving URL for pet images (`https://<backend-host>/api/upload`) |
   | `AI_SERVICE_BASE_URL` | Endpoint for the AI detection/BCS microservice |
   | `GOOGLE_CLIENT_ID` | Google OAuth **Web** client ID used by `google_sign_in` |

   > **Important:** `.env` is ignored by Git. Add a `.env.example` for teammates if needed.

4. **Run (device or emulator)**
   ```bash
   fvm flutter run
   ```

5. **Run on Web (optional)**
   ```bash
   fvm flutter run -d chrome --web-port 8080
   ```

---

## 🔐 Security Considerations

- Access/refresh tokens are stored in `flutter_secure_storage`; legacy `SharedPreferences` data migrates on first launch.
- When the backend reports “expired or invalid refresh token,” the app forces logout and shows a themed modal.
- Environment secrets (`.env`) are never committed; CI creates a dummy `.env` for analyzer/tests.
- GitHub Actions `security-scan.yml` runs `flutter analyze`, `dart analyze`, `dart pub audit`, and publishes a consolidated report artifact.

---

## 🧪 Testing & QA

| Command | Purpose |
| --- | --- |
| `fvm flutter analyze` | Static analysis & linting |
| `fvm dart analyze` | Additional analyzer checks (fatal infos enabled in CI) |
| `fvm flutter test --coverage` | Run widget + unit tests |
| `./test_runner.sh` | Convenience wrapper (filters + logging) |

Automated coverage: 54 test cases covering login, record flows, history, special care, profile, and widgets. See [HOW_TO_RUN_TESTS.md](HOW_TO_RUN_TESTS.md) for scenario mapping and [CI_CD_GUIDE.md](CI_CD_GUIDE.md) for workflow details.

---

## ✨ Key Features

- Multi-angle capture workflow (front/back/left/right/top)
- AI-assisted species/view detection + BCS score prediction
- Record history with charts + care recommendations
- Google Sign-In + traditional auth with auto token refresh
- Secure image delivery with authenticated `Image.network`
- Session-expiry modal + root navigator for global routing

---

## 🧰 Useful Scripts

```bash
fvm flutter pub get          # Install deps with version pin
fvm flutter analyze          # Analyzer with fvm
fvm dart run build_runner    # (If using code generation)
./scripts/clean.sh           # Example cleanup script (if present)
```

---

## 🤝 Contributing

1. Fork / create feature branch
2. Keep `.env` local; never commit secrets
3. Run `fvm flutter analyze` + `fvm flutter test`
4. Open a PR with screenshots/logs if the feature touches UI or auth flows

---

## 📄 License & Authors

- License: _Add your license text or link here_
- Maintainers: _Add team/contact information here_

---

Need help? Check the issues tab or contact the mobile team on your project board. Happy coding! 🐾
