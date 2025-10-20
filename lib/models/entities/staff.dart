class Staff {
  final String id;
  final String firstName;
  final String lastName;
  final String? middleName;
  final String? position;
  final String email;
  final String? phoneNumber;
  final String username;
  final String? password; // Password field for user creation
  final String? confirmPassword; // Confirm password field for user creation
  final String userRole;
  final String? status;
  final String? type; // $type field from API
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
    this.position,
    required this.email,
    this.phoneNumber,
    required this.username,
    this.password,
    this.confirmPassword,
    required this.userRole,
    this.status,
    this.type,
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
    String? confirmPassword,
    String? userRole,
    String? status,
    String? type,
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
      confirmPassword: confirmPassword ?? this.confirmPassword,
      userRole: userRole ?? this.userRole,
      status: status ?? this.status,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Staff.fromJson(Map<String, dynamic> json) {
    return Staff(
      id: json['id'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      middleName: json['middleName'],
      position: json['position'],
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'],
      username: json['username'] ?? '',
      password: json['password'], // Password is typically not returned from API
      confirmPassword:
          json['confirmPassword'], // Confirm password is typically not returned from API
      userRole: json['userRole'] ?? '',
      status: json['status'],
      type: json['\$type'],
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
      'firstName': firstName,
      'lastName': lastName,
      'middleName': middleName,
      'position': position,
      'email': email,
      'phoneNumber': phoneNumber,
      'username': username,
      'password': password, // Include password in JSON for user creation
      'confirmPassword': confirmPassword, // Include confirm password in JSON for user creation
      'userRole': userRole,
      'status': status,
      '\$type': type,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // Helper method for registration endpoint - matches curl command structure exactly
  Map<String, dynamic> toRegistrationJson() {
    return {
      'username': username,
      'lastName': lastName,
      'middleName': middleName,
      'firstName': firstName,
      'email': email,
      'phoneNumber': phoneNumber,
      'role': userRole,
      'password': password,
      'confirmPassword': confirmPassword,
    };
  }

  // Helper method for updating staff as form data (for multipart requests)
  Map<String, String> toUpdateFormData() {
    return {
      'FirstName': firstName,
      'LastName': lastName,
      'MiddleName': middleName ?? '',
      'Position': position ?? '',
      'Email': email,
      'PhoneNumber': phoneNumber ?? '',
      'Username': username,
      'Password': password ?? '', // Include password in form data
      'UserRole': userRole,
      'Status': status ?? '',
    };
  }

  // Helper method for updating staff (without timestamps)
  Map<String, dynamic> toUpdateJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'middleName': middleName,
      'position': position,
      'email': email,
      'phoneNumber': phoneNumber,
      'username': username,
      'password': password, // Include password in update JSON
      'userRole': userRole,
      'status': status,
      '\$type': type,
    };
  }
}
