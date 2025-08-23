import 'package:flutter/material.dart';

class StarRating extends StatelessWidget {
  final double rating;
  final double size;
  final bool allowSelection;
  final Function(double)? onRatingChanged;
  final Color? activeColor;
  final Color? inactiveColor;
  final int maxStars;

  const StarRating({
    super.key,
    required this.rating,
    this.size = 24.0,
    this.allowSelection = false,
    this.onRatingChanged,
    this.activeColor,
    this.inactiveColor,
    this.maxStars = 5,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeStarColor = activeColor ?? Colors.amber;
    final inactiveStarColor = inactiveColor ?? theme.colorScheme.outline.withOpacity(0.3);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(maxStars, (index) {
        final starIndex = index + 1;
        final isActive = rating >= starIndex;
        final isHalfActive = rating >= starIndex - 0.5 && rating < starIndex;

        return GestureDetector(
          onTap: allowSelection && onRatingChanged != null
              ? () => onRatingChanged!(starIndex.toDouble())
              : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.0),
            child: Icon(
              isActive
                  ? Icons.star
                  : isHalfActive
                      ? Icons.star_half
                      : Icons.star_border,
              size: size,
              color: isActive || isHalfActive ? activeStarColor : inactiveStarColor,
            ),
          ),
        );
      }),
    );
  }
}

class InteractiveStarRating extends StatefulWidget {
  final double initialRating;
  final double size;
  final Function(double) onRatingChanged;
  final Color? activeColor;
  final Color? inactiveColor;
  final int maxStars;

  const InteractiveStarRating({
    super.key,
    this.initialRating = 0,
    this.size = 32.0,
    required this.onRatingChanged,
    this.activeColor,
    this.inactiveColor,
    this.maxStars = 5,
  });

  @override
  State<InteractiveStarRating> createState() => _InteractiveStarRatingState();
}

class _InteractiveStarRatingState extends State<InteractiveStarRating> {
  late double _currentRating;
  double? _hoverRating;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.initialRating;
  }

  @override
  void didUpdateWidget(InteractiveStarRating oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialRating != widget.initialRating) {
      _currentRating = widget.initialRating;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeStarColor = widget.activeColor ?? Colors.amber;
    final inactiveStarColor = widget.inactiveColor ?? theme.colorScheme.outline.withOpacity(0.3);
    final displayRating = _hoverRating ?? _currentRating;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(widget.maxStars, (index) {
        final starIndex = index + 1;
        final isActive = displayRating >= starIndex;

        return GestureDetector(
          onTap: () {
            setState(() {
              _currentRating = starIndex.toDouble();
            });
            widget.onRatingChanged(_currentRating);
          },
          onTapDown: (_) {
            setState(() {
              _hoverRating = starIndex.toDouble();
            });
          },
          onTapCancel: () {
            setState(() {
              _hoverRating = null;
            });
          },
          child: MouseRegion(
            onEnter: (_) {
              setState(() {
                _hoverRating = starIndex.toDouble();
              });
            },
            onExit: (_) {
              setState(() {
                _hoverRating = null;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Icon(
                isActive ? Icons.star : Icons.star_border,
                size: widget.size,
                color: isActive ? activeStarColor : inactiveStarColor,
              ),
            ),
          ),
        );
      }),
    );
  }
}

class CompactRatingDisplay extends StatelessWidget {
  final double rating;
  final int? reviewCount;
  final double size;
  final bool showNumber;

  const CompactRatingDisplay({
    super.key,
    required this.rating,
    this.reviewCount,
    this.size = 16.0,
    this.showNumber = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.star,
          size: size,
          color: Colors.amber,
        ),
        const SizedBox(width: 4),
        if (showNumber) ...[
          Text(
            rating.toStringAsFixed(1),
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          if (reviewCount != null) ...[
            const SizedBox(width: 4),
            Text(
              '($reviewCount)',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ],
      ],
    );
  }
}

class RatingBreakdown extends StatelessWidget {
  final Map<int, int> ratingCounts;
  final int totalRatings;

  const RatingBreakdown({
    super.key,
    required this.ratingCounts,
    required this.totalRatings,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        for (int star = 5; star >= 1; star--)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.0),
            child: Row(
              children: [
                Text(
                  '$star',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.star,
                  size: 12,
                  color: Colors.amber,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: LinearProgressIndicator(
                    value: totalRatings > 0 
                        ? (ratingCounts[star] ?? 0) / totalRatings 
                        : 0,
                    backgroundColor: theme.colorScheme.outline.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 30,
                  child: Text(
                    '${ratingCounts[star] ?? 0}',
                    style: theme.textTheme.bodySmall,
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
