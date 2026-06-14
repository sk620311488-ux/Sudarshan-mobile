import 'package:flutter/material.dart';

class PaymentFailureScreen extends StatelessWidget {
  final VoidCallback onRetry;
  final VoidCallback onContact;
  const PaymentFailureScreen({super.key, required this.onRetry, required this.onContact});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.close_rounded, size: 110, color: Colors.redAccent),
              const SizedBox(height: 12),
              const Text('Payment Failed', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 18),
              ElevatedButton(onPressed: onRetry, child: const Text('Retry Payment')),
              TextButton(onPressed: onContact, child: const Text('Contact Support')),
            ],
          ),
        ),
      ),
    );
  }
}
