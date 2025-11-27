import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/entities/user.dart';
import '../../utils/constants.dart';
import '../../utils/snackbar_helper.dart';

class StaffDetailScreen extends StatefulWidget {
  const StaffDetailScreen({
    super.key,
    required this.staff,
    this.startInEdit = false,
  });

  final Staff staff;
  final bool startInEdit;

  @override
  State<StaffDetailScreen> createState() => _StaffDetailScreenState();
}

class _StaffDetailScreenState extends State<StaffDetailScreen> {
  bool _isEditing = false;
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _middleNameController;
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  // Teacher-specific controllers
  late TextEditingController _departmentController;
  // Student‑specific controllers (only shown when role is Student)
  late TextEditingController _studentIdController;
  late TextEditingController _courseController;
  late TextEditingController _sectionController;
  late TextEditingController _yearController;
  late TextEditingController _streetController;
  late TextEditingController _cityController;
  late TextEditingController _provinceController;
  late TextEditingController _postalCodeController;
  // Picture path controllers (optional – treat as string paths for now)
  late TextEditingController _profilePicController;
  late TextEditingController _frontIdPicController;
  late TextEditingController _backIdPicController;
  String _userRole = 'Staff';
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;
  late List<String> _userRoleOptions;
  
  // Image picker for student images
  final ImagePicker _imagePicker = ImagePicker();
  XFile? _selectedProfilePic;
  XFile? _selectedFrontIdPic;
  XFile? _selectedBackIdPic;
  bool _profilePicRemoved = false;
  bool _frontIdPicRemoved = false;
  bool _backIdPicRemoved = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.startInEdit;
    _firstNameController = TextEditingController(text: widget.staff.firstName);
    _lastNameController = TextEditingController(text: widget.staff.lastName);
    _middleNameController = TextEditingController(
      text: widget.staff.middleName ?? '',
    );
    _usernameController = TextEditingController(text: widget.staff.username);
    _emailController = TextEditingController(text: widget.staff.email);
    _phoneController = TextEditingController(
      text: widget.staff.phoneNumber ?? '',
    );
    _userRole = widget.staff.userRole;
    // Initialize teacher-specific controllers
    _departmentController = TextEditingController(text: widget.staff.department ?? '');
    // Initialise student‑specific controllers
    _studentIdController = TextEditingController(text: widget.staff.studentIdNumber ?? '');
    _courseController = TextEditingController(text: widget.staff.course ?? '');
    _sectionController = TextEditingController(text: widget.staff.section ?? '');
    _yearController = TextEditingController(text: widget.staff.year ?? '');
    _streetController = TextEditingController(text: widget.staff.street ?? '');
    _cityController = TextEditingController(text: widget.staff.cityMunicipality ?? '');
    _provinceController = TextEditingController(text: widget.staff.province ?? '');
    _postalCodeController = TextEditingController(text: widget.staff.postalCode ?? '');
    _profilePicController = TextEditingController(text: widget.staff.profilePicture ?? '');
    _frontIdPicController = TextEditingController(text: widget.staff.frontStudentIdPicture ?? '');
    _backIdPicController = TextEditingController(text: widget.staff.backStudentIdPicture ?? '');
    
