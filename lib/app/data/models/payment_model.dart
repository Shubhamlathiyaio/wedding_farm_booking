// lib/models/payment_model.dart

enum PaymentType { token, final_ }

enum PaymentStatus { pending, succeeded, failed, cancelled }

class PaymentModel {
  final String id;
  final String bookingId;
  final String customerId;
  final String ownerId;
  final String farmId;
  final PaymentType paymentType;
  final double amount;
  final double? totalBookingAmount;
  final double? tokenAmountPaid;
  final String currency;
  final String? stripePaymentIntentId;
  final String? stripePaymentMethod;
  final PaymentStatus status;
  final DateTime? paidAt;
  final DateTime createdAt;
  final Map<String, dynamic> metadata;

  // From payment_history view
  final String? farmName;
  final String? farmLocation;
  final String? farmImage;
  final DateTime? bookingDate;
  final String? bookingStatus;

  const PaymentModel({
    required this.id,
    required this.bookingId,
    required this.customerId,
    required this.ownerId,
    required this.farmId,
    required this.paymentType,
    required this.amount,
    this.totalBookingAmount,
    this.tokenAmountPaid,
    required this.currency,
    this.stripePaymentIntentId,
    this.stripePaymentMethod,
    required this.status,
    this.paidAt,
    required this.createdAt,
    required this.metadata,
    this.farmName,
    this.farmLocation,
    this.farmImage,
    this.bookingDate,
    this.bookingStatus,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'] as String,
      bookingId: json['booking_id'] as String,
      customerId: json['customer_id'] as String,
      ownerId: json['owner_id'] as String,
      farmId: json['farm_id'] as String,
      // ✅ FIX: your schema uses 'full' not 'final'
      paymentType: json['payment_type'] == 'token' ? PaymentType.token : PaymentType.final_,
      amount: (json['amount'] as num).toDouble(),
      totalBookingAmount: json['total_booking_amount'] != null ? (json['total_booking_amount'] as num).toDouble() : null,
      tokenAmountPaid: json['token_amount_paid'] != null ? (json['token_amount_paid'] as num).toDouble() : null,
      currency: json['currency'] as String? ?? 'INR',
      stripePaymentIntentId: json['stripe_payment_intent_id'] as String?,
      stripePaymentMethod: json['stripe_payment_method'] as String?,
      status: _parseStatus(json['status'] as String),
      paidAt: json['paid_at'] != null ? DateTime.parse(json['paid_at'] as String) : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      metadata: (json['metadata'] as Map<String, dynamic>?) ?? {},
      farmName: json['farm_name'] as String?,
      farmLocation: json['farm_location'] as String?,
      farmImage: json['farm_image'] as String?,
      // ✅ FIX: your bookings table uses 'event_date' — view aliases it to 'booking_date'
      bookingDate: json['booking_date'] != null ? DateTime.parse(json['booking_date'] as String) : null,
      bookingStatus: json['booking_status'] as String?,
    );
  }

  static PaymentStatus _parseStatus(String s) {
    switch (s) {
      // ✅ FIX: your schema uses 'success' not 'succeeded'
      case 'success':
        return PaymentStatus.succeeded;
      case 'failed':
        return PaymentStatus.failed;
      case 'cancelled':
        return PaymentStatus.cancelled;
      default:
        return PaymentStatus.pending;
    }
  }

  /// Remaining amount to be paid (only meaningful on token payment row)
  double get remainingAmount => totalBookingAmount != null ? totalBookingAmount! - amount : 0;

  String get paymentTypeLabel => paymentType == PaymentType.token ? 'Token' : 'Final Payment';

  String get statusLabel {
    switch (status) {
      case PaymentStatus.succeeded:
        return 'Paid';
      case PaymentStatus.failed:
        return 'Failed';
      case PaymentStatus.cancelled:
        return 'Cancelled';
      case PaymentStatus.pending:
        return 'Pending';
    }
  }
}
