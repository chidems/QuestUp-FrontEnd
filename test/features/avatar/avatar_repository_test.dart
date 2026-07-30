import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:quest_up/features/avatar/data/avatar_repository.dart';
import 'package:quest_up/features/avatar/models/avatar_models.dart';

void main() {
  group('AvatarRepository', () {
    test('a fresh account with nothing saved gets the starter defaults',
        () async {
      SharedPreferences.setMockInitialValues({});
      final repo = AvatarRepository();

      final appearance = await repo.getAppearance('user-a');

      expect(appearance, AvatarAppearance.defaults);
    });

    test('two accounts on the same device keep separate looks', () async {
      SharedPreferences.setMockInitialValues({});
      final repo = AvatarRepository();

      await repo.saveAppearance(
        'user-a',
        AvatarAppearance.defaults.copyWith(skinId: 'skin_blue'),
      );

      expect((await repo.getAppearance('user-a')).skinId, 'skin_blue');
      // A second account that never saved anything must not inherit the
      // first account's look — this is the bug: logging out and registering
      // a new user showed the previous user's avatar.
      expect(
        (await repo.getAppearance('user-b')).skinId,
        AvatarAppearance.defaults.skinId,
      );
    });

    test(
        'a pre-namespacing save under the old global key is not picked up '
        'by any account — safer to lose it once than to risk handing it to '
        'whichever account happens to read it first', () async {
      SharedPreferences.setMockInitialValues({
        'flutter.avatar_appearance':
            AvatarAppearance.defaults.copyWith(skinId: 'skin_blue').encode(),
      });
      final repo = AvatarRepository();

      expect((await repo.getAppearance('user-a')).skinId,
          AvatarAppearance.defaults.skinId);
    });
  });
}
