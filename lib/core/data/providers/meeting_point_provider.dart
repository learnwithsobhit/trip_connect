import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import '../../services/mock_server.dart';

// Meeting Points Provider
final meetingPointsProvider = FutureProvider.family<List<MeetingPoint>, String>((ref, tripId) async {
  final mockServer = MockServer();
  return await mockServer.getMeetingPoints(tripId);
});

// Meeting Point Check-ins Provider
final meetingPointCheckInsProvider = FutureProvider.family<List<MeetingPointCheckIn>, String>((ref, meetingPointId) async {
  final mockServer = MockServer();
  return await mockServer.getMeetingPointCheckIns(meetingPointId);
});

// Meeting Point Report Provider
final meetingPointReportProvider = FutureProvider.family<MeetingPointReport?, String>((ref, tripId) async {
  final mockServer = MockServer();
  return await mockServer.getMeetingPointReport(tripId);
});

// Meeting Point Actions Notifier
class MeetingPointActionsNotifier extends StateNotifier<AsyncValue<void>> {
  final MockServer _mockServer;

  MeetingPointActionsNotifier(this._mockServer) : super(const AsyncValue.data(null));

  Future<void> createMeetingPoint({
    required String tripId,
    required String name,
    required String description,
    required Location location,
    required MeetingPointType type,
    required DateTime scheduledTime,
    required int checkInRadius,
    required List<String> participantIds,
    String? organizerId,
    String? notes,
    Map<String, dynamic>? metadata,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _mockServer.createMeetingPoint(
        tripId: tripId,
        name: name,
        description: description,
        location: location,
        type: type,
        scheduledTime: scheduledTime,
        checkInRadius: checkInRadius,
        participantIds: participantIds,
        organizerId: organizerId,
        notes: notes,
        metadata: metadata,
      );
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateMeetingPoint({
    required String meetingPointId,
    required String name,
    required String description,
    required Location location,
    required MeetingPointType type,
    required DateTime scheduledTime,
    required int checkInRadius,
    required List<String> participantIds,
    String? organizerId,
    String? notes,
    Map<String, dynamic>? metadata,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _mockServer.updateMeetingPoint(
        meetingPointId: meetingPointId,
        name: name,
        description: description,
        location: location,
        type: type,
        scheduledTime: scheduledTime,
        checkInRadius: checkInRadius,
        participantIds: participantIds,
        organizerId: organizerId,
        notes: notes,
        metadata: metadata,
      );
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deleteMeetingPoint(String meetingPointId) async {
    state = const AsyncValue.loading();
    try {
      await _mockServer.deleteMeetingPoint(meetingPointId);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> checkInToMeetingPoint({
    required String meetingPointId,
    required String userId,
    required CheckInMode mode,
    Location? location,
    String? notes,
    Map<String, dynamic>? metadata,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _mockServer.checkInToMeetingPoint(
        meetingPointId: meetingPointId,
        userId: userId,
        mode: mode,
        location: location,
        notes: notes,
        metadata: metadata,
      );
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> startMeetingPointRollCall({
    required String meetingPointId,
    required int graceMinutes,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _mockServer.startMeetingPointRollCall(
        meetingPointId: meetingPointId,
        graceMinutes: graceMinutes,
      );
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> endMeetingPointRollCall(String meetingPointId) async {
    state = const AsyncValue.loading();
    try {
      await _mockServer.endMeetingPointRollCall(meetingPointId);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

final meetingPointActionsProvider = StateNotifierProvider<MeetingPointActionsNotifier, AsyncValue<void>>((ref) {
  return MeetingPointActionsNotifier(MockServer());
});

// Meeting Point Type Provider
final meetingPointTypesProvider = Provider<List<MeetingPointType>>((ref) {
  return [
    const MeetingPointType.hotel(),
    const MeetingPointType.restaurant(),
    const MeetingPointType.touristSpot(),
    const MeetingPointType.transport(),
    const MeetingPointType.custom(),
  ];
});

// Meeting Point Status Provider
final meetingPointStatusesProvider = Provider<List<MeetingPointStatus>>((ref) {
  return [
    const MeetingPointStatus.upcoming(),
    const MeetingPointStatus.inProgress(),
    const MeetingPointStatus.completed(),
    const MeetingPointStatus.cancelled(),
  ];
});

// Helper function to get meeting point type name
String getMeetingPointTypeName(MeetingPointType type) {
  return type.when(
    hotel: () => 'Hotel',
    restaurant: () => 'Restaurant',
    touristSpot: () => 'Tourist Spot',
    transport: () => 'Transport',
    custom: () => 'Custom',
  );
}

// Helper function to get meeting point type icon
String getMeetingPointTypeIcon(MeetingPointType type) {
  return type.when(
    hotel: () => '🏨',
    restaurant: () => '🍽️',
    touristSpot: () => '🏖️',
    transport: () => '🚌',
    custom: () => '📍',
  );
}

// Helper function to get meeting point status name
String getMeetingPointStatusName(MeetingPointStatus status) {
  return status.when(
    upcoming: () => 'Upcoming',
    inProgress: () => 'In Progress',
    completed: () => 'Completed',
    cancelled: () => 'Cancelled',
  );
}

// Helper function to get meeting point status color
String getMeetingPointStatusColor(MeetingPointStatus status) {
  return status.when(
    upcoming: () => '#FFA500', // Orange
    inProgress: () => '#2196F3', // Blue
    completed: () => '#4CAF50', // Green
    cancelled: () => '#F44336', // Red
  );
}
