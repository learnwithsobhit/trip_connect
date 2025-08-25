import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/models/social_features.dart';
import '../../../core/data/models/models.dart';
import '../../../core/services/social_sharing_service.dart';
import '../../../core/theme/app_spacing.dart';
import 'widgets/social_sharing_dialog.dart';
import 'widgets/social_post_card.dart';
import 'widgets/trip_story_card.dart';
import 'widgets/create_post_dialog.dart';
import 'widgets/create_story_dialog.dart';
import 'widgets/highlight_viewer.dart';
import 'widgets/notification_center.dart';
import 'widgets/user_profile_card.dart';
import 'widgets/message_dialog.dart';
import 'user_profile_screen.dart';

class SocialFeedScreen extends ConsumerStatefulWidget {
  final String tripId;

  const SocialFeedScreen({
    super.key,
    required this.tripId,
  });

  @override
  ConsumerState<SocialFeedScreen> createState() => _SocialFeedScreenState();
}

class _SocialFeedScreenState extends ConsumerState<SocialFeedScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final SocialSharingService _sharingService = SocialSharingService();
  
  // Mock data for demonstration
  List<SocialPost> _posts = [];
  List<TripStory> _stories = [];
  List<ShareableContent> _highlights = [];
  List<AppNotification> _notifications = [];
  List<UserProfile> _tripMembers = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadMockData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Social Feed'),
        leading: IconButton(
          onPressed: () => context.go('/trips/${widget.tripId}'),
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [
          IconButton(
            onPressed: _showNotificationCenter,
            icon: Stack(
              children: [
                const Icon(Icons.notifications),
                if (_notifications.where((n) => !n.isRead).isNotEmpty)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 12,
                        minHeight: 12,
                      ),
                      child: Text(
                        '${_notifications.where((n) => !n.isRead).length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            tooltip: 'Notifications',
          ),
          IconButton(
            onPressed: _showCreatePostDialog,
            icon: const Icon(Icons.add),
            tooltip: 'Create Post',
          ),
          IconButton(
            onPressed: _showCreateStoryDialog,
            icon: const Icon(Icons.auto_stories),
            tooltip: 'Create Story',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Stories'),
            Tab(text: 'Posts'),
            Tab(text: 'Highlights'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildStoriesTab(theme),
          _buildPostsTab(theme),
          _buildHighlightsTab(theme),
        ],
      ),
    );
  }

  Widget _buildStoriesTab(ThemeData theme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_stories.isEmpty) {
      return _buildEmptyState(
        theme,
        'No Stories Yet',
        'Be the first to share a story from your trip!',
        Icons.auto_stories,
        () => _showCreateStoryDialog(),
      );
    }

    return ListView.builder(
      padding: AppSpacing.paddingMd,
      itemCount: _stories.length,
                        itemBuilder: (context, index) {
                    final story = _stories[index];
                    return TripStoryCard(
                      story: story,
                      onTap: () => _viewStory(story),
                      onShare: () => _shareStory(story),
                      allStories: _stories,
                      storyIndex: index,
                    );
                  },
    );
  }

  Widget _buildPostsTab(ThemeData theme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_posts.isEmpty) {
      return _buildEmptyState(
        theme,
        'No Posts Yet',
        'Share your first post from the trip!',
        Icons.post_add,
        () => _showCreatePostDialog(),
      );
    }

    return ListView.builder(
      padding: AppSpacing.paddingMd,
      itemCount: _posts.length,
                        itemBuilder: (context, index) {
                    final post = _posts[index];
                    return SocialPostCard(
                      post: post,
                      onLike: () => _likePost(post),
                      onComment: () => _commentOnPost(post),
                      onShare: () => _sharePost(post),
                      onCommentAdded: (comment) => _addCommentToPost(post, comment),
                    );
                  },
    );
  }

  Widget _buildHighlightsTab(ThemeData theme) {
    return ListView(
      padding: AppSpacing.paddingMd,
      children: [
        // Trip Members Section
        _buildSectionHeader(theme, 'Trip Members', Icons.people),
        const SizedBox(height: 12),
        ..._tripMembers.map((member) => UserProfileCard(
          user: member,
          isCurrentUser: member.id == 'u_leader',
          onTap: () => _viewUserProfile(member.id),
          onFollow: () => _followUser(member.id),
          onMessage: () => _messageUser(member.id),
        )),
        const SizedBox(height: 24),
        // Trip Highlights Section
        _buildSectionHeader(theme, 'Trip Highlights', Icons.star),
        const SizedBox(height: 12),
        _buildHighlightCard(
          theme,
          'Trip Highlights',
          'Amazing moments from your adventure',
          Icons.star,
          ContentType.tripHighlight,
        ),
        _buildHighlightCard(
          theme,
          'Photo Album',
          'Beautiful photos from the trip',
          Icons.photo_library,
          ContentType.photoAlbum,
        ),
        _buildHighlightCard(
          theme,
          'Video Memories',
          'Incredible video moments',
          Icons.video_library,
          ContentType.video,
        ),
        _buildHighlightCard(
          theme,
          'Achievements',
          'Milestones and accomplishments',
          Icons.emoji_events,
          ContentType.achievement,
        ),
        _buildHighlightCard(
          theme,
          'Special Memories',
          'Unforgettable moments',
          Icons.favorite,
          ContentType.memory,
        ),
      ],
    );
  }

  Widget _buildHighlightCard(
    ThemeData theme,
    String title,
    String description,
    IconData icon,
    ContentType type,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(
            icon,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(title),
        subtitle: Text(description),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () => _shareHighlight(type),
              icon: const Icon(Icons.share),
              tooltip: 'Share',
            ),
            IconButton(
              onPressed: () => _viewHighlight(type),
              icon: const Icon(Icons.arrow_forward),
              tooltip: 'View',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    ThemeData theme,
    String title,
    String message,
    IconData icon,
    VoidCallback onAction,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAction,
            icon: Icon(icon),
            label: Text('Create $title'),
          ),
        ],
      ),
    );
  }

  void _loadMockData() {
    setState(() {
      _isLoading = true;
    });

    // Simulate loading
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _posts = _generateMockPosts();
        _stories = _generateMockStories();
        _highlights = _generateMockHighlights();
        _notifications = _generateMockNotifications();
        _tripMembers = _generateMockTripMembers();
        _isLoading = false;
      });
    });
  }

  List<SocialPost> _generateMockPosts() {
    return [
      SocialPost(
        id: 'post_1',
        tripId: widget.tripId,
        authorId: 'u_leader',
        content: 'Amazing sunset at the beach! 🌅 The colors were absolutely breathtaking. This is why we travel!',
        type: PostType.photo,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        media: [
          MediaItem(
            id: 'media_1',
            type: SocialMediaType.image,
            url: 'https://picsum.photos/400/300',
            caption: 'Sunset at Goa Beach',
          ),
        ],
        reactions: [
          Reaction(
            id: 'reaction_1',
            userId: 'u_123',
            type: ReactionType.love,
            createdAt: DateTime.now().subtract(const Duration(hours: 1)),
            targetId: 'post_1',
          ),
          Reaction(
            id: 'reaction_2',
            userId: 'u_456',
            type: ReactionType.fire,
            createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
            targetId: 'post_1',
          ),
        ],
        comments: [
          Comment(
            id: 'comment_1',
            postId: 'post_1',
            authorId: 'u_123',
            content: 'Absolutely stunning! 😍',
            createdAt: DateTime.now().subtract(const Duration(hours: 1)),
          ),
        ],
      ),
      SocialPost(
        id: 'post_2',
        tripId: widget.tripId,
        authorId: 'u_456',
        content: 'Just had the most delicious seafood! 🦐 The local restaurant was incredible.',
        type: PostType.text,
        createdAt: DateTime.now().subtract(const Duration(hours: 4)),
        reactions: [
          Reaction(
            id: 'reaction_3',
            userId: 'u_leader',
            type: ReactionType.thumbsUp,
            createdAt: DateTime.now().subtract(const Duration(hours: 3)),
            targetId: 'post_2',
          ),
        ],
      ),
    ];
  }

  List<TripStory> _generateMockStories() {
    return [
      TripStory(
        id: 'story_1',
        tripId: widget.tripId,
        authorId: 'u_leader',
        title: 'Morning at the Beach',
        content: 'Started our day with a beautiful sunrise walk along the shore.',
        media: [
          StoryMedia(
            id: 'story_media_1',
            type: SocialMediaType.image,
            url: 'https://picsum.photos/400/600',
            caption: 'Sunrise walk',
          ),
        ],
        createdAt: DateTime.now().subtract(const Duration(hours: 6)),
        expiresAt: DateTime.now().add(const Duration(hours: 18)),
      ),
      TripStory(
        id: 'story_2',
        tripId: widget.tripId,
        authorId: 'u_123',
        title: 'Local Market Adventure',
        content: 'Exploring the vibrant local market and trying street food!',
        media: [
          StoryMedia(
            id: 'story_media_2',
            type: SocialMediaType.image,
            url: 'https://picsum.photos/400/600',
            caption: 'Market exploration',
          ),
        ],
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        expiresAt: DateTime.now().add(const Duration(hours: 21)),
      ),
    ];
  }

  List<ShareableContent> _generateMockHighlights() {
    return [
      ShareableContent(
        id: 'highlight_1',
        tripId: widget.tripId,
        type: ContentType.tripHighlight,
        title: 'Amazing Sunset at Goa Beach',
        description: 'Witnessed the most breathtaking sunset of our lives. The sky was painted in hues of orange, pink, and purple.',
        shareUrl: 'https://tripconnect.app/highlights/sunset',
        imageUrl: 'https://picsum.photos/800/600',
        platforms: [SocialPlatform.instagram, SocialPlatform.facebook],
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        createdBy: 'u_leader',
      ),
      ShareableContent(
        id: 'highlight_2',
        tripId: widget.tripId,
        type: ContentType.photoAlbum,
        title: 'Local Market Adventure',
        description: 'Explored the vibrant local market, tried amazing street food, and captured the essence of Goan culture.',
        shareUrl: 'https://tripconnect.app/highlights/market',
        imageUrl: 'https://picsum.photos/800/600',
        platforms: [SocialPlatform.instagram, SocialPlatform.whatsapp],
        createdAt: DateTime.now().subtract(const Duration(hours: 12)),
        createdBy: 'u_123',
      ),
      ShareableContent(
        id: 'highlight_3',
        tripId: widget.tripId,
        type: ContentType.video,
        title: 'Dolphin Watching Experience',
        description: 'Incredible boat ride where we spotted dolphins in their natural habitat. A truly magical experience!',
        shareUrl: 'https://tripconnect.app/highlights/dolphins',
        imageUrl: 'https://picsum.photos/800/600',
        platforms: [SocialPlatform.twitter, SocialPlatform.instagram],
        createdAt: DateTime.now().subtract(const Duration(hours: 6)),
        createdBy: 'u_456',
      ),
      ShareableContent(
        id: 'highlight_4',
        tripId: widget.tripId,
        type: ContentType.achievement,
        title: 'First Time Scuba Diving',
        description: 'Conquered our fears and experienced the underwater world for the first time. Unforgettable!',
        shareUrl: 'https://tripconnect.app/highlights/scuba',
        imageUrl: 'https://picsum.photos/800/600',
        platforms: [SocialPlatform.instagram, SocialPlatform.facebook],
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        createdBy: 'u_leader',
      ),
      ShareableContent(
        id: 'highlight_5',
        tripId: widget.tripId,
        type: ContentType.memory,
        title: 'Group Photo at Fort Aguada',
        description: 'Perfect group photo at the historic Fort Aguada with the Arabian Sea as our backdrop.',
        shareUrl: 'https://tripconnect.app/highlights/group-photo',
        imageUrl: 'https://picsum.photos/800/600',
        platforms: [SocialPlatform.whatsapp, SocialPlatform.telegram],
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        createdBy: 'u_789',
      ),
    ];
  }

  List<AppNotification> _generateMockNotifications() {
    return [
      AppNotification(
        id: 'notif_1',
        type: NotificationType.newPost,
        title: 'New Post from Aisha Sharma',
        body: 'Amazing sunset at the beach! 🌅 The colors were absolutely breathtaking...',
        data: {
          'postId': 'post_1',
          'tripId': widget.tripId,
          'authorId': 'u_leader',
        },
        createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
        isRead: false,
      ),
      AppNotification(
        id: 'notif_2',
        type: NotificationType.newComment,
        title: 'Rahul Kumar commented on Aisha Sharma\'s post',
        body: 'Absolutely stunning! 😍',
        data: {
          'commentId': 'comment_1',
          'postId': 'post_1',
          'authorId': 'u_123',
        },
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        isRead: false,
      ),
      AppNotification(
        id: 'notif_3',
        type: NotificationType.newReaction,
        title: 'Priya Singh reacted to Aisha Sharma\'s post',
        body: 'Priya Singh thought was fire',
        data: {
          'reactionId': 'reaction_2',
          'targetId': 'post_1',
          'targetType': 'post',
          'reactorId': 'u_456',
        },
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        isRead: true,
      ),
      AppNotification(
        id: 'notif_4',
        type: NotificationType.newStory,
        title: 'New Story from Aisha Sharma',
        body: 'Morning at the Beach',
        data: {
          'storyId': 'story_1',
          'tripId': widget.tripId,
          'authorId': 'u_leader',
        },
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        isRead: true,
      ),
      AppNotification(
        id: 'notif_5',
        type: NotificationType.tripUpdate,
        title: 'Trip Update: Goa Monsoon Adventure',
        body: 'Weather alert: Light rain expected in the afternoon',
        data: {
          'tripName': 'Goa Monsoon Adventure',
          'updateType': 'weather',
        },
        createdAt: DateTime.now().subtract(const Duration(hours: 4)),
        isRead: true,
      ),
    ];
  }

  List<UserProfile> _generateMockTripMembers() {
    return [
      UserProfile(
        id: 'u_leader',
        name: 'Aisha Sharma',
        email: 'aisha@example.com',
        bio: 'Trip leader and adventure enthusiast. Love exploring new places!',
        location: 'Mumbai, India',
        joinedAt: DateTime.now().subtract(const Duration(days: 365)),
        stats: UserStats(
          totalTrips: 15,
          completedTrips: 12,
          totalPosts: 67,
          totalStories: 34,
          totalLikes: 234,
          totalComments: 123,
          followersCount: 456,
          followingCount: 234,
          achievementsCount: 12,
          checkIns: 89,
          rollCallsAttended: 67,
          rollCallsLed: 23,
          averageRating: 4.8,
          totalReviews: 45,
        ),
        achievements: _generateMockAchievements('u_leader'),
        following: ['u_123', 'u_456', 'u_789'],
        followers: ['u_321', 'u_654', 'u_987'],
        preferences: const UserPreferences(),
        isVerified: true,
      ),
      UserProfile(
        id: 'u_123',
        name: 'Rahul Kumar',
        email: 'rahul@example.com',
        bio: 'Photography lover and travel blogger. Always ready for the next adventure!',
        location: 'Delhi, India',
        joinedAt: DateTime.now().subtract(const Duration(days: 280)),
        stats: UserStats(
          totalTrips: 8,
          completedTrips: 7,
          totalPosts: 45,
          totalStories: 23,
          totalLikes: 189,
          totalComments: 67,
          followersCount: 234,
          followingCount: 123,
          achievementsCount: 8,
          checkIns: 45,
          rollCallsAttended: 34,
          rollCallsLed: 5,
          averageRating: 4.6,
          totalReviews: 23,
        ),
        achievements: _generateMockAchievements('u_123'),
        following: ['u_leader', 'u_456'],
        followers: ['u_789', 'u_321'],
        preferences: const UserPreferences(),
        isVerified: false,
      ),
      UserProfile(
        id: 'u_456',
        name: 'Priya Singh',
        email: 'priya@example.com',
        bio: 'Foodie and culture explorer. Love trying local cuisines!',
        location: 'Bangalore, India',
        joinedAt: DateTime.now().subtract(const Duration(days: 200)),
        stats: UserStats(
          totalTrips: 6,
          completedTrips: 5,
          totalPosts: 34,
          totalStories: 18,
          totalLikes: 156,
          totalComments: 45,
          followersCount: 189,
          followingCount: 98,
          achievementsCount: 6,
          checkIns: 34,
          rollCallsAttended: 28,
          rollCallsLed: 2,
          averageRating: 4.5,
          totalReviews: 18,
        ),
        achievements: _generateMockAchievements('u_456'),
        following: ['u_leader', 'u_123'],
        followers: ['u_789', 'u_654'],
        preferences: const UserPreferences(),
        isVerified: false,
      ),
    ];
  }

  List<Achievement> _generateMockAchievements(String userId) {
    final achievements = [
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
    ];

    if (userId == 'u_leader') {
      achievements.addAll([
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
      ]);
    }

    return achievements;
  }

  void _showNotificationCenter() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => NotificationCenter(
          notifications: _notifications,
          onNotificationTap: _handleNotificationTap,
          onMarkAllRead: _markAllNotificationsRead,
          onClearAll: _clearAllNotifications,
        ),
      ),
    );
  }

  void _handleNotificationTap(String notificationId) {
    // Mark notification as read
    setState(() {
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
      }
    });

    // TODO: Navigate to relevant content based on notification type
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening notification: $notificationId'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _markAllNotificationsRead() {
    setState(() {
      for (int i = 0; i < _notifications.length; i++) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
      }
    });
  }

  void _clearAllNotifications() {
    setState(() {
      _notifications.clear();
    });
  }

  Widget _buildSectionHeader(ThemeData theme, String title, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          color: theme.colorScheme.primary,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _viewUserProfile(String userId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => UserProfileScreen(
          userId: userId,
          tripId: widget.tripId,
        ),
      ),
    );
  }

  void _followUser(String userId) {
    // TODO: Implement follow/unfollow functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Following user: $userId'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _messageUser(String userId) {
    final user = _tripMembers.firstWhere(
      (member) => member.id == userId,
      orElse: () => _tripMembers.first,
    );
    
    showDialog(
      context: context,
      builder: (context) => MessageDialog(
        recipientName: user.name,
        recipientId: user.id,
        tripId: widget.tripId,
      ),
    );
  }

  void _showCreatePostDialog() {
    showDialog(
      context: context,
      builder: (context) => CreatePostDialog(
        tripId: widget.tripId,
        authorId: 'u_leader', // TODO: Get from auth provider
        onPostCreated: (post) {
          setState(() {
            _posts.insert(0, post);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Post created successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        },
      ),
    );
  }

  void _showCreateStoryDialog() {
    showDialog(
      context: context,
      builder: (context) => CreateStoryDialog(
        tripId: widget.tripId,
        authorId: 'u_leader', // TODO: Get from auth provider
        onStoryCreated: (story) {
          setState(() {
            _stories.insert(0, story);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Story created successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        },
      ),
    );
  }

  void _viewStory(TripStory story) {
    // TODO: Implement story viewer
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Viewing story: ${story.title}'),
      ),
    );
  }

  void _shareStory(TripStory story) async {
    // TODO: Get actual trip data
    final mockTrip = Trip(
      id: widget.tripId,
      name: 'Goa Monsoon Adventure',
      theme: 'Beach',
      origin: const Location(name: 'Mumbai', lat: 19.076, lng: 72.8777),
      destination: const Location(name: 'Goa', lat: 15.2993, lng: 74.124),
      startDate: DateTime.now().subtract(const Duration(days: 2)),
      endDate: DateTime.now().add(const Duration(days: 3)),
      seatsTotal: 8,
      seatsAvailable: 2,
      leaderId: 'u_leader',
      invite: const TripInvite(code: 'GOA2024', qr: 'qr_code'),
    );

    final content = _sharingService.generateStoryContent(
      story: story,
      trip: mockTrip,
    );

    showDialog(
      context: context,
      builder: (context) => SocialSharingDialog(content: content),
    );
  }

  void _likePost(SocialPost post) {
    setState(() {
      // Create a new list with the existing reactions plus the new one
      final updatedReactions = List<Reaction>.from(post.reactions)
        ..add(
          Reaction(
            id: 'reaction_${DateTime.now().millisecondsSinceEpoch}',
            userId: 'u_leader', // Current user
            type: ReactionType.like,
            createdAt: DateTime.now(),
            targetId: post.id,
          ),
        );
      
      // Update the post with the new reactions list
      final postIndex = _posts.indexOf(post);
      if (postIndex != -1) {
        _posts[postIndex] = post.copyWith(reactions: updatedReactions);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Post liked! ❤️'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _commentOnPost(SocialPost post) {
    // TODO: Implement comment dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Comment feature coming soon!'),
      ),
    );
  }

  void _addCommentToPost(SocialPost post, Comment comment) {
    setState(() {
      final postIndex = _posts.indexOf(post);
      if (postIndex != -1) {
        final updatedComments = List<Comment>.from(post.comments)..add(comment);
        _posts[postIndex] = post.copyWith(comments: updatedComments);
      }
    });
  }

  void _sharePost(SocialPost post) async {
    // TODO: Get actual trip data
    final mockTrip = Trip(
      id: widget.tripId,
      name: 'Goa Monsoon Adventure',
      theme: 'Beach',
      origin: const Location(name: 'Mumbai', lat: 19.076, lng: 72.8777),
      destination: const Location(name: 'Goa', lat: 15.2993, lng: 74.124),
      startDate: DateTime.now().subtract(const Duration(days: 2)),
      endDate: DateTime.now().add(const Duration(days: 3)),
      seatsTotal: 8,
      seatsAvailable: 2,
      leaderId: 'u_leader',
      invite: const TripInvite(code: 'GOA2024', qr: 'qr_code'),
    );

    final content = _sharingService.generatePostContent(
      post: post,
      trip: mockTrip,
    );

    showDialog(
      context: context,
      builder: (context) => SocialSharingDialog(content: content),
    );
  }

  void _shareHighlight(ContentType type) async {
    // TODO: Get actual trip data
    final mockTrip = Trip(
      id: widget.tripId,
      name: 'Goa Monsoon Adventure',
      theme: 'Beach',
      origin: const Location(name: 'Mumbai', lat: 19.076, lng: 72.8777),
      destination: const Location(name: 'Goa', lat: 15.2993, lng: 74.124),
      startDate: DateTime.now().subtract(const Duration(days: 2)),
      endDate: DateTime.now().add(const Duration(days: 3)),
      seatsTotal: 8,
      seatsAvailable: 2,
      leaderId: 'u_leader',
      invite: const TripInvite(code: 'GOA2024', qr: 'qr_code'),
    );

    final content = _sharingService.generateTripContent(
      trip: mockTrip,
      type: type,
    );

    showDialog(
      context: context,
      builder: (context) => SocialSharingDialog(content: content),
    );
  }

  void _viewHighlight(ContentType type) {
    // Find the highlight for this type
    final highlight = _highlights.firstWhere(
      (h) => h.type == type,
      orElse: () => _highlights.first,
    );
    
    final highlightIndex = _highlights.indexOf(highlight);
    if (highlightIndex != -1) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => HighlightViewer(
            highlight: highlight,
            allHighlights: _highlights,
            initialIndex: highlightIndex,
          ),
        ),
      );
    }
  }
}
