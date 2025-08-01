class User {
  final String id;
  final String email;
  final String? phone;
  final String role;
  final String status;
  final String? lastLogin;
  final String? createdAt;
  final String? updatedAt;

  User({
    required this.id,
    required this.email,
    this.phone,
    required this.role,
    required this.status,
    this.lastLogin,
    this.createdAt,
    this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? 'unknown',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString(),
      role: json['role']?.toString() ?? 'customer',
      status: json['status']?.toString() ?? 'active',
      lastLogin: json['lastLogin']?.toString(),
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
    );
  }
}
