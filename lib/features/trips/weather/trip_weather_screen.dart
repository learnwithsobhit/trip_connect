import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/models/models.dart';
import '../../../core/data/providers/trip_provider.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_colors.dart';

class TripWeatherScreen extends ConsumerStatefulWidget {
  final String tripId;

  const TripWeatherScreen({super.key, required this.tripId});

  @override
  ConsumerState<TripWeatherScreen> createState() => _TripWeatherScreenState();
}

class _TripWeatherScreenState extends ConsumerState<TripWeatherScreen> {
  String _selectedLocation = 'Destination';
  final List<String> _locations = ['Destination', 'Current Location', 'Waypoint 1', 'Waypoint 2'];
  
  final List<WeatherDay> _mockWeatherData = [
    WeatherDay(
      date: DateTime.now(),
      location: 'Goa, India',
      temperature: 28,
      condition: 'Partly Cloudy',
      icon: '⛅',
      humidity: 75,
      windSpeed: 12,
      precipitation: 10,
      uvIndex: 6,
      hourlyForecast: [
        HourlyWeather(time: '09:00', temp: 26, condition: 'Cloudy', icon: '☁️'),
        HourlyWeather(time: '12:00', temp: 30, condition: 'Sunny', icon: '☀️'),
        HourlyWeather(time: '15:00', temp: 32, condition: 'Hot', icon: '🌡️'),
        HourlyWeather(time: '18:00', temp: 29, condition: 'Partly Cloudy', icon: '⛅'),
        HourlyWeather(time: '21:00', temp: 27, condition: 'Clear', icon: '🌙'),
      ],
    ),
    WeatherDay(
      date: DateTime.now().add(const Duration(days: 1)),
      location: 'Goa, India',
      temperature: 31,
      condition: 'Sunny',
      icon: '☀️',
      humidity: 68,
      windSpeed: 8,
      precipitation: 0,
      uvIndex: 8,
      hourlyForecast: [],
    ),
    WeatherDay(
      date: DateTime.now().add(const Duration(days: 2)),
      location: 'Goa, India',
      temperature: 29,
      condition: 'Rain',
      icon: '🌧️',
      humidity: 85,
      windSpeed: 15,
      precipitation: 80,
      uvIndex: 3,
      hourlyForecast: [],
    ),
    WeatherDay(
      date: DateTime.now().add(const Duration(days: 3)),
      location: 'Goa, India',
      temperature: 27,
      condition: 'Thunderstorm',
      icon: '⛈️',
      humidity: 90,
      windSpeed: 20,
      precipitation: 95,
      uvIndex: 2,
      hourlyForecast: [],
    ),
    WeatherDay(
      date: DateTime.now().add(const Duration(days: 4)),
      location: 'Goa, India',
      temperature: 30,
      condition: 'Partly Cloudy',
      icon: '⛅',
      humidity: 70,
      windSpeed: 10,
      precipitation: 20,
      uvIndex: 7,
      hourlyForecast: [],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tripAsync = ref.watch(tripProvider(widget.tripId));

    return tripAsync.when(
      data: (trip) => trip != null 
          ? _buildWeatherContent(context, theme, trip)
          : const Center(child: Text('Trip not found')),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text('Error loading trip: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.pop(),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherContent(BuildContext context, ThemeData theme, Trip trip) {
    final currentWeather = _mockWeatherData.first;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weather Forecast'),
        actions: [
          IconButton(
            onPressed: () => _showWeatherOptions(context),
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Mock refresh
          await Future.delayed(const Duration(seconds: 1));
        },
        child: CustomScrollView(
          slivers: [
            // Location Selector
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(AppSpacing.md),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedLocation,
                    isExpanded: true,
                    icon: const Icon(Icons.location_on),
                    items: _locations.map((location) => DropdownMenuItem(
                      value: location,
                      child: Text(location),
                    )).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedLocation = value);
                      }
                    },
                  ),
                ),
              ),
            ),

