import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/providers/trip_provider.dart';
import '../../../core/data/providers/auth_provider.dart';
import '../../../core/data/models/models.dart';
import '../../../core/theme/app_spacing.dart';
import '../chat/poll_widget.dart';

class TripChatScreen extends ConsumerStatefulWidget {
  final String tripId;

  const TripChatScreen({super.key, required this.tripId});

  @override
  ConsumerState<TripChatScreen> createState() => _TripChatScreenState();
}

class _TripChatScreenState extends ConsumerState<TripChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isRecording = false;
  bool _hasText = false;
  ChatPoll? _activePoll;

  @override
  void initState() {
    super.initState();
    _messageController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _messageController.removeListener(_onTextChanged);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {
      _hasText = _messageController.text.trim().isNotEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tripAsync = ref.watch(tripProvider(widget.tripId));
    final messagesAsync = ref.watch(tripMessagesStreamProvider(widget.tripId));
    final currentUser = ref.watch(currentUserProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Trip Chat'),
            tripAsync.whenOrNull(
              data: (trip) => Text(
                trip?.name ?? '',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ) ?? const SizedBox.shrink(),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/trips/${widget.tripId}'),
        ),
        actions: [
          // Audio call button
          IconButton(
            icon: const Icon(Icons.call),
            onPressed: () => _initiateAudioCall(),
            tooltip: 'Audio Call',
          ),
          // Video call button
          IconButton(
            icon: const Icon(Icons.videocam),
            onPressed: () => _initiateVideoCall(),
            tooltip: 'Video Call',
          ),
          // Poll button
          IconButton(
            icon: const Icon(Icons.poll),
            onPressed: () => _createQuickPoll(),
            tooltip: 'Create Poll',
          ),
          // Chat options
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) => _handleMenuAction(value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'notifications',
                child: ListTile(
                  leading: Icon(Icons.notifications),
                  title: Text('Notifications'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'members',
                child: ListTile(
                  leading: Icon(Icons.people),
                  title: Text('Trip Members'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'media',
                child: ListTile(
                  leading: Icon(Icons.photo_library),
                  title: Text('Shared Media'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'clear',
                child: ListTile(
                  leading: Icon(Icons.clear_all),
                  title: Text('Clear Chat'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                return Column(
                  children: [
                    // Active poll display
                    if (_activePoll != null)
                      PollWidget(
                        poll: _activePoll!,
                        currentUserId: currentUser?.id ?? '',
                        onVote: () {
                          // Handle vote - in real app would update poll state
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Vote recorded! 🗳️'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                        onClose: () {
                          setState(() => _activePoll = null);
                        },
                      ),
                    
                    // Messages
                    Expanded(
                      child: messages.isEmpty 
                          ? _buildEmptyState()
                          : ListView.builder(
                              controller: _scrollController,
                              padding: AppSpacing.paddingMd,
                              itemCount: messages.length,
                              itemBuilder: (context, index) {
                                final message = messages[index];
                                return _buildMessageBubble(message, theme);
                              },
                            ),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64),
                    AppSpacing.verticalSpaceMd,
                    Text('Error loading messages'),
                    AppSpacing.verticalSpaceSm,
                    Text(
                      error.toString(),
                      style: theme.textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Message input
          _buildMessageInput(theme),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          AppSpacing.verticalSpaceMd,
          Text(
            'No messages yet',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          AppSpacing.verticalSpaceSm,
          Text(
            'Start the conversation with your trip members!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message message, ThemeData theme) {
    final currentUser = ref.watch(currentUserProvider);
    final isCurrentUser = currentUser?.id == message.senderId;
    
    return Padding(
      padding: AppSpacing.paddingVerticalXs,
      child: Row(
        mainAxisAlignment: isCurrentUser 
            ? MainAxisAlignment.end 
            : MainAxisAlignment.start,
        children: [
          if (!isCurrentUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: theme.colorScheme.primary,
              child: Text(
                message.senderId.substring(0, 1).toUpperCase(),
                style: TextStyle(
                  color: theme.colorScheme.onPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            AppSpacing.horizontalSpaceXs,
          ],
          
          Flexible(
            child: Container(
              padding: AppSpacing.paddingMd,
              decoration: BoxDecoration(
                color: isCurrentUser 
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16).copyWith(
                  bottomRight: isCurrentUser 
                      ? const Radius.circular(4) 
                      : const Radius.circular(16),
                  bottomLeft: !isCurrentUser 
                      ? const Radius.circular(4) 
                      : const Radius.circular(16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isCurrentUser) ...[
                    Text(
                      message.senderId, // In real app, this would be display name
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    AppSpacing.verticalSpaceXs,
                  ],
                  
                  // Check if this is a voice message
                  message.text.startsWith('Voice message')
                      ? _buildVoiceMessageBubble(message, theme, isCurrentUser)
                      : Text(
                          message.text,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isCurrentUser 
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                  
                  AppSpacing.verticalSpaceXs,
                  
                  Text(
                    _formatMessageTime(message.createdAt),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isCurrentUser 
                          ? theme.colorScheme.onPrimary.withOpacity(0.7)
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  
                  if (message.type == MessageType.announcement) ...[
                    AppSpacing.verticalSpaceXs,
                    Icon(
                      Icons.campaign,
                      size: 16,
                      color: isCurrentUser 
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.primary,
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          if (isCurrentUser) ...[
            AppSpacing.horizontalSpaceXs,
            CircleAvatar(
              radius: 16,
              backgroundColor: theme.colorScheme.secondary,
              child: Text(
                (currentUser?.displayName ?? 'You').substring(0, 1).toUpperCase(),
                style: TextStyle(
                  color: theme.colorScheme.onSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageInput(ThemeData theme) {
    return Container(
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Attachment button
            if (!_isRecording) ...[
              IconButton(
                icon: const Icon(Icons.attach_file),
                onPressed: () => _showAttachmentOptions(context),
                tooltip: 'Attach file',
              ),
            ],
            
            // Message input field or recording indicator
            Expanded(
              child: _isRecording 
                  ? _buildRecordingIndicator(theme)
                  : TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => _sendMessage(),
                    ),
            ),
            
            AppSpacing.horizontalSpaceSm,
            
            // Camera button (only when not recording)
            if (!_isRecording && !_hasText) ...[
              IconButton(
                icon: const Icon(Icons.camera_alt),
                onPressed: () => _takePicture(),
                tooltip: 'Take picture',
              ),
            ],
            
            // Send/Voice button
            Container(
              decoration: BoxDecoration(
                color: _isRecording 
                    ? Colors.red 
                    : theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(
                  _isRecording 
                      ? Icons.stop
                      : _hasText 
                          ? Icons.send 
                          : Icons.mic,
                  color: Colors.white,
                ),
                onPressed: _isRecording 
                    ? _stopRecording 
                    : _hasText 
                        ? _sendMessage 
                        : _startRecording,
                tooltip: _isRecording 
                    ? 'Stop recording'
                    : _hasText 
                        ? 'Send message' 
                        : 'Record voice message',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordingIndicator(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          // Recording animation
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 1500),
            builder: (context, value, child) {
              return Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(value),
                  shape: BoxShape.circle,
                ),
              );
            },
          ),
          
          AppSpacing.horizontalSpaceSm,
          
          Text(
            'Recording voice message...',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          
          const Spacer(),
          
          // Recording duration (mock)
          Text(
            '0:${DateTime.now().second.toString().padLeft(2, '0')}',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceMessageBubble(Message message, ThemeData theme, bool isCurrentUser) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Play button
          Container(
            decoration: BoxDecoration(
              color: isCurrentUser 
                  ? theme.colorScheme.onPrimary.withOpacity(0.2)
                  : theme.colorScheme.primary.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                Icons.play_arrow,
                color: isCurrentUser 
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.primary,
                size: 20,
              ),
              onPressed: () {
                // Mock audio playback
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Playing voice message...'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
              constraints: const BoxConstraints(
                minWidth: 32,
                minHeight: 32,
              ),
              padding: EdgeInsets.zero,
            ),
          ),
          
          AppSpacing.horizontalSpaceXs,
          
          // Waveform visualization (mock)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: List.generate(20, (index) {
                    final height = (index % 3 + 1) * 4.0; // Mock waveform
                    return Container(
                      width: 2,
                      height: height,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                        color: isCurrentUser 
                            ? theme.colorScheme.onPrimary.withOpacity(0.7)
                            : theme.colorScheme.primary.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    );
                  }),
                ),
                AppSpacing.verticalSpaceXs,
                Text(
                  '0:03', // Mock duration
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isCurrentUser 
                        ? theme.colorScheme.onPrimary.withOpacity(0.8)
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          
          AppSpacing.horizontalSpaceXs,
          
          // Voice message icon
          Icon(
            Icons.mic,
            size: 16,
            color: isCurrentUser 
                ? theme.colorScheme.onPrimary.withOpacity(0.7)
                : theme.colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isNotEmpty) {
      print('Sending message: $text'); // Debug log
      
      try {
        // Send message through provider
        ref.read(tripActionsProvider.notifier).sendMessage(
          widget.tripId,
          text,
          type: MessageType.chat,
        );
        
        _messageController.clear();
        
        // Scroll to bottom after a short delay
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Future.delayed(const Duration(milliseconds: 100), () {
            if (_scrollController.hasClients) {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            }
          });
        });
        
        print('Message sent successfully'); // Debug log
      } catch (e) {
        print('Error sending message: $e'); // Debug log
        
        // Show error snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  // Audio/Video call methods
  void _initiateAudioCall() {
    print('Initiating audio call for trip: ${widget.tripId}');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Audio Call'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.call, size: 64, color: Colors.green),
            AppSpacing.verticalSpaceMd,
            const Text('Starting audio call with trip members...'),
            AppSpacing.verticalSpaceMd,
            const LinearProgressIndicator(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showCallScreen(isVideo: false);
            },
            child: const Text('Join'),
          ),
        ],
      ),
    );
  }

  void _initiateVideoCall() {
    print('Initiating video call for trip: ${widget.tripId}');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Video Call'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.videocam, size: 64, color: Colors.blue),
            AppSpacing.verticalSpaceMd,
            const Text('Starting video call with trip members...'),
            AppSpacing.verticalSpaceMd,
            const LinearProgressIndicator(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showCallScreen(isVideo: true);
            },
            child: const Text('Join'),
          ),
        ],
      ),
    );
  }

  void _showCallScreen({required bool isVideo}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black87,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            // Call header
            Container(
              padding: AppSpacing.paddingMd,
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: const Icon(Icons.group, color: Colors.white),
                  ),
                  AppSpacing.horizontalSpaceMd,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Trip Group ${isVideo ? 'Video' : 'Audio'} Call',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          '3 participants',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            
            // Video area (mock)
            Expanded(
              child: Container(
                margin: AppSpacing.paddingMd,
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isVideo ? Icons.videocam_off : Icons.mic,
                        size: 64,
                        color: Colors.white54,
                      ),
                      AppSpacing.verticalSpaceMd,
                      Text(
                        isVideo 
                            ? 'Camera is turned off'
                            : 'Audio call in progress',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 16,
                        ),
                      ),
                      AppSpacing.verticalSpaceMd,
                      const Text(
                        'This is a mock call interface.\nWebRTC integration would be implemented here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Call controls
            Container(
              padding: AppSpacing.paddingMd,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildCallButton(
                    icon: Icons.mic_off,
                    onPressed: () {},
                    backgroundColor: Colors.grey[700],
                  ),
                  if (isVideo) ...[
                    _buildCallButton(
                      icon: Icons.videocam_off,
                      onPressed: () {},
                      backgroundColor: Colors.grey[700],
                    ),
                    _buildCallButton(
                      icon: Icons.flip_camera_ios,
                      onPressed: () {},
                      backgroundColor: Colors.grey[700],
                    ),
                  ],
                  _buildCallButton(
                    icon: Icons.call_end,
                    onPressed: () => Navigator.of(context).pop(),
                    backgroundColor: Colors.red,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCallButton({
    required IconData icon,
    required VoidCallback onPressed,
    Color? backgroundColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.grey[700],
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        onPressed: onPressed,
        iconSize: 28,
      ),
    );
  }

  // Menu actions
  void _handleMenuAction(String action) {
    switch (action) {
      case 'notifications':
        _toggleNotifications();
        break;
      case 'members':
        _showTripMembers();
        break;
      case 'media':
        _showSharedMedia();
        break;
      case 'clear':
        _clearChat();
        break;
    }
  }

  void _toggleNotifications() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notifications toggled')),
    );
  }

  void _showTripMembers() {
    // Navigate to trip members screen or show modal
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Trip members feature coming soon')),
    );
  }

  void _showSharedMedia() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Shared media feature coming soon')),
    );
  }

  void _clearChat() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Chat'),
        content: const Text('Are you sure you want to clear all messages? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Implement clear chat functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Chat cleared')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  // Media and attachment methods
  void _showAttachmentOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Photo Library'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () {
                Navigator.of(context).pop();
                _takePicture();
              },
            ),
            ListTile(
              leading: const Icon(Icons.insert_drive_file),
              title: const Text('Document'),
              onTap: () {
                Navigator.of(context).pop();
                _pickDocument();
              },
            ),
            ListTile(
              leading: const Icon(Icons.location_on),
              title: const Text('Location'),
              onTap: () {
                Navigator.of(context).pop();
                _shareLocation();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _pickImage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Image picker feature coming soon')),
    );
  }

  void _takePicture() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Camera feature coming soon')),
    );
  }

  void _pickDocument() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Document picker feature coming soon')),
    );
  }

  void _shareLocation() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Location sharing feature coming soon')),
    );
  }

  // Voice recording methods
  void _startRecording() async {
    print('Starting voice recording');
    
    // Check microphone permission (mock)
    bool hasPermission = await _checkMicrophonePermission();
    if (!hasPermission) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Microphone permission required for voice messages'),
          action: SnackBarAction(
            label: 'Settings',
            onPressed: () {
              // Open app settings
            },
          ),
        ),
      );
      return;
    }
    
    setState(() {
      _isRecording = true;
    });
    
    // Mock recording start
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Recording started. Tap stop when finished.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _stopRecording() async {
    print('Stopping voice recording');
    
    setState(() {
      _isRecording = false;
    });
    
    // Mock recording processing
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            AppSpacing.verticalSpaceMd,
            const Text('Processing voice message...'),
          ],
        ),
      ),
    );
    
    // Simulate processing time
    await Future.delayed(const Duration(seconds: 2));
    
    if (mounted) {
      Navigator.of(context).pop(); // Close processing dialog
      
      // Show voice message preview dialog
      _showVoiceMessagePreview();
    }
  }

  void _showVoiceMessagePreview() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Voice Message'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.play_arrow),
                    onPressed: () {
                      // Mock audio playback
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Playing voice message...')),
                      );
                    },
                  ),
                  AppSpacing.horizontalSpaceSm,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LinearProgressIndicator(
                          value: 0.0,
                          backgroundColor: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                        ),
                        AppSpacing.verticalSpaceXs,
                        Text(
                          '0:03',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _sendVoiceMessage();
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  void _sendVoiceMessage() {
    print('Sending voice message');
    
    try {
      // Check if widget is still mounted before using ref
      if (!mounted) return;
      
      // Send voice message through provider
      ref.read(tripActionsProvider.notifier).sendMessage(
        widget.tripId,
        'Voice message (3 seconds)', // In real app, this would be audio data
        type: MessageType.chat, // In real app, would be MessageType.voice
      );
      
      // Show success feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Voice message sent!'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
      
      // Scroll to bottom
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      });
      
    } catch (e) {
      print('Error sending voice message: $e');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send voice message: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<bool> _checkMicrophonePermission() async {
    // Mock permission check - in real app would use permission_handler
    await Future.delayed(const Duration(milliseconds: 500));
    return true; // Mock granted permission
  }

  // Polling methods
  void _createQuickPoll() {
    showDialog(
      context: context,
      builder: (context) => QuickPollDialog(
        onCreate: (question, options, deadlineMinutes) {
          _createPoll(question, options, deadlineMinutes);
        },
      ),
    );
  }

  void _createPoll(String question, List<String> options, int? deadlineMinutes) {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    final pollId = 'poll_${DateTime.now().millisecondsSinceEpoch}';
    final deadline = deadlineMinutes != null 
        ? DateTime.now().add(Duration(minutes: deadlineMinutes))
        : null;

    final poll = ChatPoll(
      id: pollId,
      question: question,
      options: options,
      votes: {for (String option in options) option: 0},
      userVotes: {},
      createdAt: DateTime.now(),
      deadline: deadline,
      creatorId: currentUser.id,
      isActive: true,
    );

    setState(() {
      _activePoll = poll;
    });

    // Send poll announcement to chat
    ref.read(tripActionsProvider.notifier).sendMessage(
      widget.tripId,
      '📊 Poll created: "$question"',
      type: MessageType.announcement,
    );

    // Show success feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.poll, color: Colors.white),
            AppSpacing.horizontalSpaceSm,
            const Text('Poll created! Members can vote now.'),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );

    // Auto-close poll after deadline (for demo)
    if (deadline != null) {
      Future.delayed(Duration(minutes: deadlineMinutes!), () {
        if (mounted && _activePoll?.id == pollId) {
          setState(() {
            _activePoll = _activePoll?.copyWith(isActive: false);
          });
          
          // Announce results
          final winningOption = _activePoll?.winningOption;
          if (winningOption != null) {
            ref.read(tripActionsProvider.notifier).sendMessage(
              widget.tripId,
              '🏆 Poll result: "$winningOption" wins!',
              type: MessageType.announcement,
            );
          }
        }
      });
    }
  }

  String _formatMessageTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'now';
    }
  }
}
