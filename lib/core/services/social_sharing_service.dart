import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../data/models/social_features.dart';
import '../data/models/models.dart';

class SocialSharingService {
  static final SocialSharingService _instance = SocialSharingService._internal();
  factory SocialSharingService() => _instance;
  SocialSharingService._internal();

  final _uuid = const Uuid();

  /// Share trip content to social platforms
  Future<bool> shareToSocialPlatform({
    required ShareableContent content,
    required SocialPlatform platform,
    String? customMessage,
  }) async {
    try {
      final shareMessage = customMessage ?? _generateShareMessage(content);
      final shareUrl = content.shareUrl;

      switch (platform) {
        case SocialPlatform.instagram:
          return await _shareToInstagram(content, shareMessage);
        case SocialPlatform.facebook:
          return await _shareToFacebook(shareUrl, shareMessage);
        case SocialPlatform.twitter:
          return await _shareToTwitter(shareUrl, shareMessage);
        case SocialPlatform.whatsapp:
          return await _shareToWhatsApp(shareUrl, shareMessage);
        case SocialPlatform.telegram:
          return await _shareToTelegram(shareUrl, shareMessage);
        case SocialPlatform.email:
          return await _shareViaEmail(content, shareMessage);
        case SocialPlatform.sms:
          return await _shareViaSMS(shareUrl, shareMessage);
        case SocialPlatform.copyLink:
          return await _copyToClipboard(shareUrl, shareMessage);
      }
    } catch (e) {
      debugPrint('Error sharing to $platform: $e');
      return false;
    }
  }

  /// Share trip highlight to Instagram
  Future<bool> _shareToInstagram(ShareableContent content, String message) async {
    try {
      // Instagram sharing requires specific format
      final instagramMessage = _formatForInstagram(content, message);
      
      // For Instagram, we typically share images with captions
      if (content.imageUrl != null) {
        // Download and share image with caption
        final imageFile = await _downloadImage(content.imageUrl!);
        if (imageFile != null) {
          await Share.shareXFiles(
            [XFile(imageFile.path)],
            text: instagramMessage,
            subject: content.title,
          );
          return true;
        }
      }
      
      // Fallback to text sharing
      await Share.share(instagramMessage, subject: content.title);
      return true;
    } catch (e) {
      debugPrint('Error sharing to Instagram: $e');
      return false;
    }
  }

  /// Share to Facebook
  Future<bool> _shareToFacebook(String url, String message) async {
    try {
      final facebookUrl = 'https://www.facebook.com/sharer/sharer.php?u=${Uri.encodeComponent(url)}&quote=${Uri.encodeComponent(message)}';
      return await _launchUrl(Uri.parse(facebookUrl));
    } catch (e) {
      debugPrint('Error sharing to Facebook: $e');
      return false;
    }
  }

  /// Share to Twitter/X
  Future<bool> _shareToTwitter(String url, String message) async {
    try {
      final twitterUrl = 'https://twitter.com/intent/tweet?text=${Uri.encodeComponent(message)}&url=${Uri.encodeComponent(url)}';
      return await _launchUrl(Uri.parse(twitterUrl));
    } catch (e) {
      debugPrint('Error sharing to Twitter: $e');
      return false;
    }
  }

  /// Share to WhatsApp
  Future<bool> _shareToWhatsApp(String url, String message) async {
    try {
      final whatsappUrl = 'https://wa.me/?text=${Uri.encodeComponent('$message\n\n$url')}';
      return await _launchUrl(Uri.parse(whatsappUrl));
    } catch (e) {
      debugPrint('Error sharing to WhatsApp: $e');
      return false;
    }
  }

  /// Share to Telegram
  Future<bool> _shareToTelegram(String url, String message) async {
    try {
      final telegramUrl = 'https://t.me/share/url?url=${Uri.encodeComponent(url)}&text=${Uri.encodeComponent(message)}';
      return await _launchUrl(Uri.parse(telegramUrl));
    } catch (e) {
      debugPrint('Error sharing to Telegram: $e');
      return false;
    }
  }

  /// Share via Email
  Future<bool> _shareViaEmail(ShareableContent content, String message) async {
    try {
      final emailUrl = 'mailto:?subject=${Uri.encodeComponent(content.title)}&body=${Uri.encodeComponent('$message\n\n${content.shareUrl}')}';
      return await _launchUrl(Uri.parse(emailUrl));
    } catch (e) {
      debugPrint('Error sharing via email: $e');
      return false;
    }
  }

