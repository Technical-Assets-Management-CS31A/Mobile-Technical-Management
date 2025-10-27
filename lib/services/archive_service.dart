import '../models/entities/item.dart';
import '../models/entities/user.dart';
import '../models/responses/responses.dart';
import 'api_service.dart';

class ArchiveService {
  static final ArchiveService _instance = ArchiveService._internal();
  factory ArchiveService() => _instance;
  ArchiveService._internal();

  ApiService? _apiService;

  /// Initialize the service - gets the existing ApiService singleton
  Future<void> initialize() async {
    _apiService = ApiService(); // Gets the singleton instance
  }

  /// Alternative: Initialize with existing ApiService instance
  void initializeWithApiService(ApiService apiService) {
    _apiService = apiService;
  }

  /// Get the ApiService instance (auto-initializes if needed)
  ApiService get apiService {
    if (_apiService == null) {
      _apiService = ApiService(); // Gets the singleton instance
    }
    return _apiService!;
  }

  // ========== HELPER METHODS ==========

  /// Parse archived item from the specific archive API response format
  Item _parseArchivedItem(Map<String, dynamic> json) {
    try {
      return Item(
        id: json['id']?.toString() ?? json['itemId']?.toString() ?? '',
        serialNumber: json['serialNumber']?.toString() ?? '',
        image: json['image']?.toString(),
        itemName: json['itemName']?.toString() ?? 'Archived Item',
        itemType: json['itemType']?.toString() ?? 'Unknown',
        itemModel: json['itemModel']?.toString(),
        itemMake: json['itemMake']?.toString() ?? 'Unknown',
        description: json['description']?.toString(),
        category: _parseCategory(json['category']?.toString()),
        condition: _parseCondition(json['condition']?.toString()),
        barcode: json['barcode']?.toString(),
        createdAt:
            _parseDateTime(json['archivedAt']?.toString()) ?? DateTime.now(),
        updatedAt:
            _parseDateTime(json['archivedAt']?.toString()) ?? DateTime.now(),
      );
    } catch (e) {
      // Fallback item if parsing fails
      return Item(
        id: json['id']?.toString() ?? 'unknown',
        serialNumber: '',
        itemName: 'Archived Item',
        itemType: 'Unknown',
        itemMake: 'Unknown',
        category: ItemCategory.Miscellaneous,
        condition: ItemCondition.Good,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
  }

  /// Safely parse ItemCategory
  ItemCategory _parseCategory(String? categoryStr) {
    if (categoryStr == null || categoryStr.isEmpty) {
      return ItemCategory.Miscellaneous;
    }
    try {
      return ItemCategory.fromString(categoryStr);
    } catch (e) {
      return ItemCategory.Miscellaneous;
    }
  }

  /// Safely parse ItemCondition
  ItemCondition _parseCondition(String? conditionStr) {
    if (conditionStr == null || conditionStr.isEmpty) {
      return ItemCondition.Good;
    }
    try {
      return ItemCondition.fromString(conditionStr);
    } catch (e) {
      return ItemCondition.Good;
    }
  }

  /// Safely parse DateTime
  DateTime? _parseDateTime(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) {
      return null;
    }
    try {
      return DateTime.parse(dateStr);
    } catch (e) {
      return null;
    }
  }

  // ========== ARCHIVED ITEMS ==========

  /// Get all archived items
  Future<List<Item>> getArchivedItems({
    int page = 1,
    int pageSize = 50,
    String? search,
    ItemCategory? category,
    ItemCondition? condition,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'pageSize': pageSize.toString(),
      };

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (category != null) {
        queryParams['category'] = category.name;
      }
      if (condition != null) {
        queryParams['condition'] = condition.name;
      }

      final response = await apiService.get(
        'archiveitems',
        queryParams: queryParams,
      );

      // Handle the specific archive API response format
      if (response['success'] == true && response['data'] != null) {
        final List<dynamic> itemsData = response['data'];
        return itemsData
            .map((itemJson) => _parseArchivedItem(itemJson))
            .toList();
      } else {
        throw Exception(
          response['message'] ?? 'Failed to fetch archived items',
        );
      }
    } catch (e) {
      throw Exception('Failed to fetch archived items: $e');
    }
  }

