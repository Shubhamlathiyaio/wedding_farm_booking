class ProfileModel {
  final String id;
  final String fullName;
  final String phone;
  final String role; // 'customer' | 'owner'

  const ProfileModel({required this.id, required this.fullName, required this.phone, required this.role});

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(id: json['id'] as String, fullName: json['full_name'] as String? ?? '', phone: json['phone'] as String? ?? '', role: json['role'] as String? ?? 'customer');
  }

  bool get isOwner => role == 'owner';
  bool get isCustomer => role == 'customer';
}
