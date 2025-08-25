import 'package:flutter/material.dart';
import '../models/item_list.dart';
import '../models/item.dart';
import 'item_detail_screen.dart';

class ItemListScreen extends StatefulWidget {
  final String category;

  const ItemListScreen({super.key, required this.category});

  @override
  State<ItemListScreen> createState() => _ItemListScreenState();
}

class _ItemListScreenState extends State<ItemListScreen> {
  // Sample data - replace with actual API calls
  late List<ItemList> items;

  @override
  void initState() {
    super.initState();
    // Generate sample data based on category
    items = _generateSampleItems(widget.category);
  }

  List<ItemList> _generateSampleItems(String category) {
    switch (category.toLowerCase()) {
      case 'laptops':
        return [
          ItemList(
            itemImage: 'assets/images/laptop1.jpg',
            itemSerialNumber: 'LAP001',
            itemName: 'Dell Latitude 5520',
            itemCategory: 'Laptops',
            itemCondition: 'Excellent',
          ),
          ItemList(
            itemImage: 'assets/images/laptop2.jpg',
            itemSerialNumber: 'LAP002',
            itemName: 'HP EliteBook 840',
            itemCategory: 'Laptops',
            itemCondition: 'Good',
          ),
          ItemList(
            itemImage: 'assets/images/laptop3.jpg',
            itemSerialNumber: 'LAP003',
            itemName: 'Lenovo ThinkPad T14',
            itemCategory: 'Laptops',
            itemCondition: 'Fair',
          ),
        ];
      case 'projectors':
        return [
          ItemList(
            itemImage: 'assets/images/projector1.jpg',
            itemSerialNumber: 'PROJ001',
            itemName: 'Epson PowerLite 1781W',
            itemCategory: 'Projectors',
            itemCondition: 'Excellent',
          ),
          ItemList(
            itemImage: 'assets/images/projector2.jpg',
            itemSerialNumber: 'PROJ002',
            itemName: 'BenQ MH535FHD',
            itemCategory: 'Projectors',
            itemCondition: 'Good',
          ),
        ];
      default:
        return [
          ItemList(
            itemImage: 'assets/images/default.jpg',
            itemSerialNumber: 'ITEM001',
            itemName: 'Sample Item',
            itemCategory: category,
            itemCondition: 'Good',
          ),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text('${widget.category} Items'),
        backgroundColor: const Color(0xFF338AFF),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // Show filter options
            },
          ),
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: () {
              // Show sort options
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            margin: const EdgeInsets.all(20),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search ${widget.category.toLowerCase()}...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 15,
                ),
              ),
            ),
          ),
          // Items list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return _buildItemCard(item);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to add item screen
        },
        backgroundColor: const Color(0xFF338AFF),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildItemCard(ItemList item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: () {
          // Create a full Item object from ItemList for detail view
          final fullItem = Item(
            id: 1, // This would come from actual data
            serialNumber: item.itemSerialNumber,
            itemName: item.itemName,
            itemImage: item.itemImage,
            itemCategory: item.itemCategory,
            condition: item.itemCondition,
            createdAt: DateTime.now(), // This would come from actual data
            updatedAt: DateTime.now(), // This would come from actual data
          );
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ItemDetailScreen(item: fullItem),
            ),
          );
        },
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Item image
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF338AFF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: item.itemImage.startsWith('assets/')
                    ? Image.asset(item.itemImage, fit: BoxFit.cover)
                    : Icon(
                        _getCategoryIcon(item.itemCategory),
                        color: const Color(0xFF338AFF),
                        size: 40,
                      ),
              ),
              const SizedBox(width: 16),
              // Item details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.itemName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'SN: ${item.itemSerialNumber}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildConditionChip(item.itemCondition),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          onPressed: () {
                            // Navigate to edit item screen
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, size: 20),
                          onPressed: () {
                            // Show delete confirmation
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConditionChip(String condition) {
    Color color;
    switch (condition.toLowerCase()) {
      case 'excellent':
        color = Colors.green;
        break;
      case 'good':
        color = Colors.blue;
        break;
      case 'fair':
        color = Colors.orange;
        break;
      case 'poor':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        condition,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'laptops':
        return Icons.laptop;
      case 'projectors':
        return Icons.video_camera_front;
      case 'audio equipment':
        return Icons.headphones;
      case 'cables & adapters':
        return Icons.cable;
      case 'tools':
        return Icons.build;
      default:
        return Icons.category;
    }
  }
}
