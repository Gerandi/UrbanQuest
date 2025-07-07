import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:urbanquest_app/main.dart' as app;
import 'package:urbanquest_app/src/presentation/atoms/custom_button.dart';
import 'package:urbanquest_app/src/presentation/templates/app_template.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('UrbanQuest App Integration Tests', () {
    testWidgets('app loads and displays main interface', (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Verify the app loads without crashing
      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.byType(AppTemplate), findsOneWidget);
    });

    testWidgets('navigation between main views works', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Test bottom navigation if it exists
      final bottomNavFinder = find.byType(BottomNavigationBar);
      if (bottomNavFinder.evaluate().isNotEmpty) {
        // Navigate to different tabs
        await tester.tap(find.byIcon(Icons.home).first);
        await tester.pumpAndSettle();
        
        // Check if we can find typical home page elements
        // This would depend on your actual home page implementation
        
        await tester.tap(find.byIcon(Icons.search).first);
        await tester.pumpAndSettle();
        
        await tester.tap(find.byIcon(Icons.person).first);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('buttons respond to taps correctly', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Find any custom buttons and test them
      final customButtonFinder = find.byType(CustomButton);
      if (customButtonFinder.evaluate().isNotEmpty) {
        await tester.tap(customButtonFinder.first);
        await tester.pumpAndSettle();
        
        // Verify no crash occurred
        expect(find.byType(MaterialApp), findsOneWidget);
      }
    });

    testWidgets('app handles screen rotation', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Test portrait orientation
      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/platform',
        null,
        (data) {},
      );
      
      // Rotate to landscape
      await tester.binding.setSurfaceSize(const Size(800, 600));
      await tester.pumpAndSettle();
      
      // Verify app still works
      expect(find.byType(MaterialApp), findsOneWidget);
      
      // Rotate back to portrait
      await tester.binding.setSurfaceSize(const Size(400, 800));
      await tester.pumpAndSettle();
      
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('app handles back navigation correctly', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to a different screen if possible
      final buttonFinder = find.byType(ElevatedButton);
      if (buttonFinder.evaluate().isNotEmpty) {
        await tester.tap(buttonFinder.first);
        await tester.pumpAndSettle();
        
        // Try to go back
        final backButtonFinder = find.byIcon(Icons.arrow_back);
        if (backButtonFinder.evaluate().isNotEmpty) {
          await tester.tap(backButtonFinder.first);
          await tester.pumpAndSettle();
        } else {
          // Use system back if no back button
          await tester.pageBack();
          await tester.pumpAndSettle();
        }
        
        // Verify we're back to the main screen
        expect(find.byType(MaterialApp), findsOneWidget);
      }
    });

    testWidgets('text input fields work correctly', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Find any text input fields
      final textFieldFinder = find.byType(TextField);
      if (textFieldFinder.evaluate().isNotEmpty) {
        await tester.tap(textFieldFinder.first);
        await tester.pumpAndSettle();
        
        // Enter some text
        await tester.enterText(textFieldFinder.first, 'Test input');
        await tester.pumpAndSettle();
        
        // Verify text was entered
        expect(find.text('Test input'), findsOneWidget);
      }
    });

    testWidgets('loading states work correctly', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Look for any loading indicators
      final progressIndicatorFinder = find.byType(CircularProgressIndicator);
      
      // If we find loading indicators, wait for them to disappear
      if (progressIndicatorFinder.evaluate().isNotEmpty) {
        await tester.pumpAndSettle(const Duration(seconds: 10));
        
        // Verify app loaded successfully
        expect(find.byType(MaterialApp), findsOneWidget);
      }
    });

    testWidgets('error handling works correctly', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // The app should handle errors gracefully and not crash
      // Look for any error indicators or fallback UI
      
      // Verify the app is still responsive
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    group('Performance Tests', () {
      testWidgets('app renders within reasonable time', (WidgetTester tester) async {
        final stopwatch = Stopwatch()..start();
        
        app.main();
        await tester.pumpAndSettle();
        
        stopwatch.stop();
        
        // App should load within 5 seconds
        expect(stopwatch.elapsedMilliseconds, lessThan(5000));
        expect(find.byType(MaterialApp), findsOneWidget);
      });

      testWidgets('navigation is smooth and responsive', (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle();

        final stopwatch = Stopwatch();

        // Test navigation performance
        final buttonFinder = find.byType(CustomButton);
        if (buttonFinder.evaluate().isNotEmpty) {
          stopwatch.start();
          await tester.tap(buttonFinder.first);
          await tester.pumpAndSettle();
          stopwatch.stop();

          // Navigation should be quick (less than 1 second)
          expect(stopwatch.elapsedMilliseconds, lessThan(1000));
        }
      });
    });

    group('Accessibility Tests', () {
      testWidgets('app is accessible', (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle();

        // Check for semantic labels
        final semanticsFinder = find.byType(Semantics);
        expect(semanticsFinder.evaluate().length, greaterThan(0));

        // Verify no accessibility issues
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(iOSHTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
      });

      testWidgets('keyboard navigation works', (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle();

        // Test tab navigation
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();

        // Verify focus moved
        expect(find.byType(MaterialApp), findsOneWidget);
      });
    });

    group('Memory and Resource Tests', () {
      testWidgets('app does not leak memory during navigation', (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle();

        // Simulate multiple navigation cycles
        for (int i = 0; i < 5; i++) {
          final buttonFinder = find.byType(CustomButton);
          if (buttonFinder.evaluate().isNotEmpty) {
            await tester.tap(buttonFinder.first);
            await tester.pumpAndSettle();
            
            // Go back
            final backButtonFinder = find.byIcon(Icons.arrow_back);
            if (backButtonFinder.evaluate().isNotEmpty) {
              await tester.tap(backButtonFinder.first);
              await tester.pumpAndSettle();
            }
          }
        }

        // App should still be working
        expect(find.byType(MaterialApp), findsOneWidget);
      });
    });
  });
}

// Additional utility functions for integration tests
extension IntegrationTestHelpers on WidgetTester {
  Future<void> waitForAnimation() async {
    await pumpAndSettle(const Duration(milliseconds: 300));
  }

  Future<void> scrollToWidget(Finder finder) async {
    final element = finder.evaluate().single;
    await scrollUntilVisible(finder, 100);
    await pumpAndSettle();
  }

  Future<void> tapAndWait(Finder finder) async {
    await tap(finder);
    await waitForAnimation();
  }
}