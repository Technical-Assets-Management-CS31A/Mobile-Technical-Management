import 'package:flutter/material.dart';
import '../../models/entities/user.dart';
import '../../services/user_service.dart';
import '../../widgets/skeleton.dart';
import '../users/add_user_screen.dart';
import '../users/users_detail_screen.dart';

class RegisteredModulesScreen extends StatefulWidget {
  const RegisteredModulesScreen({super.key, this.isMobile = false});

  final bool isMobile;

  @override
  State<RegisteredModulesScreen> createState() => _RegisteredModulesScreenState();
}

class _RegisteredModulesScreenState extends State<RegisteredModulesScreen> {
  final StaffService _staffService = StaffService();
  bool _isLoading = true;
  List<Staff> _staffList = [];
  List<Staff> _filteredStaffList = [];
  String _searchQuery = '';
  String _selectedFilter = 'All';
  int _currentPage = 1;
  final List<int> _pageSizeOptions = [5, 10, 20, 50];
  int _pageSize = 10;
  final List<String> _filterOptions = ['All', 'Student', 'Teacher'];

  final _searchController = TextEditingController();

  // Store reference to ScaffoldMessenger to avoid disposal issues
  ScaffoldMessengerState? _scaffoldMessenger;

  @override
  void initState() {
    super.initState();
    _loadStaffData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Store reference to ScaffoldMessenger to avoid disposal issues
    _scaffoldMessenger = ScaffoldMessenger.of(context);
  }

  Future<void> _loadStaffData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get all teachers and students using the dedicated service method
      final staffList = await _staffService.getAllTeachersAndStudents();
      
