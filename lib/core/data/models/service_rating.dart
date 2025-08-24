import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';
import 'models.dart'; // For Location

part 'service_rating.freezed.dart';
part 'service_rating.g.dart';

@freezed
class ServiceRating with _$ServiceRating {
  const factory ServiceRating({
    required String id,
    required String tripId,
    required String serviceName,
    required ServiceCategory category,
    required Location location,
    required String stopName,
    required double overallRating,
    required Map<String, double> categoryRatings,
    required String review,
    required List<String> tags,
    required List<String> photoUrls,
    required String userId,
    required String userName,
    required DateTime createdAt,
    required DateTime updatedAt,
    String? serviceProvider,
    String? contactInfo,
    double? price,
    String? currency,
    Map<String, dynamic>? metadata,
  }) = _ServiceRating;

  factory ServiceRating.fromJson(Map<String, dynamic> json) => _$ServiceRatingFromJson(json);
}

@freezed
class ServiceCategory with _$ServiceCategory {
  const factory ServiceCategory.accommodation() = _Accommodation;
  const factory ServiceCategory.food() = _Food;
  const factory ServiceCategory.transportation() = _Transportation;
  const factory ServiceCategory.staff() = _Staff;
  const factory ServiceCategory.activities() = _Activities;
  const factory ServiceCategory.shopping() = _Shopping;
  const factory ServiceCategory.emergency() = _Emergency;
  const factory ServiceCategory.other() = _Other;

  factory ServiceCategory.fromJson(Map<String, dynamic> json) => _$ServiceCategoryFromJson(json);
}

@freezed
class ServiceReview with _$ServiceReview {
  const factory ServiceReview({
    required String id,
    required String serviceRatingId,
    required String userId,
    required String userName,
    required String comment,
    required double rating,
    required List<String> tags,
    required DateTime createdAt,
    List<String>? photoUrls,
    Map<String, dynamic>? metadata,
  }) = _ServiceReview;

  factory ServiceReview.fromJson(Map<String, dynamic> json) => _$ServiceReviewFromJson(json);
}

@freezed
class ServiceRatingSummary with _$ServiceRatingSummary {
  const factory ServiceRatingSummary({
    required String tripId,
    required int totalRatings,
    required double averageOverallRating,
    required Map<String, double> categoryAverages,
    required Map<String, int> categoryCounts,
    required List<String> topRatedServices,
    required List<String> lowestRatedServices,
    required Map<String, int> tagFrequency,
    required DateTime generatedAt,
  }) = _ServiceRatingSummary;

  factory ServiceRatingSummary.fromJson(Map<String, dynamic> json) => _$ServiceRatingSummaryFromJson(json);
}

@freezed
class ServiceRatingFilter with _$ServiceRatingFilter {
  const factory ServiceRatingFilter({
    ServiceCategory? category,
    double? minRating,
    double? maxRating,
    List<String>? tags,
    String? location,
    DateTime? fromDate,
    DateTime? toDate,
    String? serviceProvider,
  }) = _ServiceRatingFilter;

  factory ServiceRatingFilter.fromJson(Map<String, dynamic> json) => _$ServiceRatingFilterFromJson(json);
}
