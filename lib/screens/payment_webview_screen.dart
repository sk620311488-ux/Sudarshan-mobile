import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/payment_config.dart';
import '../services/premium_service.dart';

class PaymentWebviewScreen extends StatefulWidget {
  final String initialUrl;
  const PaymentWebviewScreen({super.key, required this.initialUrl});

  @override
  State<PaymentWebviewScreen> createState() => _PaymentWebviewScreenState();
}

class _PaymentWebviewScreenState extends State<PaymentWebviewScreen> {
  final PremiumService _premiumService = PremiumService();
  late final WebViewController _controller;
  double _progress = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();

    if (kIsWeb) {
      _launchWebPayment();
      return;
    }

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (url) {
          if (mounted) setState(() => _loading = true);
        },
        onProgress: (progress) {
          if (mounted) setState(() => _progress = progress / 100.0);
        },
        onPageFinished: (url) async {
          if (mounted) setState(() => _loading = false);
          if (url.startsWith(PaymentConfig.successUrl)) {
            await _premiumService.setPremium(true);
            if (mounted) Navigator.of(context).pop(true);
          } else if (url.startsWith(PaymentConfig.failedUrl)) {
            if (mounted) Navigator.of(context).pop(false);
          }
        },
        onNavigationRequest: (request) {
          final uri = Uri.parse(request.url);
          if (uri.scheme == 'http' || uri.scheme == 'https') {
            return NavigationDecision.navigate;
          }
          return NavigationDecision.prevent;
        },
      ))
      ..loadRequest(Uri.parse(widget.initialUrl));
  }

  Future<void> _launchWebPayment() async {
    final uri = Uri.parse(widget.initialUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (mounted) Navigator.pop(context, null);
    }
  }

  Future<void> _openInBrowser() async {
    final uri = Uri.parse(widget.initialUrl);
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(
        title: const Row(children: [Icon(Icons.lock, size: 18), SizedBox(width: 8), Text('Secure Payment')]),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => _controller.reload()),
          IconButton(icon: const Icon(Icons.open_in_browser), onPressed: _openInBrowser),
        ],
      ),
      body: Column(
        children: [
          LinearProgressIndicator(value: _loading ? _progress : 0, minHeight: 3),
          Expanded(
            child: WebViewWidget(controller: _controller),
          ),
        ],
      ),
    );
  }
}
