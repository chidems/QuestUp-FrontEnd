import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../location/location_service.dart';
import 'api_exception.dart';

/// Retry policy for every provider in the app, installed on the [ProviderScope].
///
/// Riverpod retries a failed provider with exponential backoff. Its default is
/// 10 attempts with delays growing to 6.4s — roughly 38 seconds of spinner
/// before the error ever reaches the screen. That is the wrong trade for two
/// kinds of failure:
///
/// * A 4xx is the server's final answer (404 for a quest that isn't the user's,
///   400 for an action the backend rejects). Retrying cannot change it.
/// * A [LocationException] means permissions or services are off. Only the user
///   can fix that, and the feed already offers an "Open settings" action.
///
/// Both fail immediately so the UI can say what happened. Genuinely transient
/// trouble still gets a few quick attempts.
Duration? appProviderRetry(int retryCount, Object error) {
  if (error is LocationException) return null;
  if (error is ApiException) {
    final status = error.statusCode;
    if (status != null && status >= 400 && status < 500) return null;
  }
  // 200ms + 400ms + 800ms, then give up and show the error with its Retry
  // button rather than spinning.
  return ProviderContainer.defaultRetry(retryCount, error, maxRetries: 3);
}
