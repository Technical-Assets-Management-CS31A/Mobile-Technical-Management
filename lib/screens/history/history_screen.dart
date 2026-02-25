import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/entities/lend_item.dart';
import '../../services/lend_service.dart';
import '../../services/user_service.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/skeleton.dart';
import 'lend_item_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, this.isMobile = true});

  final bool isMobile;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final LendService _lendService = LendService();
  final StaffService _staffService = StaffService();
  List<LendItem> _lendItems = [];
  List<LendItem> _filteredItems = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedStatusFilter = 'All';
  String _selectedRoleFilter = 'All';

  // Pagination
  int _currentPage = 1;
  final List<int> _pageSizeOptions = [5, 10, 20, 50];
  int _pageSize = 10;

  final _searchController = TextEditingController();
  final List<String> _statusFilterOptions = [
    'All',
    'Active',
    'Borrowed',
    'Returned',
    'Overdue',
  ];
  final List<String> _roleFilterOptions = [
    'All',
    'Student',
    'Teacher',
    'Staff',
    'Guest',
  ];

  @override
  void initState() {
    super.initState();
    _loadBorrowedItems();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBorrowedItems() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userRole = authProvider.userRole;
      
      List<LendItem> items;
      
      // For students and teachers, load from their profile's lentItemsHistory
      if (userRole == 'Student' || userRole == 'Teacher') {
        final result = await _staffService.getUserProfile();
        if (result['success'] == true && result['data'] != null) {
          final userData = result['data'];
          final lentItemsHistory = userData['lentItemsHistory'] as List<dynamic>?;
          
          if (lentItemsHistory != null) {
            items = lentItemsHistory.map((item) => LendItem.fromJson(item)).toList();
          } else {
            items = [];
          }
        } else {
          items = [];
        }
      } else {
        // For other roles (Admin, Staff), load all lent items
        items = await _lendService.getAllLentItems(pageSize: 100);
      }
      
      if (mounted) {
        setState(() {
          _lendItems = items;
          _filteredItems = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading lent items: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  void _filterItems() {
    setState(() {
      _filteredItems = _lendItems.where((item) {
        final matchesSearch =
            _searchQuery.isEmpty ||
            item.borrowerFullName.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ) ||
            (item.teacherFullName?.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ??
                false) ||
            (item.room?.toLowerCase().contains(_searchQuery.toLowerCase()) ??
                false) ||
            (item.subjectTimeSchedule?.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ??
                false) ||
            (item.itemId?.toLowerCase().contains(_searchQuery.toLowerCase()) ??
                false) ||
            (item.itemName?.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ??
                false);

        final matchesStatusFilter =
            _selectedStatusFilter == 'All' ||
            (item.status == null && _selectedStatusFilter == 'Active') ||
            item.status == _selectedStatusFilter;

        final matchesRoleFilter =
            _selectedRoleFilter == 'All' ||
            item.borrowerRole == _selectedRoleFilter;

        return matchesSearch && matchesStatusFilter && matchesRoleFilter;
      }).toList();
      _currentPage = 1;
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _filterItems();
  }

  void _onStatusFilterChanged(String filter) {
    setState(() {
      _selectedStatusFilter = filter;
    });
    _filterItems();
  }

  void _onRoleFilterChanged(String filter) {
    setState(() {
      _selectedRoleFilter = filter;
    });
    _filterItems();
  }

  void _goToPreviousPage() {
    if (_currentPage > 1) {
      setState(() {
        _currentPage--;
      });
    }
  }

  void _goToNextPage() {
    final totalPages = (_filteredItems.length + _pageSize - 1) ~/ _pageSize;
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

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final isStudentOrTeacher = authProvider.userRole == 'Student' || 
                                   authProvider.userRole == 'Teacher';
        
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            title: Text(
              'Borrowing History',
              style: TextStyle(
                color: isStudentOrTeacher ? Colors.black : null,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.3,
              ),
            ),
            centerTitle: true,
            backgroundColor: isStudentOrTeacher 
                ? Colors.transparent 
                : Theme.of(context).colorScheme.primary,
            foregroundColor: isStudentOrTeacher 
                ? Colors.black 
                : Theme.of(context).colorScheme.onPrimary,
            elevation: 0,
            iconTheme: IconThemeData(
              color: isStudentOrTeacher ? Colors.black : Colors.white,
            ),
          ),
      body: RefreshIndicator(
        onRefresh: _loadBorrowedItems,
        child: _isLoading
            ? HistorySkeleton(isMobile: widget.isMobile)
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(widget.isMobile ? 16 : 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSearchAndFilterSection(),
                    SizedBox(height: widget.isMobile ? 24 : 32),
                    _buildHistoryList(),
                  ],
                ),
              ),
          ),
        );
      },
    );
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
                hintText: 'Search by borrower, item, teacher, room...',
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
            // Status Filter
            DropdownButtonFormField<String>(
              value: _selectedStatusFilter,
              decoration: InputDecoration(
                labelText: 'Filter by Status',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              items: _statusFilterOptions.map((String filter) {
                return DropdownMenuItem<String>(
                  value: filter,
                  child: Text(filter),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  _onStatusFilterChanged(newValue);
                }
              },
            ),
            const SizedBox(height: 12),
            // Role Filter
            DropdownButtonFormField<String>(
              value: _selectedRoleFilter,
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
              items: _roleFilterOptions.map((String filter) {
                return DropdownMenuItem<String>(
                  value: filter,
                  child: Text(filter),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  _onRoleFilterChanged(newValue);
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
                  hintText: 'Search by borrower, item, teacher, room...',
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
            // Status Filter
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedStatusFilter,
                decoration: InputDecoration(
                  labelText: 'Filter by Status',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                items: _statusFilterOptions.map((String filter) {
                  return DropdownMenuItem<String>(
                    value: filter,
                    child: Text(filter),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    _onStatusFilterChanged(newValue);
                  }
                },
              ),
            ),
            const SizedBox(width: 16),
            // Role Filter
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedRoleFilter,
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
                items: _roleFilterOptions.map((String filter) {
                  return DropdownMenuItem<String>(
                    value: filter,
                    child: Text(filter),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    _onRoleFilterChanged(newValue);
                  }
                },
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildHistoryList() {
    if (_filteredItems.isEmpty) {
      return Center(
        child: Column(
          children: [
            Icon(
              Icons.history_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty ||
                      _selectedStatusFilter != 'All' ||
                      _selectedRoleFilter != 'All'
                  ? 'No items found matching your criteria'
                  : 'No lent items yet',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            if (_searchQuery.isNotEmpty ||
                _selectedStatusFilter != 'All' ||
                _selectedRoleFilter != 'All')
              TextButton(
                onPressed: () {
                  _searchController.clear();
                  _onSearchChanged('');
                  _onStatusFilterChanged('All');
                  _onRoleFilterChanged('All');
                },
                child: const Text('Clear filters'),
              ),
          ],
        ),
      );
    }

    final totalItems = _filteredItems.length;
    final totalPages = (totalItems + _pageSize - 1) ~/ _pageSize;
    final startIndex = (_currentPage - 1) * _pageSize;
    final endIndex = (startIndex + _pageSize) > totalItems
        ? totalItems
        : startIndex + _pageSize;
    final pageItems = _filteredItems.sublist(startIndex, endIndex);

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
            return _buildMobileCard(pageItems[index]);
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

  Widget _buildMobileCard(LendItem item) {
    final status = item.status ?? 'Active';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceBright,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            _showItemDetails(item);
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.borrowerFullName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface,
                          letterSpacing: -0.3,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _getStatusColor(status),
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildInfoRow(CupertinoIcons.person_badge_plus, 'Role', item.borrowerRole),
                const SizedBox(height: 10),
                if (item.itemName != null)
                  _buildInfoRow(CupertinoIcons.cube_box, 'Item', item.itemName!),
                if (item.itemName != null) const SizedBox(height: 10),
                if (item.itemId != null)
                  _buildInfoRow(CupertinoIcons.tag, 'Item ID', item.itemId!),
                if (item.itemId != null) const SizedBox(height: 10),
                if (item.room != null)
                  _buildInfoRow(CupertinoIcons.building_2_fill, 'Room', item.room!),
                if (item.room != null) const SizedBox(height: 10),
                if (item.subjectTimeSchedule != null)
                  _buildInfoRow(
                    CupertinoIcons.clock,
                    'Schedule',
                    item.subjectTimeSchedule!,
                  ),
                if (item.subjectTimeSchedule != null) const SizedBox(height: 10),
                if (item.teacherFullName != null &&
                    item.teacherFullName!.isNotEmpty) ...[
                  _buildInfoRow(CupertinoIcons.person, 'Teacher', item.teacherFullName!),
                  const SizedBox(height: 10),
                ],
                if (item.lentAt != null)
                  _buildInfoRow(
                    CupertinoIcons.calendar,
                    'Lent Date',
                    _formatDate(item.lentAt!),
                  ),
                if (item.returnedAt != null) ...[
                  const SizedBox(height: 10),
                  _buildInfoRow(
                    CupertinoIcons.checkmark_circle,
                    'Returned',
                    _formatDate(item.returnedAt!),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
        ),
        const SizedBox(width: 10),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 15,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 15,
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'returned':
        return const Color(0xFF10B981); // Green
      case 'active':
      case 'borrowed':
        return Theme.of(context).colorScheme.primary; // Primary color
      case 'overdue':
        return const Color(0xFFEF4444); // Red
      default:
        return Theme.of(
          context,
        ).colorScheme.onSurface.withOpacity(0.6); // Theme-aware gray
    }
  }

  void _showItemDetails(LendItem item) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LendItemDetailScreen(lendItem: item),
      ),
    );

    // If the item was deleted or modified, refresh the list
    if (result == true) {
      _loadBorrowedItems();
    }
  }
}
