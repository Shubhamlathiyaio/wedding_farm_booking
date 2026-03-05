class FarmModel {
  final String id;
  final String ownerId;
  final String name;
  final String description;
  final String location;
  final String category;
  final double pricePerDay;
  final double tokenAmount;
  final double rating;
  final List<String> photoUrls;
  final bool isAvailable;

  const FarmModel({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.description,
    required this.location,
    required this.category,
    required this.pricePerDay,
    required this.tokenAmount,
    required this.rating,
    required this.photoUrls,
    required this.isAvailable,
  });

  factory FarmModel.fromJson(Map<String, dynamic> json) {
    return FarmModel(
      id: json['id'] as String? ?? '',
      ownerId: json['owner_id'] as String? ?? '',
      name: json['name'] as String? ?? 'Unnamed Farm',
      description: json['description'] as String? ?? '',
      location: json['location'] as String? ?? '',
      category: json['category'] as String? ?? 'Lawn',
      pricePerDay: (json['price_per_day'] as num?)?.toDouble() ?? 0.0,
      tokenAmount: (json['token_amount'] as num?)?.toDouble() ?? 0.0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      photoUrls: json['photo_urls'] != null ? List<String>.from(json['photo_urls'] as List) : [],
      isAvailable: json['is_available'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'owner_id': ownerId,
        'name': name,
        'description': description,
        'location': location,
        'category': category,
        'price_per_day': pricePerDay,
        'token_amount': tokenAmount,
        'rating': rating,
        'photo_urls': photoUrls,
        'is_available': isAvailable,
      };

  String get firstPhotoUrl => photoUrls.isNotEmpty ? photoUrls.first : '';
}
