# TripConnect Developer Guide - Part 2

## ➕ Adding New Features

### Step-by-Step Process

#### 1. **Define the Feature Requirements**
```markdown
Feature: Trip Weather
- Show weather for trip destination
- Display 7-day forecast
- Show weather alerts
- Update weather in real-time
```

#### 2. **Create Data Models**
```dart
// lib/core/data/models/weather.dart
@freezed
class Weather with _$Weather {
  const factory Weather({
    required String location,
    required double temperature,
    required String condition,
    required DateTime date,
  }) = _Weather;

  factory Weather.fromJson(Map<String, dynamic> json) => _$WeatherFromJson(json);
}
```

#### 3. **Create Provider**
```dart
// lib/core/data/providers/weather_provider.dart
final weatherProvider = FutureProvider.family<Weather, String>((ref, location) async {
  return await WeatherService.getWeather(location);
});

final weatherNotifierProvider = StateNotifierProvider<WeatherNotifier, WeatherState>((ref) {
  return WeatherNotifier();
});

class WeatherNotifier extends StateNotifier<WeatherState> {
  WeatherNotifier() : super(WeatherState.initial());

  Future<void> refreshWeather(String location) async {
    state = state.copyWith(isLoading: true);
    try {
      final weather = await WeatherService.getWeather(location);
      state = state.copyWith(weather: weather, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }
}
```

#### 4. **Create Service**
```dart
// lib/core/services/weather_service.dart
class WeatherService {
  static Future<Weather> getWeather(String location) async {
    // API call implementation
    await Future.delayed(Duration(seconds: 1)); // Simulate API call
    return Weather(
      location: location,
      temperature: 25.0,
      condition: 'Sunny',
      date: DateTime.now(),
    );
  }
}
```

#### 5. **Create UI Screen**
```dart
// lib/features/trips/weather/trip_weather_screen.dart
class TripWeatherScreen extends ConsumerWidget {
  final String tripId;

  const TripWeatherScreen({required this.tripId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weatherAsync = ref.watch(weatherProvider('Mumbai'));

    return Scaffold(
      appBar: AppBar(title: Text('Weather')),
      body: weatherAsync.when(
        data: (weather) => _buildWeatherCard(weather),
        loading: () => Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildWeatherCard(Weather weather) {
    return Card(
      child: ListTile(
        title: Text(weather.location),
        subtitle: Text(weather.condition),
        trailing: Text('${weather.temperature}°C'),
      ),
    );
  }
}
```

#### 6. **Add Navigation Route**
```dart
// lib/routing/app_router.dart
GoRoute(
  path: '/trips/:tripId/weather',
  builder: (context, state) => TripWeatherScreen(
    tripId: state.pathParameters['tripId']!,
  ),
),
```

#### 7. **Add Feature Card**
```dart
// lib/features/trips/detail/trip_detail_screen.dart
_buildFeatureCard(
  context,
  'Weather',
  Icons.wb_sunny,
  Colors.orange,
  () => context.go('/trips/$tripId/weather'),
),
```

---

## 📱 Adding New Screens

### Screen Template

```dart
// lib/features/example/example_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ExampleScreen extends ConsumerStatefulWidget {
  final String? parameter;

  const ExampleScreen({this.parameter, super.key});

  @override
  ConsumerState<ExampleScreen> createState() => _ExampleScreenState();
}

class _ExampleScreenState extends ConsumerState<ExampleScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize data
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Example Screen'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _onAddPressed,
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _onFloatingActionPressed,
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: _buildContent(),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Text(
        'Header Content',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
    );
  }

  Widget _buildContent() {
    return ListView.builder(
      itemCount: 10,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text('Item $index'),
          onTap: () => _onItemTap(index),
        );
      },
    );
  }

  void _onAddPressed() {
    // Handle add action
  }

  void _onFloatingActionPressed() {
    // Handle floating action
  }

  void _onItemTap(int index) {
    // Handle item tap
  }
}
```

### Dialog Template

```dart
// lib/features/example/example_dialog.dart
class ExampleDialog extends ConsumerStatefulWidget {
  final String? initialValue;

  const ExampleDialog({this.initialValue, super.key});

  @override
  ConsumerState<ExampleDialog> createState() => _ExampleDialogState();
}

class _ExampleDialogState extends ConsumerState<ExampleDialog> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.text = widget.initialValue ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _controller,
                decoration: InputDecoration(
                  labelText: 'Enter Value',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Please enter a value';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('Cancel'),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _onSubmit,
                      child: Text('Submit'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onSubmit() {
    if (_formKey.currentState!.validate()) {
      Navigator.of(context).pop(_controller.text);
    }
  }
}
```

