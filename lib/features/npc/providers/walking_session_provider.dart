import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/config/app_config.dart';
import 'npc_encounter_provider.dart';

// Fallback coordinates used in mock mode (no real GPS).
const double _mockLat = 49.2827;
const double _mockLng = -123.1207;

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
    _mockTimer = Timer(
      Duration(seconds: _thresholdSeconds),
      () => _check(_mockLat, _mockLng),
    );
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

    final seconds = DateTime.now().difference(since).inSeconds;
    ref.read(npcEncounterProvider.notifier).sessionTick(
          latitude: lat,
          longitude: lng,
          walkingSeconds: seconds,
        );

    if (seconds >= _thresholdSeconds) _check(lat, lng);
  }

  Future<void> _check(double lat, double lng) async {
    // Restart the continuous-walking window so we don't fire repeatedly.
    if (state.isActive) {
      state = WalkingSessionState(
        isActive: true,
        isWalking: state.isWalking,
        walkingSince: DateTime.now(),
      );
    }
    await ref
        .read(npcEncounterProvider.notifier)
        .checkEncounter(latitude: lat, longitude: lng);
  }
}

final walkingSessionProvider =
    NotifierProvider<WalkingSessionNotifier, WalkingSessionState>(
  WalkingSessionNotifier.new,
);
