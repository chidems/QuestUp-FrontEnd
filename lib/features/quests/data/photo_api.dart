import 'dart:io';
import 'package:dio/dio.dart';
import '../../../core/config/app_config.dart';
import '../../../core/network/dio_client.dart';
import '../models/completion_models.dart';

class PhotoApi {
  final Dio _dio;

  PhotoApi(this._dio);

  /// Photo support is a mock/local flow on the backend: `/photos/upload-url`
  /// hands back a `local://` URL to attach to the quest completion. There is no
  /// binary upload endpoint yet, so the file is referenced, not transferred.
  Future<PhotoUploadResult> uploadPhoto(File file) async {
    if (AppConfig.useMockApi) {
      return const PhotoUploadResult(
        id: 'mock',
        url: 'https://placehold.co/400x400/png',
      );
    }
    try {
      final response = await _dio.post('/photos/upload-url');
      return PhotoUploadResult.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw dioErrorToApiException(e);
    }
  }
}
