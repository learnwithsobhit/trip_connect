import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/data/models/social_features.dart';
import '../../../../core/services/social_sharing_service.dart';
import '../../../../core/theme/app_spacing.dart';

class SocialSharingDialog extends ConsumerStatefulWidget {
  final ShareableContent content;
  final String? customMessage;

  const SocialSharingDialog({
    super.key,
    required this.content,
    this.customMessage,
  });

  @override
  ConsumerState<SocialSharingDialog> createState() => _SocialSharingDialogState();
}

class _SocialSharingDialogState extends ConsumerState<SocialSharingDialog> {
  final TextEditingController _messageController = TextEditingController();
  final SocialSharingService _sharingService = SocialSharingService();
  bool _isSharing = false;

  @override
  void initState() {
    super.initState();
    _messageController.text = widget.customMessage ?? _sharingService.generateShareMessage(widget.content);
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final platforms = _sharingService.getAvailablePlatforms();

    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        padding: AppSpacing.paddingMd,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.share,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Share to Social Media',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Content Preview
            _buildContentPreview(theme),
            
            const SizedBox(height: 16),
            
            // Custom Message
            _buildMessageInput(theme),
            
            const SizedBox(height: 16),
            
            // Platform Selection
            _buildPlatformSelection(theme, platforms),
            
            const SizedBox(height: 16),
            
            // Action Buttons
            _buildActionButtons(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContentPreview(ThemeData theme) {
    return Card(
      child: Padding(
        padding: AppSpacing.paddingMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Preview',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                // Image preview
                if (widget.content.imageUrl != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      widget.content.imageUrl!,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.image,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                
                // Content details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.content.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.content.description,
                        style: theme.textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.content.shareUrl,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Custom Message',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _messageController,
          maxLines: 2,
          decoration: InputDecoration(
            hintText: 'Add your custom message...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
            fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
      ],
    );
  }

  Widget _buildPlatformSelection(ThemeData theme, List<SocialPlatform> platforms) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose Platform',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1.1,
          ),
          itemCount: platforms.length,
          itemBuilder: (context, index) {
            final platform = platforms[index];
            return _buildPlatformCard(theme, platform);
          },
        ),
      ],
    );
  }

  Widget _buildPlatformCard(ThemeData theme, SocialPlatform platform) {
    return Card(
      child: InkWell(
        onTap: _isSharing ? null : () => _shareToPlatform(platform),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                platform.icon,
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(height: 2),
              Text(
                platform.displayName,
                style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isSharing ? null : () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: _isSharing ? null : _shareToAllPlatforms,
            child: _isSharing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Share to All'),
          ),
        ),
      ],
    );
  }

  Future<void> _shareToPlatform(SocialPlatform platform) async {
    setState(() {
      _isSharing = true;
    });

    try {
      final success = await _sharingService.shareToSocialPlatform(
        content: widget.content,
        platform: platform,
        customMessage: _messageController.text.trim(),
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Shared to ${platform.displayName} successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share to ${platform.displayName}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSharing = false;
        });
      }
    }
  }

  Future<void> _shareToAllPlatforms() async {
    setState(() {
      _isSharing = true;
    });

    try {
      final platforms = _sharingService.getAvailablePlatforms();
      int successCount = 0;

      for (final platform in platforms) {
        if (platform != SocialPlatform.copyLink) { // Skip copy link for bulk sharing
          final success = await _sharingService.shareToSocialPlatform(
            content: widget.content,
            platform: platform,
            customMessage: _messageController.text.trim(),
          );
          if (success) successCount++;
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Shared to $successCount platforms successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSharing = false;
        });
      }
    }
  }
}
