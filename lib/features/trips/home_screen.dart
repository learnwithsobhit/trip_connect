import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/data/providers/auth_provider.dart';
import '../../core/data/providers/trip_provider.dart';
import '../../core/data/models/models.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../common/widgets/user_rating_badge.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildUserRatingDisplay(User? user, ThemeData theme) {
    if (user == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withOpacity(0.3), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.star_border,
              size: 18,
              color: Colors.grey,
            ),
            AppSpacing.horizontalSpaceXs,
            Text(
              'New Traveler',
              style: theme.textTheme.labelMedium?.copyWith(
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    if (user.ratingSummary.totalRatings > 0) {
      return GestureDetector(
        onTap: () {
          context.pushNamed(
            'user-ratings-list',
            pathParameters: {'userId': user.id},
            queryParameters: {'name': user.displayName},
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.amber.withOpacity(0.2),
                Colors.orange.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.amber, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.amber.withOpacity(0.2),
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.star,
                size: 16,
                color: Colors.amber.shade700,
              ),
              const SizedBox(width: 4),
              Text(
                user.ratingSummary.averageRating.toStringAsFixed(1),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.amber.shade800,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  '(${user.ratingSummary.totalRatings})',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.amber.shade700,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (user.ratingSummary.isVerified) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.verified,
                  size: 14,
                  color: theme.colorScheme.primary,
                ),
              ],
            ],
          ),
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary.withOpacity(0.1),
              theme.colorScheme.secondary.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3), width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.star_border,
              size: 16,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                'New Traveler',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);
    final tripsAsync = ref.watch(tripsProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with user profile and actions
          SliverAppBar(
            expandedHeight: 160,
            floating: false,
            pinned: true,
            backgroundColor: theme.colorScheme.surface,
            foregroundColor: theme.colorScheme.onSurface,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      theme.colorScheme.primary.withOpacity(0.1),
                      theme.colorScheme.surface,
                    ],
                  ),
                ),
              ),
              title: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back,',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  AppSpacing.verticalSpaceXs,
                                        // User name and rating in prominent display
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user?.displayName.split(' ').first ?? 'Traveler',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 24,
                                  ),
                                ),
                                // Always show rating section, even if 0 ratings
                                AppSpacing.verticalSpaceXs,
                                _buildUserRatingDisplay(user, theme),
                              ],
                            ),
                          ),
                          AppSpacing.horizontalSpaceSm,
                      // Profile avatar with rating overlay
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              theme.colorScheme.primary,
                              theme.colorScheme.secondary,
                            ],
                          ),
                          border: Border.all(
                            color: Colors.amber,
                            width: 3,
                          ),
                        ),
                        child: Stack(
                          children: [
                            Center(
                              child: Text(
                                user?.displayName.split(' ').map((e) => e[0]).take(2).join() ?? 'T',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (user != null && user.ratingSummary.totalRatings > 0) ...[
                              Positioned(
                                top: -2,
                                right: -2,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.amber,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.white, width: 1),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.star,
                                        size: 10,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        user.ratingSummary.averageRating.toStringAsFixed(1),
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              titlePadding: AppSpacing.paddingMd,
            ),
            actions: [
              // Show discover button for guest users
              if (ref.watch(isGuestUserProvider)) ...[
                IconButton(
                  onPressed: () => context.go('/discover'),
                  icon: const Icon(Icons.explore),
                  tooltip: 'Discover Public Trips',
                ),
              ],
              IconButton(
                onPressed: () {
                  if (user != null) {
                    context.pushNamed(
                      'user-ratings-list',
                      pathParameters: {'userId': user.id},
                      queryParameters: {'name': user.displayName},
                    );
                  }
                },
                icon: const Icon(Icons.star_border),
                tooltip: 'My Ratings',
              ),
              IconButton(
                onPressed: () => context.go('/join'),
                icon: const Icon(Icons.qr_code_scanner),
                tooltip: 'Join Trip',
              ),
              IconButton(
                onPressed: () => context.go('/settings'),
                icon: const Icon(Icons.settings_outlined),
                tooltip: 'Settings',
              ),
              AppSpacing.horizontalSpaceMd,
            ],
          ),

          // Tab Bar for trip categories
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Active'),
                  Tab(text: 'Upcoming'),
                  Tab(text: 'Waiting'),
                  Tab(text: 'Past'),
                ],
              ),
            ),
          ),

          // Trips content
          SliverToBoxAdapter(
            child: SizedBox(
              height: MediaQuery.of(context).size.height - 250, // Give it a fixed height
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTripsTabWithAsync(ref.watch(activeTripsProvider), 'active'),
                  _buildTripsTabWithAsync(ref.watch(upcomingTripsProvider), 'upcoming'),
                  _buildTripsTabWithAsync(ref.watch(waitingTripsProvider), 'waiting'),
                  _buildTripsTabWithAsync(ref.watch(pastTripsProvider), 'past'),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/trips/create'),
        icon: const Icon(Icons.add),
        label: const Text('New Trip'),
      ),
    );
  }

  Widget _buildTripsTabWithAsync(List<Trip> trips, String category) {
    print('Building $category trips tab with ${trips.length} trips');
    if (trips.isEmpty) {
      return _buildEmptyState(category);
    }

    return ListView.builder(
      padding: AppSpacing.paddingMd,
      itemCount: trips.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: AppSpacing.paddingVerticalXs,
          child: _TripCard(trip: trips[index]),
        );
      },
    );
  }

  Widget _buildTripsTab(List<Trip> trips, String category) {
    if (trips.isEmpty) {
      return _buildEmptyState(category);
    }

    return ListView.builder(
      padding: AppSpacing.paddingMd,
      itemCount: trips.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: AppSpacing.paddingVerticalXs,
          child: _TripCard(trip: trips[index]),
        );
      },
    );
  }

  Widget _buildEmptyState(String category) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getEmptyStateIcon(category),
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          AppSpacing.verticalSpaceMd,
          Text(
            _getEmptyStateTitle(category),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          AppSpacing.verticalSpaceSm,
          Text(
            _getEmptyStateSubtitle(category),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          if (category == 'upcoming') ...[
            AppSpacing.verticalSpaceLg,
            if (ref.watch(isGuestUserProvider)) ...[
              FilledButton(
                onPressed: () => context.go('/discover'),
                child: const Text('Discover Public Trips'),
              ),
              AppSpacing.verticalSpaceSm,
              OutlinedButton(
                onPressed: () => context.go('/auth/signup'),
                child: const Text('Sign Up to Create Trips'),
              ),
            ] else ...[
              FilledButton(
                onPressed: () => context.go('/trips/create'),
                child: const Text('Create Your First Trip'),
              ),
            ],
          ],
        ],
      ),
    );
  }

  IconData _getEmptyStateIcon(String category) {
    switch (category) {
      case 'active':
        return Icons.explore_off;
      case 'upcoming':
        return Icons.flight_takeoff;
      case 'past':
        return Icons.history;
      default:
        return Icons.trip_origin;
    }
  }

  String _getEmptyStateTitle(String category) {
    switch (category) {
      case 'active':
        return 'No Active Trips';
      case 'upcoming':
        return 'No Upcoming Trips';
      case 'past':
        return 'No Past Trips';
      default:
        return 'No Trips';
    }
  }

  String _getEmptyStateSubtitle(String category) {
    final isGuest = ref.watch(isGuestUserProvider);
    
    switch (category) {
      case 'active':
        return isGuest 
            ? 'Browse public trips or join private trips to get started.'
            : 'You don\'t have any trips in progress right now.';
      case 'upcoming':
        return isGuest
            ? 'Discover public trips or sign up to create your own adventures.'
            : 'Start planning your next adventure by creating a new trip.';
      case 'past':
        return 'Your completed trips will appear here.';
      default:
        return 'Your trips will appear here.';
    }
  }

  void _showJoinTripDialog(BuildContext context) {
    final codeController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Join Trip'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter the trip invite code to join:'),
            AppSpacing.verticalSpaceMd,
            TextField(
              controller: codeController,
              decoration: const InputDecoration(
                labelText: 'Invite Code',
                hintText: 'e.g. 7Q9KHF',
              ),
              textCapitalization: TextCapitalization.characters,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (codeController.text.isNotEmpty) {
                Navigator.of(context).pop();
                final tripsNotifier = ref.read(tripsProvider.notifier);
                try {
                  await tripsNotifier.joinTrip(codeController.text);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Successfully joined trip!')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to join trip: $e')),
                    );
                  }
                }
              }
            },
            child: const Text('Join'),
          ),
        ],
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  final Trip trip;

  const _TripCard({required this.trip});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    try {
      final statusColor = AppColors.getTripStatusColor(trip.status.name);

      return Card(
      child: InkWell(
        onTap: () => context.go('/trips/${trip.id}'),
        borderRadius: AppSpacing.cardRadius,
        child: Padding(
          padding: AppSpacing.paddingLg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with title and status
              Row(
                children: [
                  Expanded(
                    child: Text(
                      trip.name,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: AppSpacing.paddingVerticalXs.copyWith(
                      left: AppSpacing.sm,
                      right: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: Text(
                      trip.status.name.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              AppSpacing.verticalSpaceSm,

              // Theme and route
              Text(
                trip.theme,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),

              AppSpacing.verticalSpaceXs,

              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: AppSpacing.iconSm,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  AppSpacing.horizontalSpaceXs,
                  Expanded(
                    child: Text(
                      '${trip.origin.name} → ${trip.destination.name}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),

              AppSpacing.verticalSpaceMd,

              // Dates and participants
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: AppSpacing.iconSm,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  AppSpacing.horizontalSpaceXs,
                  Text(
                    _formatDateRange(trip.startDate, trip.endDate),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.people_outlined,
                    size: AppSpacing.iconSm,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  AppSpacing.horizontalSpaceXs,
                  Text(
                    '${trip.seatsTotal - trip.seatsAvailable}/${trip.seatsTotal}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),

              // Rating display
              if (trip.ratingSummary.totalRatings > 0) ...[
                AppSpacing.verticalSpaceXs,
                Row(
                  children: [
                    Icon(
                      Icons.star,
                      size: 16,
                      color: Colors.amber,
                    ),
                    AppSpacing.horizontalSpaceXs,
                    Text(
                      trip.ratingSummary.averageRating.toStringAsFixed(1),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    AppSpacing.horizontalSpaceXs,
                    Text(
                      '(${trip.ratingSummary.totalRatings} reviews)',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (trip.ratingSummary.topHighlights.isNotEmpty) ...[
                      AppSpacing.horizontalSpaceXs,
                      Icon(
                        Icons.recommend,
                        size: 14,
                        color: theme.colorScheme.primary,
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
    } catch (e) {
      print('Error building trip card for ${trip.id}: $e');
      return Card(
        child: Padding(
          padding: AppSpacing.paddingLg,
          child: Text('Error loading trip: ${trip.name}'),
        ),
      );
    }
  }

  String _formatDateRange(DateTime start, DateTime end) {
    try {
      final startStr = '${start.day}/${start.month}';
      final endStr = '${end.day}/${end.month}';
      return '$startStr - $endStr';
    } catch (e) {
      print('Error formatting date range: $e');
      return 'Invalid Date';
    }
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _TabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) {
    return false;
  }
}

