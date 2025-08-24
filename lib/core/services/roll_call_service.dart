import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';

import '../data/models/models.dart';
import 'location_service.dart';
import 'notification_service.dart';
import 'mock_server.dart';

class RollCallService {
  static final RollCallService _instance = RollCallService._internal();
  factory RollCallService() => _instance;
  RollCallService._internal();

  final _uuid = const Uuid();
  final LocationService _locationService = LocationService();
  final NotificationService _notificationService = NotificationService();

  // Active roll calls
  final Map<String, RollCall> _activeRollCalls = {};
  final Map<String, Timer> _graceTimers = {};
  final Map<String, StreamSubscription<Position>> _locationSubscriptions = {};

  // Stream controllers for real-time updates
  final Map<String, StreamController<RollCall>> _rollCallControllers = {};
  final Map<String, StreamController<RollCallCheckIn>> _checkInControllers = {};

  // Settings
  RollCallSettings _settings = const RollCallSettings();
  bool _isInitialized = false;

  // Getters
  Map<String, RollCall> get activeRollCalls {
    // Initialize if not already done
    if (!_isInitialized) {
      _initializeMockData();
      _isInitialized = true;
    }
    return Map.unmodifiable(_activeRollCalls);
  }
  RollCallSettings get settings => _settings;

  // Initialize the service
  Future<void> initialize() async {
    print('RollCallService: Initializing...');
    await _locationService.initialize();
    await _notificationService.initialize();
    
    // Initialize with mock data for demo
    _initializeMockData();
    print('RollCallService: Initialization complete. Active roll calls: ${_activeRollCalls.length}');
  }

  // Initialize mock data for demo purposes
  void _initializeMockData() {
    // Create a test roll call for demo
    final testRollCall = RollCall(
      id: 'test_roll_call_${DateTime.now().millisecondsSinceEpoch}',
      tripId: 't_001', // Goa Monsoon Adventure
      leaderId: 'u_leader',
      startedAt: DateTime.now().subtract(const Duration(minutes: 2)),
      status: RollCallStatus.active,
      anchorLocation: RollCallLocation(
        lat: 15.2993, // Goa coordinates
        lng: 74.1240,
        timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
        accuracy: 5.0,
        bearing: 0.0,
        speed: 0.0,
      ),
      radiusMeters: 50.0,
      gracePeriodMinutes: 5,
      anchorName: 'Beach Meeting Point',
      allowManualCheckIn: true,
      announceOnClose: true,
      auditLog: [
        RollCallAuditLog(
          timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
          userId: 'u_leader',
          action: RollCallAuditAction.started,
          details: {
            'radius': 50.0,
            'gracePeriod': 5,
            'anchorName': 'Beach Meeting Point',
          },
        ),
      ],
      checkIns: [
        // Add some test check-ins
        RollCallCheckIn(
          userId: 'u_leader',
          checkedInAt: DateTime.now().subtract(const Duration(minutes: 1, seconds: 30)),
          method: CheckInMethod.gps,
          status: RollCallCheckInStatus.present,
          distanceFromAnchor: 15.0,
        ),
        RollCallCheckIn(
          userId: 'u_123',
          checkedInAt: DateTime.now().subtract(const Duration(minutes: 1)),
          method: CheckInMethod.manual,
          status: RollCallCheckInStatus.present,
          manualReason: 'GPS not working',
        ),
      ],
    );
    
    _activeRollCalls[testRollCall.id] = testRollCall;
  }

