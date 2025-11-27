import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ExportConfigurationDialog extends StatefulWidget {
  final int totalUsersCount;
  final int filteredUsersCount;
  final List<String> availableColumns;
  final Function(List<String> selectedColumns, ExportScope scope, int? customCount) onExport;

  const ExportConfigurationDialog({
    super.key,
    required this.totalUsersCount,
    required this.filteredUsersCount,
    required this.availableColumns,
    required this.onExport,
  });

  @override
  State<ExportConfigurationDialog> createState() => _ExportConfigurationDialogState();
}

enum ExportScope { all, filtered, custom }

class _ExportConfigurationDialogState extends State<ExportConfigurationDialog> {
  late List<String> _selectedColumns;
  ExportScope _selectedScope = ExportScope.all;
  final TextEditingController _countController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedColumns = List.from(widget.availableColumns);
    _countController.text = '10'; // Default custom count
  }

  @override
  void dispose() {
    _countController.dispose();
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
            ExportScope.all,
            'All Users (${widget.totalUsersCount})',
          ),
          _buildRadioOption(
            ExportScope.filtered,
            'Current Filtered View (${widget.filteredUsersCount})',
          ),
          Row(
            children: [
              Expanded(
                child: _buildRadioOption(
                  ExportScope.custom,
                  'Custom Count',
                ),
              ),
              if (_selectedScope == ExportScope.custom)
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
                  if (_selectedScope == ExportScope.custom) {
                    customCount = int.tryParse(_countController.text);
                    if (customCount == null || customCount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a valid number')),
                      );
                      return;
                    }
                  }
                  widget.onExport(_selectedColumns, _selectedScope, customCount);
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

  Widget _buildRadioOption(ExportScope value, String label) {
    return RadioListTile<ExportScope>(
      title: Text(label),
      value: value,
      groupValue: _selectedScope,
      contentPadding: EdgeInsets.zero,
      dense: true,
      onChanged: (ExportScope? newValue) {
        if (newValue != null) {
          setState(() {
            _selectedScope = newValue;
          });
        }
      },
    );
  }
}
