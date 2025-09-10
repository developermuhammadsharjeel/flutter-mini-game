# Development Setup Instructions

## Quick Start Guide for Block Blast Enhanced

### 1. Environment Setup
```bash
# Ensure Flutter is installed and up to date
flutter doctor

# If Flutter is not installed, follow: https://flutter.dev/docs/get-started/install
```

### 2. Project Setup
```bash
# Clone the repository
git clone https://github.com/developermuhammadsharjeel/flutter-mini-game.git
cd flutter-mini-game/flutter-mini-game

# Get dependencies
flutter pub get

# Check for any dependency issues
flutter pub deps
```

### 3. Development
```bash
# Run in debug mode (with hot reload)
flutter run

# Run on specific device
flutter devices
flutter run -d <device_id>

# Run with verbose logging
flutter run -v
```

### 4. Testing
```bash
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage

# Run specific test file
flutter test test/game_engine_test.dart

# Generate test coverage report
genhtml coverage/lcov.info -o coverage/html
```

### 5. Building
```bash
# Build APK for testing
flutter build apk --debug

# Build release APK
flutter build apk --release

# Build App Bundle for Play Store
flutter build appbundle --release

# Build for iOS (macOS only)
flutter build ios --release
```

### 6. Code Analysis
```bash
# Run static analysis
flutter analyze

# Format code
dart format lib/ test/

# Fix auto-fixable issues
dart fix --apply
```

### 7. Debugging
```bash
# Enable Flutter Inspector in VS Code/Android Studio
# Or use command line:
flutter inspector

# For performance profiling:
flutter run --profile
```

### 8. Asset Management
```bash
# Current placeholder assets are in:
assets/
├── animations/    # Replace with actual Lottie files
├── sfx/          # Replace with actual sound files
└── images/       # Replace with actual images

# After adding new assets, update pubspec.yaml and run:
flutter pub get
```

### 9. Common Issues & Solutions

#### Issue: Dependencies not resolving
```bash
flutter clean
flutter pub get
```

#### Issue: Build failures
```bash
# Clear Flutter cache
flutter clean
rm -rf ~/.pub-cache

# Reinstall dependencies
flutter pub get
```

#### Issue: Android build issues
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
```

### 10. Performance Tips

- Use `flutter run --profile` for performance testing
- Monitor frame rates with Flutter DevTools
- Use `const` constructors where possible
- Minimize `setState()` calls in widgets
- Use `flutter build apk --analyze-size` to analyze APK size

### 11. Project Structure Notes

The project follows clean architecture principles:

- `lib/game/` - Core game logic (business logic)
- `lib/screens/` - UI screens (presentation layer)
- `lib/widgets/` - Reusable UI components
- `lib/utils/` - Utility classes and helpers
- `test/` - Unit and widget tests

### 12. State Management (Riverpod)

Key providers:
- `gameEngineProvider` - Main game state
- `settingsProvider` - App settings
- `highScoreProvider` - Score persistence

### 13. Next Steps for Enhancement

1. Replace placeholder assets with real content
2. Add Flame particles for visual effects
3. Implement daily challenges
4. Add social features
5. Optimize for different screen sizes
6. Add accessibility features

---

**Happy Coding! 🚀**