import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';
import 'package:flutter/material.dart';

import 'models.dart';

part 'roll_call.freezed.dart';
part 'roll_call.g.dart';

// Roll call specific location model
@freezed
@HiveType(typeId: 55)
class RollCallLocation with _$RollCallLocation {
  const factory RollCallLocation({
    @HiveField(0) required double lat,
    @HiveField(1) required double lng,
    @HiveField(2) required DateTime timestamp,
    @HiveField(3) double? accuracy,
    @HiveField(4) double? bearing,
    @HiveField(5) double? speed,
  }) = _RollCallLocation;

  factory RollCallLocation.fromJson(Map<String, dynamic> json) => _$RollCallLocationFromJson(json);
}

@freezed
@HiveType(typeId: 50)
class RollCall with _$RollCall {
  const factory RollCall({
    @HiveField(0) required String id,
    @HiveField(1) required String tripId,
    @HiveField(2) required String leaderId,
    @HiveField(3) required DateTime startedAt,
    @HiveField(4) DateTime? endedAt,
    @HiveField(5) required RollCallStatus status,
    @HiveField(6) required RollCallLocation anchorLocation,
    @HiveField(7) required double radiusMeters,
    @HiveField(8) required int gracePeriodMinutes,
    @HiveField(9) @Default([]) List<RollCallCheckIn> checkIns,
    @HiveField(10) @Default([]) List<String> notifiedUserIds,
    @HiveField(11) String? anchorName,
    @HiveField(12) @Default(false) bool allowManualCheckIn,
    @HiveField(13) @Default(false) bool announceOnClose,
    @HiveField(14) String? closeMessage,
    @HiveField(15) @Default([]) List<RollCallAuditLog> auditLog,
  }) = _RollCall;

  factory RollCall.fromJson(Map<String, dynamic> json) => _$RollCallFromJson(json);
}

@freezed
@HiveType(typeId: 51)
class RollCallCheckIn with _$RollCallCheckIn {
  const factory RollCallCheckIn({
    @HiveField(0) required String userId,
    @HiveField(1) required DateTime checkedInAt,
    @HiveField(2) required CheckInMethod method,
    @HiveField(3) RollCallLocation? location,
    @HiveField(4) double? distanceFromAnchor,
    @HiveField(5) bool? isWithinRadius,
    @HiveField(6) String? manualReason,
    @HiveField(7) String? markedByLeaderId,
    @HiveField(8) @Default(RollCallCheckInStatus.present) RollCallCheckInStatus status,
  }) = _RollCallCheckIn;

  factory RollCallCheckIn.fromJson(Map<String, dynamic> json) => _$RollCallCheckInFromJson(json);
}

@freezed
@HiveType(typeId: 52)
class RollCallAuditLog with _$RollCallAuditLog {
  const factory RollCallAuditLog({
    @HiveField(0) required DateTime timestamp,
    @HiveField(1) required String userId,
    @HiveField(2) required RollCallAuditAction action,
    @HiveField(3) Map<String, dynamic>? details,
    @HiveField(4) String? reason,
  }) = _RollCallAuditLog;

  factory RollCallAuditLog.fromJson(Map<String, dynamic> json) => _$RollCallAuditLogFromJson(json);
}

@freezed
@HiveType(typeId: 53)
class RollCallSettings with _$RollCallSettings {
  const factory RollCallSettings({
    @HiveField(0) @Default(50.0) double defaultRadiusMeters,
    @HiveField(1) @Default(3) int defaultGracePeriodMinutes,
    @HiveField(2) @Default(true) bool allowManualCheckIn,
    @HiveField(3) @Default(true) bool announceOnClose,
    @HiveField(4) @Default(true) bool enableNotifications,
    @HiveField(5) @Default(true) bool enableDriverMode,
    @HiveField(6) @Default(false) bool autoStartOnGeofence,
    @HiveField(7) @Default(120) int gpsFreshnessSeconds,
    @HiveField(8) @Default(true) bool enableHysteresis,
    @HiveField(9) @Default(false) bool requireDualConfirmManual,
  }) = _RollCallSettings;

  factory RollCallSettings.fromJson(Map<String, dynamic> json) => _$RollCallSettingsFromJson(json);
}

