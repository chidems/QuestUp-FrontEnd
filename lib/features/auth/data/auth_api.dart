import 'package:dio/dio.dart';
import '../../../core/config/app_config.dart';
import '../../../core/network/dio_client.dart';
import '../models/auth_models.dart';

class AuthApi {
  final Dio _dio;

  AuthApi(this._dio);

  Future<AuthResponse> login(LoginRequest request) async {
    if (AppConfig.useMockApi) return _mockAuthResponse(request.email, 'Hero');
    try {
      final response =
          await _dio.post('/auth/login', data: request.toJson());
      return AuthResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw dioErrorToApiException(e);
    }
  }

  Future<AuthResponse> register(RegisterRequest request) async {
    if (AppConfig.useMockApi) {
      return _mockAuthResponse(request.email, request.displayName);
    }
    try {
      final response =
          await _dio.post('/auth/register', data: request.toJson());
      return AuthResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw dioErrorToApiException(e);
    }
  }

  Future<User> getMe() async {
    if (AppConfig.useMockApi) return _mockUser();
    try {
      final response = await _dio.get('/users/me');
      return User.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw dioErrorToApiException(e);
    }
  }

  // --- Mock helpers ---

  AuthResponse _mockAuthResponse(String email, String displayName) =>
      AuthResponse(
        accessToken: 'mock_access_token',
        refreshToken: 'mock_refresh_token',
        user: User(
          id: '1',
          email: email,
          displayName: displayName,
          level: 3,
          totalXp: 450,
          coins: 350,
          currentStreak: 5,
          longestStreak: 12,
        ),
      );

  User _mockUser() => const User(
        id: '1',
        email: 'hero@questup.app',
        displayName: 'Hero',
        level: 3,
        totalXp: 450,
        coins: 350,
        currentStreak: 5,
        longestStreak: 12,
      );
}
