import 'dart:async';

import '../models/models.dart';
import '../../services/mock_server.dart';

class TripRepository {
  final MockServer _mockServer = MockServer();

  Future<List<Trip>> getUserTrips() async {
    return await _mockServer.getTrips();
  }

  Future<Trip?> getTrip(String tripId) async {
    return await _mockServer.getTrip(tripId);
  }

  Future<TripResult> createTrip({
    required String name,
    required String theme,
    required Location origin,
    required Location destination,
    required DateTime startDate,
    required DateTime endDate,
    required int seatsTotal,
    TripPrivacy privacy = TripPrivacy.private,
  }) async {
    try {
      final tripData = {
        'name': name,
        'theme': theme,
        'origin': origin.toJson(),
        'destination': destination.toJson(),
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'seatsTotal': seatsTotal,
        'privacy': privacy.name,
      };

      final result = await _mockServer.createTrip(tripData);
      
      if (result['success'] == true) {
        final trip = Trip.fromJson(result['trip']);
        return TripResult.success(trip: trip);
      } else {
        return TripResult.failure(error: result['error'] ?? 'Unknown error');
      }
    } catch (e) {
      return TripResult.failure(error: 'Network error: $e');
    }
  }

  Future<JoinTripResult> joinTrip(String inviteCode) async {
    try {
      final result = await _mockServer.joinTrip(inviteCode);
      
      if (result['success'] == true) {
        final trip = Trip.fromJson(result['trip']);
        final membership = Membership.fromJson(result['membership']);
        return JoinTripResult.success(trip: trip, membership: membership);
      } else {
        return JoinTripResult.failure(error: result['error'] ?? 'Unknown error');
      }
    } catch (e) {
      return JoinTripResult.failure(error: 'Network error: $e');
    }
  }

  Future<LeaveTripResult> leaveTrip(String tripId) async {
    try {
      final result = await _mockServer.leaveTrip(tripId);
      
      if (result['success'] == true) {
        final trip = Trip.fromJson(result['trip']);
        return LeaveTripResult.success(
          trip: trip, 
          message: result['message'] ?? 'Successfully left the trip'
        );
      } else {
        return LeaveTripResult.failure(error: result['error'] ?? 'Unknown error');
      }
    } catch (e) {
      return LeaveTripResult.failure(error: 'Network error: $e');
    }
  }

  Future<List<Membership>> getTripMembers(String tripId) async {
    return _mockServer.memberships
        .where((m) => m.tripId == tripId)
        .toList();
  }

  Future<List<User>> getTripUsers(String tripId) async {
    final members = await getTripMembers(tripId);
    final userIds = members.map((m) => m.userId).toSet();
    
    return _mockServer.users
        .where((u) => userIds.contains(u.id))
        .toList();
  }

  Future<List<Message>> getTripMessages(String tripId, {int limit = 50, String? before}) async {
    return await _mockServer.getMessages(tripId, limit: limit, before: before);
  }

  Future<Message> sendMessage(
    String tripId,
    String text, {
    MessageType type = MessageType.chat,
    List<String> tags = const [],
    bool requiresAck = false,
  }) async {
    return await _mockServer.sendMessage(
      tripId,
      text,
      type: type,
      tags: tags,
      requiresAck: requiresAck,
    );
  }

  Future<Alert> raiseAlert(String tripId, AlertKind kind, AlertPayload payload) async {
    return await _mockServer.raiseAlert(tripId, kind, payload);
  }

  Future<RollCall> startRollCall(String tripId, {String? stopId, int graceMin = 10}) async {
    return await _mockServer.startRollCall(tripId, stopId: stopId, graceMin: graceMin);
  }

  Future<CheckIn> checkIn(String rollCallId, {CheckInMode mode = CheckInMode.manual}) async {
    return await _mockServer.checkIn(rollCallId, mode: mode);
  }

  // Real-time streams
  Stream<Map<String, dynamic>> getTripStream(String tripId) {
    return _mockServer.getTripStream(tripId);
  }

  Stream<List<Trip>> get tripsStream => _mockServer.tripsStream;

  Future<TripResult> updateTrip(String tripId, Map<String, dynamic> updates) async {
    // Mock update functionality
    await Future.delayed(const Duration(milliseconds: 300));
    
    try {
      final trip = await getTrip(tripId);
      if (trip == null) {
        return TripResult.failure(error: 'Trip not found');
      }
      
      // In a real implementation, this would send updates to the server
      return TripResult.success(trip: trip);
    } catch (e) {
      return TripResult.failure(error: 'Failed to update trip: $e');
    }
  }

  Future<bool> addStopToTrip(String tripId, Stop stop) async {
    // Mock add stop functionality
    await Future.delayed(const Duration(milliseconds: 400));
    return true;
  }

  Future<bool> updateTripSchedule(String tripId, List<ScheduleItem> schedule) async {
    // Mock schedule update
    await Future.delayed(const Duration(milliseconds: 500));
    return true;
  }

  Future<List<Media>> getTripMedia(String tripId, {String? stopId}) async {
    // This would be implemented with proper API calls in a real app
    await Future.delayed(const Duration(milliseconds: 200));
    return [];
  }

  Future<List<Document>> getTripDocuments(String tripId) async {
    // This would be implemented with proper API calls in a real app
    await Future.delayed(const Duration(milliseconds: 200));
    return [];
  }
}

// Result classes
class TripResult {
  final bool isSuccess;
  final Trip? trip;
  final String? error;

  const TripResult._({
    required this.isSuccess,
    this.trip,
    this.error,
  });

  factory TripResult.success({required Trip trip}) {
    return TripResult._(isSuccess: true, trip: trip);
  }

  factory TripResult.failure({required String error}) {
    return TripResult._(isSuccess: false, error: error);
  }
}

class JoinTripResult {
  final bool isSuccess;
  final Trip? trip;
  final Membership? membership;
  final String? error;

  const JoinTripResult._({
    required this.isSuccess,
    this.trip,
    this.membership,
    this.error,
  });

  factory JoinTripResult.success({required Trip trip, required Membership membership}) {
    return JoinTripResult._(
      isSuccess: true,
      trip: trip,
      membership: membership,
    );
  }

  factory JoinTripResult.failure({required String error}) {
    return JoinTripResult._(isSuccess: false, error: error);
  }
}

class LeaveTripResult {
  final bool isSuccess;
  final Trip? trip;
  final String? error;
  final String? message;

  const LeaveTripResult._({
    required this.isSuccess,
    this.trip,
    this.error,
    this.message,
  });

  factory LeaveTripResult.success({required Trip trip, String? message}) {
    return LeaveTripResult._(
      isSuccess: true,
      trip: trip,
      message: message,
    );
  }

  factory LeaveTripResult.failure({required String error}) {
    return LeaveTripResult._(isSuccess: false, error: error);
  }
}
