import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/data/providers/service_rating_provider.dart';
import '../../../core/data/providers/auth_provider.dart';
import '../../../core/data/models/models.dart';
import '../../../core/services/mock_server.dart';
import 'add_service_rating_dialog.dart';

class TripServiceRatingScreen extends ConsumerStatefulWidget {
  final String tripId;

  const TripServiceRatingScreen({
    super.key,
    required this.tripId,
  });

  @override
  ConsumerState<TripServiceRatingScreen> createState() => _TripServiceRatingScreenState();
}

class _TripServiceRatingScreenState extends ConsumerState<TripServiceRatingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  ServiceCategory? _selectedCategory;
  String? _selectedStop;

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
    final currentUser = ref.watch(authProvider).maybeWhen(
          authenticated: (user) => user,
          orElse: () => null,
        );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Service Ratings'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Ratings', icon: Icon(Icons.star)),
            Tab(text: 'Reviews', icon: Icon(Icons.rate_review)),
            Tab(text: 'Analytics', icon: Icon(Icons.analytics)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddRatingDialog(context, currentUser),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRatingsTab(),
          _buildReviewsTab(),
          _buildAnalyticsTab(),
        ],
      ),
    );
  }

  Widget _buildRatingsTab() {
    final ratingsAsync = ref.watch(serviceRatingsProvider(widget.tripId));

    return ratingsAsync.when(
      data: (ratings) {
        if (ratings.isEmpty) {
          return _buildEmptyState(
            'No Service Ratings Yet',
            'Be the first to rate a service on this trip!',
            Icons.star_border,
            () => _showAddRatingDialog(context, null),
          );
        }

        // Filter ratings based on selected category and stop
        final filteredRatings = ratings.where((rating) {
          if (_selectedCategory != null && rating.category != _selectedCategory) {
            return false;
          }
          if (_selectedStop != null && rating.stopName != _selectedStop) {
            return false;
          }
          return true;
        }).toList();

        if (filteredRatings.isEmpty) {
          return _buildEmptyState(
            'No Ratings Found',
            'Try adjusting your filters to see more ratings.',
            Icons.filter_list,
            () => _showFilterDialog(),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(serviceRatingsProvider(widget.tripId));
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredRatings.length,
            itemBuilder: (context, index) {
              final rating = filteredRatings[index];
              return _buildRatingCard(rating);
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Error: $error'),
      ),
    );
  }

  Widget _buildReviewsTab() {
    final ratingsAsync = ref.watch(serviceRatingsProvider(widget.tripId));

    return ratingsAsync.when(
      data: (ratings) {
        if (ratings.isEmpty) {
          return _buildEmptyState(
            'No Reviews Yet',
            'Be the first to review a service on this trip!',
            Icons.rate_review,
            () => _showAddRatingDialog(context, null),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(serviceRatingsProvider(widget.tripId));
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: ratings.length,
            itemBuilder: (context, index) {
              final rating = ratings[index];
              return _buildReviewCard(rating);
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Error: $error'),
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    final summaryAsync = ref.watch(serviceRatingSummaryProvider(widget.tripId));

    return summaryAsync.when(
      data: (summary) {
        if (summary == null) {
          return _buildEmptyState(
            'No Analytics Available',
            'Add some service ratings to see analytics!',
            Icons.analytics,
            () => _showAddRatingDialog(context, null),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(serviceRatingSummaryProvider(widget.tripId));
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryCard(summary),
                const SizedBox(height: 24),
                _buildCategoryAnalytics(summary),
                const SizedBox(height: 24),
                _buildTopServices(summary),
                const SizedBox(height: 24),
                _buildTagAnalytics(summary),
              ],
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Error: $error'),
      ),
    );
  }

  Widget _buildRatingCard(ServiceRating rating) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: getServiceCategoryColor(rating.category).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    getServiceCategoryIcon(rating.category),
                    color: getServiceCategoryColor(rating.category),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rating.serviceName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        getServiceCategoryName(rating.category),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          rating.overallRating.toStringAsFixed(1),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.star, color: Colors.orange, size: 18),
                      ],
                    ),
                    Text(
                      rating.stopName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              rating.review,
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: rating.tags.map((tag) => Chip(
                label: Text(tag),
                backgroundColor: Colors.blue.withOpacity(0.1),
                labelStyle: TextStyle(
                  color: Colors.blue[700],
                  fontSize: 12,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8),
              )).toList(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.grey[300],
                  child: Text(
                    rating.userName[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rating.userName,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _formatDate(rating.createdAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (rating.price != null)
                  Flexible(
                    child: Text(
                      '${rating.currency} ${rating.price!.toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: Colors.green[700],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewCard(ServiceRating rating) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    rating.serviceName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      rating.overallRating.toStringAsFixed(1),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.star, color: Colors.orange, size: 18),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              rating.review,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: Colors.grey[300],
                  child: Text(
                    rating.userName[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    rating.userName,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  _formatDate(rating.createdAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(ServiceRatingSummary summary) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem(
                  'Total Ratings',
                  summary.totalRatings.toString(),
                  Icons.star,
                  Colors.orange,
                ),
                _buildSummaryItem(
                  'Average Rating',
                  summary.averageOverallRating.toStringAsFixed(1),
                  Icons.analytics,
                  Colors.blue,
                ),
                _buildSummaryItem(
                  'Categories',
                  summary.categoryCounts.length.toString(),
                  Icons.category,
                  Colors.green,
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: summary.averageOverallRating / 5.0,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
            ),
            const SizedBox(height: 8),
            Text(
              'Overall Trip Experience',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryAnalytics(ServiceRatingSummary summary) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Category Performance',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...summary.categoryAverages.entries.map((entry) {
              final category = entry.key;
              final average = entry.value;
              final count = summary.categoryCounts[category] ?? 0;
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            category,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Text(
                          '${average.toStringAsFixed(1)} ⭐ ($count ratings)',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: average / 5.0,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopServices(ServiceRatingSummary summary) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Top Rated Services',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...summary.topRatedServices.asMap().entries.map((entry) {
              final index = entry.key;
              final service = entry.value;
              
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.orange.withOpacity(0.1),
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: Colors.orange[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(service),
                trailing: const Icon(Icons.star, color: Colors.orange),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildTagAnalytics(ServiceRatingSummary summary) {
    final sortedTags = summary.tagFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Popular Tags',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: sortedTags.take(10).map((entry) {
                final tag = entry.key;
                final count = entry.value;
                
                return Chip(
                  label: Text('$tag ($count)'),
                  backgroundColor: Colors.blue.withOpacity(0.1),
                  labelStyle: TextStyle(
                    color: Colors.blue[700],
                    fontSize: 12,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String title, String message, IconData icon, VoidCallback onAction) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.add),
              label: const Text('Add Rating'),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterDialog() {
    final categories = ref.read(serviceCategoriesProvider);
    final stops = ref.read(serviceRatingsProvider(widget.tripId)).value?.map((r) => r.stopName).toSet().toList() ?? [];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Ratings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<ServiceCategory?>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Service Category',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('All Categories'),
                ),
                ...categories.map((category) => DropdownMenuItem(
                  value: category,
                  child: Text(getServiceCategoryName(category)),
                )),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value;
                });
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String?>(
              value: _selectedStop,
              decoration: const InputDecoration(
                labelText: 'Trip Stop',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('All Stops'),
                ),
                ...stops.map((stop) => DropdownMenuItem(
                  value: stop,
                  child: Text(stop),
                )),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedStop = value;
                });
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedCategory = null;
                _selectedStop = null;
              });
              Navigator.of(context).pop();
            },
            child: const Text('Clear All'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _showAddRatingDialog(BuildContext context, User? currentUser) {
    showDialog(
      context: context,
      builder: (context) => const AddServiceRatingDialog(),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
