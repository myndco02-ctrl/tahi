import 'package:flutter/material.dart';

class AppLoadingOverlay extends StatelessWidget {
  const AppLoadingOverlay({
    super.key,
    required this.progress,
    required this.failed,
    required this.child,
  });

  final int progress;
  final bool failed;
  final Widget child;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      child,
      if (progress < 100 && !failed)
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: LinearProgressIndicator(
              value: progress == 0 ? null : progress / 100,
              color: const Color(0xFFB8D057),
              backgroundColor: Colors.transparent,
              minHeight: 2,
              semanticsLabel: 'Loading',
            ),
          ),
        ),
    ],
  );
}

enum AppDialogKind { alert, confirm, prompt }

class AppMessageDialog extends StatefulWidget {
  const AppMessageDialog({
    super.key,
    required this.message,
    this.kind = AppDialogKind.alert,
    this.initialText = '',
  });

  final String message;
  final AppDialogKind kind;
  final String initialText;

  @override
  State<AppMessageDialog> createState() => _AppMessageDialogState();
}

class _AppMessageDialogState extends State<AppMessageDialog> {
  late final _text = TextEditingController(text: widget.initialText);

  void _accept() {
    switch (widget.kind) {
      case AppDialogKind.alert:
        Navigator.pop(context);
      case AppDialogKind.confirm:
        Navigator.pop(context, true);
      case AppDialogKind.prompt:
        Navigator.pop(context, _text.text);
    }
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog.adaptive(
    title: const Text('elTahi'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.message),
          if (widget.kind == AppDialogKind.prompt) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _text,
              autofocus: true,
              onSubmitted: (_) => _accept(),
            ),
          ],
        ],
      ),
    ),
    actions: [
      if (widget.kind != AppDialogKind.alert)
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      TextButton(onPressed: _accept, child: const Text('OK')),
    ],
  );
}
