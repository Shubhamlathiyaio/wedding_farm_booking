import 'package:supabase_flutter/supabase_flutter.dart';

import '../../global/app_config.dart';

class EdgeFunctionService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<Map<String, dynamic>> confirmTokenPayment(String bookingId) async {
    await Supabase.instance.client.auth.refreshSession();
    final response = await _client.functions.invoke(
      AppConfig.confirmTokenPaymentFn,
      body: {'booking_id': bookingId},
    );
    return response.data as Map<String, dynamic>? ?? {};
  }

  Future<Map<String, dynamic>> releaseFarm({
    required String bookingId,
    required String ownerId,
  }) async {
    final response = await _client.functions.invoke(
      AppConfig.releaseFarmFn,
      body: {
        'booking_id': bookingId,
        'owner_id': ownerId,
      },
    );
    return response.data as Map<String, dynamic>? ?? {};
  }
}
