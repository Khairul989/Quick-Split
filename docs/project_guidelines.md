# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Quicksplit** is a Flutter-based mobile/web application for fast receipt bill-splitting using OCR technology. The goal is to enable users to split bills among multiple people within 30-40 seconds using camera-based receipt scanning.

**Current Status:** Early-stage boilerplate (Phase 0). No core features implemented yet.

**Tech Stack:**

- Flutter (Dart ^3.9.2)
- Planned: Riverpod (state management), GoRouter (navigation), Hive (local storage), Google ML Kit (OCR), share_plus (sharing)

## Common Commands

### Development

```bash
# Install dependencies
flutter pub get

# Run the app (defaults to first available device)
flutter run

# Run on specific platform
flutter run -d chrome          # Web
flutter run -d macos           # macOS
flutter run -d ios             # iOS simulator
flutter run -d android         # Android emulator

# Hot reload is enabled by default - press 'r' in terminal
# Hot restart - press 'R' in terminal
```

### Code Quality

```bash
# Run static analysis
flutter analyze

# Format code
flutter format lib/

# Format specific file
flutter format lib/main.dart
```

### Testing

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/widget_test.dart

# Run tests with coverage
flutter test --coverage
```

### Building

```bash
# Build for production (Android APK)
flutter build apk

# Build for production (iOS - requires macOS + Xcode)
flutter build ios

# Build for web
flutter build web

# Build for macOS
flutter build macos

# Clean build artifacts
flutter clean
```

### Dependencies

```bash
# Add a new dependency
flutter pub add package_name

# Add a dev dependency
flutter pub add --dev package_name

# Update dependencies
flutter pub upgrade

# Check for outdated packages
flutter pub outdated
```

## Planned Architecture

The codebase will follow a feature-based modular architecture:

```
lib/
  core/                    # Shared utilities and infrastructure
    utils/                 # Helper functions, extensions
    widgets/               # Reusable UI components
    services/              # Business logic services
    error/                 # Error handling utilities
    theme/                 # App theming (Material theme, dark mode)

  features/                # Feature modules (each self-contained)
    scan/                  # Camera capture and image selection
    ocr/                   # ML Kit text recognition pipeline
    items/                 # Receipt item management and editing
    assign/                # Person-to-item assignment logic
    groups/                # Group and people management
    history/               # Historical split records
```

### State Management Pattern

- **Riverpod** will be used for state management
- Providers should be defined within each feature module
- Hooks (`hooks_riverpod`) for stateful widget logic
- Follow functional reactive programming patterns

### Navigation Pattern

- **GoRouter** for declarative routing
- Route definitions should be centralized in `core/`
- Deep linking support for sharing split sessions

### Data Persistence Pattern

- **Hive** for local NoSQL storage
- Offline-first architecture
- Store: frequent groups, contact preferences, split history
- No cloud sync in MVP (planned for Phase 7)

### OCR Processing Pipeline

1. Image input (camera/gallery) → `scan/`
2. ML Kit text recognition → `ocr/`
3. Parse text blocks into structured items (name, quantity, price)
4. Manual editing UI → `items/`
5. Tax/service charge detection (SST, service charge, rounding)

### UI/UX Principles

- Target flow completion: ≤ 40 seconds (scan → assign → share)
- Material Design with seed color (deepPurple currently)
- Dark mode support (Phase 5)
- Empty states for each module
- Loading states during OCR processing

## Key Development Notes

### Current File Structure

- Entry point: [lib/main.dart](lib/main.dart) (boilerplate counter app)
- Single test: [test/widget_test.dart](test/widget_test.dart)
- Configuration: [pubspec.yaml](pubspec.yaml)
- Linting: [analysis_options.yaml](analysis_options.yaml) (uses `flutter_lints`)

### Platform Support

This project targets **7 platforms**: Android, iOS, macOS, Windows, Linux, Web, and Flutter Test.

**Platform-specific code locations:**

- Android: [android/](android/) (Gradle + Kotlin)
- iOS: [ios/](ios/) (Xcode + Swift)
- macOS: [macos/](macos/) (CMake)
- Windows: [windows/](windows/) (CMake)
- Linux: [linux/](linux/) (CMake)
- Web: [web/](web/) (PWA manifest + service worker)

### Dependencies to Add (Per Feature Blueprint)

When implementing features, add these dependencies to [pubspec.yaml](pubspec.yaml):

**Phase 1 (Core Foundations):**

```yaml
dependencies:
  riverpod: ^latest
  hooks_riverpod: ^latest
  go_router: ^latest
  hive: ^latest
  hive_flutter: ^latest
