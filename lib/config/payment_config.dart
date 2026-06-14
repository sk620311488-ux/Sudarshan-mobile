class PaymentConfig {
  // Toggle demo/test mode
  static const bool testMode = true;

  // Base payment website (change to real site later)
  static const String paymentWebsiteUrl = 'https://your-payment-website.com/pay';
  static const String successUrl = 'https://your-payment-website.com/success';
  static const String failedUrl = 'https://your-payment-website.com/failure';
  static const String supportEmail = 'support@your-payment-website.com';
}