  // Start a new roll call
  Future<RollCall> startRollCall({
    required String tripId,
    required String leaderId,
    RollCallLocation? anchorLocation,
    double? radiusMeters,
    int? gracePeriodMinutes,
    String? anchorName,
    bool? allowManualCheckIn,
    bool? announceOnClose,
  }) async {
    // Get leader's current location if not provided
    final location = anchorLocation ?? await _getCurrentLocation();
    if (location == null) {
      throw Exception('Unable to get current location');
    }

    final rollCall = RollCall(
      id: _uuid.v4(),
      tripId: tripId,
      leaderId: leaderId,
      startedAt: DateTime.now(),
      status: RollCallStatus.active,
      anchorLocation: location,
      radiusMeters: radiusMeters ?? _settings.defaultRadiusMeters,
      gracePeriodMinutes: gracePeriodMinutes ?? _settings.defaultGracePeriodMinutes,
      anchorName: anchorName ?? 'Current Location',
      allowManualCheckIn: allowManualCheckIn ?? _settings.allowManualCheckIn,
      announceOnClose: announceOnClose ?? _settings.announceOnClose,
      auditLog: [
        RollCallAuditLog(
          timestamp: DateTime.now(),
          userId: leaderId,
          action: RollCallAuditAction.started,
          details: {
            'radius': radiusMeters ?? _settings.defaultRadiusMeters,
            'gracePeriod': gracePeriodMinutes ?? _settings.defaultGracePeriodMinutes,
            'anchorName': anchorName ?? 'Current Location',
          },
        ),
      ],
    );

    _activeRollCalls[rollCall.id] = rollCall;
    _startGraceTimer(rollCall);
    _startLocationTracking(rollCall);
    _notifyRollCallStarted(rollCall);

    // Emit to stream
    _getRollCallStream(rollCall.id).add(rollCall);

    return rollCall;
  }

  // Check in to a roll call
  Future<RollCallCheckIn> checkIn({
    required String rollCallId,
    required String userId,
    CheckInMethod method = CheckInMethod.gps,
    String? manualReason,
    String? markedByLeaderId,
  }) async {
    final rollCall = _activeRollCalls[rollCallId];
    if (rollCall == null) {
      throw Exception('Roll call not found or not active');
    }

    if (rollCall.status != RollCallStatus.active) {
      throw Exception('Roll call is not active');
    }

    RollCallLocation? location;
    double? distanceFromAnchor;
    bool? isWithinRadius;

    // Get location and calculate distance for GPS check-ins
    if (method == CheckInMethod.gps) {
      location = await _getCurrentLocation();
      if (location != null) {
        distanceFromAnchor = _calculateDistance(location, rollCall.anchorLocation);
        isWithinRadius = distanceFromAnchor <= rollCall.radiusMeters;
      }
    }

    final checkIn = RollCallCheckIn(
      userId: userId,
      checkedInAt: DateTime.now(),
      method: method,
      location: location,
      distanceFromAnchor: distanceFromAnchor,
      isWithinRadius: isWithinRadius,
      manualReason: manualReason,
      markedByLeaderId: markedByLeaderId,
      status: _determineCheckInStatus(rollCall, method, isWithinRadius),
    );

    // Add to roll call
    final updatedRollCall = rollCall.copyWith(
      checkIns: [...rollCall.checkIns, checkIn],
      auditLog: [
        ...rollCall.auditLog,
        RollCallAuditLog(
          timestamp: DateTime.now(),
          userId: userId,
          action: RollCallAuditAction.checkedIn,
          details: {
            'method': method.name,
            'distance': distanceFromAnchor,
            'withinRadius': isWithinRadius,
            'manualReason': manualReason,
          },
        ),
      ],
    );

    _activeRollCalls[rollCallId] = updatedRollCall;

    // Emit updates
    _getRollCallStream(rollCallId).add(updatedRollCall);
    _getCheckInStream(rollCallId).add(checkIn);

    return checkIn;
  }

