import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/providers/trip_provider.dart';
import '../../../core/data/models/models.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_colors.dart';

class TripMapScreen extends ConsumerStatefulWidget {
  final String tripId;

  const TripMapScreen({super.key, required this.tripId});

  @override
  ConsumerState<TripMapScreen> createState() => _TripMapScreenState();
}

class _TripMapScreenState extends ConsumerState<TripMapScreen> {
  bool _isTrackingEnabled = true;
  bool _showAllMembers = true;
  String _selectedView = 'Live';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tripAsync = ref.watch(tripProvider(widget.tripId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Map'),
        leading: IconButton(
          onPressed: () => context.go('/trips/${widget.tripId}'),
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [
          IconButton(
            onPressed: () => _showMapOptions(context),
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
      body: tripAsync.when(
        data: (trip) => trip != null ? _buildMapContent(theme, trip) : const Center(child: Text('Trip not found')),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildMapContent(ThemeData theme, Trip trip) {
    return Column(
      children: [
        // Map Controls
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color: theme.colorScheme.outline.withOpacity(0.2),
              ),
            ),
          ),
          child: Row(
            children: [
              // View Selector
              Expanded(
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'Live', label: Text('Live')),
                    ButtonSegment(value: 'Route', label: Text('Route')),
                    ButtonSegment(value: 'Stops', label: Text('Stops')),
                  ],
                  selected: {_selectedView},
                  onSelectionChanged: (Set<String> selection) {
                    setState(() {
                      _selectedView = selection.first;
                    });
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              // Tracking Toggle
              Switch(
                value: _isTrackingEnabled,
                onChanged: (value) {
                  setState(() {
                    _isTrackingEnabled = value;
                  });
                },
              ),
            ],
          ),
        ),

        // Map Area
        Expanded(
          child: _buildMapArea(theme, trip),
        ),

        // Member List
        if (_showAllMembers) _buildMemberList(theme, trip),
      ],
    );
  }

  Widget _buildMapArea(ThemeData theme, Trip trip) {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Stack(
        children: [
          // Mock Map Background
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.blue.shade100,
                  Colors.green.shade100,
                ],
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.map,
                    size: 64,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Live Location Map',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Real-time tracking of trip members',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _buildMapFeatures(theme),
                ],
              ),
            ),
          ),

          // Map Controls Overlay
          Positioned(
            top: AppSpacing.md,
            right: AppSpacing.md,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'map-center-user',
                  onPressed: () => _centerOnUser(),
                  child: const Icon(Icons.my_location),
                ),
                const SizedBox(height: AppSpacing.sm),
                FloatingActionButton.small(
                  heroTag: 'map-satellite-view',
                  onPressed: () => _toggleSatelliteView(),
                  child: const Icon(Icons.satellite),
                ),
              ],
            ),
          ),

          // Status Indicator
          Positioned(
            bottom: AppSpacing.md,
            left: AppSpacing.md,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _isTrackingEnabled ? Colors.green : Colors.orange,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isTrackingEnabled ? Icons.location_on : Icons.location_off,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _isTrackingEnabled ? 'Live Tracking' : 'Tracking Paused',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapFeatures(ThemeData theme) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        _buildFeatureChip(theme, Icons.location_on, 'Real-time Location'),
        _buildFeatureChip(theme, Icons.route, 'Route Planning'),
        _buildFeatureChip(theme, Icons.group, 'Member Tracking'),
        _buildFeatureChip(theme, Icons.notifications, 'Location Alerts'),
        _buildFeatureChip(theme, Icons.history, 'Location History'),
        _buildFeatureChip(theme, Icons.share_location, 'Share Location'),
      ],
    );
  }

  Widget _buildFeatureChip(ThemeData theme, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

    Widget _buildMemberList(ThemeData theme, Trip trip) {
    return Container(
      height: 100, // Further reduced height to prevent overflow
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // Added to prevent overflow
        children: [
          Row(
            children: [
              Text(
                'Trip Members',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '5 online',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6), // Reduced spacing
          Flexible( // Changed from Expanded to Flexible
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 5,
              itemBuilder: (context, index) {
                final memberNames = ['Aisha Sharma', 'Rahul Kumar', 'Priya Patel', 'Vikram Singh', 'Meera Iyer'];
                final memberName = memberNames[index];
                return Container(
                  width: 80,
                  margin: const EdgeInsets.only(right: AppSpacing.sm),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 18, // Reduced from 20
                            backgroundColor: AppColors.primary,
                            child: Text(
                              memberName.substring(0, 1).toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14, // Reduced font size
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 10, // Reduced from 12
                              height: 10, // Reduced from 12
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: theme.colorScheme.surface,
                                  width: 1.5, // Reduced from 2
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2), // Reduced from 4
                      Flexible( // Added Flexible wrapper
                        child: Text(
                          memberName,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 10, // Reduced font size
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1, // Added maxLines
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showMapOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.layers),
            title: const Text('Map Layers'),
            onTap: () {
              Navigator.pop(context);
              _showMapLayers();
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Map Settings'),
            onTap: () {
              Navigator.pop(context);
              _showMapSettings();
            },
          ),
          ListTile(
            leading: const Icon(Icons.share),
            title: const Text('Share Map'),
            onTap: () {
              Navigator.pop(context);
              _shareMap();
            },
          ),
        ],
      ),
    );
  }

  void _centerOnUser() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Centering on your location...')),
    );
  }

  void _toggleSatelliteView() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Switching to satellite view...')),
    );
  }

  void _showMapLayers() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Map Layers'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: Text('Satellite View'),
              subtitle: Text('Show satellite imagery'),
              value: false,
              onChanged: null,
            ),
            SwitchListTile(
              title: Text('Traffic'),
              subtitle: Text('Show real-time traffic'),
              value: true,
              onChanged: null,
            ),
            SwitchListTile(
              title: Text('Transit'),
              subtitle: Text('Show public transit'),
              value: false,
              onChanged: null,
            ),
            SwitchListTile(
              title: Text('Bicycle'),
              subtitle: Text('Show bicycle routes'),
              value: true,
              onChanged: null,
            ),
            SwitchListTile(
              title: Text('Terrain'),
              subtitle: Text('Show terrain details'),
              value: false,
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
                const SnackBar(content: Text('Map layers updated!')),
              );
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _showMapSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Map Settings'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: Text('Auto-zoom'),
              subtitle: Text('Automatically zoom to fit all members'),
              value: true,
              onChanged: null,
            ),
            SwitchListTile(
              title: Text('Show member names'),
              subtitle: Text('Display member names on map'),
              value: true,
              onChanged: null,
            ),
            SwitchListTile(
              title: Text('Show member photos'),
              subtitle: Text('Display member profile photos'),
              value: false,
              onChanged: null,
            ),
            SwitchListTile(
              title: Text('Location history'),
              subtitle: Text('Show member location history'),
              value: false,
              onChanged: null,
            ),
            SwitchListTile(
              title: Text('Offline maps'),
              subtitle: Text('Download maps for offline use'),
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
                const SnackBar(content: Text('Map settings updated!')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _shareMap() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sharing map...')),
    );
  }
}


