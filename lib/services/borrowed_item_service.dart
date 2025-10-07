import '../models/entities/borrowed_item.dart';

class BorrowedItemService {
  static final BorrowedItemService _instance = BorrowedItemService._internal();
  factory BorrowedItemService() => _instance;
  BorrowedItemService._internal();

  // In-memory storage for demo purposes
  final List<BorrowedItem> _borrowedItems = [
    BorrowedItem(
      id: 1,
      itemName: 'Wireless Mouse',
      borrowedId: 'BRW-2024-001',
      teacher: 'Mr. John D. Santos',
      room: 'A-207',
      occupied: 'Henry Bautista',
      condition: 'Good',
      eventDate: '2025-10-05 2:30 PM',
      status: 'Returned',
    ),
    BorrowedItem(
      id: 2,
      itemName: 'HDMI Projector',
      borrowedId: 'BRW-2024-002',
      teacher: 'Ms. Fiona Cruz',
      room: 'B-101',
      occupied: 'Uzziah Ramos',
      condition: 'Good',
      eventDate: '2025-10-04 10:30 AM',
      status: 'In Use',
    ),
    BorrowedItem(
      id: 3,
      itemName: 'Mechanical Keyboard',
      borrowedId: 'BRW-2024-003',
      teacher: 'Mr. Nilo Bautista',
      room: 'C-301',
      occupied: 'Sung Jin Ho',
      condition: 'Fair',
      eventDate: '2025-10-03 3:00 PM',
      status: 'For Repair',
    ),
    BorrowedItem(
      id: 4,
      itemName: 'USB-C Cable 2m',
      borrowedId: 'BRW-2024-004',
      teacher: 'Dr. Maria Santos',
      room: 'A-103',
      occupied: 'Alex Johnson',
      condition: 'Good',
      eventDate: '2025-10-02 9:15 AM',
      status: 'Returned',
    ),
    BorrowedItem(
      id: 5,
      itemName: 'Laptop Adapter',
      borrowedId: 'BRW-2024-005',
      teacher: 'Prof. Robert Chen',
      room: 'B-205',
      occupied: 'Sarah Williams',
      condition: 'Good',
      eventDate: '2025-10-01 1:45 PM',
      status: 'Returned',
    ),
    BorrowedItem(
      id: 6,
      itemName: 'Wireless Presenter',
      borrowedId: 'BRW-2024-006',
      teacher: 'Ms. Jennifer Lopez',
      room: 'A-401',
      occupied: 'Michael Brown',
      condition: 'Excellent',
      eventDate: '2025-09-30 11:00 AM',
      status: 'In Use',
    ),
    BorrowedItem(
      id: 7,
      itemName: 'Webcam HD',
      borrowedId: 'BRW-2024-007',
      teacher: 'Dr. James Wilson',
      room: 'C-102',
      occupied: 'Emily Davis',
      condition: 'Good',
      eventDate: '2025-09-29 4:20 PM',
      status: 'Damaged',
    ),
    BorrowedItem(
      id: 8,
      itemName: 'Extension Cord 5m',
      borrowedId: 'BRW-2024-008',
      teacher: 'Mr. David Martinez',
      room: 'B-303',
      occupied: 'Chris Anderson',
      condition: 'Fair',
      eventDate: '2025-09-28 8:30 AM',
      status: 'Returned',
    ),
  ];

  int _nextId = 9;

  // READ - Get all borrowed items
  Future<List<BorrowedItem>> getAllBorrowedItems() async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 300));
    return List.from(_borrowedItems);
  }

  // READ - Get borrowed item by ID
  Future<BorrowedItem?> getBorrowedItemById(int id) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      return _borrowedItems.firstWhere((item) => item.id == id);
    } catch (e) {
      return null;
    }
  }

  // READ - Get items by status
  Future<List<BorrowedItem>> getItemsByStatus(String status) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 300));
    return _borrowedItems
        .where((item) => item.status.toLowerCase() == status.toLowerCase())
        .toList();
  }

  // CREATE - Add a new borrowed item
  Future<BorrowedItem> createBorrowedItem(BorrowedItem item) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 500));

    final newItem = BorrowedItem(
      id: _nextId++,
      itemName: item.itemName,
      borrowedId: item.borrowedId,
      teacher: item.teacher,
      room: item.room,
      occupied: item.occupied,
      condition: item.condition,
      eventDate: item.eventDate,
      status: item.status,
    );

    _borrowedItems.add(newItem);
    return newItem;
  }

  // UPDATE - Update an existing borrowed item
  Future<BorrowedItem?> updateBorrowedItem(BorrowedItem updatedItem) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 500));

    final index = _borrowedItems.indexWhere(
      (item) => item.id == updatedItem.id,
    );
    if (index != -1) {
      _borrowedItems[index] = updatedItem;
      return updatedItem;
    }
    return null;
  }

  // DELETE - Delete a borrowed item
  Future<bool> deleteBorrowedItem(int id) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 400));

    final index = _borrowedItems.indexWhere((item) => item.id == id);
    if (index != -1) {
      _borrowedItems.removeAt(index);
      return true;
    }
    return false;
  }

  // Search borrowed items
  Future<List<BorrowedItem>> searchBorrowedItems(String query) async {
    await Future.delayed(const Duration(milliseconds: 300));

    if (query.isEmpty) return _borrowedItems;

    final lowerQuery = query.toLowerCase();
    return _borrowedItems
        .where(
          (item) =>
              item.itemName.toLowerCase().contains(lowerQuery) ||
              item.borrowedId.toLowerCase().contains(lowerQuery) ||
              item.teacher.toLowerCase().contains(lowerQuery) ||
              item.room.toLowerCase().contains(lowerQuery) ||
              item.occupied.toLowerCase().contains(lowerQuery) ||
              item.condition.toLowerCase().contains(lowerQuery) ||
              item.status.toLowerCase().contains(lowerQuery),
        )
        .toList();
  }

  // Get statistics
  Future<Map<String, int>> getStatistics() async {
    await Future.delayed(const Duration(milliseconds: 200));

    final stats = {
      'total': _borrowedItems.length,
      'inUse': _borrowedItems.where((item) => item.status == 'In Use').length,
      'returned': _borrowedItems
          .where((item) => item.status == 'Returned')
          .length,
      'damaged': _borrowedItems
          .where((item) => item.status == 'Damaged')
          .length,
      'forRepair': _borrowedItems
          .where((item) => item.status == 'For Repair')
          .length,
    };

    return stats;
  }
}