  // Mark someone present/absent (leader only)
  Future<RollCallCheckIn> markMember({
    required String rollCallId,
    required String userId,
    required RollCallCheckInStatus status,
    required String leaderId,
    String? reason,
  }) async {
    final rollCall = _activeRollCalls[rollCallId];
    if (rollCall == null) {
      throw Exception('Roll call not found or not active');
    }

    if (rollCall.leaderId != leaderId) {
      throw Exception('Only the roll call leader can mark members');
    }

    final checkIn = RollCallCheckIn(
      userId: userId,
      checkedInAt: DateTime.now(),
      method: CheckInMethod.leaderMarked,
      status: status,
      markedByLeaderId: leaderId,
      manualReason: reason,
    );

    // Add to roll call
    final updatedRollCall = rollCall.copyWith(
      checkIns: [...rollCall.checkIns, checkIn],
      auditLog: [
        ...rollCall.auditLog,
        RollCallAuditLog(
          timestamp: DateTime.now(),
          userId: leaderId,
          action: status == RollCallCheckInStatus.present 
              ? RollCallAuditAction.markedPresent 
              : RollCallAuditAction.markedAbsent,
          details: {
            'targetUserId': userId,
            'status': status.name,
            'reason': reason,
          },
        ),
      ],
    );

    _activeRollCalls[rollCallId] = updatedRollCall;

    // Emit updates
    _getRollCallStream(rollCallId).add(updatedRollCall);
    _getCheckInStream(rollCallId).add(checkIn);

    return checkIn;
  }

  // Send reminder to missing members
  Future<void> sendReminder({
    required String rollCallId,
    required String leaderId,
  }) async {
    final rollCall = _activeRollCalls[rollCallId];
    if (rollCall == null) {
      throw Exception('Roll call not found or not active');
    }

    if (rollCall.leaderId != leaderId) {
      throw Exception('Only the roll call leader can send reminders');
    }

    final missingUserIds = _getMissingUserIds(rollCall);
    
    // Send notifications to missing members
    for (final userId in missingUserIds) {
      await _notificationService.showRollCallReminder(
        userId: userId,
        tripId: rollCall.tripId,
        rollCallId: rollCall.id,
        anchorLocation: rollCall.anchorLocation,
        anchorName: rollCall.anchorName ?? 'Roll Call Location',
      );
    }

    // Send chat message with roll call location
    await _sendRollCallReminderMessage(rollCall, missingUserIds.length);

    // Update audit log
    final updatedRollCall = rollCall.copyWith(
      auditLog: [
        ...rollCall.auditLog,
        RollCallAuditLog(
          timestamp: DateTime.now(),
          userId: leaderId,
          action: RollCallAuditAction.sentReminder,
          details: {
            'missingCount': missingUserIds.length,
            'missingUserIds': missingUserIds,
          },
        ),
      ],
    );

    _activeRollCalls[rollCallId] = updatedRollCall;
    _getRollCallStream(rollCallId).add(updatedRollCall);
  }

  // Send roll call reminder message to chat
  Future<void> _sendRollCallReminderMessage(RollCall rollCall, int missingCount) async {
    try {
      // Add roll call reminder message to chat using MockServer
      final mockServer = MockServer();
      await mockServer.addRollCallReminderMessage(
        tripId: rollCall.tripId,
        senderId: rollCall.leaderId,
        anchorName: rollCall.anchorName ?? 'Current Location',
        lat: rollCall.anchorLocation.lat,
        lng: rollCall.anchorLocation.lng,
        missingCount: missingCount,
        gracePeriodMinutes: rollCall.gracePeriodMinutes,
      );

      print('Roll call reminder message sent to chat for trip: ${rollCall.tripId}');
    } catch (e) {
      print('Error sending roll call reminder message: $e');
    }
  }

  // Extend grace period
  Future<RollCall> extendGracePeriod({
    required String rollCallId,
    required String leaderId,
    required int additionalMinutes,
  }) async {
    final rollCall = _activeRollCalls[rollCallId];
    if (rollCall == null) {
      throw Exception('Roll call not found or not active');
    }

    if (rollCall.leaderId != leaderId) {
      throw Exception('Only the roll call leader can extend grace period');
    }

    final updatedRollCall = rollCall.copyWith(
      gracePeriodMinutes: rollCall.gracePeriodMinutes + additionalMinutes,
      auditLog: [
        ...rollCall.auditLog,
        RollCallAuditLog(
          timestamp: DateTime.now(),
          userId: leaderId,
          action: RollCallAuditAction.extended,
          details: {
            'additionalMinutes': additionalMinutes,
            'newGracePeriod': rollCall.gracePeriodMinutes + additionalMinutes,
          },
        ),
      ],
    );

    _activeRollCalls[rollCallId] = updatedRollCall;
    _restartGraceTimer(updatedRollCall);
    _getRollCallStream(rollCallId).add(updatedRollCall);

    return updatedRollCall;
  }

