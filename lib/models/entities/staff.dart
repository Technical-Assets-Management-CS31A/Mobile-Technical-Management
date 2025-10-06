class Staff {
  final String id;
  final String firstName;
  final String lastName;
  final String? middleName;
  final String position;
  final String email;
  final String phoneNumber;
  final String username;
  final String password;
  final String? status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Computed property for full name
  String get name {
    if (middleName != null && middleName!.isNotEmpty) {
      return '$firstName $middleName $lastName';
    }
    return '$firstName $lastName';
  }

  Staff({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.middleName,
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
    String? firstName,
    String? lastName,
    String? middleName,
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
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      middleName: middleName ?? this.middleName,
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
      firstName: json['first_name'] ?? json['name']?.split(' ')[0] ?? '',
      lastName: json['last_name'] ?? json['name']?.split(' ').last ?? '',
      middleName: json['middle_name'],
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
      'first_name': firstName,
      'last_name': lastName,
      'middle_name': middleName,
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
