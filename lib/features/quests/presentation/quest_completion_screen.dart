import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/routing/route_names.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/pixel_button.dart';
import '../../../shared/widgets/reward_summary_modal.dart';
import '../models/quest_models.dart';
import '../providers/quest_detail_provider.dart';
import '../providers/quest_completion_provider.dart';
import '../../weekly/providers/weekly_provider.dart';

class QuestCompletionScreen extends ConsumerStatefulWidget {
  final String questId;

  const QuestCompletionScreen({super.key, required this.questId});

  @override
  ConsumerState<QuestCompletionScreen> createState() =>
      _QuestCompletionScreenState();
}

class _QuestCompletionScreenState
    extends ConsumerState<QuestCompletionScreen> {
  XFile? _photo;

  Future<void> _pick(ImageSource source) async {
    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 70,
    );
    if (picked != null) setState(() => _photo = picked);
  }

  void _submit() {
    ref
        .read(questCompletionProvider(widget.questId).notifier)
        .submit(photo: _photo);
  }

  // Weekly quests can optionally share their completion photo to the community.
  Future<void> _maybeShareWeekly(Quest quest) async {
    final photoUrl = ref
        .read(questCompletionProvider(widget.questId).notifier)
        .uploadedPhotoUrl;
    if (photoUrl == null) return;
    if (!mounted) return;

    final share = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.colors.surface,
        title: const Text('Share your photo?'),
        content: const Text(
          'Share this photo to the weekly community page?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Not now'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Share'),
          ),
        ],
      ),
    );
    if (share != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(weeklyProvider.notifier).sharePhoto(
            photoUrl: photoUrl,
            questTitle: quest.title,
          );
      messenger.showSnackBar(
        const SnackBar(content: Text('Shared to the community!')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not share: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final quest = ref.watch(questDetailProvider(widget.questId));
    final completion = ref.watch(questCompletionProvider(widget.questId));

    ref.listen(questCompletionProvider(widget.questId), (_, next) {
      next.whenOrNull(
        data: (result) async {
          if (result == null) return;
          await showRewardSummary(context, result);
          if (!context.mounted) return;
          final quest = ref.read(questDetailProvider(widget.questId)).valueOrNull;
          if (quest != null && quest.isWeekly) {
            await _maybeShareWeekly(quest);
            if (!context.mounted) return;
          }
          context.go(RouteNames.home);
        },
        error: (error, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error.toString())),
          );
        },
      );
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Complete Quest')),
      body: quest.when(
        loading: () => const LoadingView(),
        error: (_, __) => ErrorView(
          message: 'Could not load this quest.',
          onRetry: () => ref.invalidate(questDetailProvider(widget.questId)),
        ),
        data: (q) => _Body(
          quest: q,
          photo: _photo,
          isSubmitting: completion.isLoading,
          onPickCamera: () => _pick(ImageSource.camera),
          onPickGallery: () => _pick(ImageSource.gallery),
          onSubmit: _submit,
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final Quest quest;
  final XFile? photo;
  final bool isSubmitting;
  final VoidCallback onPickCamera;
  final VoidCallback onPickGallery;
  final VoidCallback onSubmit;

  const _Body({
    required this.quest,
    required this.photo,
    required this.isSubmitting,
    required this.onPickCamera,
    required this.onPickGallery,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final photoMissing = quest.requiresPhoto && photo == null;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                quest.title,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              if (quest.requiresPhoto) ...[
                Text(
                  'Add a photo',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _PhotoArea(photo: photo),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: isSubmitting ? null : onPickCamera,
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Camera'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: isSubmitting ? null : onPickGallery,
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Gallery'),
                      ),
                    ),
                  ],
                ),
              ] else
                Text(
                  'Ready to mark this quest as complete?',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (photoMissing)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'A photo is required to complete this quest.',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: context.colors.textMuted),
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  child: PixelButton(
                    label: 'Submit',
                    isLoading: isSubmitting,
                    onPressed: photoMissing ? null : onSubmit,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PhotoArea extends StatelessWidget {
  final XFile? photo;
  const _PhotoArea({required this.photo});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          color: context.colors.surface,
          border: Border.all(color: context.colors.primaryLight),
        ),
        clipBehavior: Clip.hardEdge,
        child: photo == null
            ? Center(
                child: Icon(
                  Icons.add_a_photo,
                  size: 40,
                  color: context.colors.textMuted,
                ),
              )
            : Image.file(File(photo!.path), fit: BoxFit.cover),
      ),
    );
  }
}
