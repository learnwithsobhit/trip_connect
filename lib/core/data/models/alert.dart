import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';

part 'alert.freezed.dart';
part 'alert.g.dart';

@freezed
@HiveType(typeId: 24)
class Alert with _$Alert {
  const factory Alert({
    @HiveField(0) required String id,
    @HiveField(1) required String tripId,
    @HiveField(2) required AlertKind kind,
    @HiveField(3) required String raisedBy,
    @HiveField(4) required AlertPayload payload,
    @HiveField(5) required DateTime createdAt,
    @HiveField(6) @Default(true) bool active,
    @HiveField(7) String? resolvedBy,
    @HiveField(8) DateTime? resolvedAt,
    @HiveField(9) String? notes,
    @HiveField(10) @Default(AlertPriority.medium) AlertPriority priority,
  }) = _Alert;

  factory Alert.fromJson(Map<String, dynamic> json) => _$AlertFromJson(json);
}

@freezed
@HiveType(typeId: 25)
class AlertPayload with _$AlertPayload {
  const factory AlertPayload({
    @HiveField(0) double? lat,
    @HiveField(1) double? lng,
    @HiveField(2) String? message,
    @HiveField(3) List<String>? affectedUsers,
    @HiveField(4) String? stopId,
    @HiveField(5) Map<String, dynamic>? metadata,
  }) = _AlertPayload;

  factory AlertPayload.fromJson(Map<String, dynamic> json) => _$AlertPayloadFromJson(json);
}

@HiveType(typeId: 26)
enum AlertKind {
  @HiveField(0)
  sos,
  @HiveField(1)
  info,
  @HiveField(2)
  missing,
  @HiveField(3)
  delay,
  @HiveField(4)
  deviation,
  @HiveField(5)
  lowBattery,
  @HiveField(6)
  weather,
  @HiveField(7)
  medical,
}

@HiveType(typeId: 27)
enum AlertPriority {
  @HiveField(0)
  low,
  @HiveField(1)
  medium,
  @HiveField(2)
  high,
  @HiveField(3)
  critical,
}
