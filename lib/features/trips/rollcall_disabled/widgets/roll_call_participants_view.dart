import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/data/models/rollcall.dart';
import '../../../../core/data/models/user.dart';
import '../../../../core/data/models/trip.dart';
import '../../../../core/data/providers/rollcall_provider.dart';
import '../../../../core/data/providers/auth_provider.dart';
import '../../../../core/theme/app_spacing.dart';

class RollCallParticipantsView extends ConsumerWidget {
  final RollCallSession session;
  final TabController tabController;

  const RollCallParticipantsView({
    super.key,
    required this.session,
    required this.tabController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rollCallNotifier = ref.read(rollCallProvider.notifier);
    final presentParticipants = rollCallNotifier.presentParticipants;
    final missingParticipants = rollCallNotifier.missingParticipants;
    final isLeader = rollCallNotifier.isCurrentUserLeader;
    final theme = Theme.of(context);

    return Column(
      children: [
        // Tab bar
        Container(
          margin: AppSpacing.paddingMd,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TabBar(
            controller: tabController,
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            labelColor: theme.colorScheme.onPrimary,
            unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
            dividerColor: Colors.transparent,
            tabs: [
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle, size: 18),
                    AppSpacing.horizontalSpaceXs,
                    Text('Present (${presentParticipants.length})'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.schedule, size: 18),
                    AppSpacing.horizontalSpaceXs,
                    Text('Missing (${missingParticipants.length})'),
                  ],
                ),
              ),
              const Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.analytics, size: 18),
                    SizedBox(width: 4),
                    Text('Stats'),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Tab content
        Expanded(
          child: TabBarView(
            controller: tabController,
            children: [
              _buildPresentTab(context, ref, presentParticipants, isLeader),
              _buildMissingTab(context, ref, missingParticipants, isLeader),
              _buildStatsTab(context, ref, session),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPresentTab(
    BuildContext context,
    WidgetRef ref,
    List<RollCallParticipant> participants,
    bool isLeader,
  ) {
    if (participants.isEmpty) {
      return _buildEmptyState(
        context,
        icon: Icons.schedule,
        title: 'No one checked in yet',
        subtitle: 'Participants will appear here as they check in',
      );
    }

    return ListView.builder(
      padding: AppSpacing.paddingMd,
      itemCount: participants.length,
      itemBuilder: (context, index) {
        final participant = participants[index];
        return _buildParticipantCard(
          context,
          ref,
          participant,
          isPresent: true,
          isLeader: isLeader,
        );
      },
    );
  }

  Widget _buildMissingTab(
    BuildContext context,
    WidgetRef ref,
    List<RollCallParticipant> participants,
    bool isLeader,
  ) {
    if (participants.isEmpty) {
      return _buildEmptyState(
        context,
        icon: Icons.check_circle,
        title: 'Everyone is present!',
        subtitle: 'All participants have checked in successfully',
        color: Colors.green,
      );
    }

    return Column(
      children: [
        // Missing reminder bar (leader only)
        if (isLeader && participants.isNotEmpty)
          _buildMissingReminderBar(context, ref, participants),
        
        // Missing participants list
        Expanded(
          child: ListView.builder(
            padding: AppSpacing.paddingMd,
            itemCount: participants.length,
            itemBuilder: (context, index) {
              final participant = participants[index];
              return _buildParticipantCard(
                context,
                ref,
                participant,
                isPresent: false,
                isLeader: isLeader,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatsTab(BuildContext context, WidgetRef ref, RollCallSession session) {
    final theme = Theme.of(context);
    final methodBreakdown = <String, int>{};
    
    // Calculate method breakdown
    for (final participant in session.participants) {
      participant.status.when(
        present: (method, timestamp, distance, accuracy) {
          final methodName = method.when(
            gps: () => 'GPS',
            manual: () => 'Manual',
            leaderMark: (reason) => 'Leader Mark',
            qr: () => 'QR Code',
            nfc: () => 'NFC',
          );
          methodBreakdown[methodName] = (methodBreakdown[methodName] ?? 0) + 1;
        },
        pending: () {},
        missing: (lastSeen, lastDistance) {},
        excused: (reason, timestamp) {},
      );
    }

    return SingleChildScrollView(
      padding: AppSpacing.paddingMd,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary stats
          Card(
            child: Padding(
              padding: AppSpacing.paddingLg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Session Summary',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  AppSpacing.verticalSpaceMd,
                  
                  _buildStatRow('Total Participants', '${session.totalParticipants}'),
                  _buildStatRow('Present', '${session.presentCount}'),
                  _buildStatRow('Missing', '${session.missingCount}'),
                  if (session.excusedCount > 0)
                    _buildStatRow('Excused', '${session.excusedCount}'),
                  
                  AppSpacing.verticalSpaceMd,
                  
                  _buildStatRow('Completion Rate', 
                      '${((session.presentCount / session.totalParticipants) * 100).round()}%'),
                  _buildStatRow('Duration', _formatDuration(
                      DateTime.now().difference(session.startTime))),
                ],
              ),
            ),
          ),
          
          AppSpacing.verticalSpaceMd,
          
          // Method breakdown
          if (methodBreakdown.isNotEmpty) ...[
            Card(
              child: Padding(
                padding: AppSpacing.paddingLg,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Check-in Methods',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    AppSpacing.verticalSpaceMd,
                    
                    ...methodBreakdown.entries.map((entry) {
                      final icon = switch (entry.key) {
                        'GPS' => Icons.gps_fixed,
                        'Manual' => Icons.touch_app,
                        'Leader Mark' => Icons.admin_panel_settings,
                        'QR Code' => Icons.qr_code,
                        'NFC' => Icons.nfc,
                        _ => Icons.check_circle,
                      };
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Icon(icon, size: 20),
                            AppSpacing.horizontalSpaceSm,
                            Expanded(child: Text(entry.key)),
                            Text(
                              '${entry.value}',
                              style: theme.textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
            
            AppSpacing.verticalSpaceMd,
          ],
          
          // Configuration info
          Card(
            child: Padding(
              padding: AppSpacing.paddingLg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Configuration',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  AppSpacing.verticalSpaceMd,
                  
                  _buildStatRow('Detection Radius', '${session.config.radiusMeters.toInt()}m'),
                  _buildStatRow('Grace Period', '${session.config.gracePeriodSeconds ~/ 60}min'),
                  _buildStatRow('Mode', _getModeLabel(session.config.mode)),
                  _buildStatRow('GPS Tracking', session.config.enableGpsTracking ? 'Enabled' : 'Disabled'),
                  _buildStatRow('Manual Check-in', session.config.allowManualCheckIn ? 'Allowed' : 'Disabled'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantCard(
    BuildContext context,
    WidgetRef ref,
    RollCallParticipant participant,
    bool isPresent,
    bool isLeader,
  ) {
    final theme = Theme.of(context);
    final currentUser = ref.watch(currentUserProvider);
    final isCurrentUser = participant.userId == currentUser?.id;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Stack(
          children: [
            CircleAvatar(
              backgroundColor: _getRoleColor(participant.role),
              child: Text(
                participant.userId[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (isPresent)
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getMethodIcon(participant.status),
                    size: 12,
                    color: Colors.green,
                  ),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                isCurrentUser ? 'You' : 'User ${participant.userId}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            _buildRoleBadge(participant.role),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (participant.seat != null)
              Text('Seat: ${participant.seat}'),
            
            if (isPresent)
              _buildCheckInInfo(participant.status),
            
            if (!isPresent)
              _buildMissingInfo(participant),
          ],
        ),
        trailing: isLeader && !isPresent ? _buildLeaderActions(context, ref, participant) : null,
      ),
    );
  }

  Widget _buildCheckInInfo(CheckInStatus status) {
    final theme = Theme.of(context);
    
    return Row(
      children: [
        Icon(
          _getMethodIcon(status),
          size: 14,
          color: Colors.green,
        ),
        const SizedBox(width: 4),
        Text(
          _getMethodText(status.method),
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.green,
          ),
        ),
        if (status.distance != null) ...[
          const Text(' • '),
          Text(
            '${status.distance!.round()}m away',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.green,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMissingInfo(RollCallParticipant participant) {
    final theme = Theme.of(context);
    
    return Row(
      children: [
        Icon(
          Icons.schedule,
          size: 14,
          color: Colors.orange,
        ),
        const SizedBox(width: 4),
        Text(
          'Not checked in',
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.orange,
          ),
        ),
        if (participant.reminderCount > 0) ...[
          const Text(' • '),
          Text(
            '${participant.reminderCount} reminder${participant.reminderCount > 1 ? 's' : ''} sent',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.orange,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLeaderActions(
    BuildContext context,
    WidgetRef ref,
    RollCallParticipant participant,
  ) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (action) => _handleLeaderAction(context, ref, participant, action),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'ping',
          child: ListTile(
            leading: Icon(Icons.notifications),
            title: Text('Send Reminder'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem(
          value: 'call',
          child: ListTile(
            leading: Icon(Icons.phone),
            title: Text('Call'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem(
          value: 'mark_present',
          child: ListTile(
            leading: Icon(Icons.check_circle),
            title: Text('Mark Present'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem(
          value: 'excuse',
          child: ListTile(
            leading: Icon(Icons.person_off),
            title: Text('Excuse'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }

  Widget _buildMissingReminderBar(
    BuildContext context,
    WidgetRef ref,
    List<RollCallParticipant> missingParticipants,
  ) {
    final theme = Theme.of(context);
    
    return Container(
      margin: AppSpacing.paddingMd,
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        border: Border.all(color: Colors.orange.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning,
            color: Colors.orange.shade600,
          ),
          AppSpacing.horizontalSpaceSm,
          Expanded(
            child: Text(
              '${missingParticipants.length} participant${missingParticipants.length > 1 ? 's' : ''} missing',
              style: theme.textTheme.titleSmall?.copyWith(
                color: Colors.orange.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => _pingAllMissing(context, ref, missingParticipants),
            icon: const Icon(Icons.notifications, size: 16),
            label: const Text('Ping All'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleBadge(UserRole role) {
    final color = _getRoleColor(role);
    final label = _getRoleLabel(role);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    Color? color,
  }) {
    final theme = Theme.of(context);
    final displayColor = color ?? theme.colorScheme.onSurfaceVariant;
    
    return Center(
      child: Padding(
        padding: AppSpacing.paddingLg,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: displayColor.withOpacity(0.5),
            ),
            AppSpacing.verticalSpaceMd,
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                color: displayColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            AppSpacing.verticalSpaceSm,
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: displayColor.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _handleLeaderAction(
    BuildContext context,
    WidgetRef ref,
    RollCallParticipant participant,
    String action,
  ) {
    final rollCallNotifier = ref.read(rollCallProvider.notifier);
    
    switch (action) {
      case 'ping':
        _pingParticipant(context, participant);
        break;
      case 'call':
        _callParticipant(context, participant);
        break;
      case 'mark_present':
        _markParticipantPresent(context, ref, participant);
        break;
      case 'excuse':
        _excuseParticipant(context, ref, participant);
        break;
    }
  }

  void _pingParticipant(BuildContext context, RollCallParticipant participant) {
    // TODO: Send reminder notification
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Reminder sent to User ${participant.userId}')),
    );
  }

  void _callParticipant(BuildContext context, RollCallParticipant participant) {
    // TODO: Initiate call
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Calling User ${participant.userId}...')),
    );
  }

  Future<void> _markParticipantPresent(
    BuildContext context,
    WidgetRef ref,
    RollCallParticipant participant,
  ) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Mark User ${participant.userId} Present'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Why are you marking this participant as present?'),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                hintText: 'e.g., "Present but GPS not working"',
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
            onPressed: () => Navigator.of(context).pop('Manually marked present'),
            child: const Text('Mark Present'),
          ),
        ],
      ),
    );

    if (reason != null) {
      final success = await ref.read(rollCallProvider.notifier).markParticipantPresent(
        participant.userId,
        reason,
      );
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success 
                ? 'User ${participant.userId} marked as present'
                : 'Failed to mark participant as present'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  void _excuseParticipant(
    BuildContext context,
    WidgetRef ref,
    RollCallParticipant participant,
  ) {
    // TODO: Excuse participant
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('User ${participant.userId} excused (feature coming soon)')),
    );
  }

  void _pingAllMissing(
    BuildContext context,
    WidgetRef ref,
    List<RollCallParticipant> missingParticipants,
  ) {
    // TODO: Send reminders to all missing participants
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Reminders sent to ${missingParticipants.length} participants')),
    );
  }

  Color _getRoleColor(UserRole role) {
    return switch (role) {
      UserRole.leader => Colors.purple,
      UserRole.coLeader => Colors.blue,
      UserRole.traveler => Colors.green,
      UserRole.follower => Colors.grey,
    };
  }

  String _getRoleLabel(UserRole role) {
    return switch (role) {
      UserRole.leader => 'Leader',
      UserRole.coLeader => 'Co-Leader',
      UserRole.traveler => 'Traveler',
      UserRole.follower => 'Follower',
    };
  }

  IconData _getMethodIcon(CheckInStatus status) {
    if (status is _Present) {
      return switch (status.method) {
        _GPS() => Icons.gps_fixed,
        _Manual() => Icons.touch_app,
        _LeaderMark() => Icons.admin_panel_settings,
        _QR() => Icons.qr_code,
        _NFC() => Icons.nfc,
      };
    }
    return Icons.schedule;
  }

  String _getMethodText(PresenceMethod method) {
    return switch (method) {
      _GPS() => 'GPS',
      _Manual() => 'Manual',
      _LeaderMark() => 'Leader Mark',
      _QR() => 'QR Code',
      _NFC() => 'NFC',
    };
  }

  String _getModeLabel(RollCallMode mode) {
    return switch (mode) {
      RollCallMode.standard => 'Standard',
      RollCallMode.vehicle => 'Vehicle',
      RollCallMode.table => 'Table',
      RollCallMode.indoor => 'Indoor',
      RollCallMode.kidsElderly => 'Kids & Elderly',
    };
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes}m ${seconds}s';
  }
}
