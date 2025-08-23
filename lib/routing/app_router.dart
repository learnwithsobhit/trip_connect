import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/data/providers/auth_provider.dart';
import '../core/data/providers/trip_provider.dart';
import '../features/auth/welcome_screen.dart';
import '../features/auth/sign_in_screen.dart';
import '../features/auth/sign_up_screen.dart';
import '../features/trips/home_screen.dart';
import '../features/trips/create/trip_create_screen.dart';
import '../features/trips/join/trip_join_screen.dart';
import '../features/trips/guardian/guardian_view_screen.dart';
import '../features/trips/rollcall/trip_rollcall_screen.dart';
import '../features/trips/discovery/public_trips_screen.dart';
import '../features/trips/detail/trip_detail_screen.dart';
import '../features/trips/schedule/trip_schedule_screen.dart';
import '../features/trips/map/trip_map_screen.dart';
import '../features/trips/detail/trip_chat_screen.dart';
import '../features/trips/docs/trip_docs_screen.dart';
import '../features/trips/people/trip_people_screen.dart';
import '../features/trips/rollcall/trip_rollcall_screen.dart';
import '../features/ratings/user_rating_screen.dart';
import '../features/ratings/trip_rating_screen.dart';
import '../features/ratings/ratings_list_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/settings/language_selection_screen.dart';
import '../features/profile/profile_edit_screen.dart';
import '../features/trips/weather/trip_weather_screen.dart';
import '../features/trips/checklist/trip_checklist_screen.dart';
import '../features/trips/transportation/trip_transportation_screen.dart';
import '../features/trips/health/trip_health_screen.dart';
import '../features/trips/documents/trip_documents_screen.dart';
import '../features/trips/media/trip_media_screen.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);
  
  return GoRouter(
    debugLogDiagnostics: true,
    initialLocation: '/',
    redirect: (context, state) {
      final isAuthenticated = authState.maybeWhen(
        authenticated: (_) => true,
        guest: (_) => true, // Guests are considered authenticated for routing
        orElse: () => false,
      );
      
      final isGuest = authState.maybeWhen(
        guest: (_) => true,
        orElse: () => false,
      );
      
      final isLoading = authState.maybeWhen(
        loading: () => true,
        orElse: () => false,
      );

      // Don't redirect while loading
      if (isLoading) return null;

      final isOnAuthPage = state.matchedLocation.startsWith('/auth');
      final isOnDiscoverPage = state.matchedLocation == '/discover';
      final isOnJoinPage = state.matchedLocation.startsWith('/join');
      
      // Allow access to public discovery and join pages for unauthenticated users
      if (!isAuthenticated && (isOnDiscoverPage || isOnJoinPage)) {
        return null;
      }
      
      // If not authenticated and not on auth/discover/join page, go to welcome
      if (!isAuthenticated && !isOnAuthPage && !isOnDiscoverPage && !isOnJoinPage) {
        return '/auth/welcome';
      }
      
      // If authenticated and on auth page, go to appropriate home
      // But allow guests to access auth pages for sign up/sign in
      if (isAuthenticated && isOnAuthPage) {
        // Allow guests to stay on auth pages (for sign up/sign in)
        if (isGuest) {
          return null; // Don't redirect, let them access auth pages
        }
        return '/';
      }
      
      // If guest user is on home page, redirect to discover
      if (isGuest && state.matchedLocation == '/') {
        return '/discover';
      }
      
      return null;
    },
    routes: [
      // Authentication routes
      GoRoute(
        path: '/auth/welcome',
        name: 'welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/auth/signin',
        name: 'signin',
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: '/auth/signup',
        name: 'signup',
        builder: (context, state) => const SignUpScreen(),
      ),
      
      // Public discovery route
      GoRoute(
        path: '/discover',
        name: 'discover',
        builder: (context, state) => const PublicTripsScreen(),
      ),
      
      // Main app routes
      ShellRoute(
        builder: (context, state, child) {
          return MainShell(child: child);
        },
        routes: [
          // Home
          GoRoute(
            path: '/',
            name: 'home',
            builder: (context, state) => const HomeScreen(),
          ),
          
          // Settings
          GoRoute(
            path: '/settings',
            name: 'settings',
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: '/settings/language',
            name: 'language-settings',
            builder: (context, state) => const LanguageSelectionScreen(),
          ),
          GoRoute(
            path: '/settings/profile',
            name: 'profile-edit',
            builder: (context, state) => const ProfileEditScreen(),
          ),
          
          // Trip creation
          GoRoute(
            path: '/trips/create',
            name: 'trip-create',
            builder: (context, state) => const TripCreateScreen(),
          ),
          
          // Trip joining
          GoRoute(
            path: '/join',
            name: 'trip-join',
            builder: (context, state) {
              final inviteCode = state.uri.queryParameters['code'];
              return TripJoinScreen(inviteCode: inviteCode);
            },
          ),
          GoRoute(
            path: '/join/:code',
            name: 'trip-join-code',
            builder: (context, state) {
              final inviteCode = state.pathParameters['code'];
              return TripJoinScreen(inviteCode: inviteCode);
            },
          ),
          
          // Guardian view
          GoRoute(
            path: '/guardian/:tripId',
            name: 'guardian-view',
            builder: (context, state) {
              final tripId = state.pathParameters['tripId']!;
              final guardianToken = state.uri.queryParameters['token'];
              return GuardianViewScreen(tripId: tripId, guardianToken: guardianToken);
            },
          ),
          
          // Trip details and nested routes
          GoRoute(
            path: '/trips/:tripId',
            name: 'trip-detail',
            builder: (context, state) {
              final tripId = state.pathParameters['tripId']!;
              return TripDetailScreen(tripId: tripId);
            },
            routes: [
              GoRoute(
                path: 'schedule',
                name: 'trip-schedule',
                builder: (context, state) {
                  final tripId = state.pathParameters['tripId']!;
                  return TripScheduleScreen(tripId: tripId);
                },
              ),
              GoRoute(
                path: 'map',
                name: 'trip-map',
                builder: (context, state) {
                  final tripId = state.pathParameters['tripId']!;
                  return TripMapScreen(tripId: tripId);
                },
              ),
              GoRoute(
                path: 'chat',
                name: 'trip-chat',
                builder: (context, state) {
                  final tripId = state.pathParameters['tripId']!;
                  return TripChatScreen(tripId: tripId);
                },
              ),

              GoRoute(
                path: 'docs',
                name: 'trip-docs',
                builder: (context, state) {
                  final tripId = state.pathParameters['tripId']!;
                  return TripDocsScreen(tripId: tripId);
                },
              ),
              GoRoute(
                path: 'people',
                name: 'trip-people',
                builder: (context, state) {
                  final tripId = state.pathParameters['tripId']!;
                  return TripPeopleScreen(tripId: tripId);
                },
              ),
              GoRoute(
                path: 'rollcall',
                name: 'trip-rollcall',
                builder: (context, state) {
                  final tripId = state.pathParameters['tripId']!;
                  return TripRollCallScreen(tripId: tripId);
                },
              ),
              GoRoute(
                path: 'rate-trip',
                name: 'rate-trip',
                builder: (context, state) {
                  final tripId = state.pathParameters['tripId']!;
                  final tripName = state.uri.queryParameters['name'] ?? 'Trip';
                  final tripImage = state.uri.queryParameters['image'];
                  return TripRatingScreen(
                    tripId: tripId,
                    tripName: tripName,
                    tripImage: tripImage,
                  );
                },
              ),
              GoRoute(
                path: 'rate-user/:userId',
                name: 'rate-user',
                builder: (context, state) {
                  final tripId = state.pathParameters['tripId']!;
                  final userId = state.pathParameters['userId']!;
                  final userName = state.uri.queryParameters['name'] ?? 'User';
                  final userAvatar = state.uri.queryParameters['avatar'];
                  return UserRatingScreen(
                    ratedUserId: userId,
                    tripId: tripId,
                    userName: userName,
                    userAvatar: userAvatar,
                  );
                },
              ),
              GoRoute(
                path: 'weather',
                name: 'trip-weather',
                builder: (context, state) {
                  final tripId = state.pathParameters['tripId']!;
                  return TripWeatherScreen(tripId: tripId);
                },
              ),
              GoRoute(
                path: 'checklist',
                name: 'trip-checklist',
                builder: (context, state) {
                  final tripId = state.pathParameters['tripId']!;
                  return TripChecklistScreen(tripId: tripId);
                },
              ),
              GoRoute(
                path: 'transportation',
                name: 'trip-transportation',
                builder: (context, state) {
                  final tripId = state.pathParameters['tripId']!;
                  return TripTransportationScreen(tripId: tripId);
                },
              ),
                 GoRoute(
                   path: 'health',
                   name: 'trip-health',
                   builder: (context, state) {
                     final tripId = state.pathParameters['tripId']!;
                     return TripHealthScreen(tripId: tripId);
                   },
                 ),
                 GoRoute(
                   path: 'documents',
                   name: 'trip-documents',
                   builder: (context, state) {
                     final tripId = state.pathParameters['tripId']!;
                     return TripDocumentsScreen(tripId: tripId);
                   },
                 ),
                 GoRoute(
                   path: 'media',
                   name: 'trip-media',
                   builder: (context, state) {
                     final tripId = state.pathParameters['tripId']!;
                     return TripMediaScreen(tripId: tripId);
                   },
                 ),
               ],
             ),
        ],
      ),
      
      // Rating screens
      GoRoute(
        path: '/user-ratings/:userId',
        name: 'user-ratings-list',
        builder: (context, state) {
          final userId = state.pathParameters['userId']!;
          final userName = state.uri.queryParameters['name'] ?? 'User';
          return UserRatingsListScreen(userId: userId, userName: userName);
        },
      ),
      
      GoRoute(
        path: '/trip-ratings/:tripId',
        name: 'trip-ratings-list',
        builder: (context, state) {
          final tripId = state.pathParameters['tripId']!;
          final tripName = state.uri.queryParameters['name'] ?? 'Trip';
          return TripRatingsListScreen(tripId: tripId, tripName: tripName);
        },
      ),

      // Deep link handling for join trip
      GoRoute(
        path: '/join/:code',
        name: 'join-trip',
        builder: (context, state) {
          final code = state.pathParameters['code']!;
          return JoinTripScreen(inviteCode: code);
        },
      ),
    ],
    errorBuilder: (context, state) => ErrorScreen(error: state.error.toString()),
  );
});

