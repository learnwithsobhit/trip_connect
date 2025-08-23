import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/providers/trip_provider.dart';
import '../../../core/data/providers/auth_provider.dart';
import '../../../core/data/models/models.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_colors.dart';
import '../../common/widgets/user_rating_badge.dart';

class TripChatScreen extends ConsumerStatefulWidget {
  final String tripId;

  const TripChatScreen({super.key, required this.tripId});

  @override
  ConsumerState<TripChatScreen> createState() => _TripChatScreenState();
}

class _TripChatScreenState extends ConsumerState<TripChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final messagesAsync = ref.watch(tripMessagesProvider(widget.tripId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Chat'),
        leading: IconButton(
          onPressed: () => context.go('/trips/${widget.tripId}'),
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [
          IconButton(
            onPressed: () => _showAnnouncementDialog(context),
            icon: const Icon(Icons.campaign_outlined),
            tooltip: 'Send Announcement',
          ),
          IconButton(
            onPressed: () => _showPollDialog(context),
            icon: const Icon(Icons.poll_outlined),
            tooltip: 'Create Poll',
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'emergency',
                child: Row(
                  children: [
                    Icon(Icons.emergency, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Emergency Alert'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'rollcall',
                child: Row(
                  children: [
                    Icon(Icons.how_to_reg),
                    SizedBox(width: 8),
                    Text('Start Roll Call'),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'emergency') {
                _sendEmergencyAlert();
              } else if (value == 'rollcall') {
                _startRollCall();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: messagesAsync.when(
              data: (messages) => _buildMessagesList(messages),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
            ),
          ),
          
          // Message input
          _buildMessageInput(theme),
        ],
      ),
    );
  }

  Widget _buildMessagesList(List<Message> messages) {
    if (messages.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No messages yet'),
            Text('Start the conversation!'),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: AppSpacing.paddingMd,
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        return Padding(
          padding: AppSpacing.paddingVerticalXs,
          child: _MessageBubble(message: message),
        );
      },
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
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  filled: true,
                  fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: AppSpacing.paddingMd,
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            AppSpacing.horizontalSpaceSm,
            FloatingActionButton.small(
              onPressed: _sendMessage,
              child: const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final text = _messageController.text.trim();
    _messageController.clear();

    try {
      final tripActions = ref.read(tripActionsProvider.notifier);
      await tripActions.sendMessage(widget.tripId, text);
      
      // Scroll to bottom after sending
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: AppSpacing.animationFast,
          curve: AppSpacing.curveStandard,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e')),
        );
      }
    }
  }

  void _showAnnouncementDialog(BuildContext context) {
    final controller = TextEditingController();
    bool requiresAck = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Send Announcement'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Announcement',
                  hintText: 'Important message for all members',
                ),
                maxLines: 3,
              ),
              AppSpacing.verticalSpaceMd,
              CheckboxListTile(
                value: requiresAck,
                onChanged: (value) => setState(() => requiresAck = value ?? false),
                title: const Text('Require Acknowledgment'),
                subtitle: const Text('Members must acknowledge this message'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (controller.text.isNotEmpty) {
                  Navigator.of(context).pop();
                  try {
                    final tripActions = ref.read(tripActionsProvider.notifier);
                    await tripActions.sendMessage(
                      widget.tripId,
                      controller.text,
                      type: MessageType.announcement,
                      requiresAck: requiresAck,
                    );
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to send announcement: $e')),
                      );
                    }
                  }
                }
              },
              child: const Text('Send'),
            ),
          ],
        ),
      ),
    );
  }

  void _showPollDialog(BuildContext context) {
    final questionController = TextEditingController();
    final List<TextEditingController> optionControllers = [
      TextEditingController(),
      TextEditingController(),
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Poll'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: questionController,
                decoration: const InputDecoration(
                  labelText: 'Question',
                  hintText: 'What would you like to ask?',
                ),
              ),
              AppSpacing.verticalSpaceMd,
              ...optionControllers.asMap().entries.map((entry) {
                final index = entry.key;
                final controller = entry.value;
                return Padding(
                  padding: AppSpacing.paddingVerticalXs,
                  child: TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      labelText: 'Option ${index + 1}',
                      hintText: 'Enter option',
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              // Poll creation would be implemented here
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Poll feature coming soon!')),
              );
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendEmergencyAlert() async {
    try {
      final tripActions = ref.read(tripActionsProvider.notifier);
      await tripActions.raiseAlert(
        widget.tripId,
        AlertKind.sos,
        const AlertPayload(
          message: 'Emergency alert raised from chat',
        ),
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Emergency alert sent to all members'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send emergency alert: $e')),
        );
      }
    }
  }

  Future<void> _startRollCall() async {
    try {
      final tripActions = ref.read(tripActionsProvider.notifier);
      await tripActions.startRollCall(widget.tripId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Roll call started')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start roll call: $e')),
        );
      }
    }
  }
}

