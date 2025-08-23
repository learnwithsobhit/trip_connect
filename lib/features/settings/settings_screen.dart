import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/data/providers/auth_provider.dart';
import '../../core/data/providers/language_provider.dart';
import '../../core/theme/app_spacing.dart';
import '../../app.dart';

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
                    onPressed: () => context.push('/settings/profile'),
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
                ref.watch(themeProvider).name,
                () => _showThemeDialog(context, ref),
              ),
              _buildSettingTile(
                context,
                Icons.language_outlined,
                'Language',
                ref.watch(currentLanguageNameProvider),
                () => context.push('/settings/language'),
              ),
              _buildSettingTile(
                context,
                Icons.notifications_outlined,
                'Notifications',
                'Manage notifications',
                () => _showNotificationSettings(context),
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
                () => _showLocationSettings(context),
              ),
              _buildSettingTile(
                context,
                Icons.security_outlined,
                'Privacy Settings',
                'Manage privacy',
                () => _showPrivacySettings(context),
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
                () => _showHelpSupport(context),
              ),
              _buildSettingTile(
                context,
                Icons.bug_report_outlined,
                'Report a Bug',
                '',
                () => _showReportBug(context),
              ),
              _buildSettingTile(
                context,
                Icons.info_outline,
                'About',
                'Version 1.0.0',
                () => _showAbout(context),
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
      onTap: onTap,
    );
  }

  // Settings dialog methods
  void _showThemeDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: const Text('Light'),
              subtitle: const Text('Use light theme'),
              value: ThemeMode.light,
              groupValue: ref.read(themeProvider),
              onChanged: (value) {
                ref.read(themeProvider.notifier).state = value!;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Theme changed to Light')),
                );
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Dark'),
              subtitle: const Text('Use dark theme'),
              value: ThemeMode.dark,
              groupValue: ref.read(themeProvider),
              onChanged: (value) {
                ref.read(themeProvider.notifier).state = value!;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Theme changed to Dark')),
                );
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('System'),
              subtitle: const Text('Follow system theme'),
              value: ThemeMode.system,
              groupValue: ref.read(themeProvider),
              onChanged: (value) {
                ref.read(themeProvider.notifier).state = value!;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Theme set to System')),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showNotificationSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notification Settings'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: Text('Trip Updates'),
              subtitle: Text('Get notified about trip changes'),
              value: true,
              onChanged: null,
            ),
            SwitchListTile(
              title: Text('Chat Messages'),
              subtitle: Text('Get notified about new messages'),
              value: true,
              onChanged: null,
            ),
            SwitchListTile(
              title: Text('Emergency Alerts'),
              subtitle: Text('Get notified about emergency situations'),
              value: true,
              onChanged: null,
            ),
            SwitchListTile(
              title: Text('Roll Call Reminders'),
              subtitle: Text('Get reminded about roll calls'),
              value: false,
              onChanged: null,
            ),
            SwitchListTile(
              title: Text('Weather Updates'),
              subtitle: Text('Get weather alerts for your trips'),
              value: true,
              onChanged: null,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notification settings updated!')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showLocationSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Sharing'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: Text('Precise'),
              subtitle: Text('Share exact location'),
              value: 'precise',
              groupValue: 'precise',
              onChanged: null,
            ),
            RadioListTile<String>(
              title: Text('Approximate'),
              subtitle: Text('Share approximate location'),
              value: 'approximate',
              groupValue: 'precise',
              onChanged: null,
            ),
            RadioListTile<String>(
              title: Text('Off'),
              subtitle: Text('Don\'t share location'),
              value: 'off',
              groupValue: 'precise',
              onChanged: null,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Location settings updated!')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showPrivacySettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Settings'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: Text('Profile Visibility'),
              subtitle: Text('Allow others to see your profile'),
              value: true,
              onChanged: null,
            ),
            SwitchListTile(
              title: Text('Location History'),
              subtitle: Text('Save location history'),
              value: false,
              onChanged: null,
            ),
            SwitchListTile(
              title: Text('Analytics'),
              subtitle: Text('Share usage data for improvements'),
              value: true,
              onChanged: null,
            ),
            SwitchListTile(
              title: Text('Crash Reports'),
              subtitle: Text('Send crash reports automatically'),
              value: true,
              onChanged: null,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Privacy settings updated!')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showHelpSupport(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & Support'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.book),
              title: Text('User Guide'),
              subtitle: Text('Learn how to use the app'),
            ),
            ListTile(
              leading: Icon(Icons.question_answer),
              title: Text('FAQ'),
              subtitle: Text('Frequently asked questions'),
            ),
            ListTile(
              leading: Icon(Icons.contact_support),
              title: Text('Contact Support'),
              subtitle: Text('Get help from our team'),
            ),
            ListTile(
              leading: Icon(Icons.video_library),
              title: Text('Video Tutorials'),
              subtitle: Text('Watch helpful videos'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showReportBug(BuildContext context) {
    final bugController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report a Bug'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Help us improve by reporting any issues you encounter.'),
            const SizedBox(height: 16),
            TextField(
              controller: bugController,
              decoration: const InputDecoration(
                labelText: 'Describe the issue',
                hintText: 'What happened? What did you expect?',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (bugController.text.trim().isNotEmpty) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Bug report submitted! Thank you.')),
                );
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About TripConnect'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version 1.0.0'),
            SizedBox(height: 8),
            Text('TripConnect is your ultimate travel companion app.'),
            SizedBox(height: 16),
            Text('Features:'),
            Text('• Trip planning and management'),
            Text('• Real-time location tracking'),
            Text('• Group chat and communication'),
            Text('• Weather updates and alerts'),
            Text('• Emergency assistance'),
            SizedBox(height: 16),
            Text('© 2024 TripConnect. All rights reserved.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}