      if (mounted) {
        setState(() {
          _staffList = staffList;
          _filterStaff();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _scaffoldMessenger?.showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterStaff() {
    setState(() {
      _filteredStaffList = _staffList.where((staff) {
        final matchesSearch =
            staff.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (staff.position?.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ??
                false) ||
            staff.email.toLowerCase().contains(_searchQuery.toLowerCase());

        final matchesFilter =
            _selectedFilter == 'All' ||
            (_selectedFilter == 'Student' && staff.userRole == 'Student') ||
            (_selectedFilter == 'Teacher' && staff.userRole == 'Teacher');

        return matchesSearch && matchesFilter;
      }).toList();
      _currentPage = 1;
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _filterStaff();
  }

  void _onFilterChanged(String filter) {
    setState(() {
      _selectedFilter = filter;
    });
    _filterStaff();
  }

  void _goToPreviousPage() {
    if (_currentPage > 1) {
      setState(() {
        _currentPage--;
      });
    }
  }

  void _goToNextPage() {
    final totalPages = (_filteredStaffList.length + _pageSize - 1) ~/ _pageSize;
    if (_currentPage < totalPages) {
      setState(() {
        _currentPage++;
      });
    }
  }

  void _changePageSize(int newSize) {
    setState(() {
      _pageSize = newSize;
      _currentPage = 1;
    });
  }

  Future<void> _viewStaff(Staff staff) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            StaffDetailScreen(staff: staff, startInEdit: false),
      ),
    );
    if (result is Map && result['updated'] is Staff) {
      try {
        final updated = result['updated'] as Staff;
        await _staffService.updateStaff(updated);
        await _loadStaffData(); // Reload data from service
        if (mounted) {
          _scaffoldMessenger?.showSnackBar(
            SnackBar(
              content: Text('${updated.name} updated successfully!'),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error updating user: $e')));
        }
      }
    } else if (result is Map && result['deleted'] is String) {
      try {
        final id = result['deleted'] as String;
        await _staffService.deleteStaff(id);
        await _loadStaffData(); // Reload data from service
        if (mounted) {
          _scaffoldMessenger?.showSnackBar(
            const SnackBar(
              content: Text('User archived successfully!'),
              backgroundColor: Color(0xFFF59E0B),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error archiving user: $e')));
        }
      }
    }
  }

  Future<void> _editStaff(Staff staff) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            StaffDetailScreen(staff: staff, startInEdit: true),
      ),
    );
    if (result is Map && result['updated'] is Staff) {
      try {
        final updated = result['updated'] as Staff;
        await _staffService.updateStaff(updated);
        await _loadStaffData(); // Reload data from service
        if (mounted) {
          _scaffoldMessenger?.showSnackBar(
            SnackBar(
              content: Text('${updated.name} updated successfully!'),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error updating user: $e')));
        }
      }
    } else if (result is Map && result['deleted'] is String) {
      try {
        final id = result['deleted'] as String;
        await _staffService.deleteStaff(id);
        await _loadStaffData(); // Reload data from service
        if (mounted) {
          _scaffoldMessenger?.showSnackBar(
            const SnackBar(
              content: Text('User archived successfully!'),
              backgroundColor: Color(0xFFF59E0B),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error archiving user: $e')));
        }
      }
    }
  }

  void _deleteStaff(Staff staff) {
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
                'Are you sure you want to archive ${staff.name}?',
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
                      onPressed: () async {
                        Navigator.pop(context);
                        try {
                          await _staffService.deleteStaff(staff.id);
                          await _loadStaffData(); // Reload data from service
                          if (mounted) {
                            _scaffoldMessenger?.showSnackBar(
                              SnackBar(
                                content: Text(
                                  '${staff.name} archived successfully!',
                                ),
                                backgroundColor: const Color(0xFFF59E0B),
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            _scaffoldMessenger?.showSnackBar(
                              SnackBar(
                                content: Text('Error archiving user: $e'),
                              ),
                            );
                          }
                        }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Registered Modules'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadStaffData,
          child: _isLoading
              ? StaffSkeleton(isMobile: widget.isMobile)
              : SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.all(widget.isMobile ? 16 : 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Text(
                          'REGISTERED MODULES',
                          style: TextStyle(
                            fontSize: widget.isMobile ? 24 : 28,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                      SizedBox(height: widget.isMobile ? 24 : 32),
                      _buildSummarySection(),
                      _buildSearchAndFilterSection(),
                      SizedBox(height: widget.isMobile ? 24 : 32),
                      _buildStaffList(),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildSummarySection() {
    if (widget.isMobile) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _onFilterChanged('All'),
                  child: _buildSummaryCard(
                    'Total Users',
                    '${_staffList.length}',
                    Icons.people,
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => _onFilterChanged('Student'),
                  child: _buildSummaryCard(
                    'Students',
                    '${_staffList.where((s) => s.userRole == 'Student').length}',
                    Icons.school,
                    const Color(0xFF8B5CF6),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _onFilterChanged('Teacher'),
                  child: _buildSummaryCard(
                    'Teachers',
                    '${_staffList.where((s) => s.userRole == 'Teacher').length}',
                    Icons.person_outline,
                    const Color(0xFFF59E0B),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => _onFilterChanged('All'),
                  child: _buildSummaryCard(
                    'Active Users',
                    '${_staffList.where((s) => (s.status?.toLowerCase() ?? 'offline') == 'online' || (s.status?.toLowerCase() ?? 'offline') == 'active').length}/${_staffList.length}',
                    Icons.check_circle,
                    const Color(0xFF10B981),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    } else {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _onFilterChanged('All'),
                  child: _buildSummaryCard(
                    'Total Users',
                    '${_staffList.length}',
                    Icons.people,
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: GestureDetector(
                  onTap: () => _onFilterChanged('Student'),
                  child: _buildSummaryCard(
                    'Students',
                    '${_staffList.where((s) => s.userRole == 'Student').length}',
                    Icons.school,
                    const Color(0xFF8B5CF6),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _onFilterChanged('Teacher'),
                  child: _buildSummaryCard(
                    'Teachers',
                    '${_staffList.where((s) => s.userRole == 'Teacher').length}',
                    Icons.person_outline,
                    const Color(0xFFF59E0B),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: GestureDetector(
                  onTap: () => _onFilterChanged('All'),
                  child: _buildSummaryCard(
                    'Online Users',
                    '${_staffList.where((s) => (s.status?.toLowerCase() ?? 'offline') == 'online' || (s.status?.toLowerCase() ?? 'offline') == 'active').length}/${_staffList.length}',
                    Icons.check_circle,
                    const Color(0xFF10B981),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }
  }

  Widget _buildSearchAndFilterSection() {
    if (widget.isMobile) {
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Column(
          children: [
            // Search Bar
            TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search users...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceBright,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Filter dropdown
            DropdownButtonFormField<String>(
              value: _selectedFilter,
              decoration: InputDecoration(
                labelText: 'Filter by Role',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              items: _filterOptions.map((String filter) {
                return DropdownMenuItem<String>(
                  value: filter,
                  child: Text(filter),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  _onFilterChanged(newValue);
                }
              },
            ),
          ],
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Row(
          children: [
            // Search Bar
            Expanded(
              flex: 2,
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search users by name, role, or email...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceBright,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Filter Dropdown
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedFilter,
                decoration: InputDecoration(
                  labelText: 'Filter by Role',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                items: _filterOptions.map((String filter) {
                  return DropdownMenuItem<String>(
                    value: filter,
                    child: Text(filter),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    _onFilterChanged(newValue);
                  }
                },
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildStaffList() {
    if (_filteredStaffList.isEmpty) {
      return Center(
        child: Column(
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty || _selectedFilter != 'All'
                  ? 'No users found matching your criteria'
                  : 'No users yet',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            if (_searchQuery.isNotEmpty || _selectedFilter != 'All')
              TextButton(
                onPressed: () {
                  _searchController.clear();
                  _onSearchChanged('');
                  _onFilterChanged('All');
                },
                child: const Text('Clear filters'),
              ),
          ],
        ),
      );
    } else {
      final totalItems = _filteredStaffList.length;
      final totalPages = (totalItems + _pageSize - 1) ~/ _pageSize;
      final startIndex = (_currentPage - 1) * _pageSize;
      final endIndex = (startIndex + _pageSize) > totalItems
          ? totalItems
          : startIndex + _pageSize;
      final pageItems = _filteredStaffList.sublist(startIndex, endIndex);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Page size and count
          Row(
            children: [
              Text(
                'Showing ${startIndex + 1}-$endIndex of $totalItems',
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: 160,
                child: DropdownButtonFormField<int>(
                  value: _pageSize,
                  decoration: InputDecoration(
                    labelText: 'Page size',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: _pageSizeOptions
                      .map(
                        (s) => DropdownMenuItem<int>(
                          value: s,
                          child: Text('$s per page'),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    if (val != null) _changePageSize(val);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Paged list
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: pageItems.length,
            itemBuilder: (context, index) {
              final staff = pageItems[index];
              return _buildStaffCard(staff);
            },
          ),

          const SizedBox(height: 12),

          // Pagination controls
          Row(
            children: [
              Text('Page $_currentPage of $totalPages'),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: _currentPage > 1 ? _goToPreviousPage : null,
                icon: const Icon(Icons.chevron_left),
                label: const Text('Prev'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _currentPage < totalPages ? _goToNextPage : null,
                icon: const Icon(Icons.chevron_right),
                label: const Text('Next'),
              ),
            ],
          ),
        ],
      );
    }
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(widget.isMobile ? 16 : 20),
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
              Icon(icon, color: color, size: widget.isMobile ? 28 : 24),
            ],
          ),
          SizedBox(height: widget.isMobile ? 12 : 16),
          Text(
            value,
            style: TextStyle(
              fontSize: widget.isMobile ? 32 : 28,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: widget.isMobile ? 16 : 14,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffCard(Staff staff) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(widget.isMobile ? 16 : 20),
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
        children: [
          Row(
            children: [
              // Avatar
              Container(
                width: widget.isMobile ? 50 : 60,
                height: widget.isMobile ? 50 : 60,
                decoration: BoxDecoration(
                  color: _getPositionColor(
                    staff.position,
                    userRole: staff.userRole,
                  ).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(
                    widget.isMobile ? 25 : 30,
                  ),
                ),
                child: Icon(
                  _getPositionIcon(staff.position, userRole: staff.userRole),
                  color: _getPositionColor(
                    staff.position,
                    userRole: staff.userRole,
                  ),
                  size: widget.isMobile ? 24 : 28,
                ),
              ),
              SizedBox(width: widget.isMobile ? 16 : 20),
              // Staff info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      staff.name,
                      style: TextStyle(
                        fontSize: widget.isMobile ? 16 : 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      staff.userRole,
                      style: TextStyle(
                        fontSize: widget.isMobile ? 12 : 14,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(
                              staff.status ?? 'online',
                            ).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: _getStatusColor(
                                    staff.status ?? 'online',
                                  ),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _getStatusText(staff.status ?? 'online'),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _getStatusColor(
                                    staff.status ?? 'online',
                                  ),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getPositionColor(
                              staff.position,
                              userRole: staff.userRole,
                            ).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            staff.userRole,
                            style: TextStyle(
                              fontSize: 12,
                              color: _getPositionColor(
                                staff.position,
                                userRole: staff.userRole,
                              ),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Triple burger dot menu
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                  size: 24,
                ),
                onSelected: (String value) {
                  switch (value) {
                    case 'view':
                      _viewStaff(staff);
                      break;
                    case 'edit':
                      _editStaff(staff);
                      break;
                    case 'delete':
                      _deleteStaff(staff);
                      break;
                  }
                },
                itemBuilder: (BuildContext context) => [
                  PopupMenuItem<String>(
                    value: 'view',
                    child: Row(
                      children: [
                        Icon(
                          Icons.visibility,
                          color: Theme.of(context).colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        const Text('View Details'),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'edit',
                    child: Row(
                      children: [
                        const Icon(
                          Icons.edit,
                          color: Color(0xFFF59E0B),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        const Text('Edit'),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(
                          Icons.archive,
                          color: Colors.orange,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        const Text('Archive'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Additional staff information
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        Icons.email,
                        'Email',
                        staff.email,
                        widget.isMobile,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildInfoItem(
                        Icons.phone,
                        'Phone',
                        staff.phoneNumber ?? 'No Phone',
                        widget.isMobile,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        Icons.person,
                        'Username',
                        staff.username,
                        widget.isMobile,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildInfoItem(
                        Icons.badge,
                        'ID',
                        staff.id,
                        widget.isMobile,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(
    IconData icon,
    String label,
    String value,
    bool isMobile, {
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          size: isMobile ? 16 : 18,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: isMobile ? 10 : 12,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: isMobile ? 12 : 14,
                  color:
                      valueColor ??
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.9),
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getPositionColor(String? position, {String? userRole}) {
    if (userRole == 'Student') {
      return const Color(0xFF8B5CF6); // Purple for students
    }
    if (userRole == 'Teacher') {
      return const Color(0xFFF59E0B); // Orange for teachers
    }
    if (position == null) {
      return Theme.of(context).colorScheme.onSurface.withOpacity(0.6);
    }
    return Theme.of(context).colorScheme.onSurface.withOpacity(0.6);
  }

  IconData _getPositionIcon(String? position, {String? userRole}) {
    if (userRole == 'Student') {
      return Icons.school;
    }
    if (userRole == 'Teacher') {
      return Icons.person_outline;
    }
    return Icons.person;
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'online':
      case 'active':
        return const Color(0xFF10B981); // Green
      case 'offline':
        return Theme.of(
          context,
        ).colorScheme.onSurface.withOpacity(0.6); // Theme-aware gray
      case 'busy':
        return const Color(0xFFF59E0B); // Orange
      case 'away':
        return const Color(0xFF3B82F6); // Blue
      case 'inactive':
        return const Color(0xFF6B7280); // Gray
      case 'pending':
        return const Color(0xFF8B5CF6); // Purple
      default:
        return const Color(0xFF10B981); // Default to green
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'online':
      case 'active':
        return 'Online';
      case 'offline':
        return 'Offline';
      case 'busy':
        return 'Busy';
      case 'away':
        return 'Away';
      case 'inactive':
        return 'Inactive';
      case 'pending':
        return 'Pending';
      default:
        return 'Online';
    }
  }
}
