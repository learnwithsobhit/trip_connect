import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import '../data/models/models.dart';

class MockServer {
  static final MockServer _instance = MockServer._internal();
  factory MockServer() => _instance;
  MockServer._internal();

  final _uuid = const Uuid();
  final _random = Random();

  // In-memory data storage
  List<User> _users = [];
  List<Trip> _trips = [];
  List<Membership> _memberships = [];
  List<Message> _messages = [];
  List<Media> _media = [];
  List<Document> _documents = [];
  List<Alert> _alerts = [];
  List<RollCall> _rollCalls = [];
  List<UserRating> _userRatings = [];
  List<TripRating> _tripRatings = [];

  // Stream controllers for real-time updates
  final Map<String, StreamController<Map<String, dynamic>>> _tripStreams = {};
  final StreamController<List<Trip>> _tripsController = StreamController<List<Trip>>.broadcast();
  final StreamController<String> _connectionController = StreamController<String>.broadcast();

  bool _isInitialized = false;
  String? _currentUserId;

  // Getters for accessing private members
  List<User> get users => List.unmodifiable(_users);
  List<Trip> get trips => List.unmodifiable(_trips);
  List<Membership> get memberships => List.unmodifiable(_memberships);
  List<UserRating> get userRatings => List.unmodifiable(_userRatings);
  List<TripRating> get tripRatings => List.unmodifiable(_tripRatings);
  String? get currentUserId => _currentUserId;

  // Initialize with mock data
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Load mock data from assets
      await _loadMockData();
      
      // Initialize mock ratings
      await _initializeMockRatings();
      
      _isInitialized = true;
      
      // Start simulating real-time updates
      _startRealtimeSimulation();
      
