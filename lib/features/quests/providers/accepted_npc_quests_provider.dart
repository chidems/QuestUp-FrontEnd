import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/quest_models.dart';

/// Quests accepted from NPC encounters during this session. The mock backend
/// doesn't return them in the feed, so we hold them here and merge them into
/// the active quest list (and resolve them for the detail screen).
class AcceptedNpcQuestsNotifier extends Notifier<List<Quest>> {
  @override
  List<Quest> build() => const [];

  void add(Quest quest) {
    if (state.any((q) => q.id == quest.id)) return;
    state = [...state, quest];
  }
}

final acceptedNpcQuestsProvider =
    NotifierProvider<AcceptedNpcQuestsNotifier, List<Quest>>(
  AcceptedNpcQuestsNotifier.new,
);
