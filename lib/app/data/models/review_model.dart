class ReviewModel {
  final String id;
  final String bookingId;
  final String farmId;
  final String customerId;
  final int rating;
  final String? reviewText;
  final DateTime createdAt;

  ReviewModel({
    required this.id,
    required this.bookingId,
    required this.farmId,
    required this.customerId,
    required this.rating,
    this.reviewText,
    required this.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'] as String,
      bookingId: json['booking_id'] as String,
      farmId: json['farm_id'] as String,
      customerId: json['customer_id'] as String,
      rating: json['rating'] as int,
      reviewText: json['review_text'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'booking_id': bookingId,
      'farm_id': farmId,
      'customer_id': customerId,
      'rating': rating,
      'review_text': reviewText,
    };
  }
}
