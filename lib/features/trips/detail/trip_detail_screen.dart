import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/providers/trip_provider.dart';
import '../../../core/data/models/models.dart';
import '../../../core/theme/app_spacing.dart';

class TripDetailScreen extends ConsumerWidget {
  final String tripId;

  const TripDetailScreen({super.key, required this.tripId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripAsync = ref.watch(tripProvider(tripId));

    return Scaffold(
      body: tripAsync.when(
        data: (trip) {
          if (trip == null) {
            return const Center(child: Text('Trip not found'));
          }

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => context.go('/'),
                ),
                actions: [
                  PopupMenuButton<String>(
                    onSelected: (value) => _handleMenuAction(context, tripId, value),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'guardian_link',
                        child: ListTile(
                          leading: Icon(Icons.family_restroom),
                          title: Text('Share Guardian Link'),
                          subtitle: Text('Read-only view for family'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'trip_settings',
                        child: ListTile(
                          leading: Icon(Icons.settings),
                          title: Text('Trip Settings'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(trip.name),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.secondary,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Trip Status and Current Schedule Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: AppSpacing.paddingMd,
                  child: _buildTripStatusAndSchedule(context, trip),
                ),
              ),
              SliverPadding(
                padding: AppSpacing.paddingMd,
                sliver: SliverGrid(
                  delegate: SliverChildListDelegate([
                    _buildFeatureCard(
                      context,
                      'Schedule',
                      Icons.schedule,
                      'View trip timeline',
                      () => context.go('/trips/$tripId/schedule'),
                    ),
                    _buildFeatureCard(
                      context,
                      'Map',
                      Icons.map,
                      'Live location tracking',
                      () => context.go('/trips/$tripId/map'),
                    ),
                    _buildFeatureCard(
                      context,
                      'Chat',
                      Icons.chat,
                      'Group communication',
                      () => context.go('/trips/$tripId/chat'),
                    ),

                    _buildFeatureCard(
                      context,
                      'People',
                      Icons.people,
                      'Trip members',
                      () => context.go('/trips/$tripId/people'),
                    ),
                    _buildFeatureCard(
                      context,
                      'Roll Call',
                      Icons.how_to_reg,
                      'Check-in tracking',
                      () => context.go('/trips/$tripId/rollcall'),
                    ),
                    _buildFeatureCard(
                      context,
                      'Rate Trip',
                      Icons.star,
                      'Rate your experience',
                      () => context.go('/trips/$tripId/rate-trip?name=${Uri.encodeComponent(trip.name)}'),
                    ),
                    _buildFeatureCard(
                      context,
                      'Rate Members',
                      Icons.people_alt,
                      'Rate trip members',
                      () => context.go('/trips/$tripId/people?showRating=true'),
                    ),
                    _buildFeatureCard(
                      context,
                      'Weather',
                      Icons.wb_sunny,
                      'Weather forecast',
                      () => context.go('/trips/$tripId/weather'),
                    ),
                    _buildFeatureCard(
                      context,
                      'Checklist',
                      Icons.checklist,
                      'Trip preparation',
                      () => context.go('/trips/$tripId/checklist'),
                    ),
                    _buildFeatureCard(
                      context,
                      'Transportation',
                      Icons.flight,
                      'Travel tracking',
                      () => context.go('/trips/$tripId/transportation'),
                    ),
                    _buildFeatureCard(
                      context,
                      'Health & Safety',
                      Icons.health_and_safety,
                      'Health information',
                      () => context.go('/trips/$tripId/health'),
                    ),
                    _buildFeatureCard(
                      context,
                      'Documents',
                      Icons.folder,
                      'Trip documents',
                      () => context.go('/trips/$tripId/documents'),
                    ),
                    _buildFeatureCard(
                      context,
                      'Media Gallery',
                      Icons.photo_library,
                      'Photos & videos',
                      () => context.go('/trips/$tripId/media'),
                    ),
         ]),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
      floatingActionButton: tripAsync.when(
        data: (trip) => trip != null 
            ? FloatingActionButton.extended(
                heroTag: 'trip-detail-ratings',
                onPressed: () => context.pushNamed(
                  'trip-ratings-list',
                  pathParameters: {'tripId': tripId},
                  queryParameters: {'name': trip.name},
                ),
                icon: const Icon(Icons.rate_review),
                label: const Text('View Ratings'),
              )
            : null,
        loading: () => null,
        error: (_, __) => null,
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context,
    String title,
    IconData icon,
    String subtitle,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: AppSpacing.cardRadius,
        child: Padding(
          padding: AppSpacing.paddingMd,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: theme.colorScheme.primary,
              ),
              AppSpacing.verticalSpaceMd,
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              AppSpacing.verticalSpaceXs,
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void _handleMenuAction(BuildContext context, String tripId, String action) {
    switch (action) {
      case 'guardian_link':
        _showGuardianLinkDialog(context, tripId);
        break;
      case 'trip_settings':
        _showTripSettingsDialog(context, tripId);
        break;
    }
  }

  static void _showTripSettingsDialog(BuildContext context, String tripId) {
    bool _isPublic = true;
    bool _allowGuestJoin = false;
    bool _requireApproval = true;
    bool _enableLocationSharing = true;
    bool _enableChat = true;
    bool _enableRollCall = true;
    bool _enableGuardianLink = true;
    String _selectedPrivacy = 'Trip Members';
    String _selectedLocationAccuracy = 'High';
    
    final List<String> _privacyOptions = ['Trip Members', 'Friends', 'Public'];
    final List<String> _locationAccuracyOptions = ['Low', 'Medium', 'High'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.settings,
                color: Theme.of(context).colorScheme.primary,
              ),
              AppSpacing.horizontalSpaceSm,
              const Text('Trip Settings'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Privacy Settings
                Text(
                  'Privacy & Visibility',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                AppSpacing.verticalSpaceSm,
                
                SwitchListTile(
                  title: const Text('Public Trip'),
                  subtitle: const Text('Allow others to discover this trip'),
                  value: _isPublic,
                  onChanged: (value) {
                    setState(() {
                      _isPublic = value;
                    });
                  },
                ),
                
                SwitchListTile(
                  title: const Text('Allow Guest Join'),
                  subtitle: const Text('Let guests join with trip code'),
                  value: _allowGuestJoin,
                  onChanged: (value) {
                    setState(() {
                      _allowGuestJoin = value;
                    });
                  },
                ),
                
                SwitchListTile(
                  title: const Text('Require Approval'),
                  subtitle: const Text('Approve new members before joining'),
                  value: _requireApproval,
                  onChanged: (value) {
                    setState(() {
                      _requireApproval = value;
                    });
                  },
                ),
                
                DropdownButtonFormField<String>(
                  value: _selectedPrivacy,
                  decoration: const InputDecoration(
                    labelText: 'Who can see trip details',
                    border: OutlineInputBorder(),
                  ),
                  items: _privacyOptions.map((option) => DropdownMenuItem(
                    value: option,
                    child: Text(option),
                  )).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedPrivacy = value!;
                    });
                  },
                ),
                
                AppSpacing.verticalSpaceMd,
                
                // Location Settings
                Text(
                  'Location & Tracking',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                AppSpacing.verticalSpaceSm,
                
                SwitchListTile(
                  title: const Text('Enable Location Sharing'),
                  subtitle: const Text('Share location with trip members'),
                  value: _enableLocationSharing,
                  onChanged: (value) {
                    setState(() {
                      _enableLocationSharing = value;
                    });
                  },
                ),
                
                DropdownButtonFormField<String>(
                  value: _selectedLocationAccuracy,
                  decoration: const InputDecoration(
                    labelText: 'Location Accuracy',
                    border: OutlineInputBorder(),
                  ),
                  items: _locationAccuracyOptions.map((option) => DropdownMenuItem(
                    value: option,
                    child: Text(option),
                  )).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedLocationAccuracy = value!;
                    });
                  },
                ),
                
                AppSpacing.verticalSpaceMd,
                
                // Feature Settings
                Text(
                  'Features',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                AppSpacing.verticalSpaceSm,
                
                SwitchListTile(
                  title: const Text('Enable Chat'),
                  subtitle: const Text('Allow members to chat'),
                  value: _enableChat,
                  onChanged: (value) {
                    setState(() {
                      _enableChat = value;
                    });
                  },
                ),
                
                SwitchListTile(
                  title: const Text('Enable Roll Call'),
                  subtitle: const Text('Allow roll call functionality'),
                  value: _enableRollCall,
                  onChanged: (value) {
                    setState(() {
                      _enableRollCall = value;
                    });
                  },
                ),
                
                SwitchListTile(
                  title: const Text('Enable Guardian Link'),
                  subtitle: const Text('Allow guardian access'),
                  value: _enableGuardianLink,
                  onChanged: (value) {
                    setState(() {
                      _enableGuardianLink = value;
                    });
                  },
                ),
              ],
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
                  const SnackBar(content: Text('Trip settings updated successfully!')),
                );
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  static void _showGuardianLinkDialog(BuildContext context, String tripId) {
    final safeTripId = tripId.length >= 8 ? tripId.substring(0, 8) : tripId.padRight(8, '0');
    final guardianToken = 'GT${safeTripId.toUpperCase()}';
    final guardianUrl = 'https://tripconnect.app/guardian/$tripId?token=$guardianToken';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.family_restroom,
              color: Theme.of(context).colorScheme.primary,
            ),
            AppSpacing.horizontalSpaceSm,
            const Text('Guardian Link'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Share this link with family members to give them a read-only view of the trip progress and member safety.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              
              AppSpacing.verticalSpaceLg,
              
              Container(
                padding: AppSpacing.paddingMd,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Guardian Token',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    AppSpacing.verticalSpaceXs,
                    SelectableText(
                      guardianToken,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              
              AppSpacing.verticalSpaceMd,
              
              Container(
                padding: AppSpacing.paddingMd,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.security,
                          size: 20,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                        AppSpacing.horizontalSpaceXs,
                        Text(
                          'Privacy Protected',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    AppSpacing.verticalSpaceXs,
                    Text(
                      'Guardians can only see:\n• Trip progress and location\n• Member check-in status\n• Safety information\n\nThey cannot access:\n• Chat messages\n• Personal photos\n• Member details',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
              
              AppSpacing.verticalSpaceMd,
              
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: guardianUrl));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Guardian link copied!')),
                        );
                      },
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('Copy Link'),
                    ),
                  ),
                  AppSpacing.horizontalSpaceSm,
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        // In a real app, this would open the guardian view
                        Navigator.of(context).pop();
                        context.go('/guardian/$tripId?token=$guardianToken');
                      },
                      icon: const Icon(Icons.preview, size: 16),
                      label: const Text('Preview'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Widget _buildTripStatusAndSchedule(BuildContext context, Trip trip) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final isActive = trip.status == TripStatus.active;
    final hasStarted = trip.startDate.isBefore(now);
    final hasEnded = trip.endDate.isBefore(now);
    
    // Determine current status
    String statusText;
    Color statusColor;
    IconData statusIcon;
    
    if (hasEnded) {
      statusText = 'Completed';
      statusColor = Colors.grey;
      statusIcon = Icons.check_circle;
    } else if (isActive && hasStarted) {
      statusText = 'In Progress';
      statusColor = Colors.green;
      statusIcon = Icons.play_circle;
    } else if (trip.status == TripStatus.planning) {
      statusText = 'Planning';
      statusColor = Colors.orange;
      statusIcon = Icons.schedule;
    } else {
      statusText = 'Upcoming';
      statusColor = Colors.blue;
      statusIcon = Icons.event;
    }

    // Get current schedule item (mock data)
    final currentSchedule = _getCurrentScheduleItem(trip);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Trip Status Card
        Card(
          child: Padding(
            padding: AppSpacing.paddingLg,
            child: Row(
              children: [
                Container(
                  padding: AppSpacing.paddingMd,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    statusIcon,
                    color: statusColor,
                    size: 32,
                  ),
                ),
                AppSpacing.horizontalSpaceMd,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Trip Status',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                      AppSpacing.verticalSpaceXs,
                      Text(
                        statusText,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                      AppSpacing.verticalSpaceXs,
                      Text(
                        '${_formatDate(trip.startDate)} - ${_formatDate(trip.endDate)}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isActive && hasStarted) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Text(
                      'LIVE',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        
        AppSpacing.verticalSpaceMd,
        
        // Current Schedule Card
        if (currentSchedule != null) ...[
          Card(
            child: Padding(
              padding: AppSpacing.paddingLg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        color: theme.colorScheme.primary,
                        size: 24,
                      ),
                      AppSpacing.horizontalSpaceSm,
                      Text(
                        'Current Activity',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      if (currentSchedule.isOngoing) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'NOW',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  AppSpacing.verticalSpaceMd,
                  Text(
                    currentSchedule.title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  AppSpacing.verticalSpaceXs,
                  Text(
                    currentSchedule.description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                  AppSpacing.verticalSpaceMd,
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: theme.colorScheme.outline,
                      ),
                      AppSpacing.horizontalSpaceXs,
                      Text(
                        '${_formatTime(currentSchedule.startTime)} - ${_formatTime(currentSchedule.endTime)}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                      const Spacer(),
                      if (currentSchedule.hasAction) ...[
                        FilledButton(
                          onPressed: () => _handleScheduleAction(context, currentSchedule),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(80, 32),
                          ),
                          child: Text(currentSchedule.actionText),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  ScheduleItem? _getCurrentScheduleItem(Trip trip) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Mock schedule data based on trip
    final scheduleItems = [
      ScheduleItem(
        title: 'Breakfast at Hotel',
        description: 'Meet in the hotel lobby for breakfast',
        startTime: DateTime(today.year, today.month, today.day, 8, 0),
        endTime: DateTime(today.year, today.month, today.day, 9, 30),
        isOngoing: now.hour >= 8 && now.hour < 9,
        hasAction: true,
        actionText: 'Check In',
      ),
      ScheduleItem(
        title: 'Beach Visit',
        description: 'Head to Calangute Beach for water activities',
        startTime: DateTime(today.year, today.month, today.day, 10, 0),
        endTime: DateTime(today.year, today.month, today.day, 14, 0),
        isOngoing: now.hour >= 10 && now.hour < 14,
        hasAction: true,
        actionText: 'Share Location',
      ),
      ScheduleItem(
        title: 'Lunch Break',
        description: 'Lunch at local restaurant',
        startTime: DateTime(today.year, today.month, today.day, 14, 30),
        endTime: DateTime(today.year, today.month, today.day, 16, 0),
        isOngoing: now.hour >= 14 && now.hour < 16,
        hasAction: false,
        actionText: '',
      ),
      ScheduleItem(
        title: 'Sunset Cruise',
        description: 'Evening cruise on Mandovi River',
        startTime: DateTime(today.year, today.month, today.day, 17, 0),
        endTime: DateTime(today.year, today.month, today.day, 19, 0),
        isOngoing: now.hour >= 17 && now.hour < 19,
        hasAction: true,
        actionText: 'Join',
      ),
    ];

    // Find current or next activity
    for (final item in scheduleItems) {
      if (item.isOngoing || item.startTime.isAfter(now)) {
        return item;
      }
    }
    
    return null;
  }

  void _handleScheduleAction(BuildContext context, ScheduleItem item) {
    switch (item.actionText) {
      case 'Check In':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Checked in for ${item.title}')),
        );
        break;
      case 'Share Location':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location shared for ${item.title}')),
        );
        break;
      case 'Join':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Joined ${item.title}')),
        );
        break;
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month]}';
  }

  String _formatTime(DateTime time) {
    final hour = time.hour;
    final minute = time.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '${displayHour}:${minute.toString().padLeft(2, '0')} $period';
  }
}

// Helper class for schedule items
class ScheduleItem {
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final bool isOngoing;
  final bool hasAction;
  final String actionText;

  ScheduleItem({
    required this.title,
    required this.description,
    required this.startTime,
    required this.endTime,
    required this.isOngoing,
    required this.hasAction,
    required this.actionText,
  });
}

