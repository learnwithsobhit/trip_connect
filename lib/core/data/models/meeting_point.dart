import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';
import 'models.dart';

part 'meeting_point.freezed.dart';
part 'meeting_point.g.dart';

@freezed
class MeetingPoint with _$MeetingPoint {
  const factory MeetingPoint({
    required String id,
    required String tripId,
    required String name,
    required String description,
    required Location location,
    required MeetingPointType type,
    required DateTime scheduledTime,
    required int checkInRadius,
    required List<String> participantIds,
    required MeetingPointStatus status,
    required DateTime createdAt,
    required DateTime updatedAt,
    String? organizerId,
    String? notes,
    Map<String, dynamic>? metadata,
    @Default(true) bool enableAutoCheckIn,
    @Default(true) bool enableNotifications,
    @Default(15) int gracePeriodMinutes,
    @Default([]) List<String> notifiedUserIds,
    @Default([]) List<String> autoCheckedInUserIds,
  }) = _MeetingPoint;

  factory MeetingPoint.fromJson(Map<String, dynamic> json) => _$MeetingPointFromJson(json);
}

@freezed
class MeetingPointType with _$MeetingPointType {
  const factory MeetingPointType.hotel() = _Hotel;
  const factory MeetingPointType.restaurant() = _Restaurant;
  const factory MeetingPointType.touristSpot() = _TouristSpot;
  const factory MeetingPointType.transport() = _Transport;
  const factory MeetingPointType.custom() = _Custom;

  factory MeetingPointType.fromJson(Map<String, dynamic> json) => _$MeetingPointTypeFromJson(json);
}

@freezed
class MeetingPointStatus with _$MeetingPointStatus {
  const factory MeetingPointStatus.upcoming() = _Upcoming;
  const factory MeetingPointStatus.inProgress() = _InProgress;
  const factory MeetingPointStatus.completed() = _Completed;
  const factory MeetingPointStatus.cancelled() = _Cancelled;

  factory MeetingPointStatus.fromJson(Map<String, dynamic> json) => _$MeetingPointStatusFromJson(json);
}

@freezed
class MeetingPointCheckIn with _$MeetingPointCheckIn {
  const factory MeetingPointCheckIn({
    required String id,
    required String meetingPointId,
    required String userId,
    required CheckInMode mode,
    required DateTime checkedInAt,
    Location? location,
    String? notes,
    Map<String, dynamic>? metadata,
    @Default(LegacyCheckInStatus.present) LegacyCheckInStatus status,
    double? distanceFromPoint,
    bool? isWithinRadius,
  }) = _MeetingPointCheckIn;

  factory MeetingPointCheckIn.fromJson(Map<String, dynamic> json) => _$MeetingPointCheckInFromJson(json);
}

@freezed
class MeetingPointReport with _$MeetingPointReport {
  const factory MeetingPointReport({
    required String tripId,
    required int totalMeetingPoints,
    required int completedMeetingPoints,
    required int totalParticipants,
    required int totalCheckIns,
    required double averageCheckInRate,
    required List<String> topParticipants,
    required Map<String, int> checkInStats,
    required DateTime generatedAt,
    required List<String> missingParticipants,
    required List<String> lateParticipants,
    required Map<String, double> averageResponseTime,
  }) = _MeetingPointReport;

  factory MeetingPointReport.fromJson(Map<String, dynamic> json) => _$MeetingPointReportFromJson(json);
}

@freezed
class RollCallSession with _$RollCallSession {
  const factory RollCallSession({
    required String id,
    required String meetingPointId,
    required String tripId,
    required String startedBy,
    required DateTime startedAt,
    required int gracePeriodMinutes,
    required RollCallSessionStatus status,
    DateTime? endedAt,
    String? endedBy,
    required List<String> participantIds,
    required List<String> checkedInUserIds,
    required List<String> missingUserIds,
    required List<String> notifiedUserIds,
    Map<String, DateTime>? checkInTimes,
    Map<String, CheckInMode>? checkInModes,
  }) = _RollCallSession;

  factory RollCallSession.fromJson(Map<String, dynamic> json) => _$RollCallSessionFromJson(json);
}

@freezed
class RollCallSessionStatus with _$RollCallSessionStatus {
  const factory RollCallSessionStatus.running() = _Running;
  const factory RollCallSessionStatus.finished() = _Finished;
  const factory RollCallSessionStatus.terminated() = _Terminated;

  factory RollCallSessionStatus.fromJson(Map<String, dynamic> json) => _$RollCallSessionStatusFromJson(json);
}

@freezed
class GeofenceEvent with _$GeofenceEvent {
  const factory GeofenceEvent({
    required String id,
    required String userId,
    required String meetingPointId,
    required GeofenceEventType type,
    required DateTime timestamp,
    required Location location,
    double? distanceFromPoint,
    bool? isWithinRadius,
  }) = _GeofenceEvent;

  factory GeofenceEvent.fromJson(Map<String, dynamic> json) => _$GeofenceEventFromJson(json);
}

@freezed
class GeofenceEventType with _$GeofenceEventType {
  const factory GeofenceEventType.entered() = _Entered;
  const factory GeofenceEventType.exited() = _Exited;
  const factory GeofenceEventType.within() = _Within;

  factory GeofenceEventType.fromJson(Map<String, dynamic> json) => _$GeofenceEventTypeFromJson(json);
}
