import 'package:supabase_flutter/supabase_flutter.dart';

import '../../global/app_config.dart';
import '../models/farm_model.dart';

class FarmService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<FarmModel>> getAvailableFarms({String? category}) async {
    var query = _client.from(AppConfig.farmsTable).select().eq('is_available', true);

    if (category != null && category != 'All') {
      query = query.eq('category', category);
    }

    final response = await query;
    return (response as List).map((e) => FarmModel.fromJson(e as Map<String, dynamic>)).toList();
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
}
