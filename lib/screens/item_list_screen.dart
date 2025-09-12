import 'package:flutter/material.dart';
import '../models/item.dart';
import 'package:flutter/cupertino.dart';

class ItemListScreen extends StatefulWidget {
  const ItemListScreen({Key? key}) : super(key: key);

  @override
  State<ItemListScreen> createState() => _ItemListScreenState();
}

class _ItemListScreenState extends State<ItemListScreen> {
  final _formKey = GlobalKey<FormState>();
  final _serialNumberController = TextEditingController();
  final _itemNameController = TextEditingController();
  String _selectedCategory = 'Cables'; // Default category
  String _selectedCondition = 'Good'; // Default condition
  
  // Conditions list
  final List<String> conditions = ['Excellent', 'Good', 'Fair', 'Poor'];
  
  @override
  void dispose() {
    _serialNumberController.dispose();
    _itemNameController.dispose();
    super.dispose();
  }

  void _showAddItemDialog(BuildContext context) {
    // Reset form
    _serialNumberController.clear();
    _itemNameController.clear();
    _selectedCategory = 'Cables';
    _selectedCondition = 'Good';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add New Item'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Serial Number Field
                  TextFormField(
                    controller: _serialNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Serial Number',
                      hintText: 'Enter serial number',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a serial number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Item Name Field
                  TextFormField(
                    controller: _itemNameController,
                    decoration: const InputDecoration(
                      labelText: 'Item Name',
                      hintText: 'Enter item name',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter an item name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Category Dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                    ),
                    items: categoryIcons.keys.map((String category) {
                      return DropdownMenuItem<String>(
                        value: category,
                        child: Row(
                          children: [
                            Icon(categoryIcons[category], size: 20),
                            const SizedBox(width: 8),
                            Text(category),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedCategory = newValue;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Condition Dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedCondition,
                    decoration: const InputDecoration(
                      labelText: 'Condition',
                    ),
                    items: conditions.map((String condition) {
                      return DropdownMenuItem<String>(
                        value: condition,
                        child: Text(condition),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedCondition = newValue;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  _addNewItem();
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Add Item'),
            ),
          ],
        );
      },
    );
  }

  void _addNewItem() {
    final newItem = Item(
      id: items.length + 1,
      serialNumber: _serialNumberController.text,
      itemName: _itemNameController.text,
      itemImage: 'assets/icons/aclcLOGO.png',
      itemCategory: _selectedCategory,
      condition: _selectedCondition,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    setState(() {
      items.add(newItem);
    });

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${newItem.itemName} has been added successfully!'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Dummy data for demonstration
  final List<Item> items = [
    Item(
      id: 1,
      serialNumber: 'CBL001',
      itemName: 'HDMI Cable',
      itemImage: 'assets/icons/aclcLOGO.png',
      itemCategory: 'Cables',
      condition: 'Good',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    Item(
      id: 2,
      serialNumber: 'ADP001',
      itemName: 'Power Adapter',
      itemImage: 'assets/icons/aclcLOGO.png',
      itemCategory: 'Adapters',
      condition: 'Excellent',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    Item(
      id: 3,
      serialNumber: 'PRN001',
      itemName: 'HP Printer',
      itemImage: 'assets/icons/aclcLOGO.png',
      itemCategory: 'Peripherals',
      condition: 'Good',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    Item(
      id: 4,
      serialNumber: 'RTR001',
      itemName: 'Cisco Router',
      itemImage: 'assets/icons/aclcLOGO.png',
      itemCategory: 'Networking',
      condition: 'Good',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    Item(
      id: 5,
      serialNumber: 'HDD001',
      itemName: 'External Hard Drive',
      itemImage: 'assets/icons/aclcLOGO.png',
      itemCategory: 'Storage',
      condition: 'Fair',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    Item(
      id: 6,
      serialNumber: 'SPK001',
      itemName: 'Logitech Speakers',
      itemImage: 'assets/icons/aclcLOGO.png',
      itemCategory: 'Audio',
      condition: 'Good',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    Item(
      id: 7,
      serialNumber: 'MON001',
      itemName: 'Dell Monitor',
      itemImage: 'assets/icons/aclcLOGO.png',
      itemCategory: 'Display',
      condition: 'Excellent',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    Item(
      id: 8,
      serialNumber: 'MSC001',
      itemName: 'Laptop Stand',
      itemImage: 'assets/icons/aclcLOGO.png',
      itemCategory: 'Other',
      condition: 'Good',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];

  // Define category icons
  final Map<String, IconData> categoryIcons = {
    'Cables': Icons.cable,
    'Adapters': Icons.power,
    'Peripherals': Icons.keyboard,
    'Networking': Icons.router,
    'Storage': Icons.storage,
    'Audio': Icons.headphones,
    'Display': Icons.monitor,
    'Other': Icons.devices_other,
  };

  // Group items by category
  Map<String, List<Item>> _groupItemsByCategory() {
    final groupedItems = <String, List<Item>>{};
    for (var item in items) {
      if (!groupedItems.containsKey(item.itemCategory)) {
        groupedItems[item.itemCategory] = [];
      }
      groupedItems[item.itemCategory]!.add(item);
    }
    return groupedItems;
  }

  @override
  Widget build(BuildContext context) {
    final groupedItems = _groupItemsByCategory();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Item List'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: groupedItems.length,
        itemBuilder: (context, index) {
          final category = groupedItems.keys.elementAt(index);
          final categoryItems = groupedItems[category]!;

          return ExpansionTile(
            leading: Icon(
              categoryIcons[category] ?? Icons.category,
              color: Theme.of(context).primaryColor,
            ),
            title: Text(
              category,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            children: categoryItems.map((item) => _buildItemTile(item)).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddItemDialog(context);
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildItemTile(Item item) {
    return ListTile(
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey[200],
        ),
        child: item.itemImage.isNotEmpty
            ? Image.asset(
                item.itemImage,
                fit: BoxFit.cover,
              )
            : Icon(
                categoryIcons[item.itemCategory] ?? Icons.devices,
                color: Theme.of(context).primaryColor,
              ),
      ),
      title: Text(item.itemName),
      subtitle: Text('SN: ${item.serialNumber} • ${item.condition}'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
      },
    );
  }
}
