import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import 'models.dart';

class TripRollCallScreen extends ConsumerStatefulWidget {
  final String tripId;

  const TripRollCallScreen({super.key, required this.tripId});

  @override
  ConsumerState<TripRollCallScreen> createState() => _TripRollCallScreenState();
}

class _TripRollCallScreenState extends ConsumerState<TripRollCallScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  List<CheckPoint> _checkPoints = [];
  List<MemberCheckIn> _checkIns = [];
  CheckPoint? _currentCheckPoint;
  bool _isLocationEnabled = false;
  bool _isAutoCheckInEnabled = true;
  Timer? _locationTimer;
  int _totalMembers = 20;
  bool _isTripLeader = true; // Mock: assume current user is trip leader

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _initializeMockData();
    _startLocationTracking();
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _locationTimer?.cancel();
    super.dispose();
  }

  // Mock data for all trip members
  List<Map<String, dynamic>> _allMembers = [];

  void _initializeMockData() {
    // Initialize all trip members
    _allMembers = [
      {'id': 'u_001', 'name': 'Priya Sharma', 'role': 'Leader'},
      {'id': 'u_002', 'name': 'Aisha Khan', 'role': 'Member'},
      {'id': 'u_003', 'name': 'Rohan Patel', 'role': 'Member'},
      {'id': 'u_004', 'name': 'Anjali Singh', 'role': 'Member'},
      {'id': 'u_005', 'name': 'Vikram Gupta', 'role': 'Member'},
      {'id': 'u_006', 'name': 'Neha Joshi', 'role': 'Member'},
      {'id': 'u_007', 'name': 'Arjun Mehta', 'role': 'Member'},
      {'id': 'u_008', 'name': 'Kavya Reddy', 'role': 'Member'},
      {'id': 'u_009', 'name': 'Rahul Kumar', 'role': 'Member'},
      {'id': 'u_010', 'name': 'Pooja Sharma', 'role': 'Member'},
      {'id': 'u_011', 'name': 'Sanjay Patel', 'role': 'Member'},
      {'id': 'u_012', 'name': 'Meera Nair', 'role': 'Member'},
      {'id': 'u_013', 'name': 'Karan Verma', 'role': 'Member'},
      {'id': 'u_014', 'name': 'Riya Agarwal', 'role': 'Member'},
      {'id': 'u_015', 'name': 'Abhishek Rao', 'role': 'Member'},
      {'id': 'u_016', 'name': 'Shreya Das', 'role': 'Member'},
      {'id': 'u_017', 'name': 'Manish Bansal', 'role': 'Member'},
      {'id': 'u_018', 'name': 'Deepika Shah', 'role': 'Member'},
      {'id': 'u_019', 'name': 'Rohit Kapoor', 'role': 'Member'},
      {'id': 'u_020', 'name': 'Ananya Iyer', 'role': 'Member'},
    ];

    _checkPoints = [
      CheckPoint(
        id: 'cp_001',
        name: 'Hotel Departure',
        description: 'Meeting point - Main lobby',
        latitude: 15.5951,
        longitude: 73.8236,
        arrivalTime: DateTime.now().subtract(const Duration(hours: 2)),
        departureTime: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      CheckPoint(
        id: 'cp_002',
        name: 'Baga Beach',
        description: 'Beach activities & lunch',
        latitude: 15.5555,
        longitude: 73.7516,
        radiusMeters: 200.0,
        arrivalTime: DateTime.now().subtract(const Duration(minutes: 30)),
      ),
    ];

    _currentCheckPoint = _checkPoints[1]; // Currently at Baga Beach

    // Mock check-ins for current location (some auto, some manual)
    _checkIns = [
      MemberCheckIn(
        memberId: 'u_001',
        memberName: 'Priya Sharma',
        checkPointId: 'cp_002',
        timestamp: DateTime.now().subtract(const Duration(minutes: 25)),
        isAutomatic: true,
        accuracy: 12.5,
      ),
      MemberCheckIn(
        memberId: 'u_002',
        memberName: 'Aisha Khan',
        checkPointId: 'cp_002',
        timestamp: DateTime.now().subtract(const Duration(minutes: 23)),
        isAutomatic: true,
        accuracy: 8.2,
      ),
      MemberCheckIn(
        memberId: 'u_003',
        memberName: 'Rohan Patel',
        checkPointId: 'cp_002',
        timestamp: DateTime.now().subtract(const Duration(minutes: 20)),
        isAutomatic: false,
        manualNote: 'Late arrival - traffic delay',
      ),
    ];

    setState(() {
      _isLocationEnabled = true;
    });
  }

  void _startLocationTracking() {
    _locationTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted && _isAutoCheckInEnabled && _currentCheckPoint != null) {
        _simulateAutoCheckIn();
      }
    });
  }

  void _simulateAutoCheckIn() {
    // Simulate random members checking in automatically
    final random = Random();
    if (random.nextDouble() < 0.3) { // 30% chance every 10 seconds
      final missingMembers = _totalMembers - _checkIns.where((c) => c.checkPointId == _currentCheckPoint!.id).length;
      if (missingMembers > 0) {
        setState(() {
          _checkIns.add(MemberCheckIn(
            memberId: 'u_${DateTime.now().millisecondsSinceEpoch}',
            memberName: 'Member ${_checkIns.length + 1}',
            checkPointId: _currentCheckPoint!.id,
            timestamp: DateTime.now(),
            isAutomatic: true,
            accuracy: 5.0 + random.nextDouble() * 20,
          ));
        });
      }
    }
  }

  void _showRollCallSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.95,
        minChildSize: 0.6,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: AppSpacing.paddingLg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              
              AppSpacing.verticalSpaceMd,
              
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Roll Call Settings',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    tooltip: 'Close',
                  ),
                ],
              ),
              
              AppSpacing.verticalSpaceMd,
              
              // Auto-detection range settings
              Text(
                'Auto-Detection Range',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              AppSpacing.verticalSpaceSm,
              
              Container(
                padding: AppSpacing.paddingMd,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Range: ${_currentCheckPoint?.radiusMeters.toInt() ?? 100}m',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    AppSpacing.verticalSpaceXs,
                    Text(
                      'Members within this range will be automatically checked in',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
              
              AppSpacing.verticalSpaceMd,
              
              // Range slider
              StatefulBuilder(
                builder: (context, setModalState) {
                  double currentRadius = _currentCheckPoint?.radiusMeters ?? 100.0;
                  
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Range: ${currentRadius.toInt()}m',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _getRangeDescription(currentRadius),
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      AppSpacing.verticalSpaceSm,
                      
                      Slider(
                        value: currentRadius,
                        min: 25.0,
                        max: 500.0,
                        divisions: 19, // 25m to 500m in 25m steps
                        onChanged: (value) {
                          setModalState(() {
                            currentRadius = value;
                          });
                        },
                        onChangeEnd: (value) {
                          _updateCheckPointRadius(value);
                        },
                      ),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '25m',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                          Text(
                            '500m',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
              
              AppSpacing.verticalSpaceMd,
              
              // Auto-check-in toggle
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Auto Check-in',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        AppSpacing.verticalSpaceXs,
                        Text(
                          'Automatically check in members within range',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isAutoCheckInEnabled,
                    onChanged: (value) {
                      setState(() {
                        _isAutoCheckInEnabled = value;
                      });
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
              
              AppSpacing.verticalSpaceMd,
              
              // Preset ranges
              Text(
                'Quick Presets',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              AppSpacing.verticalSpaceMd,
              
              Container(
                padding: AppSpacing.paddingMd,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildPresetChip(context, 50, 'Indoor'),
                        _buildPresetChip(context, 100, 'Small Venue'),
                        _buildPresetChip(context, 200, 'Beach/Park'),
                        _buildPresetChip(context, 300, 'Large Area'),
                        _buildPresetChip(context, 500, 'Wide Range'),
                      ],
                    ),
                    AppSpacing.verticalSpaceMd,
                    Text(
                      'Tap any preset to quickly set the auto-detection range',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              AppSpacing.verticalSpaceMd,
              
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  AppSpacing.horizontalSpaceMd,
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Done'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }

  Widget _buildPresetChip(BuildContext context, double radius, String label) {
    final isSelected = (_currentCheckPoint?.radiusMeters ?? 100.0) == radius;
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: isSelected 
            ? theme.colorScheme.primary 
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected 
              ? theme.colorScheme.primary 
              : theme.colorScheme.outline.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: isSelected ? [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ] : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            _updateCheckPointRadius(radius);
            Navigator.pop(context);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSelected) ...[
                  Icon(
                    Icons.check_circle,
                    size: 16,
                    color: theme.colorScheme.onPrimary,
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  '$label\n(${radius.toInt()}m)',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isSelected 
                        ? theme.colorScheme.onPrimary 
                        : theme.colorScheme.onSurface,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _updateCheckPointRadius(double newRadius) {
    if (_currentCheckPoint != null) {
      setState(() {
        _checkPoints = _checkPoints.map((cp) {
          if (cp.id == _currentCheckPoint!.id) {
            return CheckPoint(
              id: cp.id,
              name: cp.name,
              description: cp.description,
              latitude: cp.latitude,
              longitude: cp.longitude,
              radiusMeters: newRadius,
              arrivalTime: cp.arrivalTime,
              departureTime: cp.departureTime,
              isOptional: cp.isOptional,
            );
          }
          return cp;
        }).toList();
        
        _currentCheckPoint = _checkPoints.firstWhere((cp) => cp.id == _currentCheckPoint!.id);
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Auto-detection range updated to ${newRadius.toInt()}m'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  String _getRangeDescription(double radius) {
    if (radius <= 50) return 'Indoor';
    if (radius <= 100) return 'Small Venue';
    if (radius <= 200) return 'Beach/Park';
    if (radius <= 300) return 'Large Area';
    return 'Wide Range';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentCheckIns = _checkIns.where((c) => c.checkPointId == _currentCheckPoint?.id).toList();
    final checkedInCount = currentCheckIns.length;
    final missingCount = _totalMembers - checkedInCount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Roll Call Ranger'),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [
          if (_isTripLeader) ...[
            IconButton(
              onPressed: () => _showRollCallSettings(context),
              icon: const Icon(Icons.settings),
              tooltip: 'Roll Call Settings',
            ),
          ],
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _simulateAutoCheckIn();
          await Future.delayed(const Duration(seconds: 1));
        },
        child: ListView(
          padding: AppSpacing.paddingMd,
          children: [
            // Current Location Status
            _buildCurrentLocationCard(theme),
            
            AppSpacing.verticalSpaceMd,
            
            // Check-in Progress
            _buildProgressCard(theme, checkedInCount, missingCount),
            
            AppSpacing.verticalSpaceMd,
            
            // Quick Actions
            _buildQuickActionsCard(theme),
            
            AppSpacing.verticalSpaceMd,
            
            // Member Status List
            _buildMemberStatusCard(theme, currentCheckIns),
            
            AppSpacing.verticalSpaceXxl,
          ],
        ),
      ),
      floatingActionButton: missingCount > 0 ? FloatingActionButton.extended(
        onPressed: () => _showMissingMembersDialog(currentCheckIns),
        icon: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: const Icon(Icons.person_search),
            );
          },
        ),
        label: Text('$missingCount Missing'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ) : FloatingActionButton.extended(
        onPressed: () => _showAllPresentDialog(),
        icon: const Icon(Icons.check_circle),
        label: const Text('All Present'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildCurrentLocationCard(ThemeData theme) {
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
                    color: _isLocationEnabled ? Colors.green : Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                AppSpacing.horizontalSpaceXs,
                Text(
                  'Current Stop',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_isAutoCheckInEnabled)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.my_location,
                          size: 14,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                        AppSpacing.horizontalSpaceXs,
                        Text(
                          'Auto Check-in',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            
            AppSpacing.verticalSpaceSm,
            
            if (_currentCheckPoint != null) ...[
              Text(
                _currentCheckPoint!.name,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              AppSpacing.verticalSpaceXs,
              
              Text(
                _currentCheckPoint!.description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard(ThemeData theme, int checkedIn, int missing) {
    final progress = checkedIn / _totalMembers;
    
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
                  'Check-in Progress',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '$checkedIn / $_totalMembers',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: missing == 0 ? Colors.green : theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            
            AppSpacing.verticalSpaceSm,
            
            LinearProgressIndicator(
              value: progress,
              backgroundColor: theme.colorScheme.surfaceContainerHigh,
              valueColor: AlwaysStoppedAnimation(
                missing == 0 ? Colors.green : theme.colorScheme.primary,
              ),
            ),
            
            AppSpacing.verticalSpaceSm,
            
            Text(
              '${(progress * 100).toInt()}% checked in',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: missing == 0 ? Colors.green : theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsCard(ThemeData theme) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: AppSpacing.paddingMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            AppSpacing.verticalSpaceSm,
            
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _showManualCheckInDialog(),
                    icon: const Icon(Icons.person_add, size: 18),
                    label: const Text('Manual Check-in'),
                  ),
                ),
                AppSpacing.horizontalSpaceSm,
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _sendReminderNotification(),
                    icon: const Icon(Icons.notifications, size: 18),
                    label: const Text('Send Reminder'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberStatusCard(ThemeData theme, List<MemberCheckIn> checkIns) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: AppSpacing.paddingMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Check-ins',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            AppSpacing.verticalSpaceSm,
            
            if (checkIns.isEmpty)
              Container(
                padding: AppSpacing.paddingLg,
                child: Column(
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 48,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    AppSpacing.verticalSpaceSm,
                    Text(
                      'No check-ins yet',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              )
            else
              ...checkIns.take(10).map((checkIn) => _buildMemberCheckInTile(checkIn, theme)),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberCheckInTile(MemberCheckIn checkIn, ThemeData theme) {
    final isRecent = DateTime.now().difference(checkIn.timestamp).inMinutes < 5;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isRecent ? Colors.green : theme.colorScheme.outline,
              shape: BoxShape.circle,
            ),
          ),
          
          AppSpacing.horizontalSpaceSm,
          
          CircleAvatar(
            radius: 16,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Text(
              checkIn.memberName.substring(0, 1).toUpperCase(),
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          AppSpacing.horizontalSpaceSm,
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  checkIn.memberName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (checkIn.manualNote != null)
                  Text(
                    checkIn.manualNote!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
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
                    checkIn.isAutomatic ? Icons.my_location : Icons.person,
                    size: 14,
                    color: checkIn.isAutomatic ? Colors.green : Colors.blue,
                  ),
                  AppSpacing.horizontalSpaceXs,
                  Text(
                    checkIn.isAutomatic ? 'Auto' : 'Manual',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: checkIn.isAutomatic ? Colors.green : Colors.blue,
                    ),
                  ),
                ],
              ),
              Text(
                _formatTime(checkIn.timestamp),
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

  void _showMissingMembersDialog(List<MemberCheckIn> currentCheckIns) {
    final missingCount = _totalMembers - currentCheckIns.length;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$missingCount Missing Members'),
        content: Text('${currentCheckIns.length} members have checked in.\n$missingCount members are still missing from ${_currentCheckPoint?.name}.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('📢 Reminder sent to missing members')),
              );
            },
            child: const Text('Send Reminder'),
          ),
        ],
      ),
    );
  }

  void _showAllPresentDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🎉 All Members Present!'),
        content: const Text('Everyone has successfully checked in at this location.'),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Great!'),
          ),
        ],
      ),
    );
  }

  void _showManualCheckInDialog() {
    if (_currentCheckPoint == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No active checkpoint selected')),
      );
      return;
    }

    // Get members who haven't checked in yet
    final currentCheckIns = _checkIns.where((c) => c.checkPointId == _currentCheckPoint!.id).toList();
    final checkedInIds = currentCheckIns.map((c) => c.memberId).toSet();
    final missingMembers = _allMembers.where((member) => !checkedInIds.contains(member['id'])).toList();

    if (missingMembers.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('🎉 All Present!'),
          content: const Text('All members have already checked in at this location.'),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Great!'),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Manual Check-in (${missingMembers.length} missing)'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: Column(
            children: [
              Container(
                padding: AppSpacing.paddingMd,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      size: 20,
                    ),
                    AppSpacing.horizontalSpaceXs,
                    Expanded(
                      child: Text(
                        'Select members who are present but not auto-detected. Each member can only be checked in once.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              AppSpacing.verticalSpaceMd,
              
              Expanded(
                child: ListView.builder(
                  itemCount: missingMembers.length,
                  itemBuilder: (context, index) {
                    final member = missingMembers[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                          child: Text(
                            member['name'].substring(0, 1).toUpperCase(),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(member['name']),
                        subtitle: Text(member['role']),
                        trailing: FilledButton.icon(
                          onPressed: () => _performManualCheckIn(member),
                          icon: const Icon(Icons.check, size: 16),
                          label: const Text('Check In'),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(80, 32),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          OutlinedButton.icon(
            onPressed: () => _showBulkCheckInDialog(missingMembers),
            icon: const Icon(Icons.group_add, size: 16),
            label: const Text('Check All'),
          ),
        ],
      ),
    );
  }

  void _performManualCheckIn(Map<String, dynamic> member) {
    // Check if already checked in (double protection)
    final currentCheckIns = _checkIns.where((c) => c.checkPointId == _currentCheckPoint!.id).toList();
    final isAlreadyCheckedIn = currentCheckIns.any((c) => c.memberId == member['id']);
    
    if (isAlreadyCheckedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${member['name']} is already checked in!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show note dialog for manual check-in
    showDialog(
      context: context,
      builder: (context) {
        String note = '';
        return AlertDialog(
          title: Text('Check in ${member['name']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Add an optional note for this manual check-in:'),
              AppSpacing.verticalSpaceMd,
              TextField(
                decoration: const InputDecoration(
                  hintText: 'e.g., "GPS not working", "Phone battery dead"',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
                onChanged: (value) => note = value,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                _addManualCheckIn(member, note.isEmpty ? null : note);
                Navigator.of(context).pop(); // Close note dialog
                Navigator.of(context).pop(); // Close member list dialog
              },
              child: const Text('Check In'),
            ),
          ],
        );
      },
    );
  }

  void _addManualCheckIn(Map<String, dynamic> member, String? note) {
    setState(() {
      _checkIns.add(MemberCheckIn(
        memberId: member['id'],
        memberName: member['name'],
        checkPointId: _currentCheckPoint!.id,
        timestamp: DateTime.now(),
        isAutomatic: false,
        manualNote: note ?? 'Manual check-in by leader',
      ));
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ ${member['name']} checked in manually'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showBulkCheckInDialog(List<Map<String, dynamic>> missingMembers) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bulk Check-in'),
        content: Text('Check in all ${missingMembers.length} missing members at once?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              // Bulk check-in all missing members
              setState(() {
                for (final member in missingMembers) {
                  _checkIns.add(MemberCheckIn(
                    memberId: member['id'],
                    memberName: member['name'],
                    checkPointId: _currentCheckPoint!.id,
                    timestamp: DateTime.now(),
                    isAutomatic: false,
                    manualNote: 'Bulk check-in by leader',
                  ));
                }
              });
              
              Navigator.of(context).pop(); // Close bulk dialog
              Navigator.of(context).pop(); // Close member list dialog
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('✅ ${missingMembers.length} members checked in'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Check All'),
          ),
        ],
      ),
    );
  }

  void _sendReminderNotification() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📢 Reminder sent to all missing members'),
        backgroundColor: Colors.blue,
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
    } else {
      return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
}