import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ExportItemConfigurationDialog extends StatefulWidget {
  final int totalItemsCount;
  final int filteredItemsCount;
  final List<String> availableColumns;
  final Function(List<String> selectedColumns, ExportItemScope scope, int? customCount, String fileName) onExport;

  const ExportItemConfigurationDialog({
    super.key,
    required this.totalItemsCount,
    required this.filteredItemsCount,
    required this.availableColumns,
    required this.onExport,
  });

  @override
  State<ExportItemConfigurationDialog> createState() => _ExportItemConfigurationDialogState();
}

enum ExportItemScope { all, filtered, custom }

class _ExportItemConfigurationDialogState extends State<ExportItemConfigurationDialog> {
  late List<String> _selectedColumns;
  ExportItemScope _selectedScope = ExportItemScope.all;
  final TextEditingController _countController = TextEditingController();
  final TextEditingController _fileNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedColumns = List.from(widget.availableColumns);
    _countController.text = '10'; // Default custom count
    _fileNameController.text = 'items_export_${DateTime.now().millisecondsSinceEpoch}';
  }

  @override
  void dispose() {
    _countController.dispose();
    _fileNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Export Configuration'),
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('File Name'),
          const SizedBox(height: 8),
          TextField(
            controller: _fileNameController,
            decoration: const InputDecoration(
              hintText: 'Enter file name',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              suffixText: '.xlsx',
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Select Columns'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8.0,
            runSpacing: 4.0,
            children: widget.availableColumns.map((column) {
              return FilterChip(
                label: Text(column),
                selected: _selectedColumns.contains(column),
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedColumns.add(column);
                    } else {
                      _selectedColumns.remove(column);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Number of Records'),
          const SizedBox(height: 8),
          _buildRadioOption(
            ExportItemScope.all,
            'All Items (${widget.totalItemsCount})',
          ),
          _buildRadioOption(
            ExportItemScope.filtered,
            'Current Filtered View (${widget.filteredItemsCount})',
          ),
          Row(
            children: [
              Expanded(
                child: _buildRadioOption(
                  ExportItemScope.custom,
                  'Custom Count',
                ),
              ),
              if (_selectedScope == ExportItemScope.custom)
                SizedBox(
                  width: 80,
                  child: TextField(
                    controller: _countController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _selectedColumns.isEmpty
              ? null
              : () {
                  int? customCount;
                  if (_selectedScope == ExportItemScope.custom) {
                    customCount = int.tryParse(_countController.text);
                    if (customCount == null || customCount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a valid number')),
                      );
                      return;
                    }
                  }
                  widget.onExport(
                    _selectedColumns,
                    _selectedScope,
                    customCount,
                    _fileNameController.text.trim().isEmpty
                        ? 'items_export_${DateTime.now().millisecondsSinceEpoch}'
                        : _fileNameController.text.trim(),
                  );
                  Navigator.pop(context);
                },
          child: const Text('Export'),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
    );
  }

  Widget _buildRadioOption(ExportItemScope value, String label) {
    return RadioListTile<ExportItemScope>(
      title: Text(label),
      value: value,
      groupValue: _selectedScope,
      contentPadding: EdgeInsets.zero,
      dense: true,
      onChanged: (ExportItemScope? newValue) {
        if (newValue != null) {
          setState(() {
            _selectedScope = newValue;
          });
        }
      },
    );
  }
}
