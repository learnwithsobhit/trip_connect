import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/entertainment.dart';
import '../models/models.dart';
import '../../services/mock_server.dart';

// Entertainment Activities Provider
final entertainmentActivitiesProvider = FutureProvider.family<List<EntertainmentActivity>, String>((ref, tripId) async {
  final mockServer = MockServer();
  return await mockServer.getEntertainmentActivities(tripId);
});

// Game Sessions Provider
final gameSessionsProvider = FutureProvider.family<List<GameSession>, String>((ref, tripId) async {
  final mockServer = MockServer();
  return await mockServer.getGameSessions(tripId);
});

// Entertainment Categories Provider
final entertainmentCategoriesProvider = Provider<List<EntertainmentCategory>>((ref) {
  return [
    const EntertainmentCategory(
      id: 'trivia',
      name: 'Trivia & Quiz',
      description: 'Test your knowledge with fun trivia games',
      icon: '🎯',
      color: '#FF6B6B',
      tags: ['knowledge', 'fun', 'competitive'],
      minParticipants: 2,
      maxParticipants: 10,
      estimatedDuration: 30,
      requiresEquipment: false,
      instructions: 'Answer questions to earn points and compete with friends!',
    ),
    const EntertainmentCategory(
      id: 'wordgames',
      name: 'Word Games',
      description: 'Challenge your vocabulary and word skills',
      icon: '📝',
      color: '#4ECDC4',
      tags: ['vocabulary', 'creative', 'brain'],
      minParticipants: 2,
      maxParticipants: 8,
      estimatedDuration: 20,
      requiresEquipment: false,
      instructions: 'Create words, solve puzzles, and expand your vocabulary!',
    ),
    const EntertainmentCategory(
      id: 'scavengerhunt',
      name: 'Scavenger Hunt',
      description: 'Explore and discover hidden treasures',
      icon: '🔍',
      color: '#45B7D1',
      tags: ['exploration', 'adventure', 'teamwork'],
      minParticipants: 3,
      maxParticipants: 15,
      estimatedDuration: 60,
      requiresEquipment: true,
      equipment: ['Camera', 'Clues', 'Timer'],
      instructions: 'Follow clues to find hidden items and complete challenges!',
    ),
    const EntertainmentCategory(
      id: 'photochallenge',
      name: 'Photo Challenge',
      description: 'Capture creative and fun moments',
      icon: '📸',
      color: '#96CEB4',
      tags: ['photography', 'creative', 'memories'],
      minParticipants: 2,
      maxParticipants: 12,
      estimatedDuration: 45,
      requiresEquipment: true,
      equipment: ['Camera/Phone'],
      instructions: 'Take photos based on themes and compete for the best shot!',
    ),
    const EntertainmentCategory(
      id: 'storytelling',
      name: 'Storytelling',
      description: 'Create and share amazing stories together',
      icon: '📚',
      color: '#FFEAA7',
      tags: ['creative', 'imagination', 'collaboration'],
      minParticipants: 3,
      maxParticipants: 10,
      estimatedDuration: 40,
      requiresEquipment: false,
      instructions: 'Build stories together, one sentence at a time!',
    ),
    const EntertainmentCategory(
      id: 'charades',
      name: 'Charades',
      description: 'Act out words and phrases without speaking',
      icon: '🎭',
      color: '#DDA0DD',
      tags: ['acting', 'fun', 'teamwork'],
      minParticipants: 4,
      maxParticipants: 12,
      estimatedDuration: 30,
      requiresEquipment: false,
      instructions: 'Act out words while your team tries to guess!',
    ),
    const EntertainmentCategory(
      id: 'outdoorgames',
      name: 'Outdoor Games',
      description: 'Active games for outdoor fun',
      icon: '🏃',
      color: '#FF8C42',
      tags: ['active', 'outdoor', 'fitness'],
      minParticipants: 4,
      maxParticipants: 20,
      estimatedDuration: 60,
      requiresEquipment: true,
      equipment: ['Ball', 'Cones', 'Timer'],
      instructions: 'Get active with fun outdoor games and challenges!',
    ),
    const EntertainmentCategory(
      id: 'boardgames',
      name: 'Board Games',
      description: 'Classic and modern board games',
      icon: '🎲',
      color: '#A8E6CF',
      tags: ['strategy', 'classic', 'social'],
      minParticipants: 2,
      maxParticipants: 8,
      estimatedDuration: 90,
      requiresEquipment: true,
      equipment: ['Board Game', 'Pieces'],
      instructions: 'Enjoy classic board games with friends!',
    ),
    const EntertainmentCategory(
      id: 'cultural',
      name: 'Cultural Activities',
      description: 'Learn about local culture and traditions',
      icon: '🏛️',
      color: '#FFB6C1',
      tags: ['cultural', 'educational', 'local'],
      minParticipants: 2,
      maxParticipants: 15,
      estimatedDuration: 120,
      requiresEquipment: false,
      instructions: 'Immerse yourself in local culture and traditions!',
    ),
    const EntertainmentCategory(
      id: 'team-building',
      name: 'Team Building',
      description: 'Build stronger bonds with team activities',
      icon: '🤝',
      color: '#87CEEB',
      tags: ['teamwork', 'bonding', 'leadership'],
      minParticipants: 6,
      maxParticipants: 20,
      estimatedDuration: 90,
      requiresEquipment: true,
      equipment: ['Ropes', 'Blindfolds', 'Timer'],
      instructions: 'Work together to complete challenging team activities!',
    ),
  ];
});

