import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/models/models.dart';
import '../../../core/data/providers/trip_provider.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_colors.dart';

class TripAnalyticsScreen extends ConsumerWidget {
  final String tripId;

  const TripAnalyticsScreen({super.key, required this.tripId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tripAsync = ref.watch(tripProvider(tripId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Analytics'),
        actions: [
          IconButton(
            onPressed: () => _showAnalyticsOptions(context),
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
      body: tripAsync.when(
        data: (trip) => trip != null ? _buildAnalyticsContent(context, ref, trip) : const Center(child: Text('Trip not found')),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              AppSpacing.verticalSpaceMd,
              Text('Error loading analytics: $error'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyticsContent(BuildContext context, WidgetRef ref, Trip trip) {
    final theme = Theme.of(context);
    
    return ListView(
      padding: AppSpacing.paddingLg,
      children: [
        // Trip Overview Card
        _buildOverviewCard(context, trip),
        AppSpacing.verticalSpaceLg,
        
        // Engagement Metrics
        _buildEngagementMetrics(context, trip),
        AppSpacing.verticalSpaceLg,
        
        // Trip Performance
        _buildTripPerformance(context, trip),
        AppSpacing.verticalSpaceLg,
        
        // Rating Insights
        _buildRatingInsights(context, trip),
        AppSpacing.verticalSpaceLg,
        
        // Financial Summary (if applicable)
        _buildFinancialSummary(context, trip),
        AppSpacing.verticalSpaceLg,
      ],
    );
  }

  Widget _buildOverviewCard(BuildContext context, Trip trip) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: AppSpacing.paddingLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: theme.colorScheme.primary),
                AppSpacing.horizontalSpaceSm,
                Text(
                  'Trip Overview',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            AppSpacing.verticalSpaceMd,
            Row(
              children: [
                Expanded(
                  child: _buildMetricItem(
                    context,
                    'Members',
                    '${trip.seatsTotal - trip.seatsAvailable}',
                    Icons.people,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildMetricItem(
                    context,
                    'Capacity',
                    '${trip.seatsTotal}',
                    Icons.event_seat,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildMetricItem(
                    context,
                    'Days Left',
                    _calculateDaysLeft(trip),
                    Icons.schedule,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEngagementMetrics(BuildContext context, Trip trip) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: AppSpacing.paddingLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Engagement Metrics',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            AppSpacing.verticalSpaceMd,
            _buildEngagementBar('Chat Activity', 0.85, Colors.blue),
            AppSpacing.verticalSpaceSm,
            _buildEngagementBar('Location Sharing', 0.72, Colors.green),
            AppSpacing.verticalSpaceSm,
            _buildEngagementBar('Roll Call Participation', 0.93, Colors.orange),
            AppSpacing.verticalSpaceSm,
            _buildEngagementBar('Document Access', 0.68, Colors.purple),
          ],
        ),
      ),
    );
  }



  Widget _buildTripPerformance(BuildContext context, Trip trip) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: AppSpacing.paddingLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Trip Performance',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            AppSpacing.verticalSpaceMd,
            Row(
              children: [
                Expanded(
                  child: _buildPerformanceMetric(
                    context,
                    'On-Time Departure',
                    '95%',
                    Icons.departure_board,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildPerformanceMetric(
                    context,
                    'Member Satisfaction',
                    '4.2/5',
                    Icons.sentiment_satisfied,
                    Colors.amber,
                  ),
                ),
              ],
            ),
            AppSpacing.verticalSpaceMd,
            Row(
              children: [
                Expanded(
                  child: _buildPerformanceMetric(
                    context,
                    'Safety Score',
                    '98%',
                    Icons.security,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildPerformanceMetric(
                    context,
                    'Budget Adherence',
                    '92%',
                    Icons.account_balance_wallet,
                    Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingInsights(BuildContext context, Trip trip) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: AppSpacing.paddingLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Rating Insights',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (trip.ratingSummary.totalRatings > 0)
                  TextButton(
                    onPressed: () => _showRatingDetails(context, trip),
                    child: const Text('View All'),
                  ),
              ],
            ),
            AppSpacing.verticalSpaceMd,
            if (trip.ratingSummary.totalRatings > 0) ...[
              Row(
                children: [
                  Icon(Icons.star, color: Colors.amber, size: 24),
                  AppSpacing.horizontalSpaceSm,
                  Text(
                    trip.ratingSummary.averageRating.toStringAsFixed(1),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  AppSpacing.horizontalSpaceSm,
                  Text(
                    '(${trip.ratingSummary.totalRatings} reviews)',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              AppSpacing.verticalSpaceSm,
              Text(
                'Top highlights: ${trip.ratingSummary.topHighlights.take(3).join(', ')}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ] else ...[
              Text(
                'No ratings yet',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialSummary(BuildContext context, Trip trip) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: AppSpacing.paddingLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Financial Summary',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            AppSpacing.verticalSpaceMd,
            Row(
              children: [
                Expanded(
                  child: _buildFinancialMetric(
                    context,
                    'Total Revenue',
                    '\$2,450',
                    Icons.trending_up,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildFinancialMetric(
                    context,
                    'Expenses',
                    '\$1,890',
                    Icons.trending_down,
                    Colors.red,
                  ),
                ),
              ],
            ),
            AppSpacing.verticalSpaceMd,
            Row(
              children: [
                Expanded(
                  child: _buildFinancialMetric(
                    context,
                    'Profit',
                    '\$560',
                    Icons.account_balance,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildFinancialMetric(
                    context,
                    'Per Member',
                    '\$35',
                    Icons.person,
                    Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem(BuildContext context, String label, String value, IconData icon, Color color) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        AppSpacing.verticalSpaceSm,
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildEngagementBar(String label, double percentage, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text('${(percentage * 100).toInt()}%'),
          ],
        ),
        AppSpacing.verticalSpaceXs,
        LinearProgressIndicator(
          value: percentage,
          backgroundColor: color.withOpacity(0.2),
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ],
    );
  }



  Widget _buildPerformanceMetric(BuildContext context, String label, String value, IconData icon, Color color) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: AppSpacing.paddingVerticalSm,
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          AppSpacing.verticalSpaceXs,
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialMetric(BuildContext context, String label, String value, IconData icon, Color color) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: AppSpacing.paddingVerticalSm,
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          AppSpacing.verticalSpaceXs,
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _calculateDaysLeft(Trip trip) {
    final now = DateTime.now();
    final endDate = trip.endDate;
    final difference = endDate.difference(now).inDays;
    return difference > 0 ? '$difference' : 'Completed';
  }

  String _getRandomActivity() {
    final activities = ['Sent message', 'Shared location', 'Checked in', 'Viewed docs'];
    return activities[DateTime.now().millisecond % activities.length];
  }

  String _getRandomTime() {
    final times = ['2 min ago', '5 min ago', '10 min ago', '1 hour ago'];
    return times[DateTime.now().second % times.length];
  }

  void _showAnalyticsOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: AppSpacing.paddingLg,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Export Analytics'),
              onTap: () {
                Navigator.pop(context);
                _exportAnalytics();
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share Report'),
              onTap: () {
                Navigator.pop(context);
                _shareAnalytics();
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Analytics Settings'),
              onTap: () {
                Navigator.pop(context);
                _showAnalyticsSettings(context);
              },
            ),
          ],
        ),
      ),
    );
  }



  void _showRatingDetails(BuildContext context, Trip trip) {
    // Navigate to detailed ratings screen
    context.push('/trips/$tripId/ratings');
  }

  void _exportAnalytics() {
    // Implementation for exporting analytics
  }

  void _shareAnalytics() {
    // Implementation for sharing analytics
  }

  void _showAnalyticsSettings(BuildContext context) {
    // Show analytics settings dialog
  }
}