    // Initialize role options - include current role if not in default list
    _userRoleOptions = ['Staff', 'Admin', 'SuperAdmin', 'Student', 'Teacher'];
    if (!_userRoleOptions.contains(_userRole)) {
      _userRoleOptions.add(_userRole);
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _middleNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    // Dispose teacher-specific controllers
    _departmentController.dispose();
    // Dispose student‑specific controllers
    _studentIdController.dispose();
    _courseController.dispose();
    _sectionController.dispose();
    _yearController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _provinceController.dispose();
    _postalCodeController.dispose();
    _profilePicController.dispose();
    _frontIdPicController.dispose();
    _backIdPicController.dispose();
    super.dispose();
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing) {
        // Reset core fields
        _firstNameController.text = widget.staff.firstName;
        _lastNameController.text = widget.staff.lastName;
        _middleNameController.text = widget.staff.middleName ?? '';
        _usernameController.text = widget.staff.username;
        _emailController.text = widget.staff.email;
        _phoneController.text = widget.staff.phoneNumber ?? '';
        _userRole = widget.staff.userRole;
        // Reset teacher-specific fields
        _departmentController.text = widget.staff.department ?? '';
        // Reset student‑specific fields
        _studentIdController.text = widget.staff.studentIdNumber ?? '';
        _courseController.text = widget.staff.course ?? '';
        _sectionController.text = widget.staff.section ?? '';
        _yearController.text = widget.staff.year ?? '';
        _streetController.text = widget.staff.street ?? '';
        _cityController.text = widget.staff.cityMunicipality ?? '';
        _provinceController.text = widget.staff.province ?? '';
        _postalCodeController.text = widget.staff.postalCode ?? '';
        _profilePicController.text = widget.staff.profilePicture ?? '';
        _frontIdPicController.text = widget.staff.frontStudentIdPicture ?? '';
        _backIdPicController.text = widget.staff.backStudentIdPicture ?? '';
        // Reset image selections
        _selectedProfilePic = null;
        _selectedFrontIdPic = null;
        _selectedBackIdPic = null;
        _profilePicRemoved = false;
        _frontIdPicRemoved = false;
        _backIdPicRemoved = false;
      }
    });
  }

  Future<void> _pickProfilePicture() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _selectedProfilePic = image;
          _profilePicRemoved = false;
        });
      }
    } catch (e) {
      if (mounted) {
        if (mounted) {
          SnackbarHelper.showErrorSnackBar(context, 'Error picking image: $e');
        }
      }
    }
  }

  Future<void> _pickFrontIdPicture() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _selectedFrontIdPic = image;
          _frontIdPicRemoved = false;
        });
      }
    } catch (e) {
      if (mounted) {
        if (mounted) {
          SnackbarHelper.showErrorSnackBar(context, 'Error picking image: $e');
        }
      }
    }
  }

  Future<void> _pickBackIdPicture() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _selectedBackIdPic = image;
          _backIdPicRemoved = false;
        });
      }
    } catch (e) {
      if (mounted) {
        if (mounted) {
          SnackbarHelper.showErrorSnackBar(context, 'Error picking image: $e');
        }
      }
    }
  }


  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSaving = true;
    });

    try {
      // Handle image updates for students
      String? profilePictureBase64;
      String? frontIdPictureBase64;
      String? backIdPictureBase64;

      if (_userRole == 'Student') {
        // Profile Picture
        if (_selectedProfilePic != null) {
          // User selected a new image - convert to base64
          final bytes = await _selectedProfilePic!.readAsBytes();
          profilePictureBase64 = base64Encode(bytes);
        } else if (_profilePicRemoved) {
          // User explicitly removed the image
          profilePictureBase64 = null;
        } else {
          // No changes to image - keep existing image
          profilePictureBase64 = widget.staff.profilePicture;
        }

        // Front ID Picture
        if (_selectedFrontIdPic != null) {
          final bytes = await _selectedFrontIdPic!.readAsBytes();
          frontIdPictureBase64 = base64Encode(bytes);
        } else if (_frontIdPicRemoved) {
          frontIdPictureBase64 = null;
        } else {
          frontIdPictureBase64 = widget.staff.frontStudentIdPicture;
        }

        // Back ID Picture
        if (_selectedBackIdPic != null) {
          final bytes = await _selectedBackIdPic!.readAsBytes();
          backIdPictureBase64 = base64Encode(bytes);
        } else if (_backIdPicRemoved) {
          backIdPictureBase64 = null;
        } else {
          backIdPictureBase64 = widget.staff.backStudentIdPicture;
        }
      }

      final updated = widget.staff.copyWith(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        middleName: _middleNameController.text.trim().isEmpty
            ? null
            : _middleNameController.text.trim(),
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        phoneNumber: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        userRole: _userRole,
        // Teacher-specific fields (only saved when role is Teacher)
        department: _userRole == 'Teacher' && _departmentController.text.trim().isNotEmpty
            ? _departmentController.text.trim()
            : null,
        // Student‑specific fields (only saved when role is Student)
        studentIdNumber: _userRole == 'Student' && _studentIdController.text.trim().isNotEmpty
            ? _studentIdController.text.trim()
            : null,
        course: _userRole == 'Student' && _courseController.text.trim().isNotEmpty
            ? _courseController.text.trim()
            : null,
        section: _userRole == 'Student' && _sectionController.text.trim().isNotEmpty
            ? _sectionController.text.trim()
            : null,
        year: _userRole == 'Student' && _yearController.text.trim().isNotEmpty
            ? _yearController.text.trim()
            : null,
        street: _userRole == 'Student' && _streetController.text.trim().isNotEmpty
            ? _streetController.text.trim()
            : null,
        cityMunicipality: _userRole == 'Student' && _cityController.text.trim().isNotEmpty
            ? _cityController.text.trim()
            : null,
        province: _userRole == 'Student' && _provinceController.text.trim().isNotEmpty
            ? _provinceController.text.trim()
            : null,
        postalCode: _userRole == 'Student' && _postalCodeController.text.trim().isNotEmpty
            ? _postalCodeController.text.trim()
            : null,
        // Use the base64 encoded images or null if removed
        profilePicture: _userRole == 'Student' ? profilePictureBase64 : null,
        frontStudentIdPicture: _userRole == 'Student' ? frontIdPictureBase64 : null,
        backStudentIdPicture: _userRole == 'Student' ? backIdPictureBase64 : null,
      );
      
      if (mounted) {
        Navigator.of(context).pop({'updated': updated});
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        if (mounted) {
          SnackbarHelper.showErrorSnackBar(context, 'Error preparing update: $e');
        }
      }
    }
  }

  void _delete() {
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
                'Archive User',
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
                'Are you sure you want to archive ${widget.staff.name}?',
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
                        Navigator.of(context).pop({'deleted': widget.staff.id});
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

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
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
        keyboardType: keyboardType,
        obscureText: obscureText,
        enabled: _isEditing,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
          prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.primary),
          suffixIcon: suffixIcon,
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
        border: Border.all(color: color.withOpacity(0.2), width: 1),
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildImageCard({
    required String title,
    required String imageUrl,
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
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              imageUrl,
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: double.infinity,
                  height: 200,
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.broken_image,
                        size: 48,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Image not available',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                );
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  width: double.infinity,
                  height: 200,
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  child: Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableImageCard({
    required String title,
    String? imageUrl,
    required VoidCallback onTap,
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              TextButton.icon(
                onPressed: onTap,
                icon: Icon(
                  imageUrl != null && imageUrl.isNotEmpty ? Icons.edit : Icons.add_photo_alternate,
                  size: 18,
                ),
                label: Text(imageUrl != null && imageUrl.isNotEmpty ? 'Change' : 'Add'),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (imageUrl != null && imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                imageUrl,
                width: double.infinity,
                height: 150,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: double.infinity,
                    height: 150,
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.broken_image,
                          size: 40,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Image not available',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    width: double.infinity,
                    height: 150,
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  );
                },
              ),
            )
          else
            Container(
              width: double.infinity,
              height: 150,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                  width: 2,
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate,
                    size: 48,
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No image',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  IconData _getRoleIcon(String? role) {
    if (role == null) {
      return Icons.person;
    }
    switch (role.toLowerCase()) {
      case 'superadmin':
        return Icons.security;
      case 'admin':
        return Icons.admin_panel_settings;
      case 'staff':
        return Icons.person;
      default:
        return Icons.person;
    }
  }

  Color _getStatusColor(String? status) {
    if (status == null) {
      return const Color(0xFF718096);
    }
    switch (status.toLowerCase()) {
      case 'online':
      case 'active':
        return const Color(0xFF10B981);
      case 'offline':
        return const Color(0xFF6B7280);
      case 'busy':
        return const Color(0xFFF59E0B);
      case 'away':
        return const Color(0xFF3B82F6);
      case 'inactive':
        return const Color(0xFF6B7280);
      case 'pending':
        return const Color(0xFF8B5CF6);
      default:
        return const Color(0xFF718096);
    }
  }

  Color _getUserRoleColor(String? userRole) {
    if (userRole == null) {
      return const Color(0xFF718096);
    }
    switch (userRole.toLowerCase()) {
      case 'superadmin':
        return const Color(0xFFDC2626);
      case 'admin':
        return const Color(0xFFE53E3E);
      case 'staff':
        return const Color(0xFF805AD5);
      default:
        return const Color(0xFF718096);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit User' : 'User Details'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 0,
        actions: [
          if (_isSaving)
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
              onPressed: _save,
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
              onPressed: _delete,
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
                        _getRoleIcon(widget.staff.userRole),
                        color: Theme.of(context).colorScheme.primary,
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _isEditing ? 'Edit User Information' : 'User Information',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isEditing
                          ? 'Update the user details below'
                          : 'View and manage user details',
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
                // First Name
                _buildFormField(
                  label: 'First Name',
                  controller: _firstNameController,
                  icon: Icons.person,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter first name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Last Name
                _buildFormField(
                  label: 'Last Name',
                  controller: _lastNameController,
                  icon: Icons.person,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter last name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Middle Name
                _buildFormField(
                  label: 'Middle Name (Optional)',
                  controller: _middleNameController,
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 20),

                // Phone Number
                _buildFormField(
                  label: 'Phone Number',
                  controller: _phoneController,
                  icon: Icons.phone,
                  keyboardType: TextInputType.phone,
                  validator: AppConstants.validatePhoneNumber,
                ),
                const SizedBox(height: 20),
                // Show teacher-specific fields only when role is Teacher
                if (_userRole == 'Teacher') ...[
                  _buildFormField(
                    label: 'Department',
                    controller: _departmentController,
                    icon: Icons.business,
                  ),
                  const SizedBox(height: 20),
                ],
                // Show student‑specific fields only when role is Student
                if (_userRole == 'Student') ...[
                  const SizedBox(height: 20),
                  _buildFormField(
                    label: 'Student ID Number',
                    controller: _studentIdController,
                    icon: Icons.confirmation_number,
                  ),
                  const SizedBox(height: 20),
                  _buildFormField(
                    label: 'Course',
                    controller: _courseController,
                    icon: Icons.book,
                  ),
                  const SizedBox(height: 20),
                  _buildFormField(
                    label: 'Section',
                    controller: _sectionController,
                    icon: Icons.group,
                  ),
                  const SizedBox(height: 20),
                  _buildFormField(
                    label: 'Year',
                    controller: _yearController,
                    icon: Icons.calendar_today,
                  ),
                  const SizedBox(height: 20),
                  // Address fields
                  _buildFormField(
                    label: 'Street',
                    controller: _streetController,
                    icon: Icons.location_on,
                  ),
                  const SizedBox(height: 20),
                  _buildFormField(
                    label: 'City / Municipality',
                    controller: _cityController,
                    icon: Icons.location_city,
                  ),
                  const SizedBox(height: 20),
                  _buildFormField(
                    label: 'Province',
                    controller: _provinceController,
                    icon: Icons.map,
                  ),
                  const SizedBox(height: 20),
                  _buildFormField(
                    label: 'Postal Code',
                    controller: _postalCodeController,
                    icon: Icons.markunread_mailbox,
                  ),
                  const SizedBox(height: 20),
                  
                  // Student Images Section
                  Text(
                    'Student Images',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Profile Picture
                  Container(
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
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.account_circle,
                              color: Theme.of(context).colorScheme.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Profile Picture',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (_selectedProfilePic != null || (widget.staff.profilePicture != null && widget.staff.profilePicture!.isNotEmpty)) ...[
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
                              child: _selectedProfilePic != null
                                  ? FutureBuilder<Uint8List>(
                                      future: _selectedProfilePic!.readAsBytes(),
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
                                  : (widget.staff.profilePicture != null && widget.staff.profilePicture!.isNotEmpty)
                                      ? Image.network(
                                          widget.staff.profilePicture!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Center(
                                              child: Icon(
                                                Icons.broken_image,
                                                size: 48,
                                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                              ),
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
                                onPressed: _pickProfilePicture,
                                icon: Icon(
                                  _selectedProfilePic == null && (widget.staff.profilePicture == null || widget.staff.profilePicture!.isEmpty)
                                      ? Icons.add_photo_alternate
                                      : Icons.edit,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                label: Text(
                                  _selectedProfilePic == null && (widget.staff.profilePicture == null || widget.staff.profilePicture!.isEmpty)
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
                            if (_selectedProfilePic != null || (widget.staff.profilePicture != null && widget.staff.profilePicture!.isNotEmpty)) ...[
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _selectedProfilePic = null;
                                      _profilePicRemoved = true;
                                    });
                                  },
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
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Front ID Picture
                  Container(
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
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.badge,
                              color: Theme.of(context).colorScheme.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Front ID Picture',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (_selectedFrontIdPic != null || (widget.staff.frontStudentIdPicture != null && widget.staff.frontStudentIdPicture!.isNotEmpty)) ...[
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
                              child: _selectedFrontIdPic != null
                                  ? FutureBuilder<Uint8List>(
                                      future: _selectedFrontIdPic!.readAsBytes(),
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
                                  : (widget.staff.frontStudentIdPicture != null && widget.staff.frontStudentIdPicture!.isNotEmpty)
                                      ? Image.network(
                                          widget.staff.frontStudentIdPicture!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Center(
                                              child: Icon(
                                                Icons.broken_image,
                                                size: 48,
                                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                              ),
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
                                onPressed: _pickFrontIdPicture,
                                icon: Icon(
                                  _selectedFrontIdPic == null && (widget.staff.frontStudentIdPicture == null || widget.staff.frontStudentIdPicture!.isEmpty)
                                      ? Icons.add_photo_alternate
                                      : Icons.edit,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                label: Text(
                                  _selectedFrontIdPic == null && (widget.staff.frontStudentIdPicture == null || widget.staff.frontStudentIdPicture!.isEmpty)
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
                            if (_selectedFrontIdPic != null || (widget.staff.frontStudentIdPicture != null && widget.staff.frontStudentIdPicture!.isNotEmpty)) ...[
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _selectedFrontIdPic = null;
                                      _frontIdPicRemoved = true;
                                    });
                                  },
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
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Back ID Picture
                  Container(
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
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.badge,
                              color: Theme.of(context).colorScheme.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Back ID Picture',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (_selectedBackIdPic != null || (widget.staff.backStudentIdPicture != null && widget.staff.backStudentIdPicture!.isNotEmpty)) ...[
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
                              child: _selectedBackIdPic != null
                                  ? FutureBuilder<Uint8List>(
                                      future: _selectedBackIdPic!.readAsBytes(),
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
                                  : (widget.staff.backStudentIdPicture != null && widget.staff.backStudentIdPicture!.isNotEmpty)
                                      ? Image.network(
                                          widget.staff.backStudentIdPicture!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Center(
                                              child: Icon(
                                                Icons.broken_image,
                                                size: 48,
                                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                              ),
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
                                onPressed: _pickBackIdPicture,
                                icon: Icon(
                                  _selectedBackIdPic == null && (widget.staff.backStudentIdPicture == null || widget.staff.backStudentIdPicture!.isEmpty)
                                      ? Icons.add_photo_alternate
                                      : Icons.edit,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                label: Text(
                                  _selectedBackIdPic == null && (widget.staff.backStudentIdPicture == null || widget.staff.backStudentIdPicture!.isEmpty)
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
                            if (_selectedBackIdPic != null || (widget.staff.backStudentIdPicture != null && widget.staff.backStudentIdPicture!.isNotEmpty)) ...[
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _selectedBackIdPic = null;
                                      _backIdPicRemoved = true;
                                    });
                                  },
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
                                    padding: const EdgeInsets.symmetric(vertical: 12),
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
              ] else ...[
                // Read-only View
                _buildInfoCard(
                  title: 'Full Name',
                  value: widget.staff.name,
                  icon: Icons.person,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),

                _buildInfoCard(
                  title: 'Username',
                  value: widget.staff.username,
                  icon: Icons.account_circle,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _buildInfoCard(
                        title: 'Email',
                        value: widget.staff.email,
                        icon: Icons.email,
                        color: Theme.of(context).colorScheme.tertiary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildInfoCard(
                        title: 'Phone Number',
                        value: widget.staff.phoneNumber ?? 'No Phone',
                        icon: Icons.phone,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Status and User Role Row
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoCard(
                        title: 'Status',
                        value: widget.staff.status ?? 'Unknown',
                        icon: Icons.circle,
                        color: _getStatusColor(widget.staff.status),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildInfoCard(
                        title: 'User Role',
                        value: widget.staff.userRole,
                        icon: Icons.admin_panel_settings,
                        color: _getUserRoleColor(widget.staff.userRole),
                      ),
                    ),
                  ],
                ),
                
                // Student-specific fields (only show for students)
                if (widget.staff.userRole == 'Student') ...[
                  const SizedBox(height: 24),
                  Text(
                    'Student Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Student ID and Course Row
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoCard(
                          title: 'Student ID',
                          value: widget.staff.studentIdNumber ?? 'N/A',
                          icon: Icons.confirmation_number,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildInfoCard(
                          title: 'Course',
                          value: widget.staff.course ?? 'N/A',
                          icon: Icons.book,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Section and Year Row
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoCard(
                          title: 'Section',
                          value: widget.staff.section ?? 'N/A',
                          icon: Icons.group,
                          color: Theme.of(context).colorScheme.tertiary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildInfoCard(
                          title: 'Year',
                          value: widget.staff.year ?? 'N/A',
                          icon: Icons.calendar_today,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  Text(
                    'Address',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildInfoCard(
                    title: 'Street',
                    value: widget.staff.street ?? 'N/A',
                    icon: Icons.location_on,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoCard(
                          title: 'City/Municipality',
                          value: widget.staff.cityMunicipality ?? 'N/A',
                          icon: Icons.location_city,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildInfoCard(
                          title: 'Province',
                          value: widget.staff.province ?? 'N/A',
                          icon: Icons.map,
                          color: Theme.of(context).colorScheme.tertiary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  _buildInfoCard(
                    title: 'Postal Code',
                    value: widget.staff.postalCode ?? 'N/A',
                    icon: Icons.markunread_mailbox,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
                
                // Student Images Section (only show for students)
                if (widget.staff.userRole == 'Student') ...[
                  const SizedBox(height: 24),
                  Text(
                    'Student Images',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Profile Picture
                  if (widget.staff.profilePicture != null && widget.staff.profilePicture!.isNotEmpty) ...[
                    _buildImageCard(
                      title: 'Profile Picture',
                      imageUrl: widget.staff.profilePicture!,
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // Student ID Pictures Column
                  Column(
                    children: [
                      if (widget.staff.frontStudentIdPicture != null && widget.staff.frontStudentIdPicture!.isNotEmpty) ...[
                        _buildImageCard(
                          title: 'Front ID',
                          imageUrl: widget.staff.frontStudentIdPicture!,
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (widget.staff.backStudentIdPicture != null && widget.staff.backStudentIdPicture!.isNotEmpty)
                        _buildImageCard(
                          title: 'Back ID',
                          imageUrl: widget.staff.backStudentIdPicture!,
                        ),
                    ],
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
