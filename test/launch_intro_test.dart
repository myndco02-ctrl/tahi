import 'dart:async';
import 'dart:ui' as ui;

import 'package:eltahi_demo/launch_intro.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> loadArtwork(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 100)),
  );
  await tester.pump();
}

Widget host({
  required bool ready,
  required VoidCallback complete,
  bool reduced = false,
}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reduced),
    child: Scaffold(
      body: LaunchIntro(ready: ready, onComplete: complete),
    ),
  ),
);

void main() {
  testWidgets('waits for the native splash to release the first frame', (
    tester,
  ) async {
    final visible = Completer<void>();
    var completed = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LaunchIntro(
            ready: true,
            startAfter: visible.future,
            onComplete: () => completed++,
          ),
        ),
      ),
    );
    await loadArtwork(tester);
    await tester.pump(const Duration(seconds: 4));
    final paint = tester.widget<CustomPaint>(
      find.byKey(const ValueKey('launch-artwork')),
    );
    expect((paint.painter! as LaunchArtwork).progress, 0);
    expect(completed, 0);
    visible.complete();
    await tester.pumpAndSettle();
    expect(completed, 1);
  });
  for (final size in [const Size(320, 568), const Size(844, 390)]) {
    testWidgets('fits portrait and landscape $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(host(ready: true, complete: () {}));
      await loadArtwork(tester);
      final bounds = tester.getRect(
        find.byKey(const ValueKey('launch-artwork')),
      );
      expect(bounds.left, greaterThanOrEqualTo(0));
      expect(bounds.right, lessThanOrEqualTo(size.width));
      expect(bounds.top, greaterThanOrEqualTo(0));
      expect(bounds.bottom, lessThanOrEqualTo(size.height));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('finishes the cut, waits for the site, then reveals once', (
    tester,
  ) async {
    var completed = 0;
    await tester.pumpWidget(host(ready: false, complete: () => completed++));
    await loadArtwork(tester);
    await tester.pump(const Duration(seconds: 3));
    expect(completed, 0);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpWidget(host(ready: true, complete: () => completed++));
    await tester.pumpAndSettle();
    expect(completed, 1);
    await tester.pump(const Duration(seconds: 2));
    expect(completed, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a fast page cannot skip the animation', (tester) async {
    var completed = 0;
    await tester.pumpWidget(host(ready: true, complete: () => completed++));
    await loadArtwork(tester);
    await tester.pump(const Duration(milliseconds: 1200));
    expect(completed, 0);
    await tester.pumpAndSettle();
    expect(completed, 1);
  });

  testWidgets(
    'reduced motion waits for readiness without a cutting animation',
    (tester) async {
      var completed = 0;
      await tester.pumpWidget(
        host(ready: false, reduced: true, complete: () => completed++),
      );
      await loadArtwork(tester);
      await tester.pump();
      final paint = tester.widget<CustomPaint>(
        find.byKey(const ValueKey('launch-artwork')),
      );
      expect((paint.painter! as LaunchArtwork).progress, 0);
      expect(completed, 0);
      await tester.pumpWidget(
        host(ready: true, reduced: true, complete: () => completed++),
      );
      await tester.pumpAndSettle();
      expect(completed, 1);
    },
  );

  testWidgets('disposal during the animation cancels callbacks', (
    tester,
  ) async {
    var completed = 0;
    await tester.pumpWidget(host(ready: true, complete: () => completed++));
    await loadArtwork(tester);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 5));
    expect(completed, 0);
    expect(tester.takeException(), isNull);
  });

  for (final phase in {'start': 0.0, 'cut': .52, 'split': 1.0}.entries) {
    testWidgets('brand artwork ${phase.key}', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final logo = await tester.runAsync(() async {
        final bytes = await rootBundle.load('assets/brand/logo.png');
        final codec = await ui.instantiateImageCodec(
          bytes.buffer.asUint8List(),
        );
        final frame = await codec.getNextFrame();
        codec.dispose();
        return frame.image;
      });
      addTearDown(() => logo!.dispose());
      await tester.pumpWidget(
        MaterialApp(
          home: RepaintBoundary(
            key: const ValueKey('frame'),
            child: Scaffold(
              backgroundColor: Colors.white,
              body: Center(
                child: CustomPaint(
                  size: const Size(342, 171),
                  painter: LaunchArtwork(
                    logo: logo,
                    progress: phase.value,
                    reveal: 0,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await expectLater(
        find.byKey(const ValueKey('frame')),
        matchesGoldenFile('goldens/intro-${phase.key}.png'),
      );
    });
  }
}
