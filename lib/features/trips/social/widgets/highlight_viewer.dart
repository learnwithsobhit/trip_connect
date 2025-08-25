import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../../core/data/models/models.dart';
import '../../../../core/theme/app_colors.dart';

class HighlightViewer extends ConsumerStatefulWidget {
  final ShareableContent highlight;
  final List<ShareableContent> allHighlights;
  final int initialIndex;

  const HighlightViewer({
    super.key,
    required this.highlight,
    required this.allHighlights,
    required this.initialIndex,
  });

  @override
  ConsumerState<HighlightViewer> createState() => _HighlightViewerState();
}

class _HighlightViewerState extends ConsumerState<HighlightViewer>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  int _currentIndex = 0;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeController.forward();
    _startControlsTimer();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          children: [
            // Highlight Content
            PageView.builder(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              itemCount: widget.allHighlights.length,
              itemBuilder: (context, index) {
                final highlight = widget.allHighlights[index];
                return _buildHighlightContent(highlight);
              },
            ),
            // Top Controls
            if (_showControls) _buildTopControls(),
            // Bottom Controls
            if (_showControls) _buildBottomControls(),
            // Share Button
            if (_showControls) _buildShareButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHighlightContent(ShareableContent highlight) {
    return FadeTransition(
      opacity: _fadeController,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          children: [
            // Background Image
            if (highlight.imageUrl != null) ...[
              Positioned.fill(
                child: Image.network(
                  highlight.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildFallbackBackground(highlight);
                  },
                ),
              ),
            ] else ...[
              Positioned.fill(
                child: _buildFallbackBackground(highlight),
              ),
            ],
            // Gradient Overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.4),
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
              ),
            ),
            // Highlight Content
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Spacer(),
                    // Highlight Type Badge
                    _buildTypeBadge(highlight.type),
                    const SizedBox(height: 16),
                    // Title
                    Text(
                      highlight.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            offset: Offset(0, 2),
                            blurRadius: 4,
                            color: Colors.black54,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Description
                    Text(
                      highlight.description,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        shadows: [
                          Shadow(
                            offset: Offset(0, 1),
                            blurRadius: 2,
                            color: Colors.black54,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Metadata
                    _buildMetadata(highlight),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackBackground(ShareableContent highlight) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primary.withOpacity(0.7),
            Colors.purple.shade600,
          ],
        ),
      ),
      child: Center(
        child: Icon(
          _getHighlightIcon(highlight.type),
          size: 80,
          color: Colors.white.withOpacity(0.8),
        ),
      ),
    );
  }

  Widget _buildTypeBadge(ContentType type) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getHighlightIcon(type),
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            type.displayName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadata(ShareableContent highlight) {
    return Row(
      children: [
        if (highlight.createdBy != null) ...[
          CircleAvatar(
            radius: 12,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: Text(
              _getUserName(highlight.createdBy!).substring(0, 1).toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _getUserName(highlight.createdBy!),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 16),
        ],
        Icon(
          Icons.access_time,
          color: Colors.white70,
          size: 14,
        ),
        const SizedBox(width: 4),
        Text(
          timeago.format(highlight.createdAt),
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildTopControls() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.only(
          top: 60,
          left: 16,
          right: 16,
          bottom: 16,
        ),
        child: Row(
          children: [
            // Back Button
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 24,
              ),
            ),
            const Spacer(),
            // Highlight Counter
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_currentIndex + 1} / ${widget.allHighlights.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            // Previous Button
            IconButton(
              onPressed: _currentIndex > 0 ? _previousHighlight : null,
              icon: Icon(
                Icons.arrow_back_ios,
                color: _currentIndex > 0 ? Colors.white : Colors.white38,
                size: 24,
              ),
            ),
            const Spacer(),
            // Next Button
            IconButton(
              onPressed: _currentIndex < widget.allHighlights.length - 1
                  ? _nextHighlight
                  : null,
              icon: Icon(
                Icons.arrow_forward_ios,
                color: _currentIndex < widget.allHighlights.length - 1
                    ? Colors.white
                    : Colors.white38,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShareButton() {
    return Positioned(
      top: 120,
      right: 16,
      child: ScaleTransition(
        scale: _scaleController,
        child: FloatingActionButton(
          onPressed: _shareHighlight,
          backgroundColor: Colors.white.withOpacity(0.2),
          foregroundColor: Colors.white,
          child: const Icon(Icons.share),
        ),
      ),
    );
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
    _fadeController.reset();
    _fadeController.forward();
  }

  void _nextHighlight() {
    if (_currentIndex < widget.allHighlights.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousHighlight() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) {
      _startControlsTimer();
    }
  }

  void _startControlsTimer() {
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _shareHighlight() {
    // TODO: Implement sharing functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sharing ${widget.allHighlights[_currentIndex].title}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  IconData _getHighlightIcon(ContentType type) {
    switch (type) {
      case ContentType.tripHighlight:
        return Icons.star;
      case ContentType.photoAlbum:
        return Icons.photo_library;
      case ContentType.video:
        return Icons.videocam;
      case ContentType.story:
        return Icons.auto_stories;
      case ContentType.achievement:
        return Icons.emoji_events;
      case ContentType.memory:
        return Icons.favorite;
    }
  }

  String _getUserName(String userId) {
    // Mock user names - in real app, get from user service
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
}
