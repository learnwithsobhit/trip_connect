import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/models/models.dart';
import '../../../core/data/providers/trip_provider.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_colors.dart';

class TripDocumentsScreen extends ConsumerStatefulWidget {
  final String tripId;

  const TripDocumentsScreen({super.key, required this.tripId});

  @override
  ConsumerState<TripDocumentsScreen> createState() => _TripDocumentsScreenState();
}

class _TripDocumentsScreenState extends ConsumerState<TripDocumentsScreen> {
  final _searchController = TextEditingController();
  String _selectedCategory = 'All';
  String _selectedSortBy = 'Date Added';
  bool _isSearching = false;

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

  // Mock documents data
  final List<TripDocument> _documents = [
    TripDocument(
      id: '1',
      name: 'Goa Trip Itinerary.pdf',
      type: 'PDF',
      category: 'Itinerary',
      size: '2.4 MB',
      dateAdded: DateTime.now().subtract(const Duration(days: 2)),
      uploadedBy: 'Aisha Sharma',
      isShared: true,
      downloadUrl: 'https://example.com/itinerary.pdf',
      thumbnail: '📄',
    ),
    TripDocument(
      id: '2',
      name: 'Hotel Booking Confirmation.pdf',
      type: 'PDF',
      category: 'Bookings',
      size: '1.8 MB',
      dateAdded: DateTime.now().subtract(const Duration(days: 3)),
      uploadedBy: 'Aisha Sharma',
      isShared: true,
      downloadUrl: 'https://example.com/hotel.pdf',
      thumbnail: '🏨',
    ),
    TripDocument(
      id: '3',
      name: 'Goa Beach Map.jpg',
      type: 'Image',
      category: 'Maps',
      size: '3.2 MB',
      dateAdded: DateTime.now().subtract(const Duration(days: 1)),
      uploadedBy: 'Rahul Kumar',
      isShared: true,
      downloadUrl: 'https://example.com/map.jpg',
      thumbnail: '🗺️',
    ),
    TripDocument(
      id: '4',
      name: 'Group Photo at Beach.jpg',
      type: 'Image',
      category: 'Photos',
      size: '4.1 MB',
      dateAdded: DateTime.now().subtract(const Duration(hours: 6)),
      uploadedBy: 'Priya Singh',
      isShared: true,
      downloadUrl: 'https://example.com/photo.jpg',
      thumbnail: '📸',
    ),
    TripDocument(
      id: '5',
      name: 'Sunset Video.mp4',
      type: 'Video',
      category: 'Videos',
      size: '15.7 MB',
      dateAdded: DateTime.now().subtract(const Duration(hours: 4)),
      uploadedBy: 'Vikram Patel',
      isShared: true,
      downloadUrl: 'https://example.com/video.mp4',
      thumbnail: '🎥',
    ),
    TripDocument(
      id: '6',
      name: 'Medical Form.pdf',
      type: 'PDF',
      category: 'Forms',
      size: '0.8 MB',
      dateAdded: DateTime.now().subtract(const Duration(days: 4)),
      uploadedBy: 'Aisha Sharma',
      isShared: false,
      downloadUrl: 'https://example.com/medical.pdf',
      thumbnail: '📋',
    ),
    TripDocument(
      id: '7',
      name: 'Restaurant Receipt.jpg',
      type: 'Image',
      category: 'Receipts',
      size: '1.2 MB',
      dateAdded: DateTime.now().subtract(const Duration(hours: 2)),
      uploadedBy: 'Neha Gupta',
      isShared: true,
      downloadUrl: 'https://example.com/receipt.jpg',
      thumbnail: '🧾',
    ),
    TripDocument(
      id: '8',
      name: 'Travel Insurance.pdf',
      type: 'PDF',
      category: 'Insurance',
      size: '5.6 MB',
      dateAdded: DateTime.now().subtract(const Duration(days: 5)),
      uploadedBy: 'Aisha Sharma',
      isShared: true,
      downloadUrl: 'https://example.com/insurance.pdf',
      thumbnail: '🛡️',
    ),
  ];

