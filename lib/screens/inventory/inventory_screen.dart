import 'package:flutter/material.dart';
import '../screens.dart';
import '../../services/inventory_service.dart';
import '../../models/entities/item.dart';
import 'add_item_screen.dart';
import '../../widgets/skeleton.dart';
import '../../utils/snackbar_helper.dart';

class InventoryScreen extends StatefulWidget {
  final bool isMobile;

  const InventoryScreen({super.key, required this.isMobile});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = 'All';
  final InventoryService _inventoryService = InventoryService();
  bool _isLoading = true;
  Map<String, Map<String, int>> _categoryCounts = {};

  @override
  void initState() {
    super.initState();
    _initializeAndLoadData();
  }

  Future<void> _initializeAndLoadData() async {
    try {
      await _inventoryService.initialize();
      await _loadData();
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showErrorSnackBar(context, 'Error initializing service: $e');
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData({bool useSkeleton = true}) async {
    if (useSkeleton) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      // Only get category stats - this already fetches all items internally
      _categoryCounts = await _inventoryService.getCategoryStats();
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showErrorSnackBar(context, 'Error loading data: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshData() async {
    await _loadData(useSkeleton: false);
  }

  void _navigateToAddItem() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddItemScreen(isMobile: widget.isMobile),
      ),
    );

    if (result == true) {
      // Item was added successfully, refresh the data
      _refreshData();
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  void _onStatusChanged(String? status) {
    if (status == null) return;
    setState(() {
      _statusFilter = status;
    });
  }

  // Calculate dynamic counts from category data
  int get _totalItems {
    return _allCategories.fold(
      0,
      (sum, category) => sum + (category['total'] as int),
    );
  }

  int get _totalCategories {
    return _allCategories.length;
  }

  int get _availableItems {
    return _allCategories.fold(0, (sum, category) {
      final total = category['total'] as int;
      final borrowed = category['borrowed'] as int;
      return sum + (total - borrowed);
    });
  }

  int get _inUseItems {
    return _allCategories.fold(
      0,
      (sum, category) => sum + (category['borrowed'] as int),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.all(widget.isMobile ? 16 : 20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                icon,
                color: Theme.of(context).colorScheme.primary,
                size: widget.isMobile ? 28 : 24,
              ),
            ],
          ),
          SizedBox(height: widget.isMobile ? 12 : 16),
          Text(
            value,
            style: TextStyle(
              fontSize: widget.isMobile ? 32 : 28,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: widget.isMobile ? 16 : 14,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    String title,
    String count,
    Color color,
    IconData icon,
  ) {
    return InkWell(
      onTap: () async {
        final result = await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                CategoryItemsScreen(category: title, isMobile: widget.isMobile),
          ),
        );

        if (result == true) {
          // Items were modified, refresh the data
          _refreshData();
        }
      },
      child: Container(
        padding: EdgeInsets.all(widget.isMobile ? 16 : 20),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  count,
                  style: TextStyle(
                    fontSize: widget.isMobile ? 24 : 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: widget.isMobile ? 14 : 12,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Data and filtering for categories
  List<Map<String, Object>> get _allCategories {
    final realCounts = _categoryCounts;
    return ItemCategory.values.map((category) {
      final categoryName = category.displayName;
      return {
        'name': categoryName,
        'total': realCounts[categoryName]?['total'] ?? 0,
        'borrowed': realCounts[categoryName]?['borrowed'] ?? 0,
        'color': _getCategoryColor(category),
        'icon': _getCategoryIcon(category),
      };
    }).toList();
  }

  Color _getCategoryColor(ItemCategory category) {
    switch (category) {
      case ItemCategory.Electronics:
        return const Color(0xFF06B6D4);
      case ItemCategory.Keys:
        return const Color(0xFFF59E0B);
      case ItemCategory.MediaEquipment:
        return const Color(0xFFEC4899);
      case ItemCategory.Tools:
        return const Color(0xFF8B5CF6);
      case ItemCategory.Miscellaneous:
        return const Color(0xFF6B7280);
    }
  }

  IconData _getCategoryIcon(ItemCategory category) {
    switch (category) {
      case ItemCategory.Electronics:
        return Icons.devices;
      case ItemCategory.Keys:
        return Icons.vpn_key;
      case ItemCategory.MediaEquipment:
        return Icons.monitor;
      case ItemCategory.Tools:
        return Icons.build;
      case ItemCategory.Miscellaneous:
        return Icons.category;
    }
  }

  List<Map<String, Object>> get _filteredCategories {
    final lower = _searchQuery.toLowerCase();
    return _allCategories
        .where((cat) {
          final name = (cat['name'] as String).toLowerCase();
          final total = cat['total'] as int;
          final borrowed = cat['borrowed'] as int;
          final available = total - borrowed;

          bool statusOk = true;
          if (_statusFilter == 'Available') {
            statusOk = available > 0;
          } else if (_statusFilter == 'Borrowed') {
            statusOk = borrowed > 0;
          }

          return name.contains(lower) && statusOk;
        })
        .map((cat) {
          final total = cat['total'] as int;
          final borrowed = cat['borrowed'] as int;
          final available = total - borrowed;
          final displayCount = _statusFilter == 'Borrowed'
              ? borrowed
              : _statusFilter == 'Available'
              ? available
              : total;
          return {...cat, 'displayCount': displayCount};
        })
        .toList();
  }

  Widget _buildSearchAndFilterSection() {
    return Padding(
      padding: EdgeInsets.only(top: widget.isMobile ? 12 : 16),
      child: widget.isMobile
          ? Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search categories...',
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
                DropdownButtonFormField<String>(
                  value: _statusFilter,
                  decoration: InputDecoration(
                    labelText: 'Filter by status',
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
                    DropdownMenuItem(
                      value: 'Available',
                      child: Text('Available'),
                    ),
                    DropdownMenuItem(
                      value: 'Borrowed',
                      child: Text('Borrowed'),
                    ),
                  ],
                  onChanged: _onStatusChanged,
                ),
              ],
            )
          : Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Search categories...',
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
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _statusFilter,
                    decoration: InputDecoration(
                      labelText: 'Filter by status',
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
                      DropdownMenuItem(
                        value: 'Available',
                        child: Text('Available'),
                      ),
                      DropdownMenuItem(
                        value: 'Borrowed',
                        child: Text('Borrowed'),
                      ),
                    ],
                    onChanged: _onStatusChanged,
                  ),
                ),
              ],
            ),
    );
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshData,
          child: _isLoading
              ? InventorySkeleton(isMobile: widget.isMobile)
              : SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.all(widget.isMobile ? 16 : 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Center(
                        child: Text(
                          'INVENTORY',
                          style: TextStyle(
                            fontSize: widget.isMobile ? 24 : 28,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                      SizedBox(height: widget.isMobile ? 24 : 32),
                      // Top Summary Cards
                      if (widget.isMobile)
                        Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _buildSummaryCard(
                                    'Total Items',
                                    _totalItems.toString(),
                                    Icons.inventory,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildSummaryCard(
                                    'Categories',
                                    _totalCategories.toString(),
                                    Icons.category,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildSummaryCard(
                                    'Available',
                                    _availableItems.toString(),
                                    Icons.check_circle,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildSummaryCard(
                                    'In Use',
                                    _inUseItems.toString(),
                                    Icons.access_time,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        )
                      else
                        Row(
                          children: [
                            Expanded(
                              child: _buildSummaryCard(
                                'Total Items',
                                _totalItems.toString(),
                                Icons.inventory,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildSummaryCard(
                                'Categories',
                                _totalCategories.toString(),
                                Icons.category,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildSummaryCard(
                                'Available',
                                _availableItems.toString(),
                                Icons.check_circle,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildSummaryCard(
                                'In Use',
                                _inUseItems.toString(),
                                Icons.access_time,
                              ),
                            ),
                          ],
                        ),
                      // Search and Filter section
                      _buildSearchAndFilterSection(),
                      SizedBox(height: widget.isMobile ? 24 : 32),
                      // Categories Grid
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: widget.isMobile ? 2 : 4,
                          childAspectRatio: widget.isMobile ? 1.2 : 1.5,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: _filteredCategories.length,
                        itemBuilder: (context, index) {
                          final category = _filteredCategories[index];
                          return _buildCategoryCard(
                            context,
                            category['name'] as String,
                            (category['displayCount']).toString(),
                            category['color'] as Color,
                            category['icon'] as IconData,
                          );
                        },
                      ),
                    ],
                  ),
                ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddItem,
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
