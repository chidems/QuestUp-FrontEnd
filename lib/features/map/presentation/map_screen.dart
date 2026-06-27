import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/theme/app_palette.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/pixel_box.dart';
import '../../../shared/widgets/pixel_button.dart';
import '../../settings/providers/settings_provider.dart';
import '../providers/map_providers.dart';

/// Nearby quests on a retro-styled Google Map. Centers on the user, draws the
/// preferred-radius circle, and drops a marker per quest that has coordinates.
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  GoogleMapController? _controller;
  String? _darkStyle;
  String? _lightStyle;

  @override
  void initState() {
    super.initState();
    _loadStyles();
  }

  Future<void> _loadStyles() async {
    final dark = await rootBundle.loadString('assets/map_style/map_style_dark.json');
    final light =
        await rootBundle.loadString('assets/map_style/map_style_light.json');
    if (!mounted) return;
    setState(() {
      _darkStyle = dark;
      _lightStyle = light;
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _recenter(LatLng center) async {
    await _controller?.animateCamera(
      CameraUpdate.newLatLngZoom(center, 15),
    );
  }

  @override
  Widget build(BuildContext context) {
    final centerAsync = ref.watch(mapCenterProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Map')),
      body: centerAsync.when(
        loading: () => const LoadingView(message: 'Finding your location...'),
        error: (_, __) => ErrorView(
          message: 'Could not get your location.',
          onRetry: () => ref.invalidate(mapCenterProvider),
        ),
        data: (center) => _MapView(
          center: center,
          darkStyle: _darkStyle,
          lightStyle: _lightStyle,
          onMapCreated: (c) => _controller = c,
          onRecenter: () => _recenter(center),
        ),
      ),
    );
  }
}

class _MapView extends ConsumerWidget {
  final LatLng center;
  final String? darkStyle;
  final String? lightStyle;
  final ValueChanged<GoogleMapController> onMapCreated;
  final VoidCallback onRecenter;

  const _MapView({
    required this.center,
    required this.darkStyle,
    required this.lightStyle,
    required this.onMapCreated,
    required this.onRecenter,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.colors;
    final settings = ref.watch(settingsProvider).value;
    // Dark is the default theme; mirror that fallback here.
    final darkMode = settings?.darkMode ?? true;
    final radiusKm = settings?.radiusKm ?? 2.0;
    final quests = ref.watch(mapQuestsProvider);

    final markers = {
      for (final q in quests)
        Marker(
          markerId: MarkerId(q.id),
          position: LatLng(q.targetLatitude!, q.targetLongitude!),
          infoWindow: InfoWindow(
            title: q.title,
            snippet: '${q.xpReward} XP · ${q.difficultyLabel}',
          ),
          // TODO(map): replace the placeholder hue with pixel-art marker
          // sprites (BitmapDescriptor.bytes from a rendered glyph) — tracked as
          // a separate follow-up.
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueOrange,
          ),
        ),
    };

    final circles = {
      Circle(
        circleId: const CircleId('preferred_radius'),
        center: center,
        radius: radiusKm * 1000,
        fillColor: palette.accent.withValues(alpha: 0.12),
        strokeColor: palette.accent,
        strokeWidth: 2,
      ),
    };

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(target: center, zoom: 15),
          style: darkMode ? darkStyle : lightStyle,
          onMapCreated: onMapCreated,
          markers: markers,
          circles: circles,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
        ),
        // Quest-count badge.
        Positioned(
          top: 12,
          left: 12,
          child: PixelBox(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
              quests.length == 1 ? '1 quest nearby' : '${quests.length} quests nearby',
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(color: palette.textPrimary),
            ),
          ),
        ),
        // Recenter control.
        Positioned(
          bottom: 16,
          right: 16,
          child: PixelButton(
            label: 'Recenter',
            icon: Icons.my_location,
            variant: PixelButtonVariant.navigation,
            onPressed: onRecenter,
          ),
        ),
      ],
    );
  }
}
