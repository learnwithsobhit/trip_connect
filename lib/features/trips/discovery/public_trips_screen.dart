import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/models/models.dart';
import '../../../core/data/providers/auth_provider.dart';

import '../../../core/theme/app_spacing.dart';
import '../../common/widgets/star_rating.dart';
import 'trip_filters_screen.dart';

class PublicTripsScreen extends ConsumerStatefulWidget {
  const PublicTripsScreen({super.key});

  @override
  ConsumerState<PublicTripsScreen> createState() => _PublicTripsScreenState();
}

class _PublicTripsScreenState extends ConsumerState<PublicTripsScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  final _privateTripCodeController = TextEditingController();
  String _searchQuery = '';
  bool _showPrivateTripSearch = false;
  TripSearchFilter? _activeFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _privateTripCodeController.dispose();
    super.dispose();
  }

  // Mock public trips data
  List<Trip> get _publicTrips => [
    Trip(
      id: 'pub_001',
      name: 'Goa Beach Hopping 🏖️',
      theme: 'Beach & Adventure',
      origin: Location(name: 'Mumbai', lat: 19.0760, lng: 72.8777),
      destination: Location(name: 'Goa', lat: 15.2993, lng: 74.1240),
      startDate: DateTime.now().add(const Duration(days: 15)),
      endDate: DateTime.now().add(const Duration(days: 20)),
      seatsTotal: 25,
      seatsAvailable: 8,
      leaderId: 'leader_1',
      invite: TripInvite(code: 'GOABEACH', qr: 'QR_DATA'),
      status: TripStatus.planning,
    ),
    Trip(
      id: 'pub_002',
      name: 'Himachal Trek Adventure ⛰️',
      theme: 'Mountains & Trekking',
      origin: Location(name: 'Delhi', lat: 28.7041, lng: 77.1025),
      destination: Location(name: 'Manali', lat: 32.2396, lng: 77.1887),
      startDate: DateTime.now().add(const Duration(days: 30)),
      endDate: DateTime.now().add(const Duration(days: 35)),
      seatsTotal: 15,
      seatsAvailable: 5,
      leaderId: 'leader_2',
      invite: TripInvite(code: 'HIMTREK', qr: 'QR_DATA'),
      status: TripStatus.planning,
    ),
    Trip(
      id: 'pub_003',
      name: 'Kerala Backwaters 🛶',
      theme: 'Nature & Culture',
      origin: Location(name: 'Kochi', lat: 9.9312, lng: 76.2673),
      destination: Location(name: 'Alleppey', lat: 9.4981, lng: 76.3388),
      startDate: DateTime.now().add(const Duration(days: 45)),
      endDate: DateTime.now().add(const Duration(days: 48)),
      seatsTotal: 20,
      seatsAvailable: 12,
      leaderId: 'leader_3',
      invite: TripInvite(code: 'KERALA', qr: 'QR_DATA'),
      status: TripStatus.planning,
    ),
  ];

  List<Trip> get _filteredTrips {
    var trips = _publicTrips;
    
    // Apply search query filter
    if (_searchQuery.isNotEmpty) {
      trips = trips.where((trip) =>
        trip.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        trip.theme.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        trip.destination.name.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }
    
    // Apply rating and other filters
    if (_activeFilter != null) {
      final filter = _activeFilter!;
      
      trips = trips.where((trip) {
        // Rating filter
        if (filter.minRating != null && trip.ratingSummary.averageRating < filter.minRating!) {
          return false;
        }
        
        // Reviews filter
        if (filter.minReviews != null && trip.ratingSummary.totalRatings < filter.minReviews!) {
          return false;
        }
        
        // Date range filter
        if (filter.dateRange != null) {
          final dateRange = filter.dateRange!;
          if (trip.startDate.isBefore(dateRange.start) || trip.endDate.isAfter(dateRange.end)) {
            return false;
          }
        }
        
        // Theme filter
        if (filter.themes.isNotEmpty && !filter.themes.contains(trip.theme)) {
          return false;
        }
        
        // Group size filter
        if (trip.seatsTotal > filter.maxParticipants) {
          return false;
        }
        
        // Recommendation filter
        if (filter.onlyRecommended) {
          final recommendationRate = trip.ratingSummary.totalRatings > 0 
              ? trip.ratingSummary.recommendationCount / trip.ratingSummary.totalRatings
              : 0.0;
          if (recommendationRate < 0.8) {
            return false;
          }
        }
        
        return true;
      }).toList();
    }
    
    return trips;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover Public Trips'),
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
        leading: ref.watch(isGuestUserProvider) 
            ? IconButton(
                onPressed: () => context.go('/auth/welcome'),
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Back to Welcome',
              )
            : null,
        actions: [
          IconButton(
            onPressed: _openFilters,
            icon: const Icon(Icons.tune),
            tooltip: 'Filter Trips',
          ),
          IconButton(
            onPressed: () {
              print('App bar Sign Up button pressed');
              _showSignUpPrompt();
            },
            icon: const Icon(Icons.person_add),
            tooltip: 'Sign Up',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Public Trips'),
            Tab(text: 'Private Trips'),
            Tab(text: 'This Month'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: AppSpacing.paddingMd,
            child: Column(
              children: [
                // Public trips search
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search public trips by destination, theme...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_searchQuery.isNotEmpty)
                          IconButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                            icon: const Icon(Icons.clear),
                          ),
                        IconButton(
                          onPressed: () {
                            setState(() => _showPrivateTripSearch = !_showPrivateTripSearch);
                          },
                          icon: Icon(_showPrivateTripSearch ? Icons.public : Icons.lock),
                          tooltip: _showPrivateTripSearch ? 'Switch to Public' : 'Search Private Trips',
                        ),
                      ],
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                  },
                ),
                
                // Private trip code search
                if (_showPrivateTripSearch) ...[
                  AppSpacing.verticalSpaceSm,
                  TextField(
                    controller: _privateTripCodeController,
                    decoration: InputDecoration(
                      hintText: 'Enter private trip joining code...',
                      prefixIcon: const Icon(Icons.vpn_key),
                      suffixIcon: _privateTripCodeController.text.isNotEmpty
                          ? IconButton(
                              onPressed: () => _searchPrivateTrip(),
                              icon: const Icon(Icons.search),
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),
                ],
              ],
            ),
          ),
          
          // Trips List
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTripsList(_filteredTrips),
                _buildPrivateTripsSearch(),
                _buildTripsList(_filteredTrips.where((trip) =>
                  trip.startDate.isBefore(DateTime.now().add(const Duration(days: 30)))
                ).toList()),
              ],
            ),
          ),
        ],
      ),
              bottomNavigationBar: Container(
          padding: AppSpacing.paddingMd,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(
              top: BorderSide(
                color: theme.colorScheme.outline.withOpacity(0.2),
              ),
            ),
          ),
          child: ref.watch(isGuestUserProvider) 
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Back to Welcome button for guests
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        onPressed: () => context.go('/auth/welcome'),
                        icon: const Icon(Icons.home),
                        label: const Text('Back to Welcome'),
                        style: TextButton.styleFrom(
                          foregroundColor: theme.colorScheme.outline,
                        ),
                      ),
                    ),
                    AppSpacing.verticalSpaceSm,
                    // Sign In and Sign Up buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              print('Sign In button pressed');
                              context.go('/auth/signin');
                            },
                            icon: const Icon(Icons.login),
                            label: const Text('Sign In'),
                          ),
                        ),
                        AppSpacing.horizontalSpaceMd,
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () {
                              print('Sign Up button pressed');
                              context.go('/auth/signup');
                            },
                            icon: const Icon(Icons.person_add),
                            label: const Text('Sign Up'),
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          print('Sign In button pressed');
                          context.go('/auth/signin');
                        },
                        icon: const Icon(Icons.login),
                        label: const Text('Sign In'),
                      ),
                    ),
                    AppSpacing.horizontalSpaceMd,
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          print('Sign Up button pressed');
                          context.go('/auth/signup');
                        },
                        icon: const Icon(Icons.person_add),
                        label: const Text('Sign Up'),
                      ),
                    ),
                  ],
                ),
        ),
    );
  }

  Widget _buildTripsList(List<Trip> trips) {
    if (trips.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.explore_off,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            AppSpacing.verticalSpaceMd,
            Text(
              'No trips found',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            AppSpacing.verticalSpaceXs,
            Text(
              'Try adjusting your search or filters',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: AppSpacing.paddingMd,
      itemCount: trips.length,
      itemBuilder: (context, index) {
        final trip = trips[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildTripCard(trip),
        );
      },
    );
  }

  Widget _buildTripCard(Trip trip) {
    final theme = Theme.of(context);
    final daysLeft = trip.startDate.difference(DateTime.now()).inDays;
    
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showTripDetails(trip),
        child: Padding(
          padding: AppSpacing.paddingLg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trip.name,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        AppSpacing.verticalSpaceXs,
                        Text(
                          trip.theme,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Public',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              
              AppSpacing.verticalSpaceMd,
              
              // Route
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  AppSpacing.horizontalSpaceXs,
                  Text(
                    '${trip.origin.name} → ${trip.destination.name}',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
              
              AppSpacing.verticalSpaceXs,
              
              // Date
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: theme.colorScheme.outline,
                  ),
                  AppSpacing.horizontalSpaceXs,
                  Text(
                    '${_formatDate(trip.startDate)} - ${_formatDate(trip.endDate)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                  const Spacer(),
                  if (daysLeft > 0) ...[
                    Icon(
                      Icons.schedule,
                      size: 16,
                      color: theme.colorScheme.outline,
                    ),
                    AppSpacing.horizontalSpaceXs,
                    Text(
                      '$daysLeft days left',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
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
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    AppSpacing.horizontalSpaceXs,
                    Text(
                      '(${trip.ratingSummary.totalRatings} reviews)',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                    if (trip.ratingSummary.recommendationCount > 0) ...[
                      AppSpacing.horizontalSpaceXs,
                      Icon(
                        Icons.thumb_up,
                        size: 14,
                        color: theme.colorScheme.primary,
                      ),
                      AppSpacing.horizontalSpaceXs,
                      Text(
                        '${trip.ratingSummary.recommendationCount} recommend',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
              
              AppSpacing.verticalSpaceMd,
              
              // Seats and Action
              Row(
                children: [
                  Icon(
                    Icons.people,
                    size: 16,
                    color: theme.colorScheme.outline,
                  ),
                  AppSpacing.horizontalSpaceXs,
                  Text(
                    '${trip.seatsAvailable}/${trip.seatsTotal} seats available',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                  const Spacer(),
                  OutlinedButton(
                    onPressed: () => _showJoinDialog(trip),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(80, 32),
                    ),
                    child: const Text('Join Trip'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]}';
  }

  void _showTripDetails(Trip trip) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          padding: AppSpacing.paddingLg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              
              AppSpacing.verticalSpaceMd,
              
              Text(
                trip.name,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              AppSpacing.verticalSpaceXs,
              
              Text(
                trip.theme,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              
              // Rating display
              if (trip.ratingSummary.totalRatings > 0) ...[
                AppSpacing.verticalSpaceMd,
                Row(
                  children: [
                    Icon(
                      Icons.star,
                      size: 20,
                      color: Colors.amber,
                    ),
                    AppSpacing.horizontalSpaceXs,
                    Text(
                      trip.ratingSummary.averageRating.toStringAsFixed(1),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    AppSpacing.horizontalSpaceXs,
                    Text(
                      '(${trip.ratingSummary.totalRatings} reviews)',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                if (trip.ratingSummary.topHighlights.isNotEmpty) ...[
                  AppSpacing.verticalSpaceXs,
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: trip.ratingSummary.topHighlights.take(3).map((highlight) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          highlight.replaceAll(RegExp(r'([A-Z])'), ' \$1').trim(),
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
              
              AppSpacing.verticalSpaceLg,
              
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _showJoinDialog(trip);
                      },
                      icon: const Icon(Icons.login),
                      label: const Text('Sign In to Join'),
                    ),
                  ),
                  AppSpacing.horizontalSpaceMd,
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _showSignUpPrompt();
                      },
                      icon: const Icon(Icons.person_add),
                      label: const Text('Sign Up & Join'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showJoinDialog(Trip trip) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Authentication Required'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('To join "${trip.name}", you need to sign in or create an account.'),
            AppSpacing.verticalSpaceMd,
            Container(
              padding: AppSpacing.paddingMd,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Why sign up?',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  AppSpacing.verticalSpaceXs,
                  Text(
                    '• Full trip participation',
                    style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer),
                  ),
                  Text(
                    '• Chat and media sharing',
                    style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer),
                  ),
                  Text(
                    '• Trip history and ratings',
                    style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer),
                  ),
                  Text(
                    '• Safety and emergency features',
                    style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          OutlinedButton(
            onPressed: () {
              print('Dialog Sign In button pressed');
              Navigator.pop(context);
              context.go('/auth/signin');
            },
            child: const Text('Sign In'),
          ),
          FilledButton(
            onPressed: () {
              print('Dialog Sign Up button pressed');
              Navigator.pop(context);
              context.go('/auth/signup');
            },
            child: const Text('Sign Up'),
          ),
        ],
      ),
    );
  }

  void _showSignUpPrompt() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Account'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sign up to unlock full features:'),
            SizedBox(height: 12),
            Text('✓ Create unlimited trips'),
            Text('✓ Full chat and media sharing'),
            Text('✓ Trip history and favorites'),
            Text('✓ Advanced safety features'),
            Text('✓ Priority support'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Maybe Later'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/auth/signup');
            },
            child: const Text('Sign Up'),
          ),
        ],
      ),
    );
  }

  void _searchPrivateTrip() {
    final code = _privateTripCodeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a trip code')),
      );
      return;
    }

    // Mock private trip search - in real app this would call the API
    _showPrivateTripResult(code);
  }

  void _showPrivateTripResult(String code) {
    // Mock private trip data based on code
    Trip? privateTrip;
    
    switch (code) {
      case 'FAMILY2025':
        privateTrip = Trip(
          id: 'priv_001',
          name: 'Family Beach Vacation 🏖️',
          theme: 'Family & Relaxation',
          origin: Location(name: 'Mumbai', lat: 19.0760, lng: 72.8777),
          destination: Location(name: 'Goa', lat: 15.2993, lng: 74.1240),
          startDate: DateTime.now().add(const Duration(days: 20)),
          endDate: DateTime.now().add(const Duration(days: 25)),
          seatsTotal: 12,
          seatsAvailable: 3,
          leaderId: 'leader_4',
          invite: TripInvite(code: 'FAMILY2025', qr: 'QR_DATA'),
          status: TripStatus.planning,
          privacy: TripPrivacy.private,
        );
        break;
      case 'CORP2025':
        privateTrip = Trip(
          id: 'priv_002',
          name: 'Corporate Team Building 🏢',
          theme: 'Business & Adventure',
          origin: Location(name: 'Bangalore', lat: 12.9716, lng: 77.5946),
          destination: Location(name: 'Coorg', lat: 12.3375, lng: 75.8069),
          startDate: DateTime.now().add(const Duration(days: 35)),
          endDate: DateTime.now().add(const Duration(days: 37)),
          seatsTotal: 20,
          seatsAvailable: 8,
          leaderId: 'leader_5',
          invite: TripInvite(code: 'CORP2025', qr: 'QR_DATA'),
          status: TripStatus.planning,
          privacy: TripPrivacy.private,
        );
        break;
      default:
        privateTrip = null;
    }

    if (privateTrip != null) {
      _showPrivateTripDetails(privateTrip);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No trip found with code: $code'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _showPrivateTripDetails(Trip trip) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.9,
        minChildSize: 0.6,
        builder: (context, scrollController) => Container(
          padding: AppSpacing.paddingLg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              
              AppSpacing.verticalSpaceMd,
              
              // Private trip indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.lock,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                    AppSpacing.horizontalSpaceXs,
                    Text(
                      'Private Trip',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSecondaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              
              AppSpacing.verticalSpaceMd,
              
              Text(
                trip.name,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              AppSpacing.verticalSpaceXs,
              
              Text(
                trip.theme,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              
              AppSpacing.verticalSpaceLg,
              
              // Trip details
              _buildTripDetailRow('Route', '${trip.origin.name} → ${trip.destination.name}'),
              _buildTripDetailRow('Dates', '${_formatDate(trip.startDate)} - ${_formatDate(trip.endDate)}'),
              _buildTripDetailRow('Seats', '${trip.seatsAvailable}/${trip.seatsTotal} available'),
              _buildTripDetailRow('Code', trip.invite.code),
              
              AppSpacing.verticalSpaceLg,
              
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _showJoinPrivateTripDialog(trip);
                      },
                      icon: const Icon(Icons.login),
                      label: const Text('Sign In to Join'),
                    ),
                  ),
                  AppSpacing.horizontalSpaceMd,
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _showSignUpForPrivateTrip(trip);
                      },
                      icon: const Icon(Icons.person_add),
                      label: const Text('Sign Up & Join'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTripDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  void _showJoinPrivateTripDialog(Trip trip) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Join Private Trip'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('You need to sign in to join "${trip.name}".'),
            AppSpacing.verticalSpaceMd,
            Container(
              padding: AppSpacing.paddingMd,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Private Trip Benefits:',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                  ),
                  AppSpacing.verticalSpaceXs,
                  Text(
                    '• Exclusive access to trip details',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSecondaryContainer),
                  ),
                  Text(
                    '• Direct communication with trip leader',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSecondaryContainer),
                  ),
                  Text(
                    '• Priority booking and updates',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSecondaryContainer),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/auth/signin');
            },
            child: const Text('Sign In'),
          ),
        ],
      ),
    );
  }

  void _showSignUpForPrivateTrip(Trip trip) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Up & Join'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Create an account to join "${trip.name}" and unlock all features.'),
            AppSpacing.verticalSpaceMd,
            Container(
              padding: AppSpacing.paddingMd,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'What you\'ll get:',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  AppSpacing.verticalSpaceXs,
                  Text(
                    '• Immediate access to this private trip',
                    style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer),
                  ),
                  Text(
                    '• Full trip participation and chat',
                    style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer),
                  ),
                  Text(
                    '• Trip history and ratings',
                    style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer),
                  ),
                  Text(
                    '• Create your own trips',
                    style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/auth/signup');
            },
            child: const Text('Sign Up Now'),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivateTripsSearch() {
    return Padding(
      padding: AppSpacing.paddingLg,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lock_outline,
            size: 80,
            color: Theme.of(context).colorScheme.outline,
          ),
          AppSpacing.verticalSpaceLg,
          Text(
            'Search Private Trips',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          AppSpacing.verticalSpaceMd,
          Text(
            'Enter a private trip joining code to find and join exclusive trips.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
            textAlign: TextAlign.center,
          ),
          AppSpacing.verticalSpaceLg,
          Container(
            padding: AppSpacing.paddingLg,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  'Sample Private Trip Codes:',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                AppSpacing.verticalSpaceMd,
                _buildSampleCode('FAMILY2025', 'Family Beach Vacation'),
                _buildSampleCode('CORP2025', 'Corporate Team Building'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSampleCode(String code, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              code,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          AppSpacing.horizontalSpaceMd,
          Expanded(
            child: Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openFilters() async {
    final result = await Navigator.push<TripSearchFilter>(
      context,
      MaterialPageRoute(
        builder: (context) => TripFiltersScreen(
          currentFilter: _activeFilter,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _activeFilter = result;
      });
    }
  }
}