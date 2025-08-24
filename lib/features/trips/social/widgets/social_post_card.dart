import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../../core/data/models/social_features.dart';
import '../../../../core/theme/app_spacing.dart';

class SocialPostCard extends StatelessWidget {
  final SocialPost post;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onShare;

  const SocialPostCard({
    super.key,
    required this.post,
    this.onLike,
    this.onComment,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: AppSpacing.paddingMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Post Header
            _buildPostHeader(theme),
            
            const SizedBox(height: 12),
            
            // Post Content
            _buildPostContent(theme),
            
            // Media
            if (post.media.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildMediaSection(theme),
            ],
            
            const SizedBox(height: 12),
            
            // Reactions
            if (post.reactions.isNotEmpty) ...[
              _buildReactionsSection(theme),
              const SizedBox(height: 8),
            ],
            
            // Comments
            if (post.comments.isNotEmpty) ...[
              _buildCommentsSection(theme),
              const SizedBox(height: 8),
            ],
            
            // Action Buttons
            _buildActionButtons(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildPostHeader(ThemeData theme) {
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Text(
            post.authorId.substring(0, 1).toUpperCase(),
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
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
                'Trip Member', // TODO: Get actual user name
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  Text(
                    post.type.icon,
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    timeago.format(post.createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (post.isPinned)
          Icon(
            Icons.push_pin,
            size: 16,
            color: theme.colorScheme.primary,
          ),
      ],
    );
  }

  Widget _buildPostContent(ThemeData theme) {
    return Text(
      post.content,
      style: theme.textTheme.bodyMedium,
    );
  }

  Widget _buildMediaSection(ThemeData theme) {
    if (post.media.isEmpty) return const SizedBox.shrink();

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Image.network(
          post.media.first.url,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Icon(
                  Icons.image,
                  size: 48,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildReactionsSection(ThemeData theme) {
    final reactionCounts = <ReactionType, int>{};
    for (final reaction in post.reactions) {
      reactionCounts[reaction.type] = (reactionCounts[reaction.type] ?? 0) + 1;
    }

    return Row(
      children: [
        ...reactionCounts.entries.take(3).map((entry) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  entry.key.emoji,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(width: 4),
                Text(
                  '${entry.value}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }),
        if (reactionCounts.length > 3)
          Text(
            ' +${reactionCounts.length - 3} more',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }

  Widget _buildCommentsSection(ThemeData theme) {
    return Column(
      children: post.comments.take(2).map((comment) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: theme.colorScheme.secondaryContainer,
                child: Text(
                  comment.authorId.substring(0, 1).toUpperCase(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSecondaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Trip Member', // TODO: Get actual user name
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      comment.content,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            theme,
            icon: Icons.favorite_border,
            label: 'Like',
            onTap: onLike,
          ),
        ),
        Expanded(
          child: _buildActionButton(
            theme,
            icon: Icons.comment_outlined,
            label: 'Comment',
            onTap: onComment,
          ),
        ),
        Expanded(
          child: _buildActionButton(
            theme,
            icon: Icons.share_outlined,
            label: 'Share',
            onTap: onShare,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    ThemeData theme, {
    required IconData icon,
    required String label,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
