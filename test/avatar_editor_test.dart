import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:quest_up/features/avatar/presentation/customize_screen.dart';
import 'package:quest_up/features/avatar/providers/avatar_provider.dart';

void main() {
  testWidgets('tapping a skin swatch equips it and persists', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: CustomizeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(container.read(appearanceProvider).value?.skinId, 'skin_light');

    await tester.tap(find.bySemanticsLabel('Blue'));
    await tester.pumpAndSettle();

    expect(container.read(appearanceProvider).value?.skinId, 'skin_blue');

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('avatar_appearance'), contains('skin_blue'));
  });

  testWidgets('Tops tab None cell clears the top slot', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: CustomizeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tops'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('None'));
    await tester.pumpAndSettle();

    final appearance = container.read(appearanceProvider).value;
    expect(appearance?.topId, isNull);
    // Other slots untouched.
    expect(appearance?.bottomId, isNotNull);
  });
}
