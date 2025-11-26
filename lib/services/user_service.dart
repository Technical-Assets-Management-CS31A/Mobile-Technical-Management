import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import '../models/entities/user.dart';
import 'api_service.dart';

class StaffService {
  static final StaffService _instance = StaffService._internal();
  factory StaffService() => _instance;
  StaffService._internal();

  late final ApiService _apiService;
  late final String _staffEndpoint;
  late final String _registrationEndpoint;
  late final String _deleteEndpoint; // Add this

  /// Initialize the StaffService with ApiService dependency
  Future<void> initialize() async {
    _apiService = ApiService();
    await _apiService.initialize();
    _staffEndpoint = dotenv.env['STAFF_ENDPOINT'] ?? '/users';
    _registrationEndpoint =
        dotenv.env['REGISTRATION_ENDPOINT'] ?? '/auth/register';
    _deleteEndpoint = dotenv.env['DELETE_ENDPOINT'] ?? '/users/archive';
    ;
    print('StaffService initialized with endpoint: $_staffEndpoint');
  }

  // CREATE - Add a new staff member
  Future<Staff> createStaff(Staff staff) async {
    try {
      final registrationData = staff.toRegistrationJson();

      final response = await _apiService.post(
        "$_registrationEndpoint",
        body: registrationData,
      );

      return Staff.fromJson(response['data'] ?? response);
    } catch (e) {
      throw Exception('Failed to create staff: $e');
    }
  }

