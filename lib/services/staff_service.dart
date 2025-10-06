import '../models/entities/staff.dart';

class StaffService {
  static final StaffService _instance = StaffService._internal();
  factory StaffService() => _instance;
  StaffService._internal();

  // In-memory storage for demo purposes
  // In a real app, this would connect to a database or API
  final List<Staff> _staff = [
    Staff(
      id: '1',
      firstName: 'Alice',
      lastName: 'Johnson',
      middleName: 'Marie',
      position: 'Technical',
      email: 'alice@example.com',
      phoneNumber: '09123456789',
      username: 'alice.johnson',
      password: 'password123',
      status: 'active',
      createdAt: DateTime.now().subtract(const Duration(days: 180)),
      updatedAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
    Staff(
      id: '2',
      firstName: 'Bob',
      lastName: 'Martinez',
      position: 'Admin',
      email: 'bob@example.com',
      phoneNumber: '09234567890',
      username: 'bob.martinez',
      password: 'password123',
      status: 'active',
      createdAt: DateTime.now().subtract(const Duration(days: 150)),
      updatedAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    Staff(
      id: '3',
      firstName: 'Carla',
      lastName: 'Reyes',
      middleName: 'Santos',
      position: 'Technical',
      email: 'carla@example.com',
      phoneNumber: '09345678901',
      username: 'carla.reyes',
      password: 'password123',
      status: 'offline',
      createdAt: DateTime.now().subtract(const Duration(days: 120)),
      updatedAt: DateTime.now().subtract(const Duration(days: 10)),
    ),
    Staff(
      id: '4',
      firstName: 'David',
      lastName: 'Smith',
      position: 'Admin',
      email: 'david@example.com',
      phoneNumber: '09456789012',
      username: 'david.smith',
      password: 'password123',
      status: 'active',
      createdAt: DateTime.now().subtract(const Duration(days: 90)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    Staff(
      id: '5',
      firstName: 'Eve',
      lastName: 'Thompson',
      position: 'Technical',
      email: 'eve@example.com',
      phoneNumber: '09567890123',
      username: 'eve.thompson',
      password: 'password123',
      status: 'active',
      createdAt: DateTime.now().subtract(const Duration(days: 60)),
      updatedAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
  ];

  int _nextId = 6;

  // CREATE - Add a new staff member
  Future<Staff> createStaff(Staff staff) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 500));

    final newStaff = staff.copyWith(
      id: (_nextId++).toString(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    _staff.insert(0, newStaff);
    return newStaff;
  }

  // READ - Get all staff
  Future<List<Staff>> getAllStaff() async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 300));
    return List.from(_staff);
  }

  // READ - Get staff by ID
  Future<Staff?> getStaffById(String id) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      return _staff.firstWhere((staff) => staff.id == id);
    } catch (e) {
      return null;
    }
  }

  // READ - Get staff by position
  Future<List<Staff>> getStaffByPosition(String position) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 300));
    return _staff
        .where(
          (staff) => staff.position.toLowerCase() == position.toLowerCase(),
        )
        .toList();
  }

  // READ - Get active staff count
  Future<int> getActiveStaffCount() async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 200));
    return _staff
        .where((staff) => staff.status?.toLowerCase() == 'active')
        .length;
  }

  // READ - Get staff statistics
  Future<Map<String, int>> getStaffStats() async {
    await Future.delayed(const Duration(milliseconds: 200));

    final stats = {
      'total': _staff.length,
      'active': 0,
      'offline': 0,
      'technical': 0,
      'admin': 0,
    };

    for (final staff in _staff) {
      // Count by status
      final status = staff.status?.toLowerCase() ?? '';
      if (status == 'active') {
        stats['active'] = (stats['active'] ?? 0) + 1;
      } else if (status == 'offline') {
        stats['offline'] = (stats['offline'] ?? 0) + 1;
      }

      // Count by position
      final position = staff.position.toLowerCase();
      if (position == 'technical') {
        stats['technical'] = (stats['technical'] ?? 0) + 1;
      } else if (position == 'admin') {
        stats['admin'] = (stats['admin'] ?? 0) + 1;
      }
    }

    return stats;
  }

  // UPDATE - Update an existing staff member
  Future<Staff?> updateStaff(Staff updatedStaff) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 500));

    final index = _staff.indexWhere((staff) => staff.id == updatedStaff.id);
    if (index != -1) {
      final staff = updatedStaff.copyWith(
        createdAt: _staff[index].createdAt,
        updatedAt: DateTime.now(),
      );

      _staff[index] = staff;
      return staff;
    }
    return null;
  }

  // DELETE - Delete a staff member
  Future<bool> deleteStaff(String id) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 400));

    final index = _staff.indexWhere((staff) => staff.id == id);
    if (index != -1) {
      _staff.removeAt(index);
      return true;
    }
    return false;
  }

  // Search staff
  Future<List<Staff>> searchStaff(String query) async {
    await Future.delayed(const Duration(milliseconds: 300));

    if (query.isEmpty) return _staff;

    final lowerQuery = query.toLowerCase();
    return _staff
        .where(
          (staff) =>
              staff.name.toLowerCase().contains(lowerQuery) ||
              staff.email.toLowerCase().contains(lowerQuery) ||
              staff.position.toLowerCase().contains(lowerQuery) ||
              staff.username.toLowerCase().contains(lowerQuery) ||
              (staff.phoneNumber.contains(lowerQuery)),
        )
        .toList();
  }

  // Filter staff by status
  Future<List<Staff>> filterByStatus(String status) async {
    await Future.delayed(const Duration(milliseconds: 200));

    if (status.toLowerCase() == 'all') return _staff;

    return _staff
        .where((staff) => staff.status?.toLowerCase() == status.toLowerCase())
        .toList();
  }
}
