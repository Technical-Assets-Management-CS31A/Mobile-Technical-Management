import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/entities/item.dart';
import '../../services/inventory_service.dart';

class BorrowNewItemScreen extends StatefulWidget {
  const BorrowNewItemScreen({super.key, this.preSelectedItemId});

  final String? preSelectedItemId;

  @override
  State<BorrowNewItemScreen> createState() => _BorrowNewItemScreenState();
}

class _BorrowNewItemScreenState extends State<BorrowNewItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _inventoryService = InventoryService();

  // Form controllers
  final _itemIdController = TextEditingController();
  final _borrowerFirstNameController = TextEditingController();
  final _borrowerLastNameController = TextEditingController();
  final _teacherFirstNameController = TextEditingController();
  final _teacherLastNameController = TextEditingController();
  final _roomController = TextEditingController();
  final _subjectTimeScheduleController = TextEditingController();
  final _remarksController = TextEditingController();
  final _studentIdNumberController = TextEditingController();

  // Form state
  Item? _selectedItem;
  String _borrowerRole = 'Student';
  bool _isLoadingItem = false;
  bool _isSubmitting = false;

  final List<String> _borrowerRoles = ['Student', 'Teacher', 'Staff', 'Guest'];

  @override
  void initState() {
    super.initState();
    // If preselected item ID, set it and fetch details
    if (widget.preSelectedItemId != null) {
      _itemIdController.text = widget.preSelectedItemId!;
      _fetchItemDetails(widget.preSelectedItemId!);
    }
  }

  Future<void> _fetchItemDetails(String itemId) async {
    if (itemId.trim().isEmpty) {
      setState(() => _selectedItem = null);
      return;
    }

    setState(() => _isLoadingItem = true);
    try {
      final item = await _inventoryService.getItemById(itemId.trim());
      setState(() {
        _selectedItem = item;
        _isLoadingItem = false;
      });

      if (item == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item not found'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _selectedItem = null;
        _isLoadingItem = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading item: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _itemIdController.dispose();
    _borrowerFirstNameController.dispose();
    _borrowerLastNameController.dispose();
    _teacherFirstNameController.dispose();
    _teacherLastNameController.dispose();
    _roomController.dispose();
    _subjectTimeScheduleController.dispose();
    _remarksController.dispose();
    _studentIdNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Borrow New Item'),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderSection(),
                const SizedBox(height: 24),
                _buildItemSelectionSection(),
                const SizedBox(height: 24),
                _buildBorrowerInfoSection(),
                const SizedBox(height: 24),
                _buildTeacherInfoSection(),
                const SizedBox(height: 24),
                _buildLocationScheduleSection(),
                const SizedBox(height: 24),
                _buildAdditionalInfoSection(),
                const SizedBox(height: 32),
                _buildSubmitButton(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
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
          color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.inventory_2_outlined,
              color: Theme.of(context).colorScheme.primary,
              size: 48,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Borrow Item Form',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Fill out the form to borrow an item',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemSelectionSection() {
    return _buildSection(
      title: 'Item Selection',
      icon: Icons.shopping_bag_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          TextFormField(
            controller: _itemIdController,
            decoration:
                _inputDecoration(
                  label: 'Item ID *',
                  prefixIcon: Icons.tag,
                  hint: 'Enter the item ID',
                ).copyWith(
                  suffixIcon: _isLoadingItem
                      ? const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : _selectedItem != null
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : null,
                ),
            textCapitalization: TextCapitalization.none,
            onChanged: (value) {
              // Debounce the search
              Future.delayed(const Duration(milliseconds: 500), () {
                if (_itemIdController.text == value) {
                  _fetchItemDetails(value);
                }
              });
            },
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter item ID';
              }
              if (_selectedItem == null && !_isLoadingItem) {
                return 'Item not found';
              }
              return null;
            },
          ),
          if (_selectedItem != null) ...[
            const SizedBox(height: 16),
            _buildSelectedItemCard(),
          ],
        ],
      ),
    );
  }

  Widget _buildSelectedItemCard() {
    if (_selectedItem == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Item Details',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildItemDetailRow('Name', _selectedItem!.itemName),
          _buildItemDetailRow('Serial Number', _selectedItem!.serialNumber),
          _buildItemDetailRow('Category', _selectedItem!.category.displayName),
          _buildItemDetailRow(
            'Condition',
            _selectedItem!.condition.displayName,
          ),
          if (_selectedItem!.itemModel != null)
            _buildItemDetailRow('Model', _selectedItem!.itemModel!),
        ],
      ),
    );
  }

  Widget _buildItemDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBorrowerInfoSection() {
    return _buildSection(
      title: 'Borrower Information',
      icon: Icons.person_outline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          TextFormField(
            controller: _borrowerFirstNameController,
            decoration: _inputDecoration(
              label: 'First Name *',
              prefixIcon: Icons.person,
            ),
            textCapitalization: TextCapitalization.words,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter first name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _borrowerLastNameController,
            decoration: _inputDecoration(
              label: 'Last Name *',
              prefixIcon: Icons.person,
            ),
            textCapitalization: TextCapitalization.words,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter last name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _borrowerRole,
            decoration: _inputDecoration(
              label: 'Borrower Role *',
              prefixIcon: Icons.badge_outlined,
            ),
            items: _borrowerRoles.map((role) {
              return DropdownMenuItem<String>(value: role, child: Text(role));
            }).toList(),
            onChanged: (value) {
              setState(() {
                _borrowerRole = value!;
                // Clear student ID if not a student
                if (_borrowerRole != 'Student') {
                  _studentIdNumberController.clear();
                }
              });
            },
          ),
          if (_borrowerRole == 'Student') ...[
            const SizedBox(height: 16),
            TextFormField(
              controller: _studentIdNumberController,
              decoration: _inputDecoration(
                label: 'Student ID Number',
                prefixIcon: Icons.numbers,
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTeacherInfoSection() {
    return _buildSection(
      title: 'Teacher/Supervisor Information',
      icon: Icons.school_outlined,
      isOptional: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            'If this item is being borrowed for a class or under supervision',
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _teacherFirstNameController,
            decoration: _inputDecoration(
              label: 'Teacher First Name',
              prefixIcon: Icons.person_outline,
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _teacherLastNameController,
            decoration: _inputDecoration(
              label: 'Teacher Last Name',
              prefixIcon: Icons.person_outline,
            ),
            textCapitalization: TextCapitalization.words,
          ),
        ],
      ),
    );
  }

  Widget _buildLocationScheduleSection() {
    return _buildSection(
      title: 'Location & Schedule',
      icon: Icons.location_on_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          TextFormField(
            controller: _roomController,
            decoration: _inputDecoration(
              label: 'Room/Location *',
              prefixIcon: Icons.meeting_room,
              hint: 'e.g., Room 301, Lab A',
            ),
            textCapitalization: TextCapitalization.words,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter room/location';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _subjectTimeScheduleController,
            decoration: _inputDecoration(
              label: 'Subject/Time Schedule *',
              prefixIcon: Icons.schedule,
              hint: 'e.g., Math 101 - 9:00 AM',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter subject/time schedule';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfoSection() {
    return _buildSection(
      title: 'Additional Information',
      icon: Icons.notes_outlined,
      isOptional: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          TextFormField(
            controller: _remarksController,
            decoration: _inputDecoration(
              label: 'Remarks',
              prefixIcon: Icons.comment_outlined,
              hint: 'Any special notes or requirements',
            ),
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
    bool isOptional = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceBright,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              if (isOptional)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Optional',
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ),
            ],
          ),
          child,
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData prefixIcon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(prefixIcon),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.primary,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      filled: true,
      fillColor: Theme.of(context).colorScheme.surface,
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: _isSubmitting
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 24),
                  SizedBox(width: 12),
                  Text(
                    'Submit Borrow Request',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Prepare borrow request data
      final borrowData = {
        'itemId': _itemIdController.text.trim(),
        'borrowerFirstName': _borrowerFirstNameController.text.trim(),
        'borrowerLastName': _borrowerLastNameController.text.trim(),
        'borrowerRole': _borrowerRole,
        'teacherFirstName': _teacherFirstNameController.text.trim().isEmpty
            ? null
            : _teacherFirstNameController.text.trim(),
        'teacherLastName': _teacherLastNameController.text.trim().isEmpty
            ? null
            : _teacherLastNameController.text.trim(),
        'room': _roomController.text.trim(),
        'subjectTimeSchedule': _subjectTimeScheduleController.text.trim(),
        'remarks': _remarksController.text.trim().isEmpty
            ? null
            : _remarksController.text.trim(),
        'status': null,
        'studentIdNumber': _studentIdNumberController.text.trim().isEmpty
            ? null
            : _studentIdNumberController.text.trim(),
      };

      // TODO: Integrate with API service to submit borrow request
      // await borrowService.createBorrowRequest(borrowData);
      // For now, we log the data that would be sent
      debugPrint('Borrow request data prepared: $borrowData');

      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      setState(() => _isSubmitting = false);

      if (mounted) {
        // Show success dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 64,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Success!',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  'Borrow request submitted successfully',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(context).pop(); // Return to previous screen
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() => _isSubmitting = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
