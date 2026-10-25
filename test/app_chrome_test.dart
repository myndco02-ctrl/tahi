import 'package:eltahi_demo/app_chrome.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget shell({int progress = 25, bool failed = false}) => MaterialApp(
  home: MediaQuery(
    data: const MediaQueryData(padding: EdgeInsets.only(top: 32, bottom: 24)),
    child: Scaffold(
      body: AppLoadingOverlay(
        progress: progress,
        failed: failed,
        child: const SafeArea(child: SizedBox.expand(key: Key('content'))),
      ),
    ),
  ),
);

Future<({Future<T?> result})> openDialog<T>(
  WidgetTester tester,
  AppMessageDialog dialog,
) async {
  late BuildContext context;
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (value) {
          context = value;
          return const Scaffold();
        },
      ),
    ),
  );
  return (result: showDialog<T>(context: context, builder: (_) => dialog));
}

void main() {
  testWidgets('content opens immediately; loading is above the safe area', (
    tester,
  ) async {
    await tester.pumpWidget(shell());
    expect(find.byKey(const Key('content')), findsOneWidget);
    expect(tester.getTopLeft(find.byKey(const Key('content'))).dy, 32);
    expect(tester.getTopLeft(find.byType(LinearProgressIndicator)).dy, 0);
    expect(tester.getSize(find.byType(LinearProgressIndicator)).height, 2);
    expect(find.textContaining('eltahi.com'), findsNothing);
  });

  testWidgets('loading disappears on completion and errors', (tester) async {
    await tester.pumpWidget(shell(progress: 100));
    expect(find.byType(LinearProgressIndicator), findsNothing);
    await tester.pumpWidget(shell(failed: true));
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });

  testWidgets('zero progress has an indeterminate loading line', (
    tester,
  ) async {
    await tester.pumpWidget(shell(progress: 0));
    expect(
      tester
          .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
          .value,
      isNull,
    );
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('alert uses the app name and dismisses', (tester) async {
    final result = await openDialog<void>(
      tester,
      const AppMessageDialog(message: 'Saved.'),
    );
    await tester.pumpAndSettle();
    expect(find.text('elTahi'), findsOneWidget);
    expect(find.text('Saved.'), findsOneWidget);
    expect(find.textContaining('eltahi.com'), findsNothing);
    expect(find.text('Cancel'), findsNothing);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await result.result;
    expect(find.byType(AppMessageDialog), findsNothing);
  });

  testWidgets('confirm returns true only after OK', (tester) async {
    final result = await openDialog<bool>(
      tester,
      const AppMessageDialog(message: 'Continue?', kind: AppDialogKind.confirm),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(await result.result, isTrue);
  });

  testWidgets('confirm cancellation does not approve the action', (
    tester,
  ) async {
    final result = await openDialog<bool>(
      tester,
      const AppMessageDialog(message: 'Delete?', kind: AppDialogKind.confirm),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(await result.result, isNull);
  });

  testWidgets('prompt preserves initial text and returns edits', (
    tester,
  ) async {
    final result = await openDialog<String>(
      tester,
      const AppMessageDialog(
        message: 'Name',
        kind: AppDialogKind.prompt,
        initialText: 'Old',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Old'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'New');
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(await result.result, 'New');
  });

  testWidgets('prompt cancellation discards input', (tester) async {
    final result = await openDialog<String>(
      tester,
      const AppMessageDialog(message: 'Name', kind: AppDialogKind.prompt),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Discard');
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(await result.result, isNull);
  });
}
