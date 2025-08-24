import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../data/models/models.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  StreamSubscription<Position>? _locationSubscription;
  final Map<String, Timer> _geofenceTimers = {};
  final Map<String, StreamController<GeofenceEvent>> _geofenceControllers = {};
  
  // Callbacks for different events
  Function(GeofenceEvent)? onGeofenceEntered;
  Function(GeofenceEvent)? onGeofenceExited;
  Function(GeofenceEvent)? onGeofenceWithin;
  Function(Location)? onLocationUpdated;

  /// Initialize location service and request permissions
  Future<bool> initialize() async {
    try {
      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return false;
      }

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return false;
      }

      return true;
    } catch (e) {
      print('Error initializing location service: $e');
      return false;
    }
  }

  /// Start location tracking
  Future<void> startLocationTracking({
    Duration interval = const Duration(seconds: 10),
    int distanceFilter = 10, // meters
  }) async {
    if (!await initialize()) {
      throw Exception('Location service not available');
    }

    // Stop existing subscription if any
    await stopLocationTracking();

    _locationSubscription = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.low,
        distanceFilter: distanceFilter,
        timeLimit: Duration(seconds: 10),
      ),
    ).listen(
      (Position position) {
        final location = Location(
          name: 'Current Location',
          lat: position.latitude,
          lng: position.longitude,
          address: 'Current Location',
        );

        onLocationUpdated?.call(location);
        _checkGeofences(location);
      },
      onError: (error) {
        print('Location tracking error: $error');
      },
    );
  }

  /// Stop location tracking
  Future<void> stopLocationTracking() async {
    await _locationSubscription?.cancel();
    _locationSubscription = null;
  }

    /// Get current location
  Future<Location?> getCurrentLocation() async {
    try {
      if (!await initialize()) {
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low, // Reduced for faster response
        timeLimit: const Duration(seconds: 3), // Reduced timeout
      ).timeout(
        const Duration(seconds: 5), // Additional timeout wrapper
        onTimeout: () {
          throw TimeoutException('Location request timed out', const Duration(seconds: 5));
        },
      );

      return Location(
        name: 'Current Location',
        lat: position.latitude,
        lng: position.longitude,
        address: 'Current Location',
      );
    } catch (e) {
      print('Error getting current location: $e');
      return null;
    }
  }

  /// Add a geofence for a meeting point
  void addGeofence(MeetingPoint meetingPoint) {
    final meetingPointId = meetingPoint.id;
    
    // Cancel existing timer for this meeting point
    _geofenceTimers[meetingPointId]?.cancel();
    
    // Create stream controller for this geofence
    _geofenceControllers[meetingPointId] = StreamController<GeofenceEvent>.broadcast();

    // Start periodic geofence checking
    _geofenceTimers[meetingPointId] = Timer.periodic(
      const Duration(seconds: 5),
      (_) async {
        final currentLocation = await getCurrentLocation();
        if (currentLocation != null) {
          _checkGeofence(meetingPoint, currentLocation);
        }
      },
    );
  }

  /// Remove a geofence
  void removeGeofence(String meetingPointId) {
    _geofenceTimers[meetingPointId]?.cancel();
    _geofenceTimers.remove(meetingPointId);
    
    _geofenceControllers[meetingPointId]?.close();
    _geofenceControllers.remove(meetingPointId);
  }

  /// Check if location is within geofence radius
  bool isWithinGeofence(Location location, MeetingPoint meetingPoint) {
    final distance = _calculateDistance(
      location.lat,
      location.lng,
      meetingPoint.location.lat,
      meetingPoint.location.lng,
    );
    
    return distance <= meetingPoint.checkInRadius;
  }

  /// Calculate distance between two points in meters
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  /// Check all active geofences
  void _checkGeofences(Location currentLocation) {
    // This would be called from the location stream
    // Implementation would check all active geofences
  }

  /// Check specific geofence
  void _checkGeofence(MeetingPoint meetingPoint, Location currentLocation) {
    final distance = _calculateDistance(
      currentLocation.lat,
      currentLocation.lng,
      meetingPoint.location.lat,
      meetingPoint.location.lng,
    );

    final isWithin = distance <= meetingPoint.checkInRadius;
    final meetingPointId = meetingPoint.id;

    // Create geofence event
    final event = GeofenceEvent(
      id: 'geofence_${DateTime.now().millisecondsSinceEpoch}',
      userId: 'current_user', // This should be the actual user ID
      meetingPointId: meetingPointId,
      type: isWithin ? const GeofenceEventType.within() : const GeofenceEventType.exited(),
      timestamp: DateTime.now(),
      location: currentLocation,
      distanceFromPoint: distance,
      isWithinRadius: isWithin,
    );

    // Emit event
    _geofenceControllers[meetingPointId]?.add(event);

    // Trigger callbacks
    if (isWithin) {
      onGeofenceWithin?.call(event);
    } else {
      onGeofenceExited?.call(event);
    }
  }

  /// Get stream for geofence events
  Stream<GeofenceEvent>? getGeofenceStream(String meetingPointId) {
    return _geofenceControllers[meetingPointId]?.stream;
  }

  /// Calculate distance between two locations
  double calculateDistance(Location location1, Location location2) {
    return _calculateDistance(
      location1.lat,
      location1.lng,
      location2.lat,
      location2.lng,
    );
  }

  /// Get location stream for real-time position updates
  Stream<Position> getLocationStream({
    Duration interval = const Duration(seconds: 10),
    int distanceFilter = 10,
  }) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.low,
        distanceFilter: distanceFilter,
        timeLimit: Duration(seconds: 10),
      ),
    );
  }

  /// Get current position (raw Position object)
  Future<Position?> getCurrentPosition() async {
    try {
      if (!await initialize()) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium, // Reduced for faster response
        timeLimit: const Duration(seconds: 5), // Reduced timeout
      ).timeout(
        const Duration(seconds: 8), // Additional timeout wrapper
        onTimeout: () {
          throw TimeoutException('Location request timed out', const Duration(seconds: 8));
        },
      );
    } catch (e) {
      print('Error getting current position: $e');
      return null;
    }
  }

  /// Check if user should be auto-checked in based on location
  bool shouldAutoCheckIn(Location userLocation, MeetingPoint meetingPoint) {
    if (!meetingPoint.enableAutoCheckIn) {
      return false;
    }

    final distance = calculateDistance(userLocation, meetingPoint.location);
    return distance <= meetingPoint.checkInRadius;
  }

  /// Dispose all resources
  void dispose() {
    stopLocationTracking();
    
    for (final timer in _geofenceTimers.values) {
      timer.cancel();
    }
    _geofenceTimers.clear();

    for (final controller in _geofenceControllers.values) {
      controller.close();
    }
    _geofenceControllers.clear();
  }
}
