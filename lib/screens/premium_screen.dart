import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/payment_config.dart';
import '../services/premium_service.dart';
import '../services/payment_launcher.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  final PremiumService _premiumService = PremiumService();

  Future<void> _startPayment(String plan, double amount) async {
    final url = '${PaymentConfig.paymentWebsiteUrl}?plan=$plan&amount=$amount&test=${PaymentConfig.testMode}';
    final result = await PaymentLauncher.launchPayment(context, url);

    if (result == true) {
      await _premiumService.setPremium(true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Premium activated')));
      }
    } else if (result == false) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment failed')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2A3A4A), Color(0xFF59B6A9)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Icon(Icons.arrow_back, color: Colors.white),
                Icon(Icons.star, color: Colors.white),
              ],
            ),
            const SizedBox(height: 18),
            Center(
              child: Column(
                children: [
                  Icon(Icons.verified, size: 84, color: Colors.yellow.shade700),
                  const SizedBox(height: 12),
                  Text('Sudarshan Pro', style: GoogleFonts.inter(fontSize: 28, color: Colors.white, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      color: Colors.white.withValues(alpha: 0.06),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Premium Benefits', style: theme.textTheme.titleLarge?.copyWith(color: Colors.white)),
                            const SizedBox(height: 12),
                            ...[
                              'Ad-free experience',
                              'Unlimited tests',
                              'AI features',
                              'Faster performance',
                            ].map((t) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(children: [
                                const Icon(Icons.check_circle, color: Colors.greenAccent),
                                const SizedBox(width: 10),
                                Expanded(child: Text(t, style: const TextStyle(color: Colors.white))),
                              ]),
                            )),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(),
                    const SizedBox(height: 20),

                    // Pricing cards
                    Row(
                      children: [
                        Expanded(child: _planCard('Monthly', '₹49', 'monthly', 49)),
                        const SizedBox(width: 12),
                        Expanded(child: _planCard('Quarterly', '₹99', 'quarterly', 99)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _lifetimeCard(),
                    const SizedBox(height: 18),
                    Center(
                      child: ElevatedButton(
                        onPressed: () => _startPayment('monthly', 49),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.yellow.shade700,
                          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('Continue', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(child: Text('By continuing you agree to terms', style: TextStyle(color: Colors.white.withValues(alpha: 0.8)))),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _planCard(String title, String price, String id, double amount) {
    return GestureDetector(
      onTap: () => _startPayment(id, amount),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white.withValues(alpha: 0.06),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 12, spreadRadius: 1)],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(price, style: const TextStyle(color: Colors.yellowAccent, fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text('/plan', style: TextStyle(color: Colors.white.withValues(alpha: 0.8))),
          ],
        ),
      ),
    );
  }

  Widget _lifetimeCard() {
    return GestureDetector(
      onTap: () => _startPayment('lifetime', 199),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.white.withValues(alpha: 0.06),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 12)],
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Lifetime', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text('₹199 • One time', style: TextStyle(color: Colors.white.withValues(alpha: 0.9))),
            ]),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: Colors.yellow.shade700, borderRadius: BorderRadius.circular(10)),
              child: const Text('Best', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }
}
