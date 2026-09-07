import 'package:benesnap/widgets/directional_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('firstStrongDirection', () {
    test('reads a Latin name left to right', () {
      expect(firstStrongDirection('LUMEN'), TextDirection.ltr);
    });

    test('reads an Arabic name right to left', () {
      expect(firstStrongDirection('غسول الوجه'), TextDirection.rtl);
    });

    test('skips punctuation to reach the first letter', () {
      // The bug this whole file exists for: the trailing '+' decided the
      // direction of the entire string, so "DERMA+" drew as "+DERMA".
      expect(firstStrongDirection('DERMA+'), TextDirection.ltr);
      expect(firstStrongDirection('Dr. Jart+'), TextDirection.ltr);
      expect(firstStrongDirection('+DERMA'), TextDirection.ltr);
      expect(firstStrongDirection('«غسول»'), TextDirection.rtl);
    });

    test('skips digits, which decide nothing on their own', () {
      expect(firstStrongDirection('7 Days'), TextDirection.ltr);
      expect(firstStrongDirection('2% حمض'), TextDirection.rtl);
    });

    test('takes the first strong character, not the majority', () {
      // A mostly-Arabic string that opens in Latin still reads as Latin —
      // first strong wins, which is what the bidi algorithm specifies.
      expect(firstStrongDirection('SPF واقي الشمس'), TextDirection.ltr);
      expect(firstStrongDirection('واقي الشمس SPF'), TextDirection.rtl);
    });

    test('gives up when there is nothing strong to go on', () {
      expect(firstStrongDirection(''), isNull);
      expect(firstStrongDirection('2024'), isNull);
      expect(firstStrongDirection('+'), isNull);
      expect(firstStrongDirection('   '), isNull);
    });
  });

  group('DirectionalText', () {
    /// Renders [text] inside an RTL app, the way every screen here does.
    Future<Text> render(WidgetTester tester, String text) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.rtl,
          child: SizedBox.shrink(),
        ),
      );
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.rtl,
          child: DirectionalText(text),
        ),
      );
      return tester.widget<Text>(find.byType(Text));
    }

    testWidgets('lays a Latin name out left to right inside an RTL app', (
      tester,
    ) async {
      final text = await render(tester, 'DERMA+');
      expect(text.textDirection, TextDirection.ltr);
    });

    testWidgets('leaves an Arabic name right to left', (tester) async {
      final text = await render(tester, 'غسول الوجه');
      expect(text.textDirection, TextDirection.rtl);
    });

    testWidgets('falls back to the ambient direction with nothing to go on', (
      tester,
    ) async {
      final text = await render(tester, '2024');
      expect(text.textDirection, TextDirection.rtl);
    });

    testWidgets('keeps alignment with the layout, not with the string', (
      tester,
    ) async {
      // The reason alignment is pinned rather than left to resolve against
      // the text's own direction: a Latin brand in a stretched, right
      // aligned card would otherwise jump to the far edge and break the
      // column it sits in.
      final latin = await render(tester, 'DERMA+');
      expect(latin.textAlign, TextAlign.right);

      final arabic = await render(tester, 'غسول الوجه');
      expect(arabic.textAlign, TextAlign.right);
    });

    testWidgets('still finds by text, so it reads as ordinary text', (
      tester,
    ) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.rtl,
          child: DirectionalText('DERMA+'),
        ),
      );
      // The string is untouched — no isolate characters spliced into it,
      // which would have quietly broken every `find.text` in the suite.
      expect(find.text('DERMA+'), findsOneWidget);
    });
  });
}
