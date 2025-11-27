import 'package:flutter/material.dart';
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
    final item = await Navigator.push<Item>(
      context,
      MaterialPageRoute(
        builder: (context) => const ItemSelectionScreen(isMobile: true),
      ),
    );

    if (item != null) {
      setState(() {
        _selectedItem = item;
      });
    }
  }

  Future<void> _selectTeacher() async {
    final teacher = await Navigator.push<Staff>(
      context,
      MaterialPageRoute(
        builder: (context) => const TeacherSelectionScreen(isMobile: true),
      ),
    );

    if (teacher != null) {
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: _isLoading
            ? BorrowSkeleton(isMobile: widget.isMobile)
            : RefreshIndicator(
                onRefresh: _loadUserData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.all(widget.isMobile ? 16 : 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Text(
                            'BORROW ITEM',
                            style: TextStyle(
                              fontSize: widget.isMobile ? 24 : 28,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                        SizedBox(height: widget.isMobile ? 24 : 32),

                        // Borrower Information Card
                        _buildInfoCard(
                          'Borrower Information',
                          [
                            _buildInfoRow('Name', _currentUser?.name ?? 'N/A'),
                            _buildInfoRow('Role', userRole),
                            if (_currentUser?.email != null)
                              _buildInfoRow('Email', _currentUser!.email),
                          ],
                        ),
                        SizedBox(height: widget.isMobile ? 24 : 32),

                        // Item Selection
                        _buildSectionTitle('Select Item'),
                        const SizedBox(height: 12),
                        _buildItemSelectionCard(),
                        SizedBox(height: widget.isMobile ? 24 : 32),

                        // Teacher Selection (for students only)
                        if (isStudent) ...[
                          _buildSectionTitle('Teacher Information'),
                          const SizedBox(height: 12),
                          _buildTeacherSelectionCard(),
                          SizedBox(height: widget.isMobile ? 24 : 32),
                        ],

                        // Room
                        _buildSectionTitle('Room'),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _roomController,
                          decoration: InputDecoration(
                            labelText: 'Room Number',
                            hintText: 'e.g., Room 101',
                            prefixIcon: const Icon(Icons.room),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        SizedBox(height: widget.isMobile ? 24 : 32),

                        // Subject/Schedule
                        _buildSectionTitle('Subject & Schedule'),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _subjectScheduleController,
                          decoration: InputDecoration(
                            labelText: 'Subject & Time Schedule',
                            hintText: 'e.g., Math 101 - MWF 8:00-9:00 AM',
                            prefixIcon: const Icon(Icons.schedule),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        SizedBox(height: widget.isMobile ? 24 : 32),

                        // Remarks
                        _buildSectionTitle('Remarks (Optional)'),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _remarksController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: 'Additional Remarks',
                            hintText: 'Any additional notes...',
                            prefixIcon: const Icon(Icons.note),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        SizedBox(height: widget.isMobile ? 32 : 40),

                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _submitBorrowRequest,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Text(
                                    'Borrow Item',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 100), // Space for bottom bar
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
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
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemSelectionCard() {
    return InkWell(
      onTap: _selectItem,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceBright,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _selectedItem != null
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              _selectedItem != null ? Icons.check_circle : Icons.add_circle_outline,
              color: _selectedItem != null
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedItem != null ? 'Selected Item' : 'Select Item',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  if (_selectedItem != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _selectedItem!.itemName,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'ID: ${_selectedItem!.id} • SN: ${_selectedItem!.serialNumber}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ] else
                    Text(
                      'Tap to select an item from inventory',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeacherSelectionCard() {
    return InkWell(
      onTap: _selectTeacher,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceBright,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _selectedTeacher != null
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              _selectedTeacher != null ? Icons.check_circle : Icons.person_add_outlined,
              color: _selectedTeacher != null
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedTeacher != null ? 'Selected Teacher' : 'Select Teacher',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  if (_selectedTeacher != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _selectedTeacher!.name,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ] else
                    Text(
                      'Tap to enter teacher name',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
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

