import 'package:flutter/material.dart';
import '../../models/entities/item.dart';
import '../../services/inventory_service.dart';
import 'stock_view_screen.dart';

class ItemSelectionScreen extends StatefulWidget {
  final bool isMobile;

  const ItemSelectionScreen({super.key, this.isMobile = true});

  @override
  State<ItemSelectionScreen> createState() => _ItemSelectionScreenState();
}

class _ItemSelectionScreenState extends State<ItemSelectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _selectedCondition = 'All';

  final List<int> _pageSizeOptions = [10, 20, 50, 100];
  int _pageSize = 20;
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
      final items = await _inventoryService.getAllItems(
        page: _currentPage,
        pageSize: _pageSize,
        category: _selectedCategory != 'All'
            ? ItemCategory.fromString(_selectedCategory)
            : null,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      );
      setState(() {
        _items = items;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading items: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<Item> get _filteredItems {
    return _items.where((item) {
      final matchesSearch =
          item.itemName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.serialNumber.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          item.id.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesCategory = _selectedCategory == 'All'
          ? true
          : item.category.displayName == _selectedCategory;

      final matchesCondition = _selectedCondition == 'All'
          ? true
          : item.condition.displayName == _selectedCondition;

      return matchesSearch && matchesCategory && matchesCondition;
    }).toList();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _currentPage = 1;
    });
    // Debounce search to avoid too many API calls
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_searchQuery == query) {
        _loadItems();
      }
    });
  }

  void _onCategoryChanged(String? category) {
    if (category == null) return;
    setState(() {
      _selectedCategory = category;
      _currentPage = 1;
    });
    _loadItems();
  }

  void _onConditionChanged(String? condition) {
    if (condition == null) return;
    setState(() {
      _selectedCondition = condition;
      _currentPage = 1;
    });
    _loadItems();
  }

  void _goToPreviousPage() {
    if (_currentPage > 1) {
      setState(() {
        _currentPage--;
      });
      _loadItems();
    }
  }

  void _goToNextPage(int totalItems) {
    final totalPages = (totalItems + _pageSize - 1) ~/ _pageSize;
    if (_currentPage < totalPages) {
      setState(() {
        _currentPage++;
      });
      _loadItems();
    }
  }

  void _changePageSize(int newSize) {
    setState(() {
      _pageSize = newSize;
      _currentPage = 1;
    });
    _loadItems();
  }

  void _selectItem(Item item) {
    Navigator.of(context).pop(item);
  }

  @override
  Widget build(BuildContext context) {
    final items = _filteredItems;
    final totalItems = items.length;
    final totalPages = (totalItems + _pageSize - 1) ~/ _pageSize;
    final startIndex = (_currentPage - 1) * _pageSize;
    final endIndex = (startIndex + _pageSize) > totalItems
        ? totalItems
        : startIndex + _pageSize;
    final pageItems = totalItems == 0
        ? <Item>[]
        : items.sublist(startIndex, endIndex);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Select Item'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            tooltip: 'View Stocks',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const StockViewScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: EdgeInsets.all(widget.isMobile ? 12 : 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header info
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Theme.of(context).colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Select an item from the inventory below',
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.8),
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Search
                    TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText: 'Search by name, serial, or ID...',
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

                    // Category filter
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: InputDecoration(
                        labelText: 'Filter by category',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: 'All',
                          child: Text('All'),
                        ),
                        ...ItemCategory.values.map(
                          (cat) => DropdownMenuItem(
                            value: cat.displayName,
                            child: Text(cat.displayName),
                          ),
                        ),
                      ],
                      onChanged: _onCategoryChanged,
                    ),
                    const SizedBox(height: 12),

                    // Condition filter
                    DropdownButtonFormField<String>(
                      value: _selectedCondition,
                      decoration: InputDecoration(
                        labelText: 'Filter by condition',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'All', child: Text('All')),
                        DropdownMenuItem(value: 'New', child: Text('New')),
                        DropdownMenuItem(value: 'Good', child: Text('Good')),
                        DropdownMenuItem(
                          value: 'Defective',
                          child: Text('Defective'),
                        ),
                        DropdownMenuItem(
                          value: 'Refurbished',
                          child: Text('Refurbished'),
                        ),
                        DropdownMenuItem(
                          value: 'Need Repair',
                          child: Text('Need Repair'),
                        ),
                      ],
                      onChanged: _onConditionChanged,
                    ),

                    SizedBox(height: widget.isMobile ? 16 : 20),

                    if (totalItems == 0)
                      Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 64,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.4),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _searchQuery.isNotEmpty ||
                                      _selectedCategory != 'All' ||
                                      _selectedCondition != 'All'
                                  ? 'No items match your filters'
                                  : 'No items found',
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                            if (_searchQuery.isNotEmpty ||
                                _selectedCategory != 'All' ||
                                _selectedCondition != 'All')
                              TextButton(
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                    _selectedCategory = 'All';
                                    _selectedCondition = 'All';
                                    _currentPage = 1;
                                  });
                                  _loadItems();
                                },
                                child: const Text('Clear filters'),
                              ),
                          ],
                        ),
                      )
                    else ...[
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
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemBuilder: (context, index) {
                          final item = pageItems[index];
                          return _buildItemTile(context, item);
                        },
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemCount: pageItems.length,
                      ),

                      const SizedBox(height: 12),

                      // Pagination controls
                      Row(
                        children: [
                          OutlinedButton.icon(
                            onPressed: _currentPage > 1
                                ? _goToPreviousPage
                                : null,
                            icon: const Icon(Icons.chevron_left),
                            label: const Text('Prev'),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: _currentPage < totalPages
                                ? () => _goToNextPage(totalItems)
                                : null,
                            icon: const Icon(Icons.chevron_right),
                            label: const Text('Next'),
                          ),
                          const Spacer(),
                          Text('Page $_currentPage of $totalPages'),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
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

  Widget _buildItemTile(BuildContext context, Item item) {
    return Container(
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
            Icons.inventory_2,
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
              'ID: ${item.id}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _getConditionColor(item.condition).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getConditionColor(
                        item.condition,
                      ).withOpacity(0.3),
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
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.secondary.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    item.category.displayName,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.secondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _selectItem(item),
      ),
    );
  }
}
