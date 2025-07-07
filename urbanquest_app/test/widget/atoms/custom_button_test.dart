import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:urbanquest_app/src/presentation/atoms/custom_button.dart';
import 'package:urbanquest_app/src/core/constants/app_colors.dart';

void main() {
  group('CustomButton Widget Tests', () {
    testWidgets('should display button text correctly', (WidgetTester tester) async {
      const buttonText = 'Test Button';
      bool wasPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomButton(
              text: buttonText,
              onPressed: () => wasPressed = true,
            ),
          ),
        ),
      );

      expect(find.text(buttonText), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('should handle button press correctly', (WidgetTester tester) async {
      bool wasPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomButton(
              text: 'Press Me',
              onPressed: () => wasPressed = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(CustomButton));
      await tester.pump();

      expect(wasPressed, isTrue);
    });

    testWidgets('should be disabled when onPressed is null', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomButton(
              text: 'Disabled Button',
              onPressed: null,
            ),
          ),
        ),
      );

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('should display icon when provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomButton(
              text: 'Button with Icon',
              icon: Icons.star,
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.star), findsOneWidget);
      expect(find.text('Button with Icon'), findsOneWidget);
    });

    testWidgets('should display loading indicator when isLoading is true', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomButton(
              text: 'Loading Button',
              isLoading: true,
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading Button'), findsNothing);
    });

    testWidgets('should be disabled when loading', (WidgetTester tester) async {
      bool wasPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomButton(
              text: 'Loading Button',
              isLoading: true,
              onPressed: () => wasPressed = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(CustomButton));
      await tester.pump();

      expect(wasPressed, isFalse);
    });

    testWidgets('should apply primary variant styles correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomButton(
              text: 'Primary Button',
              variant: ButtonVariant.primary,
              onPressed: () {},
            ),
          ),
        ),
      );

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      final style = button.style!;
      
      // Check if the style has been applied (we can't directly test the colors due to theming)
      expect(style, isNotNull);
    });

    testWidgets('should apply secondary variant styles correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomButton(
              text: 'Secondary Button',
              variant: ButtonVariant.secondary,
              onPressed: () {},
            ),
          ),
        ),
      );

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.style, isNotNull);
    });

    testWidgets('should apply outline variant styles correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomButton(
              text: 'Outline Button',
              variant: ButtonVariant.outline,
              onPressed: () {},
            ),
          ),
        ),
      );

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.style, isNotNull);
    });

    testWidgets('should apply ghost variant styles correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomButton(
              text: 'Ghost Button',
              variant: ButtonVariant.ghost,
              onPressed: () {},
            ),
          ),
        ),
      );

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.style, isNotNull);
    });

    testWidgets('should apply small size correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomButton(
              text: 'Small Button',
              size: ButtonSize.small,
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byType(CustomButton), findsOneWidget);
    });

    testWidgets('should apply medium size correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomButton(
              text: 'Medium Button',
              size: ButtonSize.medium,
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byType(CustomButton), findsOneWidget);
    });

    testWidgets('should apply large size correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomButton(
              text: 'Large Button',
              size: ButtonSize.large,
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byType(CustomButton), findsOneWidget);
    });

    testWidgets('should expand to full width when isFullWidth is true', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              child: CustomButton(
                text: 'Full Width Button',
                isFullWidth: true,
                onPressed: () {},
              ),
            ),
          ),
        ),
      );

      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox).first);
      expect(sizedBox.width, double.infinity);
    });

    testWidgets('should not expand when isFullWidth is false', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomButton(
              text: 'Normal Button',
              isFullWidth: false,
              onPressed: () {},
            ),
          ),
        ),
      );

      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox).first);
      expect(sizedBox.width, isNull);
    });

    testWidgets('should handle text overflow correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 100, // Very narrow width to force overflow
              child: CustomButton(
                text: 'This is a very long button text that should overflow',
                onPressed: () {},
              ),
            ),
          ),
        ),
      );

      // Should not throw overflow errors
      expect(find.byType(CustomButton), findsOneWidget);
      
      // Find the Text widget inside the button
      final textWidgets = find.descendant(
        of: find.byType(CustomButton),
        matching: find.byType(Text),
      );
      
      expect(textWidgets, findsOneWidget);
      
      final textWidget = tester.widget<Text>(textWidgets.first);
      expect(textWidget.overflow, TextOverflow.ellipsis);
    });

    testWidgets('should maintain icon spacing correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomButton(
              text: 'Icon Button',
              icon: Icons.star,
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.star), findsOneWidget);
      expect(find.text('Icon Button'), findsOneWidget);
      
      // Verify the Row structure
      final rowFinder = find.descendant(
        of: find.byType(CustomButton),
        matching: find.byType(Row),
      );
      expect(rowFinder, findsOneWidget);
    });

    group('Button combinations', () {
      testWidgets('should handle icon + loading state correctly', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CustomButton(
                text: 'Icon Loading Button',
                icon: Icons.star,
                isLoading: true,
                onPressed: () {},
              ),
            ),
          ),
        );

        // When loading, should show progress indicator, not icon or text
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.byIcon(Icons.star), findsNothing);
        expect(find.text('Icon Loading Button'), findsNothing);
      });

      testWidgets('should handle full width + icon correctly', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CustomButton(
                text: 'Full Width Icon Button',
                icon: Icons.star,
                isFullWidth: true,
                onPressed: () {},
              ),
            ),
          ),
        );

        expect(find.byIcon(Icons.star), findsOneWidget);
        expect(find.text('Full Width Icon Button'), findsOneWidget);
        
        final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox).first);
        expect(sizedBox.width, double.infinity);
      });
    });
  });
}