import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class PaymentSuccessScreen extends StatelessWidget {
  const PaymentSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // animated checkmark (local Lottie can be used later)
              LottieBuilder.asset('assets/lottie/success.json', width: 180, height: 180, repeat: false),
              const SizedBox(height: 12),
              const Text('Premium Activated', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Continue'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
