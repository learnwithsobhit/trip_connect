// Mock data models for roll-call
class CheckPoint {
  final String id;
  final String name;
  final String description;
  final double latitude;
  final double longitude;
  final double radiusMeters;
  final DateTime? arrivalTime;
  final DateTime? departureTime;
  final bool isOptional;
  
  CheckPoint({
    required this.id,
    required this.name,
    required this.description,
    required this.latitude,
    required this.longitude,
    this.radiusMeters = 100.0,
    this.arrivalTime,
    this.departureTime,
    this.isOptional = false,
  });
}

class MemberCheckIn {
  final String memberId;
  final String memberName;
  final String checkPointId;
  final DateTime timestamp;
  final bool isAutomatic;
  final String? manualNote;
  final double? accuracy;
  
  MemberCheckIn({
    required this.memberId,
    required this.memberName,
    required this.checkPointId,
    required this.timestamp,
    this.isAutomatic = true,
    this.manualNote,
    this.accuracy,
  });
}

