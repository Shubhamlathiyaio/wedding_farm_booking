import 'package:get/get.dart';

import '../data/models/farm_model.dart';
import '../data/services/farm_service.dart';

class HomeController extends GetxController {
  final FarmService _farmService = FarmService();

  final RxList<FarmModel> farms = <FarmModel>[].obs;
  final RxList<FarmModel> filteredFarms = <FarmModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString searchQuery = ''.obs;
  final RxString selectedCategory = 'All'.obs;
  final RxBool isMapView = false.obs;

  final List<String> categories = ['All', 'Lawn', 'Banquet', 'Resort'];

  @override
  void onInit() {
    super.onInit();
    loadFarms();

    debounce(searchQuery, (_) => _applyFilter(), time: const Duration(milliseconds: 300));
  }

  Future<void> loadFarms() async {
    isLoading.value = true;
    try {
      final category = selectedCategory.value == 'All' ? null : selectedCategory.value;
      farms.value = await _farmService.getAvailableFarms(category: category);
      _applyFilter();
    } catch (e) {
      _showError(e.toString());
    } finally {
      isLoading.value = false;
    }
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
      filteredFarms.value = farms.where((f) => f.name.toLowerCase().contains(q) || f.location.toLowerCase().contains(q)).toList();
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
