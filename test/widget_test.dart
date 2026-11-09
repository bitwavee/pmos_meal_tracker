import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pmos_meal_tracker/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('shows PMOS onboarding on first launch', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const PMOSMealTrackerApp());
    await tester.pumpAndSettle();

    expect(find.text('PMOS'), findsWidgets);
    expect(find.text('Welcome to your PCOS wellness rhythm'), findsOneWidget);
  });
}