  List<TripDocument> get _filteredDocuments {
    List<TripDocument> filtered = _documents;

    // Filter by category
    if (_selectedCategory != 'All') {
      filtered = filtered.where((doc) => doc.category == _selectedCategory).toList();
    }

    // Filter by search
    if (_searchController.text.isNotEmpty) {
      filtered = filtered.where((doc) =>
          doc.name.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          doc.uploadedBy.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          doc.category.toLowerCase().contains(_searchController.text.toLowerCase())).toList();
    }

    // Sort documents
    switch (_selectedSortBy) {
      case 'Date Added':
        filtered.sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
        break;
      case 'Name':
        filtered.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'Size':
        filtered.sort((a, b) => _parseSize(b.size).compareTo(_parseSize(a.size)));
        break;
      case 'Type':
        filtered.sort((a, b) => a.type.compareTo(b.type));
        break;
    }

    return filtered;
  }

  double _parseSize(String size) {
    final number = double.tryParse(size.split(' ')[0]) ?? 0;
    final unit = size.split(' ')[1];
    switch (unit) {
      case 'KB':
        return number;
      case 'MB':
        return number * 1024;
      case 'GB':
        return number * 1024 * 1024;
      default:
        return number;
    }
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

    return tripAsync.when(
      data: (trip) => trip != null ? _buildDocumentsContent(context, theme, trip) : const Center(child: Text('Trip not found')),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red),
            AppSpacing.verticalSpaceMd,
            Text('Error loading documents: $error'),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentsContent(BuildContext context, ThemeData theme, Trip trip) {
    final filteredDocs = _filteredDocuments;
    final totalSize = _calculateTotalSize(filteredDocs);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Documents'),
        actions: [
          IconButton(
            onPressed: () => _showDocumentsOptions(context),
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          Container(
            padding: AppSpacing.paddingMd,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
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
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _isSearching = value.isNotEmpty;
                    });
                  },
                ),
                AppSpacing.verticalSpaceMd,
                
                // Filter Row
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          isDense: true,
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
                    AppSpacing.horizontalSpaceMd,
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedSortBy,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          isDense: true,
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

          // Documents Summary
          Container(
            padding: AppSpacing.paddingMd,
            child: Row(
              children: [
                Icon(Icons.folder, color: theme.colorScheme.primary),
                AppSpacing.horizontalSpaceSm,
                Text(
                  '${filteredDocs.length} documents',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  'Total: $totalSize',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          // Documents List
          Expanded(
            child: filteredDocs.isEmpty
                ? _buildEmptyState(theme)
                : ListView.builder(
                    padding: AppSpacing.paddingMd,
                    itemCount: filteredDocs.length,
                    itemBuilder: (context, index) {
                      final document = filteredDocs[index];
                      return _buildDocumentCard(theme, document);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showUploadDialog(context),
        icon: const Icon(Icons.upload),
        label: const Text('Upload'),
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
          AppSpacing.verticalSpaceMd,
          Text(
            _isSearching ? 'No documents found' : 'No documents yet',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          AppSpacing.verticalSpaceSm,
          Text(
            _isSearching ? 'Try adjusting your search' : 'Upload your first document to get started',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentCard(ThemeData theme, TripDocument document) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getDocumentTypeColor(document.type),
          child: Text(
            document.thumbnail,
            style: const TextStyle(fontSize: 20),
          ),
        ),
        title: Text(
          document.name,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            decoration: document.isShared ? null : TextDecoration.lineThrough,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${document.type} • ${document.size} • ${document.category}'),
            Text('Uploaded by ${document.uploadedBy} • ${_formatDate(document.dateAdded)}'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (document.isShared)
              Icon(
                Icons.share,
                size: 16,
                color: theme.colorScheme.primary,
              ),
            AppSpacing.horizontalSpaceSm,
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) => _handleDocumentAction(value, document),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'download',
                  child: Row(
                    children: [
                      Icon(Icons.download),
                      AppSpacing.horizontalSpaceSm,
                      Text('Download'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'share',
                  child: Row(
                    children: [
                      Icon(Icons.share),
                      AppSpacing.horizontalSpaceSm,
                      Text('Share'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'rename',
                  child: Row(
                    children: [
                      Icon(Icons.edit),
                      AppSpacing.horizontalSpaceSm,
                      Text('Rename'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      AppSpacing.horizontalSpaceSm,
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        onTap: () => _showDocumentDetails(context, document),
      ),
    );
  }

  Color _getDocumentTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'pdf':
        return Colors.red;
      case 'image':
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Colors.green;
      case 'video':
      case 'mp4':
      case 'mov':
        return Colors.purple;
      case 'document':
      case 'doc':
      case 'docx':
        return Colors.blue;
      default:
        return Colors.grey;
    }
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

  String _calculateTotalSize(List<TripDocument> documents) {
    double totalKB = 0;
    for (final doc in documents) {
      totalKB += _parseSize(doc.size);
    }

    if (totalKB > 1024 * 1024) {
      return '${(totalKB / (1024 * 1024)).toStringAsFixed(1)} GB';
    } else if (totalKB > 1024) {
      return '${(totalKB / 1024).toStringAsFixed(1)} MB';
    } else {
      return '${totalKB.toStringAsFixed(1)} KB';
    }
  }

  void _handleDocumentAction(String action, TripDocument document) {
    switch (action) {
      case 'download':
        _downloadDocument(document);
        break;
      case 'share':
        _shareDocument(document);
        break;
      case 'rename':
        _renameDocument(document);
        break;
      case 'delete':
        _deleteDocument(document);
        break;
    }
  }

  void _downloadDocument(TripDocument document) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Downloading ${document.name}...')),
    );
  }

  void _shareDocument(TripDocument document) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Sharing ${document.name}...')),
    );
  }

  void _renameDocument(TripDocument document) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Document'),
        content: TextField(
          controller: TextEditingController(text: document.name),
          decoration: const InputDecoration(
            labelText: 'New Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Document renamed')),
              );
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _deleteDocument(TripDocument document) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Document'),
        content: Text('Are you sure you want to delete "${document.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _documents.removeWhere((doc) => doc.id == document.id);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Document deleted')),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showDocumentDetails(BuildContext context, TripDocument document) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(document.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Type: ${document.type}'),
            Text('Category: ${document.category}'),
            Text('Size: ${document.size}'),
            Text('Uploaded by: ${document.uploadedBy}'),
            Text('Date: ${_formatDate(document.dateAdded)}'),
            Text('Shared: ${document.isShared ? 'Yes' : 'No'}'),
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
              _downloadDocument(document);
            },
            child: const Text('Download'),
          ),
        ],
      ),
    );
  }

  void _showUploadDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upload Document'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _uploadDocument('camera');
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _uploadDocument('gallery');
              },
            ),
            ListTile(
              leading: const Icon(Icons.folder),
              title: const Text('Choose File'),
              onTap: () {
                Navigator.pop(context);
                _uploadDocument('file');
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

  void _uploadDocument(String source) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Uploading document from $source...')),
    );
  }

  void _showDocumentsOptions(BuildContext context) {
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
                _downloadAllDocuments();
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share All'),
              onTap: () {
                Navigator.pop(context);
                _shareAllDocuments();
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Document Settings'),
              onTap: () {
                Navigator.pop(context);
                _showDocumentSettings(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _downloadAllDocuments() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Downloading all documents...')),
    );
  }

  void _shareAllDocuments() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sharing all documents...')),
    );
  }

  void _showDocumentSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Document Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text('Auto-sync'),
              subtitle: const Text('Automatically sync documents'),
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
              subtitle: const Text('Backup documents to cloud storage'),
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

class TripDocument {
  final String id;
  final String name;
  final String type;
  final String category;
  final String size;
  final DateTime dateAdded;
  final String uploadedBy;
  final bool isShared;
  final String downloadUrl;
  final String thumbnail;

  TripDocument({
    required this.id,
    required this.name,
    required this.type,
    required this.category,
    required this.size,
    required this.dateAdded,
    required this.uploadedBy,
    required this.isShared,
    required this.downloadUrl,
    required this.thumbnail,
  });
}
