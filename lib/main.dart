import 'dart:async';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import 'navigation_policy.dart';
import 'app_chrome.dart';

const brandGreen = Color(0xFFB8D057);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const ElTahiApp());
}

class ElTahiApp extends StatelessWidget {
  const ElTahiApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'elTahi',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: brandGreen),
      scaffoldBackgroundColor: Colors.white,
      useMaterial3: true,
    ),
    home: const WebsiteScreen(),
  );
}

class WebsiteScreen extends StatefulWidget {
  const WebsiteScreen({super.key});
  @override
  State<WebsiteScreen> createState() => _WebsiteScreenState();
}

class _WebsiteScreenState extends State<WebsiteScreen> {
  late final WebViewController _controller;
  Timer? _timeout;
  bool _failed = false;
  bool _timedOut = false;
  int _progress = 0;
  String _retryUrl = 'https://www.eltahi.com/';

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) async {
            final uri = Uri.tryParse(request.url);
            if (uri != null && isWebsiteUrl(uri)) {
              return NavigationDecision.navigate;
            }
            if (request.isMainFrame && uri != null && isExternalUrl(uri)) {
              try {
                final opened = await launchUrl(
                  uri,
                  mode: LaunchMode.externalApplication,
                );
                if (!opened) throw StateError('External link was not opened');
              } catch (_) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Unable to open this link.')),
                  );
                }
              }
            }
            return NavigationDecision.prevent;
          },
          onProgress: (progress) {
            if (mounted) setState(() => _progress = progress);
          },
          onPageStarted: (url) {
            _timeout?.cancel();
            _timedOut = false;
            if (isWebsiteUrl(Uri.parse(url))) _retryUrl = url;
            if (mounted) {
              setState(() {
                _failed = false;
                _progress = 0;
              });
            }
            _timeout = Timer(const Duration(seconds: 60), () {
              if (mounted && _progress < 100) {
                setState(() {
                  _failed = true;
                  _timedOut = true;
                });
              }
            });
          },
          onPageFinished: (_) {
            _timeout?.cancel();
            if (mounted) {
              setState(() {
                _progress = 100;
                if (_timedOut) {
                  _failed = false;
                  _timedOut = false;
                }
              });
            }
          },
          onWebResourceError: (error) {
            if (error.isForMainFrame == true) {
              _timeout?.cancel();
              _timedOut = false;
              if (mounted) setState(() => _failed = true);
            }
          },
          onHttpError: (error) {
            if (error.request?.uri.toString() == _retryUrl &&
                (error.response?.statusCode ?? 0) >= 400) {
              _timeout?.cancel();
              _timedOut = false;
              if (mounted) setState(() => _failed = true);
            }
          },
        ),
      );
    _prepare();
  }

  Future<void> _prepare() async {
    await _controller.setOnJavaScriptAlertDialog((request) async {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (_) => AppMessageDialog(message: request.message),
      );
    });
    await _controller.setOnJavaScriptConfirmDialog((request) async {
      if (!mounted) return false;
      return await showDialog<bool>(
            context: context,
            builder: (_) => AppMessageDialog(
              message: request.message,
              kind: AppDialogKind.confirm,
            ),
          ) ??
          false;
    });
    await _controller.setOnJavaScriptTextInputDialog((request) async {
      if (!mounted) return '';
      return await showDialog<String>(
            context: context,
            builder: (_) => AppMessageDialog(
              message: request.message,
              kind: AppDialogKind.prompt,
              initialText: request.defaultText ?? '',
            ),
          ) ??
          '';
    });
    await _controller.setOverScrollMode(WebViewOverScrollMode.never);
    final platform = _controller.platform;
    if (platform is AndroidWebViewController) {
      await platform.setOnShowFileSelector((params) async {
        // Access is limited to files explicitly chosen in the system picker.
        final types = params.acceptTypes.where((s) => s.contains('/')).toList();
        final groups = types.isEmpty
            ? <XTypeGroup>[]
            : [XTypeGroup(mimeTypes: types)];
        try {
          final files = params.mode == FileSelectorMode.openMultiple
              ? await openFiles(acceptedTypeGroups: groups)
              : [await openFile(acceptedTypeGroups: groups)].nonNulls.toList();
          return files.map((file) => Uri.file(file.path).toString()).toList();
        } catch (_) {
          return <String>[];
        }
      });
    }
    if (platform is WebKitWebViewController) {
      await platform.setAllowsBackForwardNavigationGestures(true);
      await platform.setAllowsLinkPreview(false);
    }
    if (mounted) await _controller.loadRequest(Uri.parse(_retryUrl));
  }

  Future<void> _back() async {
    if (await _controller.canGoBack()) {
      await _controller.goBack();
    } else {
      await SystemNavigator.pop();
    }
  }

  @override
  void dispose() {
    _timeout?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop) _back();
    },
    child: Scaffold(
      body: AppLoadingOverlay(
        progress: _progress,
        failed: _failed,
        child: SafeArea(
          child: Stack(
            fit: StackFit.expand,
            children: [
              WebViewWidget(controller: _controller),
              if (_failed)
                ColoredBox(
                  color: Colors.white,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'assets/icon/app-icon.png',
                            width: 96,
                            height: 96,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Unable to load elTahi',
                            style: TextStyle(fontSize: 21),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Check your connection and try again.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: brandGreen,
                              foregroundColor: Colors.black87,
                            ),
                            onPressed: () {
                              setState(() {
                                _failed = false;
                                _progress = 0;
                              });
                              _controller.loadRequest(Uri.parse(_retryUrl));
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}
