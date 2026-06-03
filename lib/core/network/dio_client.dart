import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';
import '../storage/token_storage.dart';
import 'auth_interceptor.dart';
import 'api_exception.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

final dioClientProvider = Provider<Dio>((ref) {
  final tokenStorage = ref.read(tokenStorageProvider);

  final dio = Dio(BaseOptions(
    baseUrl: AppConfig.apiBaseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 30),
    headers: {'Content-Type': 'application/json'},
  ));

  dio.interceptors.add(AuthInterceptor(tokenStorage));

  return dio;
});

ApiException dioErrorToApiException(DioException e) {
  if (e.response != null) {
    final data = e.response!.data;
    final message = (data is Map && data['detail'] != null)
        ? data['detail'].toString()
        : 'Request failed (${e.response!.statusCode})';
    return ApiException(message, statusCode: e.response!.statusCode);
  }
  if (e.type == DioExceptionType.connectionTimeout ||
      e.type == DioExceptionType.receiveTimeout) {
    return const ApiException('Connection timed out. Check your internet.');
  }
  return const ApiException('Network error. Check your connection.');
}
