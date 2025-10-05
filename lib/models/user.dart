class AppUser {
  final String id;
  final String customUserId;
  final String? phoneNumber;
  final String? email;
  final DateTime createdAt;
  final String? defaultZipcode;

  AppUser({
    required this.id,
    required this.customUserId,
    this.phoneNumber,
    this.email,
    required this.createdAt,
    this.defaultZipcode,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'],
      customUserId: json['custom_user_id'],
      phoneNumber: json['phone_number'],
      email: json['google_email'],
      createdAt: DateTime.parse(json['created_at']),
      defaultZipcode: json['default_zipcode'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'custom_user_id': customUserId,
      'phone_number': phoneNumber,
      'google_email': email,
      'created_at': createdAt.toIso8601String(),
      'default_zipcode': defaultZipcode,
    };
  }
}