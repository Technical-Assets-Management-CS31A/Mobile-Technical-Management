import 'package:flutter/material.dart';
import '../../models/entities/lend_item.dart';
import '../../services/lend_service.dart';
import '../../widgets/skeleton.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, this.isMobile = true});

  final bool isMobile;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final LendService _lendService = LendService();
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
      final items = await _lendService.getAllLentItems(pageSize: 100);
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
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Borrowing History'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 0,
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
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => _showItemDetails(item),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
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
                        fontWeight: FontWeight.bold,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.9),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _getStatusColor(status).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _getStatusColor(status),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildInfoRow(Icons.badge, 'Role', item.borrowerRole),
              const SizedBox(height: 8),
              if (item.itemName != null)
                _buildInfoRow(Icons.inventory_2, 'Item', item.itemName!),
              if (item.itemName != null) const SizedBox(height: 8),
              if (item.itemId != null)
                _buildInfoRow(Icons.tag, 'Item ID', item.itemId!),
              if (item.itemId != null) const SizedBox(height: 8),
              if (item.room != null)
                _buildInfoRow(Icons.room, 'Room', item.room!),
              if (item.room != null) const SizedBox(height: 8),
              if (item.subjectTimeSchedule != null)
                _buildInfoRow(
                  Icons.schedule,
                  'Schedule',
                  item.subjectTimeSchedule!,
                ),
              if (item.subjectTimeSchedule != null) const SizedBox(height: 8),
              if (item.teacherFullName != null &&
                  item.teacherFullName!.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildInfoRow(Icons.person, 'Teacher', item.teacherFullName!),
              ],
              if (item.lentAt != null) ...[
                const SizedBox(height: 8),
                _buildInfoRow(
                  Icons.calendar_today,
                  'Lent Date',
                  _formatDate(item.lentAt!),
                ),
              ],
              if (item.returnedAt != null) ...[
                const SizedBox(height: 8),
                _buildInfoRow(
                  Icons.event_available,
                  'Returned',
                  _formatDate(item.returnedAt!),
                ),
              ],
            ],
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
          size: 16,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.9),
              fontWeight: FontWeight.w600,
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

  void _showItemDetails(LendItem item) {
    final status = item.status ?? 'Active';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lent Item Details'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (item.id != null) _buildDetailRow('ID', item.id!),
              _buildDetailRow('Borrower', item.borrowerFullName),
              _buildDetailRow('Role', item.borrowerRole),
              if (item.teacherFullName != null &&
                  item.teacherFullName!.isNotEmpty)
                _buildDetailRow('Teacher', item.teacherFullName!),
              const Divider(),
              if (item.itemName != null)
                _buildDetailRow('Item Name', item.itemName!),
              if (item.itemId != null) _buildDetailRow('Item ID', item.itemId!),
              if (item.item != null) ...[
                _buildDetailRow('Serial Number', item.item!.serialNumber),
                _buildDetailRow('Category', item.item!.category.displayName),
                _buildDetailRow('Condition', item.item!.condition.displayName),
              ],
              const Divider(),
              if (item.room != null) _buildDetailRow('Room', item.room!),
              if (item.subjectTimeSchedule != null)
                _buildDetailRow('Schedule', item.subjectTimeSchedule!),
              if (item.remarks != null && item.remarks!.isNotEmpty)
                _buildDetailRow('Remarks', item.remarks!),
              const Divider(),
              if (item.lentAt != null)
                _buildDetailRow('Lent Date', _formatDate(item.lentAt!)),
              if (item.returnedAt != null)
                _buildDetailRow('Returned Date', _formatDate(item.returnedAt!)),
              _buildDetailRow('Status', status, color: _getStatusColor(status)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color:
                    color ??
                    Theme.of(context).colorScheme.onSurface.withOpacity(0.9),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
