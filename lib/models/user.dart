class AppUser {
  final String id;
  final String customUserId;
  final String? phoneNumber;
  final String? email;
  final DateTime createdAt;
  final String? defaultZipcode;
  final String? nickname;
  final String? bio;
  final int followerCount;
  final int followingCount;
  final int postCount;
  final bool isProfileComplete;

  AppUser({
    required this.id,
    required this.customUserId,
    this.phoneNumber,
    this.email,
    required this.createdAt,
    this.defaultZipcode,
    this.nickname,
    this.bio,
    this.followerCount = 0,
    this.followingCount = 0,
    this.postCount = 0,
    this.isProfileComplete = false,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'],
      customUserId: json['custom_user_id'],
      phoneNumber: json['phone_number'],
      email: json['google_email'],
      createdAt: DateTime.parse(json['created_at']),
      defaultZipcode: json['default_zipcode'],
      nickname: json['nickname'],
      bio: json['bio'],
      followerCount: json['follower_count'] ?? 0,
      followingCount: json['following_count'] ?? 0,
      postCount: json['post_count'] ?? 0,
      isProfileComplete: json['is_profile_complete'] ?? false,
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
      'nickname': nickname,
      'bio': bio,
      'follower_count': followerCount,
      'following_count': followingCount,
      'post_count': postCount,
      'is_profile_complete': isProfileComplete,
    };
  }
}