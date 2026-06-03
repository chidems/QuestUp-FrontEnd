import 'dart:io';
import 'package:dio/dio.dart';
import '../../../core/config/app_config.dart';
import '../../../core/network/dio_client.dart';
import '../models/completion_models.dart';

class PhotoApi {
  final Dio _dio;

  PhotoApi(this._dio);

  Future<PhotoUploadResult> uploadPhoto(File file) async {
    if (AppConfig.useMockApi) {
      return const PhotoUploadResult(
        id: 'mock_photo',
        url: 'https://placehold.co/400x400/png',
      );
    }
    try {
      final filename = file.path.split(RegExp(r'[/\\]')).last;
      final form = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path, filename: filename),
      });
      final response = await _dio.post('/photos/upload', data: form);
      return PhotoUploadResult.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw dioErrorToApiException(e);
    }
  }
}
