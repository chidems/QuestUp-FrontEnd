import 'package:dio/dio.dart';
import '../../../core/config/app_config.dart';
import '../../../core/network/dio_client.dart';
import '../../avatar/data/avatar_api.dart' show mockCatalog;
import '../../avatar/models/avatar_models.dart';

class StoreApi {
  final Dio _dio;

  StoreApi(this._dio);

  Future<List<AvatarItem>> getItems() async {
    if (AppConfig.useMockApi) return mockCatalog;
    try {
      final response = await _dio.get('/store/items');
      final data = response.data;
      final list = data is List ? data : (data['items'] as List? ?? []);
      return list
          .map((e) => AvatarItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw dioErrorToApiException(e);
    }
  }

  Future<void> buy(String itemId) async {
    if (AppConfig.useMockApi) return;
    try {
      await _dio.post('/store/items/$itemId/buy');
    } on DioException catch (e) {
      throw dioErrorToApiException(e);
    }
  }
}
