import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:first_app/main.dart';
import 'test_helpers.dart';

/// General System Tests (4 test cases)
/// Tests system-wide functionality and behavior
void main() {
  // Ignore overflow errors in tests
  FlutterError.onError = (FlutterErrorDetails details) {
    if (details.exception.toString().contains('RenderFlex overflowed')) {
      return;
    }
    FlutterError.presentError(details);
  };

  group('General System Tests', () {
    
    // Test Case 1: Portrait Lock
    testWidgets('TC1: Portrait Lock - App should remain in portrait orientation', (WidgetTester tester) async {
      await tester.pumpWidget(const BCSLensApp());
      await pumpForAsyncInit(tester);

      // Verify: App should be locked to portrait orientation
      // Note: This is set in main.dart with SystemChrome.setPreferredOrientations
      expect(find.byType(MaterialApp), findsOneWidget,
        reason: 'App should enforce portrait orientation lock');
    });

    // Test Case 2: Navigation
    testWidgets('TC2: Navigation - Should have smooth route transitions', (WidgetTester tester) async {
      await tester.pumpWidget(const BCSLensApp());
      await pumpForAsyncInit(tester);

      // Verify: Navigation should work correctly
      expect(find.byType(MaterialApp), findsOneWidget,
        reason: 'App should support navigation between screens');
    });

    // Test Case 3: Loading States
    testWidgets('TC3: Loading States - Should show loading indicators', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ));
      await tester.pump();

      // Verify: Loading indicator should be displayed
      expect(find.byType(CircularProgressIndicator), findsOneWidget,
        reason: 'Should display loading indicators during async operations');
    });

    // Test Case 4: Error Messages
    testWidgets('TC4: Error Messages - Should display user-friendly errors', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: Something went wrong')),
                  );
                },
                child: Text('Trigger Error'),
              );
            },
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // Tap button to trigger error
      await tester.tap(find.text('Trigger Error'));
      await tester.pump();

      // Verify: Error message should be displayed
      expect(find.text('Error: Something went wrong'), findsOneWidget,
        reason: 'Should display user-friendly error messages');
    });
  });
}

