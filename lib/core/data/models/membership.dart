import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';

part 'membership.freezed.dart';
part 'membership.g.dart';

@freezed
@HiveType(typeId: 12)
class Membership with _$Membership {
  const factory Membership({
    @HiveField(0) required String tripId,
    @HiveField(1) required String userId,
    @HiveField(2) required UserRole role,
    @HiveField(3) String? seat,
    @HiveField(4) required DateTime joinedAt,
    @HiveField(5) UserLocation? location,
    @HiveField(6) @Default(MembershipStatus.active) MembershipStatus status,
    @HiveField(7) DateTime? lastSeen,
    @HiveField(8) bool? isOnline,
  }) = _Membership;

  factory Membership.fromJson(Map<String, dynamic> json) => _$MembershipFromJson(json);
}

@freezed
@HiveType(typeId: 13)
class UserLocation with _$UserLocation {
  const factory UserLocation({
    @HiveField(0) required double lat,
    @HiveField(1) required double lng,
    @HiveField(2) required DateTime lastSeen,
    @HiveField(3) double? accuracy,
    @HiveField(4) double? bearing,
    @HiveField(5) double? speed,
  }) = _UserLocation;

  factory UserLocation.fromJson(Map<String, dynamic> json) => _$UserLocationFromJson(json);
}

@HiveType(typeId: 14)
enum UserRole {
  @HiveField(0)
  leader,
  @HiveField(1)
  coLeader,
  @HiveField(2)
  traveler,
  @HiveField(3)
  follower,
}

@HiveType(typeId: 15)
enum MembershipStatus {
  @HiveField(0)
  pending,
  @HiveField(1)
  active,
  @HiveField(2)
  dropped,
  @HiveField(3)
  left,
  @HiveField(4)
  waiting,
}
