import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../data/history_api.dart';
import '../data/history_repository.dart';
import '../models/history_models.dart';

final historyApiProvider =
    Provider<HistoryApi>((ref) => HistoryApi(ref.read(dioClientProvider)));

final historyRepositoryProvider = Provider<HistoryRepository>(
  (ref) => HistoryRepository(ref.read(historyApiProvider)),
);

final historyProvider = FutureProvider<List<QuestHistoryItem>>(
  (ref) => ref.read(historyRepositoryProvider).getHistory(),
);
