import 'package:flutter/material.dart';
import '../../models/entities/staff.dart';

class StaffManagementScreen extends StatefulWidget {
  const StaffManagementScreen({super.key, this.isMobile = false});

  final bool isMobile;

  @override
  State<StaffManagementScreen> createState() => _StaffManagementScreenState();
}

class _StaffManagementScreenState extends State<StaffManagementScreen> {
  // Dummy data for demonstration
  final List<Staff> _staffList = [
    Staff(
      id: '1',
      name: 'Alice Johnson',
      position: 'Technical',
      email: 'alice@example.com',
      phoneNumber: '+1 (555) 123-4567',
      username: 'alice.johnson',
      password: 'password123',
      status: 'active',
    ),
    Staff(
      id: '2',
      name: 'Bob Martinez',
      position: 'Admin',
      email: 'bob@example.com',
      phoneNumber: '+1 (555) 234-5678',
      username: 'bob.martinez',
      password: 'password123',
      status: 'active',
    ),
    Staff(
      id: '3',
      name: 'Carla Reyes',
      position: 'Technical',
      email: 'carla@example.com',
      phoneNumber: '+1 (555) 345-6789',
      username: 'carla.reyes',
      password: 'password123',
      status: 'offline',
    ),
    Staff(
      id: '4',
      name: 'David Smith',
      position: 'Admin',
      email: 'david@example.com',
      phoneNumber: '+1 (555) 456-7890',
      username: 'david.smith',
      password: 'password123',
      status: 'active',
    ),
    Staff(
      id: '5',
      name: 'Eve Thompson',
      position: 'Technical',
      email: 'eve@example.com',
      phoneNumber: '+1 (555) 567-8901',
      username: 'eve.thompson',
      password: 'password123',
      status: 'active',
    ),
  ];

