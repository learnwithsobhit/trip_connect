import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';
import 'rating.dart';

part 'user.freezed.dart';
part 'user.g.dart';

@freezed
@HiveType(typeId: 0)
class User with _$User {
  const factory User({
    @HiveField(0) required String id,
    @HiveField(1) required String displayName,
    @HiveField(2) String? avatarUrl,
    @HiveField(3) String? phone,
    @HiveField(4) @Default('en') String language,
    @HiveField(5) required UserPrivacy privacy,
    @HiveField(6) @Default(UserRatingSummary(userId: '')) UserRatingSummary ratingSummary,
    @HiveField(7) String? email,
    @HiveField(8) String? bio,
    @HiveField(9) String? profilePicture,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}

@freezed
@HiveType(typeId: 1)
class UserPrivacy with _$UserPrivacy {
  const factory UserPrivacy({
    @HiveField(0) @Default(LocationMode.precise) LocationMode locationMode,
  }) = _UserPrivacy;

  factory UserPrivacy.fromJson(Map<String, dynamic> json) => _$UserPrivacyFromJson(json);
}

// UserRating model moved to rating.dart

@HiveType(typeId: 2)
enum LocationMode {
  @HiveField(0)
  precise,
  @HiveField(1)
  approx,
  @HiveField(2)
  paused,
}
