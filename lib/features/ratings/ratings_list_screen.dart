import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/models/models.dart';
import '../../core/data/providers/rating_provider.dart';
import '../../core/theme/app_spacing.dart';
import '../common/widgets/star_rating.dart';
import 'package:timeago/timeago.dart' as timeago;

class UserRatingsListScreen extends ConsumerWidget {
  final String userId;
  final String userName;

  const UserRatingsListScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ratingsAsync = ref.watch(userRatingsProvider(userId));

    return Scaffold(
      appBar: AppBar(
        title: Text('$userName\'s Ratings'),
      ),
      body: ratingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: theme.colorScheme.error,
              ),
              AppSpacing.verticalSpaceMd,
              Text(
                'Failed to load ratings',
                style: theme.textTheme.titleMedium,
              ),
              AppSpacing.verticalSpaceSm,
              Text(
                error.toString(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        data: (ratings) {
          if (ratings.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.star_border,
                    size: 64,
                    color: theme.colorScheme.outline,
                  ),
                  AppSpacing.verticalSpaceMd,
                  Text(
                    'No ratings yet',
                    style: theme.textTheme.titleMedium,
                  ),
                  AppSpacing.verticalSpaceSm,
                  Text(
                    '$userName hasn\'t received any ratings yet.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          // Calculate statistics
          final averageRating = ratings.fold<double>(0, (sum, r) => sum + r.rating) / ratings.length;
          final ratingCounts = <int, int>{};
          for (final rating in ratings) {
            final starRating = rating.rating.round();
            ratingCounts[starRating] = (ratingCounts[starRating] ?? 0) + 1;
          }

          return ListView(
            padding: AppSpacing.paddingMd,
            children: [
              // Summary card
              Card(
                child: Padding(
                  padding: AppSpacing.paddingLg,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  averageRating.toStringAsFixed(1),
                                  style: theme.textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                StarRating(rating: averageRating, size: 20),
                                AppSpacing.verticalSpaceXs,
                                Text(
                                  '${ratings.length} ${ratings.length == 1 ? 'rating' : 'ratings'}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.outline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: RatingBreakdown(
                              ratingCounts: ratingCounts,
                              totalRatings: ratings.length,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              AppSpacing.verticalSpaceMd,

              // Individual ratings
              ...ratings.map((rating) => _UserRatingCard(rating: rating)),
            ],
          );
        },
      ),
    );
  }
}

class TripRatingsListScreen extends ConsumerWidget {
  final String tripId;
  final String tripName;

  const TripRatingsListScreen({
    super.key,
    required this.tripId,
    required this.tripName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ratingsAsync = ref.watch(tripRatingsProvider(tripId));

    return Scaffold(
      appBar: AppBar(
        title: Text('$tripName Reviews'),
      ),
      body: ratingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: theme.colorScheme.error,
              ),
              AppSpacing.verticalSpaceMd,
              Text(
                'Failed to load reviews',
                style: theme.textTheme.titleMedium,
              ),
              AppSpacing.verticalSpaceSm,
              Text(
                error.toString(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        data: (ratings) {
          if (ratings.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.rate_review_outlined,
                    size: 64,
                    color: theme.colorScheme.outline,
                  ),
                  AppSpacing.verticalSpaceMd,
                  Text(
                    'No reviews yet',
                    style: theme.textTheme.titleMedium,
                  ),
                  AppSpacing.verticalSpaceSm,
                  Text(
                    'This trip hasn\'t been reviewed yet.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          // Calculate statistics
          final averageOverall = ratings.fold<double>(0, (sum, r) => sum + r.overallRating) / ratings.length;
          final averageOrganization = ratings.fold<double>(0, (sum, r) => sum + r.organizationRating) / ratings.length;
          final averageValue = ratings.fold<double>(0, (sum, r) => sum + r.valueRating) / ratings.length;
          final averageExperience = ratings.fold<double>(0, (sum, r) => sum + r.experienceRating) / ratings.length;
          final recommendationPercent = (ratings.where((r) => r.wouldRecommend).length / ratings.length * 100).round();

          return ListView(
            padding: AppSpacing.paddingMd,
            children: [
              // Summary card
              Card(
                child: Padding(
                  padding: AppSpacing.paddingLg,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  averageOverall.toStringAsFixed(1),
                                  style: theme.textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                StarRating(rating: averageOverall, size: 20),
                                AppSpacing.verticalSpaceXs,
                                Text(
                                  '${ratings.length} ${ratings.length == 1 ? 'review' : 'reviews'}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.outline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: AppSpacing.paddingMd,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  '$recommendationPercent%',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onPrimaryContainer,
                                  ),
                                ),
                                Text(
                                  'recommend',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      AppSpacing.verticalSpaceLg,
                      // Detailed ratings
                      Row(
                        children: [
                          Expanded(
                            child: _DetailedRatingItem(
                              'Organization',
                              averageOrganization,
                              theme,
                            ),
                          ),
                          Expanded(
                            child: _DetailedRatingItem(
                              'Value',
                              averageValue,
                              theme,
                            ),
                          ),
                          Expanded(
                            child: _DetailedRatingItem(
                              'Experience',
                              averageExperience,
                              theme,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              AppSpacing.verticalSpaceMd,

              // Individual reviews
              ...ratings.map((rating) => _TripRatingCard(rating: rating)),
            ],
          );
        },
      ),
    );
  }
}

class _UserRatingCard extends StatelessWidget {
  final UserRating rating;

  const _UserRatingCard({required this.rating});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: AppSpacing.paddingMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      StarRating(rating: rating.rating, size: 16),
                      AppSpacing.verticalSpaceXs,
                      Text(
                        timeago.format(rating.createdAt),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (rating.tags.isNotEmpty) ...[
              AppSpacing.verticalSpaceSm,
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: rating.tags.map((tag) {
                  final ratingTag = UserRatingTag.values.firstWhere(
                    (t) => t.name == tag,
                    orElse: () => UserRatingTag.friendly,
                  );
                  return Chip(
                    label: Text(
                      ratingTag.label,
                      style: theme.textTheme.bodySmall,
                    ),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );
                }).toList(),
              ),
            ],
            if (rating.feedback?.isNotEmpty == true) ...[
              AppSpacing.verticalSpaceSm,
              Text(
                rating.feedback!,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TripRatingCard extends StatelessWidget {
  final TripRating rating;

  const _TripRatingCard({required this.rating});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: AppSpacing.paddingMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      StarRating(rating: rating.overallRating, size: 16),
                      AppSpacing.verticalSpaceXs,
                      Text(
                        timeago.format(rating.createdAt),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
                if (rating.wouldRecommend)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green),
                    ),
                    child: Text(
                      'Recommends',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
            if (rating.highlights.isNotEmpty) ...[
              AppSpacing.verticalSpaceSm,
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: rating.highlights.map((highlight) {
                  final tripHighlight = TripHighlight.values.firstWhere(
                    (h) => h.name == highlight,
                    orElse: () => TripHighlight.amazingExperience,
                  );
                  return Chip(
                    label: Text(
                      tripHighlight.label,
                      style: theme.textTheme.bodySmall,
                    ),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );
                }).toList(),
              ),
            ],
            if (rating.feedback?.isNotEmpty == true) ...[
              AppSpacing.verticalSpaceSm,
              Text(
                rating.feedback!,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailedRatingItem extends StatelessWidget {
  final String label;
  final double rating;
  final ThemeData theme;

  const _DetailedRatingItem(this.label, this.rating, this.theme);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          rating.toStringAsFixed(1),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        AppSpacing.verticalSpaceXs,
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