  /// Share via SMS
  Future<bool> _shareViaSMS(String url, String message) async {
    try {
      final smsUrl = 'sms:?body=${Uri.encodeComponent('$message\n\n$url')}';
      return await _launchUrl(Uri.parse(smsUrl));
    } catch (e) {
      debugPrint('Error sharing via SMS: $e');
      return false;
    }
  }

  /// Copy to clipboard
  Future<bool> _copyToClipboard(String url, String message) async {
    try {
      final fullMessage = '$message\n\n$url';
      await Share.share(fullMessage, subject: 'TripConnect Share');
      return true;
    } catch (e) {
      debugPrint('Error copying to clipboard: $e');
      return false;
    }
  }

  /// Generate shareable content from trip
  ShareableContent generateTripContent({
    required Trip trip,
    required ContentType type,
    String? customTitle,
    String? customDescription,
    String? imageUrl,
    List<SocialPlatform> platforms = const [SocialPlatform.copyLink],
  }) {
    final title = customTitle ?? _generateTitle(trip, type);
    final description = customDescription ?? _generateDescription(trip, type);
    final shareUrl = _generateShareUrl(trip, type);

    return ShareableContent(
      id: _uuid.v4(),
      tripId: trip.id,
      type: type,
      title: title,
      description: description,
      shareUrl: shareUrl,
      imageUrl: imageUrl,
      platforms: platforms,
      createdAt: DateTime.now(),
      createdBy: trip.leaderId,
    );
  }

  /// Generate shareable content from social post
  ShareableContent generatePostContent({
    required SocialPost post,
    required Trip trip,
    List<SocialPlatform> platforms = const [SocialPlatform.copyLink],
  }) {
    final title = 'TripConnect Post';
    final description = post.content.length > 100 
        ? '${post.content.substring(0, 100)}...' 
        : post.content;
    final shareUrl = _generatePostShareUrl(trip, post);

    return ShareableContent(
      id: _uuid.v4(),
      tripId: trip.id,
      type: ContentType.tripHighlight,
      title: title,
      description: description,
      shareUrl: shareUrl,
      imageUrl: post.media.isNotEmpty ? post.media.first.url : null,
      platforms: platforms,
      createdAt: DateTime.now(),
      createdBy: post.authorId,
    );
  }

  /// Generate shareable content from trip story
  ShareableContent generateStoryContent({
    required TripStory story,
    required Trip trip,
    List<SocialPlatform> platforms = const [SocialPlatform.copyLink],
  }) {
    final title = story.title;
    final description = story.content.length > 100 
        ? '${story.content.substring(0, 100)}...' 
        : story.content;
    final shareUrl = _generateStoryShareUrl(trip, story);

    return ShareableContent(
      id: _uuid.v4(),
      tripId: trip.id,
      type: ContentType.story,
      title: title,
      description: description,
      shareUrl: shareUrl,
      imageUrl: story.media.isNotEmpty ? story.media.first.url : null,
      platforms: platforms,
      createdAt: DateTime.now(),
      createdBy: story.authorId,
    );
  }

  /// Generate share message for content
  String _generateShareMessage(ShareableContent content) {
    switch (content.type) {
      case ContentType.tripHighlight:
        return 'Check out this amazing trip highlight! 🌟\n\n${content.title}\n\n${content.description}';
      case ContentType.photoAlbum:
        return 'Beautiful memories from our trip! 📸\n\n${content.title}\n\n${content.description}';
      case ContentType.video:
        return 'Watch this incredible moment from our trip! 🎥\n\n${content.title}\n\n${content.description}';
      case ContentType.story:
        return 'Read this amazing story from our trip! 📖\n\n${content.title}\n\n${content.description}';
      case ContentType.achievement:
        return 'We achieved something amazing! 🏆\n\n${content.title}\n\n${content.description}';
      case ContentType.memory:
        return 'A special memory from our trip! 💭\n\n${content.title}\n\n${content.description}';
    }
  }

  /// Public method to generate share message for content
  String generateShareMessage(ShareableContent content) {
    return _generateShareMessage(content);
  }

