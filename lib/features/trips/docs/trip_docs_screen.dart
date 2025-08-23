import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/models/models.dart';
import '../../../core/data/providers/trip_provider.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_colors.dart';

class TripDocsScreen extends ConsumerStatefulWidget {
  final String tripId;

  const TripDocsScreen({super.key, required this.tripId});

  @override
  ConsumerState<TripDocsScreen> createState() => _TripDocsScreenState();
}

class _TripDocsScreenState extends ConsumerState<TripDocsScreen> {
  final _searchController = TextEditingController();
  String _selectedCategory = 'All';
  String _selectedSortBy = 'Date Added';

  final List<String> _categories = [
    'All',
    'Itinerary',
    'Bookings',
    'Maps',
    'Photos',
    'Videos',
    'Forms',
    'Receipts',
    'Insurance',
    'Other',
  ];

  final List<String> _sortOptions = [
    'Date Added',
    'Name',
    'Size',
    'Type',
  ];

  // Mock documents data using the correct Document model
  late final List<Document> _documents;

  @override
  void initState() {
    super.initState();
    _documents = [
      Document(
        id: '1',
        tripId: widget.tripId,
        uploaderId: 'u_leader',
        name: 'Goa Trip Itinerary.pdf',
        uri: 'https://example.com/itinerary.pdf',
        tags: ['Itinerary', 'PDF'],
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        description: 'Complete trip itinerary with day-wise plans',
        metadata: DocumentMetadata(
          fileSize: 2516582, // 2.4 MB in bytes
          mimeType: 'application/pdf',
          originalName: 'Goa Trip Itinerary.pdf',
        ),
      ),
      Document(
        id: '2',
        tripId: widget.tripId,
        uploaderId: 'u_leader',
        name: 'Hotel Booking Confirmation.pdf',
        uri: 'https://example.com/hotel.pdf',
        tags: ['Bookings', 'PDF'],
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        description: 'Hotel booking confirmation details',
        metadata: DocumentMetadata(
          fileSize: 1887437, // 1.8 MB in bytes
          mimeType: 'application/pdf',
          originalName: 'Hotel Booking Confirmation.pdf',
        ),
      ),
      Document(
        id: '3',
        tripId: widget.tripId,
        uploaderId: 'u_123',
        name: 'Goa Beach Map.jpg',
        uri: 'https://example.com/map.jpg',
        tags: ['Maps', 'Image'],
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        description: 'Map of Goa beaches',
        metadata: DocumentMetadata(
          fileSize: 3355443, // 3.2 MB in bytes
          mimeType: 'image/jpeg',
          originalName: 'Goa Beach Map.jpg',
        ),
      ),
      Document(
        id: '4',
        tripId: widget.tripId,
        uploaderId: 'u_456',
        name: 'Group Photo at Beach.jpg',
        uri: 'https://example.com/photo.jpg',
        tags: ['Photos', 'Image'],
        createdAt: DateTime.now().subtract(const Duration(hours: 6)),
        description: 'Group photo at the beach',
        metadata: DocumentMetadata(
          fileSize: 4299161, // 4.1 MB in bytes
          mimeType: 'image/jpeg',
          originalName: 'Group Photo at Beach.jpg',
        ),
      ),
      Document(
        id: '5',
        tripId: widget.tripId,
        uploaderId: 'u_789',
        name: 'Sunset Video.mp4',
        uri: 'https://example.com/video.mp4',
        tags: ['Videos', 'Video'],
        createdAt: DateTime.now().subtract(const Duration(hours: 12)),
        description: 'Beautiful sunset video',
        metadata: DocumentMetadata(
          fileSize: 16462643, // 15.7 MB in bytes
          mimeType: 'video/mp4',
          originalName: 'Sunset Video.mp4',
        ),
      ),
      Document(
        id: '6',
        tripId: widget.tripId,
        uploaderId: 'u_leader',
        name: 'Emergency Contact List.pdf',
        uri: 'https://example.com/contacts.pdf',
        tags: ['Forms', 'PDF'],
        createdAt: DateTime.now().subtract(const Duration(days: 4)),
        description: 'Emergency contact information',
        metadata: DocumentMetadata(
          fileSize: 838860, // 0.8 MB in bytes
          mimeType: 'application/pdf',
          originalName: 'Emergency Contact List.pdf',
        ),
      ),
    ];
  }

