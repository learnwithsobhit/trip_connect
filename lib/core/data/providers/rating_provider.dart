import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../repositories/rating_repository.dart';

// ============================================================================
// Repository Providers
// ============================================================================

final ratingRepositoryProvider = Provider<RatingRepository>((ref) {
  return RatingRepository();
});

// ============================================================================
// Rating Providers
// ============================================================================

/// Submit a user rating
final submitUserRatingProvider = FutureProvider.family<Map<String, dynamic>, UserRatingRequest>((ref, request) async {
  final repository = ref.read(ratingRepositoryProvider);
  return repository.rateUser(
    ratedUserId: request.ratedUserId,
    tripId: request.tripId,
    rating: request.rating,
    feedback: request.feedback,
    tags: request.tags,
  );
});

/// Submit a trip rating
final submitTripRatingProvider = FutureProvider.family<Map<String, dynamic>, TripRatingRequest>((ref, request) async {
  final repository = ref.read(ratingRepositoryProvider);
  return repository.rateTrip(
    tripId: request.tripId,
    overallRating: request.overallRating,
    organizationRating: request.organizationRating,
    valueRating: request.valueRating,
    experienceRating: request.experienceRating,
    feedback: request.feedback,
    highlights: request.highlights,
    improvements: request.improvements,
    wouldRecommend: request.wouldRecommend,
  );
});

/// Get user ratings
final userRatingsProvider = FutureProvider.family<List<UserRating>, String>((ref, userId) async {
  final repository = ref.read(ratingRepositoryProvider);
  return repository.getUserRatings(userId);
});

/// Get trip ratings
final tripRatingsProvider = FutureProvider.family<List<TripRating>, String>((ref, tripId) async {
  final repository = ref.read(ratingRepositoryProvider);
  return repository.getTripRatings(tripId);
});

/// Get user rating by current user
final userRatingByCurrentUserProvider = FutureProvider.family<UserRating?, UserRatingQuery>((ref, query) async {
  final repository = ref.read(ratingRepositoryProvider);
  return repository.getUserRatingByCurrentUser(query.ratedUserId, query.tripId);
});

/// Get trip rating by current user
final tripRatingByCurrentUserProvider = FutureProvider.family<TripRating?, String>((ref, tripId) async {
  final repository = ref.read(ratingRepositoryProvider);
  return repository.getTripRatingByCurrentUser(tripId);
});

/// Check rating eligibility for trip joining
final ratingEligibilityProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, tripId) async {
  final repository = ref.read(ratingRepositoryProvider);
  return repository.checkRatingEligibility(tripId);
});

/// Get trips filtered by rating
final tripsFilteredByRatingProvider = FutureProvider.family<List<Trip>, RatingFilter>((ref, filter) async {
  final repository = ref.read(ratingRepositoryProvider);
  return repository.getTripsFilteredByRating(
    minRating: filter.minRating,
    maxRating: filter.maxRating,
    minReviews: filter.minReviews,
  );
});

// ============================================================================
// Helper Classes
// ============================================================================

class UserRatingRequest {
  final String ratedUserId;
  final String tripId;
  final double rating;
  final String? feedback;
  final List<String>? tags;

  const UserRatingRequest({
    required this.ratedUserId,
    required this.tripId,
    required this.rating,
    this.feedback,
    this.tags,
  });
}

class TripRatingRequest {
  final String tripId;
  final double overallRating;
  final double organizationRating;
  final double valueRating;
  final double experienceRating;
  final String? feedback;
  final List<String>? highlights;
  final List<String>? improvements;
  final bool wouldRecommend;

  const TripRatingRequest({
    required this.tripId,
    required this.overallRating,
    required this.organizationRating,
    required this.valueRating,
    required this.experienceRating,
    this.feedback,
    this.highlights,
    this.improvements,
    this.wouldRecommend = true,
  });
}

class UserRatingQuery {
  final String ratedUserId;
  final String tripId;

  const UserRatingQuery({
    required this.ratedUserId,
    required this.tripId,
  });
}

class RatingFilter {
  final double? minRating;
  final double? maxRating;
  final int? minReviews;

  const RatingFilter({
    this.minRating,
    this.maxRating,
    this.minReviews,
  });
}

// ============================================================================
// State Management for Rating Forms
// ============================================================================

class UserRatingFormState {
  final double rating;
  final String feedback;
  final List<UserRatingTag> selectedTags;
  final bool isSubmitting;
  final String? error;

  const UserRatingFormState({
    this.rating = 5.0,
    this.feedback = '',
    this.selectedTags = const [],
    this.isSubmitting = false,
    this.error,
  });