// Main shell for authenticated screens
class MainShell extends StatelessWidget {
  final Widget child;
  
  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
    );
  }
}

// Error screen
class ErrorScreen extends StatelessWidget {
  final String error;
  
  const ErrorScreen({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Error'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Oops! Something went wrong',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.go('/'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    );
  }
}

// Join trip screen for handling deep links
class JoinTripScreen extends ConsumerWidget {
  final String inviteCode;
  
  const JoinTripScreen({super.key, required this.inviteCode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Join Trip'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.group_add,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'Join Trip',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Invite Code: $inviteCode',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () async {
                // Handle join trip logic
                final tripsNotifier = ref.read(tripsProvider.notifier);
                try {
                  await tripsNotifier.joinTrip(inviteCode);
                  if (context.mounted) {
                    context.go('/');
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to join trip: $e')),
                    );
                  }
                }
              },
              child: const Text('Join Trip'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => context.go('/'),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}

// Extension for easy navigation
extension GoRouterExtension on BuildContext {
  void pushNamed(String name, {Map<String, String> pathParameters = const {}, Map<String, dynamic>? extra}) {
    GoRouter.of(this).pushNamed(name, pathParameters: pathParameters, extra: extra);
  }
  
  void goNamed(String name, {Map<String, String> pathParameters = const {}, Map<String, dynamic>? extra}) {
    GoRouter.of(this).goNamed(name, pathParameters: pathParameters, extra: extra);
  }
}