---

## 📊 Data Models & State Management

### Model Structure

```dart
// Example: Trip Model
@freezed
class Trip with _$Trip {
  const factory Trip({
    required String id,
    required String name,
    required String theme,
    required Location origin,
    required Location destination,
    required DateTime startDate,
    required DateTime endDate,
    required int seatsTotal,
    required int seatsAvailable,
    @Default(TripPrivacy.private) TripPrivacy privacy,
    required String leaderId,
    required TripInvite invite,
    @Default(TripStatus.planning) TripStatus status,
    @Default([]) List<ScheduleItem> schedule,
    DateTime? createdAt,
    DateTime? updatedAt,
    @Default(TripRatingSummary(tripId: '')) TripRatingSummary ratingSummary,
    @Default(4.0) double minimumUserRating,
  }) = _Trip;

  factory Trip.fromJson(Map<String, dynamic> json) => _$TripFromJson(json);
}
```

### Provider Patterns

#### 1. **Simple State Provider**
```dart
final selectedTripProvider = StateProvider<Trip?>((ref) => null);
```

#### 2. **Future Provider (Async Data)**
```dart
final tripsProvider = FutureProvider<List<Trip>>((ref) async {
  return await TripService.getTrips();
});
```

#### 3. **State Notifier (Complex State)**
```dart
final tripNotifierProvider = StateNotifierProvider<TripNotifier, TripState>((ref) {
  return TripNotifier();
});

class TripNotifier extends StateNotifier<TripState> {
  TripNotifier() : super(TripState.initial());

  Future<void> createTrip(Trip trip) async {
    state = state.copyWith(isLoading: true);
    try {
      final newTrip = await TripService.createTrip(trip);
      state = state.copyWith(
        trips: [...state.trips, newTrip],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }
}
```

#### 4. **Family Provider (Parameterized)**
```dart
final tripProvider = FutureProvider.family<Trip, String>((ref, tripId) async {
  return await TripService.getTrip(tripId);
});
```

---

## 🧭 Navigation & Routing

### Routing Structure

```dart
// lib/routing/app_router.dart
final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    // Auth routes
    GoRoute(
      path: '/',
      builder: (context, state) => WelcomeScreen(),
    ),
    GoRoute(
      path: '/signin',
      builder: (context, state) => SignInScreen(),
    ),
    
    // Main app routes
    ShellRoute(
      builder: (context, state, child) => MainLayout(child: child),
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => HomeScreen(),
        ),
        GoRoute(
          path: '/trips',
          builder: (context, state) => TripsScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => ProfileScreen(),
        ),
      ],
    ),
    
    // Trip detail routes
    GoRoute(
      path: '/trips/:tripId',
      builder: (context, state) => TripDetailScreen(
        tripId: state.pathParameters['tripId']!,
      ),
    ),
    GoRoute(
      path: '/trips/:tripId/chat',
      builder: (context, state) => TripChatScreen(
        tripId: state.pathParameters['tripId']!,
      ),
    ),
  ],
);
```

### Navigation Methods

```dart
// Navigate to new screen
context.go('/trips/t_001');

// Navigate with parameters
context.go('/trips/${trip.id}');

// Push screen (keep back stack)
context.push('/trips/t_001/chat');

// Go back
context.pop();

// Replace current screen
context.go('/home');
```

---

## 🎨 UI/UX Guidelines

### Design System

#### Colors
```dart
// lib/shared/themes/app_colors.dart
class AppColors {
  static const primary = Color(0xFF2196F3);
  static const secondary = Color(0xFF4CAF50);
  static const accent = Color(0xFFFF9800);
  static const error = Color(0xFFF44336);
  static const success = Color(0xFF4CAF50);
  static const warning = Color(0xFFFF9800);
  static const info = Color(0xFF2196F3);
}
```

#### Typography
```dart
// lib/shared/themes/app_typography.dart
class AppTypography {
  static const headline1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
  );
  static const headline2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
  );
  static const body1 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
  );
}
```

### Common Widgets

#### Card Widget
```dart
Widget _buildCard({
  required String title,
  required String subtitle,
  required IconData icon,
  required VoidCallback onTap,
}) {
  return Card(
    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: ListTile(
      leading: Icon(icon, color: Theme.of(context).primaryColor),
      title: Text(title, style: AppTypography.headline2),
      subtitle: Text(subtitle, style: AppTypography.body1),
      trailing: Icon(Icons.arrow_forward_ios),
      onTap: onTap,
    ),
  );
}
```

