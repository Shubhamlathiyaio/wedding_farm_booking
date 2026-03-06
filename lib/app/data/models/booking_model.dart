import 'farm_model.dart';

class BookingModel {
  final String id;
  final String farmId;
  final String customerId;
  final DateTime eventDate;
  final int guestCount;
  final String? notes;
  final String status; // pending | token_paid | released | confirmed
  final bool tokenPaid;
  final double tokenAmount;
  final double totalAmount;
  final DateTime? createdAt;

  // Joined fields
  final FarmModel? farm;
  final String? customerName;

  const BookingModel({
    required this.id,
    required this.farmId,
    required this.customerId,
    required this.eventDate,
    required this.guestCount,
    this.notes,
    required this.status,
    required this.tokenPaid,
    required this.tokenAmount,
    required this.totalAmount,
    this.createdAt,
    this.farm,
    this.customerName,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    FarmModel? farmModel;
    if (json['farms'] != null) {
      farmModel = FarmModel.fromJson(json['farms'] as Map<String, dynamic>);
    }

    String? custName;
    if (json['customer'] != null) {
      custName = (json['customer'] as Map<String, dynamic>)['full_name'] as String?;
    } else if (json['profiles'] != null) {
      custName = (json['profiles'] as Map<String, dynamic>)['full_name'] as String?;
    }

    return BookingModel(
      id: json['id'] as String,
      farmId: json['farm_id'] as String,
      customerId: json['customer_id'] as String,
      eventDate: DateTime.parse(json['event_date'] as String),
      guestCount: json['guest_count'] as int? ?? 0,
      notes: json['notes'] as String?,
      status: json['status'] as String? ?? 'pending',
      tokenPaid: json['token_paid'] as bool? ?? false,
      tokenAmount: (json['token_amount'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      farm: farmModel,
      customerName: custName,
    );
  }

  Map<String, dynamic> toInsertJson() => {
        'farm_id': farmId,
        'customer_id': customerId,
        'event_date': eventDate.toIso8601String().split('T').first,
        'guest_count': guestCount,
        'notes': notes,
        'status': 'pending',
        'token_paid': false,
        'token_amount': tokenAmount,
        'total_amount': totalAmount,
      };
}
