import 'package:flutter/material.dart';
import '../../models/entities/borrowed_item.dart';
import '../../services/borrowed_item_service.dart';
import '../../widgets/skeleton.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, this.isMobile = true});

  final bool isMobile;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final BorrowedItemService _borrowedItemService = BorrowedItemService();
  List<BorrowedItem> _borrowedItems = [];
  List<BorrowedItem> _filteredItems = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedStatusFilter = 'All';
  String _selectedConditionFilter = 'All';

  // Pagination
  int _currentPage = 1;
  final List<int> _pageSizeOptions = [5, 10, 20, 50];
  int _pageSize = 10;

  final _searchController = TextEditingController();
  final List<String> _statusFilterOptions = [
    'All',
    'In Use',
    'Returned',
    'Damaged',
    'For Repair',
  ];
  final List<String> _conditionFilterOptions = [
    'All',
    'Excellent',
    'Good',
    'Fair',
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
      final items = await _borrowedItemService.getAllBorrowedItems();
      if (mounted) {
        setState(() {
          _borrowedItems = items;
          _filteredItems = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading borrowed items: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  void _filterItems() {
    setState(() {
      _filteredItems = _borrowedItems.where((item) {
        final matchesSearch =
            _searchQuery.isEmpty ||
            item.itemName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            item.teacher.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            item.room.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            item.occupied.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            item.borrowedId.toLowerCase().contains(_searchQuery.toLowerCase());

        final matchesStatusFilter =
            _selectedStatusFilter == 'All' ||
            item.status == _selectedStatusFilter;

        final matchesConditionFilter =
            _selectedConditionFilter == 'All' ||
            item.condition == _selectedConditionFilter;

        return matchesSearch && matchesStatusFilter && matchesConditionFilter;
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

  void _onConditionFilterChanged(String filter) {
    setState(() {
      _selectedConditionFilter = filter;
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
    return RefreshIndicator(
      onRefresh: _loadBorrowedItems,
      child: _isLoading
          ? HistorySkeleton(isMobile: widget.isMobile)
          : SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(widget.isMobile ? 16 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      'BORROWING HISTORY',
                      style: TextStyle(
                        fontSize: widget.isMobile ? 24 : 28,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                  SizedBox(height: widget.isMobile ? 24 : 32),
                  _buildSearchAndFilterSection(),
                  SizedBox(height: widget.isMobile ? 24 : 32),
                  _buildHistoryList(),
                ],
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
                hintText: 'Search by item, teacher, room, or ID...',
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
            // Condition Filter
            DropdownButtonFormField<String>(
              value: _selectedConditionFilter,
              decoration: InputDecoration(
                labelText: 'Filter by Condition',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              items: _conditionFilterOptions.map((String filter) {
                return DropdownMenuItem<String>(
                  value: filter,
                  child: Text(filter),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  _onConditionFilterChanged(newValue);
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
                  hintText: 'Search by item, teacher, room, or ID...',
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
            // Condition Filter
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedConditionFilter,
                decoration: InputDecoration(
                  labelText: 'Filter by Condition',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                items: _conditionFilterOptions.map((String filter) {
                  return DropdownMenuItem<String>(
                    value: filter,
                    child: Text(filter),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    _onConditionFilterChanged(newValue);
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
                      _selectedConditionFilter != 'All'
                  ? 'No items found matching your criteria'
                  : 'No borrowed items yet',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            if (_searchQuery.isNotEmpty ||
                _selectedStatusFilter != 'All' ||
                _selectedConditionFilter != 'All')
              TextButton(
                onPressed: () {
                  _searchController.clear();
                  _onSearchChanged('');
                  _onStatusFilterChanged('All');
                  _onConditionFilterChanged('All');
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
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceBright,
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

  Widget _buildMobileCard(BorrowedItem item) {
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
                      item.itemName,
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
                      color: _getStatusColor(item.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _getStatusColor(item.status).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      item.status,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _getStatusColor(item.status),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildInfoRow(Icons.person, 'Teacher', item.teacher),
              const SizedBox(height: 8),
              _buildInfoRow(Icons.room, 'Room', item.room),
              const SizedBox(height: 8),
              _buildInfoRow(Icons.person_outline, 'Occupied', item.occupied),
              const SizedBox(height: 8),
              _buildInfoRow(Icons.check_circle, 'Condition', item.condition),
              const SizedBox(height: 8),
              _buildInfoRow(Icons.calendar_today, 'Date', item.eventDate),
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'returned':
        return const Color(0xFF10B981); // Green
      case 'in use':
        return Theme.of(context).colorScheme.primary; // Primary color
      case 'damaged':
        return const Color(0xFFEF4444); // Red
      case 'for repair':
        return const Color(0xFFF59E0B); // Orange
      default:
        return Theme.of(
          context,
        ).colorScheme.onSurface.withOpacity(0.6); // Theme-aware gray
    }
  }

  void _showItemDetails(BorrowedItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Borrowed Item Details'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('ID', item.id.toString()),
              _buildDetailRow('Borrowed ID', item.borrowedId),
              _buildDetailRow('Item Name', item.itemName),
              _buildDetailRow('Teacher', item.teacher),
              _buildDetailRow('Room', item.room),
              _buildDetailRow('Occupied By', item.occupied),
              _buildDetailRow('Condition', item.condition),
              _buildDetailRow('Event Date', item.eventDate),
              _buildDetailRow(
                'Status',
                item.status,
                color: _getStatusColor(item.status),
              ),
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