// Entertainment Report Provider
final entertainmentReportProvider = FutureProvider.family<EntertainmentReport?, String>((ref, tripId) async {
  final mockServer = MockServer();
  return await mockServer.getEntertainmentReport(tripId);
});

// Entertainment Actions Notifier
class EntertainmentActionsNotifier extends StateNotifier<AsyncValue<void>> {
  final MockServer _mockServer;

  EntertainmentActionsNotifier(this._mockServer) : super(const AsyncValue.data(null));

  Future<void> createActivity({
    required String tripId,
    required String title,
    required String description,
    required ActivityType type,
    required DateTime scheduledAt,
    required int durationMinutes,
    required List<String> participantIds,
    required String organizerId,
    String? location,
    int? maxParticipants,
    double? cost,
    String? imageUrl,
    Map<String, dynamic>? gameRules,
    List<String>? tags,
    String? notes,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _mockServer.createEntertainmentActivity(
        tripId: tripId,
        title: title,
        description: description,
        type: type,
        scheduledAt: scheduledAt,
        durationMinutes: durationMinutes,
        participantIds: participantIds,
        organizerId: organizerId,
        location: location,
        maxParticipants: maxParticipants,
        cost: cost,
        imageUrl: imageUrl,
        gameRules: gameRules,
        tags: tags,
        notes: notes,
      );
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateActivity({
    required String activityId,
    required String title,
    required String description,
    required ActivityType type,
    required DateTime scheduledAt,
    required int durationMinutes,
    required List<String> participantIds,
    String? location,
    int? maxParticipants,
    double? cost,
    String? imageUrl,
    Map<String, dynamic>? gameRules,
    List<String>? tags,
    String? notes,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _mockServer.updateEntertainmentActivity(
        activityId: activityId,
        title: title,
        description: description,
        type: type,
        scheduledAt: scheduledAt,
        durationMinutes: durationMinutes,
        participantIds: participantIds,
        location: location,
        maxParticipants: maxParticipants,
        cost: cost,
        imageUrl: imageUrl,
        gameRules: gameRules,
        tags: tags,
        notes: notes,
      );
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deleteActivity(String activityId) async {
    state = const AsyncValue.loading();
    try {
      await _mockServer.deleteEntertainmentActivity(activityId);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> joinActivity(String activityId, String userId) async {
    state = const AsyncValue.loading();
    try {
      await _mockServer.joinEntertainmentActivity(activityId, userId);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> leaveActivity(String activityId, String userId) async {
    state = const AsyncValue.loading();
    try {
      await _mockServer.leaveEntertainmentActivity(activityId, userId);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> startGameSession({
    required String activityId,
    required String gameType,
    required List<String> playerIds,
    required Map<String, dynamic> gameData,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _mockServer.startGameSession(
        activityId: activityId,
        gameType: gameType,
        playerIds: playerIds,
        gameData: gameData,
      );
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateGameScore({
    required String sessionId,
    required String playerId,
    required int score,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _mockServer.updateGameScore(
        sessionId: sessionId,
        playerId: playerId,
        score: score,
      );
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> endGameSession({
    required String sessionId,
    String? winnerId,
    List<String>? winners,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _mockServer.endGameSession(
        sessionId: sessionId,
        winnerId: winnerId,
        winners: winners,
      );
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

final entertainmentActionsProvider = StateNotifierProvider<EntertainmentActionsNotifier, AsyncValue<void>>((ref) {
  return EntertainmentActionsNotifier(MockServer());
});

// Activity Type Provider
final activityTypesProvider = Provider<List<ActivityType>>((ref) {
  return ActivityType.values;
});

// Game Type Provider
final gameTypesProvider = Provider<List<GameType>>((ref) {
  return GameType.values;
});
