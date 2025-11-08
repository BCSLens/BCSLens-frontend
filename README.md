# BCS Lens - Frontend Application

[![Flutter Tests](https://github.com/YOUR_USERNAME/YOUR_REPO/actions/workflows/flutter_tests.yml/badge.svg)](https://github.com/YOUR_USERNAME/YOUR_REPO/actions/workflows/flutter_tests.yml)

A Flutter mobile application for Body Condition Score (BCS) evaluation of pets using AI-powered image analysis.

## 📱 Overview

BCS Lens helps pet owners and experts evaluate their pets' body condition scores (1-9 scale) through:
- **AI-Powered Detection**: Automatic species and view classification
- **BCS Evaluation**: AI-based body condition score prediction
- **Health Tracking**: Record and track pet health history over time
- **Care Recommendations**: Species-specific health recommendations based on BCS

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (3.32.5 or higher)
- Dart SDK
- iOS Simulator / Android Emulator or physical device

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd BCS-L/BCSLens-frontend
```

2. Install dependencies:
```bash
flutter pub get
```

3. Configure environment variables:
   - Create a `.env` file in the root directory
   - Add your API base URL:
   ```
   API_BASE_URL=http://your-api-url/api
   UPLOAD_BASE_URL=http://your-upload-url
   ```

4. Run the application:
```bash
flutter run
```

## 🧪 Testing

This project includes comprehensive automated tests covering 54 test cases.

**CI/CD Status**: Tests run automatically on every push and pull request via GitHub Actions. Check the [Actions tab](https://github.com/YOUR_USERNAME/YOUR_REPO/actions) to see test results.

### Run All Tests

```bash
# Using the test runner script (recommended)
./test_runner.sh

# Or manually
flutter test --coverage
```

### Test Coverage

- **Login Tests**: 3 test cases
- **Records Dashboard Tests**: 9 test cases
- **Add Record Flow Tests**: 12 test cases
- **Review & Confirm Tests**: 3 test cases
- **History Screen Tests**: 6 test cases
- **Special Care Screen Tests**: 6 test cases
- **Profile Screen Tests**: 5 test cases
- **General System Tests**: 4 test cases
- **Widget Tests**: 1 test case

**Total: 54 automated test cases**

For detailed testing instructions, see [HOW_TO_RUN_TESTS.md](HOW_TO_RUN_TESTS.md).

## 📁 Project Structure

```
lib/
├── config/          # App configuration and themes
├── models/          # Data models
├── screens/         # UI screens
├── services/        # API and business logic services
└── widgets/         # Reusable UI components

test/                # Automated test files
test_logs/           # Test execution logs
```

## 🔧 Key Features

- **Portrait-Only Orientation**: Locked to portrait mode for consistent UX
- **AI Integration**: YOLO-based pet detection and BCS evaluation
- **Real-time Health Tracking**: Monitor pet health trends over time
- **User Authentication**: Secure login and profile management
- **Group Management**: Organize pets into groups

## 📝 Documentation

- [HOW_TO_RUN_TESTS.md](HOW_TO_RUN_TESTS.md) - Testing guide and instructions
- [CI_CD_GUIDE.md](CI_CD_GUIDE.md) - GitHub Actions CI/CD setup and usage

## 🤝 Contributing

1. Create a feature branch
2. Make your changes
3. Run tests: `./test_runner.sh`
4. Commit and push your changes
5. Create a pull request

## 📄 License

[Add your license information here]

## 👥 Authors

[Add author information here]
