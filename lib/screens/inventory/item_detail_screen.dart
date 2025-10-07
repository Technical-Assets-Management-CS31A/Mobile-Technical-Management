import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/entities/item.dart';
import '../../services/inventory_service.dart';

class ItemDetailScreen extends StatefulWidget {
  const ItemDetailScreen({
    super.key,
    required this.item,
    this.startInEdit = false,
  });

  final Item item;
  final bool startInEdit;

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  bool _isEditing = false;
  late TextEditingController _nameController;
  late TextEditingController _serialController;
  late TextEditingController _typeController;
  late TextEditingController _modelController;
  late TextEditingController _makeController;
  late TextEditingController _descriptionController;
  late String _selectedCategory;
  late String _selectedCondition;
  XFile? _selectedImage;
  final ImagePicker _imagePicker = ImagePicker();
  final InventoryService _inventoryService = InventoryService();
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _isEditing = widget.startInEdit;
    _nameController = TextEditingController(text: widget.item.itemName);
    _serialController = TextEditingController(text: widget.item.serialNumber);
    _typeController = TextEditingController(text: widget.item.itemType);
    _modelController = TextEditingController(text: widget.item.itemModel);
    _makeController = TextEditingController(text: widget.item.itemMake);
    _descriptionController = TextEditingController(
      text: widget.item.description,
    );
    _selectedCategory = widget.item.itemCategory;
    _selectedCondition = widget.item.condition;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _serialController.dispose();
    _typeController.dispose();
    _modelController.dispose();
    _makeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing) {
        _nameController.text = widget.item.itemName;
        _serialController.text = widget.item.serialNumber;
        _typeController.text = widget.item.itemType;
        _modelController.text = widget.item.itemModel;
        _makeController.text = widget.item.itemMake;
        _descriptionController.text = widget.item.description;
        _selectedCategory = widget.item.itemCategory;
        _selectedCondition = widget.item.condition;
        _selectedImage = null;
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
        itemImage: _selectedImage?.path ?? widget.item.itemImage,
        itemCategory: _selectedCategory,
        condition: _selectedCondition,
        itemType: _typeController.text.trim(),
        itemModel: _modelController.text.trim(),
        itemMake: _makeController.text.trim(),
        description: _descriptionController.text.trim(),
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
            SnackBar(
              content: const Text('Item updated successfully!'),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
          Navigator.of(context).pop(true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Failed to update item'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating item: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
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
          backgroundColor: Theme.of(context).colorScheme.surfaceBright,
          title: Text(
            'Delete Item',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          ),
          content: Text(
            'Are you sure you want to delete this item? This action cannot be undone.',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteItem();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
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
            SnackBar(
              content: const Text('Item deleted successfully!'),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
          Navigator.of(context).pop(true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Failed to delete item'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting item: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceBright,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        enabled: _isEditing,
        maxLines: maxLines,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
          prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.primary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surfaceBright,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required IconData icon,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceBright,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        items: items
            .map(
              (opt) => DropdownMenuItem(
                value: opt,
                child: Text(
                  opt,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            )
            .toList(),
        onChanged: _isEditing ? onChanged : null,
        dropdownColor: Theme.of(context).colorScheme.surfaceBright,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
          prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.primary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surfaceBright,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'electronics':
        return Icons.devices;
      case 'cables':
        return Icons.cable;
      case 'adapters':
        return Icons.settings_input_component;
      case 'peripherals':
        return Icons.keyboard;
      case 'networking':
        return Icons.router;
      case 'storage':
        return Icons.storage;
      case 'audio':
        return Icons.headphones;
      case 'display':
        return Icons.monitor;
      default:
        return Icons.category;
    }
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
        color: Theme.of(context).colorScheme.surfaceBright,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
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
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.7),
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
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Item' : 'Item Details'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
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
              tooltip: 'Save',
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _toggleEdit,
              tooltip: 'Cancel',
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _toggleEdit,
              tooltip: 'Edit',
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _showDeleteConfirmation,
              tooltip: 'Delete',
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
                      Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      Theme.of(context).colorScheme.primary.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getCategoryIcon(widget.item.itemCategory),
                        color: Theme.of(context).colorScheme.primary,
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _isEditing ? 'Edit Item Information' : 'Item Information',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isEditing
                          ? 'Update the item details below'
                          : 'View and manage item details',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Form Fields or Info Cards
              if (_isEditing) ...[
                // Item Name
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

                // Serial Number
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

                // Category
                _buildDropdownField(
                  label: 'Category',
                  icon: Icons.category,
                  value: _selectedCategory,
                  items: const [
                    'Electronics',
                    'Cables',
                    'Adapters',
                    'Peripherals',
                    'Networking',
                    'Storage',
                    'Audio',
                    'Display',
                    'Other',
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedCategory = val);
                  },
                ),
                const SizedBox(height: 20),

                // Condition
                _buildDropdownField(
                  label: 'Condition',
                  icon: Icons.info,
                  value: _selectedCondition,
                  items: const ['New', 'Good', 'Fair', 'In Use'],
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedCondition = val);
                  },
                ),
                const SizedBox(height: 20),

                // Item Type
                _buildFormField(
                  label: 'Item Type',
                  controller: _typeController,
                  icon: Icons.label,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter an item type';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Item Model
                _buildFormField(
                  label: 'Item Model',
                  controller: _modelController,
                  icon: Icons.model_training,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter an item model';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Item Make
                _buildFormField(
                  label: 'Item Make',
                  controller: _makeController,
                  icon: Icons.business,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter an item make';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Description
                _buildFormField(
                  label: 'Description',
                  controller: _descriptionController,
                  icon: Icons.description,
                  maxLines: 4,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
              ] else ...[
                // Read-only View
                // Item Image (if exists)
                if (widget.item.itemImage.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    height: 250,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(
                            context,
                          ).colorScheme.shadow.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        widget.item.itemImage,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Icon(
                              Icons.broken_image,
                              size: 64,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.5),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                _buildInfoCard(
                  title: 'Item Name',
                  value: widget.item.itemName,
                  icon: Icons.inventory_2,
                  color: const Color(0xFF338AFF),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _buildInfoCard(
                        title: 'Serial Number',
                        value: widget.item.serialNumber,
                        icon: Icons.qr_code,
                        color: Colors.purple,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildInfoCard(
                        title: 'Category',
                        value: widget.item.itemCategory,
                        icon: Icons.category,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _buildInfoCard(
                        title: 'Condition',
                        value: widget.item.condition,
                        icon: Icons.info,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildInfoCard(
                        title: 'Item Type',
                        value: widget.item.itemType,
                        icon: Icons.label,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _buildInfoCard(
                        title: 'Item Model',
                        value: widget.item.itemModel,
                        icon: Icons.model_training,
                        color: Colors.teal,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildInfoCard(
                        title: 'Item Make',
                        value: widget.item.itemMake,
                        icon: Icons.business,
                        color: Colors.indigo,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                _buildInfoCard(
                  title: 'Description',
                  value: widget.item.description,
                  icon: Icons.description,
                  color: Colors.brown,
                ),
              ],

              // Item Image (in edit mode or add new image)
              if (_isEditing) ...[
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceBright,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(
                          context,
                        ).colorScheme.shadow.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.image,
                            color: Theme.of(context).colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Item Image',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_selectedImage != null ||
                          widget.item.itemImage.isNotEmpty) ...[
                        Container(
                          width: double.infinity,
                          height: 200,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outline,
                              width: 2,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: _selectedImage != null
                                ? FutureBuilder<Uint8List>(
                                    future: _selectedImage!.readAsBytes(),
                                    builder: (context, snapshot) {
                                      if (snapshot.hasData) {
                                        return Image.memory(
                                          snapshot.data!,
                                          fit: BoxFit.cover,
                                        );
                                      }
                                      return const Center(
                                        child: CircularProgressIndicator(),
                                      );
                                    },
                                  )
                                : widget.item.itemImage.isNotEmpty
                                ? Image.network(
                                    widget.item.itemImage,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Center(
                                        child: Icon(
                                          Icons.broken_image,
                                          size: 48,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withOpacity(0.5),
                                        ),
                                      );
                                    },
                                  )
                                : const SizedBox(),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _pickImage,
                          icon: Icon(
                            _selectedImage == null &&
                                    widget.item.itemImage.isEmpty
                                ? Icons.add_photo_alternate
                                : Icons.edit,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          label: Text(
                            _selectedImage == null &&
                                    widget.item.itemImage.isEmpty
                                ? 'Select Image'
                                : 'Change Image',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: Theme.of(context).colorScheme.primary,
                              width: 2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Save Button (only show in edit mode)
              if (_isEditing) ...[
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 2,
                    ),
                    child: _isLoading
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).colorScheme.onPrimary,
                              ),
                            ),
                          )
                        : Text(
                            'Save Changes',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
