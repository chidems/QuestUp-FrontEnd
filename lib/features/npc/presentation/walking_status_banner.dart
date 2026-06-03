import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/walking_session_provider.dart';

/// Banner on the quest feed for starting/stopping walking mode (the trigger for
/// random NPC encounters). Stops tracking when the app is backgrounded.
class WalkingStatusBanner extends ConsumerStatefulWidget {
  const WalkingStatusBanner({super.key});

  @override
  ConsumerState<WalkingStatusBanner> createState() =>
      _WalkingStatusBannerState();
}

class _WalkingStatusBannerState extends ConsumerState<WalkingStatusBanner>
    with WidgetsBindingObserver {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Rebuild every second to keep the elapsed time fresh while active.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      // MVP: no background tracking — stop when leaving the foreground.
      ref.read(walkingSessionProvider.notifier).stop();
    }
  }

  String _elapsed(DateTime since) {
    final d = DateTime.now().difference(since);
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(walkingSessionProvider);
    final notifier = ref.read(walkingSessionProvider.notifier);

    if (!session.isActive) {
      return _Card(
        color: AppColors.surfaceVariant,
        child: Row(
          children: [
            const Icon(Icons.directions_walk, color: AppColors.primaryLight),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Start Walking Mode to meet NPCs and earn bonus quests.',
              ),
            ),
            TextButton(
              onPressed: notifier.start,
              child: const Text('Start'),
            ),
          ],
        ),
      );
    }

    final since = session.walkingSince;
    return _Card(
      color: AppColors.surface,
      child: Row(
        children: [
          Icon(
            session.isWalking
                ? Icons.directions_walk
                : Icons.accessibility_new,
            color: session.isWalking ? AppColors.xpColor : AppColors.textMuted,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Walking Mode active',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  session.isWalking && since != null
                      ? 'Walking · ${_elapsed(since)}'
                      : 'Stand still detected — keep moving',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: notifier.stop,
            child: const Text('Stop'),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Color color;
  final Widget child;

  const _Card({required this.color, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: AppColors.primaryLight),
      ),
      child: child,
    );
  }
}
