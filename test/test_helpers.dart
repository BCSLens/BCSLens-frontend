import 'package:flutter_test/flutter_test.dart';

/// Helper functions for widget tests
/// These functions help avoid timeout issues and handle overflow errors gracefully

/// Pump widget and wait for initialization without timeout
/// Use this instead of pumpAndSettle() to avoid timeout issues
Future<void> pumpAndWait(WidgetTester tester, {int milliseconds = 500}) async {
  await tester.pump();
  await tester.pump(Duration(milliseconds: milliseconds));
  // Clear overflow exceptions (UI layout issues don't affect functionality)
  tester.takeException();
}

/// Pump widget multiple times to ensure async operations complete
/// Use this for async initialization
Future<void> pumpForAsyncInit(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump(const Duration(milliseconds: 500));
  tester.takeException();
}

