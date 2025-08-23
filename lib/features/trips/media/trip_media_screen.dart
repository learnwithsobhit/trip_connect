import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/models/models.dart';
import '../../../core/data/providers/trip_provider.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_colors.dart';

class TripMediaScreen extends ConsumerStatefulWidget {
  final String tripId;

  const TripMediaScreen({super.key, required this.tripId});

  @override
  ConsumerState<TripMediaScreen> createState() => _TripMediaScreenState();
}

class _TripMediaScreenState extends ConsumerState<TripMediaScreen> {
  String _selectedView = 'Grid';
  String _selectedFilter = 'All';

  final List<String> _viewOptions = ['Grid', 'List'];
  final List<String> _filterOptions = ['All', 'Photos', 'Videos', 'Favorites'];

  // Mock media data
  final List<TripMedia> _mediaItems = [
    TripMedia(
      id: '1',
      title: 'Beach Sunset',
      type: 'image',
      thumbnail: '🌅',
      uploadedBy: 'Aisha Sharma',
      dateUploaded: DateTime.now().subtract(const Duration(hours: 2)),
      likes: 12,
      isFavorite: true,
      location: 'Calangute Beach, Goa',
    ),
    TripMedia(
      id: '2',
      title: 'Group Photo at Fort',
      type: 'image',
      thumbnail: '🏰',
      uploadedBy: 'Rahul Kumar',
      dateUploaded: DateTime.now().subtract(const Duration(hours: 4)),
      likes: 18,
      isFavorite: false,
      location: 'Aguada Fort, Goa',
    ),
    TripMedia(
      id: '3',
      title: 'Seafood Feast',
      type: 'image',
      thumbnail: '🦐',
      uploadedBy: 'Priya Singh',
      dateUploaded: DateTime.now().subtract(const Duration(hours: 6)),
      likes: 25,
      isFavorite: true,
      location: 'Fisherman\'s Wharf, Panaji',
    ),
    TripMedia(
      id: '4',
      title: 'Beach Activities',
      type: 'video',
      thumbnail: '🏖️',
      uploadedBy: 'Vikram Patel',
      dateUploaded: DateTime.now().subtract(const Duration(hours: 8)),
      likes: 15,
      isFavorite: false,
      location: 'Baga Beach, Goa',
    ),
    TripMedia(
      id: '5',
      title: 'Church Architecture',
      type: 'image',
      thumbnail: '⛪',
      uploadedBy: 'Neha Gupta',
      dateUploaded: DateTime.now().subtract(const Duration(days: 1)),
      likes: 9,
      isFavorite: false,
      location: 'Basilica of Bom Jesus, Old Goa',
    ),
    TripMedia(
      id: '6',
      title: 'Monsoon Rain',
      type: 'video',
      thumbnail: '🌧️',
      uploadedBy: 'Aisha Sharma',
      dateUploaded: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
      likes: 7,
      isFavorite: true,
      location: 'Panaji, Goa',
    ),
  ];

