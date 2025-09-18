import 'package:flutter/material.dart';
import '../../models/entities/item.dart';
import '../../services/inventory_service.dart';

class ItemDetailScreen extends StatefulWidget {
  final Item item;

  const ItemDetailScreen({super.key, required this.item});

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  bool _isEditing = false;
  late TextEditingController _nameController;
  late TextEditingController _serialController;
  late String _selectedCategory;
  late String _selectedCondition;
  final InventoryService _inventoryService = InventoryService();
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item.itemName);
    _serialController = TextEditingController(text: widget.item.serialNumber);
    _selectedCategory = widget.item.itemCategory;
    _selectedCondition = widget.item.condition;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _serialController.dispose();
    super.dispose();
  }

  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing) {
        // Reset controllers when canceling edit
        _nameController.text = widget.item.itemName;
        _serialController.text = widget.item.serialNumber;
        _selectedCategory = widget.item.itemCategory;
        _selectedCondition = widget.item.condition;
      }
    });
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final updatedItem = Item(
        id: widget.item.id,
        serialNumber: _serialController.text.trim(),
        itemName: _nameController.text.trim(),
        itemImage: widget.item.itemImage,
        itemCategory: _selectedCategory,
        condition: _selectedCondition,
        createdAt: widget.item.createdAt,
        updatedAt: DateTime.now(),
      );

      final result = await _inventoryService.updateItem(updatedItem);

      if (result != null) {
        setState(() {
          _isEditing = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Item updated successfully!')),
          );
          Navigator.of(context).pop(true); // Return true to indicate success
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to update item')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating item: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Item'),
          content: const Text(
            'Are you sure you want to delete this item? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteItem();
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteItem() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _inventoryService.deleteItem(widget.item.id);

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Item deleted successfully!')),
          );
          Navigator.of(context).pop(true); // Return true to indicate success
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete item')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting item: $e')));
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
        title: Text(_isEditing ? 'Edit Item' : 'Item Details'),
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
          else if (_isEditing) ...[
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveChanges,
              tooltip: 'Save Changes',
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _toggleEditMode,
              tooltip: 'Cancel',
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _toggleEditMode,
              tooltip: 'Edit Item',
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _showDeleteConfirmation,
              tooltip: 'Delete Item',
            ),
          ],
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF338AFF).withOpacity(0.1),
                      const Color(0xFF338AFF).withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF338AFF).withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF338AFF).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getCategoryIcon(widget.item.itemCategory),
                        color: const Color(0xFF338AFF),
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _isEditing ? 'Edit Item Information' : 'Item Information',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF338AFF),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isEditing
                          ? 'Update the item details below'
                          : 'View and manage item details',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Form Fields
              if (_isEditing) ...[
                // Item Name Field
                _buildFormField(
                  label: 'Item Name',
                  controller: _nameController,
                  icon: Icons.inventory_2,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter an item name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Serial Number Field
                _buildFormField(
                  label: 'Serial Number',
                  controller: _serialController,
                  icon: Icons.qr_code,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a serial number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Category Dropdown
                _buildDropdownField(
                  label: 'Category',
                  value: _selectedCategory,
                  icon: Icons.category,
                  items: const [
                    'Cables',
                    'Adapters',
                    'Peripherals',
                    'Networking',
                    'Storage',
                    'Audio',
                    'Display',
                    'Other',
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedCategory = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 20),

                // Condition Dropdown
                _buildDropdownField(
                  label: 'Condition',
                  value: _selectedCondition,
                  icon: Icons.info,
                  items: const ['Good', 'Fair', 'In Use'],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedCondition = value;
                      });
                    }
                  },
                ),
              ] else ...[
                // Read-only View
                _buildInfoCard(
                  title: 'Item Name',
                  value: widget.item.itemName,
                  icon: Icons.inventory_2,
                  color: const Color(0xFF338AFF),
                ),
                const SizedBox(height: 16),

                _buildInfoCard(
                  title: 'Serial Number',
                  value: widget.item.serialNumber,
                  icon: Icons.qr_code,
                  color: Colors.green,
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _buildInfoCard(
                        title: 'Category',
                        value: widget.item.itemCategory,
                        icon: Icons.category,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildInfoCard(
                        title: 'Condition',
                        value: widget.item.condition,
                        icon: Icons.info,
                        color: _getConditionColor(widget.item.condition),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 24),

              // Timestamps Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.schedule, color: Colors.grey[600], size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Timestamps',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTimestampItem(
                            'Created',
                            _formatDate(widget.item.createdAt),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTimestampItem(
                            'Last Updated',
                            _formatDate(widget.item.updatedAt),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Action Buttons
              if (!_isEditing) ...[
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Handle borrow action
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Borrow functionality coming soon!',
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.people),
                        label: const Text('Borrow'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF338AFF),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Handle return action
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Return functionality coming soon!',
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.undo),
                        label: const Text('Return'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getConditionColor(String condition) {
    switch (condition.toLowerCase()) {
      case 'excellent':
        return Colors.green;
      case 'good':
        return Colors.blue;
      case 'fair':
        return Colors.orange;
      case 'poor':
        return Colors.red;
      default:
        return Colors.grey;
    }
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFF338AFF)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required IconData icon,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFF338AFF)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        items: items.map((String item) {
          return DropdownMenuItem<String>(value: item, child: Text(item));
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimestampItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }
}
