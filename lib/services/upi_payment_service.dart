import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UPIPaymentService {
  final _supabase = Supabase.instance.client;

  /// Fetch owner's UPI details from the profiles table.
  Future<Map<String, dynamic>> getOwnerUpiDetails(String ownerId) async {
    final response = await _supabase.from('profiles').select('upi_id, upi_name, upi_qr_url').eq('id', ownerId).maybeSingle();

    return response ?? {};
  }

  /// Update owner's UPI details and QR code.
  Future<void> updateOwnerUpiDetails({
    required String ownerId,
    required String upiId,
    required String upiName,
    File? qrCodeFile,
  }) async {
    String? qrUrl;

    if (qrCodeFile != null) {
      // 1. Upload to Supabase Storage Directly
      final storagePath = 'qr_codes/$ownerId.jpg';
      await _supabase.storage.from('payment-screenshots').upload(
            storagePath,
            qrCodeFile,
            fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
          );
      qrUrl = storagePath;
    }

    // 3. Update profile record
    final Map<String, dynamic> updateData = {
      'upi_id': upiId,
      'upi_name': upiName,
    };
    if (qrUrl != null) {
      updateData['upi_qr_url'] = qrUrl;
    }

    await _supabase.from('profiles').update(updateData).eq('id', ownerId);
  }

  /// Submit a new UPI payment request.
  Future<void> submitUpiPaymentRequest({
    required String bookingId,
    required String customerId,
    required String ownerId,
    required String farmId,
    required String paymentType, // 'token' or 'full'
    required double amount,
    String? upiRefNumber,
    required File screenshotFile,
  }) async {
    // 🛡️ Guard against null auth session
    final user = _supabase.auth.currentUser;
    if (user == null) {
      debugPrint('Submit UPI Failure: auth.currentUser is null');
      throw Exception("User session expired. Please log in again.");
    }

    // 🎯 Explicitly use auth.uid() as suggested by DB agent
    final authUserId = user.id;
    debugPrint('Submitting UPI Payment: authUser=$authUserId, targetCustomer=$customerId');

    try {
      // 1. Upload to Supabase Storage Directly
      final storagePath = '$authUserId/${bookingId}_$paymentType.jpg';
      debugPrint('Uploading screenshot to: $storagePath');

      await _supabase.storage.from('payment-screenshots').upload(
            storagePath,
            screenshotFile,
            fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
          );

      final screenshotUrl = storagePath;
      debugPrint('Upload success: $screenshotUrl');

      // 2. Insert into upi_payment_requests table
      // IMPORTANT: customer_id MUST be auth.uid() for RLS
      // We use _supabase.auth.currentUser!.id INLINE to be 100% sure we satisfy RLS check
      final insertData = {
        'booking_id': bookingId,
        'customer_id': _supabase.auth.currentUser!.id, // 🛡️ Directly from SDK for RLS
        'owner_id': ownerId,
        'farm_id': farmId,
        'payment_type': paymentType,
        'amount': amount,
        'upi_ref_number': upiRefNumber,
        'screenshot_url': screenshotUrl,
        'status': 'pending',
      };

      debugPrint('DB Insert data: $insertData');

      await _supabase.from('upi_payment_requests').insert(insertData);
      debugPrint('DB Insert success');

      // 3. Insert notification for owner
      await _supabase.from('notifications').insert({
        'user_id': ownerId,
        'booking_id': bookingId,
        'type': 'upi_payment_pending',
        'read': false,
      });
      debugPrint('Notification success');
    } catch (e) {
      debugPrint('UPI Payment Error Chain: $e');
      rethrow;
    }
  }

  /// Fetch all pending UPI payment requests for an owner.
  Future<List<Map<String, dynamic>>> getPendingVerifications(String ownerId) async {
    final response =
        await _supabase.from('upi_payment_requests').select('*, farms(name), profiles:customer_id(full_name)').eq('owner_id', ownerId).eq('status', 'pending').order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Get a signed URL for a screenshot (expires in 1 hour).
  Future<String> getScreenshotSignedUrl(String path) async {
    try {
      return await _supabase.storage.from('payment-screenshots').createSignedUrl(path, 3600);
    } catch (e) {
      debugPrint('Error getting signed URL: $e');
      return '';
    }
  }

  /// Confirm a UPI payment request using Edge Function.
  Future<void> confirmPayment({
    required String requestId,
  }) async {
    final response = await _supabase.functions.invoke(
      'process-payment',
      body: {
        'requestId': requestId,
        'status': 'confirmed',
      },
    );

    if (response.status != 200) {
      throw Exception(response.data['error'] ?? 'Failed to confirm payment');
    }
  }

  /// Reject a UPI payment request using Edge Function.
  Future<void> rejectPayment({
    required String requestId,
    required String reason,
  }) async {
    final response = await _supabase.functions.invoke(
      'process-payment',
      body: {
        'requestId': requestId,
        'status': 'rejected',
        'rejectionReason': reason,
      },
    );

    if (response.status != 200) {
      throw Exception(response.data['error'] ?? 'Failed to reject payment');
    }
  }

  /// Fetch payment history for a specific booking.
  Future<List<Map<String, dynamic>>> getPaymentHistory(String bookingId) async {
    final response = await _supabase.from('upi_payment_requests').select('*').eq('booking_id', bookingId).order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }
}
