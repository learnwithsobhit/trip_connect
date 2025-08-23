import 'package:flutter/material.dart';
import '../../../core/data/models/models.dart';
import '../../../core/theme/app_spacing.dart';

class UserRatingBadge extends StatelessWidget {
  final UserRatingSummary ratingSummary;
  final double size;
  final bool showReviews;
  final bool showVerified;
  final bool compact;
  final Color? backgroundColor;
  final Color? borderColor;

  const UserRatingBadge({
    super.key,
    required this.ratingSummary,
    this.size = 14,
    this.showReviews = true,
    this.showVerified = true,
    this.compact = false,
    this.backgroundColor,
    this.borderColor,
  });

  const UserRatingBadge.compact({
    super.key,
    required this.ratingSummary,
    this.size = 12,
    this.showReviews = false,
    this.showVerified = false,
    this.compact = true,
    this.backgroundColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (ratingSummary.totalRatings == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 4 : 6,
        vertical: compact ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(compact ? 6 : 8),
        border: Border.all(
          color: borderColor ?? Colors.amber.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star,
            size: size,
            color: Colors.amber,
          ),
          SizedBox(width: compact ? 2 : 4),
          Text(
            ratingSummary.averageRating.toStringAsFixed(1),
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
              fontSize: compact ? 10 : 11,
            ),
          ),
          if (showReviews && ratingSummary.totalRatings > 0) ...[
            SizedBox(width: compact ? 2 : 4),
            Text(
              '(${ratingSummary.totalRatings})',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: compact ? 9 : 10,
              ),
            ),
          ],
          if (showVerified && ratingSummary.isVerified) ...[
            SizedBox(width: compact ? 2 : 4),
            Icon(
              Icons.verified,
              size: size - 2,
              color: theme.colorScheme.primary,
            ),
          ],
        ],
      ),
    );
  }
}

class UserRatingRow extends StatelessWidget {
  final UserRatingSummary ratingSummary;
  final bool showDetails;
  final MainAxisAlignment mainAxisAlignment;

  const UserRatingRow({
    super.key,
    required this.ratingSummary,
    this.showDetails = true,
    this.mainAxisAlignment = MainAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (ratingSummary.totalRatings == 0) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisAlignment: mainAxisAlignment,
      children: [
        UserRatingBadge(ratingSummary: ratingSummary),
        if (showDetails) ...[
          AppSpacing.horizontalSpaceXs,
          Text(
            '${ratingSummary.totalRatings} reviews • ${ratingSummary.completedTrips} trips',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 11,
            ),
          ),
          if (ratingSummary.isVerified) ...[
            AppSpacing.horizontalSpaceXs,
            Text(
              '• ✓ Verified',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ],
    );
  }
}

class UserRatingChip extends StatelessWidget {
  final UserRatingSummary ratingSummary;
  final VoidCallback? onTap;

  const UserRatingChip({
    super.key,
    required this.ratingSummary,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (ratingSummary.totalRatings == 0) {
      return const SizedBox.shrink();
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.amber.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.amber, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.star,
              size: 18,
              color: Colors.amber,
            ),
            AppSpacing.horizontalSpaceXs,
            Text(
              ratingSummary.averageRating.toStringAsFixed(1),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            AppSpacing.horizontalSpaceXs,
            Text(
              '(${ratingSummary.totalRatings})',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (ratingSummary.isVerified) ...[
              AppSpacing.horizontalSpaceXs,
              Icon(
                Icons.verified,
                size: 16,
                color: theme.colorScheme.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
