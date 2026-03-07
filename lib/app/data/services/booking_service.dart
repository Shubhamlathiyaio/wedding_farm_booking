import 'package:supabase_flutter/supabase_flutter.dart';

import '../../global/app_config.dart';
import '../models/booking_model.dart';

class BookingService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<BookingModel>> getCustomerBookings(String customerId) async {
    final response = await _client
        .from(AppConfig.bookingsTable)
        .select('*, farms(name, location, photo_urls, owner_id, owner_profile:profiles!farms_owner_id_fkey(phone))')
        .eq('customer_id', customerId)
        .order('created_at', ascending: false);

    return (response as List).map((e) => BookingModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<BookingModel> createBooking(BookingModel booking) async {
    final response = await _client.from(AppConfig.bookingsTable).insert(booking.toInsertJson()).select().single();
    return BookingModel.fromJson(response);
  }

  // Owner queries
  Future<int> getUpcomingCount(String ownerId) async {
    final today = DateTime.now().toIso8601String().split('T').first;
    final response = await _client
        .from(AppConfig.bookingsTable)
        .select('*, farms!inner(owner_id)')
        .eq('farms.owner_id', ownerId)
        .inFilter('status', [BookingStatus.booked.name, BookingStatus.paid.name]).gte('event_date', today);
    return (response as List).length;
  }

  Future<int> getActiveCount(String ownerId) async {
    final response = await _client.from(AppConfig.bookingsTable).select('*, farms!inner(owner_id)').eq('farms.owner_id', ownerId).eq('status', BookingStatus.paid.name);
    return (response as List).length;
  }

  Future<List<BookingModel>> getOwnerBookings(
    String ownerId, {
    List<BookingStatus>? statuses,
    DateTime? date,
  }) async {
    var query = _client.from(AppConfig.bookingsTable).select('*, farms!inner(name, location, owner_id), customer:profiles!bookings_customer_id_fkey(full_name, phone)').eq('farms.owner_id', ownerId);

    if (statuses != null && statuses.isNotEmpty) {
      query = query.inFilter('status', statuses.map((e) => e.name).toList());
    }

    if (date != null) {
      final dateStr = date.toIso8601String().split('T').first;
      query = query.eq('event_date', dateStr);
    }

    final response = await query.order('event_date', ascending: true);
    return (response as List).map((e) => BookingModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> updateOwnerNote(String bookingId, String note) async {
    await _client.from(AppConfig.bookingsTable).update({'owner_note': note}).eq('id', bookingId);
  }

  Future<List<BookingModel>> getPendingBookings(String ownerId) async {
    return getOwnerBookings(ownerId, statuses: [BookingStatus.pending]);
  }
}
