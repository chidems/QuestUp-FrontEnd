import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/quest_models.dart';
import 'quest_feed_provider.dart';

final questDetailProvider = FutureProvider.family<Quest, String>((ref, id) {
  return ref.read(questRepositoryProvider).getQuest(id);
});
