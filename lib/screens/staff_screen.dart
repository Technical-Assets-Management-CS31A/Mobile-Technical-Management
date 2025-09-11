import 'package:flutter/material.dart';

class Staff {
  final String id;
  final String name;
  final String position;
  final String email;

  Staff({
    required this.id,
    required this.name,
    required this.position,
    required this.email,
  });

  Staff copyWith({
    String? id,
    String? name,
    String? position,
    String? email,
  }) {
    return Staff(
      id: id ?? this.id,
      name: name ?? this.name,
      position: position ?? this.position,
      email: email ?? this.email,
    );
  }
}

class StaffScreen extends StatefulWidget {
  const StaffScreen({super.key, this.isMobile = false});

  final bool isMobile;

  @override
  State<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> {
  // Dummy data for demonstration
  final List<Staff> _staffList = [
    Staff(id: '1', name: 'Neg Calculator', position: 'Manager', email: 'Neg@example.com'),
    Staff(id: '2', name: 'Uzziah Smith', position: 'Developer', email: 'Uzziah@example.com'),
  ];

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _positionController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _positionController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _addNewStaff() {
    _nameController.clear();
    _positionController.clear();
    _emailController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Staff'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'Enter name',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _positionController,
                decoration: const InputDecoration(
                  labelText: 'Position',
                  hintText: 'Enter position',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a position';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'Enter email',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an email';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                setState(() {
                  _staffList.add(
                    Staff(
                      id: (_staffList.length + 1).toString(),
                      name: _nameController.text,
                      position: _positionController.text,
                      email: _emailController.text,
                    ),
                  );
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _viewStaff(Staff staff) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Staff Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: ${staff.name}'),
            const SizedBox(height: 8),
            Text('Position: ${staff.position}'),
            const SizedBox(height: 8),
            Text('Email: ${staff.email}'),
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

  void _editStaff(Staff staff) {
    _nameController.text = staff.name;
    _positionController.text = staff.position;
    _emailController.text = staff.email;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Staff'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _positionController,
                decoration: const InputDecoration(labelText: 'Position'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a position';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an email';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                setState(() {
                  final index = _staffList.indexWhere((element) => element.id == staff.id);
                  if (index != -1) {
                    _staffList[index] = Staff(
                      id: staff.id,
                      name: _nameController.text,
                      position: _positionController.text,
                      email: _emailController.text,
                    );
                  }
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _deleteStaff(Staff staff) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Staff'),
        content: Text('Are you sure you want to delete ${staff.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _staffList.removeWhere((element) => element.id == staff.id);
              });
              Navigator.pop(context);
            },
            child: const Text('Delete'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Management'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewStaff,
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Name')),
              DataColumn(label: Text('Position')),
              DataColumn(label: Text('Email')),
              DataColumn(label: Text('Actions')),
            ],
            rows: _staffList.map(
              (staff) => DataRow(
                cells: [
                  DataCell(Text(staff.name)),
                  DataCell(Text(staff.position)),
                  DataCell(Text(staff.email)),
                  DataCell(Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.visibility),
                        onPressed: () => _viewStaff(staff),
                        tooltip: 'View',
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _editStaff(staff),
                        tooltip: 'Edit',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _deleteStaff(staff),
                        tooltip: 'Delete',
                      ),
                    ],
                  )),
                ],
              ),
            ).toList(),
          ),
        ),
      ),
    );
  }
}