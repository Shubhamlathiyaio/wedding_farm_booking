class AppConfig {
  AppConfig._();

  static const String supabaseUrl = 'https://kinlzyfrfxrpaypvysbh.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imtpbmx6eWZyZnhycGF5cHZ5c2JoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI2NDI2NDAsImV4cCI6MjA4ODIxODY0MH0.J0NmVPN5AhaANWUAqpYTTL9FSu2kMz0ZP3CKH6I3HAA';

// supabase secrets set STRIPE_SECRET_KEY=sk_test_...
// supabase secrets set STRIPE_WEBHOOK_SECRET=whsec_...

  // Table names
  static const String profilesTable = 'profiles';
  static const String farmsTable = 'farms';
  static const String bookingsTable = 'bookings';
  static const String paymentsTable = 'payments';

  // Edge functions
  static const String confirmTokenPaymentFn = 'confirm-token-payment';
  static const String releaseFarmFn = 'release-farm';
  static const String createPaymentIntentFn = 'create-payment-intent';
  static const String createFinalPaymentIntentFn = 'create-final-payment-intent';
  static const String stripeWebhookFn = 'stripe-webhook';
  static const String processPaymentFn = 'process-payment';
}
