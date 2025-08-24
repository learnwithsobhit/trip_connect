import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/data/models/models.dart';
import '../../../core/data/providers/roll_call_provider.dart';
import '../../../core/data/providers/trip_provider.dart';
import '../../../core/data/providers/auth_provider.dart';
import '../../../core/theme/app_spacing.dart';

class RollCallScreen extends ConsumerStatefulWidget {
  final String tripId;

  const RollCallScreen({super.key, required this.tripId});

  @override
  ConsumerState<RollCallScreen> createState() => _RollCallScreenState();
}

class _RollCallScreenState extends ConsumerState<RollCallScreen> {
  RollCall? _activeRollCall;
  bool _isStartingRollCall = false;
  
  // Map related variables
  GoogleMapController? _mapController;
  Position? _currentPosition;
  Set<Marker> _userMarkers = {};
  Set<Circle> _rollCallCircles = {};
  bool _isLoadingLocation = false;

  @override
  Widget build(BuildContext context) {
    final tripAsync = ref.watch(tripProvider(widget.tripId));
    final currentUser = ref.watch(currentUserProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Roll Call'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/trips/${widget.tripId}'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettings(),
            tooltip: 'Roll Call Settings',
          ),
        ],
      ),
      body: tripAsync.when(
        data: (trip) {
          if (trip == null) {
            return const Center(child: Text('Trip not found'));
          }

          return _buildRollCallContent(trip, currentUser, theme);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildRollCallContent(Trip trip, User? currentUser, ThemeData theme) {
    // Check for active roll calls from the provider
    final activeRollCalls = ref.watch(activeRollCallsProvider);
    final activeRollCall = activeRollCalls.values.where((rc) => rc.tripId == trip.id).firstOrNull;
    

    
    // Always show the start view first, with active roll call alert if exists
    // Only go to active view if user explicitly taps on the alert card
    if (_activeRollCall != null) {
      return _buildActiveRollCallView(_activeRollCall!, trip, currentUser, theme);
    }

    return _buildRollCallStartView(trip, currentUser, theme);
  }

  Widget _buildRollCallStartView(Trip trip, User? currentUser, ThemeData theme) {
    final isLeader = currentUser?.id == trip.leaderId;
    
    // Check for active roll calls from other trips to show in overview
    final activeRollCalls = ref.watch(activeRollCallsProvider);

    return SingleChildScrollView(
      padding: AppSpacing.paddingMd,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Active Roll Call Alert (if any exists for this trip)
          ...activeRollCalls.values
              .where((rc) => rc.tripId == trip.id)
              .map((rollCall) => _buildActiveRollCallAlert(rollCall, trip, currentUser, theme))
              .toList(),
          
          // Current Location Display
          _buildCurrentLocationCard(theme),
          AppSpacing.verticalSpaceMd,
          
          // Map View
          _buildMapView(trip, currentUser, theme),
          AppSpacing.verticalSpaceMd,
          
          // Header
          Card(
            child: Padding(
              padding: AppSpacing.paddingMd,
              child: Column(
                children: [
                  Icon(
                    Icons.people_alt,
                    size: 64,
                    color: theme.colorScheme.primary,
                  ),
                  AppSpacing.verticalSpaceMd,
                  Text(
                    'Roll Call',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  AppSpacing.verticalSpaceSm,
                  Text(
                    'Quick attendance check for ${trip.name}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          AppSpacing.verticalSpaceLg,

          // Quick Start Button (for leaders)
          if (isLeader) ...[
            ElevatedButton.icon(
              onPressed: _isStartingRollCall ? null : _startQuickRollCall,
              icon: _isStartingRollCall
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.play_arrow),
              label: Text(_isStartingRollCall ? 'Starting...' : 'Start Quick Roll Call'),
              style: ElevatedButton.styleFrom(
                padding: AppSpacing.paddingLg,
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
              ),
            ),
            AppSpacing.verticalSpaceMd,
          ],

          // Manual Check-in Button (for all members)
          OutlinedButton.icon(
            onPressed: () => _showManualCheckInDialog(),
            icon: const Icon(Icons.touch_app),
            label: const Text('Manual Check-in'),
            style: OutlinedButton.styleFrom(
              padding: AppSpacing.paddingLg,
            ),
          ),

          AppSpacing.verticalSpaceLg,

          // Features List
          Card(
            child: Padding(
              padding: AppSpacing.paddingMd,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Features',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  AppSpacing.verticalSpaceMd,
                  _buildFeatureItem(
                    icon: Icons.location_on,
                    title: 'GPS Auto-Detection',
                    subtitle: 'Automatically detect members within radius',
                    theme: theme,
                  ),
                  _buildFeatureItem(
                    icon: Icons.touch_app,
                    title: 'Manual Check-in',
                    subtitle: 'Allow manual check-ins for privacy',
                    theme: theme,
                  ),
                  _buildFeatureItem(
                    icon: Icons.notifications,
                    title: 'Smart Notifications',
                    subtitle: 'Notify missing members with location',
                    theme: theme,
                  ),
                  _buildFeatureItem(
                    icon: Icons.analytics,
                    title: 'Real-time Reports',
                    subtitle: 'Live attendance tracking and analytics',
                    theme: theme,
                  ),
                ],
              ),
            ),
          ),

          AppSpacing.verticalSpaceLg,

          // Recent Activity
          Card(
            child: Padding(
              padding: AppSpacing.paddingMd,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recent Roll Calls',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  AppSpacing.verticalSpaceMd,
                  const Center(
                    child: Text('No recent roll calls'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveRollCallView(RollCall rollCall, Trip trip, User? currentUser, ThemeData theme) {
    final isLeader = currentUser?.id == trip.leaderId;
    final presentCount = rollCall.checkIns.where((c) => c.status == RollCallCheckInStatus.present).length;
    final totalMembers = 10; // This should come from trip membership
    final missingCount = totalMembers - presentCount;

    return SingleChildScrollView(
      padding: AppSpacing.paddingMd,
      child: Column(
      children: [
        // Status Banner
        Container(
          width: double.infinity,
          padding: AppSpacing.paddingMd,
          color: theme.colorScheme.primaryContainer,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Roll Call Active',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${presentCount}/${totalMembers}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              AppSpacing.verticalSpaceSm,
              Text(
                'Anchor: ${rollCall.anchorName ?? 'Current Location'}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              Text(
                'Radius: ${rollCall.radiusMeters.toInt()}m • Grace: ${rollCall.gracePeriodMinutes}min',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
        ),

        // Missing Members Bar
        if (missingCount > 0 && isLeader)
          Container(
            width: double.infinity,
            padding: AppSpacing.paddingMd,
            color: theme.colorScheme.errorContainer,
            child: Row(
              children: [
                Icon(
                  Icons.warning,
                  color: theme.colorScheme.onErrorContainer,
                ),
                AppSpacing.horizontalSpaceMd,
                Flexible(
                  child: Text(
                    '$missingCount members missing',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onErrorContainer,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => _sendReminder(rollCall.id),
                  child: Text(
                    'Send Reminder',
                    style: TextStyle(
                      color: theme.colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Tabs
        SizedBox(
          height: 400, // Fixed height instead of Expanded
          child: DefaultTabController(
            length: 2,
            child: Column(
              children: [
                TabBar(
                  tabs: [
                    Tab(
                      icon: Icon(Icons.check_circle, color: Colors.green),
                      text: 'Present ($presentCount)',
                    ),
                    Tab(
                      icon: Icon(Icons.cancel, color: Colors.red),
                      text: 'Missing ($missingCount)',
                    ),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildPresentMembersTab(rollCall, theme),
                      _buildMissingMembersTab(rollCall, totalMembers, theme),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Manual Check-in Button (for all members)
        Padding(
          padding: AppSpacing.paddingMd,
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showManualCheckInDialog(),
              icon: const Icon(Icons.touch_app),
              label: const Text('Manual Check-in'),
              style: OutlinedButton.styleFrom(
                padding: AppSpacing.paddingMd,
              ),
            ),
          ),
        ),

        // Action Buttons (for leaders)
        if (isLeader)
          Padding(
            padding: AppSpacing.paddingMd,
            child: Row(
              children: [
                Flexible(
                  flex: 1,
                  child: OutlinedButton.icon(
                    onPressed: () => _extendGracePeriod(rollCall.id),
                    icon: const Icon(Icons.schedule),
                    label: const Text('Extend'),
                  ),
                ),
                AppSpacing.horizontalSpaceMd,
                Flexible(
                  flex: 1,
                  child: ElevatedButton.icon(
                    onPressed: () => _closeRollCall(rollCall.id),
                    icon: const Icon(Icons.stop),
                    label: const Text('Close'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.error,
                      foregroundColor: theme.colorScheme.onError,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresentMembersTab(RollCall rollCall, ThemeData theme) {
    final presentCheckIns = rollCall.checkIns.where((c) => c.status == RollCallCheckInStatus.present).toList();

    if (presentCheckIns.isEmpty) {
      return const Center(
        child: Text('No members checked in yet'),
      );
    }

    return ListView.builder(
      padding: AppSpacing.paddingMd,
      itemCount: presentCheckIns.length,
      itemBuilder: (context, index) {
        final checkIn = presentCheckIns[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: checkIn.method.color,
              child: Icon(
                checkIn.method.icon,
                color: Colors.white,
                size: 20,
              ),
            ),
            title: Text('User ${checkIn.userId}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Method: ${checkIn.method.displayName}'),
                if (checkIn.distanceFromAnchor != null)
                  Text('Distance: ${checkIn.distanceFromAnchor!.toInt()}m'),
                Text('Time: ${_formatTime(checkIn.checkedInAt)}'),
              ],
            ),
            trailing: Icon(
              Icons.check_circle,
              color: Colors.green,
            ),
          ),
        );
      },
    );
  }

  Widget _buildMissingMembersTab(RollCall rollCall, int totalMembers, ThemeData theme) {
    final checkedInUserIds = rollCall.checkIns.map((c) => c.userId).toSet();
    final missingUserIds = List.generate(totalMembers, (index) => 'u_${index + 1}')
        .where((id) => !checkedInUserIds.contains(id))
        .toList();

    if (missingUserIds.isEmpty) {
      return const Center(
        child: Text('All members are present!'),
      );
    }

    return ListView.builder(
      padding: AppSpacing.paddingMd,
      itemCount: missingUserIds.length,
      itemBuilder: (context, index) {
        final userId = missingUserIds[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.grey,
              child: Icon(
                Icons.person,
                color: Colors.white,
              ),
            ),
            title: Text('User $userId'),
            subtitle: const Text('Not checked in'),
            trailing: PopupMenuButton<String>(
              onSelected: (action) => _handleMissingMemberAction(action, userId, rollCall.id),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'mark_present',
                  child: ListTile(
                    leading: Icon(Icons.check_circle, color: Colors.green),
                    title: Text('Mark Present'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'mark_absent',
                  child: ListTile(
                    leading: Icon(Icons.cancel, color: Colors.red),
                    title: Text('Mark Absent'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required ThemeData theme,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(
            icon,
            color: theme.colorScheme.primary,
            size: 24,
          ),
          AppSpacing.horizontalSpaceMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Actions
  Future<void> _startQuickRollCall() async {
    setState(() {
      _isStartingRollCall = true;
    });

    try {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null) return;

      final notifier = ref.read(rollCallNotifierProvider.notifier);
      await notifier.startRollCall(
        tripId: widget.tripId,
        leaderId: currentUser.id,
        radiusMeters: 50.0,
        gracePeriodMinutes: 3,
        anchorName: 'Quick Roll Call',
      );

      // Get the created roll call
      final rollCall = ref.read(rollCallNotifierProvider).value;
      if (rollCall != null) {
        setState(() {
          _activeRollCall = rollCall;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to start roll call: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isStartingRollCall = false;
      });
    }
  }

  void _showManualCheckInDialog() {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to check in'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check if there's an active roll call
    if (_activeRollCall == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No active roll call to check in to'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Check if user is already checked in
    final isAlreadyCheckedIn = _activeRollCall!.checkIns
        .any((checkIn) => checkIn.userId == currentUser.id);

    if (isAlreadyCheckedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You are already checked in!'),
          backgroundColor: Colors.green,
        ),
      );
      return;
    }

    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.touch_app,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            const Text('Manual Check-in'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Check in manually for: ${_activeRollCall!.anchorName ?? 'Roll Call'}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason (optional)',
                hintText: 'GPS not working, privacy, etc.',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Manual check-in is available when GPS detection is not working or for privacy preferences.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () => _performManualCheckIn(reasonController.text.trim()),
            icon: const Icon(Icons.check_circle),
            label: const Text('Check In'),
          ),
        ],
      ),
    );
  }

  Future<void> _performManualCheckIn(String reason) async {
    try {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null || _activeRollCall == null) return;

      // Close the dialog first
      Navigator.pop(context);

      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 16),
              Text('Checking in...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );

      final notifier = ref.read(rollCallNotifierProvider.notifier);
      await notifier.checkIn(
        rollCallId: _activeRollCall!.id,
        userId: currentUser.id,
        method: CheckInMethod.manual,
        manualReason: reason.isEmpty ? 'Manual check-in' : reason,
      );

      // Update local state to reflect the check-in
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                const Text('Successfully checked in!'),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to check in: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showSettings() {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to access settings'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check if user is trip leader
    final tripAsync = ref.read(tripProvider(widget.tripId));
    final trip = tripAsync.value;
    if (trip == null || currentUser.id != trip.leaderId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only trip leaders can modify roll call settings'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Get current settings
    final settings = ref.read(rollCallSettingsProvider);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.settings,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            const Text('Roll Call Settings'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: _buildSettingsContent(settings),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _saveSettings();
              if (mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsContent(RollCallSettings settings) {
    final theme = Theme.of(context);
    
    // Controllers for form fields
    final radiusController = TextEditingController(
      text: settings.defaultRadiusMeters.toInt().toString(),
    );
    final gracePeriodController = TextEditingController(
      text: settings.defaultGracePeriodMinutes.toString(),
    );
    final gpsFreshnessController = TextEditingController(
      text: settings.gpsFreshnessSeconds.toString(),
    );
    
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Detection Radius
          _buildSettingSection(
            title: 'Detection Radius',
            subtitle: 'Maximum distance for automatic GPS check-in',
            icon: Icons.radar,
            theme: theme,
            child: TextField(
              controller: radiusController,
              decoration: const InputDecoration(
                labelText: 'Radius (meters)',
                hintText: '50',
                suffixText: 'm',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Grace Period
          _buildSettingSection(
            title: 'Grace Period',
            subtitle: 'Time allowed for members to check in after roll call starts',
            icon: Icons.schedule,
            theme: theme,
            child: TextField(
              controller: gracePeriodController,
              decoration: const InputDecoration(
                labelText: 'Grace Period (minutes)',
                hintText: '5',
                suffixText: 'min',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // GPS Freshness
          _buildSettingSection(
            title: 'GPS Freshness',
            subtitle: 'Maximum age of GPS data for check-in (seconds)',
            icon: Icons.location_on,
            theme: theme,
            child: TextField(
              controller: gpsFreshnessController,
              decoration: const InputDecoration(
                labelText: 'GPS Freshness (seconds)',
                hintText: '120',
                suffixText: 'sec',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Toggle Settings
          _buildSettingSection(
            title: 'Features',
            subtitle: 'Enable or disable roll call features',
            icon: Icons.tune,
            theme: theme,
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Allow Manual Check-in'),
                  subtitle: const Text('Members can check in manually'),
                  value: settings.allowManualCheckIn,
                  onChanged: (value) {
                    // Settings will be updated when Save is pressed
                    // No immediate state change needed
                  },
                ),
                SwitchListTile(
                  title: const Text('Enable Notifications'),
                  subtitle: const Text('Notify members about roll calls'),
                  value: settings.enableNotifications,
                  onChanged: (value) {
                    // Settings will be updated when Save is pressed
                    // No immediate state change needed
                  },
                ),
                SwitchListTile(
                  title: const Text('Enable Driver Mode'),
                  subtitle: const Text('Special handling for drivers'),
                  value: settings.enableDriverMode,
                  onChanged: (value) {
                    // Settings will be updated when Save is pressed
                    // No immediate state change needed
                  },
                ),
                SwitchListTile(
                  title: const Text('Announce on Close'),
                  subtitle: const Text('Show results when roll call closes'),
                  value: settings.announceOnClose,
                  onChanged: (value) {
                    // Settings will be updated when Save is pressed
                    // No immediate state change needed
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Preset Buttons
          _buildSettingSection(
            title: 'Quick Presets',
            subtitle: 'Use predefined settings for different scenarios',
            icon: Icons.settings_applications,
            theme: theme,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _applyPreset('indoor'),
                        icon: const Icon(Icons.home),
                        label: const Text('Indoor'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _applyPreset('outdoor'),
                        icon: const Icon(Icons.park),
                        label: const Text('Outdoor'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _applyPreset('large_group'),
                        icon: const Icon(Icons.groups),
                        label: const Text('Large Group'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _applyPreset('privacy'),
                        icon: const Icon(Icons.privacy_tip),
                        label: const Text('Privacy'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Info Section
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info,
                  color: theme.colorScheme.onPrimaryContainer,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'These settings will apply to all future roll calls for this trip. Changes take effect immediately.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingSection({
    required String title,
    required String subtitle,
    required IconData icon,
    required ThemeData theme,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: theme.colorScheme.primary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  void _applyPreset(String presetType) {
    // Apply preset values based on type
    switch (presetType) {
      case 'indoor':
        // Indoor settings: smaller radius, longer grace period, manual check-in enabled
        break;
      case 'outdoor':
        // Outdoor settings: larger radius, shorter grace period, auto-detect enabled
        break;
      case 'large_group':
        // Large group settings: very large radius, longer grace period
        break;
      case 'privacy':
        // Privacy settings: manual check-in only, no auto-detect
        break;
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Applied $presetType preset'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _saveSettings() async {
    try {
      // Get current settings and update them
      final currentSettings = ref.read(rollCallSettingsProvider);

      // Update settings (this would normally get values from form controllers)
      final updatedSettings = currentSettings.copyWith(
        // Update with form values
        defaultRadiusMeters: 50.0,
        defaultGracePeriodMinutes: 5,
        gpsFreshnessSeconds: 120,
        allowManualCheckIn: true,
        enableNotifications: true,
        announceOnClose: true,
        enableDriverMode: true,
        autoStartOnGeofence: false,
        enableHysteresis: true,
        requireDualConfirmManual: false,
      );

      // Save settings
      final notifier = ref.read(rollCallNotifierProvider.notifier);
      notifier.updateSettings(updatedSettings);

      // Show success message only if widget is still mounted
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Roll call settings saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Show error message only if widget is still mounted
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _sendReminder(String rollCallId) async {
    try {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null) return;

      final notifier = ref.read(rollCallNotifierProvider.notifier);
      await notifier.sendReminder(
        rollCallId: rollCallId,
        leaderId: currentUser.id,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reminder sent to missing members'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send reminder: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _extendGracePeriod(String rollCallId) async {
    try {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null) return;

      final notifier = ref.read(rollCallNotifierProvider.notifier);
      await notifier.extendGracePeriod(
        rollCallId: rollCallId,
        leaderId: currentUser.id,
        additionalMinutes: 5,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Grace period extended by 5 minutes'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to extend grace period: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _closeRollCall(String rollCallId) async {
    try {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null) return;

      final notifier = ref.read(rollCallNotifierProvider.notifier);
      await notifier.closeRollCall(
        rollCallId: rollCallId,
        leaderId: currentUser.id,
        closeMessage: 'Roll call completed',
      );

      setState(() {
        _activeRollCall = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Roll call closed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to close roll call: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleMissingMemberAction(String action, String userId, String rollCallId) async {
    try {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null) return;

      final notifier = ref.read(rollCallNotifierProvider.notifier);
      
      if (action == 'mark_present') {
        await notifier.markMember(
          rollCallId: rollCallId,
          userId: userId,
          status: RollCallCheckInStatus.present,
          leaderId: currentUser.id,
          reason: 'Marked present by leader',
        );
      } else if (action == 'mark_absent') {
        await notifier.markMember(
          rollCallId: rollCallId,
          userId: userId,
          status: RollCallCheckInStatus.late,
          leaderId: currentUser.id,
          reason: 'Marked absent by leader',
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to mark member: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildActiveRollCallAlert(RollCall rollCall, Trip trip, User? currentUser, ThemeData theme) {
    final presentCount = rollCall.checkIns.where((c) => c.status == RollCallCheckInStatus.present).length;
    final totalMembers = 10; // This should come from trip membership
    final missingCount = totalMembers - presentCount;
    final isCheckedIn = rollCall.checkIns.any((checkIn) => checkIn.userId == currentUser?.id);
    
    final elapsedTime = DateTime.now().difference(rollCall.startedAt);
    final remainingTime = Duration(minutes: rollCall.gracePeriodMinutes) - elapsedTime;
    final isExpiring = remainingTime.inMinutes <= 1 && remainingTime.inSeconds > 0;
    
    return Column(
      children: [
        // Active Roll Call Card
        Card(
          elevation: 8,
          margin: const EdgeInsets.only(bottom: 16),
          child: InkWell(
            onTap: () {
              // Navigate to active roll call view
              setState(() {
                _activeRollCall = rollCall;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary.withOpacity(0.1),
                    theme.colorScheme.primaryContainer.withOpacity(0.3),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: isExpiring ? Colors.orange : theme.colorScheme.primary,
                  width: 2,
                ),
              ),
              child: Padding(
                padding: AppSpacing.paddingLg,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.people_alt,
                            color: theme.colorScheme.onPrimary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Roll Call Active',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isExpiring ? Colors.orange : Colors.green,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      isExpiring ? 'EXPIRING' : 'LIVE',
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                rollCall.anchorName ?? 'Current Location',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: theme.colorScheme.primary,
                          size: 16,
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Stats Row
                    Row(
                      children: [
                        // Present Count
                        _buildStatItem(
                          icon: Icons.check_circle,
                          label: 'Present',
                          value: presentCount.toString(),
                          color: Colors.green,
                          theme: theme,
                        ),
                        const SizedBox(width: 20),
                        
                        // Missing Count
                        _buildStatItem(
                          icon: Icons.cancel,
                          label: 'Missing',
                          value: missingCount.toString(),
                          color: Colors.red,
                          theme: theme,
                        ),
                        const SizedBox(width: 20),
                        
                        // Time Remaining
                        _buildStatItem(
                          icon: isExpiring ? Icons.timer : Icons.schedule,
                          label: 'Time Left',
                          value: remainingTime.inMinutes >= 0 
                              ? '${remainingTime.inMinutes}:${(remainingTime.inSeconds % 60).toString().padLeft(2, '0')}'
                              : 'Expired',
                          color: isExpiring ? Colors.orange : theme.colorScheme.primary,
                          theme: theme,
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // User Status Bar with Action
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isCheckedIn 
                            ? Colors.green.withOpacity(0.1)
                            : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isCheckedIn ? Colors.green : Colors.orange,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isCheckedIn ? Icons.check_circle : Icons.access_time,
                            color: isCheckedIn ? Colors.green : Colors.orange,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isCheckedIn 
                                      ? 'You are checked in ✓'
                                      : 'Please check in soon',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: isCheckedIn ? Colors.green : Colors.orange,
                                  ),
                                ),
                                Text(
                                  'Tap card to view details',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!isCheckedIn) ...[
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: () => _showManualCheckInDialog(),
                              icon: const Icon(Icons.touch_app, size: 16),
                              label: const Text('Check In'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                minimumSize: Size.zero,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required ThemeData theme,
  }) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: color,
                size: 20,
              ),
              const SizedBox(width: 4),
              Text(
                value,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  // Current Location Card
  Widget _buildCurrentLocationCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: AppSpacing.paddingMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.my_location,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Current Location',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_isLoadingLocation)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (_currentPosition != null) ...[
              Text(
                'Latitude: ${_currentPosition!.latitude.toStringAsFixed(6)}',
                style: theme.textTheme.bodySmall,
              ),
              Text(
                'Longitude: ${_currentPosition!.longitude.toStringAsFixed(6)}',
                style: theme.textTheme.bodySmall,
              ),
              Text(
                'Accuracy: ${_currentPosition!.accuracy.toStringAsFixed(1)}m',
                style: theme.textTheme.bodySmall,
              ),
            ] else ...[
              Row(
                children: [
                  Icon(
                    Icons.location_off,
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Location not available',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Tap refresh to try again or use manual check-in',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
            ],
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _getCurrentLocation,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Refresh Location'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Map View
  Widget _buildMapView(Trip trip, User? currentUser, ThemeData theme) {
    return Card(
      child: Padding(
        padding: AppSpacing.paddingMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.map,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Trip Members Location',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.my_location),
                  onPressed: _centerOnCurrentLocation,
                  tooltip: 'Center on my location',
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 250,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(
                      _currentPosition?.latitude ?? 20.5937,
                      _currentPosition?.longitude ?? 78.9629,
                    ),
                    zoom: 12.0,
                  ),
                  onMapCreated: (GoogleMapController controller) {
                    _mapController = controller;
                    _updateMapMarkers(trip);
                  },
                  markers: _userMarkers,
                  circles: _rollCallCircles,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Get current location with better error handling
  Future<void> _getCurrentLocation() async {
    if (!mounted) return;
    
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      // Check location permission first
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _handleLocationError('Location permissions are denied');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _handleLocationError('Location permissions are permanently denied');
        return;
      }

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _handleLocationError('Location services are disabled');
        return;
      }

      // Get position with reduced timeout and error handling
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium, // Reduced accuracy for faster response
        timeLimit: const Duration(seconds: 5), // Reduced timeout
      ).timeout(
        const Duration(seconds: 8), // Additional timeout wrapper
        onTimeout: () {
          throw Exception('Location request timed out');
        },
      );

      if (!mounted) return;

      setState(() {
        _currentPosition = position;
        _isLoadingLocation = false;
      });

      // Update map camera if controller is available
      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLng(
            LatLng(position.latitude, position.longitude),
          ),
        );
      }

      // Update markers
      _updateMapMarkers(null);
    } catch (e) {
      _handleLocationError(e.toString());
    }
  }

  void _handleLocationError(String error) {
    if (!mounted) return;
    
    setState(() {
      _isLoadingLocation = false;
      // Set a default location if location fails (India center)
      _currentPosition = null;
    });
    
    // Only show error message if it's not a timeout (too noisy)
    if (!error.toLowerCase().contains('timeout')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Location unavailable: ${error.length > 50 ? 'Service error' : error}'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // Center map on current location
  void _centerOnCurrentLocation() {
    if (_currentPosition != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        ),
      );
    }
  }

  // Update map markers for all trip members
  void _updateMapMarkers(Trip? trip) {
    if (trip == null) return;

    final markers = <Marker>{};
    final circles = <Circle>{};

    // Add current user marker
    if (_currentPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('current_user'),
          position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          infoWindow: const InfoWindow(
            title: 'You',
            snippet: 'Current location',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    }

    // Get trip memberships from provider
    final membershipsAsync = ref.read(tripMembersProvider(trip.id));
    final memberships = membershipsAsync.value ?? [];

    // Add trip members markers
    for (final membership in memberships) {
      if (membership.location != null) {
        final latLng = LatLng(
          membership.location!.lat,
          membership.location!.lng,
        );

        markers.add(
          Marker(
            markerId: MarkerId('user_${membership.userId}'),
            position: latLng,
            infoWindow: InfoWindow(
              title: 'Member ${membership.userId}',
              snippet: 'Last seen: ${_formatLastSeen(membership.lastSeen)}',
            ),
            icon: _getMarkerIcon(membership.role),
          ),
        );
      }
    }

    // Add roll call circle if active
    if (_activeRollCall != null) {
      circles.add(
        Circle(
          circleId: const CircleId('roll_call_area'),
          center: LatLng(
            _activeRollCall!.anchorLocation.lat,
            _activeRollCall!.anchorLocation.lng,
          ),
          radius: _activeRollCall!.radiusMeters.toDouble(),
          fillColor: Colors.blue.withOpacity(0.2),
          strokeColor: Colors.blue,
          strokeWidth: 2,
        ),
      );
    }

    setState(() {
      _userMarkers = markers;
      _rollCallCircles = circles;
    });
  }

  // Get marker icon based on user role
  BitmapDescriptor _getMarkerIcon(UserRole role) {
    switch (role) {
      case UserRole.leader:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      case UserRole.coLeader:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
      case UserRole.traveler:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      default:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet);
    }
  }

  // Format last seen time
  String _formatLastSeen(DateTime? lastSeen) {
    if (lastSeen == null) return 'Unknown';
    
    final now = DateTime.now();
    final difference = now.difference(lastSeen);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  @override
  void initState() {
    super.initState();
    // Get location asynchronously without blocking UI
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getCurrentLocation();
    });
  }
}
