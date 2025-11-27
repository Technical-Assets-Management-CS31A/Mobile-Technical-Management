import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/entities/item.dart';
import '../../services/inventory_service.dart';
import '../../services/inventory_service.dart';
import '../../widgets/barcode_widget.dart';
import '../../utils/snackbar_helper.dart';

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
  late TextEditingController _barcodeController;
  late ItemCategory _selectedCategory;
  late ItemCondition _selectedCondition;
  XFile? _selectedImage;
  bool _imageRemoved = false; // Track if user explicitly removed the image
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
    _modelController = TextEditingController(text: widget.item.itemModel ?? '');
    _makeController = TextEditingController(text: widget.item.itemMake);
    _descriptionController = TextEditingController(
      text: widget.item.description ?? '',
    );
    _barcodeController = TextEditingController(text: widget.item.barcode ?? '');
    _selectedCategory = widget.item.category;
    _selectedCondition = widget.item.condition;
    _initializeService();
  }

  Future<void> _initializeService() async {
    try {
      await _inventoryService.initialize();
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showErrorSnackBar(context, 'Error initializing service: $e');
      }
    }
  }

  /// Helper method to decode base64 image data
  Uint8List? _decodeBase64Image(String? imageData) {
    if (imageData == null || imageData.isEmpty) return null;

    try {
      // Remove data URL prefix if present
      String base64Data = imageData;
      if (imageData.startsWith('data:image/')) {
        final commaIndex = imageData.indexOf(',');
        if (commaIndex != -1) {
          base64Data = imageData.substring(commaIndex + 1);
        }
      }

      return base64Decode(base64Data);
    } catch (e) {
      print('Error decoding base64 image: $e');
      return null;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _serialController.dispose();
    _typeController.dispose();
    _modelController.dispose();
    _makeController.dispose();
    _descriptionController.dispose();
    _barcodeController.dispose();
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
          _imageRemoved =
              false; // Reset the removed flag when new image is selected
        });
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showErrorSnackBar(context, 'Error picking image: $e');
      }
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
      _imageRemoved = true;
    });
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing) {
        _nameController.text = widget.item.itemName;
        _serialController.text = widget.item.serialNumber;
        _typeController.text = widget.item.itemType;
        _modelController.text = widget.item.itemModel ?? '';
        _makeController.text = widget.item.itemMake;
        _descriptionController.text = widget.item.description ?? '';
        _barcodeController.text = widget.item.barcode ?? '';
        _selectedCategory = widget.item.category;
        _selectedCondition = widget.item.condition;
        _selectedImage = null;
        _imageRemoved = false;
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
      // Handle image updates
      String? imageBase64;
      if (_selectedImage != null) {
        // User selected a new image - convert to base64
        final bytes = await _selectedImage!.readAsBytes();
        imageBase64 = base64Encode(bytes);
      } else if (_imageRemoved) {
        // User explicitly removed the image
        imageBase64 = null;
      } else {
        // No changes to image - keep existing image
        imageBase64 = widget.item.image;
      }

      final updatedItem = Item(
        id: widget.item.id,
        serialNumber: _serialController.text.trim(),
        itemName: _nameController.text.trim(),
        image: imageBase64,
        category: _selectedCategory,
        condition: _selectedCondition,
        itemType: _typeController.text.trim(),
        itemModel: _modelController.text.trim().isEmpty
            ? null
            : _modelController.text.trim(),
        itemMake: _makeController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        barcode: _barcodeController.text.trim().isEmpty
            ? null
            : _barcodeController.text.trim(),
        createdAt: widget.item.createdAt,
        updatedAt: DateTime.now(),
      );

      final result = await _inventoryService.updateItem(updatedItem);

      if (result != null) {
        setState(() {
          _isEditing = false;
        });

        if (mounted) {
          SnackbarHelper.showSuccessSnackBar(context, 'Item updated successfully!');
          Navigator.of(context).pop(true);
        }
      } else {
        if (mounted) {
          SnackbarHelper.showErrorSnackBar(context, 'Failed to update item');
        }
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showErrorSnackBar(context, 'Error updating item: $e');
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
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Theme.of(context).colorScheme.surfaceBright,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Warning icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Icon(Icons.warning, color: Colors.orange, size: 30),
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                'Archive Item',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.9),
                ),
              ),
              const SizedBox(height: 12),

              // Message
              Text(
                'Are you sure you want to archive ${widget.item.itemName}?',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'This action cannot be undone.',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _deleteItem();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Archive'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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
          SnackbarHelper.showArchivedSnackBar(context, 'Item deleted successfully!');
          Navigator.of(context).pop(true);
        }
      } else {
        if (mounted) {
          SnackbarHelper.showErrorSnackBar(context, 'Failed to delete item');
        }
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showErrorSnackBar(context, 'Error deleting item: $e');
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
        border: Border.all(
          color: Colors.grey.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            spreadRadius: 1,
            blurRadius: 6,
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
        border: Border.all(
          color: Colors.grey.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            spreadRadius: 1,
            blurRadius: 6,
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

  IconData _getCategoryIcon(ItemCategory category) {
    switch (category) {
      case ItemCategory.Electronics:
        return Icons.devices;
      case ItemCategory.Keys:
        return Icons.vpn_key;
      case ItemCategory.MediaEquipment:
        return Icons.monitor;
      case ItemCategory.Tools:
        return Icons.build;
      case ItemCategory.Miscellaneous:
        return Icons.category;
    }
  }

  Color _getConditionColor(ItemCondition condition) {
    switch (condition) {
      case ItemCondition.New:
        return const Color(0xFF4CAF50); // Green
      case ItemCondition.Good:
        return const Color(0xFF2196F3); // Blue
      case ItemCondition.Defective:
        return const Color(0xFFF44336); // Red
      case ItemCondition.Refurbished:
        return const Color(0xFF9C27B0); // Purple
      case ItemCondition.NeedRepair:
        return const Color(0xFFFF9800); // Orange
    }
  }

  Widget _buildInfoCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceBright,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.95),
              height: 1.3,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
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
              icon: const Icon(Icons.archive),
              onPressed: _showDeleteConfirmation,
              tooltip: 'Archive',
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
                        _getCategoryIcon(widget.item.category),
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
                  value: _selectedCategory.displayName,
                  items: ItemCategory.values
                      .map((category) => category.displayName)
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(
                        () => _selectedCategory = ItemCategory.fromString(val),
                      );
                    }
                  },
                ),
                const SizedBox(height: 20),

                // Condition
                _buildDropdownField(
                  label: 'Condition',
                  icon: Icons.info,
                  value: _selectedCondition.displayName,
                  items: ItemCondition.values
                      .map((condition) => condition.displayName)
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(
                        () =>
                            _selectedCondition = ItemCondition.fromString(val),
                      );
                    }
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

                // Barcode
                _buildFormField(
                  label: 'Barcode',
                  controller: _barcodeController,
                  icon: Icons.qr_code_2,
                ),
                const SizedBox(height: 20),
              ] else ...[
                // Read-only View
                // Item Image (if exists)
                if (widget.item.image != null &&
                    widget.item.image!.isNotEmpty) ...[
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
                      child: Builder(
                        builder: (context) {
                          final imageBytes = _decodeBase64Image(
                            widget.item.image,
                          );
                          if (imageBytes == null) {
                            return Center(
                              child: Icon(
                                Icons.broken_image,
                                size: 64,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.5),
                              ),
                            );
                          }
                          return Image.memory(
                            imageBytes,
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
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Item Information Section
                Text(
                  'Item Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 16),

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
                        title: 'Category',
                        value: widget.item.category.displayName,
                        icon: Icons.label,
                        color: Colors.teal,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildInfoCard(
                        title: 'Item Type',
                        value: widget.item.itemType,
                        icon: Icons.category,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Status Section
                Text(
                  'Status',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceBright,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey.withOpacity(0.3),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.15),
                        spreadRadius: 1,
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _getConditionColor(
                                widget.item.condition,
                              ).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.assessment,
                              color: _getConditionColor(
                                widget.item.condition,
                              ),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              'Condition',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getConditionColor(
                            widget.item.condition,
                          ).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _getConditionColor(
                              widget.item.condition,
                            ).withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          widget.item.condition.displayName,
                          style: TextStyle(
                            color: _getConditionColor(
                              widget.item.condition,
                            ),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Technical Details Section
                Text(
                  'Technical Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 16),

                _buildInfoCard(
                  title: 'Serial Number',
                  value: widget.item.serialNumber,
                  icon: Icons.qr_code,
                  color: Colors.purple,
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _buildInfoCard(
                        title: 'Item Model',
                        value: widget.item.itemModel ?? 'N/A',
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
                const SizedBox(height: 24),

                // Description Section
                Text(
                  'Description',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 16),

                _buildInfoCard(
                  title: 'Description',
                  value: widget.item.description ?? 'N/A',
                  icon: Icons.description,
                  color: Colors.brown,
                ),
                const SizedBox(height: 24),

                // Barcode Display
                Center(
                  child: BarcodeDisplayWidget(
                    barcodeData: widget.item.barcode,
                    width: 250,
                    height: 100,
                    label: 'Item Barcode',
                  ),
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
                          (widget.item.image != null &&
                              widget.item.image!.isNotEmpty)) ...[
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
                                : (widget.item.image != null &&
                                      widget.item.image!.isNotEmpty)
                                ? Builder(
                                    builder: (context) {
                                      final imageBytes = _decodeBase64Image(
                                        widget.item.image,
                                      );
                                      if (imageBytes == null) {
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
                                      }
                                      return Image.memory(
                                        imageBytes,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
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
                                      );
                                    },
                                  )
                                : const SizedBox(),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _pickImage,
                              icon: Icon(
                                _selectedImage == null &&
                                        (widget.item.image == null ||
                                            widget.item.image!.isEmpty)
                                    ? Icons.add_photo_alternate
                                    : Icons.edit,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              label: Text(
                                _selectedImage == null &&
                                        (widget.item.image == null ||
                                            widget.item.image!.isEmpty)
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
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                          if (_selectedImage != null ||
                              (widget.item.image != null &&
                                  widget.item.image!.isNotEmpty)) ...[
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _removeImage,
                                icon: Icon(
                                  Icons.delete_outline,
                                  color: Theme.of(context).colorScheme.error,
                                ),
                                label: Text(
                                  'Remove',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.error,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: Theme.of(context).colorScheme.error,
                                    width: 2,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
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
