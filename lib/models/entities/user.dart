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
  
  // Student-specific fields
  final String? frontStudentIdPicture;
  final String? backStudentIdPicture;
  final String? studentIdNumber;
  final String? course;
  final String? section;
  final String? year;
  final String? profilePicture;
  
  // Address fields (for both Teacher and Student)
  final String? street;
  final String? cityMunicipality;
  final String? province;
  final String? postalCode;

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
    // Student-specific fields
    this.frontStudentIdPicture,
    this.backStudentIdPicture,
    this.studentIdNumber,
    this.course,
    this.section,
    this.year,
    this.profilePicture,
    // Address fields
    this.street,
    this.cityMunicipality,
    this.province,
    this.postalCode,
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
    String? frontStudentIdPicture,
    String? backStudentIdPicture,
    String? studentIdNumber,
    String? course,
    String? section,
    String? year,
    String? profilePicture,
    String? street,
    String? cityMunicipality,
    String? province,
    String? postalCode,
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
      frontStudentIdPicture: frontStudentIdPicture ?? this.frontStudentIdPicture,
      backStudentIdPicture: backStudentIdPicture ?? this.backStudentIdPicture,
      studentIdNumber: studentIdNumber ?? this.studentIdNumber,
      course: course ?? this.course,
      section: section ?? this.section,
      year: year ?? this.year,
      profilePicture: profilePicture ?? this.profilePicture,
      street: street ?? this.street,
      cityMunicipality: cityMunicipality ?? this.cityMunicipality,
      province: province ?? this.province,
      postalCode: postalCode ?? this.postalCode,
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
      password: json['password'],
      confirmPassword: json['confirmPassword'],
      userRole: json['userRole'] ?? '',
      status: json['status'],
      type: json['\$type'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      // Student-specific fields
      frontStudentIdPicture: json['frontStudentIdPicture'],
      backStudentIdPicture: json['backStudentIdPicture'],
      studentIdNumber: json['studentIdNumber'],
      course: json['course'],
      section: json['section'],
      year: json['year'],
      profilePicture: json['profilePicture'],
      // Address fields
      street: json['street'],
      cityMunicipality: json['cityMunicipality'],
      province: json['province'],
      postalCode: json['postalCode'],
    );
  }

  Map<String, dynamic> toJson() {
    final json = {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'middleName': middleName,
      'position': position,
      'email': email,
      'phoneNumber': phoneNumber,
      'username': username,
      'password': password,
      'confirmPassword': confirmPassword,
      'userRole': userRole,
      'status': status,
      '\$type': type,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
    
    // Add student-specific fields if present
    if (frontStudentIdPicture != null) json['frontStudentIdPicture'] = frontStudentIdPicture;
    if (backStudentIdPicture != null) json['backStudentIdPicture'] = backStudentIdPicture;
    if (studentIdNumber != null) json['studentIdNumber'] = studentIdNumber;
    if (course != null) json['course'] = course;
    if (section != null) json['section'] = section;
    if (year != null) json['year'] = year;
    if (profilePicture != null) json['profilePicture'] = profilePicture;
    
    // Add address fields if present
    if (street != null) json['street'] = street;
    if (cityMunicipality != null) json['cityMunicipality'] = cityMunicipality;
    if (province != null) json['province'] = province;
    if (postalCode != null) json['postalCode'] = postalCode;
    
    return json;
  }

  // Helper method for registration endpoint - matches curl command structure exactly
  Map<String, dynamic> toRegistrationJson() {
    // Clean phone number - remove all non-digit characters
    String? cleanPhoneNumber;
    if (phoneNumber != null && phoneNumber!.isNotEmpty) {
      cleanPhoneNumber = phoneNumber!.replaceAll(RegExp(r'[^\d]'), '');
    }

    // Ensure all required fields are present and not null
    final registrationData = <String, dynamic>{
      'username': username.trim(),
      'lastName': lastName.trim(),
      'firstName': firstName.trim(),
      'email': email.trim(),
      'role': userRole.trim(),
    };

    // Add optional fields only if they have values
    if (cleanPhoneNumber != null && cleanPhoneNumber.isNotEmpty) {
      registrationData['phoneNumber'] = cleanPhoneNumber;
    }

    if (password != null && password!.trim().isNotEmpty) {
      registrationData['password'] = password!.trim();
    }

    if (confirmPassword != null && confirmPassword!.trim().isNotEmpty) {
      registrationData['confirmPassword'] = confirmPassword!.trim();
    }

    // Add middleName only if it's not null and not empty
    if (middleName != null && middleName!.trim().isNotEmpty) {
      registrationData['middleName'] = middleName!.trim();
    }

    return registrationData;
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
      'Password': password ?? '',
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
      'password': password,
      'userRole': userRole,
      'status': status,
      '\$type': type,
    };
  }

  // Helper method for updating student as form data (for multipart requests)
  Map<String, String> toStudentFormData() {
    return {
      'FirstName': firstName,
      'LastName': lastName,
      'MiddleName': middleName ?? '',
      'Email': email,
      'PhoneNumber': phoneNumber ?? '',
      'StudentIdNumber': studentIdNumber ?? '',
      'Course': course ?? '',
      'Section': section ?? '',
      'Year': year ?? '',
      'Street': street ?? '',
      'CityMunicipality': cityMunicipality ?? '',
      'Province': province ?? '',
      'PostalCode': postalCode ?? '',
      // Optional picture fields for multipart upload
      'ProfilePicture': profilePicture ?? '',
      'FrontStudentIdPicture': frontStudentIdPicture ?? '',
      'BackStudentIdPicture': backStudentIdPicture ?? '',
    };
  }

  // Helper method for updating teacher as form data (for multipart requests)
  Map<String, String> toTeacherFormData() {
    return {
      'FirstName': firstName,
      'LastName': lastName,
      'MiddleName': middleName ?? '',
      'PhoneNumber': phoneNumber ?? '',
    };
  }
}