@freezed
@HiveType(typeId: 54)
class RollCallReport with _$RollCallReport {
  const factory RollCallReport({
    @HiveField(0) required String rollCallId,
    @HiveField(1) required DateTime generatedAt,
    @HiveField(2) required int totalMembers,
    @HiveField(3) required int presentCount,
    @HiveField(4) required int missingCount,
    @HiveField(5) required Duration completionTime,
    @HiveField(6) required Map<CheckInMethod, int> methodBreakdown,
    @HiveField(7) required List<String> missingUserIds,
    @HiveField(8) required List<String> lateUserIds,
    @HiveField(9) required Map<String, Duration> responseTimes,
    @HiveField(10) required int escalationCount,
    @HiveField(11) required List<RollCallAuditLog> auditTrail,
  }) = _RollCallReport;

  factory RollCallReport.fromJson(Map<String, dynamic> json) => _$RollCallReportFromJson(json);
}

enum RollCallStatus {
  @HiveType(typeId: 0)
  active,
  @HiveType(typeId: 1)
  completed,
  @HiveType(typeId: 2)
  cancelled,
  @HiveType(typeId: 3)
  expired,
}

enum CheckInMethod {
  @HiveType(typeId: 0)
  gps,
  @HiveType(typeId: 1)
  manual,
  @HiveType(typeId: 2)
  leaderMarked,
  @HiveType(typeId: 3)
  qrCode,
  @HiveType(typeId: 4)
  nfc,
}

enum RollCallCheckInStatus {
  @HiveType(typeId: 0)
  present,
  @HiveType(typeId: 1)
  late,
  @HiveType(typeId: 2)
  absent,
  @HiveType(typeId: 3)
  excused,
}

enum RollCallAuditAction {
  @HiveType(typeId: 0)
  started,
  @HiveType(typeId: 1)
  checkedIn,
  @HiveType(typeId: 2)
  markedPresent,
  @HiveType(typeId: 3)
  markedAbsent,
  @HiveType(typeId: 4)
  sentReminder,
  @HiveType(typeId: 5)
  escalated,
  @HiveType(typeId: 6)
  extended,
  @HiveType(typeId: 7)
  closed,
  @HiveType(typeId: 8)
  cancelled,
}

// Extension methods for better UX
extension RollCallStatusX on RollCallStatus {
  String get displayName {
    switch (this) {
      case RollCallStatus.active:
        return 'Active';
      case RollCallStatus.completed:
        return 'Completed';
      case RollCallStatus.cancelled:
        return 'Cancelled';
      case RollCallStatus.expired:
        return 'Expired';
    }
  }

  bool get isActive => this == RollCallStatus.active;
  bool get isCompleted => this == RollCallStatus.completed;
  bool get isEnded => this == RollCallStatus.completed || this == RollCallStatus.cancelled || this == RollCallStatus.expired;
}

extension CheckInMethodX on CheckInMethod {
  String get displayName {
    switch (this) {
      case CheckInMethod.gps:
        return 'GPS';
      case CheckInMethod.manual:
        return 'Manual';
      case CheckInMethod.leaderMarked:
        return 'Leader Marked';
      case CheckInMethod.qrCode:
        return 'QR Code';
      case CheckInMethod.nfc:
        return 'NFC';
    }
  }

  IconData get icon {
    switch (this) {
      case CheckInMethod.gps:
        return Icons.location_on;
      case CheckInMethod.manual:
        return Icons.touch_app;
      case CheckInMethod.leaderMarked:
        return Icons.person_add;
      case CheckInMethod.qrCode:
        return Icons.qr_code;
      case CheckInMethod.nfc:
        return Icons.nfc;
    }
  }

  Color get color {
    switch (this) {
      case CheckInMethod.gps:
        return Colors.green;
      case CheckInMethod.manual:
        return Colors.orange;
      case CheckInMethod.leaderMarked:
        return Colors.blue;
      case CheckInMethod.qrCode:
        return Colors.purple;
      case CheckInMethod.nfc:
        return Colors.indigo;
    }
  }
}

extension RollCallCheckInStatusX on RollCallCheckInStatus {
  String get displayName {
    switch (this) {
      case RollCallCheckInStatus.present:
        return 'Present';
      case RollCallCheckInStatus.late:
        return 'Late';
      case RollCallCheckInStatus.absent:
        return 'Absent';
      case RollCallCheckInStatus.excused:
        return 'Excused';
    }
  }

  Color get color {
    switch (this) {
      case RollCallCheckInStatus.present:
        return Colors.green;
      case RollCallCheckInStatus.late:
        return Colors.orange;
      case RollCallCheckInStatus.absent:
        return Colors.red;
      case RollCallCheckInStatus.excused:
        return Colors.grey;
    }
  }
}
