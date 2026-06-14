import 'package:flutter/material.dart';
import 'package:flutter_custom_tabs/flutter_custom_tabs.dart';
import '../screens/payment_webview_screen.dart';
import '../config/payment_config.dart';

class PaymentLauncher {
  static Future<bool?> launchPayment(BuildContext context, String url) async {
    try {
      await launchUrl(
        Uri.parse(url),
        customTabsOptions: CustomTabsOptions(
          colorSchemes: CustomTabsColorSchemes.defaults(
            toolbarColor: Colors.white,
          ),
          shareState: CustomTabsShareState.on,
          showTitle: true,
        ),
      );

      if (!context.mounted) return null;
      final choice = await showDialog<String?>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Payment opened'),
          content: const Text('Complete payment in browser.\n\nIf completed, tap "I completed payment". Or open inside app for automatic detection.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, 'open_in_app'), child: const Text('Open inside app')),
            TextButton(onPressed: () => Navigator.pop(ctx, 'completed'), child: const Text('I completed payment')),
            TextButton(onPressed: () => Navigator.pop(ctx, 'cancel'), child: const Text('Cancel')),
          ],
        ),
      );

      if (choice == 'open_in_app') {
        if (!context.mounted) return null;
        final res = await Navigator.of(context).push<bool?>(
          MaterialPageRoute(builder: (_) => PaymentWebviewScreen(initialUrl: url)),
        );
        return res;
      }

      if (choice == 'completed') {
        return PaymentConfig.testMode ? true : null;
      }

      return null;
    } catch (e) {
      if (!context.mounted) return null;
      final res = await Navigator.of(context).push<bool?>(
        MaterialPageRoute(builder: (_) => PaymentWebviewScreen(initialUrl: url)),
      );
      return res;
    }
  }
}
