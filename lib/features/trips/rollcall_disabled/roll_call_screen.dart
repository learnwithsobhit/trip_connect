import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/models/rollcall.dart';
import '../../../core/data/models/trip.dart';
import '../../../core/data/models/user.dart';
import '../../../core/data/providers/rollcall_provider.dart';
import '../../../core/data/providers/trip_provider.dart';
import '../../../core/theme/app_spacing.dart';
import 'widgets/roll_call_banner.dart';
import 'widgets/roll_call_config_dialog.dart';
import 'widgets/roll_call_participants_view.dart';
import 'widgets/roll_call_progress_card.dart';

class RollCallScreen extends ConsumerStatefulWidget {
  final String tripId;

  const RollCallScreen({super.key, required this.tripId});

  @override
  ConsumerState<RollCallScreen> createState() => _RollCallScreenState();
}

class _RollCallScreenState extends ConsumerState<RollCallScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _showConfigDialog = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rollCallState = ref.watch(rollCallProvider);
    final tripAsync = ref.watch(tripProvider(widget.tripId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Roll Call'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/trips/${widget.tripId}'),
        ),
        actions: [
          if (rollCallState.activeSession != null) ...[
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: _showSettings,
              tooltip: 'Settings',
            ),
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: _showMenu,
              tooltip: 'More options',
            ),
          ],
        ],
      ),
      body: tripAsync.when(
        data: (trip) => trip != null ? _buildContent(trip) : _buildTripNotFound(),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildError(error.toString()),
      ),
      floatingActionButton: rollCallState.activeSession == null
          ? FloatingActionButton.extended(
              onPressed: _startInstantRollCall,
              icon: const Icon(Icons.play_circle_fill),
              label: const Text('Start Roll Call'),
              backgroundColor: theme.colorScheme.primary,
            )
          : null,
    );
  }

  Widget _buildContent(Trip trip) {
    final rollCallState = ref.watch(rollCallProvider);
    final activeSession = rollCallState.activeSession;

    if (activeSession == null) {
      return _buildWelcomeView(trip);
    }

    return Column(
      children: [
        // Progress card
        RollCallProgressCard(session: activeSession),
        
        // Banner for current user if not checked in
        const RollCallBanner(),
        
        // Participants view with tabs
        Expanded(
          child: RollCallParticipantsView(
            session: activeSession,
            tabController: _tabController,
          ),
        ),
        
        // Control buttons
        _buildControlButtons(activeSession),
      ],
    );
  }

  Widget _buildWelcomeView(Trip trip) {
    final theme = Theme.of(context);
    
    return SingleChildScrollView(
      padding: AppSpacing.paddingLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Card(
            child: Padding(
              padding: AppSpacing.paddingLg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.groups,
                        size: 32,
                        color: theme.colorScheme.primary,
                      ),
                      AppSpacing.horizontalSpaceMd,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Instant Roll Call',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Quick attendance check for ${trip.name}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          AppSpacing.verticalSpaceLg,
          
          // Features
          Text(
            'Features',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          AppSpacing.verticalSpaceMd,
          
          _buildFeatureCard(
            icon: Icons.gps_fixed,
            title: 'GPS Auto Check-in',
            description: 'Automatic presence detection within customizable radius',
          ),
          
          AppSpacing.verticalSpaceSm,
          
          _buildFeatureCard(
            icon: Icons.touch_app,
            title: 'Manual Check-in',
            description: 'Quick manual check-in for weak GPS or privacy mode',
          ),
          
          AppSpacing.verticalSpaceSm,
          
          _buildFeatureCard(
            icon: Icons.notifications_active,
            title: 'Smart Notifications',
            description: 'Automatic reminders and location sharing',
          ),
          
          AppSpacing.verticalSpaceSm,
          
          _buildFeatureCard(
            icon: Icons.analytics,
            title: 'Real-time Progress',
            description: 'Live counter with visual progress and timing',
          ),
          
          AppSpacing.verticalSpaceLg,
          
          // Quick start instructions
          Card(
            color: theme.colorScheme.primaryContainer,
            child: Padding(
              padding: AppSpacing.paddingLg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                      AppSpacing.horizontalSpaceSm,
                      Text(
                        'Quick Start',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.verticalSpaceSm,
                  Text(
                    '1. Tap "Start Roll Call" to begin\n'
                    '2. Choose your location as the meeting point\n'
                    '3. Set the radius (default: 50m)\n'
                    '4. Everyone gets notified instantly\n'
                    '5. Watch real-time check-ins',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    final theme = Theme.of(context);
    
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(
            icon,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(description),
      ),
    );
  }

  Widget _buildControlButtons(RollCallSession session) {
    final rollCallNotifier = ref.read(rollCallProvider.notifier);
    final isLeader = rollCallNotifier.isCurrentUserLeader;
    final theme = Theme.of(context);

    if (!isLeader) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: AppSpacing.paddingLg,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Extend button
            if (session.status == const RollCallStatus.active()) ...[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _extendSession,
                  icon: const Icon(Icons.schedule),
                  label: const Text('Extend'),
                ),
              ),
              AppSpacing.horizontalSpaceSm,
            ],
            
            // Complete button
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: _completeSession,
                icon: const Icon(Icons.check_circle),
                label: Text(session.status == const RollCallStatus.active() 
                    ? 'Complete Roll Call' 
                    : 'Close'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            
            AppSpacing.horizontalSpaceSm,
            
            // Cancel button
            OutlinedButton(
              onPressed: _cancelSession,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
              ),
              child: const Icon(Icons.close),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripNotFound() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('Trip not found'),
        ],
      ),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text('Error: $error'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => ref.refresh(tripProvider(widget.tripId)),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Future<void> _startInstantRollCall() async {
    try {
      // Show configuration dialog first
      final config = await showDialog<RollCallConfig>(
        context: context,
        builder: (context) => const RollCallConfigDialog(),
      );

      if (config == null) return; // User cancelled

      final rollCallNotifier = ref.read(rollCallProvider.notifier);
      
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Starting roll call...'),
                ],
              ),
            ),
          ),
        ),
      );

      final success = await rollCallNotifier.startSession(
        tripId: widget.tripId,
        anchorName: 'Current Location',
        config: config,
      );

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      if (!success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(ref.read(rollCallProvider).error ?? 'Failed to start roll call'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _extendSession() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Extend Roll Call'),
        content: const Text('How much time would you like to add?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(rollCallProvider.notifier).extendSession(120); // 2 minutes
            },
            child: const Text('2 min'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(rollCallProvider.notifier).extendSession(300); // 5 minutes
            },
            child: const Text('5 min'),
          ),
        ],
      ),
    );
  }

  Future<void> _completeSession() async {
    final nextAction = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Roll Call'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('What\'s the next action for the group?'),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                hintText: 'e.g., "Board the bus", "Head to restaurant"',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (value) => Navigator.of(context).pop(value),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(''),
            child: const Text('Complete'),
          ),
        ],
      ),
    );

    if (nextAction != null) {
      await ref.read(rollCallProvider.notifier).completeSession(
        nextAction: nextAction.isEmpty ? null : nextAction,
      );
    }
  }

  void _cancelSession() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Roll Call'),
        content: const Text('Are you sure you want to cancel the current roll call?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(rollCallProvider.notifier).cancelSession();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  void _showSettings() {
    // TODO: Show settings dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings coming soon')),
    );
  }

  void _showMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.analytics),
              title: const Text('View Analytics'),
              onTap: () {
                Navigator.of(context).pop();
                // TODO: Navigate to analytics
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Analytics coming soon')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Session History'),
              onTap: () {
                Navigator.of(context).pop();
                // TODO: Navigate to history
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('History coming soon')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Export Data'),
              onTap: () {
                Navigator.of(context).pop();
                // TODO: Export functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Export coming soon')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
