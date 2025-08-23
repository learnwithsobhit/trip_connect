import 'package:flutter/material.dart';

class AppColors {
  // Primary brand colors
  static const Color primary = Color(0xFF6750A4);
  static const Color primaryContainer = Color(0xFFEADDFF);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFF21005D);

  // Secondary colors
  static const Color secondary = Color(0xFF625B71);
  static const Color secondaryContainer = Color(0xFFE8DEF8);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color onSecondaryContainer = Color(0xFF1D192B);

  // Tertiary colors (for accents)
  static const Color tertiary = Color(0xFF7D5260);
  static const Color tertiaryContainer = Color(0xFFFFD8E4);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color onTertiaryContainer = Color(0xFF31111D);

  // Error colors
  static const Color error = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color onErrorContainer = Color(0xFF410002);

  // Surface colors
  static const Color surface = Color(0xFFFFFBFE);
  static const Color onSurface = Color(0xFF1C1B1F);
  static const Color surfaceVariant = Color(0xFFE7E0EC);
  static const Color onSurfaceVariant = Color(0xFF49454F);

  // Outline colors
  static const Color outline = Color(0xFF79747E);
  static const Color outlineVariant = Color(0xFFCAC4D0);

  // Shadow and scrim
  static const Color shadow = Color(0xFF000000);
  static const Color scrim = Color(0xFF000000);

  // Inverse colors
  static const Color inverseSurface = Color(0xFF313033);
  static const Color onInverseSurface = Color(0xFFF4EFF4);
  static const Color inversePrimary = Color(0xFFD0BCFF);

  // Custom semantic colors for the app
  static const Color success = Color(0xFF4CAF50);
  static const Color successContainer = Color(0xFFC8E6C9);
  static const Color onSuccess = Color(0xFFFFFFFF);
  static const Color onSuccessContainer = Color(0xFF1B5E20);

  static const Color warning = Color(0xFFFF9800);
  static const Color warningContainer = Color(0xFFFFE0B2);
  static const Color onWarning = Color(0xFFFFFFFF);
  static const Color onWarningContainer = Color(0xFFE65100);

  static const Color info = Color(0xFF2196F3);
  static const Color infoContainer = Color(0xFFBBDEFB);
  static const Color onInfo = Color(0xFFFFFFFF);
  static const Color onInfoContainer = Color(0xFF0D47A1);

  // Trip status colors
  static const Color tripPlanning = Color(0xFF9C27B0);
  static const Color tripActive = Color(0xFF4CAF50);
  static const Color tripCompleted = Color(0xFF607D8B);
  static const Color tripCancelled = Color(0xFFE91E63);

  // Role colors
  static const Color roleLeader = Color(0xFFD32F2F);
  static const Color roleCoLeader = Color(0xFFFF5722);
  static const Color roleTraveler = Color(0xFF1976D2);
  static const Color roleFollower = Color(0xFF616161);

  // Alert priority colors
  static const Color alertCritical = Color(0xFFD32F2F);
  static const Color alertHigh = Color(0xFFFF5722);
  static const Color alertMedium = Color(0xFFFF9800);
  static const Color alertLow = Color(0xFF4CAF50);

  // Transport mode colors
  static const Color transportBus = Color(0xFF2196F3);
  static const Color transportCar = Color(0xFF4CAF50);
  static const Color transportTrain = Color(0xFF9C27B0);
  static const Color transportFlight = Color(0xFFFF5722);
  static const Color transportWalk = Color(0xFF795548);

  // Activity type colors
  static const Color activitySightseeing = Color(0xFF00BCD4);
  static const Color activityFood = Color(0xFFFF9800);
  static const Color activityRest = Color(0xFF9E9E9E);
  static const Color activityShopping = Color(0xFFE91E63);
  static const Color activityAdventure = Color(0xFF4CAF50);

  // Dark theme colors
  static const Color darkSurface = Color(0xFF1C1B1F);
  static const Color darkOnSurface = Color(0xFFE6E1E5);
  static const Color darkSurfaceVariant = Color(0xFF49454F);
  static const Color darkOnSurfaceVariant = Color(0xFFCAC4D0);

  // Custom gradient colors
  static const List<Color> primaryGradient = [
    Color(0xFF6750A4),
    Color(0xFF9C27B0),
  ];

  static const List<Color> successGradient = [
    Color(0xFF4CAF50),
    Color(0xFF66BB6A),
  ];

  static const List<Color> warningGradient = [
    Color(0xFFFF9800),
    Color(0xFFFFB74D),
  ];

  static const List<Color> errorGradient = [
    Color(0xFFBA1A1A),
    Color(0xFFEF5350),
  ];

  // Shimmer colors
  static const Color shimmerBase = Color(0xFFE0E0E0);
  static const Color shimmerHighlight = Color(0xFFF5F5F5);
  static const Color shimmerBaseDark = Color(0xFF424242);
  static const Color shimmerHighlightDark = Color(0xFF616161);

  // Glassmorphism colors
  static Color glassBackground = Colors.white.withOpacity(0.1);
  static Color glassBorder = Colors.white.withOpacity(0.2);
  static Color glassBackgroundDark = Colors.black.withOpacity(0.1);
  static Color glassBorderDark = Colors.white.withOpacity(0.1);

  // Method to get color by trip status
  static Color getTripStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'planning':
        return tripPlanning;
      case 'active':
        return tripActive;
      case 'completed':
        return tripCompleted;
      case 'cancelled':
        return tripCancelled;
      default:
        return onSurfaceVariant;
    }
  }

  // Method to get color by user role
  static Color getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'leader':
        return roleLeader;
      case 'coleader':
      case 'co-leader':
        return roleCoLeader;
      case 'traveler':
        return roleTraveler;
      case 'follower':
        return roleFollower;
      default:
        return onSurfaceVariant;
    }
  }

  // Method to get color by alert priority
  static Color getAlertPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'critical':
        return alertCritical;
      case 'high':
        return alertHigh;
      case 'medium':
        return alertMedium;
      case 'low':
        return alertLow;
      default:
        return info;
    }
  }
}


