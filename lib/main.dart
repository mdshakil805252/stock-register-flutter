import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const StockApp());
}

class StockApp extends StatelessWidget {
  const StockApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stock Register',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0B0F17),
      ),
      home: const StockWebViewScreen(),
    );
  }
}

class StockWebViewScreen extends StatefulWidget {
  const StockWebViewScreen({super.key});

  @override
  State<StockWebViewScreen> createState() => _StockWebViewScreenState();
}

class _StockWebViewScreenState extends State<StockWebViewScreen> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF0B0F17))
      ..loadRequest(
        Uri.parse('https://mdshakil805252.github.io/my-stock-app/'),
      );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (await _controller.canGoBack()) {
          _controller.goBack();
          return false;
        }
        return true;
      },
      child: Scaffold(
        body: SafeArea(
          child: WebViewWidget(controller: _controller),
        ),
      ),
    );
  }
}