  /// Get archived item by ID
  Future<Item?> getArchivedItemById(String id) async {
    try {
      final response = await apiService.get('archiveitems/$id');
      if (response['success'] == true && response['data'] != null) {
        return _parseArchivedItem(response['data']);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Restore an archived item (move it back to active items)
  Future<bool> restoreItem(String id) async {
    try {
      final response = await apiService.delete('archiveitems/restore/$id');
      final itemResponse = ItemResponse.fromJson(response);
      return itemResponse.success;
    } catch (e) {
      throw Exception('Failed to restore item: $e');
    }
  }

  /// Permanently delete an archived item
  Future<bool> permanentlyDeleteItem(String id) async {
    try {
      final response = await apiService.delete('archiveitems/$id');
      final itemResponse = ItemResponse.fromJson(response);
      return itemResponse.success;
    } catch (e) {
      throw Exception('Failed to permanently delete item: $e');
    }
  }

  /// Search archived items
  Future<List<Item>> searchArchivedItems(String query) async {
    if (query.isEmpty) return getArchivedItems();
    return getArchivedItems(search: query);
  }

  // ========== ARCHIVED USERS/STAFF ==========

  /// Get all archived users/staff
  Future<List<Staff>> getArchivedUsers() async {
    try {
      final response = await apiService.get('ArchiveUsers');

      if (response['success'] == true && response['data'] != null) {
        final List<dynamic> staffData = response['data'];
        return staffData.map((json) => Staff.fromJson(json)).toList();
      } else {
        throw Exception(
          response['message'] ?? 'Failed to fetch archived users',
        );
      }
    } catch (e) {
      throw Exception('Failed to fetch archived users: $e');
    }
  }

  /// Get archived user by ID
  Future<Staff?> getArchivedUserById(String id) async {
    try {
      final response = await apiService.get('ArchiveUsers/$id');
      if (response['success'] == true && response['data'] != null) {
        return Staff.fromJson(response['data']);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Restore an archived user (move it back to active users)
  Future<bool> restoreUser(String id) async {
    try {
      final response = await apiService.delete('ArchiveUsers/restore/$id');
      return response['success'] == true;
    } catch (e) {
      throw Exception('Failed to restore user: $e');
    }
  }

  /// Permanently delete an archived user
  Future<bool> permanentlyDeleteUser(String id) async {
    try {
      final response = await apiService.delete('ArchiveUsers/permanent-delete$id');
      return response['success'] == true;
    } catch (e) {
      throw Exception('Failed to permanently delete user: $e');
    }
  }

  /// Search archived users
  Future<List<Staff>> searchArchivedUsers(String query) async {
    // Since backend doesn't support search parameters,
    // we get all users and filter client-side
    final allUsers = await getArchivedUsers();
    if (query.isEmpty) return allUsers;

    return allUsers.where((user) {
      return user.name.toLowerCase().contains(query.toLowerCase()) ||
          user.email.toLowerCase().contains(query.toLowerCase()) ||
          (user.position?.toLowerCase().contains(query.toLowerCase()) ??
              false) ||
          user.username.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  // ========== ARCHIVE STATISTICS ==========

  /// Get archive statistics
  Future<Map<String, int>> getArchiveStats() async {
    try {
      final response = await apiService.get('archive/stats');
      if (response['success'] == true && response['data'] != null) {
        return Map<String, int>.from(response['data']);
      }
      return {'archived_items': 0, 'archived_users': 0};
    } catch (e) {
      return {'archived_items': 0, 'archived_users': 0};
    }
  }
}
