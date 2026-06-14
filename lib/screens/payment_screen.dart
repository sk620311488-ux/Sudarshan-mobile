import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/soft_card.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _selectedPlan = 'monthly'; // 'monthly', 'yearly'

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sudarshan Pro'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.stars_rounded,
                      size: 56,
                      color: AppColors.accent,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Unlock Pro Features',
                      style: theme.textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Get unlimited access to all tests & study materials',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Features Section
              SoftCard(
                color: AppColors.tealSoft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '✨ Pro Features',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    ...[
                      'Unlimited Full Tests Access',
                      'Unlimited Practice Questions',
                      'Detailed Solutions & Explanations',
                      'Performance Analytics & Reports',
                      'Custom Study Plans',
                      'Ad-Free Experience',
                      'Priority Support',
                      'Offline Study Materials',
                    ].map((feature) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.green,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                feature,
                                style: theme.textTheme.bodyLarge,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Plan Selection Toggle
              Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? AppColors.lineDark : AppColors.line,
                  ),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildPlanButton(
                        'Monthly',
                        'monthly',
                        theme,
                        isDark,
                      ),
                    ),
                    Expanded(
                      child: _buildPlanButton(
                        'Yearly',
                        'yearly',
                        theme,
                        isDark,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Pricing Plans
              if (_selectedPlan == 'monthly')
                _buildMonthlyPlan(theme, isDark)
              else
                _buildYearlyPlan(theme, isDark),

              const SizedBox(height: 24),

              // Payment Methods
              Text(
                'Payment Methods',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              _buildPaymentMethod(
                'Credit/Debit Card',
                'Visa, Mastercard, RuPay',
                Icons.credit_card_rounded,
                theme,
                isDark,
              ),
              const SizedBox(height: 10),
              _buildPaymentMethod(
                'UPI',
                'Google Pay, PhonePe, Paytm',
                Icons.phone_android_rounded,
                theme,
                isDark,
              ),
              const SizedBox(height: 10),
              _buildPaymentMethod(
                'Net Banking',
                'All major Indian banks',
                Icons.account_balance_rounded,
                theme,
                isDark,
              ),

              const SizedBox(height: 32),

              // Terms & Conditions
              SoftCard(
                color: AppColors.blueSoft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payment Policy',
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• 7-day money-back guarantee\n'
                      '• Secure payment processing\n'
                      '• Automatic renewal (can be cancelled anytime)\n'
                      '• No hidden charges',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlanButton(
    String label,
    String value,
    ThemeData theme,
    bool isDark,
  ) {
    final isSelected = _selectedPlan == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPlan = value;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accent
              : (isDark ? AppColors.surfaceDark : AppColors.surface),
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: isSelected ? AppColors.white : theme.colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMonthlyPlan(ThemeData theme, bool isDark) {
    return SoftCard(
      color: AppColors.yellowSoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Monthly Plan',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Renews every month',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹99',
                    style: theme.textTheme.headlineMedium!.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    '/month',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // Payment action will be implemented later
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Payment gateway coming soon')),
                );
              },
              child: const Text('Subscribe Now'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYearlyPlan(ThemeData theme, bool isDark) {
    return Stack(
      children: [
        SoftCard(
          color: AppColors.tealSoft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Yearly Plan',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Best Value • Save 30%',
                        style: theme.textTheme.bodySmall!.copyWith(
                          color: AppColors.green,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹799',
                        style: theme.textTheme.headlineMedium!.copyWith(
                          color: AppColors.teal,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '/year',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                decoration: BoxDecoration(
                  color: AppColors.greenSoft,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.savings_rounded,
                      size: 16,
                      color: AppColors.green,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Save ₹390 per year',
                      style: theme.textTheme.bodySmall!.copyWith(
                        color: AppColors.green,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Payment action will be implemented later
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Payment gateway coming soon')),
                    );
                  },
                  child: const Text('Subscribe Now'),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: -8,
          right: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'MOST POPULAR',
              style: theme.textTheme.labelLarge!.copyWith(
                color: AppColors.white,
                fontSize: 11,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethod(
    String name,
    String description,
    IconData icon,
    ThemeData theme,
    bool isDark,
  ) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: isDark ? AppColors.lineDark : AppColors.line,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: AppColors.accent,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: theme.textTheme.titleSmall,
                ),
                Text(
                  description,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 16,
            color: isDark ? AppColors.mutedDark : AppColors.muted,
          ),
        ],
      ),
    );
  }
}
