import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/models/profile_model.dart';
import '../data/services/auth_service.dart';
import '../routes/app_routes.dart';

class AuthController extends GetxController {
  final AuthService _authService = AuthService();

  final Rxn<User> currentUser = Rxn<User>();
  final Rxn<ProfileModel> profile = Rxn<ProfileModel>();
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    currentUser.value = _authService.currentUser;
    _listenToAuthChanges();
  }

  void _listenToAuthChanges() {
    _authService.authStateChanges.listen((authState) async {
      currentUser.value = authState.session?.user;
      if (authState.session?.user != null) {
        await _loadProfile(authState.session!.user.id);
        _navigate();
      } else {
        profile.value = null;
        Get.offAllNamed(AppRoutes.auth);
      }
    });
  }

  Future<void> _loadProfile(String userId) async {
    try {
      profile.value = await _authService.getProfile(userId);
    } catch (_) {}
  }

  Future<void> reloadProfile() async {
    final userId = currentUser.value?.id;
    if (userId != null) {
      await _loadProfile(userId);
    }
  }

  void _navigate() {
    if (profile.value?.isOwner == true) {
      Get.offAllNamed(AppRoutes.ownerShell);
    } else {
      Get.offAllNamed(AppRoutes.customerShell);
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String role,
  }) async {
    isLoading.value = true;
    try {
      await _authService.signUp(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
        role: role,
      );
      // Auth state change listener will handle navigation
    } catch (e) {
      _showError(e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    isLoading.value = true;
    try {
      final response = await _authService.signIn(email: email, password: password);
      if (response.user != null) {
        await _loadProfile(response.user!.id);
        _navigate();
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }

  void _showError(String message) {
    Get.snackbar(
      'Error',
      message,
      backgroundColor: const Color(0xFFD32F2F),
      colorText: const Color(0xFFFFFFFF),
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}