  List<Staff> _filteredStaffList = [];
  String _searchQuery = '';
  String _selectedFilter = 'All';
  int _currentPage = 1;
  final List<int> _pageSizeOptions = [5, 10, 20, 50];
  int _pageSize = 10;
  final List<String> _filterOptions = ['All', 'Technical', 'Admin'];

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _positionController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredStaffList = _staffList;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _positionController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _filterStaff() {
    setState(() {
      _filteredStaffList = _staffList.where((staff) {
        final matchesSearch =
            staff.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            staff.position.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            staff.email.toLowerCase().contains(_searchQuery.toLowerCase());

        final matchesFilter =
            _selectedFilter == 'All' || staff.position == _selectedFilter;

        return matchesSearch && matchesFilter;
      }).toList();
      _currentPage = 1;
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _filterStaff();
  }

  void _onFilterChanged(String filter) {
    setState(() {
      _selectedFilter = filter;
    });
    _filterStaff();
  }

  void _goToPreviousPage() {
    if (_currentPage > 1) {
      setState(() {
        _currentPage--;
      });
    }
  }

  void _goToNextPage() {
    final totalPages = (_filteredStaffList.length + _pageSize - 1) ~/ _pageSize;
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

  void _addNewStaff() {
    _nameController.clear();
    _positionController.clear();
    _emailController.clear();
    _phoneController.clear();
    _usernameController.clear();
    _passwordController.clear();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: widget.isMobile ? double.infinity : 500,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          padding: EdgeInsets.all(widget.isMobile ? 16 : 24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.person_add,
                        color: Color(0xFF10B981),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Add New Staff',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Form
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Name',
                          hintText: 'Enter full name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.person),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _positionController.text.isEmpty
                            ? null
                            : _positionController.text,
                        items: _filterOptions
                            .where((opt) => opt != 'All')
                            .map(
                              (opt) => DropdownMenuItem(
                                value: opt,
                                child: Text(opt),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            _positionController.text = val;
                          }
                        },
                        decoration: InputDecoration(
                          labelText: 'Position',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.work),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select a position';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          hintText: 'Enter email address',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.email),
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
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _phoneController,
                        decoration: InputDecoration(
                          labelText: 'Phone Number',
                          hintText: 'Enter phone number',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.phone),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a phone number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                          labelText: 'Username',
                          hintText: 'Enter username',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.person),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a username';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          hintText: 'Enter password',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.lock),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey[600],
                          side: BorderSide(color: Colors.grey[300]!),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            setState(() {
                              _staffList.add(
                                Staff(
                                  id: (_staffList.length + 1).toString(),
                                  name: _nameController.text,
                                  position: _positionController.text,
                                  email: _emailController.text,
                                  phoneNumber: _phoneController.text,
                                  username: _usernameController.text,
                                  password: _passwordController.text,
                                  status: 'active',
                                ),
                              );
                            });
                            _filterStaff();
                            Navigator.pop(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Add Staff'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _viewStaff(Staff staff) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: widget.isMobile ? double.infinity : 400,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          padding: EdgeInsets.all(widget.isMobile ? 16 : 24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with avatar
                Container(
                  width: widget.isMobile ? 60 : 80,
                  height: widget.isMobile ? 60 : 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF338AFF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(
                      widget.isMobile ? 30 : 40,
                    ),
                  ),
                  child: Icon(
                    Icons.person,
                    color: const Color(0xFF338AFF),
                    size: widget.isMobile ? 30 : 40,
                  ),
                ),
                SizedBox(height: widget.isMobile ? 16 : 20),

                // Staff name
                Text(
                  staff.name,
                  style: TextStyle(
                    fontSize: widget.isMobile ? 20 : 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // Position
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: widget.isMobile ? 12 : 16,
                    vertical: widget.isMobile ? 6 : 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF338AFF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    staff.position,
                    style: TextStyle(
                      fontSize: widget.isMobile ? 14 : 16,
                      color: const Color(0xFF338AFF),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(height: widget.isMobile ? 20 : 24),

                // Details
                Container(
                  padding: EdgeInsets.all(widget.isMobile ? 16 : 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      _buildDetailRow(Icons.email, 'Email', staff.email),
                      const SizedBox(height: 16),
                      _buildDetailRow(Icons.phone, 'Phone', staff.phoneNumber),
                      const SizedBox(height: 16),
                      _buildDetailRow(Icons.person, 'Username', staff.username),
                      const SizedBox(height: 16),
                      _buildDetailRow(Icons.lock, 'Password', staff.password),
                      const SizedBox(height: 16),
                      _buildDetailRow(Icons.badge, 'ID', staff.id),
                    ],
                  ),
                ),
                SizedBox(height: widget.isMobile ? 20 : 24),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _editStaff(staff);
                        },
                        icon: Icon(Icons.edit, size: widget.isMobile ? 16 : 18),
                        label: const Text('Edit'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF338AFF),
                          side: const BorderSide(color: Color(0xFF338AFF)),
                          padding: EdgeInsets.symmetric(
                            vertical: widget.isMobile ? 10 : 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.close,
                          size: widget.isMobile ? 16 : 18,
                        ),
                        label: const Text('Close'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF338AFF),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            vertical: widget.isMobile ? 10 : 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[600], size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  color: valueColor ?? Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _editStaff(Staff staff) {
    _nameController.text = staff.name;
    _positionController.text = staff.position;
    _emailController.text = staff.email;
    _phoneController.text = staff.phoneNumber;
    _usernameController.text = staff.username;
    _passwordController.text = staff.password;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: widget.isMobile ? double.infinity : 500,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          padding: EdgeInsets.all(widget.isMobile ? 16 : 24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF338AFF).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.edit,
                        color: Color(0xFF338AFF),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Edit Staff',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Form
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.person),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _positionController.text.isEmpty
                            ? null
                            : _positionController.text,
                        items: _filterOptions
                            .where((opt) => opt != 'All')
                            .map(
                              (opt) => DropdownMenuItem(
                                value: opt,
                                child: Text(opt),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            _positionController.text = val;
                          }
                        },
                        decoration: InputDecoration(
                          labelText: 'Position',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.work),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select a position';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.email),
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
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _phoneController,
                        decoration: InputDecoration(
                          labelText: 'Phone Number',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.phone),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a phone number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                          labelText: 'Username',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.person),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a username';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.lock),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey[600],
                          side: BorderSide(color: Colors.grey[300]!),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            setState(() {
                              final index = _staffList.indexWhere(
                                (element) => element.id == staff.id,
                              );
                              if (index != -1) {
                                _staffList[index] = Staff(
                                  id: staff.id,
                                  name: _nameController.text,
                                  position: _positionController.text,
                                  email: _emailController.text,
                                  phoneNumber: _phoneController.text,
                                  username: _usernameController.text,
                                  password: _passwordController.text,
                                  status: staff.status,
                                );
                              }
                            });
                            _filterStaff();
                            Navigator.pop(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF338AFF),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Save'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _deleteStaff(Staff staff) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Warning icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Icon(Icons.warning, color: Colors.red, size: 30),
              ),
              const SizedBox(height: 20),

              // Title
              const Text(
                'Delete Staff',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),

              // Message
              Text(
                'Are you sure you want to delete ${staff.name}?',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'This action cannot be undone.',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey[600],
                        side: BorderSide(color: Colors.grey[300]!),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _staffList.removeWhere(
                            (element) => element.id == staff.id,
                          );
                        });
                        _filterStaff();
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Delete'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewStaff,
        backgroundColor: const Color(0xFF338AFF),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            // Add refresh logic here
            await Future.delayed(const Duration(seconds: 1));
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(widget.isMobile ? 16 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Center(
                  child: Text(
                    'STAFF MANAGEMENT',
                    style: TextStyle(
                      fontSize: widget.isMobile ? 24 : 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                SizedBox(height: widget.isMobile ? 24 : 32),

                // Summary Cards
                _buildSummarySection(),

                // Search and Filter Section
                _buildSearchAndFilterSection(),

                SizedBox(height: widget.isMobile ? 24 : 32),

                // Staff List
                _buildStaffList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummarySection() {
    if (widget.isMobile) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _onFilterChanged('All'),
                  child: _buildSummaryCard(
                    'Total Staff',
                    '${_staffList.length}',
                    Icons.people,
                    const Color(0xFF338AFF),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => _onFilterChanged('Technical'),
                  child: _buildSummaryCard(
                    'Technical',
                    '${_staffList.where((s) => s.position == 'Technical').length}',
                    Icons.build,
                    const Color(0xFF10B981),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _onFilterChanged('Admin'),
                  child: _buildSummaryCard(
                    'Admins',
                    '${_staffList.where((s) => s.position == 'Admin').length}',
                    Icons.admin_panel_settings,
                    const Color(0xFF338AFF),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => _onFilterChanged('All'),
                  child: _buildSummaryCard(
                    'Active Staff',
                    '${_staffList.where((s) => (s.status ?? 'active') == 'active').length}/${_staffList.length}',
                    Icons.check_circle,
                    const Color(0xFF10B981),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    } else {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _onFilterChanged('All'),
                  child: _buildSummaryCard(
                    'Total Staff',
                    '${_staffList.length}',
                    Icons.people,
                    const Color(0xFF338AFF),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: GestureDetector(
                  onTap: () => _onFilterChanged('Technical'),
                  child: _buildSummaryCard(
                    'Technical',
                    '${_staffList.where((s) => s.position == 'Technical').length}',
                    Icons.build,
                    const Color(0xFF10B981),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: GestureDetector(
                  onTap: () => _onFilterChanged('Admin'),
                  child: _buildSummaryCard(
                    'Admins',
                    '${_staffList.where((s) => s.position == 'Admin').length}',
                    Icons.admin_panel_settings,
                    const Color(0xFF338AFF),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _onFilterChanged('All'),
                  child: _buildSummaryCard(
                    'Active Staff',
                    '${_staffList.where((s) => (s.status ?? 'active') == 'active').length}/${_staffList.length}',
                    Icons.check_circle,
                    const Color(0xFF10B981),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(child: SizedBox.shrink()),
            ],
          ),
        ],
      );
    }
  }

  Widget _buildSearchAndFilterSection() {
    if (widget.isMobile) {
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Column(
          children: [
            // Search Bar
            TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search staff...',
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
            // Filter dropdown
            DropdownButtonFormField<String>(
              value: _selectedFilter,
              decoration: InputDecoration(
                labelText: 'Filter by Position',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              items: _filterOptions.map((String filter) {
                return DropdownMenuItem<String>(
                  value: filter,
                  child: Text(filter),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  _onFilterChanged(newValue);
                }
              },
            ),
          ],
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Row(
          children: [
            // Search Bar
            Expanded(
              flex: 2,
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search staff by name, position, or email...',
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
            ),
            const SizedBox(width: 16),
            // Filter Dropdown
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedFilter,
                decoration: InputDecoration(
                  labelText: 'Filter by Position',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                items: _filterOptions.map((String filter) {
                  return DropdownMenuItem<String>(
                    value: filter,
                    child: Text(filter),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    _onFilterChanged(newValue);
                  }
                },
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildStaffList() {
    if (_filteredStaffList.isEmpty) {
      return Center(
        child: Column(
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty || _selectedFilter != 'All'
                  ? 'No staff found matching your criteria'
                  : 'No staff members yet',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            if (_searchQuery.isNotEmpty || _selectedFilter != 'All')
              TextButton(
                onPressed: () {
                  _searchController.clear();
                  _onSearchChanged('');
                  _onFilterChanged('All');
                },
                child: const Text('Clear filters'),
              ),
          ],
        ),
      );
    } else {
      final totalItems = _filteredStaffList.length;
      final totalPages = (totalItems + _pageSize - 1) ~/ _pageSize;
      final startIndex = (_currentPage - 1) * _pageSize;
      final endIndex = (startIndex + _pageSize) > totalItems
          ? totalItems
          : startIndex + _pageSize;
      final pageItems = _filteredStaffList.sublist(startIndex, endIndex);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: pageItems.length,
            itemBuilder: (context, index) {
              final staff = pageItems[index];
              return _buildStaffCard(staff);
            },
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
                onPressed: _currentPage < totalPages ? _goToNextPage : null,
                icon: const Icon(Icons.chevron_right),
                label: const Text('Next'),
              ),
            ],
          ),
        ],
      );
    }
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(widget.isMobile ? 16 : 20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: widget.isMobile ? 28 : 24),
            ],
          ),
          SizedBox(height: widget.isMobile ? 12 : 16),
          Text(
            value,
            style: TextStyle(
              fontSize: widget.isMobile ? 32 : 28,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: widget.isMobile ? 16 : 14,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffCard(Staff staff) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(widget.isMobile ? 16 : 20),
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
      child: Column(
        children: [
          Row(
            children: [
              // Avatar
              Container(
                width: widget.isMobile ? 50 : 60,
                height: widget.isMobile ? 50 : 60,
                decoration: BoxDecoration(
                  color: _getPositionColor(staff.position).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(
                    widget.isMobile ? 25 : 30,
                  ),
                ),
                child: Icon(
                  _getPositionIcon(staff.position),
                  color: _getPositionColor(staff.position),
                  size: widget.isMobile ? 24 : 28,
                ),
              ),
              SizedBox(width: widget.isMobile ? 16 : 20),
              // Staff info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      staff.name,
                      style: TextStyle(
                        fontSize: widget.isMobile ? 16 : 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      staff.position,
                      style: TextStyle(
                        fontSize: widget.isMobile ? 12 : 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(
                              staff.status ?? 'active',
                            ).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: _getStatusColor(
                                    staff.status ?? 'active',
                                  ),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _getStatusText(staff.status ?? 'active'),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _getStatusColor(
                                    staff.status ?? 'active',
                                  ),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getPositionColor(
                              staff.position,
                            ).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            staff.position,
                            style: TextStyle(
                              fontSize: 12,
                              color: _getPositionColor(staff.position),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Triple burger dot menu
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.grey, size: 24),
                onSelected: (String value) {
                  switch (value) {
                    case 'view':
                      _viewStaff(staff);
                      break;
                    case 'edit':
                      _editStaff(staff);
                      break;
                    case 'delete':
                      _deleteStaff(staff);
                      break;
                  }
                },
                itemBuilder: (BuildContext context) => [
                  const PopupMenuItem<String>(
                    value: 'view',
                    child: Row(
                      children: [
                        Icon(Icons.visibility, color: Colors.blue, size: 20),
                        SizedBox(width: 12),
                        Text('View Details'),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, color: Colors.orange, size: 20),
                        SizedBox(width: 12),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red, size: 20),
                        SizedBox(width: 12),
                        Text('Delete'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Additional staff information
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        Icons.email,
                        'Email',
                        staff.email,
                        widget.isMobile,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildInfoItem(
                        Icons.phone,
                        'Phone',
                        staff.phoneNumber,
                        widget.isMobile,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        Icons.person,
                        'Username',
                        staff.username,
                        widget.isMobile,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildInfoItem(
                        Icons.badge,
                        'ID',
                        staff.id,
                        widget.isMobile,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(
    IconData icon,
    String label,
    String value,
    bool isMobile, {
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[600], size: isMobile ? 16 : 18),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: isMobile ? 10 : 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: isMobile ? 12 : 14,
                  color: valueColor ?? Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getPositionColor(String position) {
    switch (position.toLowerCase()) {
      case 'technical':
        return const Color(0xFF10B981);
      case 'admin':
        return const Color(0xFF338AFF);
      default:
        return const Color(0xFF6B7280);
    }
  }

  IconData _getPositionIcon(String position) {
    switch (position.toLowerCase()) {
      case 'technical':
        return Icons.build;
      case 'admin':
        return Icons.admin_panel_settings;
      default:
        return Icons.person;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return const Color(0xFF10B981); // Green
      case 'offline':
        return const Color(0xFF6B7280); // Gray
      default:
        return const Color(0xFF10B981); // Default to green
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return 'Active';
      case 'offline':
        return 'Offline';
      default:
        return 'Active';
    }
  }
}
