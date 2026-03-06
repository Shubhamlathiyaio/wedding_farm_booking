import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  final Rxn<DateTime> selectedDate = Rxn<DateTime>();
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
    if (userId == null || selectedDate.value == null) return;

    isProcessing.value = true;
    try {
      final booking = BookingModel(
        id: '',
        farmId: farm.id,
        customerId: userId,
        eventDate: selectedDate.value!,
        guestCount: guestCount.value,
        status: 'pending',
        tokenPaid: false,
        tokenAmount: farm.tokenAmount,
        totalAmount: farm.pricePerDay,
      );

      await _bookingService.createBooking(booking);

      await loadBookings();
      Get.back();
      Get.back();
      _showSuccess('Booking requested! Waiting for owner approval.');
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

  void _showSuccess(String message) {
    Get.snackbar(
      'Success',
      message,
      backgroundColor: const Color(0xFF008450),
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}
