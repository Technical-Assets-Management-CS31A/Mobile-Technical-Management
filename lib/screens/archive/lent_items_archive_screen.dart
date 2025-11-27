import 'package:flutter/material.dart';
import '../../models/entities/lend_item.dart';
import '../../services/archive_service.dart';
import '../history/lend_item_detail_screen.dart';

class LentItemsArchiveScreen extends StatefulWidget {
  const LentItemsArchiveScreen({super.key});

  @override
  State<LentItemsArchiveScreen> createState() => _LentItemsArchiveScreenState();
}

class _LentItemsArchiveScreenState extends State<LentItemsArchiveScreen>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedStatusFilter = 'All';
  String _selectedRoleFilter = 'All';

  final List<int> _pageSizeOptions = [5, 10, 20, 50];
  int _pageSize = 10;
  int _currentPage = 1;

  final ArchiveService _archiveService = ArchiveService();
  List<LendItem> _lendItems = [];
  bool _isLoading = true;

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
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeAndLoadItems();
  }

  Future<void> _initializeAndLoadItems() async {
    try {
      await _archiveService.initialize();
      await _loadItems();
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

  Future<void> _loadItems() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load archived lent items using the ArchiveService
      final items = await _archiveService.getArchivedLentItems(
        page: _currentPage,
        pageSize: _pageSize,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        status: _selectedStatusFilter != 'All' ? _selectedStatusFilter : null,
        borrowerRole: _selectedRoleFilter != 'All' ? _selectedRoleFilter : null,
      );

      setState(() {
        _lendItems = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading archived lent items: $e')),
        );
      }
    }
  }

  List<LendItem> get _filteredItems {
    var filtered = _lendItems.where((item) {
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

    return filtered;
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _currentPage = 1;
    });
  }

  void _onStatusFilterChanged(String filter) {
    setState(() {
      _selectedStatusFilter = filter;
      _currentPage = 1;
    });
  }

  void _onRoleFilterChanged(String filter) {
    setState(() {
      _selectedRoleFilter = filter;
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

  Future<void> _restoreLentItem(LendItem item) async {
    if (item.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot restore item: ID is missing'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    try {
      final success = await _archiveService.restoreLentItem(item.id!);
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Lent item for ${item.borrowerFullName} has been restored successfully',
              ),
              backgroundColor: Colors.green,
            ),
          );
          await _loadItems(); // Refresh the list
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to restore lent item'),
              backgroundColor: Color(0xFFEF4444),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error restoring lent item: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Future<void> _permanentlyDeleteLentItem(LendItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permanently Delete Lent Item'),
        content: Text(
          'Are you sure you want to permanently delete the lent item record for "${item.borrowerFullName}"? '
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
      if (item.id == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot delete item: ID is missing'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
        return;
      }

      try {
        final success = await _archiveService.permanentlyDeleteLentItem(
          item.id!,
        );
        if (success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Lent item for ${item.borrowerFullName} has been permanently deleted',
                ),
                backgroundColor: Colors.green,
              ),
            );
            await _loadItems(); // Refresh the list
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to delete lent item'),
                backgroundColor: Color(0xFFEF4444),
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting lent item: $e'),
              backgroundColor: const Color(0xFFEF4444),
            ),
          );
        }
      }
    }
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

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadItems,
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
                      // Items list
                      _buildItemsList(),
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
            hintText: 'Search archived lent items...',
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
        // Filters
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedStatusFilter,
                decoration: InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                items: _statusFilterOptions
                    .map(
                      (status) => DropdownMenuItem<String>(
                        value: status,
                        child: Text(status),
                      ),
                    )
                    .toList(),
                onChanged: (val) {
                  if (val != null) _onStatusFilterChanged(val);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedRoleFilter,
                decoration: InputDecoration(
                  labelText: 'Role',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                items: _roleFilterOptions
                    .map(
                      (role) => DropdownMenuItem<String>(
                        value: role,
                        child: Text(role),
                      ),
                    )
                    .toList(),
                onChanged: (val) {
                  if (val != null) _onRoleFilterChanged(val);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildItemsList() {
    final filteredItems = _filteredItems;

    if (filteredItems.isEmpty) {
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
              _searchQuery.isNotEmpty ||
                      _selectedStatusFilter != 'All' ||
                      _selectedRoleFilter != 'All'
                  ? 'No archived lent items found matching your criteria'
                  : 'No archived lent items yet',
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

    final totalItems = filteredItems.length;
    final totalPages = (totalItems + _pageSize - 1) ~/ _pageSize;
    final startIndex = (_currentPage - 1) * _pageSize;
    final endIndex = (startIndex + _pageSize) > totalItems
        ? totalItems
        : startIndex + _pageSize;
    final pageItems = filteredItems.sublist(startIndex, endIndex);

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
            final item = pageItems[index];
            return _buildItemTile(context, item);
          },
        ),

        const SizedBox(height: 12),

        // Pagination controls
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: _currentPage > 1
                  ? () => _changePage(_currentPage - 1)
                  : null,
              icon: const Icon(Icons.chevron_left),
              label: const Text('Prev'),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: _currentPage < totalPages
                  ? () => _changePage(_currentPage + 1)
                  : null,
              icon: const Icon(Icons.chevron_right),
              label: const Text('Next'),
            ),
            const Spacer(),
            Text('Page $_currentPage of $totalPages'),
          ],
        ),
      ],
    );
  }

  Widget _buildItemTile(BuildContext context, LendItem item) {
    final status = item.status ?? 'Active';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(
            context,
          ).colorScheme.primary.withOpacity(0.1),
          child: Icon(
            Icons.archive,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Text(
          item.borrowerFullName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Role: ${item.borrowerRole}${item.itemName != null ? ' • ${item.itemName}' : ''}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            if (item.lentAt != null)
              Text(
                'Lent: ${_formatDate(item.lentAt!)}',
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _getStatusColor(status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getStatusColor(status).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                status,
                style: TextStyle(
                  color: _getStatusColor(status),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.restore, color: Colors.green),
              onPressed: () => _restoreLentItem(item),
              tooltip: 'Restore Lent Item',
            ),
            IconButton(
              icon: const Icon(Icons.delete_forever, color: Colors.red),
              onPressed: () => _permanentlyDeleteLentItem(item),
              tooltip: 'Permanently Delete',
            ),
          ],
        ),
        onTap: () async {
          // Navigate to lend item detail screen
          final result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => LendItemDetailScreen(lendItem: item),
            ),
          );

          // If item was restored or deleted, refresh the list
          if (result == true) {
            await _loadItems();
          }
        },
      ),
    );
  }
}
