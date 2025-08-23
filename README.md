# TripConnect 🌟

A modern Flutter application for connecting travelers and organizing group trips with comprehensive rating and feedback systems.

## 🚀 Features

### ✨ Core Functionality
- **Trip Management**: Create, join, and manage trips with detailed scheduling
- **User Authentication**: Secure sign-up/sign-in with guest access
- **Real-time Chat**: In-app messaging for trip participants
- **Location Sharing**: Real-time location tracking for trip members
- **Roll Call System**: Automated attendance tracking with customizable range

### 🌟 Rating & Feedback System
- **User Ratings**: Rate fellow travelers based on trip experiences
- **Trip Ratings**: Provide feedback on trip organization and experience
- **Reputation System**: Build trust through verified ratings and reviews
- **Rating-based Access**: Trip organizers can set minimum rating requirements
- **Comprehensive Feedback**: Detailed rating categories and optional comments

### 🎯 User Experience
- **Guest Mode**: Browse public trips without registration
- **Trip Discovery**: Search and filter trips by various criteria
- **Responsive Design**: Beautiful UI that works on all screen sizes
- **Real-time Updates**: Live trip status and member activity
- **Intuitive Navigation**: Seamless user journey throughout the app

## 📱 Screenshots

*Screenshots will be added here*

## 🛠️ Tech Stack

- **Framework**: Flutter 3.x
- **State Management**: Riverpod
- **Navigation**: Go Router
- **Local Storage**: Hive
- **Code Generation**: Freezed, build_runner
- **UI Components**: Material Design 3
- **Animations**: Flutter Staggered Animations

## 📋 Prerequisites

- Flutter SDK (3.0 or higher)
- Dart SDK (3.0 or higher)
- iOS Simulator / Android Emulator / Physical Device
- Git

## 🚀 Getting Started

### 1. Clone the Repository
```bash
git clone <repository-url>
cd trip_connect
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Generate Code
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 4. Run the App
```bash
flutter run
```

## 📁 Project Structure

```
lib/
├── core/
│   ├── data/
│   │   ├── models/          # Data models (User, Trip, Rating, etc.)
│   │   ├── providers/       # Riverpod providers
│   │   └── repositories/    # Data access layer
│   ├── services/            # Mock server and business logic
│   └── theme/              # App theming and styling
├── features/
│   ├── auth/               # Authentication screens
│   ├── common/             # Shared widgets and utilities
│   ├── ratings/            # Rating and feedback screens
│   └── trips/              # Trip-related screens
└── routing/                # App navigation configuration
```

## 🎨 Key Features Implementation

### Rating System
- **User Ratings**: Rate other users based on trip experiences
- **Trip Ratings**: Provide feedback on trip organization
- **Rating Display**: Prominent rating badges throughout the app
- **Rating Filters**: Search trips based on organizer ratings

### Trip Management
- **Trip Creation**: Comprehensive trip setup with scheduling
- **Member Management**: Add, remove, and manage trip participants
- **Status Tracking**: Active, upcoming, waiting, and past trips
- **Real-time Updates**: Live trip status and member activity

### User Experience
- **Guest Access**: Browse trips without registration
- **Responsive Design**: Works on all device sizes
- **Intuitive Navigation**: Seamless user journey
- **Professional UI**: Modern Material Design 3 implementation

## 🔧 Configuration

### Environment Setup
The app uses mock data for demonstration. To configure:

1. Update mock data in `lib/core/services/mock_server.dart`
2. Customize themes in `lib/core/theme/`
3. Modify rating criteria in rating models

### Build Configuration
- **iOS**: Configure in `ios/Runner/Info.plist`
- **Android**: Configure in `android/app/build.gradle`

## 🧪 Testing

```bash
# Run unit tests
flutter test

# Run integration tests
flutter test integration_test/
```

## 📦 Build & Deploy

### iOS
```bash
flutter build ios
```

### Android
```bash
flutter build apk
flutter build appbundle
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Riverpod for excellent state management
- Material Design team for design guidelines
- All contributors and testers

## 📞 Support

For support and questions:
- Create an issue in the repository
- Contact the development team

---

**TripConnect** - Connecting travelers, one trip at a time! 🌍✈️
