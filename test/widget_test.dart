import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:scanx_app/main.dart';
import 'package:scanx_app/core/services/settings_service.dart';

void main() {
  testWidgets('SCAN-X app builds', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await SettingsService.init();

    await tester.pumpWidget(const ScanXApp());
    await tester.pumpAndSettle();

    expect(find.byType(ScanXApp), findsOneWidget);
  });
}