  /// Format message for Instagram
  String _formatForInstagram(ShareableContent content, String message) {
    // Instagram has character limits and prefers hashtags
    final hashtags = _generateHashtags(content);
    final instagramMessage = '$message\n\n$hashtags';
    
    // Instagram caption limit is 2200 characters
    if (instagramMessage.length > 2200) {
      return '${instagramMessage.substring(0, 2197)}...';
    }
    
    return instagramMessage;
  }

  /// Generate hashtags for content
  String _generateHashtags(ShareableContent content) {
    final hashtags = <String>[
      '#TripConnect',
      '#Travel',
      '#Adventure',
      '#Memories',
    ];

    switch (content.type) {
      case ContentType.tripHighlight:
        hashtags.addAll(['#TripHighlight', '#TravelMoment']);
        break;
      case ContentType.photoAlbum:
        hashtags.addAll(['#PhotoAlbum', '#TravelPhotos']);
        break;
      case ContentType.video:
        hashtags.addAll(['#TravelVideo', '#AdventureVideo']);
        break;
      case ContentType.story:
        hashtags.addAll(['#TravelStory', '#AdventureStory']);
        break;
      case ContentType.achievement:
        hashtags.addAll(['#Achievement', '#TravelGoal']);
        break;
      case ContentType.memory:
        hashtags.addAll(['#Memory', '#TravelMemory']);
        break;
    }

    return hashtags.join(' ');
  }

  /// Generate title for content
  String _generateTitle(Trip trip, ContentType type) {
    switch (type) {
      case ContentType.tripHighlight:
        return '${trip.name} - Amazing Highlights!';
      case ContentType.photoAlbum:
        return '${trip.name} - Photo Collection';
      case ContentType.video:
        return '${trip.name} - Video Memories';
      case ContentType.story:
        return '${trip.name} - Travel Story';
      case ContentType.achievement:
        return '${trip.name} - Achievement Unlocked!';
      case ContentType.memory:
        return '${trip.name} - Special Memory';
    }
  }

  /// Generate description for content
  String _generateDescription(Trip trip, ContentType type) {
    switch (type) {
      case ContentType.tripHighlight:
        return 'Check out the amazing highlights from our ${trip.theme} trip to ${trip.destination.name}!';
      case ContentType.photoAlbum:
        return 'Beautiful photos from our ${trip.theme} adventure in ${trip.destination.name}!';
      case ContentType.video:
        return 'Watch the incredible moments from our ${trip.theme} trip to ${trip.destination.name}!';
      case ContentType.story:
        return 'Read the story of our ${trip.theme} adventure in ${trip.destination.name}!';
      case ContentType.achievement:
        return 'We achieved something amazing during our ${trip.theme} trip to ${trip.destination.name}!';
      case ContentType.memory:
        return 'A special memory from our ${trip.theme} adventure in ${trip.destination.name}!';
    }
  }

  /// Generate share URL for trip content
  String _generateShareUrl(Trip trip, ContentType type) {
    // In a real app, this would be a deep link to the app or web page
    return 'https://tripconnect.app/trip/${trip.id}/content/${type.name}';
  }

  /// Generate share URL for post
  String _generatePostShareUrl(Trip trip, SocialPost post) {
    return 'https://tripconnect.app/trip/${trip.id}/post/${post.id}';
  }

  /// Generate share URL for story
  String _generateStoryShareUrl(Trip trip, TripStory story) {
    return 'https://tripconnect.app/trip/${trip.id}/story/${story.id}';
  }

  /// Download image for sharing
  Future<File?> _downloadImage(String imageUrl) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        final tempDir = await getTemporaryDirectory();
        final fileName = '${_uuid.v4()}.jpg';
        final file = File('${tempDir.path}/$fileName');
        await file.writeAsBytes(response.bodyBytes);
        return file;
      }
    } catch (e) {
      debugPrint('Error downloading image: $e');
    }
    return null;
  }

  /// Launch URL
  Future<bool> _launchUrl(Uri url) async {
    try {
      return await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Error launching URL: $e');
      return false;
    }
  }

  /// Get available sharing platforms
  List<SocialPlatform> getAvailablePlatforms() {
    return SocialPlatform.values;
  }

  /// Check if platform is available
  Future<bool> isPlatformAvailable(SocialPlatform platform) async {
    // In a real app, you would check if the app is installed
    // For now, we'll assume all platforms are available
    return true;
  }
}
