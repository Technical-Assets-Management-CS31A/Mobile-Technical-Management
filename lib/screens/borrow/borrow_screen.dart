import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/entities/item.dart';
import '../../models/entities/lend_item.dart';
import '../../models/entities/user.dart';
import '../../services/lend_service.dart';
import '../../services/user_service.dart';
import '../../providers/auth_provider.dart';
import '../../utils/snackbar_helper.dart';
import '../../widgets/skeleton.dart';
import '../inventory/item_selection_screen.dart';
import 'teacher_selection_screen.dart';

class BorrowScreen extends StatefulWidget {
  const BorrowScreen({super.key, this.isMobile = true});

  final bool isMobile;

  @override
  State<BorrowScreen> createState() => _BorrowScreenState();
}

class _BorrowScreenState extends State<BorrowScreen>
    with AutomaticKeepAliveClientMixin {
  final _formKey = GlobalKey<FormState>();
  final LendService _lendService = LendService();
  final StaffService _userService = StaffService();

  Item? _selectedItem;
  Staff? _currentUser;
  Staff? _selectedTeacher;
  bool _isLoading = true;
  bool _isSubmitting = false;

  final _roomController = TextEditingController();
  final _subjectScheduleController = TextEditingController();
  final _remarksController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _roomController.dispose();
    _subjectScheduleController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.userId;

      if (userId != null) {
        // Get user profile to get full name
        final result = await _userService.getUserProfile();
        if (result['success'] == true && result['data'] != null) {
          final userData = result['data'];
          setState(() {
            _currentUser = Staff.fromJson(userData);
          });
        }
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showErrorSnackBar(
          context,
          'Error loading user data: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _selectItem() async {
    HapticFeedback.lightImpact();
    final item = await Navigator.push<Item>(
      context,
      CupertinoPageRoute(
        builder: (context) => const ItemSelectionScreen(isMobile: true),
      ),
    );

    if (item != null) {
      HapticFeedback.mediumImpact();
      setState(() {
        _selectedItem = item;
      });
    }
  }

  Future<void> _selectTeacher() async {
    HapticFeedback.lightImpact();
    final teacher = await Navigator.push<Staff>(
      context,
      CupertinoPageRoute(
        builder: (context) => const TeacherSelectionScreen(isMobile: true),
      ),
    );

    if (teacher != null) {
      HapticFeedback.mediumImpact();
      setState(() {
        _selectedTeacher = teacher;
      });
    }
  }

  Future<void> _submitBorrowRequest() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedItem == null) {
      SnackbarHelper.showErrorSnackBar(
        context,
        'Please select an item to borrow',
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userRole = authProvider.userRole ?? 'Student';
    final userId = authProvider.userId;

    if (_currentUser == null) {
      SnackbarHelper.showErrorSnackBar(
        context,
        'User information not available',
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final borrowerFullName = _currentUser!.name;
      final teacherId = userRole == 'Student' && _selectedTeacher != null
          ? _selectedTeacher!.id
          : null;
      final teacherFullName = userRole == 'Student' && _selectedTeacher != null
          ? _selectedTeacher!.name
          : null;

      final lendItem = LendItem(
        item: _selectedItem,
        userId: userId,
        teacherId: teacherId,
        borrowerFullName: borrowerFullName,
        borrowerRole: userRole,
        teacherFullName: teacherFullName,
        room: _roomController.text.trim().isEmpty
            ? null
            : _roomController.text.trim(),
        subjectTimeSchedule: _subjectScheduleController.text.trim().isEmpty
            ? null
            : _subjectScheduleController.text.trim(),
        remarks: _remarksController.text.trim().isEmpty
            ? null
            : _remarksController.text.trim(),
        status: 'Borrowed',
        lentAt: DateTime.now(),
      );

      await _lendService.createLendItem(lendItem);

      if (mounted) {
        HapticFeedback.heavyImpact();
        SnackbarHelper.showSuccessSnackBar(
          context,
          'Item borrowed successfully!',
        );

        // Reset form
        setState(() {
          _selectedItem = null;
          _selectedTeacher = null;
        });
        _roomController.clear();
        _subjectScheduleController.clear();
        _remarksController.clear();
        _formKey.currentState?.reset();
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showErrorSnackBar(
          context,
          'Error borrowing item: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final userRole = authProvider.userRole ?? 'Student';
    final isStudent = userRole == 'Student';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: _isLoading
          ? BorrowSkeleton(isMobile: widget.isMobile)
          : RefreshIndicator(
              onRefresh: _loadUserData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Page Title
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Theme.of(context).colorScheme.primary,
                                  Theme.of(context).colorScheme.primary.withBlue(255),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              CupertinoIcons.book_fill,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Borrow Item',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1A1A1A),
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Quick and easy borrowing',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF6B7280),
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // User Info Card
                      _buildModernUserCard(userRole),
                      const SizedBox(height: 20),

                      // Item Selection Card
                      _buildModernItemCard(),
                      const SizedBox(height: 20),

                      // Teacher Selection (for students only)
                      if (isStudent) ...[
                        _buildModernTeacherCard(),
                        const SizedBox(height: 20),
                      ],

                      // Details Section
                      _buildDetailsSection(),
                      const SizedBox(height: 32),

                      // Submit Button
                      _buildModernSubmitButton(),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildModernUserCard(String userRole) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            Colors.grey.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.primary.withBlue(255),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              CupertinoIcons.person_fill,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentUser?.name ?? 'Loading...',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        userRole,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    if (_currentUser?.email != null) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _currentUser!.email,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernItemCard() {
    return GestureDetector(
      onTap: _selectItem,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _selectedItem != null ? Colors.white : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _selectedItem != null
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade200,
            width: _selectedItem != null ? 2 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: _selectedItem != null
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.15)
                  : Colors.black.withOpacity(0.05),
              blurRadius: _selectedItem != null ? 20 : 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: _selectedItem != null
                        ? LinearGradient(
                            colors: [
                              Theme.of(context).colorScheme.primary,
                              Theme.of(context).colorScheme.primary.withBlue(255),
                            ],
                          )
                        : LinearGradient(
                            colors: [
                              Colors.grey.shade100,
                              Colors.grey.shade200,
                            ],
                          ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    _selectedItem != null ? CupertinoIcons.checkmark_alt_circle_fill : CupertinoIcons.cube_box,
                    color: _selectedItem != null ? Colors.white : Colors.grey.shade600,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedItem != null ? 'Item Selected' : 'Select Item',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _selectedItem != null
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey.shade700,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _selectedItem != null ? 'Tap to change' : 'Browse available items',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  CupertinoIcons.chevron_right,
                  color: Colors.grey.shade400,
                  size: 20,
                ),
              ],
            ),
            if (_selectedItem != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedItem!.itemName,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A1A),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildItemDetailChip('ID: ${_selectedItem!.id}'),
                        const SizedBox(width: 8),
                        _buildItemDetailChip('SN: ${_selectedItem!.serialNumber}'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildItemDetailChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }

  Widget _buildModernTeacherCard() {
    return GestureDetector(
      onTap: _selectTeacher,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _selectedTeacher != null
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade200,
            width: _selectedTeacher != null ? 2 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: _selectedTeacher != null
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.15)
                  : Colors.black.withOpacity(0.05),
              blurRadius: _selectedTeacher != null ? 20 : 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: _selectedTeacher != null
                    ? LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.primary.withBlue(255),
                        ],
                      )
                    : LinearGradient(
                        colors: [
                          Colors.grey.shade100,
                          Colors.grey.shade200,
                        ],
                      ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                _selectedTeacher != null ? CupertinoIcons.person_crop_circle_fill_badge_checkmark : CupertinoIcons.person_add,
                color: _selectedTeacher != null ? Colors.white : Colors.grey.shade600,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedTeacher != null ? _selectedTeacher!.name : 'Select Teacher',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: _selectedTeacher != null
                          ? const Color(0xFF1A1A1A)
                          : Colors.grey.shade700,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _selectedTeacher != null ? 'Tap to change' : 'Choose your teacher',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              CupertinoIcons.chevron_right,
              color: Colors.grey.shade400,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
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
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  CupertinoIcons.doc_text_fill,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Additional Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildModernTextField(
            controller: _roomController,
            label: 'Room Number',
            hint: 'e.g., Room 101',
            icon: CupertinoIcons.building_2_fill,
          ),
          const SizedBox(height: 16),
          _buildModernTextField(
            controller: _subjectScheduleController,
            label: 'Subject & Schedule',
            hint: 'e.g., Math 101 - MWF 8:00-9:00 AM',
            icon: CupertinoIcons.clock_fill,
          ),
          const SizedBox(height: 16),
          _buildModernTextField(
            controller: _remarksController,
            label: 'Remarks (Optional)',
            hint: 'Any additional notes...',
            icon: CupertinoIcons.chat_bubble_text_fill,
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.2,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.grey.shade400,
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: Icon(icon, color: Colors.grey.shade400, size: 20),
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildModernSubmitButton() {
    return GestureDetector(
      onTap: _isSubmitting
          ? null
          : () {
              HapticFeedback.mediumImpact();
              _submitBorrowRequest();
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _isSubmitting
                ? [
                    Colors.grey.shade300,
                    Colors.grey.shade400,
                  ]
                : [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.primary.withBlue(255),
                  ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: _isSubmitting
              ? []
              : [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: _isSubmitting
            ? const Center(
                child: CupertinoActivityIndicator(
                  color: Colors.white,
                  radius: 12,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    CupertinoIcons.checkmark_circle_fill,
                    color: Colors.white,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Confirm Borrow',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

}

// Skeleton loader for borrow screen
class BorrowSkeleton extends StatelessWidget {
  final bool isMobile;

  const BorrowSkeleton({super.key, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBox(height: 28, width: 200),
          SizedBox(height: isMobile ? 24 : 32),
          SkeletonBox(height: 100, width: double.infinity),
          SizedBox(height: isMobile ? 24 : 32),
          SkeletonBox(height: 20, width: 150),
          const SizedBox(height: 12),
          SkeletonBox(height: 80, width: double.infinity),
          SizedBox(height: isMobile ? 24 : 32),
          SkeletonBox(height: 20, width: 150),
          const SizedBox(height: 12),
          SkeletonBox(height: 60, width: double.infinity),
          SizedBox(height: isMobile ? 24 : 32),
          SkeletonBox(height: 60, width: double.infinity),
          SizedBox(height: isMobile ? 24 : 32),
          SkeletonBox(height: 100, width: double.infinity),
          SizedBox(height: isMobile ? 32 : 40),
          SkeletonBox(height: 50, width: double.infinity),
        ],
      ),
    );
  }
}

