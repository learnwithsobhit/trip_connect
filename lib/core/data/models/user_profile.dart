import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_profile.freezed.dart';
part 'user_profile.g.dart';

@freezed
class UserProfile with _$UserProfile {
  const factory UserProfile({
    required String id,
    required String name,
    required String email,
    String? avatarUrl,
    String? bio,
    required DateTime joinedAt,
    required UserStats stats,
    required List<Achievement> achievements,
    required List<String> following,
    required List<String> followers,
    required UserPreferences preferences,
    String? location,
    String? website,
    @Default(false) bool isVerified,
    @Default(UserStatus.active) UserStatus status,
  }) = _UserProfile;

  factory UserProfile.fromJson(Map<String, dynamic> json) => _$UserProfileFromJson(json);
}

@freezed
class UserStats with _$UserStats {
  const factory UserStats({
    @Default(0) int totalTrips,
    @Default(0) int completedTrips,
    @Default(0) int totalPosts,
    @Default(0) int totalStories,
    @Default(0) int totalLikes,
    @Default(0) int totalComments,
    @Default(0) int followersCount,
    @Default(0) int followingCount,
    @Default(0) int achievementsCount,
    @Default(0) int checkIns,
    @Default(0) int rollCallsAttended,
    @Default(0) int rollCallsLed,
    @Default(0.0) double averageRating,
    @Default(0) int totalReviews,
  }) = _UserStats;

  factory UserStats.fromJson(Map<String, dynamic> json) => _$UserStatsFromJson(json);
}

@freezed
class Achievement with _$Achievement {
  const factory Achievement({
    required String id,
    required String title,
    required String description,
    required String icon,
    required AchievementType type,
    required DateTime earnedAt,
    required int points,
    String? tripId,
    String? imageUrl,
    @Default(false) bool isRare,
    @Default(false) bool isSecret,
  }) = _Achievement;

  factory Achievement.fromJson(Map<String, dynamic> json) => _$AchievementFromJson(json);
}

@freezed
class UserPreferences with _$UserPreferences {
  const factory UserPreferences({
    @Default(NotificationSettings()) NotificationSettings notifications,
    @Default(PrivacySettings()) PrivacySettings privacy,
    @Default(ThemeSettings()) ThemeSettings theme,
    @Default(LanguageSettings()) LanguageSettings language,
    @Default(UserLocationSettings()) UserLocationSettings location,
  }) = _UserPreferences;

  factory UserPreferences.fromJson(Map<String, dynamic> json) => _$UserPreferencesFromJson(json);
}

@freezed
class NotificationSettings with _$NotificationSettings {
  const factory NotificationSettings({
    @Default(true) bool newPosts,
    @Default(true) bool newComments,
    @Default(true) bool newReactions,
    @Default(true) bool newStories,
    @Default(true) bool tripUpdates,
    @Default(true) bool rollCallReminders,
    @Default(true) bool mentions,
    @Default(true) bool achievements,
    @Default(true) bool followers,
    @Default(false) bool marketing,
  }) = _NotificationSettings;

  factory NotificationSettings.fromJson(Map<String, dynamic> json) => _$NotificationSettingsFromJson(json);
}

@freezed
class PrivacySettings with _$PrivacySettings {
  const factory PrivacySettings({
    @Default(ProfileVisibility.public) ProfileVisibility profileVisibility,
    @Default(true) bool showLocation,
    @Default(true) bool showStats,
    @Default(true) bool showAchievements,
    @Default(true) bool allowMessages,
    @Default(true) bool allowFollows,
    @Default(false) bool showOnlineStatus,
  }) = _PrivacySettings;

  factory PrivacySettings.fromJson(Map<String, dynamic> json) => _$PrivacySettingsFromJson(json);
}

@freezed
class ThemeSettings with _$ThemeSettings {
  const factory ThemeSettings({
    @Default(ThemeMode.system) ThemeMode themeMode,
    @Default(false) bool useDynamicColors,
    @Default('default') String accentColor,
  }) = _ThemeSettings;

  factory ThemeSettings.fromJson(Map<String, dynamic> json) => _$ThemeSettingsFromJson(json);
}

@freezed
class LanguageSettings with _$LanguageSettings {
  const factory LanguageSettings({
    @Default('en') String language,
    @Default('US') String region,
    @Default(false) bool autoTranslate,
  }) = _LanguageSettings;

