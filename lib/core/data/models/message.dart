import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';

part 'message.freezed.dart';
part 'message.g.dart';

@freezed
@HiveType(typeId: 16)
class Message with _$Message {
  const factory Message({
    @HiveField(0) required String id,
    @HiveField(1) required String tripId,
    @HiveField(2) required String senderId,
    @HiveField(3) required MessageType type,
    @HiveField(4) required String text,
    @HiveField(5) @Default([]) List<String> tags,
    @HiveField(6) required DateTime createdAt,
    @HiveField(7) @Default(false) bool requiresAck,
    @HiveField(8) @Default([]) List<MessageAck> ack,
    @HiveField(9) String? replyToId,
    @HiveField(10) MessageAttachment? attachment,
    @HiveField(11) Poll? poll,
    @HiveField(12) @Default(false) bool isEdited,
    @HiveField(13) DateTime? editedAt,
    @HiveField(14) @Default(false) bool isDeleted,
  }) = _Message;

  factory Message.fromJson(Map<String, dynamic> json) => _$MessageFromJson(json);
}

@freezed
@HiveType(typeId: 17)
class MessageAck with _$MessageAck {
  const factory MessageAck({
    @HiveField(0) required String userId,
    @HiveField(1) required DateTime ackedAt,
  }) = _MessageAck;

  factory MessageAck.fromJson(Map<String, dynamic> json) => _$MessageAckFromJson(json);
}

@freezed
@HiveType(typeId: 18)
class MessageAttachment with _$MessageAttachment {
  const factory MessageAttachment({
    @HiveField(0) required AttachmentType type,
    @HiveField(1) required String url,
    @HiveField(2) String? thumbnailUrl,
    @HiveField(3) String? fileName,
    @HiveField(4) int? fileSize,
    @HiveField(5) String? mimeType,
  }) = _MessageAttachment;

  factory MessageAttachment.fromJson(Map<String, dynamic> json) => _$MessageAttachmentFromJson(json);
}

@freezed
@HiveType(typeId: 19)
class Poll with _$Poll {
  const factory Poll({
    @HiveField(0) required String question,
    @HiveField(1) required List<PollOption> options,
    @HiveField(2) @Default(false) bool allowMultiple,
    @HiveField(3) DateTime? expiresAt,
    @HiveField(4) @Default([]) List<PollVote> votes,
    @HiveField(5) @Default(false) bool isActive,
  }) = _Poll;

  factory Poll.fromJson(Map<String, dynamic> json) => _$PollFromJson(json);
}

@freezed
@HiveType(typeId: 20)
class PollOption with _$PollOption {
  const factory PollOption({
    @HiveField(0) required String id,
    @HiveField(1) required String text,
    @HiveField(2) String? emoji,
  }) = _PollOption;

  factory PollOption.fromJson(Map<String, dynamic> json) => _$PollOptionFromJson(json);
}

@freezed
@HiveType(typeId: 21)
class PollVote with _$PollVote {
  const factory PollVote({
    @HiveField(0) required String userId,
    @HiveField(1) required String optionId,
    @HiveField(2) required DateTime votedAt,
  }) = _PollVote;

  factory PollVote.fromJson(Map<String, dynamic> json) => _$PollVoteFromJson(json);
}

@HiveType(typeId: 22)
enum MessageType {
  @HiveField(0)
  chat,
  @HiveField(1)
  announcement,
  @HiveField(2)
  poll,
  @HiveField(3)
  system,
  @HiveField(4)
  media,
}

@HiveType(typeId: 23)
enum AttachmentType {
  @HiveField(0)
  image,
  @HiveField(1)
  video,
  @HiveField(2)
  audio,
  @HiveField(3)
  document,
  @HiveField(4)
  location,
}
