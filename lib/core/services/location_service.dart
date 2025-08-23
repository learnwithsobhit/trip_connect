import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../data/models/models.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  StreamSubscription<Position>? _positionSubscription;
  final StreamController<UserLocation> _locationController = StreamController<UserLocation>.broadcast();
  final StreamController<GeofenceEvent> _geofenceController = StreamController<GeofenceEvent>.broadcast();

  Position? _lastKnownPosition;
  final List<Geofence> _activeGeofences = [];
  bool _isTracking = false;

  Stream<UserLocation> get locationStream => _locationController.stream;
  Stream<GeofenceEvent> get geofenceStream => _geofenceController.stream;

  Future<bool> initialize() async {
    final permission = await _requestLocationPermission();
    if (!permission) return false;

    final serviceEnabled = await _checkLocationService();
    return serviceEnabled;
  }

  Future<bool> _requestLocationPermission() async {
    final status = await Permission.locationWhenInUse.request();
    
    if (status.isDenied) {
      return false;
    }
    
    if (status.isPermanentlyDenied) {
      // Guide user to settings
      await openAppSettings();
      return false;
    }

    // Request background location for continuous tracking
    if (status.isGranted) {
      await Permission.locationAlways.request();
    }

    return status.isGranted;
  }

  Future<bool> _checkLocationService() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    
    if (!serviceEnabled) {
      // Location services are not enabled, request user to enable them
      return false;
    }
    
    return true;
  }

  Future<UserLocation?> getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      _lastKnownPosition = position;

      return UserLocation(
        lat: position.latitude,
        lng: position.longitude,
        lastSeen: DateTime.now(),
        accuracy: position.accuracy,
        bearing: position.heading >= 0 ? position.heading : null,
        speed: position.speed >= 0 ? position.speed : null,
      );
    } catch (e) {
      print('Error getting current location: $e');
      return null;
    }
  }

  void startLocationTracking({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilter = 10, // meters
    Duration interval = const Duration(seconds: 30),
  }) {
    if (_isTracking) return;

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position position) {
        _lastKnownPosition = position;
        
        final userLocation = UserLocation(
          lat: position.latitude,
          lng: position.longitude,
          lastSeen: DateTime.now(),
          accuracy: position.accuracy,
          bearing: position.heading >= 0 ? position.heading : null,
          speed: position.speed >= 0 ? position.speed : null,
        );

        _locationController.add(userLocation);
        _checkGeofences(userLocation);
      },
      onError: (error) {
        print('Location tracking error: $error');
      },
    );

    _isTracking = true;
  }

  void stopLocationTracking() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _isTracking = false;
  }

  void addGeofence(Geofence geofence) {
    _activeGeofences.add(geofence);
  }

  void removeGeofence(String id) {
    _activeGeofences.removeWhere((g) => g.id == id);
  }

  void clearGeofences() {
    _activeGeofences.clear();
  }

  void _checkGeofences(UserLocation location) {
    for (final geofence in _activeGeofences) {
      final distance = _calculateDistance(
        location.lat,
        location.lng,
        geofence.lat,
        geofence.lng,
      );

      final isInside = distance <= geofence.radiusMeters;
      final wasInside = geofence.isUserInside;

      if (isInside && !wasInside) {
        // User entered geofence
        geofence.isUserInside = true;
        _geofenceController.add(GeofenceEvent(
          geofenceId: geofence.id,
          type: GeofenceEventType.enter,
          location: location,
          distance: distance,
        ));
      } else if (!isInside && wasInside) {
        // User exited geofence
        geofence.isUserInside = false;
        _geofenceController.add(GeofenceEvent(
          geofenceId: geofence.id,
          type: GeofenceEventType.exit,
          location: location,
          distance: distance,
        ));
      }
    }
  }

  double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    return Geolocator.distanceBetween(lat1, lng1, lat2, lng2);
  }

  double calculateDistanceToStop(Stop stop) {
    if (_lastKnownPosition == null) return 0;
    
    return _calculateDistance(
      _lastKnownPosition!.latitude,
      _lastKnownPosition!.longitude,
      stop.lat,
      stop.lng,
    );
  }

  bool isWithinGeofence(double lat, double lng, double radiusMeters) {
    if (_lastKnownPosition == null) return false;
    
    final distance = _calculateDistance(
      _lastKnownPosition!.latitude,
      _lastKnownPosition!.longitude,
      lat,
      lng,
    );
    
    return distance <= radiusMeters;
  }

  UserLocation? get lastKnownLocation {
    if (_lastKnownPosition == null) return null;
    
    return UserLocation(
      lat: _lastKnownPosition!.latitude,
      lng: _lastKnownPosition!.longitude,
      lastSeen: DateTime.now(),
      accuracy: _lastKnownPosition!.accuracy,
      bearing: _lastKnownPosition!.heading >= 0 ? _lastKnownPosition!.heading : null,
      speed: _lastKnownPosition!.speed >= 0 ? _lastKnownPosition!.speed : null,
    );
  }

  bool get isTracking => _isTracking;

  // Helper methods for trip-specific functionality
  void setupTripGeofences(Trip trip) {
    clearGeofences();
    
    // Add geofences for all stops in the trip
    for (final scheduleItem in trip.schedule) {
      for (final stop in scheduleItem.stops) {
        addGeofence(Geofence(
          id: 'stop_${stop.id}',
          lat: stop.lat,
          lng: stop.lng,
          radiusMeters: 100, // 100 meter radius for stops
          name: stop.name,
          type: GeofenceType.stop,
        ));
      }
    }
    
    // Add geofence for destination
    addGeofence(Geofence(
      id: 'destination_${trip.id}',
      lat: trip.destination.lat,
      lng: trip.destination.lng,
      radiusMeters: 200, // 200 meter radius for destination
      name: trip.destination.name,
      type: GeofenceType.destination,
    ));
  }

  void dispose() {
    stopLocationTracking();
    _locationController.close();
    _geofenceController.close();
  }
}

// Supporting classes
class Geofence {
  final String id;
  final double lat;
  final double lng;
  final double radiusMeters;
  final String name;
  final GeofenceType type;
  bool isUserInside;

  Geofence({
    required this.id,
    required this.lat,
    required this.lng,
    required this.radiusMeters,
    required this.name,
    required this.type,
    this.isUserInside = false,
  });
}

class GeofenceEvent {
  final String geofenceId;
  final GeofenceEventType type;
  final UserLocation location;
  final double distance;

  GeofenceEvent({
    required this.geofenceId,
    required this.type,
    required this.location,
    required this.distance,
  });
}

enum GeofenceType {
  stop,
  destination,
  waypoint,
  emergency,
}

enum GeofenceEventType {
  enter,
  exit,
}
