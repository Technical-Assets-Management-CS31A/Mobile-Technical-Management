class Staff {
  final String id;
  final String name;
  final String position;
  final String email;
  final String phoneNumber;
  final String username;
  final String password;
  final String? status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Staff({
    required this.id,
    required this.name,
    required this.position,
    required this.email,
    required this.phoneNumber,
    required this.username,
    required this.password,
    this.status,
    this.createdAt,
    this.updatedAt,
  });

  Staff copyWith({
    String? id,
    String? name,
    String? position,
    String? email,
    String? phoneNumber,
    String? username,
    String? password,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Staff(
      id: id ?? this.id,
      name: name ?? this.name,
      position: position ?? this.position,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      username: username ?? this.username,
      password: password ?? this.password,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Staff.fromJson(Map<String, dynamic> json) {
    return Staff(
      id: json['id'],
      name: json['name'],
      position: json['position'],
      email: json['email'],
      phoneNumber: json['phone_number'] ?? '',
      username: json['username'] ?? '',
      password: json['password'] ?? '',
      status: json['status'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'position': position,
      'email': email,
      'phone_number': phoneNumber,
      'username': username,
      'password': password,
      'status': status,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
