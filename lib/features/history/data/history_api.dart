import 'package:dio/dio.dart';
import '../../../core/config/app_config.dart';
import '../../../core/network/dio_client.dart';
import '../models/history_models.dart';

class HistoryApi {
  final Dio _dio;

  HistoryApi(this._dio);

  Future<List<QuestHistoryItem>> getHistory() async {
    if (AppConfig.useMockApi) return _mock();
    try {
      final response = await _dio.get('/quests/history');
      final data = response.data;
      final list = data is List ? data : (data['quests'] as List? ?? []);
      return list
          .map((e) => QuestHistoryItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw dioErrorToApiException(e);
    }
  }

  List<QuestHistoryItem> _mock() => [
        QuestHistoryItem(
          id: 'h1',
          title: 'Explore a new neighborhood cafe',
          questType: 'location',
          xpEarned: 50,
          coinsEarned: 20,
          completedAt: DateTime.now().subtract(const Duration(hours: 5)),
        ),
        QuestHistoryItem(
          id: 'h2',
          title: 'Compliment 3 strangers today',
          questType: 'social',
          xpEarned: 80,
          coinsEarned: 35,
          completedAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
        QuestHistoryItem(
          id: 'h3',
          title: 'Do 20 push-ups in a park',
          questType: 'action',
          xpEarned: 60,
          coinsEarned: 25,
          completedAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
      ];
}
