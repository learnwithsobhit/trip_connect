import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:go_router/go_router.dart';

import '../../core/data/providers/auth_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  bool _isLoading = false;

  Future<void> _signInAsGuest() async {
    setState(() => _isLoading = true);
    final authNotifier = ref.read(authProvider.notifier);
    await authNotifier.signInAsGuest();
    if (mounted) {
      setState(() => _isLoading = false);
      final authState = ref.read(authProvider);
      authState.when(
        authenticated: (_) => context.go('/'),
        guest: (_) => context.go('/discover'),
        error: (error) => _showErrorSnackBar(error),
        initial: () {}, 
        loading: () {}, 
        unauthenticated: () {},
      );
    }
  }

  void _showErrorSnackBar(String error) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppColors.primaryGradient,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: AppSpacing.paddingLg,
              child: Column(
                children: [
                  // Hero section
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.5,
                    child: AnimationLimiter(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: AnimationConfiguration.toStaggeredList(
                          duration: AppSpacing.animationStandard,
                          childAnimationBuilder: (widget) => SlideAnimation(
                            verticalOffset: 50.0,
                            child: FadeInAnimation(child: widget),
                          ),
                          children: [
                            // App Logo/Animation
                            Container(
                              width: size.width * 0.6,
                              height: size.width * 0.6,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.explore,
                                size: 120,
                                color: Colors.white,
                              ),
                            ),
                            
                            AppSpacing.verticalSpaceXl,
                            
                            // App Title
                            Text(
                              'TripConnect',
                              style: theme.textTheme.displayMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            
                            AppSpacing.verticalSpaceMd,
                            
                            // Subtitle
                            Text(
                              'Your journey, perfectly connected',
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: Colors.white.withOpacity(0.9),
                                fontWeight: FontWeight.w400,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  // Features highlight
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _FeatureItem(
                        icon: Icons.groups,
                        title: 'Plan Together',
                        subtitle: 'Collaborate with your travel group',
                      ),
                      AppSpacing.verticalSpaceMd,
                      _FeatureItem(
                        icon: Icons.navigation,
                        title: 'Stay Connected',
                        subtitle: 'Real-time location and updates',
                      ),
                      AppSpacing.verticalSpaceMd,
                      _FeatureItem(
                        icon: Icons.emergency,
                        title: 'Travel Safe',
                        subtitle: 'Emergency features for peace of mind',
                      ),
                    ],
                  ),
                  
                  // Action buttons
                  Column(
                    children: [
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: () => context.go('/auth/signup'),
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: AppColors.primary,
                                padding: AppSpacing.paddingVerticalLg,
                              ),
                              child: const Text(
                                'Get Started',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          
                          AppSpacing.verticalSpaceMd,
                          
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () => context.go('/auth/signin'),
                              style: OutlinedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white, width: 2),
                                padding: AppSpacing.paddingVerticalLg,
                              ),
                              child: const Text(
                                'I already have an account',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          
                          AppSpacing.verticalSpaceMd,
                          
                          SizedBox(
                            width: double.infinity,
                            child: TextButton.icon(
                              onPressed: () => context.go('/discover'),
                              icon: const Icon(Icons.public, color: Colors.white70),
                              label: const Text(
                                'Browse Public Trips',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.white70,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                padding: AppSpacing.paddingVerticalMd,
                              ),
                            ),
                          ),
                          
                          AppSpacing.verticalSpaceSm,
                          
                          SizedBox(
                            width: double.infinity,
                            child: TextButton.icon(
                              onPressed: _isLoading ? null : _signInAsGuest,
                              icon: const Icon(Icons.person_outline, color: Colors.white60),
                              label: const Text(
                                'Continue as Guest',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.white60,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                padding: AppSpacing.paddingVerticalMd,
                              ),
                            ),
                          ),
                    ],
                  ),
                  
                  AppSpacing.verticalSpaceLg,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          padding: AppSpacing.paddingMd,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: AppSpacing.iconLg,
          ),
        ),
        
        AppSpacing.horizontalSpaceMd,
        
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

