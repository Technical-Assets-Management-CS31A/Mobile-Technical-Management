import '../models/entities/item.dart';

class InventoryService {
  static final InventoryService _instance = InventoryService._internal();
  factory InventoryService() => _instance;
  InventoryService._internal();

  // In-memory storage for demo purposes
  // In a real app, this would connect to a database or API
  List<Item> _items = [
    Item(
      id: 1,
      serialNumber: 'CBL-001',
      itemName: 'HDMI Cable 1m',
      itemImage: '',
      itemCategory: 'Cables',
      condition: 'Good',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
    Item(
      id: 2,
      serialNumber: 'CBL-002',
      itemName: 'USB-C Cable 2m',
      itemImage: '',
      itemCategory: 'Cables',
      condition: 'In Use',
      createdAt: DateTime.now().subtract(const Duration(days: 25)),
      updatedAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    Item(
      id: 3,
      serialNumber: 'ADP-010',
      itemName: 'USB-C to HDMI Adapter',
      itemImage: '',
      itemCategory: 'Adapters',
      condition: 'Fair',
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    Item(
      id: 4,
      serialNumber: 'PRP-007',
      itemName: 'Wireless Mouse',
      itemImage: '',
      itemCategory: 'Peripherals',
      condition: 'Good',
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
      updatedAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
  ];

  int _nextId = 5;

  // CREATE - Add a new item
  Future<Item> createItem(Item item) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 500));

    final newItem = Item(
      id: _nextId++,
      serialNumber: item.serialNumber,
      itemName: item.itemName,
      itemImage: item.itemImage,
      itemCategory: item.itemCategory,
      condition: item.condition,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    _items.add(newItem);
    return newItem;
  }

  // READ - Get all items
  Future<List<Item>> getAllItems() async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 300));
    return List.from(_items);
  }

  // READ - Get items by category
  Future<List<Item>> getItemsByCategory(String category) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 300));
    return _items
        .where(
          (item) => item.itemCategory.toLowerCase() == category.toLowerCase(),
        )
        .toList();
  }

  // READ - Get item by ID
  Future<Item?> getItemById(int id) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      return _items.firstWhere((item) => item.id == id);
    } catch (e) {
      return null;
    }
  }

  // UPDATE - Update an existing item
  Future<Item?> updateItem(Item updatedItem) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 500));

    final index = _items.indexWhere((item) => item.id == updatedItem.id);
    if (index != -1) {
      final item = Item(
        id: updatedItem.id,
        serialNumber: updatedItem.serialNumber,
        itemName: updatedItem.itemName,
        itemImage: updatedItem.itemImage,
        itemCategory: updatedItem.itemCategory,
        condition: updatedItem.condition,
        createdAt: _items[index].createdAt,
        updatedAt: DateTime.now(),
      );

      _items[index] = item;
      return item;
    }
    return null;
  }

  // DELETE - Delete an item
  Future<bool> deleteItem(int id) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 400));

    final index = _items.indexWhere((item) => item.id == id);
    if (index != -1) {
      _items.removeAt(index);
      return true;
    }
    return false;
  }

  // Get category statistics
  Future<Map<String, Map<String, int>>> getCategoryStats() async {
    await Future.delayed(const Duration(milliseconds: 200));

    final Map<String, Map<String, int>> stats = {};
    final categories = [
      'Cables',
      'Adapters',
      'Peripherals',
      'Networking',
      'Storage',
      'Audio',
      'Display',
      'Other',
    ];

    // Initialize all categories
    for (final category in categories) {
      stats[category] = {'total': 0, 'borrowed': 0, 'available': 0};
    }

    // Count items by category and condition
    for (final item in _items) {
      if (stats.containsKey(item.itemCategory)) {
        stats[item.itemCategory]!['total'] =
            (stats[item.itemCategory]!['total'] ?? 0) + 1;
        if (item.condition.toLowerCase() == 'in use') {
          stats[item.itemCategory]!['borrowed'] =
              (stats[item.itemCategory]!['borrowed'] ?? 0) + 1;
        }
      }
    }

    // Calculate available items
    for (final category in stats.keys) {
      final total = stats[category]!['total'] ?? 0;
      final borrowed = stats[category]!['borrowed'] ?? 0;
      stats[category]!['available'] = total - borrowed;
    }

    return stats;
  }

  // Search items
  Future<List<Item>> searchItems(String query) async {
    await Future.delayed(const Duration(milliseconds: 300));

    if (query.isEmpty) return _items;

    final lowerQuery = query.toLowerCase();
    return _items
        .where(
          (item) =>
              item.itemName.toLowerCase().contains(lowerQuery) ||
              item.serialNumber.toLowerCase().contains(lowerQuery) ||
              item.itemCategory.toLowerCase().contains(lowerQuery),
        )
        .toList();
  }
}
