class User {
  final String id;
  final String phoneNumber;
  final String username;
  final String role;
  final String roleDisplay;
  final String location;
  final bool isVerified;
  final double rating;
  final int totalTransactions;
  final String preferredLanguage;

  const User({
    required this.id,
    required this.phoneNumber,
    required this.username,
    required this.role,
    required this.roleDisplay,
    required this.location,
    required this.isVerified,
    required this.rating,
    this.totalTransactions = 0,
    this.preferredLanguage = 'EN',
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String,
        phoneNumber: json['phone_number'] as String,
        username: json['username'] as String? ?? '',
        role: json['role'] as String,
        roleDisplay: json['role_display'] as String? ?? '',
        location: json['location'] as String? ?? '',
        isVerified: json['is_verified'] as bool? ?? false,
        rating: double.tryParse(json['rating']?.toString() ?? '0') ?? 0.0,
        totalTransactions: json['total_transactions'] as int? ?? 0,
        preferredLanguage: json['preferred_language'] as String? ?? 'EN',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'phone_number': phoneNumber,
        'username': username,
        'role': role,
        'role_display': roleDisplay,
        'location': location,
        'is_verified': isVerified,
        'rating': rating,
        'total_transactions': totalTransactions,
        'preferred_language': preferredLanguage,
      };
}
