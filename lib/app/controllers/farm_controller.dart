import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/models/farm_model.dart';
import '../data/services/farm_service.dart';
import '../utils/helpers/image_utils.dart';

class FarmController extends GetxController {
  final FarmService _farmService = FarmService();

  final RxList<FarmModel> ownerFarms = <FarmModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isAdding = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadOwnerFarms();
  }

  Future<void> loadOwnerFarms() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    isLoading.value = true;
    try {
      ownerFarms.value = await _farmService.getOwnerFarms(userId);
    } catch (e) {
      _showError(e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addFarm({
    required String name,
    required String location,
    required String description,
    required String category,
    required double pricePerDay,
    required double tokenAmount,
    required String photoUrl,
    List<File>? imageFiles,
  }) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    isAdding.value = true;
    try {
      final List<String> uploadedUrls = [];
      if (imageFiles != null && imageFiles.isNotEmpty) {
        for (final file in imageFiles) {
          final url = await ImageUtils.uploadFarmImage(file.path);
          if (url != null) uploadedUrls.add(url);
        }
      }

      final farmData = {
        'owner_id': userId,
        'name': name,
        'location': location,
        'description': description,
        'category': category,
        'price_per_day': pricePerDay,
        'token_amount': tokenAmount,
        'photo_urls': [
          ...uploadedUrls,
          if (photoUrl.isNotEmpty) photoUrl,
        ],
        'is_available': true,
        'rating': 0.0,
      };
      final farm = await _farmService.addFarm(farmData);
      ownerFarms.add(farm);
      Get.back();
      _showSuccess('Farm "${farm.name}" added successfully!');
    } catch (e) {
      _showError(e.toString());
    } finally {
      isAdding.value = false;
    }
  }

  Future<void> updateExistingFarm({
    required FarmModel existingFarm,
    required String name,
    required String location,
    required String address,
    required String description,
    required String category,
    required double pricePerDay,
    required double tokenAmount,
    required int capacity,
    required List<String> amenities,
    required List<String> keptPhotoUrls,
    required List<File> newImageFiles,
    required bool isAvailable,
    String? upiId,
    String? upiName,
  }) async {
    isAdding.value = true;
    try {
      final List<String> newlyUploadedUrls = [];
      if (newImageFiles.isNotEmpty) {
        for (final file in newImageFiles) {
          final url = await ImageUtils.uploadFarmImage(file.path);
          if (url != null) newlyUploadedUrls.add(url);
        }
      }

      final updatedPhotoUrls = [...keptPhotoUrls, ...newlyUploadedUrls];

      if (updatedPhotoUrls.isEmpty) {
        throw Exception('At least one photo is required');
      }

      final farmData = {
        'name': name,
        'location': location,
        'address': address,
        'description': description,
        'category': category,
        'price_per_day': pricePerDay,
        'token_amount': tokenAmount,
        'capacity': capacity,
        'amenities': amenities,
        'photo_urls': updatedPhotoUrls,
        'is_available': isAvailable,
        'upi_id': upiId,
        'upi_name': upiName,
      };

      await _farmService.updateFarm(existingFarm.id, farmData);

      final index = ownerFarms.indexWhere((f) => f.id == existingFarm.id);
      if (index != -1) {
        ownerFarms[index] = FarmModel(
          id: existingFarm.id,
          ownerId: existingFarm.ownerId,
          name: name,
          description: description,
          location: location,
          address: address,
          category: category,
          pricePerDay: pricePerDay,
          tokenAmount: tokenAmount,
          capacity: capacity,
          amenities: amenities,
          rating: existingFarm.rating,
          photoUrls: updatedPhotoUrls,
          isAvailable: isAvailable,
          upiId: upiId,
          upiName: upiName,
        );
        ownerFarms.refresh();
      }

      Get.back();
      _showSuccess('Farm "$name" updated successfully!');
    } catch (e) {
      _showError(e.toString());
    } finally {
      isAdding.value = false;
    }
  }

  void _showError(String message) {
    Get.snackbar('Error', message, backgroundColor: const Color(0xFFD32F2F), colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
  }

  void _showSuccess(String message) {
    Get.snackbar('Success', message, backgroundColor: const Color(0xFF008450), colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
  }
}
