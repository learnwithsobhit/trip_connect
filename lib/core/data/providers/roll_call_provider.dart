import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import '../../services/roll_call_service.dart';

// Roll call service provider
final rollCallServiceProvider = Provider<RollCallService>((ref) {
  return RollCallService();
});

// Active roll calls provider
final activeRollCallsProvider = Provider<Map<String, RollCall>>((ref) {
  final service = ref.watch(rollCallServiceProvider);
  return service.activeRollCalls;
});

// Roll call settings provider
final rollCallSettingsProvider = StateProvider<RollCallSettings>((ref) {
  final service = ref.watch(rollCallServiceProvider);
  return service.settings;
});

// Specific roll call provider
final rollCallProvider = StreamProvider.family<RollCall?, String>((ref, rollCallId) {
  final service = ref.watch(rollCallServiceProvider);
  return service.getRollCallStream(rollCallId);
});

// Roll call check-ins stream provider
final rollCallCheckInsProvider = StreamProvider.family<List<RollCallCheckIn>, String>((ref, rollCallId) {
  final service = ref.watch(rollCallServiceProvider);
  return service.getCheckInStream(rollCallId).map((checkIn) => [checkIn]);
});

// Roll call notifier for actions
class RollCallNotifier extends StateNotifier<AsyncValue<RollCall?>> {
  final RollCallService _service;

  RollCallNotifier(this._service) : super(const AsyncValue.loading());

  Future<void> startRollCall({
    required String tripId,
    required String leaderId,
    RollCallLocation? anchorLocation,
    double? radiusMeters,
    int? gracePeriodMinutes,
    String? anchorName,
    bool? allowManualCheckIn,
    bool? announceOnClose,
  }) async {
    state = const AsyncValue.loading();
    
    try {
      final rollCall = await _service.startRollCall(
        tripId: tripId,
        leaderId: leaderId,
        anchorLocation: anchorLocation,
        radiusMeters: radiusMeters,
        gracePeriodMinutes: gracePeriodMinutes,
        anchorName: anchorName,
        allowManualCheckIn: allowManualCheckIn,
        announceOnClose: announceOnClose,
      );
      
      state = AsyncValue.data(rollCall);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> checkIn({
    required String rollCallId,
    required String userId,
    CheckInMethod method = CheckInMethod.gps,
    String? manualReason,
    String? markedByLeaderId,
  }) async {
    try {
      await _service.checkIn(
        rollCallId: rollCallId,
        userId: userId,
        method: method,
        manualReason: manualReason,
        markedByLeaderId: markedByLeaderId,
      );
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> markMember({
    required String rollCallId,
    required String userId,
    required RollCallCheckInStatus status,
    required String leaderId,
    String? reason,
  }) async {
    try {
      await _service.markMember(
        rollCallId: rollCallId,
        userId: userId,
        status: status,
        leaderId: leaderId,
        reason: reason,
      );
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> sendReminder({
    required String rollCallId,
    required String leaderId,
  }) async {
    try {
      await _service.sendReminder(
        rollCallId: rollCallId,
        leaderId: leaderId,
      );
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> extendGracePeriod({
    required String rollCallId,
    required String leaderId,
    required int additionalMinutes,
  }) async {
    try {
      final rollCall = await _service.extendGracePeriod(
        rollCallId: rollCallId,
        leaderId: leaderId,
        additionalMinutes: additionalMinutes,
      );
      state = AsyncValue.data(rollCall);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> closeRollCall({
    required String rollCallId,
    required String leaderId,
    String? closeMessage,
  }) async {
    try {
      final rollCall = await _service.closeRollCall(
        rollCallId: rollCallId,
        leaderId: leaderId,
        closeMessage: closeMessage,
      );
      state = AsyncValue.data(rollCall);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> cancelRollCall({
    required String rollCallId,
    required String leaderId,
    String? reason,
  }) async {
    try {
      final rollCall = await _service.cancelRollCall(
        rollCallId: rollCallId,
        leaderId: leaderId,
        reason: reason,
      );
      state = AsyncValue.data(rollCall);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  void updateSettings(RollCallSettings settings) {
    _service.updateSettings(settings);
  }

  RollCallReport? generateReport(String rollCallId) {
    try {
      return _service.generateReport(rollCallId);
    } catch (error) {
      return null;
    }
  }
}

final rollCallNotifierProvider = StateNotifierProvider<RollCallNotifier, AsyncValue<RollCall?>>((ref) {
  final service = ref.watch(rollCallServiceProvider);
  return RollCallNotifier(service);
});