  // Close roll call
  Future<RollCall> closeRollCall({
    required String rollCallId,
    required String leaderId,
    String? closeMessage,
  }) async {
    final rollCall = _activeRollCalls[rollCallId];
    if (rollCall == null) {
      throw Exception('Roll call not found or not active');
    }

    if (rollCall.leaderId != leaderId) {
      throw Exception('Only the roll call leader can close roll call');
    }

    final updatedRollCall = rollCall.copyWith(
      endedAt: DateTime.now(),
      status: RollCallStatus.completed,
      closeMessage: closeMessage,
      auditLog: [
        ...rollCall.auditLog,
        RollCallAuditLog(
          timestamp: DateTime.now(),
          userId: leaderId,
          action: RollCallAuditAction.closed,
          details: {
            'closeMessage': closeMessage,
            'finalPresentCount': _getPresentCount(rollCall),
            'finalMissingCount': _getMissingCount(rollCall),
          },
        ),
      ],
    );

    _activeRollCalls.remove(rollCallId);
    _stopGraceTimer(rollCallId);
    _stopLocationTracking(rollCallId);
    _notifyRollCallClosed(updatedRollCall);

    // Emit final update
    _getRollCallStream(rollCallId).add(updatedRollCall);

    return updatedRollCall;
  }

  // Cancel roll call
  Future<RollCall> cancelRollCall({
    required String rollCallId,
    required String leaderId,
    String? reason,
  }) async {
    final rollCall = _activeRollCalls[rollCallId];
    if (rollCall == null) {
      throw Exception('Roll call not found or not active');
    }

    if (rollCall.leaderId != leaderId) {
      throw Exception('Only the roll call leader can cancel roll call');
    }

    final updatedRollCall = rollCall.copyWith(
      endedAt: DateTime.now(),
      status: RollCallStatus.cancelled,
      auditLog: [
        ...rollCall.auditLog,
        RollCallAuditLog(
          timestamp: DateTime.now(),
          userId: leaderId,
          action: RollCallAuditAction.cancelled,
          reason: reason,
        ),
      ],
    );

    _activeRollCalls.remove(rollCallId);
    _stopGraceTimer(rollCallId);
    _stopLocationTracking(rollCallId);
    _notifyRollCallCancelled(updatedRollCall);

    // Emit final update
    _getRollCallStream(rollCallId).add(updatedRollCall);

    return updatedRollCall;
  }

  // Get roll call by ID
  RollCall? getRollCall(String rollCallId) {
    return _activeRollCalls[rollCallId];
  }

  // Get roll call stream
  Stream<RollCall> getRollCallStream(String rollCallId) {
    return _getRollCallStream(rollCallId).stream;
  }

  // Get check-in stream
  Stream<RollCallCheckIn> getCheckInStream(String rollCallId) {
    return _getCheckInStream(rollCallId).stream;
  }

  // Update settings
  void updateSettings(RollCallSettings settings) {
    _settings = settings;
  }

  // Generate roll call report
  RollCallReport generateReport(String rollCallId) {
    final rollCall = _activeRollCalls[rollCallId];
    if (rollCall == null) {
      throw Exception('Roll call not found');
    }

    final methodBreakdown = <CheckInMethod, int>{};
    final responseTimes = <String, Duration>{};
    final missingUserIds = _getMissingUserIds(rollCall);
    final lateUserIds = _getLateUserIds(rollCall);

    // Calculate method breakdown
    for (final checkIn in rollCall.checkIns) {
      methodBreakdown[checkIn.method] = (methodBreakdown[checkIn.method] ?? 0) + 1;
    }

    // Calculate response times
    for (final checkIn in rollCall.checkIns) {
      final responseTime = checkIn.checkedInAt.difference(rollCall.startedAt);
      responseTimes[checkIn.userId] = responseTime;
    }

    return RollCallReport(
      rollCallId: rollCallId,
      generatedAt: DateTime.now(),
      totalMembers: _getTotalMemberCount(rollCall),
      presentCount: _getPresentCount(rollCall),
      missingCount: missingUserIds.length,
      completionTime: rollCall.endedAt?.difference(rollCall.startedAt) ?? Duration.zero,
      methodBreakdown: methodBreakdown,
      missingUserIds: missingUserIds,
      lateUserIds: lateUserIds,
      responseTimes: responseTimes,
      escalationCount: _getEscalationCount(rollCall),
      auditTrail: rollCall.auditLog,
    );
  }

