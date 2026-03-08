// lib/services/payment_service.dart
// All Stripe & Supabase payment logic — UI never touches Stripe keys directly

import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/payment_model.dart';

class PaymentService {
  PaymentService._();
  static final instance = PaymentService._();

  final _supabase = Supabase.instance.client;

  // ─── Stripe Initialization ──────────────────────────────────────────────────

  /// Call once in main() before runApp()
  /// publishableKey is safe to have in Flutter — it's public
  static void init({required String stripePublishableKey}) {
    Stripe.publishableKey = stripePublishableKey;
    Stripe.merchantIdentifier = 'merchant.com.yourapp'; // for Apple Pay
    Stripe.instance.applySettings();
  }

  // ─── TOKEN PAYMENT ──────────────────────────────────────────────────────────

  /// Initiates the non-refundable token payment to lock a farm booking.
  /// Returns true if payment succeeded.
  Future<PaymentResult> payToken({
    required String bookingId,
    required String farmId,
    required String farmName,
    required double tokenAmount,
    required double totalAmount,
    required DateTime bookingDate,
  }) async {
    try {
      // 1. Call Edge Function to create PaymentIntent (secret stays server-side)
      final response = await _supabase.functions.invoke(
        'create-payment-intent',
        body: {
          'booking_id': bookingId,
          'farm_id': farmId,
          'farm_name': farmName,
          'token_amount': tokenAmount,
          'total_amount': totalAmount,
          'booking_date': bookingDate.toIso8601String().split('T').first,
        },
      );

      if (response.status != 200) {
        final err = (response.data as Map?)?['error'] ?? 'Unknown server error';
        return PaymentResult.failure(err.toString());
      }

      final data = response.data as Map<String, dynamic>;
      final clientSecret = data['client_secret'] as String?;
      if (clientSecret == null) return PaymentResult.failure('No client secret returned');

      // 2. Initialize payment sheet with the client secret
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'WeddingFarm',
          // Billing details collection
          billingDetailsCollectionConfiguration: const BillingDetailsCollectionConfiguration(
            name: CollectionMode.always,
            phone: CollectionMode.always,
          ),
          // Custom appearance
          appearance: const PaymentSheetAppearance(
            colors: PaymentSheetAppearanceColors(
              primary: Color(0xFF8B5E3C), // warm brown for wedding theme
            ),
            shapes: PaymentSheetShape(
              borderRadius: 12,
            ),
          ),
          // Pre-fill customer details if available
          style: ThemeMode.light,
        ),
      );

      // 3. Present the Stripe Payment Sheet to user
      await Stripe.instance.presentPaymentSheet();

      // 4. If we reach here without exception, payment was initiated
      //    Actual confirmation happens via webhook — but we can poll too
      return PaymentResult.success(
        paymentIntentId: data['payment_intent_id'] as String,
        amount: tokenAmount,
        type: PaymentType.token,
      );
    } on StripeException catch (e) {
      if (e.error.code == FailureCode.Canceled) {
        return PaymentResult.cancelled();
      }
      return PaymentResult.failure(
        e.error.localizedMessage ?? e.error.message ?? 'Payment failed',
      );
    } catch (e) {
      debugPrint('payToken error: $e');
      return PaymentResult.failure(e.toString());
    }
  }

  // ─── FINAL PAYMENT ──────────────────────────────────────────────────────────

  /// Initiates the final (remaining) payment for a confirmed booking.
  /// Token amount is automatically deducted server-side.
  Future<PaymentResult> payFinal({required String bookingId}) async {
    try {
      // 1. Ask server for PaymentIntent (it calculates total - token)
      final response = await _supabase.functions.invoke(
        'create-final-payment-intent',
        body: {'booking_id': bookingId},
      );

      if (response.status != 200) {
        final err = (response.data as Map?)?['error'] ?? 'Server error';
        return PaymentResult.failure(err.toString());
      }

      final data = response.data as Map<String, dynamic>;
      final clientSecret = data['client_secret'] as String?;
      if (clientSecret == null) return PaymentResult.failure('No client secret returned');

      final remainingAmount = (data['amount'] as num).toDouble();
      final tokenPaid = (data['token_paid'] as num).toDouble();

      // 2. Initialize payment sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'WeddingFarm',
          // Show breakdown in description
          billingDetailsCollectionConfiguration: const BillingDetailsCollectionConfiguration(
            name: CollectionMode.always,
          ),
          appearance: const PaymentSheetAppearance(
            colors: PaymentSheetAppearanceColors(
              primary: Color(0xFF8B5E3C),
            ),
            shapes: PaymentSheetShape(borderRadius: 12),
          ),
          style: ThemeMode.light,
        ),
      );

      // 3. Present to user
      await Stripe.instance.presentPaymentSheet();

      return PaymentResult.success(
        paymentIntentId: data['payment_intent_id'] as String,
        amount: remainingAmount,
        type: PaymentType.final_,
        extraData: {'token_paid': tokenPaid},
      );
    } on StripeException catch (e) {
      if (e.error.code == FailureCode.Canceled) return PaymentResult.cancelled();
      return PaymentResult.failure(
        e.error.localizedMessage ?? e.error.message ?? 'Payment failed',
      );
    } catch (e) {
      debugPrint('payFinal error: $e');
      return PaymentResult.failure(e.toString());
    }
  }

  // ─── PAYMENT HISTORY ────────────────────────────────────────────────────────

  /// Fetch all payments for the current user (customer view)
  Future<List<PaymentModel>> getMyPayments() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    final response = await _supabase.from('payment_history').select().eq('customer_id', userId).order('created_at', ascending: false);

    return (response as List).map((e) => PaymentModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Fetch payments for a specific booking
  Future<List<PaymentModel>> getBookingPayments(String bookingId) async {
    final response = await _supabase.from('payments').select().eq('booking_id', bookingId).order('created_at', ascending: true);

    return (response as List).map((e) => PaymentModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Fetch payments received by an owner (for their farms)
  Future<List<PaymentModel>> getOwnerPayments() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    final response = await _supabase
        .from('payment_history')
        .select()
        .eq('owner_id', userId)
        // ✅ FIX: your schema uses 'success' not 'succeeded'
        .eq('status', 'success')
        .order('created_at', ascending: false);

    return (response as List).map((e) => PaymentModel.fromJson(e as Map<String, dynamic>)).toList();
  }
}

// ─── Result wrapper ──────────────────────────────────────────────────────────

enum PaymentResultStatus { success, failure, cancelled }

class PaymentResult {
  final PaymentResultStatus status;
  final String? paymentIntentId;
  final double? amount;
  final PaymentType? type;
  final String? errorMessage;
  final Map<String, dynamic>? extraData;

  const PaymentResult._({
    required this.status,
    this.paymentIntentId,
    this.amount,
    this.type,
    this.errorMessage,
    this.extraData,
  });

  factory PaymentResult.success({
    required String paymentIntentId,
    required double amount,
    required PaymentType type,
    Map<String, dynamic>? extraData,
  }) =>
      PaymentResult._(
        status: PaymentResultStatus.success,
        paymentIntentId: paymentIntentId,
        amount: amount,
        type: type,
        extraData: extraData,
      );

  factory PaymentResult.failure(String message) => PaymentResult._(
        status: PaymentResultStatus.failure,
        errorMessage: message,
      );

  factory PaymentResult.cancelled() => const PaymentResult._(status: PaymentResultStatus.cancelled);

  bool get isSuccess => status == PaymentResultStatus.success;
  bool get isCancelled => status == PaymentResultStatus.cancelled;
  bool get isFailure => status == PaymentResultStatus.failure;
}
