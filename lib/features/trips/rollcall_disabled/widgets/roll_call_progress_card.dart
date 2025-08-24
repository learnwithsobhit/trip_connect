import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/data/models/rollcall.dart';
import '../../../../core/data/providers/rollcall_provider.dart';
import '../../../../core/theme/app_spacing.dart';

class RollCallProgressCard extends ConsumerWidget {
  final RollCallSession session;

  const RollCallProgressCard({super.key, required this.session});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rollCallNotifier = ref.read(rollCallProvider.notifier);
    final theme = Theme.of(context);
    
    final completionPercentage = rollCallNotifier.completionPercentage;
    final timeRemaining = rollCallNotifier.timeRemaining;
    final isGracePeriodExpired = rollCallNotifier.isGracePeriodExpired;

    return Card(
      margin: AppSpacing.paddingMd,
      child: Padding(
        padding: AppSpacing.paddingLg,
        child: Column(
          children: [
            // Header with status
            Row(
              children: [
                Icon(
                  _getStatusIcon(session.status),
                  color: _getStatusColor(session.status, isGracePeriodExpired),
                  size: 24,
                ),
                AppSpacing.horizontalSpaceSm,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getStatusText(session.status, isGracePeriodExpired),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _getStatusColor(session.status, isGracePeriodExpired),
                        ),
                      ),
                      Text(
                        session.anchorName,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                // Timer display
                if (timeRemaining != null && !isGracePeriodExpired)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getTimerColor(timeRemaining),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      _formatDuration(timeRemaining),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            
            AppSpacing.verticalSpaceLg,
            
            // Main counter
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Present count (large)
                Column(
                  children: [
                    Text(
                      '${session.presentCount}',
                      style: theme.textTheme.displayLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    Text(
                      'Present',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                
                AppSpacing.horizontalSpaceLg,
                
                // Divider
                Text(
                  '/',
                  style: theme.textTheme.displayLarge?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
                
                AppSpacing.horizontalSpaceLg,
                
                // Total count
                Column(
                  children: [
                    Text(
                      '${session.totalParticipants}',
                      style: theme.textTheme.displayLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'Total',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            AppSpacing.verticalSpaceLg,
            
            // Progress bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progress',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${(completionPercentage * 100).round()}%',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                AppSpacing.verticalSpaceXs,
                LinearProgressIndicator(
                  value: completionPercentage,
                  backgroundColor: theme.colorScheme.surfaceVariant,
                  valueColor: AlwaysStoppedAnimation<Color>(_getProgressColor(completionPercentage)),
                  minHeight: 8,
                ),
              ],
            ),
            
            AppSpacing.verticalSpaceMd,
            
            // Stats row
            Row(
              children: [
                _buildStatChip(
                  context,
                  icon: Icons.check_circle,
                  label: 'Present',
                  value: session.presentCount,
                  color: Colors.green,
                ),
                AppSpacing.horizontalSpaceSm,
                _buildStatChip(
                  context,
                  icon: Icons.schedule,
                  label: 'Missing',
                  value: session.missingCount,
                  color: Colors.orange,
                ),
                if (session.excusedCount > 0) ...[
                  AppSpacing.horizontalSpaceSm,
                  _buildStatChip(
                    context,
                    icon: Icons.person_off,
                    label: 'Excused',
                    value: session.excusedCount,
                    color: Colors.grey,
                  ),
                ],
              ],
            ),
            
            // Additional info for extended sessions
            if (session.status == const RollCallStatus.extended()) ...[
              AppSpacing.verticalSpaceMd,
              Container(
                padding: AppSpacing.paddingSm,
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 16,
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                    AppSpacing.horizontalSpaceXs,
                    Text(
                      'Session extended',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSecondaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required int value,
    required Color color,
  }) {
    final theme = Theme.of(context);
    
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            AppSpacing.horizontalSpaceXs,
            Text(
              '$value',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            AppSpacing.horizontalSpaceXs,
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: color,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getStatusIcon(RollCallStatus status) {
    return switch (status) {
      _Active() => Icons.play_circle_fill,
      _Extended() => Icons.schedule,
      _Completed() => Icons.check_circle,
      _Cancelled() => Icons.cancel,
      _Preparing() => Icons.hourglass_empty,
    };
  }

  Color _getStatusColor(RollCallStatus status, bool isGracePeriodExpired) {
    return switch (status) {
      _Active() => isGracePeriodExpired ? Colors.orange : Colors.green,
      _Extended() => Colors.blue,
      _Completed() => Colors.green,
      _Cancelled() => Colors.red,
      _Preparing() => Colors.grey,
    };
  }

  String _getStatusText(RollCallStatus status, bool isGracePeriodExpired) {
    return switch (status) {
      _Active() => isGracePeriodExpired ? 'Grace Period Expired' : 'Roll Call Active',
      _Extended() => 'Extended Session',
      _Completed() => 'Roll Call Complete',
      _Cancelled() => 'Roll Call Cancelled',
      _Preparing() => 'Preparing Roll Call',
    };
  }

  Color _getTimerColor(Duration timeRemaining) {
    final minutes = timeRemaining.inMinutes;
    if (minutes <= 1) return Colors.red;
    if (minutes <= 2) return Colors.orange;
    return Colors.green;
  }

  Color _getProgressColor(double percentage) {
    if (percentage >= 0.8) return Colors.green;
    if (percentage >= 0.5) return Colors.orange;
    return Colors.red;
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
