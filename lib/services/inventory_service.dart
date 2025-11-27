import 'dart:convert';
import 'dart:typed_data';

import '../models/entities/item.dart';
import '../models/responses/responses.dart';
import 'api_service.dart';

class InventoryService {
  static final InventoryService _instance = InventoryService._internal();
  factory InventoryService() => _instance;
  InventoryService._internal();

  ApiService? _apiService;

  /// Initialize the service - gets the existing ApiService singleton
  Future<void> initialize() async {
    _apiService = ApiService(); // Gets the singleton instance
    // Don't call initialize() again since ApiService is already initialized
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

  // CREATE - Add a new item
  Future<Item> createItem(Item item) async {
    try {
      // Prepare form data
      final formData = item.toCreateFormData();

      Map<String, List<int>>? files;

      // If there's an image, handle it as a file
      if (item.image != null && item.image!.isNotEmpty) {
        try {
          // Decode base64 image to bytes
          final base64String = item.image!.contains(',')
              ? item.image!.split(',')[1]
              : item.image!;
          final bytes = base64Decode(base64String);
          files = {'Image': bytes};
        } catch (e) {
          print('Warning: Could not decode base64 image: $e');
          // If base64 decoding fails, send as string field
          formData['Image'] = item.image!;
        }
      }

      final response = await apiService.postMultipart(
        'items',
        fields: formData,
        files: files,
      );

      final itemResponse = ItemResponse.fromJson(response);
      if (itemResponse.success && itemResponse.data != null) {
        return itemResponse.data!;
      } else {
        throw Exception(itemResponse.message);
      }
    } catch (e) {
      throw Exception('Failed to create item: $e');
    }
  }

  // READ - Get all items
  Future<List<Item>> getAllItems({
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

      final response = await apiService.get('items', queryParams: queryParams);

      final itemListResponse = ItemListResponse.fromJson(response);
      if (itemListResponse.success && itemListResponse.data != null) {
        return itemListResponse.data!;
      } else {
        throw Exception(itemListResponse.message);
      }
    } catch (e) {
      throw Exception('Failed to fetch items: $e');
    }
  }

  // READ - Get items by category
  Future<List<Item>> getItemsByCategory(ItemCategory category) async {
    return getAllItems(category: category);
  }

  // READ - Get item by ID
  Future<Item?> getItemById(String id) async {
    try {
      final response = await apiService.get('items/$id');
      final itemResponse = ItemResponse.fromJson(response);
      if (itemResponse.success && itemResponse.data != null) {
        return itemResponse.data!;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  // UPDATE - Update an existing item
  Future<Item?> updateItem(Item updatedItem) async {
    try {
      // Prepare form data and files
      final formData = updatedItem.toUpdateFormData();
      Map<String, List<int>>? files;

      // If there's a new image, handle it as a file
      if (updatedItem.image != null && updatedItem.image!.isNotEmpty) {
        // Check if this is a new image (base64 encoded) or existing image
        // If it's base64, convert it to bytes and send as file
        if (updatedItem.image!.startsWith('data:image/') ||
            (updatedItem.image!.length > 100 &&
                !updatedItem.image!.contains('http'))) {
          // This is likely a base64 encoded image
          try {
            final base64String = updatedItem.image!.contains(',')
                ? updatedItem.image!.split(',')[1]
                : updatedItem.image!;
            final bytes = base64Decode(base64String);
            files = {'Image': bytes};
            // Remove image from form data since we're sending it as file
            formData.remove('Image');
          } catch (e) {
            // If base64 decoding fails, send as string field
            print(
              'Warning: Could not decode base64 image, sending as string field: $e',
            );
          }
        }
      }

      final response = await apiService.patchMultipart(
        'items/${updatedItem.id}',
        fields: formData,
        files: files,
      );

      final itemResponse = ItemResponse.fromJson(response);
      if (itemResponse.success) {
        // Return the updated item data if available, otherwise return the original item
        return itemResponse.data ?? updatedItem;
      } else {
        throw Exception(itemResponse.message);
      }
    } catch (e) {
      throw Exception('Failed to update item: $e');
    }
  }

  // DELETE - Archive an item (soft delete)
  Future<bool> deleteItem(String id) async {
    try {
      final response = await apiService.delete('items/archive/$id');
      final itemResponse = ItemResponse.fromJson(response);
      return itemResponse.success;
    } catch (e) {
      throw Exception('Failed to delete item: $e');
    }
  }

  // Get category statistics
  Future<Map<String, Map<String, int>>> getCategoryStats({
    bool includeBorrowedStats = false,
  }) async {
    try {
      // Get all items to calculate statistics
      final response = await apiService.get(
        'items',
        queryParams: {'pageSize': '1000'},
      );
      final itemListResponse = ItemListResponse.fromJson(response);

      if (itemListResponse.success && itemListResponse.data != null) {
        final items = itemListResponse.data!;
        final Map<String, Map<String, int>> stats = {};

        // Initialize all categories
        for (final category in ItemCategory.values) {
          stats[category.displayName] = {
            'total': 0,
            'borrowed': 0,
            'available': 0,
          };
        }

        // Calculate total items per category
        for (final item in items) {
          final categoryName = item.category.displayName;

          if (stats.containsKey(categoryName)) {
            // Increment total count
            stats[categoryName]!['total'] =
                (stats[categoryName]!['total'] ?? 0) + 1;
          }
        }

        // If requested, try to get borrowed items statistics
        if (includeBorrowedStats) {
          try {
            final borrowedStats = await _getBorrowedItemStats();
            // Merge borrowed statistics
            for (final entry in borrowedStats.entries) {
              if (stats.containsKey(entry.key)) {
                stats[entry.key]!['borrowed'] = entry.value;
              }
            }
          } catch (e) {
            // If borrowed stats fail, continue with just total counts
            print('Warning: Could not fetch borrowed item statistics: $e');
          }
        }

        // Calculate available items (total - borrowed)
        for (final category in stats.keys) {
          final total = stats[category]!['total'] ?? 0;
          final borrowed = stats[category]!['borrowed'] ?? 0;
          stats[category]!['available'] = total - borrowed;
        }

        return stats;
      } else {
        throw Exception(itemListResponse.message);
      }
    } catch (e) {
      // Fallback to empty stats if API fails
      final Map<String, Map<String, int>> stats = {};
      for (final category in ItemCategory.values) {
        stats[category.displayName] = {
          'total': 0,
          'borrowed': 0,
          'available': 0,
        };
      }
      return stats;
    }
  }

  // Helper method to get borrowed item statistics from lent items endpoint
  Future<Map<String, int>> _getBorrowedItemStats() async {
    try {
      final response = await apiService.get(
        'lentItems',
        queryParams: {'pageSize': '1000'},
      );
      final lentItemsResponse = ItemListResponse.fromJson(response);

      if (lentItemsResponse.success && lentItemsResponse.data != null) {
        final Map<String, int> borrowedStats = {};

        // Initialize all categories
        for (final category in ItemCategory.values) {
          borrowedStats[category.displayName] = 0;
        }

        // Count borrowed items by category
        // Note: This is a placeholder implementation
        // To properly implement this, you would need to:
        // 1. Fetch the actual item details for each lent item to get the category
        // 2. Count items by category that are currently lent out
        // For now, we'll return empty borrowed stats

        return borrowedStats;
      }
      return {};
    } catch (e) {
      return {};
    }
  }

  // Search items
  Future<List<Item>> searchItems(String query) async {
    if (query.isEmpty) return getAllItems();
    return getAllItems(search: query);
  }

  // Get archived items
  Future<List<Item>> getArchivedItems({int page = 1, int pageSize = 50}) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'pageSize': pageSize.toString(),
      };

      final response = await apiService.get(
        'archiveitems',
        queryParams: queryParams,
      );

      final itemListResponse = ItemListResponse.fromJson(response);
      if (itemListResponse.success && itemListResponse.data != null) {
        return itemListResponse.data!;
      } else {
        throw Exception(itemListResponse.message);
      }
    } catch (e) {
      throw Exception('Failed to fetch archived items: $e');
    }
  }

  // Restore archived item
  Future<bool> restoreItem(String id) async {
    try {
      final response = await apiService.delete('archiveitems/restore/$id');
      final itemResponse = ItemResponse.fromJson(response);
      return itemResponse.success;
    } catch (e) {
      throw Exception('Failed to restore item: $e');
    }
  }

  // Permanently delete archived item
  Future<bool> permanentlyDeleteItem(String id) async {
    try {
      final response = await apiService.delete('archiveitems/$id');
      final itemResponse = ItemResponse.fromJson(response);
      return itemResponse.success;
    } catch (e) {
      throw Exception('Failed to permanently delete item: $e');
    }
  }

  // Import items from Excel file
  Future<Map<String, dynamic>> importItems(List<int> fileBytes, String filename) async {
    try {
      final response = await apiService.postMultipart(
        'items/import',
        files: {'file': fileBytes},
        fileNames: {'file': filename},
      );
      return response;
    } catch (e) {
      throw Exception('Failed to import items: $e');
    }
  }

  // Export items to Excel file
  Future<Uint8List> exportItems() async {
    try {
      return await apiService.download('items/export');
    } catch (e) {
      throw Exception('Failed to export items: $e');
    }
  }

  // Get dashboard summary data
  Future<SummaryData> getDashboardSummary() async {
    try {
      final response = await apiService.get('summary');
      final summaryResponse = SummaryResponse.fromJson(response);

      if (summaryResponse.success && summaryResponse.data != null) {
        return summaryResponse.data!;
      } else {
        throw Exception(summaryResponse.message);
      }
    } catch (e) {
      throw Exception('Failed to fetch dashboard summary: $e');
    }
  }
}
