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
  List<Budget> _budgets = [];
  List<Expense> _expenses = [];
  List<EntertainmentActivity> _entertainmentActivities = [];
  List<GameSession> _gameSessions = [];

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
  List<Budget> get budgets => List.unmodifiable(_budgets);
  List<Expense> get expenses => List.unmodifiable(_expenses);
  String? get currentUserId => _currentUserId;

  // Initialize with mock data
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Load mock data from assets
      await _loadMockData();
      
      // Initialize mock ratings
      await _initializeMockRatings();
      
      // Initialize mock budgets
      await _initializeMockBudgets();
      
      // Initialize mock entertainment activities
      await _initializeMockEntertainment();
      
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
    print('MockServer getUserRatingByCurrentUser called - currentUserId: $_currentUserId, ratedUserId: $ratedUserId, tripId: $tripId');
    
    if (_currentUserId == null) {
      print('MockServer getUserRatingByCurrentUser - currentUserId is null, returning null');
      return null;
    }
    
    await Future.delayed(const Duration(milliseconds: 150));
    
    try {
      final rating = _userRatings.firstWhere(
        (r) => r.raterId == _currentUserId && 
               r.ratedUserId == ratedUserId && 
               r.tripId == tripId,
      );
      print('MockServer getUserRatingByCurrentUser - found existing rating: ${rating.rating}');
      return rating;
    } catch (e) {
      print('MockServer getUserRatingByCurrentUser - no existing rating found, returning null');
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

  /// Initialize mock budget data
  Future<void> _initializeMockBudgets() async {
    // Generate mock budgets for each trip
    for (final trip in _trips) {
      final totalBudget = 5000.0 + _random.nextDouble() * 10000.0; // $5000-$15000
      final categories = [
        BudgetCategory(
          id: 'transportation',
          name: 'Transportation',
          allocatedAmount: totalBudget * 0.3,
          spentAmount: totalBudget * 0.25,
          color: '#FF6B6B',
          icon: '🚗',
        ),
        BudgetCategory(
          id: 'accommodation',
          name: 'Accommodation',
          allocatedAmount: totalBudget * 0.4,
          spentAmount: totalBudget * 0.35,
          color: '#4ECDC4',
          icon: '🏨',
        ),
        BudgetCategory(
          id: 'food',
          name: 'Food & Dining',
          allocatedAmount: totalBudget * 0.2,
          spentAmount: totalBudget * 0.15,
          color: '#45B7D1',
          icon: '🍽️',
        ),
        BudgetCategory(
          id: 'activities',
          name: 'Activities',
          allocatedAmount: totalBudget * 0.1,
          spentAmount: totalBudget * 0.08,
          color: '#96CEB4',
          icon: '🎯',
        ),
      ];

      final budget = Budget(
        id: _uuid.v4(),
        tripId: trip.id,
        totalBudget: totalBudget,
        spentAmount: totalBudget * 0.83, // 83% spent
        currency: 'USD',
        createdAt: DateTime.now().subtract(Duration(days: _random.nextInt(30))),
        updatedAt: DateTime.now(),
        categories: categories,
        memberIds: _memberships.where((m) => m.tripId == trip.id).map((m) => m.userId).toList(),
        description: 'Budget for ${trip.name}',
      );
      _budgets.add(budget);

      // Generate mock expenses for each trip
      final memberIds = _memberships.where((m) => m.tripId == trip.id).map((m) => m.userId).toList();
      for (int i = 0; i < 15; i++) {
        final category = categories[_random.nextInt(categories.length)];
        final amount = 50.0 + _random.nextDouble() * 500.0;
        final paidByUserId = memberIds[_random.nextInt(memberIds.length)];
        
        final expense = Expense(
          id: _uuid.v4(),
          tripId: trip.id,
          categoryId: category.id,
          amount: amount,
          currency: 'USD',
          description: _getRandomExpenseDescription(category.name),
          paidByUserId: paidByUserId,
          splitBetweenUserIds: memberIds,
          splitType: ExpenseSplitType.equal,
          date: DateTime.now().subtract(Duration(days: _random.nextInt(30))),
          createdAt: DateTime.now().subtract(Duration(days: _random.nextInt(30))),
          updatedAt: DateTime.now().subtract(Duration(days: _random.nextInt(30))),
          status: _random.nextBool() ? ExpenseStatus.settled : ExpenseStatus.pending,
          location: _random.nextBool() ? 'Trip Location' : null,
          tags: _random.nextBool() ? ['urgent', 'important'] : null,
        );
        _expenses.add(expense);
      }
    }
  }

  Future<void> _initializeMockEntertainment() async {
    // Create mock entertainment activities for the active trip
    _entertainmentActivities = [
      EntertainmentActivity(
        id: 'ent_001',
        tripId: 't_001',
        title: 'Beach Volleyball Tournament',
        description: 'Fun beach volleyball game with prizes for winners!',
        type: ActivityType.outdoor,
        status: ActivityStatus.planned,
        scheduledAt: DateTime.now().add(const Duration(hours: 2)),
        durationMinutes: 90,
        participantIds: ['u_leader', 'u_123'],
        organizerId: 'u_leader',
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
        location: 'Calangute Beach',
        maxParticipants: 12,
        tags: ['sports', 'beach', 'team'],
      ),
      EntertainmentActivity(
        id: 'ent_002',
        tripId: 't_001',
        title: 'Goa Trivia Night',
        description: 'Test your knowledge about Goa and win exciting prizes!',
        type: ActivityType.quiz,
        status: ActivityStatus.planned,
        scheduledAt: DateTime.now().add(const Duration(days: 1)),
        durationMinutes: 60,
        participantIds: ['u_leader', 'u_123', 'u_456'],
        organizerId: 'u_123',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
        location: 'Hotel Lobby',
        maxParticipants: 20,
        tags: ['knowledge', 'fun', 'prizes'],
        gameRules: {
          'rounds': 5,
          'points_per_question': 10,
          'time_limit': 30,
        },
      ),
      EntertainmentActivity(
        id: 'ent_003',
        tripId: 't_001',
        title: 'Photo Scavenger Hunt',
        description: 'Find and photograph specific landmarks around Goa!',
        type: ActivityType.challenge,
        status: ActivityStatus.active,
        scheduledAt: DateTime.now().subtract(const Duration(hours: 1)),
        durationMinutes: 120,
        participantIds: ['u_leader', 'u_123', 'u_456'],
        organizerId: 'u_456',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
        location: 'Panaji City',
        maxParticipants: 15,
        tags: ['photography', 'exploration', 'landmarks'],
        gameRules: {
          'landmarks': ['Basilica of Bom Jesus', 'Fort Aguada', 'Dona Paula'],
          'bonus_points': 50,
        },
      ),
      EntertainmentActivity(
        id: 'ent_004',
        tripId: 't_001',
        title: 'Cultural Dance Workshop',
        description: 'Learn traditional Goan dance moves from local experts!',
        type: ActivityType.cultural,
        status: ActivityStatus.completed,
        scheduledAt: DateTime.now().subtract(const Duration(days: 1)),
        durationMinutes: 90,
        participantIds: ['u_leader', 'u_123', 'u_456'],
        organizerId: 'u_leader',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
        location: 'Cultural Center',
        maxParticipants: 25,
        tags: ['cultural', 'dance', 'learning'],
      ),
    ];

    // Create mock game sessions
    _gameSessions = [
      GameSession(
        id: 'game_001',
        activityId: 'ent_002',
        gameType: 'trivia',
        status: GameStatus.completed,
        startedAt: DateTime.now().subtract(const Duration(hours: 3)),
        endedAt: DateTime.now().subtract(const Duration(hours: 2)),
        playerIds: ['u_leader', 'u_123', 'u_456'],
        scores: {
          'u_leader': 85,
          'u_123': 92,
          'u_456': 78,
        },
        gameData: {
          'total_questions': 20,
          'correct_answers': {
            'u_leader': 17,
            'u_123': 18,
            'u_456': 15,
          },
        },
        winnerId: 'u_123',
        winners: ['u_123'],
      ),
      GameSession(
        id: 'game_002',
        activityId: 'ent_003',
        gameType: 'scavenger_hunt',
        status: GameStatus.active,
        startedAt: DateTime.now().subtract(const Duration(hours: 1)),
        playerIds: ['u_leader', 'u_123', 'u_456'],
        scores: {
          'u_leader': 150,
          'u_123': 120,
          'u_456': 180,
        },
        gameData: {
          'landmarks_found': {
            'u_leader': 2,
            'u_123': 1,
            'u_456': 3,
          },
          'bonus_points': {
            'u_leader': 50,
            'u_123': 20,
            'u_456': 80,
          },
        },
      ),
    ];
  }

  String _getRandomExpenseDescription(String category) {
    final descriptions = {
      'Transportation': [
        'Flight tickets',
        'Car rental',
        'Taxi fare',
        'Bus tickets',
        'Train tickets',
        'Fuel expenses',
      ],
      'Accommodation': [
        'Hotel booking',
        'Resort stay',
        'Hostel accommodation',
        'Apartment rental',
        'Camping fees',
      ],
      'Food & Dining': [
        'Restaurant dinner',
        'Lunch at cafe',
        'Breakfast buffet',
        'Street food',
        'Groceries',
        'Coffee break',
      ],
      'Activities': [
        'Adventure sports',
        'Museum tickets',
        'Guided tour',
        'Water sports',
        'Hiking equipment',
        'Cultural show',
      ],
    };
    
    final categoryDescriptions = descriptions[category] ?? ['Miscellaneous expense'];
    return categoryDescriptions[_random.nextInt(categoryDescriptions.length)];
  }

  // Budget Methods
  Future<Budget?> getBudget(String tripId) async {
    await Future.delayed(Duration(milliseconds: 500)); // Simulate network delay
    try {
      return _budgets.firstWhere((b) => b.tripId == tripId);
    } catch (e) {
      return null;
    }
  }

  Future<List<Expense>> getExpenses(String tripId) async {
    await Future.delayed(Duration(milliseconds: 300)); // Simulate network delay
    return _expenses.where((e) => e.tripId == tripId).toList();
  }

  Future<BudgetReport?> getBudgetReport(String tripId) async {
    await Future.delayed(Duration(milliseconds: 800)); // Simulate network delay
    
    final budget = await getBudget(tripId);
    final expenses = await getExpenses(tripId);
    
    if (budget == null) return null;

    // Calculate category reports
    final categoryReports = budget.categories.map((category) {
      final categoryExpenses = expenses.where((e) => e.categoryId == category.id).toList();
      final spentAmount = categoryExpenses.fold(0.0, (sum, e) => sum + e.amount);
      final remainingAmount = category.allocatedAmount - spentAmount;
      final utilizationPercentage = category.allocatedAmount > 0 
          ? (spentAmount / category.allocatedAmount) * 100 
          : 0.0;

      return CategoryReport(
        categoryId: category.id,
        categoryName: category.name,
        allocatedAmount: category.allocatedAmount,
        spentAmount: spentAmount,
        remainingAmount: remainingAmount,
        utilizationPercentage: utilizationPercentage,
        expenseCount: categoryExpenses.length,
      );
    }).toList();

    // Calculate user reports
    final memberIds = budget.memberIds;
    final userReports = memberIds.map((userId) {
      final userExpenses = expenses.where((e) => e.paidByUserId == userId).toList();
      final totalPaid = userExpenses.fold(0.0, (sum, e) => sum + e.amount);
      final totalOwed = expenses.fold(0.0, (sum, e) => sum + (e.amount / e.splitBetweenUserIds.length));
      final netAmount = totalPaid - totalOwed;
      
      final user = _users.firstWhere((u) => u.id == userId, orElse: () => User(
        id: userId, 
        displayName: 'Unknown User', 
        email: 'unknown@example.com',
        privacy: const UserPrivacy(),
      ));
      
      return UserExpenseReport(
        userId: userId,
        userName: user.displayName,
        totalPaid: totalPaid,
        totalOwed: totalOwed,
        netAmount: netAmount,
        expenseCount: userExpenses.length,
        expenses: userExpenses,
      );
    }).toList();

    return BudgetReport(
      tripId: tripId,
      totalBudget: budget.totalBudget,
      totalSpent: budget.spentAmount,
      remainingBudget: budget.totalBudget - budget.spentAmount,
      budgetUtilizationPercentage: (budget.spentAmount / budget.totalBudget) * 100,
      categoryReports: categoryReports,
      userReports: userReports,
      recentExpenses: expenses.take(10).toList(),
      generatedAt: DateTime.now(),
    );
  }

  Future<void> createBudget({
    required String tripId,
    required double totalBudget,
    required String currency,
    required List<BudgetCategory> categories,
    String? description,
  }) async {
    await Future.delayed(Duration(milliseconds: 1000)); // Simulate network delay
    
    final budget = Budget(
      id: _uuid.v4(),
      tripId: tripId,
      totalBudget: totalBudget,
      spentAmount: 0.0,
      currency: currency,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      categories: categories,
      memberIds: _memberships.where((m) => m.tripId == tripId).map((m) => m.userId).toList(),
      description: description,
    );
    
    _budgets.add(budget);
  }

  Future<void> addExpense({
    required String tripId,
    required String categoryId,
    required double amount,
    required String currency,
    required String description,
    required String paidByUserId,
    required List<String> splitBetweenUserIds,
    required ExpenseSplitType splitType,
    required DateTime date,
    String? receiptUrl,
    String? location,
    Map<String, double>? customSplitAmounts,
    List<String>? tags,
  }) async {
    await Future.delayed(Duration(milliseconds: 800)); // Simulate network delay
    
    final expense = Expense(
      id: _uuid.v4(),
      tripId: tripId,
      categoryId: categoryId,
      amount: amount,
      currency: currency,
      description: description,
      paidByUserId: paidByUserId,
      splitBetweenUserIds: splitBetweenUserIds,
      splitType: splitType,
      date: date,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      receiptUrl: receiptUrl,
      location: location,
      customSplitAmounts: customSplitAmounts,
      tags: tags,
    );
    
    _expenses.add(expense);
    
    // Update budget spent amount
    final budgetIndex = _budgets.indexWhere((b) => b.tripId == tripId);
    if (budgetIndex >= 0) {
      final budget = _budgets[budgetIndex];
      final updatedBudget = budget.copyWith(
        spentAmount: budget.spentAmount + amount,
        updatedAt: DateTime.now(),
      );
      _budgets[budgetIndex] = updatedBudget;
    }
  }

  Future<void> updateExpense({
    required String expenseId,
    required String categoryId,
    required double amount,
    required String description,
    required List<String> splitBetweenUserIds,
    required ExpenseSplitType splitType,
    Map<String, double>? customSplitAmounts,
    List<String>? tags,
  }) async {
    await Future.delayed(Duration(milliseconds: 600)); // Simulate network delay
    
    final expenseIndex = _expenses.indexWhere((e) => e.id == expenseId);
    if (expenseIndex >= 0) {
      final oldExpense = _expenses[expenseIndex];
      final updatedExpense = oldExpense.copyWith(
        categoryId: categoryId,
        amount: amount,
        description: description,
        splitBetweenUserIds: splitBetweenUserIds,
        splitType: splitType,
        customSplitAmounts: customSplitAmounts,
        tags: tags,
        updatedAt: DateTime.now(),
      );
      _expenses[expenseIndex] = updatedExpense;
      
      // Update budget if amount changed
      if (amount != oldExpense.amount) {
        final budgetIndex = _budgets.indexWhere((b) => b.tripId == oldExpense.tripId);
        if (budgetIndex >= 0) {
          final budget = _budgets[budgetIndex];
          final updatedBudget = budget.copyWith(
            spentAmount: budget.spentAmount - oldExpense.amount + amount,
            updatedAt: DateTime.now(),
          );
          _budgets[budgetIndex] = updatedBudget;
        }
      }
    }
  }

  Future<void> deleteExpense(String expenseId) async {
    await Future.delayed(Duration(milliseconds: 500)); // Simulate network delay
    
    final expenseIndex = _expenses.indexWhere((e) => e.id == expenseId);
    if (expenseIndex >= 0) {
      final expense = _expenses[expenseIndex];
      _expenses.removeAt(expenseIndex);
      
      // Update budget
      final budgetIndex = _budgets.indexWhere((b) => b.tripId == expense.tripId);
      if (budgetIndex >= 0) {
        final budget = _budgets[budgetIndex];
        final updatedBudget = budget.copyWith(
          spentAmount: budget.spentAmount - expense.amount,
          updatedAt: DateTime.now(),
        );
        _budgets[budgetIndex] = updatedBudget;
      }
    }
  }

  Future<void> settleExpense(String expenseId) async {
    await Future.delayed(Duration(milliseconds: 400)); // Simulate network delay
    
    final expenseIndex = _expenses.indexWhere((e) => e.id == expenseId);
    if (expenseIndex >= 0) {
      final expense = _expenses[expenseIndex];
      final updatedExpense = expense.copyWith(
        status: ExpenseStatus.settled,
        updatedAt: DateTime.now(),
      );
      _expenses[expenseIndex] = updatedExpense;
    }
  }

  Future<void> updateBudget({
    required String tripId,
    required double totalBudget,
    required List<BudgetCategory> categories,
    String? description,
  }) async {
    await Future.delayed(Duration(milliseconds: 700)); // Simulate network delay
    
    final budgetIndex = _budgets.indexWhere((b) => b.tripId == tripId);
    if (budgetIndex >= 0) {
      final budget = _budgets[budgetIndex];
      final updatedBudget = budget.copyWith(
        totalBudget: totalBudget,
        categories: categories,
        description: description,
        updatedAt: DateTime.now(),
      );
      _budgets[budgetIndex] = updatedBudget;
    }
  }

  // Entertainment and Games Methods
  Future<List<EntertainmentActivity>> getEntertainmentActivities(String tripId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _entertainmentActivities.where((activity) => activity.tripId == tripId).toList();
  }

  Future<List<GameSession>> getGameSessions(String tripId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _gameSessions.where((session) {
      final activity = _entertainmentActivities.firstWhere(
        (activity) => activity.id == session.activityId,
        orElse: () => throw Exception('Activity not found'),
      );
      return activity.tripId == tripId;
    }).toList();
  }

  Future<EntertainmentReport?> getEntertainmentReport(String tripId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    print('MockServer: Getting entertainment report for trip $tripId');
    
    final activities = await getEntertainmentActivities(tripId);
    final games = await getGameSessions(tripId);
    
    print('MockServer: Found ${activities.length} activities and ${games.length} games for trip $tripId');
    
    // Always return a report, even if no activities exist
    final completedActivities = activities.where((a) => a.status == ActivityStatus.completed).length;
    final totalParticipants = activities.fold<int>(0, (sum, activity) => sum + activity.participantIds.length);
    final averageParticipation = activities.isNotEmpty ? totalParticipants / activities.length : 0.0;

    final popularTypes = activities
        .map((a) => a.type)
        .fold<Map<ActivityType, int>>({}, (map, type) {
          map[type] = (map[type] ?? 0) + 1;
          return map;
        })
        .entries
        .toList()
        ..sort((a, b) => b.value.compareTo(a.value));
    
    final top3PopularTypes = popularTypes.take(3).map((e) => e.key).toList();

    final topParticipants = activities
        .expand((a) => a.participantIds)
        .fold<Map<String, int>>({}, (map, id) {
          map[id] = (map[id] ?? 0) + 1;
          return map;
        })
        .entries
        .toList()
        ..sort((a, b) => b.value.compareTo(a.value));
    
    final top5Participants = topParticipants.take(5).map((e) => e.key).toList();

    final categoryStats = activities
        .map((a) => a.type.name)
        .fold<Map<String, int>>({}, (map, type) {
          map[type] = (map[type] ?? 0) + 1;
          return map;
        });

    final report = EntertainmentReport(
      tripId: tripId,
      totalActivities: activities.length,
      completedActivities: completedActivities,
      totalParticipants: totalParticipants,
      averageParticipation: averageParticipation,
      popularTypes: top3PopularTypes,
      topParticipants: top5Participants,
      recentGames: games.take(5).toList(),
      categoryStats: categoryStats,
      generatedAt: DateTime.now(),
    );
    
    print('MockServer: Generated entertainment report with ${report.totalActivities} activities');
    
    return report;
  }

  Future<void> createEntertainmentActivity({
    required String tripId,
    required String title,
    required String description,
    required ActivityType type,
    required DateTime scheduledAt,
    required int durationMinutes,
    required List<String> participantIds,
    required String organizerId,
    String? location,
    int? maxParticipants,
    double? cost,
    String? imageUrl,
    Map<String, dynamic>? gameRules,
    List<String>? tags,
    String? notes,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    final activity = EntertainmentActivity(
      id: 'ent_${DateTime.now().millisecondsSinceEpoch}',
      tripId: tripId,
      title: title,
      description: description,
      type: type,
      status: ActivityStatus.planned,
      scheduledAt: scheduledAt,
      durationMinutes: durationMinutes,
      participantIds: participantIds,
      organizerId: organizerId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      location: location,
      maxParticipants: maxParticipants,
      cost: cost,
      imageUrl: imageUrl,
      gameRules: gameRules,
      tags: tags,
      notes: notes,
    );

    _entertainmentActivities.add(activity);
  }

  Future<void> updateEntertainmentActivity({
    required String activityId,
    required String title,
    required String description,
    required ActivityType type,
    required DateTime scheduledAt,
    required int durationMinutes,
    required List<String> participantIds,
    String? location,
    int? maxParticipants,
    double? cost,
    String? imageUrl,
    Map<String, dynamic>? gameRules,
    List<String>? tags,
    String? notes,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    final index = _entertainmentActivities.indexWhere((activity) => activity.id == activityId);
    if (index == -1) throw Exception('Activity not found');

    final activity = _entertainmentActivities[index];
    _entertainmentActivities[index] = activity.copyWith(
      title: title,
      description: description,
      type: type,
      scheduledAt: scheduledAt,
      durationMinutes: durationMinutes,
      participantIds: participantIds,
      updatedAt: DateTime.now(),
      location: location,
      maxParticipants: maxParticipants,
      cost: cost,
      imageUrl: imageUrl,
      gameRules: gameRules,
      tags: tags,
      notes: notes,
    );
  }

  Future<void> deleteEntertainmentActivity(String activityId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _entertainmentActivities.removeWhere((activity) => activity.id == activityId);
  }

  Future<void> joinEntertainmentActivity(String activityId, String userId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    final index = _entertainmentActivities.indexWhere((activity) => activity.id == activityId);
    if (index == -1) throw Exception('Activity not found');

    final activity = _entertainmentActivities[index];
    if (!activity.participantIds.contains(userId)) {
      _entertainmentActivities[index] = activity.copyWith(
        participantIds: [...activity.participantIds, userId],
        updatedAt: DateTime.now(),
      );
    }
  }

  Future<void> leaveEntertainmentActivity(String activityId, String userId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    final index = _entertainmentActivities.indexWhere((activity) => activity.id == activityId);
    if (index == -1) throw Exception('Activity not found');

    final activity = _entertainmentActivities[index];
    _entertainmentActivities[index] = activity.copyWith(
      participantIds: activity.participantIds.where((id) => id != userId).toList(),
      updatedAt: DateTime.now(),
    );
  }

  Future<void> startGameSession({
    required String activityId,
    required String gameType,
    required List<String> playerIds,
    required Map<String, dynamic> gameData,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    final session = GameSession(
      id: 'game_${DateTime.now().millisecondsSinceEpoch}',
      activityId: activityId,
      gameType: gameType,
      status: GameStatus.active,
      startedAt: DateTime.now(),
      playerIds: playerIds,
      scores: Map.fromEntries(playerIds.map((id) => MapEntry(id, 0))),
      gameData: gameData,
    );

    _gameSessions.add(session);
  }

  Future<void> updateGameScore({
    required String sessionId,
    required String playerId,
    required int score,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    final index = _gameSessions.indexWhere((session) => session.id == sessionId);
    if (index == -1) throw Exception('Game session not found');

    final session = _gameSessions[index];
    final newScores = Map<String, int>.from(session.scores);
    newScores[playerId] = score;

    _gameSessions[index] = session.copyWith(scores: newScores);
  }

  Future<void> endGameSession({
    required String sessionId,
    String? winnerId,
    List<String>? winners,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    final index = _gameSessions.indexWhere((session) => session.id == sessionId);
    if (index == -1) throw Exception('Game session not found');

    final session = _gameSessions[index];
    _gameSessions[index] = session.copyWith(
      status: GameStatus.completed,
      endedAt: DateTime.now(),
      winnerId: winnerId,
      winners: winners,
    );
  }
}


