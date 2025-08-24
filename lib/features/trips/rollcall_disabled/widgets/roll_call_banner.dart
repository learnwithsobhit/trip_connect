import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/data/models/rollcall.dart';
import '../../../../core/data/providers/rollcall_provider.dart';
import '../../../../core/data/providers/auth_provider.dart';
import '../../../../core/theme/app_spacing.dart';

class RollCallBanner extends ConsumerStatefulWidget {
  const RollCallBanner({super.key});

  @override
  ConsumerState<RollCallBanner> createState() => _RollCallBannerState();
}

class _RollCallBannerState extends ConsumerState<RollCallBanner> {
  double? _distanceToAnchor;
  bool _isCalculatingDistance = false;

  @override
  void initState() {
    super.initState();
    _calculateDistance();
  }

  Future<void> _calculateDistance() async {
    final rollCallState = ref.read(rollCallProvider);
    final session = rollCallState.activeSession;
    if (session == null) return;

    setState(() {
      _isCalculatingDistance = true;
    });

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final distance = Geolocator.distanceBetween(
        session.anchorLocation.lat,
        session.anchorLocation.lng,
        position.latitude,
        position.longitude,
      );

      if (mounted) {
        setState(() {
          _distanceToAnchor = distance;
          _isCalculatingDistance = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCalculatingDistance = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final rollCallState = ref.watch(rollCallProvider);
    final currentUser = ref.watch(currentUserProvider);
    final session = rollCallState.activeSession;
    
    if (session == null || currentUser == null) {
      return const SizedBox.shrink();
    }

    final rollCallNotifier = ref.read(rollCallProvider.notifier);
    final participant = rollCallNotifier.getParticipant(currentUser.id);
    
    if (participant == null) {
      return const SizedBox.shrink();
    }

    // Don't show banner if already checked in
    return participant.status.when(
      present: (method, timestamp, distance, accuracy) => 
          _buildCheckedInBanner(context, participant.status),
      pending: () => _buildCheckInBanner(context, session, participant),
      missing: (lastSeen, lastDistance) => _buildCheckInBanner(context, session, participant),
      excused: (reason, timestamp) => _buildCheckInBanner(context, session, participant),
    );

    return _buildCheckInBanner(context, session, participant);
  }

  Widget _buildCheckInBanner(
    BuildContext context,
    RollCallSession session,
    RollCallParticipant participant,
  ) {
    final theme = Theme.of(context);
    final isWithinRadius = _distanceToAnchor != null && 
                          _distanceToAnchor! <= session.config.radiusMeters;

    return Container(
      margin: AppSpacing.paddingMd,
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isWithinRadius 
              ? [Colors.green.shade400, Colors.green.shade600]
              : [Colors.orange.shade400, Colors.orange.shade600],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              Icon(
                isWithinRadius ? Icons.location_on : Icons.location_searching,
                color: Colors.white,
                size: 24,
              ),
              AppSpacing.horizontalSpaceSm,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isWithinRadius ? 'You\'re at the meeting point!' : 'Roll Call Active',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      session.anchorName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              // Distance indicator
              if (_distanceToAnchor != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _formatDistance(_distanceToAnchor!),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          
          AppSpacing.verticalSpaceMd,
          
          // Action buttons
          Row(
            children: [
              // Check in button
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _checkIn,
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Check In'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: isWithinRadius ? Colors.green : Colors.orange,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              
              AppSpacing.horizontalSpaceSm,
              
              // Navigate button
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _navigate,
                  icon: const Icon(Icons.navigation),
                  label: const Text('Navigate'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              
              AppSpacing.horizontalSpaceSm,
              
              // Refresh distance button
              IconButton(
                onPressed: _isCalculatingDistance ? null : _calculateDistance,
                icon: _isCalculatingDistance 
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.refresh, color: Colors.white),
                tooltip: 'Refresh distance',
              ),
            ],
          ),
          
          // Additional info
          if (_distanceToAnchor != null) ...[
            AppSpacing.verticalSpaceSm,
            Text(
              isWithinRadius 
                  ? 'You can check in automatically or manually'
                  : 'Move closer to the meeting point for auto check-in',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCheckedInBanner(BuildContext context, CheckInStatus status) {
    final theme = Theme.of(context);
    
    return status.when(
      present: (method, timestamp, distance, accuracy) => Container(
        margin: AppSpacing.paddingMd,
        padding: AppSpacing.paddingMd,
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          border: Border.all(color: Colors.green.shade200),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.green.shade600,
              size: 24,
            ),
            AppSpacing.horizontalSpaceSm,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'You\'re checked in!',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _getCheckInMethodText(method),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.green.shade600,
                    ),
                  ),
                ],
              ),
            ),
            // Time badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _formatTime(timestamp),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
      pending: () => const SizedBox.shrink(),
      missing: (lastSeen, lastDistance) => const SizedBox.shrink(),
      excused: (reason, timestamp) => const SizedBox.shrink(),
    );
  }

  Future<void> _checkIn() async {
    final rollCallNotifier = ref.read(rollCallProvider.notifier);
    
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Check In'),
        content: const Text('Confirm your attendance at the roll call?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Check In'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await rollCallNotifier.checkInManually(reason: 'Manual check-in');
      
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Successfully checked in!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to check in. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _navigate() {
    final rollCallState = ref.read(rollCallProvider);
    final session = rollCallState.activeSession;
    if (session == null) return;

    // TODO: Open maps application with directions
    // For now, show a placeholder
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Navigate to ${session.anchorName}'),
        action: SnackBarAction(
          label: 'Open Maps',
          onPressed: () {
            // TODO: Launch external maps app
          },
        ),
      ),
    );
  }

  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()}m';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)}km';
    }
  }

  String _getCheckInMethodText(PresenceMethod method) {
    return method.when(
      gps: () => 'Checked in automatically via GPS',
      manual: () => 'Checked in manually',
      leaderMark: (reason) => 'Marked present by leader: $reason',
      qr: () => 'Checked in via QR code',
      nfc: () => 'Checked in via NFC',
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}min ago';
    } else {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
  }
}
