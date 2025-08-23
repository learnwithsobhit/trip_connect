import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/data/providers/trip_provider.dart';
import '../../../core/data/models/models.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_colors.dart';
import '../../common/widgets/user_rating_badge.dart';

class TripPeopleScreen extends ConsumerWidget {
  final String tripId;

  const TripPeopleScreen({super.key, required this.tripId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Check if rating mode is enabled
    final uri = GoRouterState.of(context).uri;
    final showRating = uri.queryParameters['showRating'] == 'true';
    final theme = Theme.of(context);
    final tripAsync = ref.watch(tripProvider(tripId));
    final membersAsync = ref.watch(tripMembersProvider(tripId));
    final usersAsync = ref.watch(tripUsersProvider(tripId));

    return Scaffold(
      appBar: AppBar(
        title: Text(showRating ? 'Rate Trip Members' : 'People'),
        leading: IconButton(
          onPressed: () => context.go('/trips/$tripId'),
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [
          IconButton(
            onPressed: () => _shareInvite(context, ref),
            icon: const Icon(Icons.share),
            tooltip: 'Share Invite',
          ),
          IconButton(
            onPressed: () => _showInviteCode(context, ref),
            icon: const Icon(Icons.qr_code),
            tooltip: 'Show QR Code',
          ),
        ],
      ),
      body: tripAsync.when(
        data: (trip) {
          if (trip == null) return const Center(child: Text('Trip not found'));
          
          return Column(
            children: [
              // Trip capacity info
              _buildCapacityCard(theme, trip),
              
              // Members list
              Expanded(
                child: membersAsync.when(
                  data: (members) => usersAsync.when(
                    data: (users) => _buildMembersList(theme, members, users, showRating),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (error, stack) => Center(child: Text('Error loading users: $error')),
                  ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(child: Text('Error loading members: $error')),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildCapacityCard(ThemeData theme, Trip trip) {
    final occupiedSeats = trip.seatsTotal - trip.seatsAvailable;
    final occupancyPercentage = occupiedSeats / trip.seatsTotal;

    return Card(
      margin: AppSpacing.paddingMd,
      child: Padding(
        padding: AppSpacing.paddingLg,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Trip Capacity',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$occupiedSeats / ${trip.seatsTotal}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            AppSpacing.verticalSpaceMd,
            
            // Progress bar
            LinearProgressIndicator(
              value: occupancyPercentage,
              backgroundColor: theme.colorScheme.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(
                occupancyPercentage > 0.8 
                    ? AppColors.warning 
                    : theme.colorScheme.primary,
              ),
            ),
            
            AppSpacing.verticalSpaceSm,
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${trip.seatsAvailable} seats available',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  trip.privacy.name.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: trip.privacy == TripPrivacy.public 
                        ? AppColors.success 
                        : AppColors.warning,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMembersList(ThemeData theme, List<Membership> members, List<User> users, bool showRating) {
    if (members.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No members yet'),
          ],
        ),
      );
    }

    // Group members by role
    final leaders = members.where((m) => m.role == UserRole.leader).toList();
    final coLeaders = members.where((m) => m.role == UserRole.coLeader).toList();
    final travelers = members.where((m) => m.role == UserRole.traveler).toList();
    final followers = members.where((m) => m.role == UserRole.follower).toList();

    return ListView(
      padding: AppSpacing.paddingMd,
      children: [
        if (leaders.isNotEmpty) _buildRoleSection(theme, 'Leaders', leaders, users, showRating),
        if (coLeaders.isNotEmpty) _buildRoleSection(theme, 'Co-Leaders', coLeaders, users, showRating),
        if (travelers.isNotEmpty) _buildRoleSection(theme, 'Travelers', travelers, users, showRating),
        if (followers.isNotEmpty) _buildRoleSection(theme, 'Followers', followers, users, showRating),
      ],
    );
  }

  Widget _buildRoleSection(ThemeData theme, String title, List<Membership> members, List<User> users, bool showRating) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: AppSpacing.paddingVerticalMd,
          child: Text(
            '$title (${members.length})',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        
        ...members.map((member) {
          final user = users.cast<User?>().firstWhere(
            (u) => u?.id == member.userId,
            orElse: () => null,
          );
          
          return _MemberCard(
            member: member,
            user: user,
            showRating: showRating,
            tripId: tripId,
          );
        }),
        
        AppSpacing.verticalSpaceLg,
      ],
    );
  }

  void _shareInvite(BuildContext context, WidgetRef ref) {
    final tripAsync = ref.read(tripProvider(tripId));
    tripAsync.whenData((trip) {
      if (trip != null) {
        Share.share(
          'Join my trip "${trip.name}" on TripConnect!\n\n'
          'Use invite code: ${trip.invite.code}\n'
          'Or scan this QR: ${trip.invite.qr}',
          subject: 'Join ${trip.name} Trip',
        );
      }
    });
  }

  void _showInviteCode(BuildContext context, WidgetRef ref) {
    final tripAsync = ref.read(tripProvider(tripId));
    tripAsync.whenData((trip) {
      if (trip != null) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Invite Code'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Share this code with others to invite them:',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                AppSpacing.verticalSpaceMd,
                Container(
                  padding: AppSpacing.paddingMd,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  ),
                  child: Text(
                    trip.invite.code,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                AppSpacing.verticalSpaceMd,
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    children: [
                      // Mock QR Code (would be generated with qr_flutter package)
                      Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.qr_code, size: 64, color: Colors.grey),
                              SizedBox(height: 8),
                              Text(
                                'QR Code',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                'Trip Invite Code',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Scan this QR code to join the trip',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Trip Code: ${trip.id.substring(0, 8).toUpperCase()}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _shareInvite(context, ref);
                },
                child: const Text('Share'),
              ),
            ],
          ),
        );
      }
    });
  }
}

class _MemberCard extends StatelessWidget {
  final Membership member;
  final User? user;
  final bool showRating;
  final String tripId;

  const _MemberCard({
    required this.member,
    required this.user,
    this.showRating = false,
    required this.tripId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final roleColor = AppColors.getRoleColor(member.role.name);

    return Card(
      margin: AppSpacing.paddingVerticalXs,
      child: ListTile(
        leading: _buildAvatar(theme),
        title: Text(
          user?.displayName ?? 'Unknown User',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: roleColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    member.role.name.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: roleColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (member.seat != null) ...[
                  AppSpacing.horizontalSpaceXs,
                  Text(
                    'Seat ${member.seat}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
            
            // User rating display
            if (user != null && user!.ratingSummary.totalRatings > 0) ...[
              AppSpacing.verticalSpaceXs,
              UserRatingRow(
                ratingSummary: user!.ratingSummary,
                showDetails: false,
              ),
            ],
            
            AppSpacing.verticalSpaceXs,
            Row(
              children: [
                Icon(
                  member.isOnline == true ? Icons.circle : Icons.circle_outlined,
                  size: 12,
                  color: member.isOnline == true ? AppColors.success : Colors.grey,
                ),
                AppSpacing.horizontalSpaceXs,
                Text(
                  member.isOnline == true ? 'Online' : _getLastSeenText(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: showRating 
            ? _buildRatingButton(context)
            : (member.location != null 
                ? IconButton(
                    onPressed: () {
                      _showMemberLocation(context);
                    },
                    icon: const Icon(Icons.location_on),
                    tooltip: 'View Location',
                  )
                : null),
      ),
    );
  }

  void _showMemberLocation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${user?.displayName ?? 'Member'}\'s Location'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 300,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.map, size: 64, color: Colors.grey),
                    SizedBox(height: 8),
                    Text(
                      'Map View',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      'Member location would be shown here',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (member.location != null) ...[
              Text(
                'Location: ${member.location!.lat.toStringAsFixed(4)}, ${member.location!.lng.toStringAsFixed(4)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Last updated: Recently',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to map screen with member location
              context.go('/trips/$tripId/map');
            },
            child: const Text('View on Map'),
          ),
        ],
      ),
    );
  }

  String _formatLocationTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  Widget _buildAvatar(ThemeData theme) {
    final initial = user?.displayName.isNotEmpty == true 
        ? user!.displayName[0].toUpperCase() 
        : '?';
    
    return Stack(
      children: [
        CircleAvatar(
          backgroundColor: AppColors.getRoleColor(member.role.name).withOpacity(0.2),
          child: Text(
            initial,
            style: TextStyle(
              color: AppColors.getRoleColor(member.role.name),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        
        // Online indicator
        if (member.isOnline == true)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.colorScheme.surface,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _getLastSeenText() {
    if (member.lastSeen == null) return 'Never seen';
    
    final now = DateTime.now();
    final difference = now.difference(member.lastSeen!);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  Widget _buildRatingButton(BuildContext context) {
    return IconButton(
      onPressed: () {
        if (user != null) {
          context.pushNamed(
            'rate-user',
            pathParameters: {
              'tripId': tripId,
              'userId': user!.id,
            },
            queryParameters: {
              'name': user!.displayName,
            },
          );
        }
      },
      icon: const Icon(Icons.star_border),
      tooltip: 'Rate ${user?.displayName ?? 'User'}',
      style: IconButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}