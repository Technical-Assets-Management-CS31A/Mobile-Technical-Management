import 'package:flutter/material.dart';
import '../../models/entities/item.dart';
import '../../services/inventory_service.dart';
import 'item_detail_screen.dart';
import 'add_item_screen.dart';

class CategoryItemsScreen extends StatefulWidget {
  final String category;
  final bool isMobile;

  const CategoryItemsScreen({
    super.key,
    required this.category,
    required this.isMobile,
  });

  @override
  State<CategoryItemsScreen> createState() => _CategoryItemsScreenState();
}

class _CategoryItemsScreenState extends State<CategoryItemsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCondition = 'All';

  final List<int> _pageSizeOptions = [5, 10, 20, 50];
  int _pageSize = 10;
  int _currentPage = 1;

  final InventoryService _inventoryService = InventoryService();
  List<Item> _items = [];
  bool _isLoading = true;
  bool _itemsModified = false;

  @override
  void initState() {
    super.initState();
    _loadItems();
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
      final items = await _inventoryService.getItemsByCategory(widget.category);
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
          item.serialNumber.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesCondition = _selectedCondition == 'All'
          ? true
          : (_selectedCondition == 'In Use'
                ? item.condition.toLowerCase() == 'in use'
                : item.condition.toLowerCase() ==
                      _selectedCondition.toLowerCase());

      return matchesSearch && matchesCondition;
    }).toList();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _currentPage = 1;
    });
  }

  void _onConditionChanged(String? condition) {
    if (condition == null) return;
    setState(() {
      _selectedCondition = condition;
      _currentPage = 1;
    });
  }

  void _goToPreviousPage() {
    if (_currentPage > 1) {
      setState(() {
        _currentPage--;
      });
    }
  }

  void _goToNextPage(int totalItems) {
    final totalPages = (totalItems + _pageSize - 1) ~/ _pageSize;
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

  void _addNewItem() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddItemScreen(isMobile: widget.isMobile),
      ),
    );

    if (result == true) {
      // Item was added successfully, refresh the data
      _itemsModified = true;
      _loadItems();
    }
  }

  void _navigateToItemDetail(Item item) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => ItemDetailScreen(item: item)),
    );

    if (result == true) {
      // Item was updated or deleted, refresh the data
      _itemsModified = true;
      _loadItems();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          title: Text(widget.category),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

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

    return WillPopScope(
      onWillPop: () async {
        // Return the modification status when the screen is popped
        Navigator.of(context).pop(_itemsModified);
        return false; // Prevent default back behavior
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          title: Text(widget.category),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _addNewItem,
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: const Icon(Icons.add, color: Colors.white),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(widget.isMobile ? 12 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search
                TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search by name or serial...',
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

                // Condition filter (includes 'In Use')
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
                    DropdownMenuItem(value: 'Good', child: Text('Good')),
                    DropdownMenuItem(value: 'Fair', child: Text('Fair')),
                    DropdownMenuItem(value: 'In Use', child: Text('In Use')),
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
                          _searchQuery.isNotEmpty || _selectedCondition != 'All'
                              ? 'No items match your filters'
                              : 'No items in this category',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        if (_searchQuery.isNotEmpty ||
                            _selectedCondition != 'All')
                          TextButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                                _selectedCondition = 'All';
                                _currentPage = 1;
                              });
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
                        style: TextStyle(color: Colors.grey[700]),
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
                      Text('Page $_currentPage of $totalPages'),
                      const Spacer(),
                      OutlinedButton.icon(
                        onPressed: _currentPage > 1 ? _goToPreviousPage : null,
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
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
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
        subtitle: Text(
          'SN: ${item.serialNumber} • Condition: ${item.condition}',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _navigateToItemDetail(item),
      ),
    );
  }
}
