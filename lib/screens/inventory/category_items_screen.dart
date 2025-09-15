import 'package:flutter/material.dart';
import '../../models/responses/item_list_response.dart';

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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ItemList> get _allItemsForCategory {
    return _mockItems()
        .where(
          (item) =>
              item.itemCategory.toLowerCase() == widget.category.toLowerCase(),
        )
        .toList();
  }

  List<ItemList> get _filteredItems {
    final items = _allItemsForCategory.where((item) {
      final matchesSearch =
          item.itemName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.itemSerialNumber.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );

      final matchesCondition = _selectedCondition == 'All'
          ? true
          : (_selectedCondition == 'In Use'
                ? item.itemCondition.toLowerCase() == 'in use'
                : item.itemCondition.toLowerCase() ==
                      _selectedCondition.toLowerCase());

      return matchesSearch && matchesCondition;
    }).toList();

    return items;
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

  void _addNewItem() {
    // TODO: Replace with real add item flow
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Add Item tapped')));
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
        ? <ItemList>[]
        : items.sublist(startIndex, endIndex);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(widget.category),
        backgroundColor: const Color(0xFF338AFF),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewItem,
        backgroundColor: const Color(0xFF338AFF),
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
                  fillColor: Colors.white,
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
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _searchQuery.isNotEmpty || _selectedCondition != 'All'
                            ? 'No items match your filters'
                            : 'No items in this category',
                        style: TextStyle(color: Colors.grey[700]),
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
                      'Showing ${startIndex + 1}-${endIndex} of $totalItems',
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
    );
  }

  Widget _buildItemTile(BuildContext context, ItemList item) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF338AFF).withOpacity(0.1),
          child: const Icon(Icons.inventory_2, color: Color(0xFF338AFF)),
        ),
        title: Text(
          item.itemName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          'SN: ${item.itemSerialNumber} • Condition: ${item.itemCondition}',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          // TODO: integrate with ItemDetailScreen when API wiring is ready
        },
      ),
    );
  }

  List<ItemList> _mockItems() {
    return [
      ItemList(
        itemImage: '',
        itemSerialNumber: 'CBL-001',
        itemName: 'HDMI Cable 1m',
        itemCategory: 'Cables',
        itemCondition: 'Good',
      ),
      ItemList(
        itemImage: '',
        itemSerialNumber: 'CBL-002',
        itemName: 'USB-C Cable 2m',
        itemCategory: 'Cables',
        itemCondition: 'In Use',
      ),
      ItemList(
        itemImage: '',
        itemSerialNumber: 'ADP-010',
        itemName: 'USB-C to HDMI Adapter',
        itemCategory: 'Adapters',
        itemCondition: 'Fair',
      ),
      ItemList(
        itemImage: '',
        itemSerialNumber: 'PRP-007',
        itemName: 'Wireless Mouse',
        itemCategory: 'Peripherals',
        itemCondition: 'Good',
      ),
    ];
  }
}
