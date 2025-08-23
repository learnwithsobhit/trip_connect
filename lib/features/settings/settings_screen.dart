import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/data/providers/auth_provider.dart';
import '../../core/theme/app_spacing.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          onPressed: () => context.go('/'),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: ListView(
        padding: AppSpacing.paddingMd,
        children: [
          // Profile section
          Card(
            child: Padding(
              padding: AppSpacing.paddingLg,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: theme.colorScheme.primary,
                    child: Text(
                      user?.displayName.substring(0, 1).toUpperCase() ?? 'U',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  AppSpacing.horizontalSpaceMd,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.displayName ?? 'User',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        AppSpacing.verticalSpaceXs,
                        Text(
                          user?.phone ?? 'No phone number',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Edit profile coming soon!')),
                      );
                    },
                    icon: const Icon(Icons.edit),
                  ),
                ],
              ),
            ),
          ),

          AppSpacing.verticalSpaceLg,

          // Settings sections
          _buildSection(
            context,
            'Preferences',
            [
              _buildSettingTile(
                context,
                Icons.dark_mode_outlined,
                'Dark Mode',
                'Coming soon',
                () {},
              ),
              _buildSettingTile(
                context,
                Icons.language_outlined,
                'Language',
                'English',
                () {},
              ),
              _buildSettingTile(
                context,
                Icons.notifications_outlined,
                'Notifications',
                'Manage notifications',
                () {},
              ),
            ],
          ),

          AppSpacing.verticalSpaceLg,

          _buildSection(
            context,
            'Privacy & Security',
            [
              _buildSettingTile(
                context,
                Icons.location_on_outlined,
                'Location Sharing',
                'Precise',
                () {},
              ),
              _buildSettingTile(
                context,
                Icons.security_outlined,
                'Privacy Settings',
                'Manage privacy',
                () {},
              ),
            ],
          ),

          AppSpacing.verticalSpaceLg,

          _buildSection(
            context,
            'Support',
            [
              _buildSettingTile(
                context,
                Icons.help_outline,
                'Help & Support',
                '',
                () {},
              ),
              _buildSettingTile(
                context,
                Icons.bug_report_outlined,
                'Report a Bug',
                '',
                () {},
              ),
              _buildSettingTile(
                context,
                Icons.info_outline,
                'About',
                'Version 1.0.0',
                () {},
              ),
            ],
          ),

          AppSpacing.verticalSpaceXl,

          // Sign out button
          Card(
            child: ListTile(
              leading: Icon(
                Icons.logout,
                color: theme.colorScheme.error,
              ),
              title: Text(
                'Sign Out',
                style: TextStyle(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () async {
                final shouldSignOut = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Sign Out'),
                    content: const Text('Are you sure you want to sign out?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Sign Out'),
                      ),
                    ],
                  ),
                );

                if (shouldSignOut == true) {
                  await ref.read(authProvider.notifier).signOut();
                  if (context.mounted) {
                    context.go('/auth/welcome');
                  }
                }
              },
            ),
          ),

          AppSpacing.verticalSpaceXl,
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: AppSpacing.paddingHorizontalMd,
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        AppSpacing.verticalSpaceSm,
        Card(
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSettingTile(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: subtitle.isNotEmpty ? Text(subtitle) : null,
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$title coming soon!')),
        );
      },
    );
  }
}


