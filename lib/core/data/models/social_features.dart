import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';

import 'models.dart';

part 'social_features.freezed.dart';
part 'social_features.g.dart';

@freezed
@HiveType(typeId: 60)
class SocialPost with _$SocialPost {
  const factory SocialPost({
    @HiveField(0) required String id,
    @HiveField(1) required String tripId,
    @HiveField(2) required String authorId,
    @HiveField(3) required String content,
    @HiveField(4) required PostType type,
    @HiveField(5) required DateTime createdAt,
    @HiveField(6) DateTime? updatedAt,
    @HiveField(7) @Default([]) List<MediaItem> media,
    @HiveField(8) @Default([]) List<String> tags,
    @HiveField(9) @Default([]) List<Comment> comments,
    @HiveField(10) @Default([]) List<Reaction> reactions,
    @HiveField(11) Location? location,
    @HiveField(12) @Default(PostVisibility.tripMembers) PostVisibility visibility,
    @HiveField(13) @Default(false) bool isPinned,
    @HiveField(14) @Default(false) bool isEdited,
    @HiveField(15) Map<String, dynamic>? metadata,
  }) = _SocialPost;

  factory SocialPost.fromJson(Map<String, dynamic> json) => _$SocialPostFromJson(json);
}

@freezed
@HiveType(typeId: 61)
class Comment with _$Comment {
  const factory Comment({
    @HiveField(0) required String id,
    @HiveField(1) required String postId,
    @HiveField(2) required String authorId,
    @HiveField(3) required String content,
    @HiveField(4) required DateTime createdAt,
    @HiveField(5) DateTime? updatedAt,
    @HiveField(6) @Default([]) List<Reaction> reactions,
    @HiveField(7) String? parentCommentId, // For nested comments
    @HiveField(8) @Default(false) bool isEdited,
    @HiveField(9) List<MediaItem>? media,
  }) = _Comment;

  factory Comment.fromJson(Map<String, dynamic> json) => _$CommentFromJson(json);
}

@freezed
@HiveType(typeId: 62)
class Reaction with _$Reaction {
  const factory Reaction({
    @HiveField(0) required String id,
    @HiveField(1) required String userId,
    @HiveField(2) required ReactionType type,
    @HiveField(3) required DateTime createdAt,
    @HiveField(4) String? targetId, // postId or commentId
    @HiveField(5) @Default(ReactionTarget.post) ReactionTarget targetType, // post or comment
  }) = _Reaction;

  factory Reaction.fromJson(Map<String, dynamic> json) => _$ReactionFromJson(json);
}

@freezed
@HiveType(typeId: 63)
class MediaItem with _$MediaItem {
  const factory MediaItem({
    @HiveField(0) required String id,
    @HiveField(1) required SocialMediaType type,
    @HiveField(2) required String url,
    @HiveField(3) String? thumbnailUrl,
    @HiveField(4) String? caption,
    @HiveField(5) Map<String, dynamic>? metadata,
    @HiveField(6) DateTime? createdAt,
    @HiveField(7) String? uploadedBy,
  }) = _MediaItem;

  factory MediaItem.fromJson(Map<String, dynamic> json) => _$MediaItemFromJson(json);
}

@freezed
@HiveType(typeId: 64)
class ShareableContent with _$ShareableContent {
  const factory ShareableContent({
    @HiveField(0) required String id,
    @HiveField(1) required String tripId,
    @HiveField(2) required ContentType type,
    @HiveField(3) required String title,
    @HiveField(4) required String description,
    @HiveField(5) required String shareUrl,
    @HiveField(6) String? imageUrl,
    @HiveField(7) @Default([]) List<SocialPlatform> platforms,
    @HiveField(8) required DateTime createdAt,
    @HiveField(9) String? createdBy,
    @HiveField(10) Map<String, dynamic>? metadata,
  }) = _ShareableContent;

  factory ShareableContent.fromJson(Map<String, dynamic> json) => _$ShareableContentFromJson(json);
}

@freezed
@HiveType(typeId: 65)
class TripStory with _$TripStory {
  const factory TripStory({
    @HiveField(0) required String id,
    @HiveField(1) required String tripId,
    @HiveField(2) required String authorId,
    @HiveField(3) required String title,
    @HiveField(4) required String content,
    @HiveField(5) required List<StoryMedia> media,
    @HiveField(6) required DateTime createdAt,
    @HiveField(7) DateTime? expiresAt,
    @HiveField(8) @Default(StoryVisibility.tripMembers) StoryVisibility visibility,
    @HiveField(9) @Default([]) List<String> viewedBy,
    @HiveField(10) Location? location,
    @HiveField(11) Map<String, dynamic>? metadata,
  }) = _TripStory;

  factory TripStory.fromJson(Map<String, dynamic> json) => _$TripStoryFromJson(json);
}

@freezed
@HiveType(typeId: 66)
class StoryMedia with _$StoryMedia {
  const factory StoryMedia({
    @HiveField(0) required String id,
    @HiveField(1) required SocialMediaType type,
    @HiveField(2) required String url,
    @HiveField(3) String? caption,
    @HiveField(4) Duration? duration,
    @HiveField(5) Map<String, dynamic>? metadata,
  }) = _StoryMedia;

  factory StoryMedia.fromJson(Map<String, dynamic> json) => _$StoryMediaFromJson(json);
}

// Enums
@HiveType(typeId: 67)
enum PostType {
  @HiveField(0)
  text,
  @HiveField(1)
  photo,
  @HiveField(2)
  video,
  @HiveField(3)
  location,
  @HiveField(4)
  milestone,
  @HiveField(5)
  announcement,
  @HiveField(6)
  memory,
}

