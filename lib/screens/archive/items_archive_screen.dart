import 'package:flutter/material.dart';
import '../../models/entities/item.dart';
import '../../services/inventory_service.dart';

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

  final InventoryService _inventoryService = InventoryService();
  List<Item> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeAndLoadItems();
  }

  Future<void> _initializeAndLoadItems() async {
    try {
      await _inventoryService.initialize();
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
      // Load archived items - you'll need to implement this in your service
      // For now, using empty list as placeholder
      final items = <Item>[];

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

  void _showBarcodeDialog(Item item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Barcode: ${item.itemName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Serial Number: ${item.serialNumber}'),
            if (item.barcode != null && item.barcode!.isNotEmpty)
              Text('Barcode: ${item.barcode}'),
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
          item.itemName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SN: ${item.serialNumber} • ${item.itemMake}',
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
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: () {
          // Navigate to item detail or show archived item info
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Viewing archived item: ${item.itemName}')),
          );
        },
      ),
    );
  }
}
