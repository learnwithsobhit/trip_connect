# TripConnect Developer Guide

## 📋 Table of Contents
1. [Project Overview](#project-overview)
2. [Architecture & Design Patterns](#architecture--design-patterns)
3. [Project Structure](#project-structure)
4. [Getting Started](#getting-started)
5. [Core Concepts](#core-concepts)
6. [Adding New Features](#adding-new-features)
7. [Adding New Screens](#adding-new-screens)
8. [Data Models & State Management](#data-models--state-management)
9. [Navigation & Routing](#navigation--routing)
10. [UI/UX Guidelines](#uiux-guidelines)
11. [Testing & Debugging](#testing--debugging)
12. [Common Patterns](#common-patterns)
13. [Troubleshooting](#troubleshooting)

---

## 🎯 Project Overview

**TripConnect** is a comprehensive trip planning and connectivity app built with Flutter. It enables users to plan trips, manage members, share locations, rate services, and stay connected during travel.

### Key Features
- **Trip Management**: Create, join, and manage trips
- **Member Management**: Add/remove members, manage roles
- **Real-time Communication**: Chat, polls, and notifications
- **Location Services**: GPS tracking, roll call, meeting points
- **Service Ratings**: Rate accommodations, food, transport
- **Budget Management**: Track expenses and budgets
- **Entertainment**: Games and activities during trips

---

## 🏗️ Architecture & Design Patterns

### Architecture Pattern: **Clean Architecture + MVVM**

```
┌─────────────────────────────────────────────────────────────┐
│                    Presentation Layer                       │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │   Screens   │  │   Widgets   │  │   Dialogs   │         │
│  └─────────────┘  └─────────────┘  └─────────────┘         │
└─────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────┐
│                     Business Logic Layer                    │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │  Providers  │  │  Notifiers  │  │  Services   │         │
│  └─────────────┘  └─────────────┘  └─────────────┘         │
└─────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────┐
│                      Data Layer                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │   Models    │  │ Repositories │  │ Mock Server │         │
│  └─────────────┘  └─────────────┘  └─────────────┘         │
└─────────────────────────────────────────────────────────────┘
```

### Design Patterns Used:
- **Provider Pattern**: State management with Riverpod
- **Repository Pattern**: Data access abstraction
- **Factory Pattern**: Model creation
- **Observer Pattern**: Real-time updates
- **Builder Pattern**: UI construction

---

## 📁 Project Structure

```
lib/
├── core/                          # Core functionality
│   ├── data/                      # Data layer
│   │   ├── models/                # Data models (User, Trip, etc.)
│   │   ├── providers/             # Riverpod providers
│   │   └── repositories/          # Data repositories
│   ├── services/                  # Business logic services
│   ├── utils/                     # Utility functions
│   └── constants/                 # App constants
├── features/                      # Feature modules
│   ├── auth/                      # Authentication
│   ├── trips/                     # Trip management
│   │   ├── detail/                # Trip details
│   │   ├── chat/                  # Trip chat
│   │   ├── rollcall/              # Roll call management
│   │   ├── entertainment/         # Games & activities
│   │   ├── budget/                # Budget management
│   │   └── service_rating/        # Service ratings
│   ├── profile/                   # User profile
│   └── settings/                  # App settings
├── shared/                        # Shared components
│   ├── widgets/                   # Reusable widgets
│   ├── themes/                    # App themes
│   └── utils/                     # Shared utilities
└── main.dart                      # App entry point
```

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.1.0 or higher)
- Dart SDK (3.1.0 or higher)
- iOS 14.0+ (for iOS builds)
- Android Studio / VS Code

### Setup Instructions

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd trip_connect
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate code** (for models)
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

### Development Environment Setup

1. **VS Code Extensions** (recommended):
   - Flutter
   - Dart
   - Riverpod Snippets
   - Error Lens

2. **Hot Reload**: Press `r` in terminal for hot reload
3. **Hot Restart**: Press `R` in terminal for hot restart

---

## 🧠 Core Concepts

### 1. Flutter Basics

**Widgets**: Everything in Flutter is a widget
```dart
// Stateless Widget (immutable)
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Text('Hello World'),
    );
  }
}

// Stateful Widget (mutable)
class MyStatefulWidget extends StatefulWidget {
  @override
  _MyStatefulWidgetState createState() => _MyStatefulWidgetState();
}

class _MyStatefulWidgetState extends State<MyStatefulWidget> {
  String _text = 'Hello';
  
  @override
  Widget build(BuildContext context) {
    return Text(_text);
  }
}
```

### 2. Riverpod State Management

**Provider**: Creates and manages state
```dart
// Simple provider
final counterProvider = StateProvider<int>((ref) => 0);

// Future provider (async data)
final userProvider = FutureProvider<User>((ref) async {
  return await UserService.getUser();
});

// State notifier (complex state)
final tripNotifierProvider = StateNotifierProvider<TripNotifier, TripState>((ref) {
  return TripNotifier();
});
```

**Consumer**: Accesses provider state
```dart
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(counterProvider);
    final user = ref.watch(userProvider);
    
    return Text('Count: $count');
  }
}
```

### 3. Data Models

**Freezed Models**: Immutable data classes
```dart
@freezed
class User with _$User {
  const factory User({
    required String id,
    required String name,
    required String email,
    @Default(0.0) double rating,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}
```
