import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../../core/data/models/models.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

class CommentDialog extends ConsumerStatefulWidget {
  final SocialPost post;
  final Function(Comment) onCommentAdded;

  const CommentDialog({
    super.key,
    required this.post,
    required this.onCommentAdded,
  });

  @override
  ConsumerState<CommentDialog> createState() => _CommentDialogState();
}

class _CommentDialogState extends ConsumerState<CommentDialog> {
  final _commentController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Flexible(
              child: Column(
                children: [
                  _buildPostPreview(),
                  const Divider(height: 1),
                  Expanded(
                    child: _buildCommentsList(),
                  ),
                ],
              ),
            ),
            _buildCommentInput(),
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
              'Comments',
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

  Widget _buildPostPreview() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primary,
            child: Text(
              _getUserName(widget.post.authorId).substring(0, 1).toUpperCase(),
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
                Row(
                  children: [
                    Text(
                      _getUserName(widget.post.authorId),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      timeago.format(widget.post.createdAt),
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  widget.post.content,
                  style: const TextStyle(fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.post.media.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        widget.post.media.first.type == SocialMediaType.video
                            ? Icons.videocam
                            : Icons.photo,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.post.media.length} ${widget.post.media.length == 1 ? 'media' : 'media'}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsList() {
    if (widget.post.comments.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 48,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No comments yet',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Be the first to comment!',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.post.comments.length,
      itemBuilder: (context, index) {
        final comment = widget.post.comments[index];
        return _buildCommentItem(comment);
      },
    );
  }

  Widget _buildCommentItem(Comment comment) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primary.withOpacity(0.7),
            child: Text(
              _getUserName(comment.authorId).substring(0, 1).toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _getUserName(comment.authorId),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      timeago.format(comment.createdAt),
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  comment.content,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildReactionButton(comment, ReactionType.like),
                    const SizedBox(width: 16),
                    _buildReactionButton(comment, ReactionType.love),
                    const SizedBox(width: 16),
                    _buildReactionButton(comment, ReactionType.laugh),
                    const Spacer(),
                    TextButton(
                      onPressed: () => _replyToComment(comment),
                      child: const Text(
                        'Reply',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReactionButton(Comment comment, ReactionType reactionType) {
    final hasReaction = comment.reactions.any(
      (r) => r.type == reactionType && r.userId == 'u_leader', // TODO: Get current user ID
    );

    return GestureDetector(
      onTap: () => _toggleReaction(comment, reactionType),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _getReactionEmoji(reactionType),
            style: TextStyle(
              fontSize: 14,
              color: hasReaction ? AppColors.primary : Colors.grey.shade600,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            _getReactionCount(comment, reactionType).toString(),
            style: TextStyle(
              fontSize: 11,
              color: hasReaction ? AppColors.primary : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primary,
            child: const Text(
              'A', // TODO: Get current user initial
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText: 'Write a comment...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _addComment(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _isLoading ? null : _addComment,
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }

  void _addComment() async {
    final commentText = _commentController.text.trim();
    if (commentText.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final comment = Comment(
        id: 'comment_${DateTime.now().millisecondsSinceEpoch}',
        postId: widget.post.id,
        authorId: 'u_leader', // TODO: Get from auth provider
        content: commentText,
        createdAt: DateTime.now(),
      );

      widget.onCommentAdded(comment);
      _commentController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add comment: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _toggleReaction(Comment comment, ReactionType reactionType) {
    // TODO: Implement reaction toggling
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Reacted with ${_getReactionEmoji(reactionType)}'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _replyToComment(Comment comment) {
    // TODO: Implement reply functionality
    _commentController.text = '@${_getUserName(comment.authorId)} ';
    _commentController.selection = TextSelection.fromPosition(
      TextPosition(offset: _commentController.text.length),
    );
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

  String _getReactionEmoji(ReactionType type) {
    switch (type) {
      case ReactionType.like:
        return '👍';
      case ReactionType.love:
        return '❤️';
      case ReactionType.laugh:
        return '😂';
      case ReactionType.wow:
        return '😮';
      case ReactionType.sad:
        return '😢';
      case ReactionType.angry:
        return '😠';
      case ReactionType.fire:
        return '🔥';
      case ReactionType.heart:
        return '💖';
      case ReactionType.thumbsUp:
        return '👍';
      case ReactionType.clap:
        return '👏';
    }
  }

  int _getReactionCount(Comment comment, ReactionType type) {
    return comment.reactions.where((r) => r.type == type).length;
  }
}
