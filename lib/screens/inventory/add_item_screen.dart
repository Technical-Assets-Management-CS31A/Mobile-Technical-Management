import 'package:flutter/material.dart';
import '../../models/entities/item.dart';
import '../../services/inventory_service.dart';

class AddItemScreen extends StatefulWidget {
  final bool isMobile;

  const AddItemScreen({super.key, required this.isMobile});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _serialController = TextEditingController();
  String _selectedCategory = 'Cables';
  String _selectedCondition = 'Good';
  bool _isLoading = false;

  final InventoryService _inventoryService = InventoryService();

  @override
  void dispose() {
    _nameController.dispose();
    _serialController.dispose();
    super.dispose();
  }

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final newItem = Item(
        id: 0, // Will be assigned by the service
        serialNumber: _serialController.text.trim(),
        itemName: _nameController.text.trim(),
        itemImage: '', // For now, no image support
        itemCategory: _selectedCategory,
        condition: _selectedCondition,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _inventoryService.createItem(newItem);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item added successfully!')),
        );
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error adding item: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Add New Item'),
        backgroundColor: const Color(0xFF338AFF),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveItem,
              child: const Text(
                'Save',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(widget.isMobile ? 16 : 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF338AFF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.add_circle_outline,
                      size: 64,
                      color: const Color(0xFF338AFF),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Add New Item',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Fill in the details below to add a new item to your inventory',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Item Name
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Item Name',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          hintText: 'Enter item name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.inventory_2),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter an item name';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Serial Number
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Serial Number',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _serialController,
                        decoration: InputDecoration(
                          hintText: 'Enter serial number',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.qr_code),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a serial number';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Category and Condition Row
              Row(
                children: [
                  // Category
                  Expanded(
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Category',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              value: _selectedCategory,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                prefixIcon: const Icon(Icons.category),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'Cables',
                                  child: Text('Cables'),
                                ),
                                DropdownMenuItem(
                                  value: 'Adapters',
                                  child: Text('Adapters'),
                                ),
                                DropdownMenuItem(
                                  value: 'Peripherals',
                                  child: Text('Peripherals'),
                                ),
                                DropdownMenuItem(
                                  value: 'Networking',
                                  child: Text('Networking'),
                                ),
                                DropdownMenuItem(
                                  value: 'Storage',
                                  child: Text('Storage'),
                                ),
                                DropdownMenuItem(
                                  value: 'Audio',
                                  child: Text('Audio'),
                                ),
                                DropdownMenuItem(
                                  value: 'Display',
                                  child: Text('Display'),
                                ),
                                DropdownMenuItem(
                                  value: 'Other',
                                  child: Text('Other'),
                                ),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _selectedCategory = value;
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Condition
                  Expanded(
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Condition',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              value: _selectedCondition,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                prefixIcon: const Icon(Icons.info),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'Good',
                                  child: Text('Good'),
                                ),
                                DropdownMenuItem(
                                  value: 'Fair',
                                  child: Text('Fair'),
                                ),
                                DropdownMenuItem(
                                  value: 'In Use',
                                  child: Text('In Use'),
                                ),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _selectedCondition = value;
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveItem,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF338AFF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          'Add Item',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
