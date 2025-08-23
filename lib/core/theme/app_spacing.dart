import 'package:flutter/material.dart';

class AppSpacing {
  // Base spacing unit (8dp)
  static const double unit = 8.0;

  // Common spacing values
  static const double xs = unit * 0.5; // 4
  static const double sm = unit; // 8
  static const double md = unit * 2; // 16
  static const double lg = unit * 3; // 24
  static const double xl = unit * 4; // 32
  static const double xxl = unit * 6; // 48
  static const double xxxl = unit * 8; // 64

  // Specific spacing for different use cases
  static const double screenPadding = md; // 16
  static const double cardPadding = lg; // 24
  static const double sectionSpacing = xl; // 32
  static const double listItemSpacing = sm; // 8
  static const double buttonSpacing = md; // 16

  // Radius values
  static const double radiusXs = 4.0;
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 20.0;
  static const double radiusXxl = 24.0;
  static const double radiusXxxl = 32.0;

  // Border radius for different components
  static const BorderRadius cardRadius = BorderRadius.all(Radius.circular(radiusXxl));
  static const BorderRadius buttonRadius = BorderRadius.all(Radius.circular(radiusXxl));
  static const BorderRadius inputRadius = BorderRadius.all(Radius.circular(radiusLg));
  static const BorderRadius chipRadius = BorderRadius.all(Radius.circular(radiusLg));
  static const BorderRadius dialogRadius = BorderRadius.all(Radius.circular(radiusXxl));
  static const BorderRadius bottomSheetRadius = BorderRadius.vertical(top: Radius.circular(radiusXxl));

  // Icon sizes
  static const double iconXs = 16.0;
  static const double iconSm = 20.0;
  static const double iconMd = 24.0;
  static const double iconLg = 32.0;
  static const double iconXl = 40.0;
  static const double iconXxl = 48.0;

  // Avatar sizes
  static const double avatarSm = 32.0;
  static const double avatarMd = 40.0;
  static const double avatarLg = 56.0;
  static const double avatarXl = 72.0;
  static const double avatarXxl = 96.0;

  // Button heights
  static const double buttonHeightSm = 36.0;
  static const double buttonHeightMd = 48.0;
  static const double buttonHeightLg = 56.0;

  // App bar height
  static const double appBarHeight = 56.0;
  static const double appBarHeightLarge = 64.0;

  // Bottom navigation height
  static const double bottomNavHeight = 80.0;

  // Tab bar height
  static const double tabBarHeight = 48.0;

  // Card elevations
  static const double elevationSm = 1.0;
  static const double elevationMd = 2.0;
  static const double elevationLg = 4.0;
  static const double elevationXl = 8.0;

  // Animation durations
  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationStandard = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);
  static const Duration animationExtended = Duration(milliseconds: 1000);

  // Curves
  static const Curve curveStandard = Curves.easeInOut;
  static const Curve curveDecelerate = Curves.decelerate;
  static const Curve curveAccelerate = Curves.easeIn;
  static const Curve curveBounce = Curves.bounceOut;

  // Breakpoints for responsive design
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  // Grid spacing
  static const double gridSpacing = sm;
  static const int gridCrossAxisCount = 2;
  static const double gridChildAspectRatio = 0.8;

  // List spacing
  static const double listSpacing = md;
  static const double listTileHeight = 72.0;
  static const double listTileHeightCompact = 56.0;

  // FAB positioning
  static const double fabMargin = md;
  static const double fabMarginExtended = lg;

  // Safe area padding
  static const EdgeInsets safePadding = EdgeInsets.all(screenPadding);
  static const EdgeInsets safeHorizontalPadding = EdgeInsets.symmetric(horizontal: screenPadding);
  static const EdgeInsets safeVerticalPadding = EdgeInsets.symmetric(vertical: screenPadding);

  // Common padding presets
  static const EdgeInsets paddingXs = EdgeInsets.all(xs);
  static const EdgeInsets paddingSm = EdgeInsets.all(sm);
  static const EdgeInsets paddingMd = EdgeInsets.all(md);
  static const EdgeInsets paddingLg = EdgeInsets.all(lg);
  static const EdgeInsets paddingXl = EdgeInsets.all(xl);

  // Horizontal padding presets
  static const EdgeInsets paddingHorizontalXs = EdgeInsets.symmetric(horizontal: xs);
  static const EdgeInsets paddingHorizontalSm = EdgeInsets.symmetric(horizontal: sm);
  static const EdgeInsets paddingHorizontalMd = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets paddingHorizontalLg = EdgeInsets.symmetric(horizontal: lg);
  static const EdgeInsets paddingHorizontalXl = EdgeInsets.symmetric(horizontal: xl);

  // Vertical padding presets
  static const EdgeInsets paddingVerticalXs = EdgeInsets.symmetric(vertical: xs);
  static const EdgeInsets paddingVerticalSm = EdgeInsets.symmetric(vertical: sm);
  static const EdgeInsets paddingVerticalMd = EdgeInsets.symmetric(vertical: md);
  static const EdgeInsets paddingVerticalLg = EdgeInsets.symmetric(vertical: lg);
  static const EdgeInsets paddingVerticalXl = EdgeInsets.symmetric(vertical: xl);

  // Margin presets
  static const EdgeInsets marginXs = EdgeInsets.all(xs);
  static const EdgeInsets marginSm = EdgeInsets.all(sm);
  static const EdgeInsets marginMd = EdgeInsets.all(md);
  static const EdgeInsets marginLg = EdgeInsets.all(lg);
  static const EdgeInsets marginXl = EdgeInsets.all(xl);

  // Common SizedBox presets
  static const SizedBox verticalSpaceXs = SizedBox(height: xs);
  static const SizedBox verticalSpaceSm = SizedBox(height: sm);
  static const SizedBox verticalSpaceMd = SizedBox(height: md);
  static const SizedBox verticalSpaceLg = SizedBox(height: lg);
  static const SizedBox verticalSpaceXl = SizedBox(height: xl);
  static const SizedBox verticalSpaceXxl = SizedBox(height: xxl);

  static const SizedBox horizontalSpaceXs = SizedBox(width: xs);
  static const SizedBox horizontalSpaceSm = SizedBox(width: sm);
  static const SizedBox horizontalSpaceMd = SizedBox(width: md);
  static const SizedBox horizontalSpaceLg = SizedBox(width: lg);
  static const SizedBox horizontalSpaceXl = SizedBox(width: xl);
  static const SizedBox horizontalSpaceXxl = SizedBox(width: xxl);

  // Method to get responsive padding based on screen width
  static EdgeInsets getResponsivePadding(double screenWidth) {
    if (screenWidth < mobileBreakpoint) {
      return paddingMd;
    } else if (screenWidth < tabletBreakpoint) {
      return paddingLg;
    } else {
      return paddingXl;
    }
  }

  // Method to get responsive spacing based on screen width
  static double getResponsiveSpacing(double screenWidth) {
    if (screenWidth < mobileBreakpoint) {
      return md;
    } else if (screenWidth < tabletBreakpoint) {
      return lg;
    } else {
      return xl;
    }
  }

  // Method to check if device is mobile
  static bool isMobile(double screenWidth) {
    return screenWidth < mobileBreakpoint;
  }

  // Method to check if device is tablet
  static bool isTablet(double screenWidth) {
    return screenWidth >= mobileBreakpoint && screenWidth < desktopBreakpoint;
  }

  // Method to check if device is desktop
  static bool isDesktop(double screenWidth) {
    return screenWidth >= desktopBreakpoint;
  }
}
