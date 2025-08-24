import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import '../repositories/trip_repository.dart';
import '../../services/mock_server.dart';
import 'auth_provider.dart';

// Repository provider
final tripRepositoryProvider = Provider<TripRepository>((ref) {
  return TripRepository();
});

// Mock server provider
final mockServerProvider = Provider<MockServer>((ref) {
  return MockServer();
});

// Trips list notifier
class TripsNotifier extends StateNotifier<AsyncValue<List<Trip>>> {
  final TripRepository _tripRepository;

  TripsNotifier(this._tripRepository) : super(const AsyncValue.loading()) {
    loadTrips();
  }

  Future<void> loadTrips() async {
    try {
      state = const AsyncValue.loading();
      final trips = await _tripRepository.getUserTrips();
      state = AsyncValue.data(trips);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<String> createTrip({
    required String name,
    required String theme,
    required Location origin,
    required Location destination,
    required DateTime startDate,
    required DateTime endDate,
    required int seatsTotal,
    TripPrivacy privacy = TripPrivacy.private,
  }) async {
    try {
      final result = await _tripRepository.createTrip(
        name: name,
        theme: theme,
        origin: origin,
        destination: destination,
        startDate: startDate,
        endDate: endDate,
        seatsTotal: seatsTotal,
        privacy: privacy,
      );

      if (result.isSuccess && result.trip != null) {
        // Reload trips to include the new one
        await loadTrips();
        return result.trip!.id;
      } else {
        throw Exception(result.error ?? 'Failed to create trip');
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> joinTrip(String inviteCode) async {
    try {
      final result = await _tripRepository.joinTrip(inviteCode);

      if (result.isSuccess) {
        // Reload trips to include the joined one
        await loadTrips();
      } else {
        throw Exception(result.error ?? 'Failed to join trip');
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> leaveTrip(String tripId) async {
    try {
      final result = await _tripRepository.leaveTrip(tripId);

      if (result.isSuccess) {
        // Reload trips to remove the left trip from user's list
        await loadTrips();
      } else {
        throw Exception(result.error ?? 'Failed to leave trip');
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refreshTrips() async {
    await loadTrips();
  }
}

// Trips provider
final tripsProvider = StateNotifierProvider<TripsNotifier, AsyncValue<List<Trip>>>((ref) {
  final tripRepository = ref.watch(tripRepositoryProvider);
  final notifier = TripsNotifier(tripRepository);
  
  // Listen to auth changes and reload trips when user logs in
  ref.listen(currentUserProvider, (previous, next) {
    if (previous == null && next != null) {
      // User just logged in, reload trips
      notifier.loadTrips();
    } else if (previous != null && next == null) {
      // User logged out, clear trips
      notifier.state = const AsyncValue.data([]);
    }
  });
  
  return notifier;
});

// Single trip provider
final tripProvider = FutureProvider.family<Trip?, String>((ref, tripId) async {
  final tripRepository = ref.watch(tripRepositoryProvider);
  return await tripRepository.getTrip(tripId);
});

// Trip members provider
final tripMembersProvider = FutureProvider.family<List<Membership>, String>((ref, tripId) async {
  final tripRepository = ref.watch(tripRepositoryProvider);
  return await tripRepository.getTripMembers(tripId);
});

// Trip users provider
final tripUsersProvider = FutureProvider.family<List<User>, String>((ref, tripId) async {
  final tripRepository = ref.watch(tripRepositoryProvider);
  return await tripRepository.getTripUsers(tripId);
});

// Trip messages provider (static load)
final tripMessagesProvider = FutureProvider.family<List<Message>, String>((ref, tripId) async {
  final tripRepository = ref.watch(tripRepositoryProvider);
  return await tripRepository.getTripMessages(tripId);
});

// Trip messages stream provider (real-time updates)
final tripMessagesStreamProvider = StreamProvider.family<List<Message>, String>((ref, tripId) async* {
  final tripRepository = ref.watch(tripRepositoryProvider);
  
  // Load initial messages
  final initialMessages = await tripRepository.getTripMessages(tripId);
  yield initialMessages;
  
  // Listen to real-time updates
  await for (final update in tripRepository.getTripStream(tripId)) {
    if (update['topic'] == 'chat' && update['event'] == 'new_message') {
      // Reload messages when new message arrives
      final updatedMessages = await tripRepository.getTripMessages(tripId);
      yield updatedMessages;
    }
  }
});

// Active trip provider (currently selected trip)
final activeTripProvider = StateProvider<Trip?>((ref) => null);

// Trip real-time updates provider
final tripStreamProvider = StreamProvider.family<Map<String, dynamic>, String>((ref, tripId) {
  final tripRepository = ref.watch(tripRepositoryProvider);
  return tripRepository.getTripStream(tripId);
});

// Trip actions notifier
class TripActionsNotifier extends StateNotifier<TripActionState> {
  final TripRepository _tripRepository;

  TripActionsNotifier(this._tripRepository) : super(const TripActionState.idle());

  Future<void> sendMessage(
    String tripId,
    String text, {
    MessageType type = MessageType.chat,
    List<String> tags = const [],
    bool requiresAck = false,
  }) async {
    state = const TripActionState.loading();
    
    try {
      await _tripRepository.sendMessage(
        tripId,
        text,
        type: type,
        tags: tags,
        requiresAck: requiresAck,
      );
      state = const TripActionState.success();
    } catch (error) {
      state = TripActionState.error(message: error.toString());
    }
  }

  Future<void> raiseAlert(String tripId, AlertKind kind, AlertPayload payload) async {
    state = const TripActionState.loading();
    
    try {
      await _tripRepository.raiseAlert(tripId, kind, payload);
      state = const TripActionState.success();
    } catch (error) {
      state = TripActionState.error(message: error.toString());
    }
  }

  Future<void> startRollCall(String tripId, {String? stopId, int graceMin = 10}) async {
    state = const TripActionState.loading();
    
    try {
      await _tripRepository.startRollCall(tripId, stopId: stopId, graceMin: graceMin);
      state = const TripActionState.success();
    } catch (error) {
      state = TripActionState.error(message: error.toString());
    }
  }

  Future<void> checkIn(String rollCallId, {CheckInMethod method = CheckInMethod.manual}) async {
    state = const TripActionState.loading();
    
    try {
      await _tripRepository.checkIn(rollCallId, method: method);
      state = const TripActionState.success();
    } catch (error) {
      state = TripActionState.error(message: error.toString());
    }
  }

  void clearState() {
    state = const TripActionState.idle();
  }
}

// Trip actions provider
final tripActionsProvider = StateNotifierProvider<TripActionsNotifier, TripActionState>((ref) {
  final tripRepository = ref.watch(tripRepositoryProvider);
  return TripActionsNotifier(tripRepository);
});

// Filtered trips providers
final upcomingTripsProvider = Provider<List<Trip>>((ref) {
  final tripsAsync = ref.watch(tripsProvider);
  return tripsAsync.when(
    data: (trips) => trips.where((trip) => 
        trip.status == TripStatus.planning || 
        (trip.status == TripStatus.active && trip.startDate.isAfter(DateTime.now()))).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

final activeTripsProvider = Provider<List<Trip>>((ref) {
  final tripsAsync = ref.watch(tripsProvider);
  return tripsAsync.when(
    data: (trips) {
      final now = DateTime.now();
      print('Current time: $now');
      
      final activeTrips = trips.where((trip) {
        final isActive = trip.status == TripStatus.active;
        final hasStarted = trip.startDate.isBefore(now);
        final hasNotEnded = trip.endDate.isAfter(now);
        
        print('Trip ${trip.name}:');
        print('  Status: ${trip.status} (isActive: $isActive)');
        print('  Start: ${trip.startDate} (hasStarted: $hasStarted)');
        print('  End: ${trip.endDate} (hasNotEnded: $hasNotEnded)');
        print('  Overall active: ${isActive && hasStarted && hasNotEnded}');
        
        return isActive && hasStarted && hasNotEnded;
      }).toList();
      
      print('Active trips count: ${activeTrips.length}');
      return activeTrips;
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

final pastTripsProvider = Provider<List<Trip>>((ref) {
  final tripsAsync = ref.watch(tripsProvider);
  return tripsAsync.when(
    data: (trips) => trips.where((trip) => 
        trip.status == TripStatus.completed || 
        trip.endDate.isBefore(DateTime.now())).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

// Waiting trips provider
final waitingTripsProvider = Provider<List<Trip>>((ref) {
  final tripsAsync = ref.watch(tripsProvider);
  final mockServer = MockServer();
  
  return tripsAsync.when(
    data: (trips) {
      final currentUserId = mockServer.currentUserId;
      if (currentUserId == null) return <Trip>[];
      
      // Get memberships where user is waiting
      final waitingMemberships = mockServer.memberships.where((m) => 
        m.userId == currentUserId && m.status == MembershipStatus.waiting
      ).toList();
      
      return trips.where((trip) => 
        waitingMemberships.any((m) => m.tripId == trip.id)
      ).toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

// Trip action state classes
abstract class TripActionState {
  const TripActionState();

  const factory TripActionState.idle() = _TripActionIdle;
  const factory TripActionState.loading() = _TripActionLoading;
  const factory TripActionState.success() = _TripActionSuccess;
  const factory TripActionState.error({required String message}) = _TripActionError;

  T when<T>({
    required T Function() idle,
    required T Function() loading,
    required T Function() success,
    required T Function(String message) error,
  }) {
    if (this is _TripActionIdle) return idle();
    if (this is _TripActionLoading) return loading();
    if (this is _TripActionSuccess) return success();
    if (this is _TripActionError) return error((this as _TripActionError).message);
    throw Exception('Unknown TripActionState');
  }

  T maybeWhen<T>({
    T Function()? idle,
    T Function()? loading,
    T Function()? success,
    T Function(String message)? error,
    required T Function() orElse,
  }) {
    if (this is _TripActionIdle && idle != null) return idle();
    if (this is _TripActionLoading && loading != null) return loading();
    if (this is _TripActionSuccess && success != null) return success();
    if (this is _TripActionError && error != null) return error((this as _TripActionError).message);
    return orElse();
  }
}

class _TripActionIdle extends TripActionState {
  const _TripActionIdle();
}

class _TripActionLoading extends TripActionState {
  const _TripActionLoading();
}

class _TripActionSuccess extends TripActionState {
  const _TripActionSuccess();
}

class _TripActionError extends TripActionState {
  final String message;
  const _TripActionError({required this.message});
}

