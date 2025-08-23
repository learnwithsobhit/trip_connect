import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';
import 'rating.dart';

part 'trip.freezed.dart';
part 'trip.g.dart';

@freezed
@HiveType(typeId: 14)
class Trip with _$Trip {
  const factory Trip({
    @HiveField(0) required String id,
    @HiveField(1) required String name,
    @HiveField(2) required String theme,
    @HiveField(3) required Location origin,
    @HiveField(4) required Location destination,
    @HiveField(5) required DateTime startDate,
    @HiveField(6) required DateTime endDate,
    @HiveField(7) required int seatsTotal,
    @HiveField(8) required int seatsAvailable,
    @HiveField(9) @Default(TripPrivacy.private) TripPrivacy privacy,
    @HiveField(10) required String leaderId,
    @HiveField(11) required TripInvite invite,
    @HiveField(12) @Default(TripStatus.planning) TripStatus status,
    @HiveField(13) @Default([]) List<ScheduleItem> schedule,
    @HiveField(14) DateTime? createdAt,
    @HiveField(15) DateTime? updatedAt,
    @HiveField(16) @Default(TripRatingSummary(tripId: '')) TripRatingSummary ratingSummary,
    @HiveField(17) @Default(4.0) double minimumUserRating, // Minimum rating required to join
  }) = _Trip;

  factory Trip.fromJson(Map<String, dynamic> json) => _$TripFromJson(json);
}

@freezed
@HiveType(typeId: 15)
class Location with _$Location {
  const factory Location({
    @HiveField(0) required String name,
    @HiveField(1) required double lat,
    @HiveField(2) required double lng,
    @HiveField(3) String? address,
  }) = _Location;

  factory Location.fromJson(Map<String, dynamic> json) => _$LocationFromJson(json);
}

@freezed
@HiveType(typeId: 16)
class TripInvite with _$TripInvite {
  const factory TripInvite({
    @HiveField(0) required String code,
    @HiveField(1) required String qr,
  }) = _TripInvite;

  factory TripInvite.fromJson(Map<String, dynamic> json) => _$TripInviteFromJson(json);
}

@freezed
@HiveType(typeId: 17)
class ScheduleItem with _$ScheduleItem {
  const factory ScheduleItem({
    @HiveField(0) required String id,
    @HiveField(1) required int day,
    @HiveField(2) required ScheduleType type,
    @HiveField(3) required String title,
    @HiveField(4) required DateTime plannedStart,
    @HiveField(5) required DateTime plannedEnd,
    @HiveField(6) DateTime? actualStart,
    @HiveField(7) DateTime? actualEnd,
    @HiveField(8) @Default([]) List<Stop> stops,
    @HiveField(9) String? description,
    @HiveField(10) Location? location,
  }) = _ScheduleItem;

  factory ScheduleItem.fromJson(Map<String, dynamic> json) => _$ScheduleItemFromJson(json);
}

@freezed
@HiveType(typeId: 18)
class Stop with _$Stop {
  const factory Stop({
    @HiveField(0) required String id,
    @HiveField(1) required String name,
    @HiveField(2) required double lat,
    @HiveField(3) required double lng,
    @HiveField(4) required DateTime plannedAt,
    @HiveField(5) required int durationMin,
    @HiveField(6) @Default(StopType.general) StopType stopType,
    @HiveField(7) String? description,
    @HiveField(8) DateTime? actualAt,
  }) = _Stop;

  factory Stop.fromJson(Map<String, dynamic> json) => _$StopFromJson(json);
}

@HiveType(typeId: 19)
enum TripPrivacy {
  @HiveField(0)
  public,
  @HiveField(1)
  private,
}

@HiveType(typeId: 20)
enum TripStatus {
  @HiveField(0)
  planning,
  @HiveField(1)
  active,
  @HiveField(2)
  completed,
  @HiveField(3)
  cancelled,
}

@HiveType(typeId: 21)
enum ScheduleType {
  @HiveField(0)
  drive,
  @HiveField(1)
  activity,
  @HiveField(2)
  meal,
  @HiveField(3)
  rest,
  @HiveField(4)
  sightseeing,
}

@HiveType(typeId: 22)
enum StopType {
  @HiveField(0)
  general,
  @HiveField(1)
  food,
  @HiveField(2)
  fuel,
  @HiveField(3)
  restroom,
  @HiveField(4)
  sightseeing,
  @HiveField(5)
  hotel,
  @HiveField(6)
  emergency,
}