            // Current Weather Card
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: _buildCurrentWeatherCard(theme, currentWeather),
              ),
            ),

            // Hourly Forecast
            if (currentWeather.hourlyForecast.isNotEmpty)
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.all(AppSpacing.md),
                  child: _buildHourlyForecast(theme, currentWeather.hourlyForecast),
                ),
              ),

            // 5-Day Forecast
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: _build5DayForecast(theme),
              ),
            ),

            // Weather Alerts
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(AppSpacing.md),
                child: _buildWeatherAlerts(theme),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'weather-add-location',
        onPressed: () => _showAddLocationDialog(context),
        icon: const Icon(Icons.add_location),
        label: const Text('Add Location'),
      ),
    );
  }

  Widget _buildCurrentWeatherCard(ThemeData theme, WeatherDay weather) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary.withOpacity(0.1),
              AppColors.secondary.withOpacity(0.1),
            ],
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  weather.icon,
                  style: const TextStyle(fontSize: 48),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${weather.temperature}°C',
                        style: theme.textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        weather.condition,
                        style: theme.textTheme.titleMedium,
                      ),
                      Text(
                        weather.location,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildWeatherStat(theme, Icons.water_drop, 'Humidity', '${weather.humidity}%'),
                _buildWeatherStat(theme, Icons.air, 'Wind', '${weather.windSpeed} km/h'),
                _buildWeatherStat(theme, Icons.umbrella, 'Rain', '${weather.precipitation}%'),
                _buildWeatherStat(theme, Icons.wb_sunny, 'UV Index', '${weather.uvIndex}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherStat(ThemeData theme, IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildHourlyForecast(ThemeData theme, List<HourlyWeather> hourlyData) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hourly Forecast',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: hourlyData.length,
                itemBuilder: (context, index) {
                  final hour = hourlyData[index];
                  return Container(
                    width: 80,
                    margin: const EdgeInsets.only(right: AppSpacing.sm),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Text(hour.time, style: theme.textTheme.bodySmall),
                        Text(hour.icon, style: const TextStyle(fontSize: 24)),
                        Text('${hour.temp}°', style: theme.textTheme.bodySmall),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _build5DayForecast(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '5-Day Forecast',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.md),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _mockWeatherData.length,
              itemBuilder: (context, index) {
                final day = _mockWeatherData[index];
                final dayName = index == 0 ? 'Today' : _getDayName(day.date);
                
                return ListTile(
                  leading: Text(day.icon, style: const TextStyle(fontSize: 24)),
                  title: Text(dayName),
                  subtitle: Text(day.condition),
                  trailing: Text(
                    '${day.temperature}°C',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherAlerts(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning, color: Colors.orange),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Weather Alerts',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.umbrella, color: Colors.orange),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Heavy Rain Expected',
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Thunderstorms expected on Day 4. Plan indoor activities.',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getDayName(DateTime date) {
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[date.weekday - 1];
  }

  void _showWeatherOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.refresh),
            title: const Text('Refresh Weather'),
            onTap: () {
              Navigator.pop(context);
              // Mock refresh
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Weather Settings'),
            onTap: () {
              Navigator.pop(context);
              // Navigate to settings
            },
          ),
          ListTile(
            leading: const Icon(Icons.share),
            title: const Text('Share Weather'),
            onTap: () {
              Navigator.pop(context);
              // Share weather
            },
          ),
        ],
      ),
    );
  }

  void _showAddLocationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Weather Location'),
        content: const TextField(
          decoration: InputDecoration(
            hintText: 'Enter city or location',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Location added successfully!')),
              );
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class WeatherDay {
  final DateTime date;
  final String location;
  final int temperature;
  final String condition;
  final String icon;
  final int humidity;
  final int windSpeed;
  final int precipitation;
  final int uvIndex;
  final List<HourlyWeather> hourlyForecast;

  WeatherDay({
    required this.date,
    required this.location,
    required this.temperature,
    required this.condition,
    required this.icon,
    required this.humidity,
    required this.windSpeed,
    required this.precipitation,
    required this.uvIndex,
    required this.hourlyForecast,
  });
}

class HourlyWeather {
  final String time;
  final int temp;
  final String condition;
  final String icon;

  HourlyWeather({
    required this.time,
    required this.temp,
    required this.condition,
    required this.icon,
  });
}
