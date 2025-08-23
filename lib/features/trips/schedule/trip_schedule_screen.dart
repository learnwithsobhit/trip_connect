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
        heroTag: 'schedule-add-item',
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
      builder: (context) => _AddScheduleItemDialog(tripId: tripId),
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

class _AddScheduleItemDialog extends StatefulWidget {
  final String tripId;

  const _AddScheduleItemDialog({required this.tripId});

  @override
  State<_AddScheduleItemDialog> createState() => _AddScheduleItemDialogState();
}

class _AddScheduleItemDialogState extends State<_AddScheduleItemDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  
  ScheduleType _selectedType = ScheduleType.activity;
  int _selectedDay = 1;
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 0);
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Add Schedule Item'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Type Selection
              DropdownButtonFormField<ScheduleType>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Type',
                  border: OutlineInputBorder(),
                ),
                items: ScheduleType.values.map((type) => DropdownMenuItem(
                  value: type,
                  child: Row(
                    children: [
                      Icon(_getTypeIcon(type)),
                      const SizedBox(width: 8),
                      Text(_getTypeName(type)),
                    ],
                  ),
                )).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedType = value!;
                  });
                },
              ),
              
              const SizedBox(height: 16),
              
              // Day Selection
              DropdownButtonFormField<int>(
                value: _selectedDay,
                decoration: const InputDecoration(
                  labelText: 'Day',
                  border: OutlineInputBorder(),
                ),
                items: List.generate(7, (index) => DropdownMenuItem(
                  value: index + 1,
                  child: Text('Day ${index + 1}'),
                )),
                onChanged: (value) {
                  setState(() {
                    _selectedDay = value!;
                  });
                },
              ),
              
              const SizedBox(height: 16),
              
              // Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              
              const SizedBox(height: 16),
              
              // Location
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  border: OutlineInputBorder(),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Time Selection
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      title: const Text('Start Time'),
                      subtitle: Text(_startTime.format(context)),
                      trailing: const Icon(Icons.access_time),
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: _startTime,
                        );
                        if (time != null) {
                          setState(() {
                            _startTime = time;
                          });
                        }
                      },
                    ),
                  ),
                  Expanded(
                    child: ListTile(
                      title: const Text('End Time'),
                      subtitle: Text(_endTime.format(context)),
                      trailing: const Icon(Icons.access_time),
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: _endTime,
                        );
                        if (time != null) {
                          setState(() {
                            _endTime = time;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _addScheduleItem,
          child: _isLoading 
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Add'),
        ),
      ],
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

  String _getTypeName(ScheduleType type) {
    switch (type) {
      case ScheduleType.drive:
        return 'Drive';
      case ScheduleType.activity:
        return 'Activity';
      case ScheduleType.meal:
        return 'Meal';
      case ScheduleType.rest:
        return 'Rest';
      case ScheduleType.sightseeing:
        return 'Sightseeing';
    }
  }

  void _addScheduleItem() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));
      
      // In real app, this would add the schedule item to the trip
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Schedule item added successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding schedule item: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}