class _MessageBubble extends ConsumerWidget {
  final Message message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currentUser = ref.watch(currentUserProvider);
    final isOwnMessage = currentUser?.id == message.senderId;

    Color bubbleColor;
    Color textColor;
    IconData? typeIcon;

    switch (message.type) {
      case MessageType.announcement:
        bubbleColor = AppColors.warning.withOpacity(0.1);
        textColor = AppColors.warning;
        typeIcon = Icons.campaign;
        break;
      case MessageType.system:
        bubbleColor = theme.colorScheme.surfaceVariant;
        textColor = theme.colorScheme.onSurfaceVariant;
        typeIcon = Icons.info_outline;
        break;
      case MessageType.poll:
        bubbleColor = AppColors.info.withOpacity(0.1);
        textColor = AppColors.info;
        typeIcon = Icons.poll;
        break;
      default:
        if (isOwnMessage) {
          bubbleColor = theme.colorScheme.primary;
          textColor = theme.colorScheme.onPrimary;
        } else {
          bubbleColor = theme.colorScheme.surfaceVariant;
          textColor = theme.colorScheme.onSurfaceVariant;
        }
    }

    return Align(
      alignment: isOwnMessage ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        margin: AppSpacing.paddingVerticalXs,
        child: Column(
          crossAxisAlignment: isOwnMessage ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Sender name for other messages
            if (!isOwnMessage && message.type == MessageType.chat) ...[
              Padding(
                padding: AppSpacing.paddingHorizontalSm.copyWith(bottom: 4),
                child: Text(
                  'User ${message.senderId.substring(0, 8)}', // Mock sender name
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
            
            // Message bubble
            Container(
              padding: AppSpacing.paddingMd,
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg).copyWith(
                  bottomLeft: Radius.circular(isOwnMessage ? AppSpacing.radiusLg : AppSpacing.radiusXs),
                  bottomRight: Radius.circular(isOwnMessage ? AppSpacing.radiusXs : AppSpacing.radiusLg),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type indicator for special messages
                  if (typeIcon != null) ...[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          typeIcon,
                          size: AppSpacing.iconSm,
                          color: textColor,
                        ),
                        AppSpacing.horizontalSpaceXs,
                        Text(
                          message.type.name.toUpperCase(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    AppSpacing.verticalSpaceXs,
                  ],
                  
                  // Message text
                  Text(
                    message.text,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: textColor,
                    ),
                  ),
                  
                  // Tags
                  if (message.tags.isNotEmpty) ...[
                    AppSpacing.verticalSpaceXs,
                    Wrap(
                      spacing: 4,
                      children: message.tags.map((tag) => Chip(
                        label: Text(
                          tag,
                          style: theme.textTheme.labelSmall,
                        ),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      )).toList(),
                    ),
                  ],
                ],
              ),
            ),
            
            // Timestamp
            Padding(
              padding: AppSpacing.paddingHorizontalSm.copyWith(top: 4),
              child: Text(
                _formatTime(message.createdAt),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${dateTime.day}/${dateTime.month} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
}