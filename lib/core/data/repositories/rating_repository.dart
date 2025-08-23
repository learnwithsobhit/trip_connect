import '../models/models.dart';
import '../../services/mock_server.dart';

class RatingRepository {
  final MockServer _mockServer = MockServer();

  /// Submit a rating for a user
  Future<Map<String, dynamic>> rateUser({
    required String ratedUserId,
    required String tripId,
    required double rating,
    String? feedback,
    List<String>? tags,
  }) async {
    return _mockServer.rateUser(
      ratedUserId: ratedUserId,
      tripId: tripId,
      rating: rating,
      feedback: feedback,
      tags: tags,
    );
  }

  /// Submit a rating for a trip
  Future<Map<String, dynamic>> rateTrip({
    required String tripId,
    required double overallRating,
    required double organizationRating,
    required double valueRating,
    required double experienceRating,
    String? feedback,
    List<String>? highlights,
    List<String>? improvements,
    bool wouldRecommend = true,
  }) async {
    return _mockServer.rateTrip(
      tripId: tripId,
      overallRating: overallRating,
      organizationRating: organizationRating,
      valueRating: valueRating,
      experienceRating: experienceRating,
      feedback: feedback,
      highlights: highlights,
      improvements: improvements,
      wouldRecommend: wouldRecommend,
    );
  }

  /// Get ratings for a specific user
  Future<List<UserRating>> getUserRatings(String userId) async {
    return _mockServer.getUserRatings(userId);
  }

  /// Get ratings for a specific trip
  Future<List<TripRating>> getTripRatings(String tripId) async {
    return _mockServer.getTripRatings(tripId);
  }

  /// Get rating given by current user for another user in a specific trip
  Future<UserRating?> getUserRatingByCurrentUser(String ratedUserId, String tripId) async {
    return _mockServer.getUserRatingByCurrentUser(ratedUserId, tripId);
  }

  /// Get trip rating given by current user
  Future<TripRating?> getTripRatingByCurrentUser(String tripId) async {
    return _mockServer.getTripRatingByCurrentUser(tripId);
  }

  /// Check if current user can join a trip based on rating requirements
  Future<Map<String, dynamic>> checkRatingEligibility(String tripId) async {
    return _mockServer.checkRatingEligibility(tripId);
  }

  /// Get trips filtered by rating
  Future<List<Trip>> getTripsFilteredByRating({
    double? minRating,
    double? maxRating,
    int? minReviews,
  }) async {
    return _mockServer.getTripsFilteredByRating(
      minRating: minRating,
      maxRating: maxRating,
      minReviews: minReviews,
    );
  }
}