  List<TripMedia> get _filteredMedia {
    List<TripMedia> filtered = _mediaItems;

    switch (_selectedFilter) {
      case 'Photos':
        filtered = filtered.where((media) => media.type == 'image').toList();
        break;
      case 'Videos':
        filtered = filtered.where((media) => media.type == 'video').toList();
        break;
      case 'Favorites':
        filtered = filtered.where((media) => media.isFavorite).toList();
        break;
    }

    filtered.sort((a, b) => b.dateUploaded.compareTo(a.dateUploaded));
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tripAsync = ref.watch(tripProvider(widget.tripId));

    return tripAsync.when(
      data: (trip) => trip != null ? _buildMediaContent(context, theme, trip) : const Center(child: Text('Trip not found')),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red),
            AppSpacing.verticalSpaceMd,
            Text('Error loading media: $error'),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaContent(BuildContext context, ThemeData theme, Trip trip) {
    final filteredMedia = _filteredMedia;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Media'),
        actions: [
          IconButton(
            onPressed: () => _showMediaOptions(context),
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Bar
          Container(
            padding: AppSpacing.paddingMd,
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedFilter,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      isDense: true,
                    ),
                    items: _filterOptions.map((filter) => DropdownMenuItem(
                      value: filter,
                      child: Text(filter),
                    )).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedFilter = value!;
                      });
                    },
                  ),
                ),
                AppSpacing.horizontalSpaceMd,
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedView,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      isDense: true,
                    ),
                    items: _viewOptions.map((view) => DropdownMenuItem(
                      value: view,
                      child: Text(view),
                    )).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedView = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),

          // Media Summary
          Container(
            padding: AppSpacing.paddingMd,
            child: Row(
              children: [
                Icon(Icons.photo_library, color: theme.colorScheme.primary),
                AppSpacing.horizontalSpaceSm,
                Text(
                  '${filteredMedia.length} items',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${filteredMedia.where((m) => m.isFavorite).length} favorites',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          // Media Grid/List
          Expanded(
            child: filteredMedia.isEmpty
                ? _buildEmptyState(theme)
                : _selectedView == 'Grid'
                    ? _buildGridView(theme, filteredMedia)
                    : _buildListView(theme, filteredMedia),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddMediaDialog(context),
        icon: const Icon(Icons.add_a_photo),
        label: const Text('Add Media'),
      ),
    );
  }

  Widget _buildGridView(ThemeData theme, List<TripMedia> mediaItems) {
    return GridView.builder(
      padding: AppSpacing.paddingMd,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: mediaItems.length,
      itemBuilder: (context, index) {
        final media = mediaItems[index];
        return _buildGridItem(theme, media);
      },
    );
  }

  Widget _buildListView(ThemeData theme, List<TripMedia> mediaItems) {
    return ListView.builder(
      padding: AppSpacing.paddingMd,
      itemCount: mediaItems.length,
      itemBuilder: (context, index) {
        final media = mediaItems[index];
        return _buildListItem(theme, media);
      },
    );
  }

  Widget _buildGridItem(ThemeData theme, TripMedia media) {
    return GestureDetector(
      onTap: () => _showMediaDetails(context, media),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  media.thumbnail,
                  style: const TextStyle(fontSize: 32),
                ),
              ),
            ),
            
            if (media.type == 'video')
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            
            if (media.isFavorite)
              Positioned(
                bottom: 4,
                left: 4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.favorite,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildListItem(ThemeData theme, TripMedia media) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Text(
            media.thumbnail,
            style: const TextStyle(fontSize: 20),
          ),
        ),
        title: Text(media.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${media.type.toUpperCase()} • ${media.likes} likes'),
            Text('${media.uploadedBy} • ${_formatDate(media.dateUploaded)}'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                media.isFavorite ? Icons.favorite : Icons.favorite_border,
                color: media.isFavorite ? Colors.red : null,
              ),
              onPressed: () => _toggleFavorite(media),
            ),
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () => _shareMedia(media),
            ),
          ],
        ),
        onTap: () => _showMediaDetails(context, media),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          AppSpacing.verticalSpaceMd,
          Text(
            'No media yet',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          AppSpacing.verticalSpaceSm,
          Text(
            'Add your first photo or video to get started',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  void _toggleFavorite(TripMedia media) {
    setState(() {
      media.isFavorite = !media.isFavorite;
      if (media.isFavorite) {
        media.likes++;
      } else {
        media.likes--;
      }
    });
  }

  void _shareMedia(TripMedia media) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Sharing ${media.title}...')),
    );
  }

  void _showMediaDetails(BuildContext context, TripMedia media) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(media.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    media.thumbnail,
                    style: const TextStyle(fontSize: 64),
                  ),
                ),
              ),
            ),
            AppSpacing.verticalSpaceMd,
            Text('Type: ${media.type.toUpperCase()}'),
            Text('Location: ${media.location}'),
            Text('Uploaded by: ${media.uploadedBy}'),
            Text('Date: ${_formatDate(media.dateUploaded)}'),
            Text('Likes: ${media.likes}'),
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
              _shareMedia(media);
            },
            child: const Text('Share'),
          ),
        ],
      ),
    );
  }

  void _showAddMediaDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Media'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _addMedia('camera');
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _addMedia('gallery');
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam),
              title: const Text('Record Video'),
              onTap: () {
                Navigator.pop(context);
                _addMedia('video');
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _addMedia(String source) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Adding media from $source...')),
    );
  }

  void _showMediaOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: AppSpacing.paddingMd,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Download All'),
              onTap: () {
                Navigator.pop(context);
                _downloadAllMedia();
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share All'),
              onTap: () {
                Navigator.pop(context);
                _shareAllMedia();
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Media Settings'),
              onTap: () {
                Navigator.pop(context);
                _showMediaSettings(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _downloadAllMedia() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Downloading all media...')),
    );
  }

  void _shareAllMedia() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sharing all media...')),
    );
  }

  void _showMediaSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Media Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text('Auto-upload'),
              subtitle: const Text('Automatically upload new media'),
              value: true,
              onChanged: (value) {},
            ),
            SwitchListTile(
              title: const Text('Compress Images'),
              subtitle: const Text('Reduce image file sizes'),
              value: false,
              onChanged: (value) {},
            ),
            SwitchListTile(
              title: const Text('Backup to Cloud'),
              subtitle: const Text('Backup media to cloud storage'),
              value: true,
              onChanged: (value) {},
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class TripMedia {
  final String id;
  final String title;
  final String type;
  final String thumbnail;
  final String uploadedBy;
  final DateTime dateUploaded;
  int likes;
  bool isFavorite;
  final String location;

  TripMedia({
    required this.id,
    required this.title,
    required this.type,
    required this.thumbnail,
    required this.uploadedBy,
    required this.dateUploaded,
    required this.likes,
    required this.isFavorite,
    required this.location,
  });
}


