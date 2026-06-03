import '../models/profile_models.dart';
import 'profile_api.dart';

class ProfileRepository {
  final ProfileApi _api;

  ProfileRepository(this._api);

  Future<LifeStats> getStats() => _api.getStats();
}
