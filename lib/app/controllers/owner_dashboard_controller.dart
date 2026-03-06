import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/models/booking_model.dart';
import '../data/services/booking_service.dart';
import '../data/services/edge_function_service.dart';

class OwnerDashboardController extends GetxController {
  final BookingService _bookingService = BookingService();
  final EdgeFunctionService _edgeFnService = EdgeFunctionService();

  final RxInt upcomingCount = 0.obs;
  final RxInt activeCount = 0.obs;
  final RxList<BookingModel> pendingBookings = <BookingModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isReleasing = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    isLoading.value = true;
    try {
      final results = await Future.wait([
        _bookingService.getUpcomingCount(userId),
        _bookingService.getActiveCount(userId),
        _bookingService.getPendingBookings(userId),
      ]);
      upcomingCount.value = results[0] as int;
      activeCount.value = results[1] as int;
      pendingBookings.value = results[2] as List<BookingModel>;
    } catch (e) {
      _showError(e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> releaseFarm(String bookingId) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    isReleasing.value = true;
    try {
      await _edgeFnService.releaseFarm(bookingId: bookingId, ownerId: userId);
      await loadDashboard();
      _showSuccess('Farm released successfully.');
    } catch (e) {
      _showError(e.toString());
    } finally {
      isReleasing.value = false;
    }
  }

  Future<void> approveBooking(String bookingId) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    isLoading.value = true;
    try {
      await Supabase.instance.client.from('bookings').update({'status': 'approved'}).eq('id', bookingId).eq('owner_id', userId);
      await loadDashboard();
      _showSuccess('Booking request approved. Waiting for customer to pay the token.');
    } catch (e) {
      _showError(e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> rejectBooking(String bookingId) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    isLoading.value = true;
    try {
      await Supabase.instance.client.from('bookings').update({'status': 'cancelled'}).eq('id', bookingId).eq('owner_id', userId);
      await loadDashboard();
      _showSuccess('Booking request rejected.');
    } catch (e) {
      _showError(e.toString());
    } finally {
      isLoading.value = false;
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
