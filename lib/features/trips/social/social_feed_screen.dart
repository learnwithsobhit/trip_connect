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
        );
      },
    );
  }

  Widget _buildHighlightsTab(ThemeData theme) {
    return ListView(
      padding: AppSpacing.paddingMd,
      children: [
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

  void _showCreatePostDialog() {
    // TODO: Implement create post dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Create post feature coming soon!'),
      ),
    );
  }

  void _showCreateStoryDialog() {
    // TODO: Implement create story dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Create story feature coming soon!'),
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
    // TODO: Implement highlight viewer
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Viewing ${type.displayName}'),
      ),
    );
  }
}
