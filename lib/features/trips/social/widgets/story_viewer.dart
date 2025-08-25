import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../../core/data/models/models.dart';
import '../../../../core/theme/app_colors.dart';

class StoryViewer extends ConsumerStatefulWidget {
  final List<TripStory> stories;
  final int initialIndex;

  const StoryViewer({
    super.key,
    required this.stories,
    required this.initialIndex,
  });

  @override
  ConsumerState<StoryViewer> createState() => _StoryViewerState();
}

class _StoryViewerState extends ConsumerState<StoryViewer>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _progressController;
  late AnimationController _fadeController;
  int _currentIndex = 0;
  bool _isPaused = false;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    _progressController = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _startProgress();
    _startControlsTimer();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _progressController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls,
        onTapDown: (_) => _pauseProgress(),
        onTapUp: (_) => _resumeProgress(),
        onTapCancel: () => _resumeProgress(),
        child: Stack(
          children: [
            // Story Content
            PageView.builder(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              itemCount: widget.stories.length,
              itemBuilder: (context, index) {
                final story = widget.stories[index];
                return _buildStoryContent(story);
              },
            ),
            // Top Controls
            if (_showControls) _buildTopControls(),
            // Bottom Controls
            if (_showControls) _buildBottomControls(),
            // Progress Bar
            _buildProgressBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryContent(TripStory story) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: Stack(
        children: [
          // Background Image/Video
          if (story.media.isNotEmpty) ...[
            Positioned.fill(
              child: _buildMediaContent(story.media.first),
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
                    Colors.black.withOpacity(0.3),
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withOpacity(0.5),
                  ],
                ),
              ),
            ),
          ),
          // Story Content
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(),
                  // Title
                  if (story.title.isNotEmpty)
                    Text(
                      story.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  const SizedBox(height: 8),
                  // Content
                  if (story.content.isNotEmpty)
                    Text(
                      story.content,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  const SizedBox(height: 16),
                  // Location
                  if (story.location != null)
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          story.location!.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaContent(StoryMedia media) {
    if (media.type == SocialMediaType.video) {
      // TODO: Implement video player
      return Container(
        color: Colors.grey.shade900,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.videocam,
                size: 64,
                color: Colors.white,
              ),
              SizedBox(height: 16),
              Text(
                'Video Player',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      // Image
      return Image.network(
        media.url,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey.shade900,
            child: const Center(
              child: Icon(
                Icons.image,
                size: 64,
                color: Colors.white,
              ),
            ),
          );
        },
      );
    }
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
            // Author Info
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary,
              child: Text(
                _getUserName(widget.stories[_currentIndex].authorId)
                    .substring(0, 1)
                    .toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getUserName(widget.stories[_currentIndex].authorId),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    timeago.format(widget.stories[_currentIndex].createdAt),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            // Close Button
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(
                Icons.close,
                color: Colors.white,
                size: 24,
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
              onPressed: _currentIndex > 0 ? _previousStory : null,
              icon: Icon(
                Icons.arrow_back_ios,
                color: _currentIndex > 0 ? Colors.white : Colors.white38,
                size: 24,
              ),
            ),
            const Spacer(),
            // Next Button
            IconButton(
              onPressed: _currentIndex < widget.stories.length - 1
                  ? _nextStory
                  : null,
              icon: Icon(
                Icons.arrow_forward_ios,
                color: _currentIndex < widget.stories.length - 1
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

  Widget _buildProgressBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.only(top: 60, left: 16, right: 16),
        child: Row(
          children: List.generate(widget.stories.length, (index) {
            return Expanded(
              child: Container(
                height: 2,
                margin: EdgeInsets.only(right: index < widget.stories.length - 1 ? 4 : 0),
                child: AnimatedBuilder(
                  animation: _progressController,
                  builder: (context, child) {
                    double progress = 0;
                    if (index == _currentIndex) {
                      progress = _progressController.value;
                    } else if (index < _currentIndex) {
                      progress = 1.0;
                    }
                    return LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.white24,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    );
                  },
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
    _restartProgress();
  }

  void _startProgress() {
    _progressController.forward();
    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _nextStory();
      }
    });
  }

  void _restartProgress() {
    _progressController.reset();
    _startProgress();
  }

  void _pauseProgress() {
    if (!_isPaused) {
      setState(() {
        _isPaused = true;
      });
      _progressController.stop();
    }
  }

  void _resumeProgress() {
    if (_isPaused) {
      setState(() {
        _isPaused = false;
      });
      _progressController.forward();
    }
  }

  void _nextStory() {
    if (_currentIndex < widget.stories.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  void _previousStory() {
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
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && !_isPaused) {
        setState(() {
          _showControls = false;
        });
      }
    });
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
