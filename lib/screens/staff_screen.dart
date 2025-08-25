import 'package:flutter/material.dart';

class StaffScreen extends StatefulWidget {
  const StaffScreen({super.key, this.isMobile = false});

  final bool isMobile;

  @override
  State<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> {
  final List<Map<String, dynamic>> _staffList = [
    {'id': 1, 'name': 'Marc Ejay Cortes', 'role': 'Intern'},
    {'id': 2, 'name': 'Stanleigh Morales', 'role': 'Irregular'},
    {'id': 3, 'name': 'Christian Dave Alicaba', 'role': 'Intern'},
    {'id': 4, 'name': 'Daryl Agustine Sedillo', 'role': 'Irregular'},
  ];

  @override
  Widget build(BuildContext context) {
    final bool isMobile = widget.isMobile;
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Center(
            child: Text(
              'Staff',
              style: TextStyle(
                fontSize: isMobile ? 24 : 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _onAddStaff,
              child: const Text('[New Staff]'),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(isMobile ? 16 : 12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: isMobile ? 8 : 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  color: Colors.grey.shade50,
                  child: Row(
                    children: const [
                      Expanded(
                        flex: 1,
                        child: Text(
                          'ID',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Expanded(
                        flex: 4,
                        child: Text(
                          'Name',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          'Role',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      SizedBox(
                        width: 160,
                        child: Text(
                          'Action',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                ..._staffList.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final staff = entry.value;
                  return Container(
                    color: idx.isEven ? Colors.white : Colors.grey.shade50,
                    child: Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text('${staff['id']}'),
                          ),
                        ),
                        Expanded(
                          flex: 4,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              '${staff['name']}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              '${staff['role']}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 160,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Row(
                              children: [
                                TextButton(
                                  onPressed: () => _onViewStaff(staff),
                                  child: const Text('[View]'),
                                ),
                                TextButton(
                                  onPressed: () => _onEditStaff(staff),
                                  child: const Text('[Edit]'),
                                ),
                                TextButton(
                                  onPressed: () => _onRemoveStaff(staff),
                                  child: const Text('[Remove]'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          if (isMobile) const SizedBox(height: 80),
        ],
      ),
    );
  }

  void _onAddStaff() {
    _showStaffFormDialog(
      title: 'New Staff',
      onSubmit: (name, role) {
        setState(() {
          final newId =
              (_staffList.isNotEmpty ? _staffList.last['id'] as int : 0) + 1;
          _staffList.add({'id': newId, 'name': name, 'role': role});
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Staff added successfully.')),
        );
      },
    );
  }

  void _onViewStaff(Map<String, dynamic> staff) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Staff Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('ID', '${staff['id']}'),
            _buildDetailRow('Name', '${staff['name']}'),
            _buildDetailRow('Role', '${staff['role']}'),
          ],
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

  void _onEditStaff(Map<String, dynamic> staff) {
    _showStaffFormDialog(
      title: 'Edit Staff',
      initialName: staff['name'] as String,
      initialRole: staff['role'] as String,
      onSubmit: (name, role) {
        setState(() {
          staff['name'] = name;
          staff['role'] = role;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Staff updated.')));
      },
    );
  }

  void _onRemoveStaff(Map<String, dynamic> staff) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Staff'),
        content: Text('Remove "${staff['name']}" from staff list?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _staffList.remove(staff);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Staff removed.')));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _showStaffFormDialog({
    required String title,
    String? initialName,
    String? initialRole,
    required void Function(String name, String role) onSubmit,
  }) {
    final nameController = TextEditingController(text: initialName ?? '');
    final roleController = TextEditingController(text: initialRole ?? '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: roleController,
                decoration: const InputDecoration(labelText: 'Role'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              final role = roleController.text.trim();
              if (name.isEmpty || role.isEmpty) return;
              Navigator.pop(context);
              onSubmit(name, role);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: color ?? Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

