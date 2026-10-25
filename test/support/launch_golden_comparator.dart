import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// Accommodates the 2-3 rasterization pixels observed on the macOS CI runner.
/// An absolute limit prevents the large white background from hiding regressions.
class LaunchGoldenComparator extends LocalFileComparator {
  LaunchGoldenComparator(super.testFile);

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );
    try {
      if (result.passed) return true;
      final actual = result.diffs?['testImage'];
      final expected = result.diffs?['masterImage'];
      if (actual != null &&
          expected != null &&
          actual.width == expected.width &&
          actual.height == expected.height) {
        final changedPixels =
            (result.diffPercent * actual.width * actual.height).round();
        if (changedPixels <= 5) return true;
      }
      throw FlutterError(await generateFailureOutput(result, golden, basedir));
    } finally {
      result.dispose();
    }
  }
}
