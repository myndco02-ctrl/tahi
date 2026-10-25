import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/launch_golden_comparator.dart';

Future<Uint8List> sample({int changedPixels = 0, int width = 16}) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawColor(const ui.Color(0xFFFFFFFF), ui.BlendMode.src);
  final paint = ui.Paint()
    ..color = const ui.Color(0xFF000000)
    ..isAntiAlias = false;
  for (var i = 0; i < changedPixels; i++) {
    canvas.drawRect(ui.Rect.fromLTWH(i.toDouble(), 0, 1, 1), paint);
  }
  final picture = recorder.endRecording();
  final image = await picture.toImage(width, 16);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  picture.dispose();
  return data!.buffer.asUint8List();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late LaunchGoldenComparator comparator;
  final golden = Uri.parse('reference.png');

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('eltahi-golden-');
    comparator = LaunchGoldenComparator(
      directory.uri.resolve('sample_test.dart'),
    );
    await File.fromUri(
      directory.uri.resolve(golden.path),
    ).writeAsBytes(await sample());
  });
  tearDown(() => directory.delete(recursive: true));

  test('accepts an exact match', () async {
    expect(await comparator.compare(await sample(), golden), isTrue);
  });
  test('accepts the observed three-pixel macOS variation', () async {
    expect(
      await comparator.compare(await sample(changedPixels: 3), golden),
      isTrue,
    );
  });
  test('accepts at most five differing pixels', () async {
    expect(
      await comparator.compare(await sample(changedPixels: 5), golden),
      isTrue,
    );
  });
  test('rejects six pixels and writes a diagnostic image', () async {
    await expectLater(
      comparator.compare(await sample(changedPixels: 6), golden),
      throwsA(isA<FlutterError>()),
    );
    expect(
      Directory.fromUri(directory.uri.resolve('failures/')).existsSync(),
      isTrue,
    );
  });
  test('rejects different image dimensions', () async {
    await expectLater(
      comparator.compare(await sample(width: 17), golden),
      throwsA(isA<FlutterError>()),
    );
  });
}
