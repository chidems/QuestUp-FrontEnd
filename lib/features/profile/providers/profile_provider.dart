import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../data/profile_api.dart';
import '../data/profile_repository.dart';
import '../models/profile_models.dart';

final profileApiProvider =
    Provider<ProfileApi>((ref) => ProfileApi(ref.read(dioClientProvider)));

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(ref.read(profileApiProvider)),
);

final statsProvider = FutureProvider<LifeStats>(
  (ref) => ref.read(profileRepositoryProvider).getStats(),
);
