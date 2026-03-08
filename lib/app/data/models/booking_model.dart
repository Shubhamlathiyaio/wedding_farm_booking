import 'package:flutter/material.dart';

import '../../utils/constants/app_colors.dart';
import 'farm_model.dart';

enum BookingStatus {
  pending,
  booked,
  paid,
  released,
  cancelled;

  String get label {
    switch (this) {
      case BookingStatus.pending:
        return 'Pending';
      case BookingStatus.booked:
        return 'Booked';
      case BookingStatus.paid:
        return 'Paid';
      case BookingStatus.released:
        return 'Released';
      case BookingStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color get color {
    switch (this) {
      case BookingStatus.pending:
        return AppColors.pending;
      case BookingStatus.booked:
        return Colors.teal;
      case BookingStatus.paid:
        return AppColors.primary;
      case BookingStatus.released:
        return Colors.blue;
      case BookingStatus.cancelled:
        return AppColors.error;
    }
  }
}

enum PaymentStatus {
  pending,
  confirmed,
  rejected,
}

enum PaymentType {
  token,
  remaining,
  full,
}

class BookingModel {
  final String id;
  final String farmId;
  final String customerId;
  final DateTime eventDate; // Keep for backward compatibility
  final List<DateTime> eventDates;
  final int guestCount;
  final String? notes; // Customer notes
  final String? ownerNote; // Owner notes
  final BookingStatus status;
  final bool tokenPaid;
  final double tokenAmount;
  final double totalAmount;
  final DateTime? createdAt;

  // Joined fields
  final FarmModel? farm;
  final String? customerName;
  final String? customerPhone;
  final String? ownerPhone;

  const BookingModel({
    required this.id,
    required this.farmId,
    required this.customerId,
    required this.eventDate,
    this.eventDates = const [],
    required this.guestCount,
    this.notes,
    this.ownerNote,
    required this.status,
    required this.tokenPaid,
    required this.tokenAmount,
    required this.totalAmount,
    this.createdAt,
    this.farm,
    this.customerName,
    this.customerPhone,
    this.ownerPhone,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    FarmModel? farmModel;
    if (json['farms'] != null) {
      farmModel = FarmModel.fromJson(json['farms'] as Map<String, dynamic>);
    }

    String? custName;
    String? phone;
    if (json['customer'] != null) {
      final cust = json['customer'] as Map<String, dynamic>;
      custName = cust['full_name'] as String?;
      phone = cust['phone'] as String?;
    } else if (json['profiles'] != null) {
      final prof = json['profiles'] as Map<String, dynamic>;
      custName = prof['full_name'] as String?;
      phone = prof['phone'] as String?;
    }

    String? oPhone;
    if (json['owner_profile'] != null) {
      oPhone = json['owner_profile']['phone'] as String?;
    }

    return BookingModel(
      id: json['id'] as String,
      farmId: json['farm_id'] as String,
      customerId: json['customer_id'] as String,
      eventDate: json['event_date'] != null ? DateTime.parse(json['event_date'] as String) : DateTime.now(),
      eventDates: (json['event_dates'] as List<dynamic>?)?.map((e) => DateTime.parse(e.toString())).toList() ?? (json['event_date'] != null ? [DateTime.parse(json['event_date'] as String)] : []),
      guestCount: json['guest_count'] as int? ?? 0,
      notes: json['notes'] as String?,
      ownerNote: json['owner_note'] as String?,
      status: _parseStatus(json['status'] as String?),
      tokenPaid: json['token_paid'] as bool? ?? false,
      tokenAmount: (json['token_amount'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      farm: farmModel,
      customerName: custName,
      customerPhone: phone,
      ownerPhone: oPhone,
    );
  }

  static BookingStatus _parseStatus(String? status) {
    if (status == null) return BookingStatus.pending;
    return BookingStatus.values.firstWhere(
      (e) => e.name == status,
      orElse: () => BookingStatus.pending,
    );
  }

  Map<String, dynamic> toInsertJson() => {
        'id': id,
        'farm_id': farmId,
        'customer_id': customerId,
        'event_date': eventDates.isNotEmpty ? eventDates.first.toIso8601String().split('T').first : eventDate.toIso8601String().split('T').first,
        'event_dates': eventDates.map((d) => d.toIso8601String().split('T').first).toList(),
        'guest_count': guestCount,
        'notes': notes,
        'status': BookingStatus.pending.name,
        'token_paid': false,
        'token_amount': tokenAmount,
        'total_amount': totalAmount,
      };
}
