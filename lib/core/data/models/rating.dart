import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';

part 'rating.freezed.dart';
part 'rating.g.dart';

@freezed
@HiveType(typeId: 10)
class UserRating with _$UserRating {
  const factory UserRating({
    @HiveField(0) required String id,
    @HiveField(1) required String raterId, // User giving the rating
    @HiveField(2) required String ratedUserId, // User being rated
    @HiveField(3) required String tripId,
    @HiveField(4) required double rating, // 1-5 stars
    @HiveField(5) String? feedback,
    @HiveField(6) required DateTime createdAt,
    @HiveField(7) @Default([]) List<String> tags, // e.g., ["punctual", "friendly", "helpful"]
  }) = _UserRating;

  factory UserRating.fromJson(Map<String, dynamic> json) =>
      _$UserRatingFromJson(json);
}

@freezed
@HiveType(typeId: 11)
class TripRating with _$TripRating {
  const factory TripRating({
    @HiveField(0) required String id,
    @HiveField(1) required String userId, // User giving the rating
    @HiveField(2) required String tripId, // Trip being rated
    @HiveField(3) required double overallRating, // 1-5 stars
    @HiveField(4) required double organizationRating, // Trip organization
    @HiveField(5) required double valueRating, // Value for money
    @HiveField(6) required double experienceRating, // Overall experience
    @HiveField(7) String? feedback,
    @HiveField(8) required DateTime createdAt,
    @HiveField(9) @Default([]) List<String> highlights, // What was good
    @HiveField(10) @Default([]) List<String> improvements, // What could be better
    @HiveField(11) @Default(true) bool wouldRecommend,
  }) = _TripRating;

  factory TripRating.fromJson(Map<String, dynamic> json) =>
      _$TripRatingFromJson(json);
}

@freezed
@HiveType(typeId: 12)
class UserRatingSummary with _$UserRatingSummary {
  const factory UserRatingSummary({
    @HiveField(0) required String userId,
    @HiveField(1) @Default(0.0) double averageRating,
    @HiveField(2) @Default(0) int totalRatings,
    @HiveField(3) @Default(0) int completedTrips,
    @HiveField(4) @Default([]) List<String> topTags,
    @HiveField(5) @Default([]) List<String> recentFeedback,
    @HiveField(6) @Default(true) bool isVerified,
    @HiveField(7) DateTime? lastUpdated,
  }) = _UserRatingSummary;

  factory UserRatingSummary.fromJson(Map<String, dynamic> json) =>
      _$UserRatingSummaryFromJson(json);
}

@freezed
@HiveType(typeId: 13)
class TripRatingSummary with _$TripRatingSummary {
  const factory TripRatingSummary({
    @HiveField(0) required String tripId,
    @HiveField(1) @Default(0.0) double averageRating,
    @HiveField(2) @Default(0.0) double organizationRating,
    @HiveField(3) @Default(0.0) double valueRating,
    @HiveField(4) @Default(0.0) double experienceRating,
    @HiveField(5) @Default(0) int totalRatings,
    @HiveField(6) @Default([]) List<String> topHighlights,
    @HiveField(7) @Default(0) int recommendationCount,
    @HiveField(8) DateTime? lastUpdated,
  }) = _TripRatingSummary;

  factory TripRatingSummary.fromJson(Map<String, dynamic> json) =>
      _$TripRatingSummaryFromJson(json);
}

// Rating criteria tags for users
enum UserRatingTag {
  punctual,
  friendly,
  helpful,
  respectful,
  communicative,
  organized,
  flexible,
  responsible,
  funToBeWith,
  reliable,
}

extension UserRatingTagX on UserRatingTag {
  String get label {
    switch (this) {
      case UserRatingTag.punctual:
        return 'Punctual';
      case UserRatingTag.friendly:
        return 'Friendly';
      case UserRatingTag.helpful:
        return 'Helpful';
      case UserRatingTag.respectful:
        return 'Respectful';
      case UserRatingTag.communicative:
        return 'Good Communicator';
      case UserRatingTag.organized:
        return 'Well Organized';
      case UserRatingTag.flexible:
        return 'Flexible';
      case UserRatingTag.responsible:
        return 'Responsible';
      case UserRatingTag.funToBeWith:
        return 'Fun to Be With';
      case UserRatingTag.reliable:
        return 'Reliable';
    }
  }
}

// Trip highlights
enum TripHighlight {
  wellOrganized,
  greatValue,
  amazingExperience,
  goodCommunication,
  safetyFocused,
  flexibleItinerary,
  greatAccommodation,
  excellentFood,
  funActivities,
  knowledgeableGuide,
}

extension TripHighlightX on TripHighlight {
  String get label {
    switch (this) {
      case TripHighlight.wellOrganized:
        return 'Well Organized';
      case TripHighlight.greatValue:
        return 'Great Value';
      case TripHighlight.amazingExperience:
        return 'Amazing Experience';
      case TripHighlight.goodCommunication:
        return 'Good Communication';
      case TripHighlight.safetyFocused:
        return 'Safety Focused';
      case TripHighlight.flexibleItinerary:
        return 'Flexible Itinerary';
      case TripHighlight.greatAccommodation:
        return 'Great Accommodation';
      case TripHighlight.excellentFood:
        return 'Excellent Food';
      case TripHighlight.funActivities:
        return 'Fun Activities';
      case TripHighlight.knowledgeableGuide:
        return 'Knowledgeable Guide';
    }
  }
}
