import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

import '../../screens/upi_payment_screen.dart';
import '../../services/upi_payment_service.dart';
import '../data/models/booking_model.dart';
import '../data/models/farm_model.dart';
import '../data/services/booking_service.dart';

class BookingController extends GetxController {
  final BookingService _bookingService = BookingService();
  final UPIPaymentService _upiService = UPIPaymentService();

  final RxList<BookingModel> bookings = <BookingModel>[].obs;
  final RxList<Map<String, dynamic>> paymentHistory = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isProcessing = false.obs;

  // Booking form state
  final RxList<DateTime> selectedDates = <DateTime>[].obs;
  final RxInt guestCount = 50.obs;

  @override
  void onInit() {
    super.onInit();
    loadBookings();
  }

  Future<void> loadBookings() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    isLoading.value = true;
    try {
      bookings.value = await _bookingService.getCustomerBookings(userId);
    } catch (e) {
      _showError(e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> requestBooking({required FarmModel farm}) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null || selectedDates.isEmpty) return;

    isProcessing.value = true;
    try {
      // 1. Check if owner has UPI set up
      final details = await _upiService.getOwnerUpiDetails(farm.ownerId);
      if (details['upi_id'] == null) {
        _showError('Owner hasn\'t set up a payment method (UPI) yet. Please contact them.');
        return;
      }

      final booking = BookingModel(
        id: const Uuid().v4(),
        farmId: farm.id,
        customerId: userId,
        eventDate: selectedDates.first, // Keep for backward compat
        eventDates: selectedDates.toList(),
        guestCount: guestCount.value,
        status: BookingStatus.pending,
        tokenPaid: false,
        tokenAmount: farm.tokenAmount,
        totalAmount: farm.pricePerDay,
      );

      final createdBooking = await _bookingService.createBooking(booking);

      await loadBookings();

      // Navigate to UPI Payment Screen
      Get.off(() => UpiPaymentScreen(
            bookingId: createdBooking.id,
            ownerId: farm.ownerId,
            farmId: farm.id,
            paymentType: 'token',
            amount: farm.tokenAmount,
          ));

      _showNotification('Booking requested! Pay the token and upload the screenshot to confirm.');
    } catch (e) {
      _showError(e.toString());
    } finally {
      isProcessing.value = false;
    }
  }

  Future<void> loadPaymentHistory(String bookingId) async {
    try {
      paymentHistory.value = await _upiService.getPaymentHistory(bookingId);
    } catch (e) {
      debugPrint('Error loading payment history: $e');
    }
  }

  void _showError(String message) {
    Get.snackbar(
      'Error',
      message,
      backgroundColor: const Color(0xFFD32F2F),
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _showNotification(String message) {
    Get.snackbar(
      'Notification',
      message,
      backgroundColor: const Color(0xFF8B5E3C),
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  Future<void> makeCall(String? phoneNumber) async {
    if (phoneNumber == null || phoneNumber.isEmpty) {
      _showError('Phone number not available');
      return;
    }
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        _showError('Could not launch dialer');
      }
    } catch (e) {
      _showError('Error: $e');
    }
  }
}
