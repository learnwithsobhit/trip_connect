import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';

part 'media.freezed.dart';
part 'media.g.dart';

@freezed
@HiveType(typeId: 33)
class Media with _$Media {
  const factory Media({
    @HiveField(0) required String id,
    @HiveField(1) required String tripId,
    @HiveField(2) required String uploaderId,
    @HiveField(3) required MediaType type,
    @HiveField(4) required String uri,
    @HiveField(5) String? thumbUri,
    @HiveField(6) @Default([]) List<String> tags,
    @HiveField(7) String? stopId,
    @HiveField(8) required DateTime takenAt,
    @HiveField(9) DateTime? uploadedAt,
    @HiveField(10) String? caption,
    @HiveField(11) MediaMetadata? metadata,
    @HiveField(12) @Default(false) bool isFavorite,
    @HiveField(13) @Default(MediaVisibility.everyone) MediaVisibility visibility,
  }) = _Media;

  factory Media.fromJson(Map<String, dynamic> json) => _$MediaFromJson(json);
}

@freezed
@HiveType(typeId: 34)
class MediaMetadata with _$MediaMetadata {
  const factory MediaMetadata({
    @HiveField(0) int? width,
    @HiveField(1) int? height,
    @HiveField(2) int? fileSize,
    @HiveField(3) int? duration, // for video/audio in seconds
    @HiveField(4) double? lat,
    @HiveField(5) double? lng,
    @HiveField(6) String? mimeType,
    @HiveField(7) String? originalName,
  }) = _MediaMetadata;

  factory MediaMetadata.fromJson(Map<String, dynamic> json) => _$MediaMetadataFromJson(json);
}

@freezed
@HiveType(typeId: 35)
class Document with _$Document {
  const factory Document({
    @HiveField(0) required String id,
    @HiveField(1) required String tripId,
    @HiveField(2) required String uploaderId,
    @HiveField(3) required String name,
    @HiveField(4) required String uri,
    @HiveField(5) @Default([]) List<String> tags,
    @HiveField(6) String? ocrText,
    @HiveField(7) required DateTime createdAt,
    @HiveField(8) DateTime? updatedAt,
    @HiveField(9) DocumentMetadata? metadata,
    @HiveField(10) @Default(DocumentVisibility.everyone) DocumentVisibility visibility,
    @HiveField(11) String? description,
  }) = _Document;

  factory Document.fromJson(Map<String, dynamic> json) => _$DocumentFromJson(json);
}

@freezed
@HiveType(typeId: 36)
class DocumentMetadata with _$DocumentMetadata {
  const factory DocumentMetadata({
    @HiveField(0) int? fileSize,
    @HiveField(1) String? mimeType,
    @HiveField(2) int? pageCount,
    @HiveField(3) String? originalName,
    @HiveField(4) String? checksum,
  }) = _DocumentMetadata;

  factory DocumentMetadata.fromJson(Map<String, dynamic> json) => _$DocumentMetadataFromJson(json);
}

@HiveType(typeId: 37)
enum MediaType {
  @HiveField(0)
  photo,
  @HiveField(1)
  video,
  @HiveField(2)
  audio,
}

@HiveType(typeId: 38)
enum MediaVisibility {
  @HiveField(0)
  everyone,
  @HiveField(1)
  leaders,
  @HiveField(2)
  private,
}

@HiveType(typeId: 39)
enum DocumentVisibility {
  @HiveField(0)
  everyone,
  @HiveField(1)
  leaders,
  @HiveField(2)
  private,
}