      print('MockServer initialized with ${_trips.length} trips and ${_users.length} users');
    } catch (e) {
      print('Error initializing MockServer: $e');
    }
  }

  Future<void> _loadMockData() async {
    // Load users
    final usersJson = await rootBundle.loadString('assets/mock/users.json');
    final usersList = jsonDecode(usersJson) as List;
    _users = usersList.map((json) => User.fromJson(json)).toList();

    // Load trips
    final tripsJson = await rootBundle.loadString('assets/mock/trips.json');
    final tripsList = jsonDecode(tripsJson) as List;
    _trips = tripsList.map((json) => Trip.fromJson(json)).toList();

    // Load memberships
    final membershipsJson = await rootBundle.loadString('assets/mock/memberships.json');
    final membershipsList = jsonDecode(membershipsJson) as List;
    _memberships = membershipsList.map((json) => Membership.fromJson(json)).toList();

    // Load messages
    final messagesJson = await rootBundle.loadString('assets/mock/messages.json');
    final messagesList = jsonDecode(messagesJson) as List;
    _messages = messagesList.map((json) => Message.fromJson(json)).toList();

    // Load media
    final mediaJson = await rootBundle.loadString('assets/mock/media.json');
    final mediaList = jsonDecode(mediaJson) as List;
    _media = mediaList.map((json) => Media.fromJson(json)).toList();

    // Load documents
    final docsJson = await rootBundle.loadString('assets/mock/docs.json');
    final docsList = jsonDecode(docsJson) as List;
    _documents = docsList.map((json) => Document.fromJson(json)).toList();
  }

  void _startRealtimeSimulation() {
    // Simulate periodic location updates
    Timer.periodic(const Duration(seconds: 30), (timer) {
      _simulateLocationUpdates();
    });

    // Simulate occasional messages
    Timer.periodic(const Duration(minutes: 2), (timer) {
      if (_random.nextBool()) {
        _simulateRandomMessage();
      }
    });
  }

  void _simulateLocationUpdates() {
    for (final membership in _memberships) {
      if (membership.location != null && membership.status == MembershipStatus.active) {
        final newLocation = membership.location!.copyWith(
          lat: membership.location!.lat + (_random.nextDouble() - 0.5) * 0.001,
          lng: membership.location!.lng + (_random.nextDouble() - 0.5) * 0.001,
          lastSeen: DateTime.now(),
        );
        
        final updatedMembership = membership.copyWith(location: newLocation);
        final index = _memberships.indexWhere((m) => 
            m.tripId == membership.tripId && m.userId == membership.userId);
        if (index != -1) {
          _memberships[index] = updatedMembership;
        }

        // Emit location update
        _emitToTrip(membership.tripId, {
          'topic': 'presence',
          'event': 'location_update',
          'data': {
            'userId': membership.userId,
            'location': newLocation.toJson(),
          }
        });
      }
    }
  }

  void _simulateRandomMessage() {
    if (_trips.where((t) => t.status == TripStatus.active).isEmpty) return;
    
    final activeTrip = _trips.where((t) => t.status == TripStatus.active).first;
    final members = _memberships.where((m) => 
        m.tripId == activeTrip.id && m.status == MembershipStatus.active).toList();
    
    if (members.isEmpty) return;
    
    final sender = members[_random.nextInt(members.length)];
    final simulatedMessages = [
      "Traffic is moving smoothly 🚗",
      "Beautiful scenery here! 📸",
      "Next stop in 30 minutes ⏰",
      "Everyone doing okay? 👍",
      "Great weather for traveling ☀️",
    ];
    
    final message = Message(
      id: _uuid.v4(),
      tripId: activeTrip.id,
      senderId: sender.userId,
      type: MessageType.chat,
      text: simulatedMessages[_random.nextInt(simulatedMessages.length)],
      createdAt: DateTime.now(),
    );
    
    _messages.add(message);
    
    _emitToTrip(activeTrip.id, {
      'topic': 'chat',
      'event': 'new_message',
      'data': message.toJson(),
    });
  }

  void _emitToTrip(String tripId, Map<String, dynamic> event) {
    if (_tripStreams.containsKey(tripId)) {
      _tripStreams[tripId]?.add(event);
    }
  }

  // Authentication
  Future<Map<String, dynamic>> signIn(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    print('MockServer signIn called - initialized: $_isInitialized, users count: ${_users.length}');
    
    // Ensure MockServer is initialized
    if (!_isInitialized) {
      print('MockServer not initialized, initializing now...');
      await initialize();
    }
    
    // Simple mock authentication
    final user = _users.isNotEmpty ? _users.first : null;
    if (user != null) {
      _currentUserId = user.id;
      print('Sign in successful for user: ${user.displayName}');
      
      // Convert to JSON manually to avoid serialization issues
      final userJson = {
        'id': user.id,
        'displayName': user.displayName,
        'avatarUrl': user.avatarUrl,
        'phone': user.phone,
        'language': user.language,
        'privacy': {
          'locationMode': user.privacy.locationMode.name,
        },
      };
      
      return {
        'success': true,
        'user': userJson,
        'token': 'mock_token_${user.id}',
      };
    }
    
    print('Sign in failed - no users available');
    return {
      'success': false,
      'error': 'Invalid credentials',
    };
  }

  Future<Map<String, dynamic>> signUp(Map<String, dynamic> userData) async {
    await Future.delayed(const Duration(milliseconds: 800));
    
    final newUser = User(
      id: _uuid.v4(),
      displayName: userData['displayName'] ?? 'New User',
      phone: userData['phone'],
      language: userData['language'] ?? 'en',
      privacy: const UserPrivacy(),
    );
    
    _users.add(newUser);
    _currentUserId = newUser.id;
    
    // Convert to JSON manually to avoid serialization issues
    final userJson = {
      'id': newUser.id,
      'displayName': newUser.displayName,
      'avatarUrl': newUser.avatarUrl,
      'phone': newUser.phone,
      'language': newUser.language,
      'privacy': {
        'locationMode': newUser.privacy.locationMode.name,
      },
    };
    
    return {
      'success': true,
      'user': userJson,
      'token': 'mock_token_${newUser.id}',
    };
  }

  Future<Map<String, dynamic>> signInAsGuest({String? displayName}) async {
    await Future.delayed(const Duration(milliseconds: 400));
    
    final guestName = displayName ?? 'Guest User';
    final guestId = 'guest_${DateTime.now().millisecondsSinceEpoch}';
    
    final guestUser = User(
      id: guestId,
      displayName: guestName,
      avatarUrl: null,
      phone: null,
      language: 'en',
      privacy: const UserPrivacy(locationMode: LocationMode.approx),
    );
    
    // Store guest user temporarily (they won't be persisted)
    _currentUserId = guestUser.id;
    
    // Convert to JSON manually to avoid serialization issues
    final userJson = {
      'id': guestUser.id,
      'displayName': guestUser.displayName,
      'avatarUrl': guestUser.avatarUrl,
      'phone': guestUser.phone,
      'language': guestUser.language,
      'privacy': {
        'locationMode': guestUser.privacy.locationMode.name,
      },
    };
    
    return {
      'success': true,
      'user': userJson,
      'token': 'guest_token_$guestId',
    };
  }

  // Trip Management
  Future<List<Trip>> getTrips() async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    print('MockServer getTrips called - currentUserId: $_currentUserId');
    
    if (_currentUserId == null) {
      print('No current user set, returning empty trip list');
      return [];
    }
    
    final userTripIds = _memberships
        .where((m) => m.userId == _currentUserId)
        .map((m) => m.tripId)
        .toSet();
    
    print('Found ${userTripIds.length} trip memberships for user $_currentUserId');
    print('Total trips available: ${_trips.length}');
    print('Total memberships: ${_memberships.length}');
    
    final userTrips = _trips.where((t) => userTripIds.contains(t.id)).toList();
    print('Returning ${userTrips.length} trips for user');
    
    return userTrips;
  }

  Future<Trip?> getTrip(String tripId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    
    try {
      return _trips.firstWhere((t) => t.id == tripId);
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>> createTrip(Map<String, dynamic> tripData) async {
    await Future.delayed(const Duration(milliseconds: 600));
    
    if (_currentUserId == null) {
      return {'success': false, 'error': 'Not authenticated'};
    }
    
    final inviteCode = _generateInviteCode();
    final trip = Trip(
      id: _uuid.v4(),
      name: tripData['name'] ?? 'New Trip',
      theme: tripData['theme'] ?? 'Adventure',
      origin: Location.fromJson(tripData['origin']),
      destination: Location.fromJson(tripData['destination']),
      startDate: DateTime.parse(tripData['startDate']),
      endDate: DateTime.parse(tripData['endDate']),
      seatsTotal: tripData['seatsTotal'] ?? 10,
      seatsAvailable: tripData['seatsTotal'] ?? 10,
      privacy: tripData['privacy'] == 'public' ? TripPrivacy.public : TripPrivacy.private,
      leaderId: _currentUserId!,
      invite: TripInvite(
        code: inviteCode,
        qr: 'tc://join?trip=${_uuid.v4()}&code=$inviteCode',
      ),
      schedule: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    _trips.add(trip);
    
    // Create leader membership
    final membership = Membership(
      tripId: trip.id,
      userId: _currentUserId!,
      role: UserRole.leader,
      joinedAt: DateTime.now(),
    );
    _memberships.add(membership);
    
    _tripsController.add(_trips);
    
    return {
      'success': true,
      'trip': trip.toJson(),
    };
  }

  Future<Map<String, dynamic>> joinTrip(String code) async {
    await Future.delayed(const Duration(milliseconds: 400));
    
    if (_currentUserId == null) {
      return {'success': false, 'error': 'Not authenticated'};
    }
    
    // Check for overlapping dates with existing trips
    final userMemberships = _memberships.where((m) => 
      m.userId == _currentUserId && 
      (m.status == MembershipStatus.active || m.status == MembershipStatus.pending)
    ).toList();
    
    // Get trip being joined to check its dates
    final tripToJoin = _trips.cast<Trip?>().firstWhere(
      (t) => t?.invite.code == code,
      orElse: () => null,
    );
    
    if (tripToJoin == null) {
      return {'success': false, 'error': 'Invalid invite code'};
    }

    // Check rating eligibility
    final eligibilityCheck = await checkRatingEligibility(tripToJoin.id);
    if (!eligibilityCheck['eligible']) {
      return {
        'success': false,
        'error': eligibilityCheck['reason'],
        'type': 'RATING_REQUIREMENT_NOT_MET',
        'currentRating': eligibilityCheck['currentRating'],
        'requiredRating': eligibilityCheck['requiredRating'],
      };
    }
    
    // Check for date overlaps with existing trips
    for (final membership in userMemberships) {
      final existingTrip = _trips.firstWhere((t) => t.id == membership.tripId);
      
      // Check if dates overlap
      final hasOverlap = _datesOverlap(
        tripToJoin.startDate, tripToJoin.endDate,
        existingTrip.startDate, existingTrip.endDate,
      );
      
      if (hasOverlap) {
        return {
          'success': false,
          'error': 'Trip dates overlap with "${existingTrip.name}" (${_formatDateRange(existingTrip.startDate, existingTrip.endDate)}). You can have multiple trips but not with overlapping dates.',
          'conflictingTripId': existingTrip.id,
          'conflictingTripName': existingTrip.name,
          'conflictingDates': _formatDateRange(existingTrip.startDate, existingTrip.endDate),
          'newTripDates': _formatDateRange(tripToJoin.startDate, tripToJoin.endDate),
        };
      }
    }
    
    // Check if already a member of this specific trip
    final existingMembership = _memberships.cast<Membership?>().firstWhere(
      (m) => m?.tripId == tripToJoin.id && m?.userId == _currentUserId,
      orElse: () => null,
    );
    
    if (existingMembership != null) {
      return {'success': false, 'error': 'Already a member of this trip'};
    }

    // Check seat availability
    final currentMemberships = _memberships.where((m) => 
      m.tripId == tripToJoin.id && 
      (m.status == MembershipStatus.active || m.status == MembershipStatus.pending)
    ).length;
    
    final isWaitingList = currentMemberships >= tripToJoin.seatsTotal;
    final membershipStatus = isWaitingList 
        ? MembershipStatus.waiting 
        : (tripToJoin.privacy == TripPrivacy.private 
            ? MembershipStatus.pending 
            : MembershipStatus.active);
    
    final membership = Membership(
      tripId: tripToJoin.id,
      userId: _currentUserId!,
      role: UserRole.traveler,
      joinedAt: DateTime.now(),
      status: membershipStatus,
    );
    
    _memberships.add(membership);
    
    return {
      'success': true,
      'trip': tripToJoin.toJson(),
      'membership': membership.toJson(),
      'isWaitingList': isWaitingList,
      'message': isWaitingList 
          ? 'Added to waiting list. You will be notified if a seat becomes available.'
          : 'Successfully joined the trip!',
    };
  }

  Future<Map<String, dynamic>> leaveTrip(String tripId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    if (_currentUserId == null) {
      return {'success': false, 'error': 'Not authenticated'};
    }
    
    final trip = _trips.cast<Trip?>().firstWhere(
      (t) => t?.id == tripId,
      orElse: () => null,
    );
    
    if (trip == null) {
      return {'success': false, 'error': 'Trip not found'};
    }
    
    // Check if user is the leader
    if (trip.leaderId == _currentUserId) {
      return {'success': false, 'error': 'Trip leaders cannot leave their own trip. Transfer leadership first.'};
    }
    
    // Find user's membership
    final membershipIndex = _memberships.indexWhere(
      (m) => m.tripId == tripId && m.userId == _currentUserId
    );
    
    if (membershipIndex == -1) {
      return {'success': false, 'error': 'You are not a member of this trip'};
    }
    
    // Update membership status to "left"
    final membership = _memberships[membershipIndex];
    final updatedMembership = membership.copyWith(
      status: MembershipStatus.left,
      lastSeen: DateTime.now(),
    );
    
    _memberships[membershipIndex] = updatedMembership;
    
    // Emit real-time update
    _emitToTrip(tripId, {
      'topic': 'membership',
      'event': 'member_left',
      'data': {
        'userId': _currentUserId,
        'userName': _users.firstWhere((u) => u.id == _currentUserId).displayName,
        'timestamp': DateTime.now().toIso8601String(),
      },
    });
    
    return {
      'success': true,
      'message': 'Successfully left the trip',
      'trip': trip.toJson(),
    };
  }

  // Real-time streams
  Stream<Map<String, dynamic>> getTripStream(String tripId) {
    if (!_tripStreams.containsKey(tripId)) {
      _tripStreams[tripId] = StreamController<Map<String, dynamic>>.broadcast();
    }
    return _tripStreams[tripId]!.stream;
  }

  Stream<List<Trip>> get tripsStream => _tripsController.stream;
  Stream<String> get connectionStream => _connectionController.stream;

  String _generateInviteCode() {
    const chars = 'ABCDEFGHIJKLMNPQRSTUVWXYZ123456789';
    return List.generate(6, (index) => chars[_random.nextInt(chars.length)]).join();
  }

  // Chat functionality
  Future<List<Message>> getMessages(String tripId, {int limit = 50, String? before}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    
    var messages = _messages.where((m) => m.tripId == tripId).toList();
    messages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    if (before != null) {
      final beforeIndex = messages.indexWhere((m) => m.id == before);
      if (beforeIndex != -1) {
        messages = messages.skip(beforeIndex + 1).toList();
      }
    }
    
    return messages.take(limit).toList();
  }

  Future<Message> sendMessage(String tripId, String text, {
    MessageType type = MessageType.chat,
    List<String> tags = const [],
    bool requiresAck = false,
  }) async {
    await Future.delayed(const Duration(milliseconds: 150));
    
    final message = Message(
      id: _uuid.v4(),
      tripId: tripId,
      senderId: _currentUserId!,
      type: type,
      text: text,
      tags: tags,
      createdAt: DateTime.now(),
      requiresAck: requiresAck,
    );
    
    _messages.add(message);
    
    _emitToTrip(tripId, {
      'topic': 'chat',
      'event': 'new_message',
      'data': message.toJson(),
    });
    
    return message;
  }

  // Emergency and alerts
  Future<Alert> raiseAlert(String tripId, AlertKind kind, AlertPayload payload) async {
    await Future.delayed(const Duration(milliseconds: 100));
    
    final alert = Alert(
      id: _uuid.v4(),
      tripId: tripId,
      kind: kind,
      raisedBy: _currentUserId!,
      payload: payload,
      createdAt: DateTime.now(),
      priority: kind == AlertKind.sos ? AlertPriority.critical : AlertPriority.medium,
    );
    
    _alerts.add(alert);
    
    _emitToTrip(tripId, {
      'topic': 'alert',
      'event': 'new_alert',
      'data': alert.toJson(),
    });
    
    return alert;
  }

  // Roll call functionality
  Future<RollCall> startRollCall(String tripId, {String? stopId, int graceMin = 10}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    
    final rollCall = RollCall(
      id: _uuid.v4(),
      tripId: tripId,
      stopId: stopId,
      startedBy: _currentUserId!,
      startedAt: DateTime.now(),
      graceMin: graceMin,
    );
    
    _rollCalls.add(rollCall);
    
    _emitToTrip(tripId, {
      'topic': 'rollcall',
      'event': 'started',
      'data': rollCall.toJson(),
    });
    
    return rollCall;
  }

  Future<CheckIn> checkIn(String rollCallId, {CheckInMode mode = CheckInMode.manual}) async {
    await Future.delayed(const Duration(milliseconds: 100));
    
    final rollCallIndex = _rollCalls.indexWhere((rc) => rc.id == rollCallId);
    if (rollCallIndex == -1) {
      throw Exception('Roll call not found');
    }
    
    final rollCall = _rollCalls[rollCallIndex];
    final checkIn = CheckIn(
      userId: _currentUserId!,
      time: DateTime.now(),
      mode: mode,
    );
    
    final updatedRollCall = rollCall.copyWith(
      checkins: [...rollCall.checkins, checkIn],
    );
    
    _rollCalls[rollCallIndex] = updatedRollCall;
    
    _emitToTrip(rollCall.tripId, {
      'topic': 'rollcall',
      'event': 'checkin',
      'data': {
        'rollCallId': rollCallId,
        'checkIn': checkIn.toJson(),
      },
    });
    
    return checkIn;
  }

  // Cleanup
  // Helper methods for date validation
  bool _datesOverlap(DateTime start1, DateTime end1, DateTime start2, DateTime end2) {
    // Two date ranges overlap if:
    // 1. start1 is before end2 AND
    // 2. start2 is before end1
    return start1.isBefore(end2) && start2.isBefore(end1);
  }

  String _formatDateRange(DateTime start, DateTime end) {
    final startFormatted = '${start.day}/${start.month}/${start.year}';
    final endFormatted = '${end.day}/${end.month}/${end.year}';
    return '$startFormatted - $endFormatted';
  }

  void dispose() {
    for (final controller in _tripStreams.values) {
      controller.close();
    }
    _tripStreams.clear();
    _tripsController.close();
    _connectionController.close();
  }

  // ============================================================================
  // Rating and Feedback Methods
  // ============================================================================

  /// Submit a rating for a user
  Future<Map<String, dynamic>> rateUser({
    required String ratedUserId,
    required String tripId,
    required double rating,
    String? feedback,
    List<String>? tags,
  }) async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));

      if (_currentUserId == null) {
        return {'success': false, 'error': 'User not authenticated'};
      }

      if (_currentUserId == ratedUserId) {
        return {'success': false, 'error': 'Cannot rate yourself'};
      }

      // Check if user has already rated this user for this trip
      final existingRating = _userRatings.firstWhere(
        (r) => r.raterId == _currentUserId && 
               r.ratedUserId == ratedUserId && 
               r.tripId == tripId,
        orElse: () => UserRating(
          id: '', raterId: '', ratedUserId: '', tripId: '', 
          rating: 0, createdAt: DateTime.now(),
        ),
      );

      final userRating = UserRating(
        id: existingRating.id.isEmpty ? _uuid.v4() : existingRating.id,
        raterId: _currentUserId!,
        ratedUserId: ratedUserId,
        tripId: tripId,
        rating: rating,
        feedback: feedback,
        tags: tags ?? [],
        createdAt: existingRating.id.isEmpty ? DateTime.now() : existingRating.createdAt,
      );

      if (existingRating.id.isEmpty) {
        _userRatings.add(userRating);
      } else {
        final index = _userRatings.indexWhere((r) => r.id == existingRating.id);
        _userRatings[index] = userRating;
      }

      // Update user's rating summary
      await _updateUserRatingSummary(ratedUserId);

      return {
        'success': true,
        'rating': userRating.toJson(),
        'message': 'Rating submitted successfully',
      };
    } catch (e) {
      return {'success': false, 'error': 'Failed to submit rating: $e'};
    }
  }

  /// Submit a rating for a trip
  Future<Map<String, dynamic>> rateTrip({
    required String tripId,
    required double overallRating,
    required double organizationRating,
    required double valueRating,
    required double experienceRating,
    String? feedback,
    List<String>? highlights,
    List<String>? improvements,
    bool wouldRecommend = true,
  }) async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));

      if (_currentUserId == null) {
        return {'success': false, 'error': 'User not authenticated'};
      }

      // Check if user has already rated this trip
      final existingRating = _tripRatings.firstWhere(
        (r) => r.userId == _currentUserId && r.tripId == tripId,
        orElse: () => TripRating(
          id: '', userId: '', tripId: '', overallRating: 0,
          organizationRating: 0, valueRating: 0, experienceRating: 0,
          createdAt: DateTime.now(),
        ),
      );

      final tripRating = TripRating(
        id: existingRating.id.isEmpty ? _uuid.v4() : existingRating.id,
        userId: _currentUserId!,
        tripId: tripId,
        overallRating: overallRating,
        organizationRating: organizationRating,
        valueRating: valueRating,
        experienceRating: experienceRating,
        feedback: feedback,
        highlights: highlights ?? [],
        improvements: improvements ?? [],
        wouldRecommend: wouldRecommend,
        createdAt: existingRating.id.isEmpty ? DateTime.now() : existingRating.createdAt,
      );

      if (existingRating.id.isEmpty) {
        _tripRatings.add(tripRating);
      } else {
        final index = _tripRatings.indexWhere((r) => r.id == existingRating.id);
        _tripRatings[index] = tripRating;
      }

      // Update trip's rating summary
      await _updateTripRatingSummary(tripId);

      return {
        'success': true,
        'rating': tripRating.toJson(),
        'message': 'Trip rating submitted successfully',
      };
    } catch (e) {
      return {'success': false, 'error': 'Failed to submit trip rating: $e'};
    }
  }

  /// Get ratings for a specific user
  Future<List<UserRating>> getUserRatings(String userId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _userRatings.where((r) => r.ratedUserId == userId).toList();
  }

  /// Get ratings for a specific trip
  Future<List<TripRating>> getTripRatings(String tripId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _tripRatings.where((r) => r.tripId == tripId).toList();
  }

  /// Get rating given by current user for another user in a specific trip
  Future<UserRating?> getUserRatingByCurrentUser(String ratedUserId, String tripId) async {
    if (_currentUserId == null) return null;
    
    await Future.delayed(const Duration(milliseconds: 150));
    
    try {
      return _userRatings.firstWhere(
        (r) => r.raterId == _currentUserId && 
               r.ratedUserId == ratedUserId && 
               r.tripId == tripId,
      );
    } catch (e) {
      return null;
    }
  }

  /// Get trip rating given by current user
  Future<TripRating?> getTripRatingByCurrentUser(String tripId) async {
    if (_currentUserId == null) return null;
    
    await Future.delayed(const Duration(milliseconds: 150));
    
    try {
      return _tripRatings.firstWhere(
        (r) => r.userId == _currentUserId && r.tripId == tripId,
      );
    } catch (e) {
      return null;
    }
  }

  /// Check if current user can join a trip based on rating requirements
  Future<Map<String, dynamic>> checkRatingEligibility(String tripId) async {
    if (_currentUserId == null) {
      return {'eligible': false, 'reason': 'User not authenticated'};
    }

    final trip = _trips.firstWhere(
      (t) => t.id == tripId,
      orElse: () => throw Exception('Trip not found'),
    );

    final currentUser = _users.firstWhere(
      (u) => u.id == _currentUserId,
      orElse: () => throw Exception('User not found'),
    );

    // If no minimum rating requirement, user is eligible
    if (trip.minimumUserRating <= 0) {
      return {'eligible': true};
    }

    // Check user's average rating
    if (currentUser.ratingSummary.averageRating >= trip.minimumUserRating) {
      return {'eligible': true};
    }

    return {
      'eligible': false,
      'reason': 'Your rating (${currentUser.ratingSummary.averageRating.toStringAsFixed(1)}) '
                'is below the minimum required (${trip.minimumUserRating.toStringAsFixed(1)})',
      'currentRating': currentUser.ratingSummary.averageRating,
      'requiredRating': trip.minimumUserRating,
    };
  }

  /// Get trips filtered by rating
  Future<List<Trip>> getTripsFilteredByRating({
    double? minRating,
    double? maxRating,
    int? minReviews,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    return _trips.where((trip) {
      if (minRating != null && trip.ratingSummary.averageRating < minRating) {
        return false;
      }
      if (maxRating != null && trip.ratingSummary.averageRating > maxRating) {
        return false;
      }
      if (minReviews != null && trip.ratingSummary.totalRatings < minReviews) {
        return false;
      }
      return true;
    }).toList();
  }

  /// Private method to update user rating summary
  Future<void> _updateUserRatingSummary(String userId) async {
    final userRatings = _userRatings.where((r) => r.ratedUserId == userId).toList();
    
    if (userRatings.isEmpty) return;

    final totalRating = userRatings.fold<double>(0, (sum, r) => sum + r.rating);
    final averageRating = totalRating / userRatings.length;
    
    // Get most common tags
    final allTags = userRatings.expand((r) => r.tags).toList();
    final tagCounts = <String, int>{};
    for (final tag in allTags) {
      tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
    }
    final topTags = tagCounts.entries
        .toList()
        ..sort((a, b) => b.value.compareTo(a.value));
    final topTagsList = topTags.take(5).map((e) => e.key).toList();

    // Get recent feedback
    final feedbackList = userRatings
        .where((r) => r.feedback?.isNotEmpty == true)
        .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final recentFeedback = feedbackList.take(3).map((r) => r.feedback!).toList();

    // Update user's rating summary
    final userIndex = _users.indexWhere((u) => u.id == userId);
    if (userIndex >= 0) {
      final user = _users[userIndex];
      final updatedUser = user.copyWith(
        ratingSummary: UserRatingSummary(
          userId: userId,
          averageRating: averageRating,
          totalRatings: userRatings.length,
          completedTrips: user.ratingSummary.completedTrips,
          topTags: topTagsList,
          recentFeedback: recentFeedback,
          isVerified: user.ratingSummary.isVerified,
          lastUpdated: DateTime.now(),
        ),
      );
      _users[userIndex] = updatedUser;
    }
  }

  /// Private method to update trip rating summary
  Future<void> _updateTripRatingSummary(String tripId) async {
    final tripRatings = _tripRatings.where((r) => r.tripId == tripId).toList();
    
    if (tripRatings.isEmpty) return;

    final totalOverall = tripRatings.fold<double>(0, (sum, r) => sum + r.overallRating);
    final totalOrganization = tripRatings.fold<double>(0, (sum, r) => sum + r.organizationRating);
    final totalValue = tripRatings.fold<double>(0, (sum, r) => sum + r.valueRating);
    final totalExperience = tripRatings.fold<double>(0, (sum, r) => sum + r.experienceRating);
    
    final count = tripRatings.length;
    final averageRating = totalOverall / count;
    final organizationRating = totalOrganization / count;
    final valueRating = totalValue / count;
    final experienceRating = totalExperience / count;
    
    // Get top highlights
    final allHighlights = tripRatings.expand((r) => r.highlights).toList();
    final highlightCounts = <String, int>{};
    for (final highlight in allHighlights) {
      highlightCounts[highlight] = (highlightCounts[highlight] ?? 0) + 1;
    }
    final highlightsList = highlightCounts.entries
        .toList()
        ..sort((a, b) => b.value.compareTo(a.value));
    final topHighlights = highlightsList.take(5).map((e) => e.key).toList();

    final recommendationCount = tripRatings.where((r) => r.wouldRecommend).length;

    // Update trip's rating summary
    final tripIndex = _trips.indexWhere((t) => t.id == tripId);
    if (tripIndex >= 0) {
      final trip = _trips[tripIndex];
      final updatedTrip = trip.copyWith(
        ratingSummary: TripRatingSummary(
          tripId: tripId,
          averageRating: averageRating,
          organizationRating: organizationRating,
          valueRating: valueRating,
          experienceRating: experienceRating,
          totalRatings: count,
          topHighlights: topHighlights,
          recommendationCount: recommendationCount,
          lastUpdated: DateTime.now(),
        ),
      );
      _trips[tripIndex] = updatedTrip;
    }
  }

  /// Initialize mock rating data
  Future<void> _initializeMockRatings() async {
    // Generate mock user ratings
    for (int i = 0; i < 50; i++) {
      final raterId = _users[_random.nextInt(_users.length)].id;
      final ratedUserId = _users[_random.nextInt(_users.length)].id;
      final tripId = _trips[_random.nextInt(_trips.length)].id;
      
      if (raterId != ratedUserId) {
        final rating = UserRating(
          id: _uuid.v4(),
          raterId: raterId,
          ratedUserId: ratedUserId,
          tripId: tripId,
          rating: 3.0 + _random.nextDouble() * 2.0, // 3.0 to 5.0
          feedback: _random.nextBool() ? 'Great travel companion!' : null,
          tags: UserRatingTag.values
              .take(_random.nextInt(3) + 1)
              .map((tag) => tag.name)
              .toList(),
          createdAt: DateTime.now().subtract(Duration(days: _random.nextInt(90))),
        );
        _userRatings.add(rating);
      }
    }

    // Generate mock trip ratings
    for (int i = 0; i < 30; i++) {
      final userId = _users[_random.nextInt(_users.length)].id;
      final tripId = _trips[_random.nextInt(_trips.length)].id;
      
      final baseRating = 3.5 + _random.nextDouble() * 1.5; // 3.5 to 5.0
      final rating = TripRating(
        id: _uuid.v4(),
        userId: userId,
        tripId: tripId,
        overallRating: baseRating,
        organizationRating: baseRating + (_random.nextDouble() - 0.5) * 0.5,
        valueRating: baseRating + (_random.nextDouble() - 0.5) * 0.5,
        experienceRating: baseRating + (_random.nextDouble() - 0.5) * 0.5,
        feedback: _random.nextBool() ? 'Amazing trip experience!' : null,
        highlights: TripHighlight.values
            .take(_random.nextInt(3) + 1)
            .map((highlight) => highlight.name)
            .toList(),
        improvements: [],
        wouldRecommend: _random.nextDouble() > 0.2, // 80% would recommend
        createdAt: DateTime.now().subtract(Duration(days: _random.nextInt(180))),
      );
      _tripRatings.add(rating);
    }

    // Update all rating summaries
    for (final user in _users) {
      await _updateUserRatingSummary(user.id);
    }
    
    for (final trip in _trips) {
      await _updateTripRatingSummary(trip.id);
    }
  }


}


