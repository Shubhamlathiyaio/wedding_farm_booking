import 'package:supabase_flutter/supabase_flutter.dart';

import '../../global/app_config.dart';
import '../models/profile_model.dart';

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  User? get currentUser => _client.auth.currentUser;
  String? get currentUserId => _client.auth.currentUser?.id;
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<AuthResponse> signUp({required String email, required String password, required String fullName, required String phone, required String role}) async {
    return await _client.auth.signUp(email: email, password: password, data: {'full_name': fullName, 'phone': phone, 'role': role});
  }

  Future<AuthResponse> signIn({required String email, required String password}) async {
    return await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<ProfileModel?> getProfile(String userId) async {
    final response = await _client.from(AppConfig.profilesTable).select().eq('id', userId).maybeSingle();
    if (response == null) return null;
    return ProfileModel.fromJson(response);
  }
}