  // Helper methods
  Future<RollCallLocation?> _getCurrentLocation() async {
    try {
      final position = await _locationService.getCurrentPosition();
      if (position != null) {
        return RollCallLocation(
          lat: position.latitude,
          lng: position.longitude,
          timestamp: DateTime.now(),
          accuracy: position.accuracy,
        );
      }
    } catch (e) {
      debugPrint('Error getting current location: $e');
      // Return a default location if current location fails
      return RollCallLocation(
        lat: 20.5937, // India center
        lng: 78.9629,
        timestamp: DateTime.now(),
        accuracy: 1000.0,
      );
    }
    return null;
  }

  double _calculateDistance(RollCallLocation location1, RollCallLocation location2) {
    return Geolocator.distanceBetween(
      location1.lat,
      location1.lng,
      location2.lat,
      location2.lng,
    );
  }

  RollCallCheckInStatus _determineCheckInStatus(
    RollCall rollCall,
    CheckInMethod method,
    bool? isWithinRadius,
  ) {
    if (method == CheckInMethod.leaderMarked) {
      return RollCallCheckInStatus.present; // Leader marks are always present
    }

    if (method == CheckInMethod.gps && isWithinRadius == true) {
      return RollCallCheckInStatus.present;
    }

    if (method == CheckInMethod.manual) {
      return RollCallCheckInStatus.present; // Manual check-ins are trusted
    }

    // Check if within grace period
    final timeSinceStart = DateTime.now().difference(rollCall.startedAt);
    final gracePeriod = Duration(minutes: rollCall.gracePeriodMinutes);
    
    if (timeSinceStart <= gracePeriod) {
      return RollCallCheckInStatus.present;
    } else {
      return RollCallCheckInStatus.late;
    }
  }

  void _startGraceTimer(RollCall rollCall) {
    _stopGraceTimer(rollCall.id);
    
    final timer = Timer(
      Duration(minutes: rollCall.gracePeriodMinutes),
      () => _onGracePeriodExpired(rollCall.id),
    );
    
    _graceTimers[rollCall.id] = timer;
  }

  void _restartGraceTimer(RollCall rollCall) {
    _startGraceTimer(rollCall);
  }

  void _stopGraceTimer(String rollCallId) {
    _graceTimers[rollCallId]?.cancel();
    _graceTimers.remove(rollCallId);
  }

  void _onGracePeriodExpired(String rollCallId) {
    final rollCall = _activeRollCalls[rollCallId];
    if (rollCall != null) {
      final updatedRollCall = rollCall.copyWith(
        status: RollCallStatus.expired,
        endedAt: DateTime.now(),
        auditLog: [
          ...rollCall.auditLog,
          RollCallAuditLog(
            timestamp: DateTime.now(),
            userId: rollCall.leaderId,
            action: RollCallAuditAction.escalated,
            details: {
              'reason': 'Grace period expired',
              'missingCount': _getMissingCount(rollCall),
            },
          ),
        ],
      );

      _activeRollCalls[rollCallId] = updatedRollCall;
      _getRollCallStream(rollCallId).add(updatedRollCall);
    }
  }

  void _startLocationTracking(RollCall rollCall) {
    _stopLocationTracking(rollCall.id);
    
    try {
      final subscription = _locationService.getLocationStream().listen(
        (position) {
          // Handle location updates for roll call
          // This could be used for real-time distance updates
        },
        onError: (error) {
          debugPrint('Roll call location tracking error: $error');
          // Don't crash the app on location errors
        },
      );
      
      _locationSubscriptions[rollCall.id] = subscription;
    } catch (e) {
      debugPrint('Failed to start location tracking for roll call: $e');
      // Don't crash if location tracking fails
    }
  }

