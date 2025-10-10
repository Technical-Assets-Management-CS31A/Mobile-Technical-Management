import '../models/entities/item.dart';
import '../services/inventory_service.dart';

/// Test utility to verify inventory API integration
class InventoryApiTest {
  static final InventoryService _inventoryService = InventoryService();

  /// Test basic API connectivity and CRUD operations
  static Future<void> runBasicTests() async {
    try {
      print('🧪 Starting Inventory API Tests...');

      // Initialize service
      await _inventoryService.initialize();
      print('✅ Service initialized successfully');

      // Test 1: Get all items
      print('📋 Testing: Get all items...');
      final items = await _inventoryService.getAllItems(pageSize: 5);
      print('✅ Retrieved ${items.length} items');

      // Test 2: Get items by category
      print('📂 Testing: Get items by category...');
      final electronicsItems = await _inventoryService.getItemsByCategory(
        ItemCategory.Electronics,
      );
      print('✅ Retrieved ${electronicsItems.length} electronics items');

      // Test 3: Search items
      print('🔍 Testing: Search items...');
      final searchResults = await _inventoryService.searchItems('test');
      print('✅ Search returned ${searchResults.length} results');

      // Test 4: Get category statistics
      print('📊 Testing: Get category statistics...');
      final stats = await _inventoryService.getCategoryStats();
      print('✅ Retrieved stats for ${stats.length} categories');

      // Test 5: Get archived items
      print('🗄️ Testing: Get archived items...');
      final archivedItems = await _inventoryService.getArchivedItems(
        pageSize: 5,
      );
      print('✅ Retrieved ${archivedItems.length} archived items');

      print('🎉 All basic tests passed!');
    } catch (e) {
      print('❌ Test failed: $e');
      rethrow;
    }
  }

  /// Test item creation (use with caution in production)
  static Future<Item?> testCreateItem() async {
    try {
      print('➕ Testing: Create item...');

      final testItem = Item(
        id: '', // Will be set by API
        serialNumber: 'TEST-${DateTime.now().millisecondsSinceEpoch}',
        itemName: 'Test Item',
        itemType: 'Test Type',
        itemMake: 'Test Make',
        category: ItemCategory.Miscellaneous,
        condition: ItemCondition.Good,
        description: 'This is a test item created by API test',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final createdItem = await _inventoryService.createItem(testItem);
      print('✅ Item created successfully with ID: ${createdItem.id}');
      return createdItem;
    } catch (e) {
      print('❌ Create item test failed: $e');
      return null;
    }
  }

  /// Test item update (use with caution in production)
  static Future<bool> testUpdateItem(Item item) async {
    try {
      print('✏️ Testing: Update item...');

      final updatedItem = item.copyWith(
        itemName: '${item.itemName} (Updated)',
        updatedAt: DateTime.now(),
      );

      final result = await _inventoryService.updateItem(updatedItem);
      if (result != null) {
        print('✅ Item updated successfully');
        return true;
      } else {
        print('❌ Item update returned null');
        return false;
      }
    } catch (e) {
      print('❌ Update item test failed: $e');
      return false;
    }
  }

  /// Test item deletion (use with caution in production)
  static Future<bool> testDeleteItem(String itemId) async {
    try {
      print('🗑️ Testing: Delete item...');

      final result = await _inventoryService.deleteItem(itemId);
      if (result) {
        print('✅ Item deleted successfully');
        return true;
      } else {
        print('❌ Item deletion failed');
        return false;
      }
    } catch (e) {
      print('❌ Delete item test failed: $e');
      return false;
    }
  }

  /// Run full CRUD test cycle (use with caution in production)
  static Future<void> runFullCrudTest() async {
    try {
      print('🔄 Starting Full CRUD Test Cycle...');

      // Create
      final createdItem = await testCreateItem();
      if (createdItem == null) {
        print('❌ CRUD test failed at creation step');
        return;
      }

      // Read
      final retrievedItem = await _inventoryService.getItemById(createdItem.id);
      if (retrievedItem == null) {
        print('❌ CRUD test failed at read step');
        return;
      }
      print('✅ Item retrieved successfully');

      // Update
      final updateSuccess = await testUpdateItem(createdItem);
      if (!updateSuccess) {
        print('❌ CRUD test failed at update step');
        return;
      }

      // Delete
      final deleteSuccess = await testDeleteItem(createdItem.id);
      if (!deleteSuccess) {
        print('❌ CRUD test failed at delete step');
        return;
      }

      print('🎉 Full CRUD test cycle completed successfully!');
    } catch (e) {
      print('❌ Full CRUD test failed: $e');
      rethrow;
    }
  }
}
