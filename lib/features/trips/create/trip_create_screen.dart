import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/data/providers/trip_provider.dart';
import '../../../core/data/models/models.dart';
import '../../../core/theme/app_spacing.dart';

class TripCreateScreen extends ConsumerStatefulWidget {
  const TripCreateScreen({super.key});

  @override
  ConsumerState<TripCreateScreen> createState() => _TripCreateScreenState();
}

class _TripCreateScreenState extends ConsumerState<TripCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _themeController = TextEditingController();
  final _originController = TextEditingController();
  final _destinationController = TextEditingController();
  final _seatsController = TextEditingController(text: '10');
  
  DateTime? _startDate;
  DateTime? _endDate;
  TripPrivacy _privacy = TripPrivacy.private;
  bool _isLoading = false;
  bool _showAiSuggestions = false;
  List<String> _aiSuggestions = [];
  String? _createdTripId;
  bool _showInviteQR = false;

  @override
  void dispose() {
    _nameController.dispose();
    _themeController.dispose();
    _originController.dispose();
    _destinationController.dispose();
    _seatsController.dispose();
    super.dispose();
  }

  Future<void> _generateAiSuggestions() async {
    if (_originController.text.isEmpty || _destinationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter origin and destination first')),
      );
      return;
    }

    setState(() => _showAiSuggestions = true);

    // Simulate AI processing
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _aiSuggestions = _getMockSuggestions();
      });
    }
  }

  List<String> _getMockSuggestions() {
    final origin = _originController.text.toLowerCase();
    final destination = _destinationController.text.toLowerCase();
    final theme = _themeController.text.toLowerCase();

    List<String> suggestions = [];

    // Route optimization suggestions
    if (destination.contains('goa')) {
      suggestions.addAll([
        '🛣️ Best route: Via NH48 → NH366 (avoid tolls on weekends)',
        '⏰ Recommended departure: 6:00 AM to avoid Mumbai traffic',
        '🍽️ Suggested stops: Lonavala (breakfast), Kolhapur (lunch)',
      ]);
    } else if (destination.contains('manali')) {
      suggestions.addAll([
        '🛣️ Scenic route: Via Chandigarh → Kullu Valley',
        '⏰ Best travel time: Early morning start (5:00 AM)',
        '🏔️ Suggested stops: Murthal (breakfast), Chandigarh (fuel)',
      ]);
    } else {
      suggestions.addAll([
        '🛣️ Optimized route calculated based on traffic patterns',
        '⏰ Recommended departure: 7:00 AM for best road conditions',
        '🍽️ Meal stops suggested every 3-4 hours of driving',
      ]);
    }

    // Theme-based suggestions
    if (theme.contains('beach')) {
      suggestions.addAll([
        '🏖️ Add water sports activities (2-3 hours)',
        '🌅 Plan sunrise/sunset viewing points',
        '🦀 Include seafood restaurant recommendations',
      ]);
    } else if (theme.contains('mountain') || theme.contains('trek')) {
      suggestions.addAll([
        '🥾 Pack trekking gear checklist',
        '🌡️ Check weather forecast for altitude changes',
        '🏕️ Consider camping spots for overnight stays',
      ]);
    }

    // Duration-based suggestions
    final duration = _endDate?.difference(_startDate ?? DateTime.now()).inDays ?? 0;
    if (duration >= 3) {
      suggestions.add('📅 Multi-day itinerary: Balance travel and exploration time');
    }

    return suggestions;
  }

  Future<void> _createTrip() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select start and end dates')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final tripsNotifier = ref.read(tripsProvider.notifier);
      final tripId = await tripsNotifier.createTrip(
        name: _nameController.text,
        theme: _themeController.text,
        origin: Location(
          name: _originController.text,
          lat: 0.0, // Mock coordinates
          lng: 0.0,
        ),
        destination: Location(
          name: _destinationController.text,
          lat: 0.0, // Mock coordinates
          lng: 0.0,
        ),
        startDate: _startDate!,
        endDate: _endDate!,
        seatsTotal: int.parse(_seatsController.text),
        privacy: _privacy,
      );

      if (mounted) {
        setState(() {
          _createdTripId = tripId;
          _showInviteQR = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create trip: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Show QR code dialog after trip creation
    if (_showInviteQR && _createdTripId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showInviteDialog();
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Trip'),
        leading: IconButton(
          onPressed: () => context.go('/'),
          icon: const Icon(Icons.close),
        ),
        actions: [
          if (_originController.text.isNotEmpty && _destinationController.text.isNotEmpty)
            IconButton(
              onPressed: _generateAiSuggestions,
              icon: const Icon(Icons.auto_awesome),
              tooltip: 'Get AI Suggestions',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: AppSpacing.paddingMd,
          children: [
            // Trip Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Trip Name',
                hintText: 'e.g., Goa Monsoon Adventure',
                prefixIcon: Icon(Icons.edit_outlined),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a trip name';
                }
                return null;
              },
            ),

            AppSpacing.verticalSpaceLg,

            // Theme
            TextFormField(
              controller: _themeController,
              decoration: const InputDecoration(
                labelText: 'Theme',
                hintText: 'e.g., Beach & Food, Mountains & Trekking',
                prefixIcon: Icon(Icons.palette_outlined),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a theme';
                }
                return null;
              },
            ),

            AppSpacing.verticalSpaceLg,

            // Origin
            TextFormField(
              controller: _originController,
              decoration: const InputDecoration(
                labelText: 'Starting Point',
                hintText: 'e.g., Pune, Mumbai',
                prefixIcon: Icon(Icons.my_location_outlined),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter starting point';
                }
                return null;
              },
            ),

            AppSpacing.verticalSpaceLg,

            // Destination
            TextFormField(
              controller: _destinationController,
              decoration: const InputDecoration(
                labelText: 'Destination',
                hintText: 'e.g., Goa, Manali',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter destination';
                }
                return null;
              },
            ),

            AppSpacing.verticalSpaceLg,

            // Date Range
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context, true),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Start Date',
                        prefixIcon: Icon(Icons.calendar_today_outlined),
                      ),
                      child: Text(
                        _startDate != null
                            ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                            : 'Select date',
                        style: _startDate != null
                            ? null
                            : TextStyle(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ),
                  ),
                ),
                AppSpacing.horizontalSpaceMd,
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context, false),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'End Date',
                        prefixIcon: Icon(Icons.event_outlined),
                      ),
                      child: Text(
                        _endDate != null
                            ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                            : 'Select date',
                        style: _endDate != null
                            ? null
                            : TextStyle(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            AppSpacing.verticalSpaceLg,

            // Total Seats
            TextFormField(
              controller: _seatsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Total Seats',
                hintText: 'Number of people',
                prefixIcon: Icon(Icons.people_outlined),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter number of seats';
                }
                final seats = int.tryParse(value);
                if (seats == null || seats < 1 || seats > 100) {
                  return 'Please enter a valid number (1-100)';
                }
                return null;
              },
            ),

            AppSpacing.verticalSpaceLg,

            // AI Suggestions
            if (_showAiSuggestions) ...[
              _buildAiSuggestions(theme),
              AppSpacing.verticalSpaceLg,
            ],

            // Privacy Setting
            Card(
              child: Padding(
                padding: AppSpacing.paddingMd,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Privacy',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    AppSpacing.verticalSpaceSm,
                    RadioListTile<TripPrivacy>(
                      title: const Text('Private'),
                      subtitle: const Text('Only invited members can join'),
                      value: TripPrivacy.private,
                      groupValue: _privacy,
                      onChanged: (value) => setState(() => _privacy = value!),
                    ),
                    RadioListTile<TripPrivacy>(
                      title: const Text('Public'),
                      subtitle: const Text('Anyone with the code can join'),
                      value: TripPrivacy.public,
                      groupValue: _privacy,
                      onChanged: (value) => setState(() => _privacy = value!),
                    ),
                  ],
                ),
              ),
            ),

            AppSpacing.verticalSpaceXxl,

            // Create Button
            SizedBox(
              height: AppSpacing.buttonHeightLg,
              child: FilledButton(
                onPressed: _isLoading ? null : _createTrip,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Create Trip',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),

            AppSpacing.verticalSpaceLg,
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final initialDate = DateTime.now();
    final firstDate = DateTime.now();
    final lastDate = DateTime.now().add(const Duration(days: 365));

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (selectedDate != null) {
      setState(() {
        if (isStartDate) {
          _startDate = selectedDate;
          // If end date is before start date, clear it
          if (_endDate != null && _endDate!.isBefore(selectedDate)) {
            _endDate = null;
          }
        } else {
          if (_startDate != null && selectedDate.isBefore(_startDate!)) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('End date cannot be before start date')),
            );
          } else {
            _endDate = selectedDate;
          }
        }
      });
    }
  }

  Widget _buildAiSuggestions(ThemeData theme) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: AppSpacing.paddingMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                AppSpacing.horizontalSpaceSm,
                Text(
                  'AI Itinerary Copilot',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const Spacer(),
                if (_aiSuggestions.isEmpty)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            AppSpacing.verticalSpaceSm,
            
            if (_aiSuggestions.isEmpty) ...[
              Text(
                'Analyzing your trip details...',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ] else ...[
              Text(
                'Here are some smart recommendations for your trip:',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              AppSpacing.verticalSpaceSm,
              
              ...(_aiSuggestions.map((suggestion) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 4,
                      height: 4,
                      margin: const EdgeInsets.only(top: 8, right: 8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        suggestion,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ))),
              
              AppSpacing.verticalSpaceSm,
              
              Row(
                children: [
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Suggestions applied to your itinerary!'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Apply Suggestions'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showInviteDialog() {
    if (_createdTripId == null) return;
    
    final inviteCode = 'TC${_createdTripId!.substring(0, 6).toUpperCase()}';
    final inviteUrl = 'https://tripconnect.app/join/$inviteCode';
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.celebration,
              color: Theme.of(context).colorScheme.primary,
            ),
            AppSpacing.horizontalSpaceSm,
            const Text('Trip Created!'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Your trip "${_nameController.text}" has been created successfully!',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              
              AppSpacing.verticalSpaceLg,
              
              Container(
                padding: AppSpacing.paddingMd,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      'Invite Code',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    AppSpacing.verticalSpaceXs,
                    SelectableText(
                      inviteCode,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
              
              AppSpacing.verticalSpaceLg,
              
              // QR Code
              Container(
                padding: AppSpacing.paddingMd,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    QrImageView(
                      data: inviteUrl,
                      version: QrVersions.auto,
                      size: 160,
                      backgroundColor: Colors.white,
                    ),
                    AppSpacing.verticalSpaceSm,
                    Text(
                      'Scan to join trip',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              
              AppSpacing.verticalSpaceLg,
              
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: inviteCode));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Invite code copied!')),
                        );
                      },
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('Copy Code'),
                    ),
                  ),
                  AppSpacing.horizontalSpaceSm,
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        // Share functionality would go here
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Share functionality coming soon!')),
                        );
                      },
                      icon: const Icon(Icons.share, size: 16),
                      label: const Text('Share'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/');
            },
            child: const Text('Done'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/trips/$_createdTripId');
            },
            child: const Text('View Trip'),
          ),
        ],
      ),
    );
    
    setState(() => _showInviteQR = false);
  }
}