```

**Phase 2 (OCR Pipeline):**

```yaml
dependencies:
  google_mlkit_text_recognition: ^latest
  camera: ^latest
  image_picker: ^latest
```

**Phase 4 (Export & Share):**

```yaml
dependencies:
  share_plus: ^latest
```

### Code Style & Linting

- Follows `flutter_lints` package rules (strict mode)
- Use `flutter analyze` before committing
- Format code with `flutter format` before PRs
- Suppress specific lints with `// ignore: rule_name` sparingly

### Testing Strategy

- Widget tests for UI components
- Unit tests for business logic (calculator, OCR parsing)
- Integration tests for complete flows (scan → assign → export)
- Use `WidgetTester` for gesture simulation (taps, swipes)

### Performance Targets

- OCR processing: ≤ 5 seconds
- UI responsiveness: 60 FPS (no jank during assignment)
- App startup: ≤ 2 seconds cold start

### Critical User Flow (30-40 Second Goal)

1. **Scan** (5-10s): Camera capture or gallery import
2. **OCR** (5s): ML Kit processing + parsing
3. **Edit** (5-10s): Quick item verification/edits
4. **Assign** (10-15s): Tap items → assign people
5. **Export** (5s): Generate summary → share to WhatsApp

### Sharing Format (WhatsApp Output)

```
Dinner Bill 🍽️
Total: RM 122.70

Khairul: RM 28.40
Aiman: RM 41.30
Syafiq: RM 53.00

Pay Khairul:
https://pay.duitnow.com/XXXXXX
```

### Development Phases (See [docs/App Feature Blueprint.md](docs/App Feature Blueprint.md))

- **Phase 0:** Setup (CURRENT - boilerplate only)
- **Phase 1:** Architecture + routing + state management
- **Phase 2:** OCR pipeline (camera, ML Kit, parsing)
- **Phase 3:** Assignment engine (people, items, calculator)
- **Phase 4:** Export & share (summary, WhatsApp, history)
- **Phase 5:** Polishing (dark mode, animations, UX)
- **Phase 6:** Growth (link sharing, templates)
- **Phase 7:** Future (cloud sync, AI corrections, web app)

## Important Considerations

### When Implementing Features

1. Always create new features in the `features/` directory following the planned structure
2. Each feature should be self-contained with its own models, providers, and UI
3. Shared code belongs in `core/`
4. Use Riverpod providers for state, not StatefulWidget state for complex logic
5. Test OCR parsing edge cases: missing prices, non-numeric text, multiple currencies

### Common Gotchas

- ML Kit requires platform-specific setup (Android: Gradle, iOS: Info.plist permissions)
- Camera permissions must be declared in AndroidManifest.xml and Info.plist
- Hive requires initialization: `await Hive.initFlutter()` in main()
- GoRouter routes must be defined before `MaterialApp.router`
- WhatsApp sharing uses platform-specific share sheets (share_plus handles this)

### Future Extensibility

- Cloud sync (Supabase) in Phase 7
- AI-powered OCR correction (OpenAI/Gemini) in Phase 7
- Web app version (Flutter Web or Next.js)
- Keep data models simple now, but design for future API serialization (JSON)
