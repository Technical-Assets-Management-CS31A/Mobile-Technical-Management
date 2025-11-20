import '../models/entities/lend_item.dart';
import '../models/responses/lend_item_response.dart';
import 'api_service.dart';

class LendService {
  static final LendService _instance = LendService._internal();
  factory LendService() => _instance;
  LendService._internal();

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

  // CREATE - Lend/Borrow a new item
  Future<LendItem> createLendItem(LendItem lendItem) async {
    try {
      final response = await apiService.post(
        'lentItems',
        body: lendItem.toCreateJson(),
      );

      final lendItemResponse = LendItemResponse.fromJson(response);
      if (lendItemResponse.success && lendItemResponse.data != null) {
        return lendItemResponse.data!;
      } else {
        throw Exception(lendItemResponse.message);
      }
    } catch (e) {
      throw Exception('Failed to create lend item: $e');
    }
  }

  // READ - Get all lent items
  Future<List<LendItem>> getAllLentItems({
    int page = 1,
    int pageSize = 50,
    String? search,
    String? status,
    String? borrowerRole,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'pageSize': pageSize.toString(),
      };

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }
      if (borrowerRole != null && borrowerRole.isNotEmpty) {
        queryParams['borrowerRole'] = borrowerRole;
      }

      final response = await apiService.get(
        'lentItems',
        queryParams: queryParams,
      );

      final lendItemListResponse = LendItemListResponse.fromJson(response);
      if (lendItemListResponse.success && lendItemListResponse.data != null) {
        return lendItemListResponse.data!;
      } else {
        throw Exception(lendItemListResponse.message);
      }
    } catch (e) {
      throw Exception('Failed to fetch lent items: $e');
    }
  }

  // READ - Get lent item by ID
  Future<LendItem?> getLentItemById(String id) async {
    try {
      final response = await apiService.get('lentItems/$id');
      final lendItemResponse = LendItemResponse.fromJson(response);
      if (lendItemResponse.success && lendItemResponse.data != null) {
        return lendItemResponse.data!;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  // READ - Get lent items by item ID
  Future<List<LendItem>> getLentItemsByItemId(String itemId) async {
    try {
      final queryParams = <String, String>{'itemId': itemId};

      final response = await apiService.get(
        'lentItems',
        queryParams: queryParams,
      );

      final lendItemListResponse = LendItemListResponse.fromJson(response);
      if (lendItemListResponse.success && lendItemListResponse.data != null) {
        return lendItemListResponse.data!;
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  // READ - Get items by status
  Future<List<LendItem>> getItemsByStatus(String status) async {
    return getAllLentItems(status: status);
  }

  // READ - Get items by borrower role
  Future<List<LendItem>> getItemsByBorrowerRole(String role) async {
    return getAllLentItems(borrowerRole: role);
  }

  // UPDATE - Update an existing lent item
  Future<LendItem?> updateLentItem(LendItem updatedItem) async {
    try {
      final response = await apiService.patch(
        'lentItems/${updatedItem.id}',
        body: updatedItem.toCreateJson(),
      );

      final lendItemResponse = LendItemResponse.fromJson(response);
      if (lendItemResponse.success) {
        return lendItemResponse.data ?? updatedItem;
      } else {
        throw Exception(lendItemResponse.message);
      }
    } catch (e) {
      throw Exception('Failed to update lent item: $e');
    }
  }

  // UPDATE - Return/Complete a borrowed item
  Future<LendItem?> returnLentItem(String id, {String? returnRemarks}) async {
    try {
      final body = <String, dynamic>{
        'status': 'Returned',
        if (returnRemarks != null) 'remarks': returnRemarks,
      };

      final response = await apiService.patch(
        'lentItems/$id/return',
        body: body,
      );

      final lendItemResponse = LendItemResponse.fromJson(response);
      if (lendItemResponse.success) {
        return lendItemResponse.data;
      } else {
        throw Exception(lendItemResponse.message);
      }
    } catch (e) {
      throw Exception('Failed to return lent item: $e');
    }
  }

  // DELETE - Delete a lent item record
  Future<bool> deleteLentItem(String id) async {
    try {
      final response = await apiService.delete('lentItems/archive/$id');
      final lendItemResponse = LendItemResponse.fromJson(response);
      return lendItemResponse.success;
    } catch (e) {
      throw Exception('Failed to delete lent item: $e');
    }
  }

  // Search lent items
  Future<List<LendItem>> searchLentItems(String query) async {
    if (query.isEmpty) return getAllLentItems();
    return getAllLentItems(search: query);
  }

  // Get borrowing history for a specific borrower
  Future<List<LendItem>> getBorrowerHistory({
    required String firstName,
    required String lastName,
  }) async {
    try {
      final queryParams = <String, String>{
        'borrowerFirstName': firstName,
        'borrowerLastName': lastName,
      };

      final response = await apiService.get(
        'lentItems',
        queryParams: queryParams,
      );

      final lendItemListResponse = LendItemListResponse.fromJson(response);
      if (lendItemListResponse.success && lendItemListResponse.data != null) {
        return lendItemListResponse.data!;
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  // Get statistics
  Future<Map<String, int>> getStatistics() async {
    try {
      final allItems = await getAllLentItems(pageSize: 1000);

      final stats = {
        'total': allItems.length,
        'active': allItems
            .where(
              (item) =>
                  item.status == null ||
                  item.status == 'Active' ||
                  item.status == 'Borrowed',
            )
            .length,
        'returned': allItems.where((item) => item.status == 'Returned').length,
        'overdue': allItems.where((item) => item.status == 'Overdue').length,
        'students': allItems
            .where((item) => item.borrowerRole == 'Student')
            .length,
        'teachers': allItems
            .where((item) => item.borrowerRole == 'Teacher')
            .length,
        'staff': allItems.where((item) => item.borrowerRole == 'Staff').length,
        'guests': allItems.where((item) => item.borrowerRole == 'Guest').length,
      };

      return stats;
    } catch (e) {
      return {
        'total': 0,
        'active': 0,
        'returned': 0,
        'overdue': 0,
        'students': 0,
        'teachers': 0,
        'staff': 0,
        'guests': 0,
      };
    }
  }

  // Get recent borrowing activity
  Future<List<LendItem>> getRecentActivity({int limit = 10}) async {
    try {
      final items = await getAllLentItems(page: 1, pageSize: limit);
      return items;
    } catch (e) {
      return [];
    }
  }
}