  List<Document> get _filteredDocuments {
    List<Document> filtered = _documents;

    // Filter by category
    if (_selectedCategory != 'All') {
      filtered = filtered.where((doc) => doc.tags.contains(_selectedCategory)).toList();
    }

    // Filter by search
    if (_searchController.text.isNotEmpty) {
      filtered = filtered.where((doc) =>
          doc.name.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          doc.description?.toLowerCase().contains(_searchController.text.toLowerCase()) == true).toList();
    }

    // Sort documents
    switch (_selectedSortBy) {
      case 'Date Added':
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'Name':
        filtered.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'Size':
        filtered.sort((a, b) => (b.metadata?.fileSize ?? 0).compareTo(a.metadata?.fileSize ?? 0));
        break;
      case 'Type':
        filtered.sort((a, b) => (a.metadata?.mimeType ?? '').compareTo(b.metadata?.mimeType ?? ''));
        break;
    }

    return filtered;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tripAsync = ref.watch(tripProvider(widget.tripId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Documents'),
        leading: IconButton(
          onPressed: () => context.go('/trips/${widget.tripId}'),
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [
          IconButton(
            onPressed: () => _showUploadDialog(context),
            icon: const Icon(Icons.upload),
            tooltip: 'Upload Document',
          ),
        ],
      ),
      body: tripAsync.when(
        data: (trip) => trip != null ? _buildDocumentsContent(theme) : const Center(child: Text('Trip not found')),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'docs-upload',
        onPressed: () => _showUploadDialog(context),
        child: const Icon(Icons.add),
        tooltip: 'Upload Document',
      ),
    );
  }

  Widget _buildDocumentsContent(ThemeData theme) {
    return Column(
      children: [
        // Search and Filter Bar
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color: theme.colorScheme.outline.withOpacity(0.2),
              ),
            ),
          ),
          child: Column(
            children: [
              // Search Bar
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search documents...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                          icon: const Icon(Icons.clear),
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (value) => setState(() {}),
              ),
              
              const SizedBox(height: AppSpacing.md),
              
              // Filter and Sort Row
              Row(
                children: [
                  // Category Filter
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      items: _categories.map((category) => DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      )).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value!;
                        });
                      },
                    ),
                  ),
                  
                  const SizedBox(width: AppSpacing.sm),
                  
                  // Sort Options
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedSortBy,
                      decoration: const InputDecoration(
                        labelText: 'Sort By',
                        border: OutlineInputBorder(),
                      ),
                      items: _sortOptions.map((option) => DropdownMenuItem(
                        value: option,
                        child: Text(option),
                      )).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedSortBy = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Documents List
        Expanded(
          child: _filteredDocuments.isEmpty
              ? _buildEmptyState(theme)
              : ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: _filteredDocuments.length,
                  itemBuilder: (context, index) {
                    final document = _filteredDocuments[index];
                    return _buildDocumentCard(theme, document);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildDocumentCard(ThemeData theme, Document document) {
    final fileType = _getFileType(document.metadata?.mimeType ?? '');
    final fileSize = _formatFileSize(document.metadata?.fileSize ?? 0);
    final category = document.tags.isNotEmpty ? document.tags.first : 'Other';
    
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: _getDocumentColor(fileType),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              _getDocumentIcon(fileType),
              style: const TextStyle(fontSize: 24),
            ),
          ),
        ),
        title: Text(
          document.name,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$fileType • $fileSize • $category',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              'Uploaded by ${_getUploaderName(document.uploaderId)} • ${_formatDate(document.createdAt)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleDocumentAction(value, document),
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'download', child: Text('Download')),
            const PopupMenuItem(value: 'share', child: Text('Share')),
            const PopupMenuItem(value: 'rename', child: Text('Rename')),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
        onTap: () => _showDocumentDetails(context, document),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No Documents Yet',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Upload documents to share with your trip members',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton.icon(
            onPressed: () => _showUploadDialog(context),
            icon: const Icon(Icons.upload),
            label: const Text('Upload First Document'),
          ),
        ],
      ),
    );
  }

  String _getFileType(String mimeType) {
    if (mimeType.contains('pdf')) return 'PDF';
    if (mimeType.contains('image')) return 'Image';
    if (mimeType.contains('video')) return 'Video';
    if (mimeType.contains('audio')) return 'Audio';
    return 'Document';
  }

  String _getDocumentIcon(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'pdf':
        return '📄';
      case 'image':
        return '🖼️';
      case 'video':
        return '🎥';
      case 'audio':
        return '🎵';
      default:
        return '📄';
    }
  }

  Color _getDocumentColor(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'pdf':
        return Colors.red.shade100;
      case 'image':
        return Colors.blue.shade100;
      case 'video':
        return Colors.purple.shade100;
      case 'audio':
        return Colors.orange.shade100;
      default:
        return Colors.grey.shade100;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String _getUploaderName(String uploaderId) {
    switch (uploaderId) {
      case 'u_leader':
        return 'Aisha Sharma';
      case 'u_123':
        return 'Rahul Kumar';
      case 'u_456':
        return 'Priya Singh';
      case 'u_789':
        return 'Vikram Patel';
      default:
        return 'Unknown User';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else {
      return 'Just now';
    }
  }

  void _showUploadDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upload Document'),
        content: const Text('Document upload functionality coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showDocumentDetails(BuildContext context, Document document) {
    final fileType = _getFileType(document.metadata?.mimeType ?? '');
    final fileSize = _formatFileSize(document.metadata?.fileSize ?? 0);
    final category = document.tags.isNotEmpty ? document.tags.first : 'Other';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(document.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Type: $fileType'),
            Text('Size: $fileSize'),
            Text('Category: $category'),
            Text('Uploaded by: ${_getUploaderName(document.uploaderId)}'),
            Text('Date: ${_formatDate(document.createdAt)}'),
            if (document.description != null) Text('Description: ${document.description}'),
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
              _handleDocumentAction('download', document);
            },
            child: const Text('Download'),
          ),
        ],
      ),
    );
  }

  void _handleDocumentAction(String action, Document document) {
    switch (action) {
      case 'download':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Downloading ${document.name}...')),
        );
        break;
      case 'share':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sharing ${document.name}...')),
        );
        break;
      case 'rename':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rename functionality coming soon!')),
        );
        break;
      case 'delete':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Deleting ${document.name}...')),
        );
        break;
    }
  }
}