  factory LanguageSettings.fromJson(Map<String, dynamic> json) => _$LanguageSettingsFromJson(json);
}

@freezed
class UserLocationSettings with _$UserLocationSettings {
  const factory UserLocationSettings({
    @Default(true) bool enableLocation,
    @Default(true) bool shareLocation,
    @Default(UserLocationAccuracy.high) UserLocationAccuracy accuracy,
    @Default(300) int updateInterval,
  }) = _UserLocationSettings;

  factory UserLocationSettings.fromJson(Map<String, dynamic> json) => _$UserLocationSettingsFromJson(json);
}

// Enums
enum UserStatus {
  active,
  inactive,
  suspended,
  deleted,
}

enum AchievementType {
  tripCompletion,
  socialEngagement,
  leadership,
  exploration,
  photography,
  community,
  milestone,
  special,
}

enum ProfileVisibility {
  public,
  friends,
  tripMembers,
  private,
}

enum UserLocationAccuracy {
  low,
  medium,
  high,
  precise,
}

// Extensions for better UX
extension UserStatusX on UserStatus {
  String get displayName {
    switch (this) {
      case UserStatus.active:
        return 'Active';
      case UserStatus.inactive:
        return 'Inactive';
      case UserStatus.suspended:
        return 'Suspended';
      case UserStatus.deleted:
        return 'Deleted';
    }
  }

  Color get color {
    switch (this) {
      case UserStatus.active:
        return Colors.green;
      case UserStatus.inactive:
        return Colors.orange;
      case UserStatus.suspended:
        return Colors.red;
      case UserStatus.deleted:
        return Colors.grey;
    }
  }

  IconData get icon {
    switch (this) {
      case UserStatus.active:
        return Icons.circle;
      case UserStatus.inactive:
        return Icons.schedule;
      case UserStatus.suspended:
        return Icons.block;
      case UserStatus.deleted:
        return Icons.delete;
    }
  }
}

extension AchievementTypeX on AchievementType {
  String get displayName {
    switch (this) {
      case AchievementType.tripCompletion:
        return 'Trip Completion';
      case AchievementType.socialEngagement:
        return 'Social Engagement';
      case AchievementType.leadership:
        return 'Leadership';
      case AchievementType.exploration:
        return 'Exploration';
      case AchievementType.photography:
        return 'Photography';
      case AchievementType.community:
        return 'Community';
      case AchievementType.milestone:
        return 'Milestone';
      case AchievementType.special:
        return 'Special';
    }
  }

  IconData get icon {
    switch (this) {
      case AchievementType.tripCompletion:
        return Icons.flag;
      case AchievementType.socialEngagement:
        return Icons.people;
      case AchievementType.leadership:
        return Icons.star;
      case AchievementType.exploration:
        return Icons.explore;
      case AchievementType.photography:
        return Icons.camera_alt;
      case AchievementType.community:
        return Icons.group;
      case AchievementType.milestone:
        return Icons.emoji_events;
      case AchievementType.special:
        return Icons.diamond;
    }
  }

  Color get color {
    switch (this) {
      case AchievementType.tripCompletion:
        return Colors.blue;
      case AchievementType.socialEngagement:
        return Colors.green;
      case AchievementType.leadership:
        return Colors.amber;
      case AchievementType.exploration:
        return Colors.purple;
      case AchievementType.photography:
        return Colors.orange;
      case AchievementType.community:
        return Colors.teal;
      case AchievementType.milestone:
        return Colors.indigo;
      case AchievementType.special:
        return Colors.pink;
    }
  }
}

extension ProfileVisibilityX on ProfileVisibility {
  String get displayName {
    switch (this) {
      case ProfileVisibility.public:
        return 'Public';
      case ProfileVisibility.friends:
        return 'Friends Only';
      case ProfileVisibility.tripMembers:
        return 'Trip Members Only';
      case ProfileVisibility.private:
        return 'Private';
    }
  }

  IconData get icon {
    switch (this) {
      case ProfileVisibility.public:
        return Icons.public;
      case ProfileVisibility.friends:
        return Icons.people;
      case ProfileVisibility.tripMembers:
        return Icons.group;
      case ProfileVisibility.private:
        return Icons.lock;
    }
  }
}
