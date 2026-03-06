import 'package:supabase_flutter/supabase_flutter.dart';

import '../../global/app_config.dart';
import '../models/booking_model.dart';

class BookingService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<BookingModel>> getCustomerBookings(String customerId) async {
    final response = await _client.from(AppConfig.bookingsTable).select('*, farms(name, location, photo_urls)').eq('customer_id', customerId).order('created_at', ascending: false);

    return (response as List).map((e) => BookingModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<BookingModel> createBooking(BookingModel booking) async {
    final response = await _client.from(AppConfig.bookingsTable).insert(booking.toInsertJson()).select().single();
    return BookingModel.fromJson(response);
  }

  // Owner queries
  Future<int> getUpcomingCount(String ownerId) async {
    final response =
        await _client.from(AppConfig.bookingsTable).select('*, farms!inner(owner_id)').eq('farms.owner_id', ownerId).eq('status', 'token_paid').gte('event_date', DateTime.now().toIso8601String());
    return (response as List).length;
  }

  Future<int> getActiveCount(String ownerId) async {
    final response = await _client.from(AppConfig.bookingsTable).select('*, farms!inner(owner_id)').eq('farms.owner_id', ownerId).eq('status', 'confirmed');
    return (response as List).length;
  }

  Future<List<BookingModel>> getPendingBookings(String ownerId) async {
    final response = await _client
        .from(AppConfig.bookingsTable)
        .select('*, farms!inner(name, location, owner_id), customer:profiles!bookings_customer_id_fkey(full_name, phone)')
        .eq('farms.owner_id', ownerId)
        .eq('status', 'pending');

    return (response as List).map((e) => BookingModel.fromJson(e as Map<String, dynamic>)).toList();
  }
}
