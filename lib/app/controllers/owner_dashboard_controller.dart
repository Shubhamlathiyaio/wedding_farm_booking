import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/models/booking_model.dart';
import '../data/services/booking_service.dart';
import '../data/services/edge_function_service.dart';

enum OwnerDashboardTab { pending, booked, paid, all }

class OwnerDashboardController extends GetxController {
  final BookingService _bookingService = BookingService();
  final EdgeFunctionService _edgeFnService = EdgeFunctionService();

  final RxInt upcomingCount = 0.obs;
  final RxInt activeCount = 0.obs;
  final RxList<BookingModel> bookings = <BookingModel>[].obs;
  final RxList<BookingModel> pendingBookings = <BookingModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isReleasing = false.obs;

  final Rx<OwnerDashboardTab> selectedTab = OwnerDashboardTab.pending.obs;
  final Rxn<DateTime> selectedDate = Rxn<DateTime>();

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
        _fetchFilteredBookings(userId),
        _bookingService.getPendingBookings(userId),
      ]);
      upcomingCount.value = results[0] as int;
      activeCount.value = results[1] as int;
      bookings.value = results[2] as List<BookingModel>;
      pendingBookings.value = results[3] as List<BookingModel>;
    } catch (e) {
      _showError(e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<List<BookingModel>> _fetchFilteredBookings(String userId) async {
    List<BookingStatus>? statuses;
    switch (selectedTab.value) {
      case OwnerDashboardTab.pending:
        statuses = [BookingStatus.pending];
        break;
      case OwnerDashboardTab.booked:
        statuses = [BookingStatus.booked, BookingStatus.paid];
        break;
      case OwnerDashboardTab.paid:
        statuses = [BookingStatus.paid];
        break;
      case OwnerDashboardTab.all:
        statuses = null;
        break;
    }

    return await _bookingService.getOwnerBookings(
      userId,
      statuses: statuses,
      date: selectedDate.value,
    );
  }

  void onTabChanged(OwnerDashboardTab tab) {
    selectedTab.value = tab;
    loadDashboard();
  }

  void onDateSelected(DateTime? date) {
    if (selectedDate.value == date) {
      selectedDate.value = null; // Toggle off if same date clicked
    } else {
      selectedDate.value = date;
    }
    loadDashboard();
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

  Future<void> confirmBooking(String bookingId) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    isLoading.value = true;
    try {
      await Supabase.instance.client.from('bookings').update({'status': BookingStatus.booked.name}).eq('id', bookingId).eq('owner_id', userId);
      await loadDashboard();
      _showSuccess('Booking confirmed/booked successfully.');
    } catch (e) {
      _showError(e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> markAsPaid(String bookingId) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    isLoading.value = true;
    try {
      await Supabase.instance.client.from('bookings').update({'status': BookingStatus.paid.name}).eq('id', bookingId).eq('owner_id', userId);
      await loadDashboard();
      _showSuccess('Booking marked as fully paid.');
    } catch (e) {
      _showError(e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateOwnerNote(String bookingId, String note) async {
    try {
      await _bookingService.updateOwnerNote(bookingId, note);
      // Update local state if needed or just reload
      await loadDashboard();
      _showSuccess('Note updated successfully.');
    } catch (e) {
      _showError(e.toString());
    }
  }

  Future<void> rejectBooking(String bookingId) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    isLoading.value = true;
    try {
      await Supabase.instance.client.from('bookings').update({'status': BookingStatus.cancelled.name}).eq('id', bookingId).eq('owner_id', userId);
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
