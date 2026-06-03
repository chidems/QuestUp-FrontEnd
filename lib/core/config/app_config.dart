class AppConfig {
  static const bool useMockApi =
      bool.fromEnvironment('USE_MOCK_API', defaultValue: false);

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );
}
