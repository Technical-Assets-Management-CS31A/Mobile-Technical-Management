import 'package:flutter/material.dart';
import '../../models/entities/staff.dart';
import '../../services/archive_service.dart';
import 'archive_user_detail_screen.dart';

class UsersArchiveScreen extends StatefulWidget {
  const UsersArchiveScreen({super.key});

  @override
  State<UsersArchiveScreen> createState() => _UsersArchiveScreenState();
}

class _UsersArchiveScreenState extends State<UsersArchiveScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'All';

  final List<int> _pageSizeOptions = [5, 10, 20, 50];
  int _pageSize = 10;
  int _currentPage = 1;

  final ArchiveService _archiveService = ArchiveService();
  List<Staff> _staffList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeAndLoadUsers();
  }

  Future<void> _initializeAndLoadUsers() async {
    try {
      await _archiveService.initialize();
      await _loadStaffData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error initializing service: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStaffData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load archived users using the ArchiveService
      final staff = await _archiveService.getArchivedUsers(
        page: _currentPage,
        pageSize: _pageSize,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        status: _selectedFilter != 'All' ? _selectedFilter : null,
      );

      setState(() {
        _staffList = staff;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading archived users: $e')),
        );
      }
    }
  }

  List<Staff> get _filteredStaffList {
    return _staffList.where((staff) {
      final matchesSearch =
          _searchQuery.isEmpty ||
          staff.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          staff.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          staff.position.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          staff.username.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesFilter =
          _selectedFilter == 'All' || staff.status == _selectedFilter;

      return matchesSearch && matchesFilter;
    }).toList();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _currentPage = 1;
    });
  }

  void _onFilterChanged(String filter) {
    setState(() {
      _selectedFilter = filter;
      _currentPage = 1;
    });
  }

  void _changePageSize(int newSize) {
    setState(() {
      _pageSize = newSize;
      _currentPage = 1;
    });
  }

  void _changePage(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  Future<void> _restoreUser(Staff staff) async {
    try {
      final success = await _archiveService.restoreUser(staff.id);
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${staff.name} has been restored successfully'),
              backgroundColor: Colors.green,
            ),
          );
          await _loadStaffData(); // Refresh the list
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to restore ${staff.name}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error restoring user: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _permanentlyDeleteUser(Staff staff) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permanently Delete User'),
        content: Text(
          'Are you sure you want to permanently delete "${staff.name}"? '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final success = await _archiveService.permanentlyDeleteUser(staff.id);
        if (success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${staff.name} has been permanently deleted'),
                backgroundColor: Colors.green,
              ),
            );
            await _loadStaffData(); // Refresh the list
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to delete ${staff.name}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting user: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Color _getPositionColor(String position) {
    switch (position.toLowerCase()) {
      case 'admin':
        return const Color(0xFFE53E3E);
      case 'manager':
        return const Color(0xFF3182CE);
      case 'supervisor':
        return const Color(0xFF38A169);
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
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadStaffData,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Search and filter section
                      _buildSearchAndFilterSection(),
                      const SizedBox(height: 24),
                      // Staff list
                      _buildStaffList(),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildSearchAndFilterSection() {
    return Column(
      children: [
        // Search bar
        TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          decoration: InputDecoration(
            hintText: 'Search archived users...',
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
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceBright,
          ),
        ),
        const SizedBox(height: 16),
        // Status filter
        Row(
          children: [
            Text(
              'Filter by status:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedFilter,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                items: ['All', 'Active', 'Inactive', 'Suspended']
                    .map(
                      (status) => DropdownMenuItem<String>(
                        value: status,
                        child: Text(status),
                      ),
                    )
                    .toList(),
                onChanged: (val) {
                  if (val != null) _onFilterChanged(val);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStaffList() {
    final filteredStaff = _filteredStaffList;

    if (filteredStaff.isEmpty) {
      return Center(
        child: Column(
          children: [
            Icon(
              Icons.archive_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty || _selectedFilter != 'All'
                  ? 'No archived users found matching your criteria'
                  : 'No archived users yet',
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
    }

    final totalItems = filteredStaff.length;
    final totalPages = (totalItems + _pageSize - 1) ~/ _pageSize;
    final startIndex = (_currentPage - 1) * _pageSize;
    final endIndex = (startIndex + _pageSize) > totalItems
        ? totalItems
        : startIndex + _pageSize;
    final pageItems = filteredStaff.sublist(startIndex, endIndex);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Page size and count
        Row(
          children: [
            Text(
              'Showing ${startIndex + 1}-$endIndex of $totalItems',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
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
        if (totalPages > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: _currentPage > 1
                    ? () => _changePage(_currentPage - 1)
                    : null,
                icon: const Icon(Icons.chevron_left),
              ),
              ...List.generate(
                totalPages,
                (index) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: TextButton(
                    onPressed: () => _changePage(index + 1),
                    style: TextButton.styleFrom(
                      backgroundColor: _currentPage == index + 1
                          ? Theme.of(context).colorScheme.primary
                          : null,
                      foregroundColor: _currentPage == index + 1
                          ? Theme.of(context).colorScheme.onPrimary
                          : null,
                    ),
                    child: Text('${index + 1}'),
                  ),
                ),
              ),
              IconButton(
                onPressed: _currentPage < totalPages
                    ? () => _changePage(_currentPage + 1)
                    : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildStaffCard(Staff staff) {
    return GestureDetector(
      onTap: () async {
        // Navigate to archive user detail screen
        final result = await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ArchiveUserDetailScreen(staff: staff),
          ),
        );

        // If user was restored or deleted, refresh the list
        if (result == true) {
          await _loadStaffData();
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
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
          children: [
            Row(
              children: [
                // Avatar
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _getPositionColor(staff.position).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Icon(
                    Icons.archive,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                // Staff info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        staff.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        staff.position,
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _getPositionColor(
                            staff.position,
                          ).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _getPositionColor(
                              staff.position,
                            ).withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          staff.status ?? 'Unknown',
                          style: TextStyle(
                            color: _getPositionColor(staff.position),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Action buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.restore, color: Colors.green),
                      onPressed: () => _restoreUser(staff),
                      tooltip: 'Restore User',
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_forever, color: Colors.red),
                      onPressed: () => _permanentlyDeleteUser(staff),
                      tooltip: 'Permanently Delete',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Additional info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
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
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildInfoItem(
                          Icons.phone,
                          'Phone',
                          staff.phoneNumber,
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
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildInfoItem(Icons.badge, 'ID', staff.id),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
