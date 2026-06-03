import '../models/history_models.dart';
import 'history_api.dart';

class HistoryRepository {
  final HistoryApi _api;

  HistoryRepository(this._api);

  Future<List<QuestHistoryItem>> getHistory() => _api.getHistory();
}