  void _stopLocationTracking(String rollCallId) {
    _locationSubscriptions[rollCallId]?.cancel();
    _locationSubscriptions.remove(rollCallId);
  }

  StreamController<RollCall> _getRollCallStream(String rollCallId) {
    return _rollCallControllers.putIfAbsent(
      rollCallId,
      () => StreamController<RollCall>.broadcast(),
    );
  }

  StreamController<RollCallCheckIn> _getCheckInStream(String rollCallId) {
    return _checkInControllers.putIfAbsent(
      rollCallId,
      () => StreamController<RollCallCheckIn>.broadcast(),
    );
  }

  void _notifyRollCallStarted(RollCall rollCall) async {
    if (_settings.enableNotifications) {
      await _notificationService.showRollCallStarted(
        tripId: rollCall.tripId,
        rollCallId: rollCall.id,
        anchorLocation: rollCall.anchorLocation,
        anchorName: rollCall.anchorName ?? 'Roll Call Location',
      );
    }
  }

  void _notifyRollCallClosed(RollCall rollCall) async {
    if (_settings.enableNotifications && rollCall.announceOnClose) {
      await _notificationService.showRollCallClosed(
        tripId: rollCall.tripId,
        rollCallId: rollCall.id,
        presentCount: _getPresentCount(rollCall),
        missingCount: _getMissingCount(rollCall),
        closeMessage: rollCall.closeMessage,
      );
    }
  }

  void _notifyRollCallCancelled(RollCall rollCall) async {
    if (_settings.enableNotifications) {
      await _notificationService.showRollCallCancelled(
        tripId: rollCall.tripId,
        rollCallId: rollCall.id,
      );
    }
  }

  List<String> _getMissingUserIds(RollCall rollCall) {
    // Get all active members for this trip
    final tripMemberships = MockServer().memberships
        .where((m) => m.tripId == rollCall.tripId && m.status == MembershipStatus.active)
        .toList();
    
    // Get user IDs of all active members
    final allMemberIds = tripMemberships.map((m) => m.userId).toSet();
    
    // Get user IDs of members who have checked in
    final checkedInIds = rollCall.checkIns
        .where((checkIn) => checkIn.status == RollCallCheckInStatus.present)
        .map((checkIn) => checkIn.userId)
        .toSet();
    
    // Return IDs of members who haven't checked in
    return allMemberIds.difference(checkedInIds).toList();
  }

  List<String> _getLateUserIds(RollCall rollCall) {
    return rollCall.checkIns
        .where((checkIn) => checkIn.status == RollCallCheckInStatus.late)
        .map((checkIn) => checkIn.userId)
        .toList();
  }

  int _getPresentCount(RollCall rollCall) {
    return rollCall.checkIns
        .where((checkIn) => checkIn.status == RollCallCheckInStatus.present)
        .length;
  }

  int _getMissingCount(RollCall rollCall) {
    return _getMissingUserIds(rollCall).length;
  }

  int _getTotalMemberCount(RollCall rollCall) {
    // Get all active members for this trip
    final tripMemberships = MockServer().memberships
        .where((m) => m.tripId == rollCall.tripId && m.status == MembershipStatus.active)
        .toList();
    
    return tripMemberships.length;
  }

  int _getEscalationCount(RollCall rollCall) {
    return rollCall.auditLog
        .where((log) => log.action == RollCallAuditAction.escalated)
        .length;
  }

  // Dispose resources
  void dispose() {
    for (final timer in _graceTimers.values) {
      timer.cancel();
    }
    _graceTimers.clear();

    for (final subscription in _locationSubscriptions.values) {
      subscription.cancel();
    }
    _locationSubscriptions.clear();

    for (final controller in _rollCallControllers.values) {
      controller.close();
    }
    _rollCallControllers.clear();

    for (final controller in _checkInControllers.values) {
      controller.close();
    }
    _checkInControllers.clear();
  }
}
