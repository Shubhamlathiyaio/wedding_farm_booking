import 'package:supabase_flutter/supabase_flutter.dart';

import '../../global/app_config.dart';
import '../models/farm_model.dart';
import '../models/review_model.dart';

class FarmService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<FarmModel>> getAvailableFarms({String? category, List<DateTime>? dates}) async {
    var query = _client.from(AppConfig.farmsTable).select().eq('is_available', true);

    if (category != null && category != 'All') {
      query = query.eq('category', category);
    }

    final response = await query;
    var allFarms = (response as List).map((e) => FarmModel.fromJson(e as Map<String, dynamic>)).toList();

    if (dates != null && dates.isNotEmpty) {
      // Find unavailable farm IDs for the selected dates
      // A farm is unavailable if any of the selected dates match any of the booked dates where status IN ('booked', 'paid')

      final dateStrings = dates.map((d) => d.toIso8601String().split('T').first).toList();

      final bookingResponse = await _client.from(AppConfig.bookingsTable).select('farm_id').inFilter('status', ['booked', 'paid']).filter('event_dates', 'cs', '{${dateStrings.join(",")}}');

      final unavailableFarmIds = (bookingResponse as List).map((e) => e['farm_id'] as String).toSet();

      allFarms = allFarms.where((farm) => !unavailableFarmIds.contains(farm.id)).toList();
    }

    return allFarms;
  }

  Future<FarmModel> getFarmById(String farmId) async {
    final response = await _client.from(AppConfig.farmsTable).select().eq('id', farmId).single();
    return FarmModel.fromJson(response);
  }

  Future<List<FarmModel>> getOwnerFarms(String ownerId) async {
    final response = await _client.from(AppConfig.farmsTable).select().eq('owner_id', ownerId);
    return (response as List).map((e) => FarmModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<FarmModel> addFarm(Map<String, dynamic> farmData) async {
    final response = await _client.from(AppConfig.farmsTable).insert(farmData).select().single();
    return FarmModel.fromJson(response);
  }

  Future<void> updateFarm(String farmId, Map<String, dynamic> farmData) async {
    await _client.from(AppConfig.farmsTable).update(farmData).eq('id', farmId);
  }

  Future<List<ReviewModel>> getFarmReviews(String farmId) async {
    final response = await _client.from(AppConfig.reviewsTable).select().eq('farm_id', farmId).order('created_at', ascending: false);
    return (response as List).map((e) => ReviewModel.fromJson(e as Map<String, dynamic>)).toList();
  }
}
