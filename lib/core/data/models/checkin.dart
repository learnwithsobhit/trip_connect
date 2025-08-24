import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';

part 'checkin.freezed.dart';
part 'checkin.g.dart';

@freezed
@HiveType(typeId: 28)
class LegacyRollCall with _$LegacyRollCall {
  const factory LegacyRollCall({
    @HiveField(0) required String id,
    @HiveField(1) required String tripId,
    @HiveField(2) String? stopId,
    @HiveField(3) required String startedBy,
    @HiveField(4) required DateTime startedAt,
    @HiveField(5) @Default(10) int graceMin,
    @HiveField(6) @Default([]) List<CheckIn> checkins,
    @HiveField(7) DateTime? closedAt,
    @HiveField(8) String? closedBy,
    @HiveField(9) @Default(LegacyRollCallStatus.active) LegacyRollCallStatus status,
    @HiveField(10) String? location,
    @HiveField(11) String? notes,
  }) = _LegacyRollCall;

  factory LegacyRollCall.fromJson(Map<String, dynamic> json) => _$LegacyRollCallFromJson(json);
}

@freezed
@HiveType(typeId: 29)
class CheckIn with _$CheckIn {
  const factory CheckIn({
    @HiveField(0) required String userId,
    @HiveField(1) required DateTime time,
    @HiveField(2) required CheckInMode mode,
    @HiveField(3) double? lat,
    @HiveField(4) double? lng,
    @HiveField(5) String? notes,
    @HiveField(6) @Default(LegacyCheckInStatus.present) LegacyCheckInStatus status,
  }) = _CheckIn;

  factory CheckIn.fromJson(Map<String, dynamic> json) => _$CheckInFromJson(json);
}

@HiveType(typeId: 30)
enum CheckInMode {
  @HiveField(0)
  manual,
  @HiveField(1)
  geo,
  @HiveField(2)
  auto,
  @HiveField(3)
  override,
}

@HiveType(typeId: 31)
enum LegacyCheckInStatus {
  @HiveField(0)
  present,
  @HiveField(1)
  late,
  @HiveField(2)
  missing,
  @HiveField(3)
  excused,
}

@HiveType(typeId: 32)
enum LegacyRollCallStatus {
  @HiveField(0)
  active,
  @HiveField(1)
  completed,
  @HiveField(2)
  cancelled,
}
