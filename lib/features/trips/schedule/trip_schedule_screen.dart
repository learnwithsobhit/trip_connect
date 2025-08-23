import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/providers/trip_provider.dart';
import '../../../core/data/models/models.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_colors.dart';

class TripScheduleScreen extends ConsumerWidget {
  final String tripId;

  const TripScheduleScreen({super.key, required this.tripId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tripAsync = ref.watch(tripProvider(tripId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule'),
        leading: IconButton(
          onPressed: () => context.go('/trips/$tripId'),
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [
          IconButton(
            onPressed: () => _showAddStopDialog(context),
            icon: const Icon(Icons.add_location_outlined),
            tooltip: 'Add Stop',
          ),
        ],
      ),
      body: tripAsync.when(
        data: (trip) {
          if (trip == null) {
            return const Center(child: Text('Trip not found'));
          }

          if (trip.schedule.isEmpty) {
            return _buildEmptySchedule(context, theme);
          }

          return _buildScheduleList(theme, trip);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddStopDialog(context),
        child: const Icon(Icons.add),
        tooltip: 'Add Schedule Item',
      ),
    );
  }

  Widget _buildEmptySchedule(BuildContext context, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.schedule,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          AppSpacing.verticalSpaceMd,
          Text(
            'No Schedule Yet',
            style: theme.textTheme.titleLarge,
          ),
          AppSpacing.verticalSpaceSm,
          Text(
            'Add schedule items to plan your trip',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          AppSpacing.verticalSpaceLg,
          FilledButton.icon(
            onPressed: () => _showAddStopDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Add First Item'),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleList(ThemeData theme, Trip trip) {
    // Group schedule items by day
    final scheduleByDay = <int, List<ScheduleItem>>{};
    for (final item in trip.schedule) {
      scheduleByDay.putIfAbsent(item.day, () => []).add(item);
    }

    return ListView.builder(
      padding: AppSpacing.paddingMd,
      itemCount: scheduleByDay.length,
      itemBuilder: (context, index) {
        final day = scheduleByDay.keys.elementAt(index);
        final dayItems = scheduleByDay[day]!;
        
        return _DayScheduleCard(
          day: day,
          items: dayItems,
          tripStartDate: trip.startDate,
        );
      },
    );
  }

  void _showAddStopDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Schedule Item'),
        content: const Text('Schedule management features coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _DayScheduleCard extends StatelessWidget {
  final int day;
  final List<ScheduleItem> items;
  final DateTime tripStartDate;

  const _DayScheduleCard({
    required this.day,
    required this.items,
    required this.tripStartDate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dayDate = tripStartDate.add(Duration(days: day - 1));

    return Card(
      margin: AppSpacing.paddingVerticalSm,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day header
          Container(
            width: double.infinity,
            padding: AppSpacing.paddingMd,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppSpacing.radiusXxl),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Day $day',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _formatDate(dayDate),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),

          // Schedule items
          Padding(
            padding: AppSpacing.paddingMd,
            child: Column(
              children: items.map((item) => _ScheduleItemTile(item: item)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    
    return '${weekdays[date.weekday - 1]}, ${date.day} ${months[date.month - 1]}';
  }
}

class _ScheduleItemTile extends StatelessWidget {
  final ScheduleItem item;

  const _ScheduleItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDelayed = item.actualStart != null && 
        item.actualStart!.isAfter(item.plannedStart);

    return Container(
      margin: AppSpacing.paddingVerticalXs,
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: isDelayed 
              ? AppColors.warning.withOpacity(0.5)
              : theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Item header
          Row(
            children: [
              Icon(
                _getTypeIcon(item.type),
                color: _getTypeColor(item.type),
                size: AppSpacing.iconMd,
              ),
              AppSpacing.horizontalSpaceSm,
              Expanded(
                child: Text(
                  item.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (isDelayed)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'DELAYED',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.warning,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),

          if (item.description?.isNotEmpty == true) ...[
            AppSpacing.verticalSpaceXs,
            Text(
              item.description!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],

          AppSpacing.verticalSpaceSm,

          // Timing info
          Row(
            children: [
              Icon(
                Icons.schedule,
                size: AppSpacing.iconSm,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              AppSpacing.horizontalSpaceXs,
              Text(
                '${_formatTime(item.plannedStart)} - ${_formatTime(item.plannedEnd)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (item.actualStart != null) ...[
                AppSpacing.horizontalSpaceMd,
                Text(
                  'Started: ${_formatTime(item.actualStart!)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDelayed ? AppColors.warning : AppColors.success,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),

          // Stops
          if (item.stops.isNotEmpty) ...[
            AppSpacing.verticalSpaceSm,
            ...item.stops.map((stop) => _StopChip(stop: stop)),
          ],
        ],
      ),
    );
  }

  IconData _getTypeIcon(ScheduleType type) {
    switch (type) {
      case ScheduleType.drive:
        return Icons.directions_car;
      case ScheduleType.activity:
        return Icons.local_activity;
      case ScheduleType.meal:
        return Icons.restaurant;
      case ScheduleType.rest:
        return Icons.hotel;
      case ScheduleType.sightseeing:
        return Icons.camera_alt;
    }
  }

  Color _getTypeColor(ScheduleType type) {
    switch (type) {
      case ScheduleType.drive:
        return AppColors.transportCar;
      case ScheduleType.activity:
        return AppColors.activityAdventure;
      case ScheduleType.meal:
        return AppColors.activityFood;
      case ScheduleType.rest:
        return AppColors.activityRest;
      case ScheduleType.sightseeing:
        return AppColors.activitySightseeing;
    }
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

class _StopChip extends StatelessWidget {
  final Stop stop;

  const _StopChip({required this.stop});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(right: 8, top: 4),
      child: Chip(
        avatar: Icon(
          _getStopIcon(stop.stopType),
          size: 16,
        ),
        label: Text(
          stop.name,
          style: theme.textTheme.labelSmall,
        ),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  IconData _getStopIcon(StopType type) {
    switch (type) {
      case StopType.food:
        return Icons.restaurant;
      case StopType.fuel:
        return Icons.local_gas_station;
      case StopType.restroom:
        return Icons.wc;
      case StopType.sightseeing:
        return Icons.camera_alt;
      case StopType.hotel:
        return Icons.hotel;
      case StopType.emergency:
        return Icons.local_hospital;
      case StopType.general:
        return Icons.place;
    }
  }
}