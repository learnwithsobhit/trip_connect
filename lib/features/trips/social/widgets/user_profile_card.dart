import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../../core/data/models/models.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

class UserProfileCard extends ConsumerStatefulWidget {
  final UserProfile user;
  final bool isCurrentUser;
  final VoidCallback? onTap;
  final VoidCallback? onFollow;
  final VoidCallback? onMessage;

  const UserProfileCard({
    super.key,
    required this.user,
    this.isCurrentUser = false,
    this.onTap,
    this.onFollow,
    this.onMessage,
  });

  @override
  ConsumerState<UserProfileCard> createState() => _UserProfileCardState();
}

class _UserProfileCardState extends ConsumerState<UserProfileCard> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFollowing = _isFollowingUser();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with avatar and basic info
              Row(
                children: [
                  // Avatar
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: theme.colorScheme.primaryContainer,
                        backgroundImage: widget.user.avatarUrl != null
                            ? NetworkImage(widget.user.avatarUrl!)
                            : null,
                        child: widget.user.avatarUrl == null
                            ? Text(
                                widget.user.name.substring(0, 1).toUpperCase(),
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                              )
                            : null,
                      ),
                      // Status indicator
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: widget.user.status.color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: theme.colorScheme.surface,
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            widget.user.status.icon,
                            size: 8,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  // User info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.user.name,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (widget.user.isVerified)
                              Icon(
                                Icons.verified,
                                color: theme.colorScheme.primary,
                                size: 16,
                              ),
                          ],
                        ),
                        if (widget.user.location != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 12,
                                color: theme.colorScheme.outline,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  widget.user.location!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.outline,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          'Joined ${timeago.format(widget.user.joinedAt)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // Bio
              if (widget.user.bio != null && widget.user.bio!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  widget.user.bio!,
                  style: theme.textTheme.bodyMedium,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              // Stats
              const SizedBox(height: 16),
              _buildStatsRow(theme),
              // Action buttons
              if (!widget.isCurrentUser) ...[
                const SizedBox(height: 16),
                _buildActionButtons(theme, isFollowing),
              ],
              // Recent achievements
              if (widget.user.achievements.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildRecentAchievements(theme),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItem(
          theme,
          'Trips',
          '${widget.user.stats.totalTrips}',
          Icons.flight,
        ),
        _buildStatItem(
          theme,
          'Posts',
          '${widget.user.stats.totalPosts}',
          Icons.post_add,
        ),
        _buildStatItem(
          theme,
          'Followers',
          '${widget.user.stats.followersCount}',
          Icons.people,
        ),
        _buildStatItem(
          theme,
          'Rating',
          widget.user.stats.averageRating > 0
              ? '${widget.user.stats.averageRating.toStringAsFixed(1)}⭐'
              : 'N/A',
          Icons.star,
        ),
      ],
    );
  }

  Widget _buildStatItem(ThemeData theme, String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(ThemeData theme, bool isFollowing) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: widget.onFollow,
            icon: Icon(
              isFollowing ? Icons.person_remove : Icons.person_add,
              size: 16,
            ),
            label: Text(
              isFollowing ? 'Unfollow' : 'Follow',
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: isFollowing
                  ? theme.colorScheme.error
                  : theme.colorScheme.primary,
              side: BorderSide(
                color: isFollowing
                    ? theme.colorScheme.error
                    : theme.colorScheme.primary,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: widget.onMessage,
            icon: const Icon(Icons.message, size: 16),
            label: const Text('Message'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentAchievements(ThemeData theme) {
    final recentAchievements = widget.user.achievements
        .take(3)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.emoji_events,
              size: 16,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Recent Achievements',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Text(
              '${widget.user.achievements.length} total',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: recentAchievements.map((achievement) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: achievement.type.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: achievement.type.color.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    achievement.type.icon,
                    size: 12,
                    color: achievement.type.color,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    achievement.title,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: achievement.type.color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  bool _isFollowingUser() {
    // TODO: Check if current user is following this user
    // For now, return false as placeholder
    return false;
  }
}
