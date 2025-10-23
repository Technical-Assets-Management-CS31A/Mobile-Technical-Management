import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/entities/staff.dart';
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

      return staffData.map((json) => Staff.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch staff: $e');
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
      final response = await _apiService.get('$_staffEndpoint?status=Online');
      final List<dynamic> userData = response['data'] ?? response;

      // Filter only active staff, admin, and superadmin members
      final activeStaff = userData.where((user) {
        final userRole = user['userRole'] as String?;
        final status = user['status'] as String?;
        return (userRole == 'Staff' ||
                userRole == 'Admin') &&
            status?.toLowerCase() == 'online';
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
          if (status == 'online') {
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
      // Prepare JSON data for PATCH request
      final jsonData = updatedStaff.toUpdateJson();

      final response = await _apiService.patch(
        'users/admin-or-staff/profile${updatedStaff.id}',
        body: jsonData,
      );

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
      if (status.toLowerCase() == 'all') {
        return await getAllStaff();
      }

      final response = await _apiService.get('$_staffEndpoint?status=$status');
      final List<dynamic> userData = response['data'] ?? response;

      // Filter only staff, admin, and superadmin members with the specified status
      final staffData = userData.where((user) {
        final userRole = user['userRole'] as String?;
        final userStatus = user['status'] as String?;
        return (userRole == 'Staff' || userRole == 'Admin') &&
            userStatus?.toLowerCase() == status.toLowerCase();
      }).toList();

      return staffData.map((json) => Staff.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to filter staff by status: $e');
    }
  }
}
