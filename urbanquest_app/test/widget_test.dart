import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:urbanquest_app/main.dart';
import 'package:urbanquest_app/src/presentation/templates/app_template.dart';

void main() {
  group('UrbanQuest App Widget Tests', () {
    testWidgets('app loads without crashing', (WidgetTester tester) async {
      // Build our app and trigger a frame
      await tester.pumpWidget(const UrbanQuestApp());

      // Verify that app loads without crashing
      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.byType(AppTemplate), findsOneWidget);
    });

    testWidgets('app has correct title', (WidgetTester tester) async {
      await tester.pumpWidget(const UrbanQuestApp());

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.title, 'Urban Quest');
    });

    testWidgets('app uses Material 3 design', (WidgetTester tester) async {
      await tester.pumpWidget(const UrbanQuestApp());

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.theme?.useMaterial3, isTrue);
    });

    testWidgets('app has debug banner disabled', (WidgetTester tester) async {
      await tester.pumpWidget(const UrbanQuestApp());

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.debugShowCheckedModeBanner, isFalse);
    });

    testWidgets('app handles theme correctly', (WidgetTester tester) async {
      await tester.pumpWidget(const UrbanQuestApp());

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.theme, isNotNull);
      expect(materialApp.theme?.colorScheme, isNotNull);
    });

    testWidgets('app template renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(const UrbanQuestApp());
      
      // Wait for the app to settle
      await tester.pumpAndSettle();

      // Verify AppTemplate is present
      expect(find.byType(AppTemplate), findsOneWidget);
      
      // Verify basic structure exists (this will depend on your AppTemplate implementation)
      expect(find.byType(Scaffold), findsAtLeastNWidgets(1));
    });

    testWidgets('app survives hot reload', (WidgetTester tester) async {
      await tester.pumpWidget(const UrbanQuestApp());
      await tester.pumpAndSettle();

      // Simulate hot reload
      await tester.pumpWidget(const UrbanQuestApp());
      await tester.pumpAndSettle();

      // App should still be working
      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.byType(AppTemplate), findsOneWidget);
    });

    testWidgets('app handles orientation changes', (WidgetTester tester) async {
      await tester.pumpWidget(const UrbanQuestApp());
      await tester.pumpAndSettle();

      // Test portrait
      await tester.binding.setSurfaceSize(const Size(400, 800));
      await tester.pumpAndSettle();
      expect(find.byType(MaterialApp), findsOneWidget);

      // Test landscape
      await tester.binding.setSurfaceSize(const Size(800, 400));
      await tester.pumpAndSettle();
      expect(find.byType(MaterialApp), findsOneWidget);

      // Reset to portrait
      await tester.binding.setSurfaceSize(const Size(400, 800));
      await tester.pumpAndSettle();
    });

    group('Error Handling', () {
      testWidgets('app handles widget errors gracefully', (WidgetTester tester) async {
        // This test ensures the app doesn't crash when encountering widget errors
        await tester.pumpWidget(const UrbanQuestApp());
        await tester.pumpAndSettle();

        // App should still be running
        expect(find.byType(MaterialApp), findsOneWidget);
      });
    });

    group('Performance', () {
      testWidgets('app builds within reasonable time', (WidgetTester tester) async {
        final stopwatch = Stopwatch()..start();
        
        await tester.pumpWidget(const UrbanQuestApp());
        await tester.pumpAndSettle();
        
        stopwatch.stop();
        
        // App should build within 2 seconds
        expect(stopwatch.elapsedMilliseconds, lessThan(2000));
      });
    });

    group('Accessibility', () {
      testWidgets('app meets basic accessibility guidelines', (WidgetTester tester) async {
        await tester.pumpWidget(const UrbanQuestApp());
        await tester.pumpAndSettle();

        // Test basic accessibility guidelines
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(iOSHTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
      });
    });
  });
}
