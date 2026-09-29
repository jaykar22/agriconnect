class AppUser {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String role;
  final DateTime? createdAt;
  final bool isActive;

  AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.createdAt,
    required this.isActive,
  });

  factory AppUser.fromMap(Map<String, dynamic> map, String documentId) {
    return AppUser(
      uid: documentId,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      role: map['role'] ?? 'farmer',
      createdAt: map['createdAt']?.toDate(),
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'isActive': isActive,
    };
  }
}
