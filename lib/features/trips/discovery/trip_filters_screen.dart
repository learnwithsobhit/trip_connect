import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/models/models.dart';
import '../../../core/data/providers/rating_provider.dart';
import '../../../core/theme/app_spacing.dart';
import '../../common/widgets/star_rating.dart';

class TripFiltersScreen extends ConsumerStatefulWidget {
  final TripSearchFilter? currentFilter;
  
  const TripFiltersScreen({
    super.key,
    this.currentFilter,
  });

  @override
  ConsumerState<TripFiltersScreen> createState() => _TripFiltersScreenState();
}

class _TripFiltersScreenState extends ConsumerState<TripFiltersScreen> {
  // Filter state
  double _minRating = 0.0;
  int _minReviews = 0;
  DateTimeRange? _dateRange;
  RangeValues _priceRange = const RangeValues(0, 50000);
  Set<String> _selectedThemes = {};
  int _maxParticipants = 50;
  bool _onlyRecommended = false;

  final List<String> _themes = [
    'Adventure',
    'Beach & Relaxation',
    'Cultural Heritage',
    'Wildlife & Nature',
    'Mountain & Trekking',
    'City Tours',
    'Food & Cuisine',
    'Photography',
    'Spiritual',
    'Backpacking',
  ];

  @override
  void initState() {
    super.initState();
    
    // Initialize filter values from currentFilter if provided
    if (widget.currentFilter != null) {
      final filter = widget.currentFilter!;
      _minRating = filter.minRating ?? 0.0;
      _minReviews = filter.minReviews ?? 0;
      _dateRange = filter.dateRange;
      _selectedThemes = Set.from(filter.themes);
      _maxParticipants = filter.maxParticipants;
      _onlyRecommended = filter.onlyRecommended;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Filter Trips'),
        actions: [
          TextButton(
            onPressed: _resetFilters,
            child: const Text('Reset'),
          ),
          TextButton(
            onPressed: _applyFilters,
            child: const Text('Apply'),
          ),
        ],
      ),
      body: ListView(
        padding: AppSpacing.paddingMd,
        children: [
          // Rating filters
          _buildRatingFiltersCard(theme),
          
          AppSpacing.verticalSpaceMd,
          
          // Date range filter
          _buildDateFiltersCard(theme),
          
          AppSpacing.verticalSpaceMd,
          
          // Price range filter
          _buildPriceFiltersCard(theme),
          
          AppSpacing.verticalSpaceMd,
          
          // Themes filter
          _buildThemesFiltersCard(theme),
          
          AppSpacing.verticalSpaceMd,
          
          // Group size filter
          _buildGroupSizeFiltersCard(theme),
          
          AppSpacing.verticalSpaceMd,
          
          // Additional filters
          _buildAdditionalFiltersCard(theme),
          
          AppSpacing.verticalSpaceLg,
          
          // Search results preview
          _buildResultsPreview(),
        ],
      ),
    );
  }

  Widget _buildRatingFiltersCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: AppSpacing.paddingLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rating & Reviews',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            AppSpacing.verticalSpaceMd,
            
            // Minimum rating
            Text(
              'Minimum Rating: ${_minRating.toStringAsFixed(1)}⭐',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            AppSpacing.verticalSpaceSm,
            StarRating(
              rating: _minRating,
              size: 32,
              allowSelection: true,
              onRatingChanged: (rating) {
                setState(() {
                  _minRating = rating;
                });
              },
            ),
            AppSpacing.verticalSpaceMd,
            
            // Minimum reviews
            Text(
              'Minimum Reviews: $_minReviews',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            AppSpacing.verticalSpaceSm,
            Slider(
              value: _minReviews.toDouble(),
              min: 0,
              max: 100,
              divisions: 20,
              label: '$_minReviews reviews',
              onChanged: (value) {
                setState(() {
                  _minReviews = value.round();
                });
              },
            ),
            
            AppSpacing.verticalSpaceMd,
            
            // Only recommended trips
            SwitchListTile(
              value: _onlyRecommended,
              onChanged: (value) {
                setState(() {
                  _onlyRecommended = value;
                });
              },
              title: Text(
                'Only Recommended Trips',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: const Text('Show only trips with 80%+ recommendation rate'),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateFiltersCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: AppSpacing.paddingLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Travel Dates',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            AppSpacing.verticalSpaceMd,
            
            InkWell(
              onTap: _selectDateRange,
              child: Container(
                padding: AppSpacing.paddingMd,
                decoration: BoxDecoration(
                  border: Border.all(color: theme.colorScheme.outline),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.date_range,
                      color: theme.colorScheme.primary,
                    ),
                    AppSpacing.horizontalSpaceMd,
                    Expanded(
                      child: Text(
                        _dateRange != null
                            ? '${_formatDate(_dateRange!.start)} - ${_formatDate(_dateRange!.end)}'
                            : 'Select travel dates',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    if (_dateRange != null)
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _dateRange = null;
                          });
                        },
                        icon: const Icon(Icons.clear),
                        iconSize: 20,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceFiltersCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: AppSpacing.paddingLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Price Range',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            AppSpacing.verticalSpaceMd,
            
            Text(
              '₹${_priceRange.start.round()} - ₹${_priceRange.end.round()}',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.primary,
              ),
            ),
            AppSpacing.verticalSpaceSm,
            
            RangeSlider(
              values: _priceRange,
              min: 0,
              max: 100000,
              divisions: 20,
              labels: RangeLabels(
                '₹${_priceRange.start.round()}',
                '₹${_priceRange.end.round()}',
              ),
              onChanged: (values) {
                setState(() {
                  _priceRange = values;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemesFiltersCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: AppSpacing.paddingLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Trip Themes',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            AppSpacing.verticalSpaceMd,
            
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _themes.map((theme) {
                final isSelected = _selectedThemes.contains(theme);
                return FilterChip(
                  label: Text(theme),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedThemes.add(theme);
                      } else {
                        _selectedThemes.remove(theme);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupSizeFiltersCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: AppSpacing.paddingLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Group Size',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            AppSpacing.verticalSpaceMd,
            
            Text(
              'Maximum $_maxParticipants participants',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            AppSpacing.verticalSpaceSm,
            
            Slider(
              value: _maxParticipants.toDouble(),
              min: 2,
              max: 100,
              divisions: 49,
              label: '$_maxParticipants people',
              onChanged: (value) {
                setState(() {
                  _maxParticipants = value.round();
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdditionalFiltersCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: AppSpacing.paddingLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Additional Filters',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            AppSpacing.verticalSpaceMd,
            
            // Quick filter chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilterChip(
                  label: const Text('Available Now'),
                  selected: false,
                  onSelected: (selected) {
                    // Implement quick filter
                  },
                ),
                FilterChip(
                  label: const Text('Weekend Trips'),
                  selected: false,
                  onSelected: (selected) {
                    // Implement quick filter
                  },
                ),
                FilterChip(
                  label: const Text('Long Weekends'),
                  selected: false,
                  onSelected: (selected) {
                    // Implement quick filter
                  },
                ),
                FilterChip(
                  label: const Text('Budget Friendly'),
                  selected: false,
                  onSelected: (selected) {
                    // Implement quick filter
                  },
                ),
                FilterChip(
                  label: const Text('Luxury'),
                  selected: false,
                  onSelected: (selected) {
                    // Implement quick filter
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsPreview() {
    final filteredTripsAsync = ref.watch(tripsFilteredByRatingProvider(
      RatingFilter(
        minRating: _minRating > 0 ? _minRating : null,
        minReviews: _minReviews > 0 ? _minReviews : null,
      ),
    ));

    return Card(
      child: Padding(
        padding: AppSpacing.paddingLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Results Preview',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            AppSpacing.verticalSpaceMd,
            
            filteredTripsAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, _) => Text(
                'Error loading results: $error',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              data: (trips) {
                final filteredCount = trips.length;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$filteredCount trips match your criteria',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    AppSpacing.verticalSpaceSm,
                    if (filteredCount > 0) ...[
                      Text(
                        'Average rating: ${(trips.fold<double>(0, (sum, trip) => sum + trip.ratingSummary.averageRating) / trips.length).toStringAsFixed(1)}⭐',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Text(
                        'Price range: ₹${trips.map((t) => 15000).reduce((a, b) => a < b ? a : b)} - ₹${trips.map((t) => 35000).reduce((a, b) => a > b ? a : b)}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDateRange() async {
    final pickedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _dateRange,
    );

    if (pickedRange != null) {
      setState(() {
        _dateRange = pickedRange;
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _resetFilters() {
    setState(() {
      _minRating = 0.0;
      _minReviews = 0;
      _dateRange = null;
      _priceRange = const RangeValues(0, 50000);
      _selectedThemes.clear();
      _maxParticipants = 50;
      _onlyRecommended = false;
    });
  }

  void _applyFilters() {
    // Create filter object and pass back to discovery screen
    final filter = TripSearchFilter(
      minRating: _minRating > 0 ? _minRating : null,
      minReviews: _minReviews > 0 ? _minReviews : null,
      dateRange: _dateRange,
      priceRange: _priceRange,
      themes: _selectedThemes.toList(),
      maxParticipants: _maxParticipants,
      onlyRecommended: _onlyRecommended,
    );

    context.pop(filter);
  }
}

class TripSearchFilter {
  final double? minRating;
  final int? minReviews;
  final DateTimeRange? dateRange;
  final RangeValues priceRange;
  final List<String> themes;
  final int maxParticipants;
  final bool onlyRecommended;

  const TripSearchFilter({
    this.minRating,
    this.minReviews,
    this.dateRange,
    required this.priceRange,
    required this.themes,
    required this.maxParticipants,
    required this.onlyRecommended,
  });
}