  // READ - Get all staff
  Future<List<Staff>> getAllStaff() async {
    try {
      final response = await _apiService.get(_staffEndpoint);
      final List<dynamic> userData = response['data'] ?? response;

      // Filter only staff, admin, and superadmin members from the mixed user types
      final staffData = userData.where((user) {
        final userRole = user['userRole'] as String?;
        return userRole == 'Staff' || userRole == 'Admin';
      }).toList();

      // Process each staff member to ensure status is properly handled
      return staffData.map((json) {
        final staff = Staff.fromJson(json);
        return staff;
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch staff: $e');
    }
  }

  // READ - Get all teachers and students (for Registered Modules)
  Future<List<Staff>> getAllTeachersAndStudents() async {
    try {
      final response = await _apiService.get(_staffEndpoint);
      final List<dynamic> userData = response['data'] ?? response;

      // Filter only Teacher and Student members from the mixed user types
      final teacherStudentData = userData.where((user) {
        final userRole = user['userRole'] as String?;
        return userRole == 'Teacher' || userRole == 'Student';
      }).toList();

      // Process each user to ensure all fields are properly handled
      return teacherStudentData.map((json) {
        final user = Staff.fromJson(json);
        return user;
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch teachers and students: $e');
    }
  }

  // READ - Get staff by ID
  Future<Staff?> getStaffById(String id) async {
    try {
      final response = await _apiService.get('$_staffEndpoint/$id');
      return Staff.fromJson(response['data'] ?? response);
    } catch (e) {
      if (e.toString().contains('404') || e.toString().contains('Not found')) {
        return null;
      }
      throw Exception('Failed to fetch staff by ID: $e');
    }
  }

  // READ - Get staff by position
  Future<List<Staff>> getStaffByPosition(String position) async {
    try {
      final response = await _apiService.get(
        '$_staffEndpoint?position=$position',
      );
      final List<dynamic> userData = response['data'] ?? response;

      // Filter only staff, admin, and superadmin members with the specified position
      final staffData = userData.where((user) {
        final userRole = user['userRole'] as String?;
        final userPosition = user['position'] as String?;
        return (userRole == 'Staff' || userRole == 'Admin') &&
            userPosition?.toLowerCase() == position.toLowerCase();
      }).toList();

      return staffData.map((json) => Staff.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch staff by position: $e');
    }
  }

  // READ - Get active staff count
  Future<int> getActiveStaffCount() async {
    try {
      // Get all staff first (which already includes status)
      final allStaff = await getAllStaff();

      // Filter locally for active staff instead of making a separate API call
      final activeStaff = allStaff.where((staff) {
        final status = staff.status?.toLowerCase() ?? 'offline';
        return status == 'online' || status == 'active';
      }).toList();

      return activeStaff.length;
    } catch (e) {
      throw Exception('Failed to fetch active staff count: $e');
    }
  }

  // READ - Get staff statistics
  Future<Map<String, int>> getStaffStats() async {
    try {
      final response = await _apiService.get('$_staffEndpoint/stats');
      return Map<String, int>.from(response['data'] ?? response);
    } catch (e) {
      // Fallback to calculating stats from all staff if stats endpoint doesn't exist
      try {
        final allStaff = await getAllStaff();
        final stats = {
          'total': allStaff.length,
          'active': 0,
          'offline': 0,
          'lab_technician': 0,
          'admin': 0,
          'other': 0,
        };

        for (final staff in allStaff) {
          // Count by status
          final status = staff.status?.toLowerCase() ?? '';
          if (status == 'online' || status == 'active') {
            stats['active'] = (stats['active'] ?? 0) + 1;
          } else if (status == 'offline') {
            stats['offline'] = (stats['offline'] ?? 0) + 1;
          }

          // Count by role and position
          final userRole = staff.userRole.toLowerCase();
          final position = staff.position?.toLowerCase() ?? '';

          if (userRole == 'admin') {
            stats['admin'] = (stats['admin'] ?? 0) + 1;
          } else if (position == 'lab technician') {
            stats['lab_technician'] = (stats['lab_technician'] ?? 0) + 1;
          } else if (position.isNotEmpty || userRole == 'staff') {
            stats['other'] = (stats['other'] ?? 0) + 1;
          }
        }

        return stats;
      } catch (fallbackError) {
        throw Exception('Failed to fetch staff statistics: $e');
      }
    }
  }

  // UPDATE - Update an existing staff member
  Future<Staff?> updateStaff(Staff updatedStaff) async {
    try {
      // Determine the endpoint based on user role
      String endpoint;
      dynamic response;
      
      if (updatedStaff.userRole == 'Teacher') {
        endpoint = '/users/teachers/profile/${updatedStaff.id}';
        final jsonData = {
          'firstName': updatedStaff.firstName,
          'lastName': updatedStaff.lastName,
          'middleName': updatedStaff.middleName,
          'phoneNumber': updatedStaff.phoneNumber,
          'department': updatedStaff.department,
        };
        
        response = await _apiService.patch(
          endpoint,
          body: jsonData,
        );
      } else if (updatedStaff.userRole == 'Student') {
        endpoint = '/users/students/profile/${updatedStaff.id}';
        final formData = updatedStaff.toStudentFormData();
        Map<String, List<int>>? files;

        // Helper function to process image fields
        void processImageField(String fieldName, String? base64Image) {
          if (base64Image != null && base64Image.isNotEmpty) {
            // Check if it's a base64 string (long string, no http)
            if (base64Image.length > 100 && !base64Image.contains('http')) {
              try {
                final base64String = base64Image.contains(',')
                    ? base64Image.split(',')[1]
                    : base64Image;
                final bytes = base64.decode(base64String);
                
                files ??= {};
                files![fieldName] = bytes;
                
                // Remove from formData as we're sending it as a file
                formData.remove(fieldName);
              } catch (e) {
                print('Warning: Could not decode base64 image for $fieldName: $e');
              }
            }
          }
        }

        // Process all three image fields
        processImageField('ProfilePicture', updatedStaff.profilePicture);
        processImageField('FrontStudentIdPicture', updatedStaff.frontStudentIdPicture);
        processImageField('BackStudentIdPicture', updatedStaff.backStudentIdPicture);
        
        response = await _apiService.patchMultipart(
          endpoint,
          fields: formData,
          files: files,
        );
      } else {
        // For Staff, Admin, SuperAdmin, etc. - use JSON
        endpoint = '/users/admin-or-staff/profile/${updatedStaff.id}';
        final jsonData = updatedStaff.toUpdateJson();
        
        response = await _apiService.patch(
          endpoint,
          body: jsonData,
        );
      }

      // Parse response similar to items
      if (response['success'] == true) {
        // Return the updated staff data if available, otherwise return the original staff
        return response['data'] != null
            ? Staff.fromJson(response['data'])
            : updatedStaff;
      } else {
        throw Exception(response['message'] ?? 'Failed to update staff');
      }
    } catch (e) {
      if (e.toString().contains('404') || e.toString().contains('Not found')) {
        return null;
      }
      throw Exception('Failed to update staff: $e');
    }
  }

  // UPDATE - Update user profile (for personal details editing)
  Future<Map<String, dynamic>> updateUserProfile({
    required String userId,
    required String firstName,
    required String lastName,
    String? middleName,
    required String username,
    required String email,
    required String phoneNumber,
    String? position,
    String? userRole, // Add userRole parameter
  }) async {
    try {
      dynamic response;
      String endpoint;

      if (userRole == 'Teacher') {
        endpoint = '/users/teachers/profile/$userId';
        final formData = {
          'FirstName': firstName,
          'LastName': lastName,
          'MiddleName': middleName ?? '',
          'Email': email,
          'PhoneNumber': phoneNumber,
          'Username': username,
          // Add other fields if available/needed, but these are the ones passed to this method
        };
        
        response = await _apiService.patchMultipart(
          endpoint,
          fields: formData,
        );
      } else if (userRole == 'Student') {
        endpoint = '/users/students/profile/$userId';
        final formData = {
          'FirstName': firstName,
          'LastName': lastName,
          'MiddleName': middleName ?? '',
          'Email': email,
          'PhoneNumber': phoneNumber,
          'Username': username,
          // Add other fields if available/needed
        };
        
        response = await _apiService.patchMultipart(
          endpoint,
          fields: formData,
        );
      } else {
        // For Staff, Admin, SuperAdmin, etc.
        endpoint = '/users/admin-or-staff/profile/$userId';
        final updateData = {
          'firstName': firstName,
          'lastName': lastName,
          'middleName': middleName,
          'username': username,
          'email': email,
          'phoneNumber': phoneNumber,
          'position': position,
        };
        
        response = await _apiService.patch(
          endpoint,
          body: updateData,
        );
      }

      if (response['success'] == true) {
        return {
          'success': true,
          'data': response['data'],
          'message': response['message'] ?? 'Profile updated successfully',
        };
      } else {
        return {
          'success': false,
          'error': response['message'] ?? 'Failed to update profile',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Failed to update profile: $e',
      };
    }
  }

  // READ - Get user profile using /auth/me endpoint
  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final response = await _apiService.get('/auth/me');
      
      if (response['success'] == true || response['data'] != null) {
        return {
          'success': true,
          'data': response['data'] ?? response,
        };
      } else {
        return {
          'success': false,
          'error': response['message'] ?? 'Failed to fetch profile',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Failed to fetch profile: $e',
      };
    }
  }

  // DELETE - Delete a staff member
  Future<bool> deleteStaff(String id) async {
    try {
      final response = await _apiService.delete('$_deleteEndpoint/$id');
      return response['success'] == true;
    } catch (e) {
      throw Exception('Failed to delete staff: $e');
    }
  }

  // Search staff
  Future<List<Staff>> searchStaff(String query) async {
    try {
      if (query.isEmpty) {
        return await getAllStaff();
      }

      final response = await _apiService.get('$_staffEndpoint/search?q=$query');
      final List<dynamic> userData = response['data'] ?? response;

      // Filter only staff, admin, and superadmin members from search results
      final staffData = userData.where((user) {
        final userRole = user['userRole'] as String?;
        return userRole == 'Staff' || userRole == 'Admin';
      }).toList();

      return staffData.map((json) => Staff.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to search staff: $e');
    }
  }

  // Filter staff by status
  Future<List<Staff>> filterByStatus(String status) async {
    try {
      // Get all staff first (which already includes status)
      final allStaff = await getAllStaff();

      if (status.toLowerCase() == 'all') {
        return allStaff;
      }

      // Filter locally by status instead of making a separate API call
      return allStaff.where((staff) {
        return staff.status?.toLowerCase() == status.toLowerCase();
      }).toList();
    } catch (e) {
      throw Exception('Failed to filter staff by status: $e');
    }
  }

  // Update user status on server
  Future<bool> updateUserStatus(String userId, String status) async {
    try {
      final response = await _apiService.patch(
        '$_staffEndpoint/$userId/status',
        body: {'status': status},
      );
      return response['success'] == true;
    } catch (e) {
      throw Exception('Failed to update user status: $e');
    }
  }
}
