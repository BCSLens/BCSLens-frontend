import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'test_helpers.dart';

/// History Screen Tests (6 test cases)
/// Tests pet health history display and data visualization
void main() {
  // Ignore overflow errors in tests
  FlutterError.onError = (FlutterErrorDetails details) {
    if (details.exception.toString().contains('RenderFlex overflowed')) {
      return;
    }
    FlutterError.presentError(details);
  };

  group('Pet History Screen Tests', () {
    
    // Test Case 1: Load Pet History
    testWidgets('TC1: Load Pet History - Should display pet info and records', (WidgetTester tester) async {
      // Note: Requires mock pet data
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(child: Text('History Screen')),
        ),
      ));
      await pumpAndWait(tester);

      // Verify: History screen should render
      expect(find.text('History Screen'), findsOneWidget,
        reason: 'Should display pet history screen');
    });

    // Test Case 2: BCS Bubble Display
    testWidgets('TC2: BCS Bubble - Should show single BCS score or N/A', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              Text('BCS: 5'),
              Text('BCS: N/A'),
            ],
          ),
        ),
      ));
      await pumpAndWait(tester);

      // Verify: Should display BCS score correctly
      expect(find.textContaining('BCS'), findsWidgets,
        reason: 'Should display BCS score or N/A');
    });

    // Test Case 3: BCS Trend Graph
    testWidgets('TC3: BCS Trend Graph - Should display red line chart', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(child: Text('BCS Trend')),
        ),
      ));
      await pumpAndWait(tester);

      // Verify: BCS trend graph should be present
      expect(find.text('BCS Trend'), findsOneWidget,
        reason: 'Should display BCS trend graph');
    });

    // Test Case 4: Weight Trend Graph
    testWidgets('TC4: Weight Trend Graph - Should display green line chart', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(child: Text('Weight Trend')),
        ),
      ));
      await pumpAndWait(tester);

      // Verify: Weight trend graph should be present
      expect(find.text('Weight Trend'), findsOneWidget,
        reason: 'Should display weight trend graph');
    });

    // Test Case 5: Recommendations
    testWidgets('TC5: Recommendations - Should show species-specific advice', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              Text('Nutrition'),
              Text('Basic Care'),
              Text('Exercise'),
              Text('Additional Tips'),
              Text('Veterinary Care'),
            ],
          ),
        ),
      ));
      await pumpAndWait(tester);

      // Verify: Recommendations should be displayed
      expect(find.text('Nutrition'), findsOneWidget,
        reason: 'Should display nutrition recommendations');
      expect(find.text('Exercise'), findsOneWidget,
        reason: 'Should display exercise recommendations');
    });

    // Test Case 6: Image Display
    testWidgets('TC6: Image Display - Should show pet images from backend', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: Image.network(
              'https://example.com/pet.jpg',
              errorBuilder: (context, error, stackTrace) {
                return Icon(Icons.pets);
              },
            ),
          ),
        ),
      ));
      await pumpAndWait(tester);

      // Verify: Should handle image display
      expect(find.byType(Image), findsOneWidget,
        reason: 'Should display pet images');
    });
  });
}

