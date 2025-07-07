import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:urbanquest_app/src/presentation/atoms/custom_card.dart';

void main() {
  group('CustomCard Widget Tests', () {
    testWidgets('should display child widget correctly', (WidgetTester tester) async {
      const testText = 'Test Content';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomCard(
              child: Text(testText),
            ),
          ),
        ),
      );

      expect(find.text(testText), findsOneWidget);
      expect(find.byType(Container), findsOneWidget);
    });

    testWidgets('should apply default padding when not specified', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomCard(
              child: Text('Test'),
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container));
      expect(container.padding, isNotNull);
    });

    testWidgets('should apply custom padding when specified', (WidgetTester tester) async {
      const customPadding = EdgeInsets.all(20);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomCard(
              padding: customPadding,
              child: Text('Test'),
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container));
      expect(container.padding, customPadding);
    });

    testWidgets('should apply default margin when not specified', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomCard(
              child: Text('Test'),
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container));
      expect(container.margin, isNotNull);
    });

    testWidgets('should apply custom margin when specified', (WidgetTester tester) async {
      const customMargin = EdgeInsets.symmetric(horizontal: 16, vertical: 8);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomCard(
              margin: customMargin,
              child: Text('Test'),
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container));
      expect(container.margin, customMargin);
    });

    testWidgets('should apply elevation through shadow', (WidgetTester tester) async {
      const elevation = 8.0;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomCard(
              elevation: elevation,
              child: Text('Test'),
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container));
      expect(container.decoration, isA<BoxDecoration>());
      
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.boxShadow, isNotNull);
      expect(decoration.boxShadow, isNotEmpty);
    });

    testWidgets('should apply custom border radius', (WidgetTester tester) async {
      const borderRadius = BorderRadius.all(Radius.circular(20));

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomCard(
              borderRadius: borderRadius,
              child: Text('Test'),
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container));
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.borderRadius, borderRadius);
    });

    testWidgets('should apply custom background color', (WidgetTester tester) async {
      const backgroundColor = Colors.red;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomCard(
              color: backgroundColor,
              child: Text('Test'),
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container));
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, backgroundColor);
    });

    testWidgets('should handle zero elevation correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomCard(
              elevation: 0,
              child: Text('Test'),
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container));
      final decoration = container.decoration as BoxDecoration;
      
      // With zero elevation, shadow should be null or empty
      expect(decoration.boxShadow, anyOf(isNull, isEmpty));
    });

    testWidgets('should handle complex child widgets', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomCard(
              child: Column(
                children: [
                  const Text('Title'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star),
                      const SizedBox(width: 4),
                      const Text('4.5'),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: () {},
                    child: const Text('Action'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Title'), findsOneWidget);
      expect(find.byIcon(Icons.star), findsOneWidget);
      expect(find.text('4.5'), findsOneWidget);
      expect(find.text('Action'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('should maintain size constraints correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              height: 100,
              child: CustomCard(
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.blue,
                ),
              ),
            ),
          ),
        ),
      );

      final cardSize = tester.getSize(find.byType(CustomCard));
      expect(cardSize.width, equals(200));
      expect(cardSize.height, equals(100));
    });

    testWidgets('should handle null properties gracefully', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomCard(
              padding: null,
              margin: null,
              color: null,
              borderRadius: null,
              child: Text('Test'),
            ),
          ),
        ),
      );

      expect(find.text('Test'), findsOneWidget);
      expect(find.byType(Container), findsOneWidget);
    });

    group('Card styling combinations', () {
      testWidgets('should apply multiple style properties together', (WidgetTester tester) async {
        const padding = EdgeInsets.all(24);
        const margin = EdgeInsets.all(16);
        const backgroundColor = Colors.amber;
        const borderRadius = BorderRadius.all(Radius.circular(16));
        const elevation = 4.0;

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: CustomCard(
                padding: padding,
                margin: margin,
                color: backgroundColor,
                borderRadius: borderRadius,
                elevation: elevation,
                child: Text('Styled Card'),
              ),
            ),
          ),
        );

        final container = tester.widget<Container>(find.byType(Container));
        final decoration = container.decoration as BoxDecoration;

        expect(container.padding, padding);
        expect(container.margin, margin);
        expect(decoration.color, backgroundColor);
        expect(decoration.borderRadius, borderRadius);
        expect(decoration.boxShadow, isNotEmpty);
        expect(find.text('Styled Card'), findsOneWidget);
      });

      testWidgets('should handle edge case values correctly', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: CustomCard(
                padding: EdgeInsets.zero,
                margin: EdgeInsets.zero,
                elevation: 0,
                borderRadius: BorderRadius.zero,
                child: Text('Edge Case Card'),
              ),
            ),
          ),
        );

        final container = tester.widget<Container>(find.byType(Container));
        final decoration = container.decoration as BoxDecoration;

        expect(container.padding, EdgeInsets.zero);
        expect(container.margin, EdgeInsets.zero);
        expect(decoration.borderRadius, BorderRadius.zero);
        expect(find.text('Edge Case Card'), findsOneWidget);
      });
    });

    group('Accessibility', () {
      testWidgets('should preserve child accessibility properties', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CustomCard(
                child: Semantics(
                  label: 'Accessible content',
                  child: const Text('Content'),
                ),
              ),
            ),
          ),
        );

        expect(find.bySemanticsLabel('Accessible content'), findsOneWidget);
      });

      testWidgets('should not interfere with focus behavior', (WidgetTester tester) async {
        final focusNode = FocusNode();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CustomCard(
                child: TextField(
                  focusNode: focusNode,
                  decoration: const InputDecoration(hintText: 'Test field'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.byType(TextField));
        await tester.pump();

        expect(focusNode.hasFocus, isTrue);
      });
    });
  });
}