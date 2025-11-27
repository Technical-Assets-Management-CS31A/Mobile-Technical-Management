import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:typed_data';
import '../screens.dart';
import '../../services/inventory_service.dart';
import '../../models/entities/item.dart';
import 'add_item_screen.dart';
import '../../widgets/skeleton.dart';
import '../../utils/snackbar_helper.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart';
import '../../services/lend_service.dart';
import '../../widgets/export_item_configuration_dialog.dart';
import '../../utils/pdf_generator.dart';

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
  final LendService _lendService = LendService();
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
    await _loadData(useSkeleton: true);
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

  Future<void> _importItems() async {
    try {
      FilePickerResult? result;
      try {
        result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['xlsx'],
          withData: true,
        );
      } catch (e) {
        // Check if it's the specific LateInitializationError from FilePicker
        if (e.toString().contains('LateInitializationError')) {
          throw Exception('FilePicker initialization failed. Please restart the app.');
        }
        rethrow;
      }

      if (result != null) {
        if (mounted) {
          setState(() {
            _isLoading = true;
          });
        }

        final fileName = result.files.single.name;
        List<int>? fileBytes = result.files.single.bytes;

        // If bytes are null (e.g. on desktop sometimes), try reading from path
        if (fileBytes == null && result.files.single.path != null) {
          final file = File(result.files.single.path!);
          fileBytes = await file.readAsBytes();
        }

        if (fileBytes != null) {
          try {
            final response = await _inventoryService.importItems(
              fileBytes,
              fileName,
            );

            if (mounted) {
              _handleImportResponse(response);
            }
          } catch (e) {
            throw Exception('Service import failed: $e');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showErrorSnackBar(context, 'Import failed: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _refreshData();
      }
    }
  }

  void _handleImportResponse(Map<String, dynamic> response) {
    final success = response['success'] == true;
    final message = response['message'] as String? ?? 'Import processed';

    if (success) {
      final data = response['data'] as Map<String, dynamic>?;
      final failureCount = data?['failureCount'] as int? ?? 0;
      final errors = data?['errors'] as List<dynamic>? ?? [];
      final skippedDuplicates =
          data?['skippedDuplicates'] as List<dynamic>? ?? [];

      if (failureCount > 0 ||
          errors.isNotEmpty ||
          skippedDuplicates.isNotEmpty) {
        SnackbarHelper.showWarningSnackBar(context, message);
        _showImportErrorsDialog(message, errors, skippedDuplicates);
      } else {
        SnackbarHelper.showSuccessSnackBar(context, message);
      }
    } else {
      final errors = response['errors'] as List<dynamic>? ?? [];
      SnackbarHelper.showErrorSnackBar(context, message);
      if (errors.isNotEmpty) {
        _showImportErrorsDialog(message, errors, []);
      }
    }
  }

  void _showImportErrorsDialog(
    String title,
    List<dynamic> errors,
    List<dynamic> skippedDuplicates,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Import Results'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title),
                  const SizedBox(height: 10),
                  if (errors.isNotEmpty) ...[
                    const Text(
                      'Errors:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 5),
                    ...errors.map(
                      (e) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '• $e',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (skippedDuplicates.isNotEmpty) ...[
                    const Text(
                      'Skipped Duplicates:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(height: 5),
                    ...skippedDuplicates.map(
                      (e) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '• $e',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  Future<void> _exportItems() async {
    // Calculate counts for the dialog
    final totalCount = _totalItems;
    final filteredCount = _filteredCategories.fold(
      0,
      (sum, cat) => sum + (cat['displayCount'] as int),
    );

    showDialog(
      context: context,
      builder:
          (context) => ExportItemConfigurationDialog(
            totalItemsCount: totalCount,
            filteredItemsCount: filteredCount,
            availableColumns: const [
              'Item Name',
              'Serial Number',
              'Type',
              'Make',
              'Model',
              'Category',
              'Condition',
              'Status',
              'Date Added',
              'Description',
            ],
            onExport: (selectedColumns, scope, customCount, fileName) {
              _processExport(selectedColumns, scope, customCount, fileName);
            },
          ),
    );
  }

  Future<void> _downloadBarcodes() async {
    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
        });
      }

      // Fetch all items
      final items = await _inventoryService.getAllItems(pageSize: 10000);
      
      if (items.isEmpty) {
        if (mounted) {
          SnackbarHelper.showWarningSnackBar(context, 'No items found to generate barcodes');
        }
        return;
      }

      await PdfGenerator.generateBarcodePdf(items);

    } catch (e) {
      if (mounted) {
        SnackbarHelper.showErrorSnackBar(context, 'Failed to generate PDF: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _processExport(
    List<String> selectedColumns,
    ExportItemScope scope,
    int? customCount,
    String fileName,
  ) async {
    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
        });
      }

      // 1. Fetch all data needed
      final items = await _inventoryService.getAllItems(pageSize: 10000);
      final lentItems = await _lendService.getAllLentItems(pageSize: 10000);

      // 2. Determine status for each item
      // Create a set of borrowed item IDs
      final borrowedItemIds =
          lentItems
              .where(
                (l) =>
                    l.returnedAt == null &&
                    (l.status == 'Borrowed' || l.status == 'Active'),
              )
              .map((l) => l.itemId)
              .toSet();

      // 3. Filter items based on scope
      List<Item> itemsToExport = items;

      if (scope == ExportItemScope.filtered) {
        // Apply current filters (Category search and Status filter)
        final lowerQuery = _searchQuery.toLowerCase();
        itemsToExport =
            items.where((item) {
              final categoryName = item.category.displayName;
              final matchesCategory = categoryName.toLowerCase().contains(
                lowerQuery,
              );

              final isBorrowed = borrowedItemIds.contains(item.id);
              bool matchesStatus = true;
              if (_statusFilter == 'Available') {
                matchesStatus = !isBorrowed;
              } else if (_statusFilter == 'Borrowed') {
                matchesStatus = isBorrowed;
              }

              return matchesCategory && matchesStatus;
            }).toList();
      }

      // Apply custom count limit if applicable
      if (scope == ExportItemScope.custom && customCount != null) {
        if (itemsToExport.length > customCount) {
          itemsToExport = itemsToExport.take(customCount).toList();
        }
      }

      // 4. Generate Excel
      var excel = Excel.createExcel();
      Sheet sheetObject = excel['Sheet1'];

      // Add Header Row
      sheetObject.appendRow(
        selectedColumns.map((c) => TextCellValue(c)).toList(),
      );

      // Add Data Rows
      for (var item in itemsToExport) {
        final isBorrowed = borrowedItemIds.contains(item.id);
        final status = isBorrowed ? 'Borrowed' : 'Available';

        List<CellValue> row = [];
        for (var column in selectedColumns) {
          switch (column) {
            case 'Item Name':
              row.add(TextCellValue(item.itemName));
              break;
            case 'Serial Number':
              row.add(TextCellValue(item.serialNumber));
              break;
            case 'Type':
              row.add(TextCellValue(item.itemType));
              break;
            case 'Make':
              row.add(TextCellValue(item.itemMake));
              break;
            case 'Model':
              row.add(TextCellValue(item.itemModel ?? ''));
              break;
            case 'Category':
              row.add(TextCellValue(item.category.displayName));
              break;
            case 'Condition':
              row.add(TextCellValue(item.condition.displayName));
              break;
            case 'Status':
              row.add(TextCellValue(status));
              break;
            case 'Date Added':
              row.add(TextCellValue(item.createdAt.toString().split(' ')[0]));
              break;
            case 'Description':
              row.add(TextCellValue(item.description ?? ''));
              break;
            default:
              row.add(TextCellValue(''));
          }
        }
        sheetObject.appendRow(row);
      }

      // 5. Save File
      final fileBytes = excel.save();

      if (fileBytes != null) {
        final Uint8List bytes = Uint8List.fromList(fileBytes);

        String? outputFile = await FilePicker.platform.saveFile(
          dialogTitle: 'Please select an output file:',
          fileName: fileName.endsWith('.xlsx') ? fileName : '$fileName.xlsx',
          allowedExtensions: ['xlsx'],
          type: FileType.custom,
          bytes: bytes,
        );

        if (outputFile != null) {
          final file = File(outputFile);
          await file.writeAsBytes(bytes);
          if (mounted) {
            SnackbarHelper.showSuccessSnackBar(
              context,
              'Exported ${itemsToExport.length} items successfully',
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showErrorSnackBar(context, 'Export failed: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _importItems,
                        icon: const Icon(Icons.file_upload_outlined),
                        label: const Text('Import'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          foregroundColor: Theme.of(context).colorScheme.primary,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _exportItems,
                        icon: const Icon(Icons.file_download_outlined),
                        label: const Text('Export'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          foregroundColor: Theme.of(context).colorScheme.primary,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _downloadBarcodes,
                        icon: const Icon(Icons.qr_code),
                        label: const Text('Barcodes'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          foregroundColor: Theme.of(context).colorScheme.primary,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
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
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _importItems,
                  icon: const Icon(Icons.file_upload_outlined),
                  label: const Text('Import'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    foregroundColor: Theme.of(context).colorScheme.primary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _exportItems,
                  icon: const Icon(Icons.file_download_outlined),
                  label: const Text('Export'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    foregroundColor: Theme.of(context).colorScheme.primary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _downloadBarcodes,
                  icon: const Icon(Icons.qr_code),
                  label: const Text('Barcodes'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    foregroundColor: Theme.of(context).colorScheme.primary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                      ),
                    ),
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
