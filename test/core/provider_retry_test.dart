import 'package:flutter_test/flutter_test.dart';
import 'package:quest_up/core/location/location_service.dart';
import 'package:quest_up/core/network/api_exception.dart';
import 'package:quest_up/core/network/provider_retry.dart';

void main() {
  group('appProviderRetry', () {
    test('never retries a 4xx — the server will keep saying no', () {
      // 404: the weekly community quest id isn't a user quest.
      expect(appProviderRetry(0, const ApiException('nope', statusCode: 404)),
          isNull);
      // 400: "Only active quests can be accepted".
      expect(appProviderRetry(0, const ApiException('nope', statusCode: 400)),
          isNull);
      expect(appProviderRetry(0, const ApiException('nope', statusCode: 401)),
          isNull);
    });

    test('never retries a location failure — only the user can fix it', () {
      expect(appProviderRetry(0, const LocationException('off')), isNull);
    });

    test('retries server errors and connection trouble, briefly', () {
      expect(appProviderRetry(0, const ApiException('boom', statusCode: 500)),
          const Duration(milliseconds: 200));
      // No status code at all = connection error, not a server verdict.
      expect(appProviderRetry(1, const ApiException('offline')),
          const Duration(milliseconds: 400));
    });

    test('gives up quickly so the error view appears instead of a spinner', () {
      // Total spent retrying is 200 + 400 + 800 = 1.4s, not the ~38s that
      // Riverpod's default (10 attempts) would burn.
      expect(appProviderRetry(2, const ApiException('boom', statusCode: 503)),
          const Duration(milliseconds: 800));
      expect(appProviderRetry(3, const ApiException('boom', statusCode: 503)),
          isNull);
    });
  });
}
