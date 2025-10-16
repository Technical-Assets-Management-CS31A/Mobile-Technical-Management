import 'package:flutter/material.dart';
import '../../models/entities/item.dart';
import '../../services/archive_service.dart';
import '../../widgets/barcode_widget.dart';
import 'archive_item_detail_screen.dart';

class ItemsArchiveScreen extends StatefulWidget {
  const ItemsArchiveScreen({super.key});

  @override
  State<ItemsArchiveScreen> createState() => _ItemsArchiveScreenState();
}

class _ItemsArchiveScreenState extends State<ItemsArchiveScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCondition = 'All';

  final List<int> _pageSizeOptions = [5, 10, 20, 50];
  int _pageSize = 10;
  int _currentPage = 1;

  final ArchiveService _archiveService = ArchiveService();
  List<Item> _items = [];
  bool _isLoading = true;

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
      // Load archived items using the ArchiveService
      final items = await _archiveService.getArchivedItems(
        page: _currentPage,
        pageSize: _pageSize,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        condition: _selectedCondition != 'All'
            ? ItemCondition.values.firstWhere(
                (c) => c.displayName == _selectedCondition,
                orElse: () => ItemCondition.New,
              )
            : null,
      );

      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading archived items: $e')),
        );
      }
    }
  }

  List<Item> get _filteredItems {
    var filtered = _items.where((item) {
      final matchesSearch =
          _searchQuery.isEmpty ||
          item.itemName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.serialNumber.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          item.itemMake.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (item.itemModel?.toLowerCase().contains(_searchQuery.toLowerCase()) ??
              false);

      final matchesCondition =
          _selectedCondition == 'All' ||
          item.condition.displayName == _selectedCondition;

      return matchesSearch && matchesCondition;
    }).toList();

    return filtered;
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _currentPage = 1;
    });
  }

  void _onConditionChanged(String condition) {
    setState(() {
      _selectedCondition = condition;
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

  Future<void> _restoreItem(Item item) async {
    try {
      final success = await _archiveService.restoreItem(item.id);
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${item.itemName} has been restored successfully'),
              backgroundColor: Colors.green,
            ),
          );
          await _loadItems(); // Refresh the list
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to restore ${item.itemName}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error restoring item: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _permanentlyDeleteItem(Item item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permanently Delete Item'),
        content: Text(
          'Are you sure you want to permanently delete "${item.itemName}"? '
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
        final success = await _archiveService.permanentlyDeleteItem(item.id);
        if (success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${item.itemName} has been permanently deleted'),
                backgroundColor: Colors.green,
              ),
            );
            await _loadItems(); // Refresh the list
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to delete ${item.itemName}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting item: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showBarcodeDialog(Item item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Barcode: ${item.itemName.isNotEmpty ? item.itemName : 'Archived Item'}',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Serial Number: ${item.serialNumber.isNotEmpty ? item.serialNumber : 'N/A'}',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 16),
            if (item.barcode != null && item.barcode!.isNotEmpty)
              BarcodeDisplayWidget(
                barcodeData: item.barcode!,
                width: 250,
                height: 100,
                label: 'Item Barcode',
              )
            else
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceBright,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.qr_code_2,
                      size: 48,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.3),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No barcode available',
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.5),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
          ],
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

  Color _getConditionColor(ItemCondition condition) {
    switch (condition) {
      case ItemCondition.New:
        return const Color(0xFF4CAF50); // Green
      case ItemCondition.Good:
        return const Color(0xFF2196F3); // Blue
      case ItemCondition.Defective:
        return const Color(0xFFF44336); // Red
      case ItemCondition.Refurbished:
        return const Color(0xFF9C27B0); // Purple
      case ItemCondition.NeedRepair:
        return const Color(0xFFFF9800); // Orange
    }
  }

  @override
  Widget build(BuildContext context) {
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
            hintText: 'Search archived items...',
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
        // Condition filter
        Row(
          children: [
            Text(
              'Filter by condition:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedCondition,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                items:
                    ['All', ...ItemCondition.values.map((c) => c.displayName)]
                        .map(
                          (condition) => DropdownMenuItem<String>(
                            value: condition,
                            child: Text(condition),
                          ),
                        )
                        .toList(),
                onChanged: (val) {
                  if (val != null) _onConditionChanged(val);
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
              _searchQuery.isNotEmpty || _selectedCondition != 'All'
                  ? 'No archived items found matching your criteria'
                  : 'No archived items yet',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            if (_searchQuery.isNotEmpty || _selectedCondition != 'All')
              TextButton(
                onPressed: () {
                  _searchController.clear();
                  _onSearchChanged('');
                  _onConditionChanged('All');
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

  Widget _buildItemTile(BuildContext context, Item item) {
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
          item.itemName.isNotEmpty ? item.itemName : 'Archived Item',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SN: ${item.serialNumber.isNotEmpty ? item.serialNumber : 'N/A'} • ${item.itemMake}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            if (item.itemModel != null && item.itemModel!.isNotEmpty)
              Text(
                'Model: ${item.itemModel}',
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
                color: _getConditionColor(item.condition).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getConditionColor(item.condition).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                item.condition.displayName,
                style: TextStyle(
                  color: _getConditionColor(item.condition),
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
            if (item.barcode != null && item.barcode!.isNotEmpty)
              IconButton(
                icon: Icon(
                  Icons.qr_code_2,
                  color: Theme.of(context).colorScheme.primary,
                ),
                onPressed: () => _showBarcodeDialog(item),
                tooltip: 'View Barcode',
              ),
            IconButton(
              icon: Icon(Icons.restore, color: Colors.green),
              onPressed: () => _restoreItem(item),
              tooltip: 'Restore Item',
            ),
            IconButton(
              icon: Icon(Icons.delete_forever, color: Colors.red),
              onPressed: () => _permanentlyDeleteItem(item),
              tooltip: 'Permanently Delete',
            ),
          ],
        ),
        onTap: () async {
          // Navigate to archive item detail screen
          final result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ArchiveItemDetailScreen(item: item),
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
