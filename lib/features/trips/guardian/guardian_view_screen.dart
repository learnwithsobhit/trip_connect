import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/models/models.dart';
import '../../../core/theme/app_spacing.dart';

class GuardianViewScreen extends ConsumerStatefulWidget {
  final String tripId;
  final String? guardianToken; // For secure access without full account

  const GuardianViewScreen({
    super.key,
    required this.tripId,
    this.guardianToken,
  });

  @override
  ConsumerState<GuardianViewScreen> createState() => _GuardianViewScreenState();
}

class _GuardianViewScreenState extends ConsumerState<GuardianViewScreen>
    with TickerProviderStateMixin {
  late AnimationController _refreshController;
  late Animation<double> _refreshAnimation;
  
  // Mock trip data for guardian view
  Trip? _trip;
  List<Map<String, dynamic>> _memberLocations = [];
  String? _currentStatus;
  DateTime? _lastUpdate;
  String? _nextDestination;
  String? _estimatedArrival;

  @override
  void initState() {
    super.initState();
    _refreshController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _refreshAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _refreshController, curve: Curves.easeInOut),
    );
    
    _loadTripData();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  void _loadTripData() async {
    // Mock trip data loading
    await Future.delayed(const Duration(milliseconds: 800));
    
    if (mounted) {
      setState(() {
        _trip = Trip(
          id: widget.tripId,
          name: 'Goa Monsoon Adventure 🌊',
          theme: 'Beach & Food',
          origin: Location(name: 'Mumbai', lat: 19.0760, lng: 72.8777),
          destination: Location(name: 'Goa', lat: 15.2993, lng: 74.1240),
          startDate: DateTime.now().subtract(const Duration(days: 2)),
          endDate: DateTime.now().add(const Duration(days: 3)),
          seatsTotal: 20,
          seatsAvailable: 6,
          leaderId: 'leader_id',
          invite: TripInvite(code: 'TC123ABC', qr: 'QR_CODE_DATA'),
          status: TripStatus.active,
        );
        
        _memberLocations = [
          {
            'name': 'Priya (Leader)',
            'location': 'Baga Beach, Goa',
            'distance': '0.2 km from group',
            'lastSeen': DateTime.now().subtract(const Duration(minutes: 2)),
            'status': 'active',
            'battery': 85,
          },
          {
            'name': 'Aisha',
            'location': 'Shack Restaurant, Baga',
            'distance': '0.1 km from group',
            'lastSeen': DateTime.now().subtract(const Duration(minutes: 1)),
            'status': 'active',
            'battery': 72,
          },
          {
            'name': 'Rohan',
            'location': 'Parking Area',
            'distance': '0.3 km from group',
            'lastSeen': DateTime.now().subtract(const Duration(minutes: 5)),
            'status': 'active',
            'battery': 45,
          },
        ];
        
        _currentStatus = 'At Baga Beach - Lunch Break';
        _lastUpdate = DateTime.now().subtract(const Duration(minutes: 1));
        _nextDestination = 'Anjuna Beach';
        _estimatedArrival = '3:30 PM';
      });
    }
  }

  void _startAutoRefresh() {
    // Refresh every 30 seconds for live updates
    Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _refreshData();
      } else {
        timer.cancel();
      }
    });
  }

  void _refreshData() async {
    _refreshController.forward();
    
    // Simulate data refresh
    await Future.delayed(const Duration(seconds: 1));
    
    if (mounted) {
      setState(() {
        _lastUpdate = DateTime.now();
        // Update some member locations slightly
        for (var member in _memberLocations) {
          member['lastSeen'] = DateTime.now().subtract(
            Duration(minutes: (member['lastSeen'] as DateTime)
                .difference(DateTime.now()).inMinutes.abs() % 10)
          );
        }
      });
      
      _refreshController.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Trip Guardian View'),
            if (_trip != null)
              Text(
                _trip!.name,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        leading: IconButton(
          onPressed: () => context.go('/'),
          icon: const Icon(Icons.close),
        ),
        actions: [
          AnimatedBuilder(
            animation: _refreshAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _refreshAnimation.value * 2 * 3.14159,
                child: IconButton(
                  onPressed: _refreshData,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh Status',
                ),
              );
            },
          ),
          IconButton(
            onPressed: () => _showHelpDialog(),
            icon: const Icon(Icons.help_outline),
            tooltip: 'Help',
          ),
        ],
      ),
      body: _trip == null 
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async => _refreshData(),
              child: ListView(
                padding: AppSpacing.paddingMd,
                children: [
                  // Status Overview Card
                  _buildStatusCard(theme),
                  
                  AppSpacing.verticalSpaceMd,
                  
                  // Trip Progress Card
                  _buildProgressCard(theme),
                  
                  AppSpacing.verticalSpaceMd,
                  
                  // Members Location Card
                  _buildMembersCard(theme),
                  
                  AppSpacing.verticalSpaceMd,
                  
                  // Next Destination Card
                  _buildNextDestinationCard(theme),
                  
                  AppSpacing.verticalSpaceMd,
                  
                  // Safety Information Card
                  _buildSafetyCard(theme),
                  
                  AppSpacing.verticalSpaceXxl,
                ],
              ),
            ),
    );
  }

  Widget _buildStatusCard(ThemeData theme) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: AppSpacing.paddingMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                AppSpacing.horizontalSpaceXs,
                Text(
                  'Trip Active',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.verified_user,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
              ],
            ),
            
            AppSpacing.verticalSpaceSm,
            
            Text(
              _currentStatus ?? 'Status unknown',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            
            AppSpacing.verticalSpaceXs,
            
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                AppSpacing.horizontalSpaceXs,
                Text(
                  'Last update: ${_formatTime(_lastUpdate)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard(ThemeData theme) {
    final daysPassed = DateTime.now().difference(_trip!.startDate).inDays;
    final totalDays = _trip!.endDate.difference(_trip!.startDate).inDays;
    final progress = daysPassed / totalDays;
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: AppSpacing.paddingMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Trip Progress',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            AppSpacing.verticalSpaceSm,
            
            LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: theme.colorScheme.surfaceContainerHigh,
              valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
            ),
            
            AppSpacing.verticalSpaceXs,
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Day ${daysPassed + 1} of ${totalDays + 1}',
                  style: theme.textTheme.bodySmall,
                ),
                Text(
                  '${((progress * 100).clamp(0, 100)).toInt()}% complete',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMembersCard(ThemeData theme) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: AppSpacing.paddingMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Group Members',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_memberLocations.length} members',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            
            AppSpacing.verticalSpaceSm,
            
            ..._memberLocations.map((member) => _buildMemberTile(member, theme)),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberTile(Map<String, dynamic> member, ThemeData theme) {
    final isLowBattery = member['battery'] < 50;
    final lastSeen = member['lastSeen'] as DateTime;
    final isRecent = DateTime.now().difference(lastSeen).inMinutes < 5;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isRecent ? Colors.green : Colors.orange,
              shape: BoxShape.circle,
            ),
          ),
          
          AppSpacing.horizontalSpaceSm,
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member['name'],
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  member['location'],
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.battery_full,
                    size: 16,
                    color: isLowBattery ? Colors.red : Colors.green,
                  ),
                  Text(
                    '${member['battery']}%',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isLowBattery ? Colors.red : null,
                    ),
                  ),
                ],
              ),
              Text(
                _formatTime(lastSeen),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNextDestinationCard(ThemeData theme) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: AppSpacing.paddingMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: theme.colorScheme.primary,
                ),
                AppSpacing.horizontalSpaceSm,
                Text(
                  'Next Destination',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            AppSpacing.verticalSpaceSm,
            
            Text(
              _nextDestination ?? 'Unknown',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            
            AppSpacing.verticalSpaceXs,
            
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                AppSpacing.horizontalSpaceXs,
                Text(
                  'Expected arrival: $_estimatedArrival',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSafetyCard(ThemeData theme) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: AppSpacing.paddingMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.security,
                  color: theme.colorScheme.primary,
                ),
                AppSpacing.horizontalSpaceSm,
                Text(
                  'Safety Information',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            AppSpacing.verticalSpaceSm,
            
            Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 16,
                ),
                AppSpacing.horizontalSpaceXs,
                Text(
                  'All members checked in at last stop',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            
            AppSpacing.verticalSpaceXs,
            
            Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 16,
                ),
                AppSpacing.horizontalSpaceXs,
                Text(
                  'Emergency contacts available',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            
            AppSpacing.verticalSpaceXs,
            
            Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 16,
                ),
                AppSpacing.horizontalSpaceXs,
                Text(
                  'Real-time location sharing active',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            
            AppSpacing.verticalSpaceMd,
            
            Container(
              padding: AppSpacing.paddingMd,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info,
                    color: theme.colorScheme.onPrimaryContainer,
                    size: 20,
                  ),
                  AppSpacing.horizontalSpaceSm,
                  Expanded(
                    child: Text(
                      'This is a read-only view. No personal data or chat messages are accessible.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Guardian View Help'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'This view allows you to monitor trip progress and member safety without accessing personal conversations.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              
              AppSpacing.verticalSpaceMd,
              
              Text(
                'Features:',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              AppSpacing.verticalSpaceXs,
              
              const Text('• Real-time location updates'),
              const Text('• Trip progress tracking'),
              const Text('• Member check-in status'),
              const Text('• Battery level monitoring'),
              const Text('• Safety notifications'),
              
              AppSpacing.verticalSpaceMd,
              
              Container(
                padding: AppSpacing.paddingMd,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Privacy Protected',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    AppSpacing.verticalSpaceXs,
                    const Text(
                      'Chat messages, photos, and personal details are not visible in this view.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return 'Unknown';
    
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${dateTime.day}/${dateTime.month} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
}


