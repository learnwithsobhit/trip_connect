import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../../../core/data/models/models.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

class CreateStoryDialog extends ConsumerStatefulWidget {
  final String tripId;
  final String authorId;
  final Function(TripStory) onStoryCreated;

  const CreateStoryDialog({
    super.key,
    required this.tripId,
    required this.authorId,
    required this.onStoryCreated,
  });

  @override
  ConsumerState<CreateStoryDialog> createState() => _CreateStoryDialogState();
}

class _CreateStoryDialogState extends ConsumerState<CreateStoryDialog> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final List<File> _selectedMedia = [];
  StoryVisibility _visibility = StoryVisibility.tripMembers;
  Location? _location;
  bool _isLoading = false;
  int _currentMediaIndex = 0;

  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMediaPreview(),
                    const SizedBox(height: 16),
                    _buildMediaControls(),
                    const SizedBox(height: 16),
                    _buildCaptionInput(),
                    const SizedBox(height: 16),
                    _buildLocationSection(),
                    const SizedBox(height: 16),
                    _buildPrivacySection(),
                  ],
                ),
              ),
            ),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: Colors.white),
          ),
          const Expanded(
            child: Text(
              'Create Story',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 48), // Balance the close button
        ],
      ),
    );
  }

  Widget _buildMediaPreview() {
    if (_selectedMedia.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_photo_alternate, size: 48, color: Colors.grey),
              SizedBox(height: 8),
              Text(
                'Add photos or videos',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Stack(
        children: [
          PageView.builder(
            itemCount: _selectedMedia.length,
            onPageChanged: (index) {
              setState(() {
                _currentMediaIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  _selectedMedia[index],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              );
            },
          ),
          if (_selectedMedia.length > 1)
            Positioned(
              bottom: 8,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_selectedMedia.length, (index) {
                  return Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index == _currentMediaIndex
                          ? AppColors.primary
                          : Colors.white.withOpacity(0.5),
                    ),
                  );
                }),
              ),
            ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () => _removeCurrentMedia(),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Media',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              '${_selectedMedia.length}/10',
              style: TextStyle(
                color: _selectedMedia.length >= 10 ? Colors.red : Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _selectedMedia.length < 10 ? _pickImage : null,
                icon: const Icon(Icons.photo_library),
                label: const Text('Photo'),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _selectedMedia.length < 10 ? _pickVideo : null,
                icon: const Icon(Icons.videocam),
                label: const Text('Video'),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _selectedMedia.length < 10 ? _takePhoto : null,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Camera'),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCaptionInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Title',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _titleController,
          maxLines: 1,
          maxLength: 100,
          decoration: InputDecoration(
            hintText: 'Story title...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Content',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _contentController,
          maxLines: 3,
          maxLength: 500,
          decoration: InputDecoration(
            hintText: 'Story content...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }



  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Location',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _addLocation,
                icon: const Icon(Icons.location_on),
                label: Text(_location?.name ?? 'Add location'),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            if (_location != null) ...[
              const SizedBox(width: 8),
              IconButton(
                onPressed: _removeLocation,
                icon: const Icon(Icons.clear),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildPrivacySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Privacy',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<StoryVisibility>(
          value: _visibility,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          items: StoryVisibility.values.map((visibility) {
            return DropdownMenuItem(
              value: visibility,
              child: Row(
                children: [
                  Icon(_getVisibilityIcon(visibility)),
                  const SizedBox(width: 8),
                  Text(_getVisibilityText(visibility)),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _visibility = value;
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: _isLoading || _selectedMedia.isEmpty ? null : _createStory,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Share Story'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _selectedMedia.add(File(image.path));
        });
      }
    } catch (e) {
      _showError('Failed to pick image: $e');
    }
  }

  Future<void> _pickVideo() async {
    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(seconds: 30),
      );
      if (video != null) {
        setState(() {
          _selectedMedia.add(File(video.path));
        });
      }
    } catch (e) {
      _showError('Failed to pick video: $e');
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _selectedMedia.add(File(image.path));
        });
      }
    } catch (e) {
      _showError('Failed to take photo: $e');
    }
  }

  void _removeCurrentMedia() {
    if (_selectedMedia.isNotEmpty) {
      setState(() {
        _selectedMedia.removeAt(_currentMediaIndex);
        if (_currentMediaIndex >= _selectedMedia.length && _selectedMedia.isNotEmpty) {
          _currentMediaIndex = _selectedMedia.length - 1;
        }
      });
    }
  }



  void _addLocation() {
    // TODO: Implement location picker
    // For now, add a mock location
    setState(() {
      _location = Location(
        name: 'Goa Beach',
        lat: 15.2993,
        lng: 74.124,
        address: 'Goa, India',
      );
    });
  }

  void _removeLocation() {
    setState(() {
      _location = null;
    });
  }

  Future<void> _createStory() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Convert selected media to StoryMedia objects
      final mediaItems = _selectedMedia.asMap().entries.map((entry) {
        final index = entry.key;
        final file = entry.value;
        return StoryMedia(
          id: 'story_media_${DateTime.now().millisecondsSinceEpoch}_$index',
          type: file.path.toLowerCase().contains('.mp4') || 
                file.path.toLowerCase().contains('.mov') ||
                file.path.toLowerCase().contains('.avi')
              ? SocialMediaType.video
              : SocialMediaType.image,
          url: file.path, // In real app, this would be uploaded URL
          caption: _contentController.text.trim(),
          metadata: {
            'fileName': file.path.split('/').last,
            'fileSize': file.lengthSync(),
          },
        );
      }).toList();

      final story = TripStory(
        id: 'story_${DateTime.now().millisecondsSinceEpoch}',
        tripId: widget.tripId,
        authorId: widget.authorId,
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        media: mediaItems,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(hours: 24)),
        visibility: _visibility,
        location: _location,
      );

      widget.onStoryCreated(story);
      Navigator.of(context).pop();
    } catch (e) {
      _showError('Failed to create story: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  IconData _getVisibilityIcon(StoryVisibility visibility) {
    switch (visibility) {
      case StoryVisibility.public:
        return Icons.public;
      case StoryVisibility.tripMembers:
        return Icons.group;
      case StoryVisibility.friends:
        return Icons.people;
      case StoryVisibility.private:
        return Icons.lock;
    }
  }

  String _getVisibilityText(StoryVisibility visibility) {
    switch (visibility) {
      case StoryVisibility.public:
        return 'Public';
      case StoryVisibility.tripMembers:
        return 'Trip Members';
      case StoryVisibility.friends:
        return 'Friends';
      case StoryVisibility.private:
        return 'Private';
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}


