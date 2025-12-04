# EarlyBird 🏠

![Tests](https://github.com/lkroon/earlybird/workflows/Flutter%20Tests/badge.svg)
![Build](https://github.com/lkroon/earlybird/workflows/Build%20and%20Deploy/badge.svg)
![Code Quality](https://github.com/lkroon/earlybird/workflows/Code%20Quality/badge.svg)

A Flutter app for finding real estate listings on Funda and other platforms. Get notified early about new listings that match your filters!

## Features

- 🏠 Browse real estate listings from Funda
- 🔄 Incremental loading with lazy image fetching
- 🔍 Customizable search filters (area, property type, date, sort order)
- 📱 Cross-platform (Android, iOS, Web, Desktop)
- ✨ Clean, modular architecture
- 🧪 Comprehensive test coverage (70+ tests)

## Architecture

The app follows a clean, modular architecture with clear separation of concerns:

- **Models**: Data structures (`Listing`, `SearchFilter`)
- **Services**: Business logic (scrapers, image loading)
- **Providers**: State management (using Provider pattern)
- **Screens**: UI components and widgets
- **Core**: Shared utilities, constants, and theme

See [ARCHITECTURE.md](ARCHITECTURE.md) for detailed documentation.

## Getting Started

### Prerequisites

- Flutter SDK 3.10.0 or higher
- Dart SDK 3.0.0 or higher

### Installation

1. Clone the repository:
```bash
git clone https://github.com/lkroon/earlybird.git
cd earlybird
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

### Running Tests

```bash
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage

# Run specific test file
flutter test test/models/listing_test.dart
```

See [TESTING.md](TESTING.md) for comprehensive test documentation.

## Project Structure

```
lib/
├── main.dart                    # App entry point
├── core/                        # Shared utilities
│   ├── constants/               # App constants
│   ├── theme/                   # Theme configuration
│   └── utils/                   # Utility functions
├── models/                      # Data models
├── services/                    # Business logic
├── providers/                   # State management
└── screens/                     # UI screens and widgets

test/
├── models/                      # Model tests
├── services/                    # Service tests
├── providers/                   # Provider tests
└── widgets/                     # Widget tests
```

## CI/CD

This project uses GitHub Actions for continuous integration:

- **Tests**: Run automatically on every push and pull request
- **Code Quality**: Formatting and analysis checks
- **Build**: Automated builds for Android, iOS, and Web

See [.github/WORKFLOWS.md](.github/WORKFLOWS.md) for details.

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

Ensure all tests pass before submitting:
```bash
flutter test
flutter analyze
dart format .
```

## Roadmap

- [ ] Add filter UI for dynamic search customization
- [ ] Implement push notifications for new listings
- [ ] Add support for additional real estate platforms (Jaap.nl, etc.)
- [ ] Implement favorites/saved listings
- [ ] Add local data persistence
- [ ] Map view for listings
- [ ] Price alerts

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