#### Loading Widget
```dart
Widget _buildLoadingWidget() {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(),
        SizedBox(height: 16),
        Text('Loading...'),
      ],
    ),
  );
}
```

#### Error Widget
```dart
Widget _buildErrorWidget(String error) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.error, size: 64, color: Colors.red),
        SizedBox(height: 16),
        Text('Error: $error'),
        SizedBox(height: 16),
        ElevatedButton(
          onPressed: () => ref.refresh(provider),
          child: Text('Retry'),
        ),
      ],
    ),
  );
}
```

---

## 🔄 Common Patterns

### 1. **Async Data Loading Pattern**
```dart
class DataScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(dataProvider);

    return Scaffold(
      body: dataAsync.when(
        data: (data) => _buildDataList(data),
        loading: () => _buildLoadingWidget(),
        error: (error, stack) => _buildErrorWidget(error.toString()),
      ),
    );
  }
}
```

### 2. **Form Validation Pattern**
```dart
class FormScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<FormScreen> createState() => _FormScreenState();
}

class _FormScreenState extends ConsumerState<FormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _controller,
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'This field is required';
              }
              return null;
            },
          ),
          ElevatedButton(
            onPressed: _onSubmit,
            child: Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _onSubmit() {
    if (_formKey.currentState!.validate()) {
      // Process form
    }
  }
}
```

### 3. **Permission Handling Pattern**
```dart
Future<void> _requestPermission() async {
  try {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      // Permission granted
    } else if (status.isPermanentlyDenied) {
      // Show settings dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Permission Required'),
          content: Text('Please enable camera access in settings.'),
          actions: [
            TextButton(
              onPressed: () => openAppSettings(),
              child: Text('Open Settings'),
            ),
          ],
        ),
      );
    }
  } catch (e) {
    print('Permission error: $e');
  }
}
```

### 4. **Error Handling Pattern**
```dart
Future<void> _performAction() async {
  try {
    setState(() => _isLoading = true);
    await _action();
    setState(() => _isLoading = false);
  } catch (e) {
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: ${e.toString()}'),
        backgroundColor: Colors.red,
      ),
    );
  }
}
```

---

## 🔧 Troubleshooting

### Common Issues & Solutions

#### 1. **Build Issues**
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter run

# For iOS specific issues
cd ios
pod install
cd ..
flutter run
```

#### 2. **Provider Issues**
```dart
// Check if provider is properly initialized
final provider = ref.read(myProvider);

// Refresh provider
ref.refresh(myProvider);

// Watch provider changes
ref.listen(myProvider, (previous, next) {
  print('Provider updated');
});
```

#### 3. **Navigation Issues**
```dart
// Check if route exists
if (context.canPop()) {
  context.pop();
} else {
  context.go('/home');
}

// Debug routing
print('Current route: ${GoRouterState.of(context).location}');
```

#### 4. **State Management Issues**
```dart
// Ensure proper state updates
setState(() {
  _variable = newValue;
});

// For Riverpod
ref.read(notifierProvider.notifier).updateState(newValue);
```

#### 5. **Performance Issues**
```dart
// Use const constructors
const MyWidget();

// Avoid unnecessary rebuilds
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Only watch what you need
    final specificData = ref.watch(specificProvider);
    return Widget();
  }
}
```

### Debug Commands

```bash
# Check Flutter doctor
flutter doctor

# Analyze code
flutter analyze

# Run tests
flutter test

# Build for release
flutter build ios
flutter build apk
```

---

## 🎯 Quick Reference

### File Naming Conventions
- **Screens**: `feature_screen.dart`
- **Widgets**: `feature_widget.dart`
- **Models**: `feature.dart`
- **Providers**: `feature_provider.dart`
- **Services**: `feature_service.dart`

### Code Organization
- **One class per file**
- **Group related functionality**
- **Use meaningful names**
- **Add comments for complex logic**

### Git Workflow
```bash
# Create feature branch
git checkout -b feature/new-feature

# Make changes
git add .
git commit -m "Add new feature"

# Push changes
git push origin feature/new-feature

# Create pull request
```

---

This comprehensive guide should help any developer, regardless of Flutter experience, understand the codebase and add new features effectively. Remember to follow the established patterns and conventions for consistency across the project.
