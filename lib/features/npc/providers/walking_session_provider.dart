import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/config/app_config.dart';
import 'npc_encounter_provider.dart';

class WalkingSessionState {
  final bool isActive;
  final bool isWalking;
  final DateTime? walkingSince;

  const WalkingSessionState({
    this.isActive = false,
    this.isWalking = false,
    this.walkingSince,
  });
}

/// Tracks "walking mode": listens to location while active, detects walking by
/// speed, and after [_thresholdSeconds] of continuous walking asks the backend
/// for an NPC encounter. The backend decides the chance — not the frontend.
class WalkingSessionNotifier extends Notifier<WalkingSessionState> {
  StreamSubscription<Position>? _sub;
  Timer? _mockTimer;

  /// Backend walking-session id, created lazily on the first real movement.
  String? _sessionId;

  // Shortened in mock mode so the flow is demoable without a real 3-min walk.
  int get _thresholdSeconds => AppConfig.useMockApi ? 10 : 180;

  @override
  WalkingSessionState build() {
    ref.onDispose(_cleanup);
    return const WalkingSessionState();
  }

  void start() {
    if (state.isActive) return;
    state = const WalkingSessionState(isActive: true);
    if (AppConfig.useMockApi) {
      _startMock();
    } else {
      _startReal();
    }
  }

  void stop() {
    _cleanup();
    state = const WalkingSessionState();
  }

  void _cleanup() {
    _sub?.cancel();
    _sub = null;
    _mockTimer?.cancel();
    _mockTimer = null;
    final id = _sessionId;
    _sessionId = null;
    if (id != null) {
      // Fire-and-forget; the session is over regardless of the result.
      try {
        ref.read(npcApiProvider).endWalkingSession(id).catchError((_) {});
      } catch (_) {
        // Container may already be disposed; nothing to do.
      }
    }
  }

  void _startReal() {
    _sub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        distanceFilter: 10,
      ),
    ).listen(
      (pos) => _onMovement(pos.speed, pos.latitude, pos.longitude),
      onError: (_) => stop(),
    );
  }

  void _startMock() {
    final since = DateTime.now();
    state = WalkingSessionState(
      isActive: true,
      isWalking: true,
      walkingSince: since,
    );
    _mockTimer = Timer(Duration(seconds: _thresholdSeconds), _check);
  }

  void _onMovement(double speed, double lat, double lng) {
    if (!state.isActive) return;

    final walking = speed >= 0.5 && speed <= 2.5;
    if (!walking) {
      state = const WalkingSessionState(isActive: true, isWalking: false);
      return;
    }

    final since = state.walkingSince ?? DateTime.now();
    state = WalkingSessionState(
      isActive: true,
      isWalking: true,
      walkingSince: since,
    );

    _reportPosition(lat, lng, speed);

    final seconds = DateTime.now().difference(since).inSeconds;
    if (seconds >= _thresholdSeconds) _check();
  }

  /// Lazily starts the backend walking session on the first movement, then
  /// streams location updates to it. Best-effort.
  Future<void> _reportPosition(double lat, double lng, double speed) async {
    final api = ref.read(npcApiProvider);
    try {
      if (_sessionId == null) {
        _sessionId =
            await api.startWalkingSession(latitude: lat, longitude: lng);
        return;
      }
      await api.updateWalkingSession(
        sessionId: _sessionId!,
        latitude: lat,
        longitude: lng,
        speedMps: speed,
      );
    } catch (_) {
      // Best-effort tracking; ignore failures.
    }
  }

  Future<void> _check() async {
    // Restart the continuous-walking window so we don't fire repeatedly.
    if (state.isActive) {
      state = WalkingSessionState(
        isActive: true,
        isWalking: state.isWalking,
        walkingSince: DateTime.now(),
      );
    }
    await ref.read(npcEncounterProvider.notifier).checkSpawn();
  }
}

final walkingSessionProvider =
    NotifierProvider<WalkingSessionNotifier, WalkingSessionState>(
  WalkingSessionNotifier.new,
);
