import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/models/booking_model.dart';
import '../data/models/farm_model.dart';
import '../data/services/booking_service.dart';
import '../data/services/farm_service.dart';

class HomeController extends GetxController {
  final FarmService _farmService = FarmService();
  final BookingService _bookingService = BookingService();

  final RxList<FarmModel> farms = <FarmModel>[].obs;
  final RxList<FarmModel> filteredFarms = <FarmModel>[].obs;
  final RxMap<String, BookingStatus> userBookingsStatusMap = <String, BookingStatus>{}.obs;
  final RxBool isLoading = false.obs;
  final RxString searchQuery = ''.obs;
  final RxString selectedCategory = 'All'.obs;
  final RxList<DateTime> selectedDates = <DateTime>[].obs;
  final RxBool isMapView = false.obs;

  final List<String> categories = ['All', 'Lawn', 'Banquet', 'Resort'];

  @override
  void onInit() {
    super.onInit();
    loadFarms();
    loadUserBookings();

    debounce(searchQuery, (_) => _applyFilter(), time: const Duration(milliseconds: 300));
  }

  Future<void> loadUserBookings() async {
    final Session? session = Supabase.instance.client.auth.currentSession;
    if (session == null) return;

    try {
      final List<BookingModel> bookings = await _bookingService.getCustomerBookings(session.user.id);
      final Map<String, BookingStatus> map = {};
      for (var b in bookings) {
        // Only keep active booking statuses for tags
        if (b.status == BookingStatus.pending || b.status == BookingStatus.booked || b.status == BookingStatus.paid) {
          map[b.farmId] = b.status;
        }
      }
      userBookingsStatusMap.assignAll(map);
    } catch (e) {
      debugPrint('Error loading user bookings for tags: $e');
    }
  }

  Future<void> loadFarms() async {
    isLoading.value = true;
    try {
      final category = selectedCategory.value == 'All' ? null : selectedCategory.value;
      farms.value = await _farmService.getAvailableFarms(
        category: category,
        dates: selectedDates.isEmpty ? null : selectedDates.toList(),
      );
      _applyFilter();
    } catch (e) {
      _showError(e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  void onDatesChanged(List<DateTime> dates) {
    selectedDates.assignAll(dates);
    loadFarms();
  }

  void clearDates() {
    selectedDates.clear();
    loadFarms();
  }

  void onCategoryChanged(String category) {
    selectedCategory.value = category;
    loadFarms();
  }

  void onSearchChanged(String query) {
    searchQuery.value = query;
  }

  void _applyFilter() {
    final q = searchQuery.value.toLowerCase();
    if (q.isEmpty) {
      filteredFarms.value = farms;
    } else {
      filteredFarms.value = farms.where((f) => (f.name.toLowerCase().contains(q)) || (f.location.toLowerCase().contains(q))).toList();
    }
  }

  void toggleView() {
    isMapView.toggle();
  }

  void _showError(String message) {
    Get.snackbar(
      'Error',
      message,
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}
