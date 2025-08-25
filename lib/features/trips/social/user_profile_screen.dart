import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../core/data/models/models.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import 'widgets/user_profile_card.dart';
import 'widgets/message_dialog.dart';

class UserProfileScreen extends ConsumerStatefulWidget {
  final String userId;
  final String? tripId;

  const UserProfileScreen({
    super.key,
    required this.userId,
    this.tripId,
  });

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  UserProfile? _userProfile;
  bool _isLoading = true;
  bool _isFollowing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
          leading: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_userProfile == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
          leading: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.person_off,
                size: 64,
                color: theme.colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                'User Not Found',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_userProfile!.name),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [
          IconButton(
            onPressed: _showMoreOptions,
            icon: const Icon(Icons.more_vert),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Achievements'),
            Tab(text: 'Activity'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(theme),
          _buildAchievementsTab(theme),
          _buildActivityTab(theme),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: AppSpacing.paddingMd,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile header
          _buildProfileHeader(theme),
          const SizedBox(height: 24),
          // Stats grid
          _buildStatsGrid(theme),
          const SizedBox(height: 24),
          // Bio section
          if (_userProfile!.bio != null && _userProfile!.bio!.isNotEmpty) ...[
            _buildBioSection(theme),
            const SizedBox(height: 24),
          ],
          // Recent trips
          _buildRecentTrips(theme),
          const SizedBox(height: 24),
          // Follow/Message buttons
          _buildActionButtons(theme),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(ThemeData theme) {
    return Row(
      children: [
        // Avatar
        Stack(
          children: [
            CircleAvatar(
              radius: 48,
              backgroundColor: theme.colorScheme.primaryContainer,
              backgroundImage: _userProfile!.avatarUrl != null
                  ? NetworkImage(_userProfile!.avatarUrl!)
                  : null,
              child: _userProfile!.avatarUrl == null
                  ? Text(
                      _userProfile!.name.substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    )
                  : null,
            ),
            // Status indicator
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: _userProfile!.status.color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.colorScheme.surface,
                    width: 3,
                  ),
                ),
                child: Icon(
                  _userProfile!.status.icon,
                  size: 10,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 16),
        // User info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _userProfile!.name,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (_userProfile!.isVerified) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.verified,
                      color: theme.colorScheme.primary,
                      size: 18,
                    ),
                  ],
                ],
              ),
              if (_userProfile!.location != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 14,
                      color: theme.colorScheme.outline,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        _userProfile!.location!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 4),
              Text(
                'Joined ${timeago.format(_userProfile!.joinedAt)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(ThemeData theme) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.2,
      children: [
        _buildStatCard(theme, 'Trips', '${_userProfile!.stats.totalTrips}', Icons.flight),
        _buildStatCard(theme, 'Posts', '${_userProfile!.stats.totalPosts}', Icons.post_add),
        _buildStatCard(theme, 'Followers', '${_userProfile!.stats.followersCount}', Icons.people),
        _buildStatCard(theme, 'Rating', _userProfile!.stats.averageRating > 0 ? '${_userProfile!.stats.averageRating.toStringAsFixed(1)}⭐' : 'N/A', Icons.star),
        _buildStatCard(theme, 'Completed', '${_userProfile!.stats.completedTrips}', Icons.check_circle),
        _buildStatCard(theme, 'Stories', '${_userProfile!.stats.totalStories}', Icons.auto_stories),
        _buildStatCard(theme, 'Following', '${_userProfile!.stats.followingCount}', Icons.person_add),
        _buildStatCard(theme, 'Achievements', '${_userProfile!.stats.achievementsCount}', Icons.emoji_events),
      ],
    );
  }

  Widget _buildStatCard(ThemeData theme, String label, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBioSection(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'About',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _userProfile!.bio!,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTrips(ThemeData theme) {
    // TODO: Load actual recent trips
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.flight,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Recent Trips',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Placeholder for recent trips
            Center(
              child: Text(
                'No recent trips to display',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _toggleFollow,
            icon: Icon(
              _isFollowing ? Icons.person_remove : Icons.person_add,
              size: 16,
            ),
            label: Text(_isFollowing ? 'Unfollow' : 'Follow'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _isFollowing
                  ? theme.colorScheme.error
                  : theme.colorScheme.primary,
              side: BorderSide(
                color: _isFollowing
                    ? theme.colorScheme.error
                    : theme.colorScheme.primary,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _sendMessage,
            icon: const Icon(Icons.message, size: 16),
            label: const Text('Message'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementsTab(ThemeData theme) {
    if (_userProfile!.achievements.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 64,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No Achievements Yet',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Complete trips and engage with the community to earn achievements!',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: AppSpacing.paddingMd,
      itemCount: _userProfile!.achievements.length,
      itemBuilder: (context, index) {
        final achievement = _userProfile!.achievements[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: achievement.type.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                achievement.type.icon,
                color: achievement.type.color,
                size: 24,
              ),
            ),
            title: Text(
              achievement.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(achievement.description),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 12,
                      color: theme.colorScheme.outline,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      timeago.format(achievement.earnedAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                    const Spacer(),
                    if (achievement.isRare)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'RARE',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            trailing: Text(
              '${achievement.points} pts',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActivityTab(ThemeData theme) {
    // TODO: Load actual activity feed
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.timeline,
            size: 64,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'Activity Feed Coming Soon',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Recent posts, comments, and interactions will appear here',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _loadUserProfile() {
    // TODO: Load actual user profile from service
    // For now, create a mock profile
    setState(() {
      _userProfile = UserProfile(
        id: widget.userId,
        name: _getUserName(widget.userId),
        email: '${widget.userId}@example.com',
        bio: 'Passionate traveler and adventure seeker. Love exploring new places and meeting amazing people!',
        location: 'Mumbai, India',
        joinedAt: DateTime.now().subtract(const Duration(days: 365)),
        stats: UserStats(
          totalTrips: 12,
          completedTrips: 10,
          totalPosts: 45,
          totalStories: 23,
          totalLikes: 156,
          totalComments: 89,
          followersCount: 234,
          followingCount: 156,
          achievementsCount: 8,
          checkIns: 67,
          rollCallsAttended: 45,
          rollCallsLed: 12,
          averageRating: 4.7,
          totalReviews: 23,
        ),
        achievements: _generateMockAchievements(),
        following: ['u_123', 'u_456', 'u_789'],
        followers: ['u_321', 'u_654', 'u_987'],
        preferences: const UserPreferences(),
        isVerified: widget.userId == 'u_leader',
      );
      _isLoading = false;
    });
  }

  List<Achievement> _generateMockAchievements() {
    return [
      Achievement(
        id: 'ach_1',
        title: 'First Trip',
        description: 'Completed your first trip',
        icon: '🎉',
        type: AchievementType.tripCompletion,
        earnedAt: DateTime.now().subtract(const Duration(days: 300)),
        points: 100,
      ),
      Achievement(
        id: 'ach_2',
        title: 'Social Butterfly',
        description: 'Made 10 posts in a single trip',
        icon: '🦋',
        type: AchievementType.socialEngagement,
        earnedAt: DateTime.now().subtract(const Duration(days: 200)),
        points: 150,
      ),
      Achievement(
        id: 'ach_3',
        title: 'Trip Leader',
        description: 'Led your first roll call',
        icon: '👑',
        type: AchievementType.leadership,
        earnedAt: DateTime.now().subtract(const Duration(days: 150)),
        points: 200,
        isRare: true,
      ),
      Achievement(
        id: 'ach_4',
        title: 'Photographer',
        description: 'Shared 5 photos in a single trip',
        icon: '📸',
        type: AchievementType.photography,
        earnedAt: DateTime.now().subtract(const Duration(days: 100)),
        points: 120,
      ),
      Achievement(
        id: 'ach_5',
        title: 'Community Helper',
        description: 'Received 10 likes on a single post',
        icon: '🤝',
        type: AchievementType.community,
        earnedAt: DateTime.now().subtract(const Duration(days: 50)),
        points: 80,
      ),
    ];
  }

  String _getUserName(String userId) {
    switch (userId) {
      case 'u_leader':
        return 'Aisha Sharma';
      case 'u_123':
        return 'Rahul Kumar';
      case 'u_456':
        return 'Priya Singh';
      case 'u_789':
        return 'Vikram Patel';
      case 'u_321':
        return 'Neha Gupta';
      default:
        return 'User ${userId.substring(2)}';
    }
  }

  void _toggleFollow() {
    setState(() {
      _isFollowing = !_isFollowing;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isFollowing ? 'Following ${_userProfile!.name}' : 'Unfollowed ${_userProfile!.name}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _sendMessage() {
    showDialog(
      context: context,
      builder: (context) => MessageDialog(
        recipientName: _userProfile!.name,
        recipientId: _userProfile!.id,
        tripId: widget.tripId,
      ),
    );
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.share),
            title: const Text('Share Profile'),
            onTap: () {
              Navigator.of(context).pop();
              // TODO: Implement share functionality
            },
          ),
          ListTile(
            leading: const Icon(Icons.report),
            title: const Text('Report User'),
            onTap: () {
              Navigator.of(context).pop();
              // TODO: Implement report functionality
            },
          ),
          ListTile(
            leading: const Icon(Icons.block),
            title: const Text('Block User'),
            onTap: () {
              Navigator.of(context).pop();
              // TODO: Implement block functionality
            },
          ),
        ],
      ),
    );
  }
}
