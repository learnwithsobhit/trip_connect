import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';

part 'entertainment.freezed.dart';
part 'entertainment.g.dart';

@freezed
@HiveType(typeId: 30)
class EntertainmentActivity with _$EntertainmentActivity {
  const factory EntertainmentActivity({
    @HiveField(0) required String id,
    @HiveField(1) required String tripId,
    @HiveField(2) required String title,
    @HiveField(3) required String description,
    @HiveField(4) required ActivityType type,
    @HiveField(5) required ActivityStatus status,
    @HiveField(6) required DateTime scheduledAt,
    @HiveField(7) required int durationMinutes,
    @HiveField(8) required List<String> participantIds,
    @HiveField(9) required String organizerId,
    @HiveField(10) required DateTime createdAt,
    @HiveField(11) required DateTime updatedAt,
    @HiveField(12) String? location,
    @HiveField(13) int? maxParticipants,
    @HiveField(14) double? cost,
    @HiveField(15) String? imageUrl,
    @HiveField(16) Map<String, dynamic>? gameRules,
    @HiveField(17) List<String>? tags,
    @HiveField(18) String? notes,
  }) = _EntertainmentActivity;

  factory EntertainmentActivity.fromJson(Map<String, dynamic> json) => _$EntertainmentActivityFromJson(json);
}

@freezed
@HiveType(typeId: 31)
class GameSession with _$GameSession {
  const factory GameSession({
    @HiveField(0) required String id,
    @HiveField(1) required String activityId,
    @HiveField(2) required String gameType,
    @HiveField(3) required GameStatus status,
    @HiveField(4) required DateTime startedAt,
    @HiveField(5) DateTime? endedAt,
    @HiveField(6) required List<String> playerIds,
    @HiveField(7) required Map<String, int> scores,
    @HiveField(8) required Map<String, dynamic> gameData,
    @HiveField(9) String? winnerId,
    @HiveField(10) List<String>? winners,
  }) = _GameSession;

  factory GameSession.fromJson(Map<String, dynamic> json) => _$GameSessionFromJson(json);
}

@freezed
@HiveType(typeId: 32)
class EntertainmentCategory with _$EntertainmentCategory {
  const factory EntertainmentCategory({
    @HiveField(0) required String id,
    @HiveField(1) required String name,
    @HiveField(2) required String description,
    @HiveField(3) required String icon,
    @HiveField(4) required String color,
    @HiveField(5) required List<String> tags,
    @HiveField(6) required int minParticipants,
    @HiveField(7) required int maxParticipants,
    @HiveField(8) required int estimatedDuration,
    @HiveField(9) required bool requiresEquipment,
    @HiveField(10) List<String>? equipment,
    @HiveField(11) String? instructions,
  }) = _EntertainmentCategory;

  factory EntertainmentCategory.fromJson(Map<String, dynamic> json) => _$EntertainmentCategoryFromJson(json);
}

@freezed
@HiveType(typeId: 33)
class EntertainmentReport with _$EntertainmentReport {
  const factory EntertainmentReport({
    @HiveField(0) required String tripId,
    @HiveField(1) required int totalActivities,
    @HiveField(2) required int completedActivities,
    @HiveField(3) required int totalParticipants,
    @HiveField(4) required double averageParticipation,
    @HiveField(5) required List<ActivityType> popularTypes,
    @HiveField(6) required List<String> topParticipants,
    @HiveField(7) required List<GameSession> recentGames,
    @HiveField(8) required Map<String, int> categoryStats,
    @HiveField(9) required DateTime generatedAt,
  }) = _EntertainmentReport;

  factory EntertainmentReport.fromJson(Map<String, dynamic> json) => _$EntertainmentReportFromJson(json);
}

enum ActivityType {
  @HiveField(0)
  game,
  @HiveField(1)
  quiz,
  @HiveField(2)
  challenge,
  @HiveField(3)
  workshop,
  @HiveField(4)
  performance,
  @HiveField(5)
  outdoor,
  @HiveField(6)
  indoor,
  @HiveField(7)
  teamBuilding,
  @HiveField(8)
  cultural,
  @HiveField(9)
  adventure,
}

enum ActivityStatus {
  @HiveField(0)
  planned,
  @HiveField(1)
  active,
  @HiveField(2)
  completed,
  @HiveField(3)
  cancelled,
  @HiveField(4)
  postponed,
}

enum GameStatus {
  @HiveField(0)
  waiting,
  @HiveField(1)
  active,
  @HiveField(2)
  completed,
  @HiveField(3)
  paused,
}

enum GameType {
  @HiveField(0)
  trivia,
  @HiveField(1)
  wordGame,
  @HiveField(2)
  puzzle,
  @HiveField(3)
  scavengerHunt,
  @HiveField(4)
  photoChallenge,
  @HiveField(5)
  storytelling,
  @HiveField(6)
  charades,
  @HiveField(7)
  boardGame,
  @HiveField(8)
  cardGame,
  @HiveField(9)
  outdoorGame,
}
