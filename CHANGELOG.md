# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-02-06

### Added
- **Logging System**
  - Complete logging framework with multiple log levels (debug, info, warning, error)
  - File-based logging with automatic rotation
  - WebSocket-based log streaming for remote debugging
  - Rich log detail view with filtering and search capabilities
  - Tag-based log categorization
  - Stack trace support for error logs
  - Configurable log output (console, file, remote)

- **State Management**
  - **Event State Management**: For handling one-time events with loading/success/error states
    - `DKStateEvent` core classes
    - Flutter integration with `StreamSubscription` helpers
    - GetX integration support
    - Automatic loading state handling
  - **Query State Management**: For data fetching operations with caching
    - `DkStateQuery` with idle/loading/success/error states
    - Flutter widgets for state display
    - GetX integration support
    - Built-in error handling and retry mechanisms

- **Utility Features**
  - App routing system with navigation helpers
  - Configuration management
  - Example implementations and demos
  - Comprehensive documentation with usage examples

- **Platform Support**
  - Full Flutter support (iOS, Android, Web, Windows, macOS, Linux)
  - File system operations with proper permissions
  - Network communication capabilities

### Dependencies
- Flutter SDK ^3.10.7
- get: ^4.7.3 (for optional GetX integration)
- path_provider: ^2.1.5 (for file operations)
- permission_handler: ^12.0.1 (for file permissions)
- file_picker: ^10.3.8 (for file selection)
- web_socket_channel: ^3.0.3 (for log streaming)
- nsd: ^4.1.0 (for network service discovery)

### Technical Details
- Minimum Dart SDK version: 3.10.7
- Follows Flutter package best practices
- Comprehensive test coverage
- Lint-compliant code with flutter_lints ^6.0.0
- Material Design integration

---

## [Unreleased]

### Planned
- Additional state management patterns
- Enhanced logging features
- Performance optimizations
- More comprehensive examples

---

**Note**: This is the initial release of dk_util. Future versions will follow semantic versioning principles.