  UserRatingFormState copyWith({
    double? rating,
    String? feedback,
    List<UserRatingTag>? selectedTags,
    bool? isSubmitting,
    String? error,
  }) {
    return UserRatingFormState(
      rating: rating ?? this.rating,
      feedback: feedback ?? this.feedback,
      selectedTags: selectedTags ?? this.selectedTags,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: error ?? this.error,
    );
  }
}

class TripRatingFormState {
  final double overallRating;
  final double organizationRating;
  final double valueRating;
  final double experienceRating;
  final String feedback;
  final List<TripHighlight> selectedHighlights;
  final List<String> improvements;
  final bool wouldRecommend;
  final bool isSubmitting;
  final String? error;

  const TripRatingFormState({
    this.overallRating = 5.0,
    this.organizationRating = 5.0,
    this.valueRating = 5.0,
    this.experienceRating = 5.0,
    this.feedback = '',
    this.selectedHighlights = const [],
    this.improvements = const [],
    this.wouldRecommend = true,
    this.isSubmitting = false,
    this.error,
  });

  TripRatingFormState copyWith({
    double? overallRating,
    double? organizationRating,
    double? valueRating,
    double? experienceRating,
    String? feedback,
    List<TripHighlight>? selectedHighlights,
    List<String>? improvements,
    bool? wouldRecommend,
    bool? isSubmitting,
    String? error,
  }) {
    return TripRatingFormState(
      overallRating: overallRating ?? this.overallRating,
      organizationRating: organizationRating ?? this.organizationRating,
      valueRating: valueRating ?? this.valueRating,
      experienceRating: experienceRating ?? this.experienceRating,
      feedback: feedback ?? this.feedback,
      selectedHighlights: selectedHighlights ?? this.selectedHighlights,
      improvements: improvements ?? this.improvements,
      wouldRecommend: wouldRecommend ?? this.wouldRecommend,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: error ?? this.error,
    );
  }
}

// State notifiers for rating forms
class UserRatingFormNotifier extends StateNotifier<UserRatingFormState> {
  UserRatingFormNotifier() : super(const UserRatingFormState());

  void updateRating(double rating) {
    state = state.copyWith(rating: rating);
  }

  void updateFeedback(String feedback) {
    state = state.copyWith(feedback: feedback);
  }

  void toggleTag(UserRatingTag tag) {
    final selectedTags = List<UserRatingTag>.from(state.selectedTags);
    if (selectedTags.contains(tag)) {
      selectedTags.remove(tag);
    } else {
      selectedTags.add(tag);
    }
    state = state.copyWith(selectedTags: selectedTags);
  }

  void setSubmitting(bool isSubmitting) {
    state = state.copyWith(isSubmitting: isSubmitting);
  }

  void setError(String? error) {
    state = state.copyWith(error: error);
  }

  void reset() {
    state = const UserRatingFormState();
  }
}

class TripRatingFormNotifier extends StateNotifier<TripRatingFormState> {
  TripRatingFormNotifier() : super(const TripRatingFormState());

  void updateOverallRating(double rating) {
    state = state.copyWith(overallRating: rating);
  }

  void updateOrganizationRating(double rating) {
    state = state.copyWith(organizationRating: rating);
  }

  void updateValueRating(double rating) {
    state = state.copyWith(valueRating: rating);
  }

  void updateExperienceRating(double rating) {
    state = state.copyWith(experienceRating: rating);
  }

  void updateFeedback(String feedback) {
    state = state.copyWith(feedback: feedback);
  }

  void toggleHighlight(TripHighlight highlight) {
    final selectedHighlights = List<TripHighlight>.from(state.selectedHighlights);
    if (selectedHighlights.contains(highlight)) {
      selectedHighlights.remove(highlight);
    } else {
      selectedHighlights.add(highlight);
    }
    state = state.copyWith(selectedHighlights: selectedHighlights);
  }

  void updateImprovements(List<String> improvements) {
    state = state.copyWith(improvements: improvements);
  }

  void updateWouldRecommend(bool wouldRecommend) {
    state = state.copyWith(wouldRecommend: wouldRecommend);
  }

  void setSubmitting(bool isSubmitting) {
    state = state.copyWith(isSubmitting: isSubmitting);
  }

  void setError(String? error) {
    state = state.copyWith(error: error);
  }

  void reset() {
    state = const TripRatingFormState();
  }
}

// Providers for rating form state
final userRatingFormProvider = StateNotifierProvider.family<UserRatingFormNotifier, UserRatingFormState, String>((ref, tripId) {
  return UserRatingFormNotifier();
});

final tripRatingFormProvider = StateNotifierProvider.family<TripRatingFormNotifier, TripRatingFormState, String>((ref, tripId) {
  return TripRatingFormNotifier();
});
