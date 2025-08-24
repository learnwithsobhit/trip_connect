import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../../services/mock_server.dart';

// Providers for fetching service rating data
final serviceRatingsProvider = FutureProvider.family<List<ServiceRating>, String>((ref, tripId) async {
  return MockServer().getServiceRatings(tripId);
});

final serviceReviewsProvider = FutureProvider.family<List<ServiceReview>, String>((ref, serviceRatingId) async {
  return MockServer().getServiceReviews(serviceRatingId);
});

final serviceRatingSummaryProvider = FutureProvider.family<ServiceRatingSummary?, String>((ref, tripId) async {
  return MockServer().getServiceRatingSummary(tripId);
});

final serviceCategoriesProvider = Provider<List<ServiceCategory>>((ref) {
  return [
    const ServiceCategory.accommodation(),
    const ServiceCategory.food(),
    const ServiceCategory.transportation(),
    const ServiceCategory.staff(),
    const ServiceCategory.activities(),
    const ServiceCategory.shopping(),
    const ServiceCategory.emergency(),
    const ServiceCategory.other(),
  ];
});

// Helper functions for UI
String getServiceCategoryName(ServiceCategory category) {
  return category.when(
    accommodation: () => 'Accommodation',
    food: () => 'Food & Dining',
    transportation: () => 'Transportation',
    staff: () => 'Staff & Service',
    activities: () => 'Activities & Attractions',
    shopping: () => 'Shopping',
    emergency: () => 'Emergency Services',
    other: () => 'Other',
  );
}

IconData getServiceCategoryIcon(ServiceCategory category) {
  return category.when(
    accommodation: () => Icons.hotel,
    food: () => Icons.restaurant,
    transportation: () => Icons.directions_car,
    staff: () => Icons.people,
    activities: () => Icons.attractions,
    shopping: () => Icons.shopping_bag,
    emergency: () => Icons.emergency,
    other: () => Icons.more_horiz,
  );
}

Color getServiceCategoryColor(ServiceCategory category) {
  return category.when(
    accommodation: () => Colors.blue,
    food: () => Colors.orange,
    transportation: () => Colors.green,
    staff: () => Colors.purple,
    activities: () => Colors.red,
    shopping: () => Colors.pink,
    emergency: () => Colors.red,
    other: () => Colors.grey,
  );
}

// Actions notifier for service rating operations
class ServiceRatingActionsNotifier extends StateNotifier<AsyncValue<void>> {
  ServiceRatingActionsNotifier() : super(const AsyncValue.data(null));

  Future<void> createServiceRating(ServiceRating rating) async {
    state = const AsyncValue.loading();
    try {
      await MockServer().createServiceRating(rating);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateServiceRating(ServiceRating rating) async {
    state = const AsyncValue.loading();
    try {
      await MockServer().updateServiceRating(rating);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deleteServiceRating(String ratingId) async {
    state = const AsyncValue.loading();
    try {
      await MockServer().deleteServiceRating(ratingId);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> addServiceReview(ServiceReview review) async {
    state = const AsyncValue.loading();
    try {
      await MockServer().addServiceReview(review);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateServiceReview(ServiceReview review) async {
    state = const AsyncValue.loading();
    try {
      await MockServer().updateServiceReview(review);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deleteServiceReview(String reviewId) async {
    state = const AsyncValue.loading();
    try {
      await MockServer().deleteServiceReview(reviewId);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

final serviceRatingActionsProvider = StateNotifierProvider<ServiceRatingActionsNotifier, AsyncValue<void>>((ref) {
  return ServiceRatingActionsNotifier();
});

// Common tags for quick selection
final commonTagsProvider = Provider<List<String>>((ref) {
  return [
    'Recommended',
    'Budget-friendly',
    'Family-friendly',
    'Romantic',
    'Adventure',
    'Luxury',
    'Local Experience',
    'Must Try',
    'Hidden Gem',
    'Tourist Trap',
    'Overpriced',
    'Poor Service',
    'Clean',
    'Dirty',
    'Noisy',
    'Quiet',
    'Crowded',
    'Peaceful',
    'Delicious',
    'Tasty',
    'Spicy',
    'Sweet',
    'Fresh',
    'Authentic',
    'Modern',
    'Traditional',
    'Convenient',
    'Accessible',
    'Scenic',
    'Historic',
  ];
});

// Category-specific rating criteria
final categoryRatingCriteriaProvider = Provider.family<Map<String, String>, ServiceCategory>((ref, category) {
  return category.when(
    accommodation: () => {
      'cleanliness': 'Cleanliness',
      'comfort': 'Comfort',
      'location': 'Location',
      'service': 'Service',
      'value': 'Value for Money',
    },
    food: () => {
      'taste': 'Taste',
      'quality': 'Quality',
      'service': 'Service',
      'ambiance': 'Ambiance',
      'value': 'Value for Money',
    },
    transportation: () => {
      'comfort': 'Comfort',
      'punctuality': 'Punctuality',
      'safety': 'Safety',
      'service': 'Service',
      'value': 'Value for Money',
    },
    staff: () => {
      'helpfulness': 'Helpfulness',
      'knowledge': 'Knowledge',
      'friendliness': 'Friendliness',
      'efficiency': 'Efficiency',
      'professionalism': 'Professionalism',
    },
    activities: () => {
      'enjoyment': 'Enjoyment',
      'safety': 'Safety',
      'organization': 'Organization',
      'value': 'Value for Money',
      'uniqueness': 'Uniqueness',
    },
    shopping: () => {
      'variety': 'Variety',
      'quality': 'Quality',
      'pricing': 'Pricing',
      'authenticity': 'Authenticity',
      'service': 'Service',
    },
    emergency: () => {
      'response_time': 'Response Time',
      'effectiveness': 'Effectiveness',
      'professionalism': 'Professionalism',
      'accessibility': 'Accessibility',
      'cost': 'Cost',
    },
    other: () => {
      'quality': 'Quality',
      'service': 'Service',
      'value': 'Value for Money',
      'convenience': 'Convenience',
      'overall': 'Overall Experience',
    },
  );
});