@HiveType(typeId: 68)
enum PostVisibility {
  @HiveField(0)
  tripMembers,
  @HiveField(1)
  public,
  @HiveField(2)
  friends,
  @HiveField(3)
  private,
}

@HiveType(typeId: 69)
enum ReactionType {
  @HiveField(0)
  like,
  @HiveField(1)
  love,
  @HiveField(2)
  laugh,
  @HiveField(3)
  wow,
  @HiveField(4)
  sad,
  @HiveField(5)
  angry,
  @HiveField(6)
  fire,
  @HiveField(7)
  heart,
  @HiveField(8)
  thumbsUp,
  @HiveField(9)
  clap,
}

@HiveType(typeId: 70)
enum ReactionTarget {
  @HiveField(0)
  post,
  @HiveField(1)
  comment,
}

@HiveType(typeId: 71)
enum SocialMediaType {
  @HiveField(0)
  image,
  @HiveField(1)
  video,
  @HiveField(2)
  audio,
  @HiveField(3)
  document,
}

@HiveType(typeId: 72)
enum ContentType {
  @HiveField(0)
  tripHighlight,
  @HiveField(1)
  photoAlbum,
  @HiveField(2)
  video,
  @HiveField(3)
  story,
  @HiveField(4)
  achievement,
  @HiveField(5)
  memory,
}

@HiveType(typeId: 73)
enum SocialPlatform {
  @HiveField(0)
  instagram,
  @HiveField(1)
  facebook,
  @HiveField(2)
  twitter,
  @HiveField(3)
  whatsapp,
  @HiveField(4)
  telegram,
  @HiveField(5)
  email,
  @HiveField(6)
  sms,
  @HiveField(7)
  copyLink,
}

@HiveType(typeId: 74)
enum StoryVisibility {
  @HiveField(0)
  tripMembers,
  @HiveField(1)
  public,
  @HiveField(2)
  friends,
  @HiveField(3)
  private,
}

// Extension methods for better UX
extension PostTypeX on PostType {
  String get displayName {
    switch (this) {
      case PostType.text:
        return 'Text';
      case PostType.photo:
        return 'Photo';
      case PostType.video:
        return 'Video';
      case PostType.location:
        return 'Location';
      case PostType.milestone:
        return 'Milestone';
      case PostType.announcement:
        return 'Announcement';
      case PostType.memory:
        return 'Memory';
    }
  }

  String get icon {
    switch (this) {
      case PostType.text:
        return '📝';
      case PostType.photo:
        return '📸';
      case PostType.video:
        return '🎥';
      case PostType.location:
        return '📍';
      case PostType.milestone:
        return '🏆';
      case PostType.announcement:
        return '📢';
      case PostType.memory:
        return '💭';
    }
  }
}

extension ReactionTypeX on ReactionType {
  String get displayName {
    switch (this) {
      case ReactionType.like:
        return 'Like';
      case ReactionType.love:
        return 'Love';
      case ReactionType.laugh:
        return 'Laugh';
      case ReactionType.wow:
        return 'Wow';
      case ReactionType.sad:
        return 'Sad';
      case ReactionType.angry:
        return 'Angry';
      case ReactionType.fire:
        return 'Fire';
      case ReactionType.heart:
        return 'Heart';
      case ReactionType.thumbsUp:
        return 'Thumbs Up';
      case ReactionType.clap:
        return 'Clap';
    }
  }

  String get emoji {
    switch (this) {
      case ReactionType.like:
        return '👍';
      case ReactionType.love:
        return '❤️';
      case ReactionType.laugh:
        return '😂';
      case ReactionType.wow:
        return '😮';
      case ReactionType.sad:
        return '😢';
      case ReactionType.angry:
        return '😠';
      case ReactionType.fire:
        return '🔥';
      case ReactionType.heart:
        return '💖';
      case ReactionType.thumbsUp:
        return '👍';
      case ReactionType.clap:
        return '👏';
    }
  }
}

extension SocialPlatformX on SocialPlatform {
  String get displayName {
    switch (this) {
      case SocialPlatform.instagram:
        return 'Instagram';
      case SocialPlatform.facebook:
        return 'Facebook';
      case SocialPlatform.twitter:
        return 'Twitter';
      case SocialPlatform.whatsapp:
        return 'WhatsApp';
      case SocialPlatform.telegram:
        return 'Telegram';
      case SocialPlatform.email:
        return 'Email';
      case SocialPlatform.sms:
        return 'SMS';
      case SocialPlatform.copyLink:
        return 'Copy Link';
    }
  }

  String get icon {
    switch (this) {
      case SocialPlatform.instagram:
        return '📷';
      case SocialPlatform.facebook:
        return '📘';
      case SocialPlatform.twitter:
        return '🐦';
      case SocialPlatform.whatsapp:
        return '💬';
      case SocialPlatform.telegram:
        return '📱';
      case SocialPlatform.email:
        return '📧';
      case SocialPlatform.sms:
        return '📱';
      case SocialPlatform.copyLink:
        return '🔗';
    }
  }
}

extension ContentTypeX on ContentType {
  String get displayName {
    switch (this) {
      case ContentType.tripHighlight:
        return 'Trip Highlight';
      case ContentType.photoAlbum:
        return 'Photo Album';
      case ContentType.video:
        return 'Video';
      case ContentType.story:
        return 'Story';
      case ContentType.achievement:
        return 'Achievement';
      case ContentType.memory:
        return 'Memory';
    }
  }

  String get icon {
    switch (this) {
      case ContentType.tripHighlight:
        return '🌟';
      case ContentType.photoAlbum:
        return '📸';
      case ContentType.video:
        return '🎥';
      case ContentType.story:
        return '📖';
      case ContentType.achievement:
        return '🏆';
      case ContentType.memory:
        return '💭';
    }
  }
}
