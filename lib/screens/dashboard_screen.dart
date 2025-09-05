import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'staff_screen.dart';
import 'sidebar.dart';
import 'inventory_list_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  bool _isSidebarOpen = false;

  // Sample data for the dashboard
  final List<Map<String, dynamic>> _recentBorrowedItems = [
    {
      'dateTime': '2025-08-9 7:30 AM',
      'teacher': 'Mr. Johnny D. Sinner',
      'room': '69',
      'item': 'Mouse',
      'occupiedBy': 'Harry Bot',
      'remarks': 'Damaged',
    },
    {
      'dateTime': '2025-08-7 10:30 AM',
      'teacher': 'Ms. Fuu K. Que',
      'room': '101',
      'item': 'Lamborghini',
      'occupiedBy': 'Uzziah',
      'remarks': 'In use',
    },
    {
      'dateTime': '2025-08-6 3:00 PM',
      'teacher': 'Mr. Nilo Butay',
      'room': '301',
      'item': 'Keyboard',
      'occupiedBy': 'Sung Jin-Bro',
      'remarks': 'Cooked',
    },
  ];

  final List<Map<String, dynamic>> _staffStatus = [
    {'name': 'Alice Guonggong', 'status': 'Active', 'color': Colors.green},
    {'name': 'Tungtung Sahur', 'status': 'Active', 'color': Colors.green},
    {'name': 'Adobong Bilat-an', 'status': 'Active', 'color': Colors.green},
    {'name': 'Nilagang Kahoy', 'status': 'Offline', 'color': Colors.orange},
  ];

  final List<Map<String, dynamic>> _categoryData = [
    {'name': 'Monitor', 'color': Colors.lightBlue, 'count': 15},
    {'name': 'Mouse', 'color': Colors.red, 'count': 25},
    {'name': 'Keyboard', 'color': Colors.green, 'count': 20},
    {'name': 'Others', 'color': Colors.blue, 'count': 30},
  ];

  // Staff page moved to separate screen

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: isMobile
          ? AppBar(
              backgroundColor: const Color(0xFF338AFF),
              foregroundColor: Colors.white,
              title: const Text('Dashboard'),
              actions: [
                IconButton(
                  icon: Icon(_isSidebarOpen ? Icons.menu_open : Icons.menu),
                  onPressed: () {
                    setState(() {
                      _isSidebarOpen = !_isSidebarOpen;
                    });
                  },
                ),
              ],
            )
          : null,
      body: Stack(
        children: [
          Row(
            children: [
              // Sidebar inline only on desktop/tablet
              if (!isMobile) Sidebar(
                isMobile: isMobile,
                selectedIndex: _selectedIndex,
                onItemSelected: (index) {
                  setState(() {
                    _selectedIndex = index;
                  });
                },
              ),
              // Main Content Area
              Expanded(child: _buildMainContent(isMobile)),
            ],
          ),
          // Mobile backdrop overlay (covers content beneath the sidebar)
          if (isMobile && _isSidebarOpen)
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _isSidebarOpen = false;
                  });
                },
                child: Container(color: Colors.black.withOpacity(0.5)),
              ),
            ),
          // Mobile sidebar overlays content
          if (isMobile && _isSidebarOpen)
            Positioned(
              top: 0,
              bottom: 0,
              left: 0,
              width: 200,
              child: SizedBox(
                height: double.infinity,
                child: Material(
                  elevation: 8,
                  child: Sidebar(
                    isMobile: true,
                    selectedIndex: _selectedIndex,
                    onItemSelected: (index) {
                      setState(() {
                        _selectedIndex = index;
                        _isSidebarOpen = false;
                      });
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMainContent(bool isMobile) {
    // Handle different screens based on sidebar selection
    if (_selectedIndex == 1) {
      return InventoryListScreen(isMobile: isMobile);
    } else if (_selectedIndex == 3) {
      return StaffScreen(isMobile: isMobile);
    }
    return RefreshIndicator(
      onRefresh: () async {
        // Simulate data refresh
        await Future.delayed(const Duration(seconds: 1));
        // You can add actual data refresh logic here
      },
      child: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Center(
              child: Text(
                'DASHBOARD',
                style: TextStyle(
                  fontSize: isMobile ? 24 : 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            SizedBox(height: isMobile ? 24 : 32),

            // Top Row - Summary Cards
            if (isMobile)
              Column(
                children: [
                  // First row: 2 cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                          'Total Items',
                          '6969',
                          Icons.inventory,
                          isMobile: isMobile,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSummaryCard(
                          'Items by Category',
                          '30',
                          Icons.category,
                          showDropdown: true,
                          isMobile: isMobile,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Second row: 2 cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                          'Active Staff',
                          '5',
                          Icons.people,
                          isMobile: isMobile,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSummaryCard(
                          'Items Borrowed',
                          '10',
                          Icons.people_outline,
                          isMobile: isMobile,
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
                      '6969',
                      Icons.inventory,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildSummaryCard(
                      'Items by Category',
                      '30',
                      Icons.category,
                      showDropdown: true,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildSummaryCard('Active Staff', '5', Icons.people),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildSummaryCard(
                      'Items Borrowed',
                      '10',
                      Icons.people_outline,
                    ),
                  ),
                ],
              ),

            SizedBox(height: isMobile ? 20 : 24),

            // Middle Row - Charts and Staff Status
            if (isMobile)
              Column(
                children: [
                  _buildCategoryChart(isMobile: isMobile),
                  const SizedBox(height: 20),
                  _buildStaffStatusCard(isMobile: isMobile),
                ],
              )
            else
              Row(
                children: [
                  Expanded(flex: 2, child: _buildCategoryChart()),
                  const SizedBox(width: 24),
                  Expanded(flex: 1, child: _buildStaffStatusCard()),
                ],
              ),

            SizedBox(height: isMobile ? 20 : 24),

            // Bottom - Recently Borrowed Items Table
            _buildRecentBorrowedTable(isMobile: isMobile),

            // Add extra space at bottom for better pull-to-refresh experience
            if (isMobile) const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon, {
    bool showDropdown = false,
    bool isMobile = false,
  }) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                icon,
                color: const Color(0xFF338AFF),
                size: isMobile ? 28 : 24,
              ),
              if (showDropdown)
                const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
            ],
          ),
          SizedBox(height: isMobile ? 12 : 16),
          Text(
            value,
            style: TextStyle(
              fontSize: isMobile ? 32 : 28,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: isMobile ? 16 : 14,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChart({bool isMobile = false}) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 24),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Items Available by Category',
            style: TextStyle(
              fontSize: isMobile ? 20 : 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          SizedBox(height: isMobile ? 20 : 24),
          if (isMobile)
            Column(
              children: [
                // Mobile: Chart on top
                SizedBox(
                  width: 150,
                  height: 150,
                  child: PieChart(
                    PieChartData(
                      sections: _categoryData.asMap().entries.map((entry) {
                        final category = entry.value;
                        return PieChartSectionData(
                          color: category['color'],
                          value: category['count'].toDouble(),
                          title: '${category['count']}',
                          radius: 60,
                          titleStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        );
                      }).toList(),
                      centerSpaceRadius: 40,
                      sectionsSpace: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Mobile: Legend below chart
                ..._categoryData.map((category) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: category['color'],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${category['name']} (${category['count']})',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            )
          else
            Row(
              children: [
                // Desktop: Chart and legend side by side
                SizedBox(
                  width: 120,
                  height: 120,
                  child: PieChart(
                    PieChartData(
                      sections: _categoryData.asMap().entries.map((entry) {
                        final category = entry.value;
                        return PieChartSectionData(
                          color: category['color'],
                          value: category['count'].toDouble(),
                          title: '${category['count']}',
                          radius: 50,
                          titleStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        );
                      }).toList(),
                      centerSpaceRadius: 30,
                      sectionsSpace: 2,
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                // Legend
                Expanded(
                  child: Column(
                    children: _categoryData.map((category) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: category['color'],
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${category['name']} (${category['count']})',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildStaffStatusCard({bool isMobile = false}) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 24),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Staff Status',
            style: TextStyle(
              fontSize: isMobile ? 20 : 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          SizedBox(height: isMobile ? 16 : 20),
          ..._staffStatus.map((staff) {
            return Padding(
              padding: EdgeInsets.symmetric(vertical: isMobile ? 10 : 8),
              child: Row(
                children: [
                  SizedBox(
                    width: isMobile ? 24 : 20,
                    height: isMobile ? 24 : 20,
                    child: Radio<bool>(
                      value: true,
                      groupValue: false,
                      onChanged: (value) {},
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      staff['name'],
                      style: TextStyle(
                        fontSize: isMobile ? 16 : 14,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Container(
                    width: isMobile ? 10 : 8,
                    height: isMobile ? 10 : 8,
                    decoration: BoxDecoration(
                      color: staff['color'],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    staff['status'],
                    style: TextStyle(
                      fontSize: isMobile ? 14 : 12,
                      color: staff['color'],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRecentBorrowedTable({bool isMobile = false}) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 24),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recently Borrowed Items',
                style: TextStyle(
                  fontSize: isMobile ? 20 : 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              if (isMobile)
                TextButton.icon(
                  onPressed: () {
                    // Navigate to full history or refresh
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Viewing full borrowing history...'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.history, size: 18),
                  label: const Text('View All'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF338AFF),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: isMobile ? 16 : 20),
          if (isMobile)
            // Mobile: Interactive Card-based layout
            Column(
              children: _recentBorrowedItems.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return _buildInteractiveMobileCard(item, index, isMobile);
              }).toList(),
            )
          else
            // Desktop: Enhanced Table layout
            Column(
              children: [
                // Table header with actions
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        flex: 2,
                        child: Text(
                          'Date & Time',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      const Expanded(
                        flex: 2,
                        child: Text(
                          'Teacher',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      const Expanded(
                        flex: 1,
                        child: Text(
                          'Room',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      const Expanded(
                        flex: 1,
                        child: Text(
                          'Item',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      const Expanded(
                        flex: 2,
                        child: Text(
                          'Occupied By',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      const Expanded(
                        flex: 1,
                        child: Text(
                          'Remarks',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 80), // Space for actions
                    ],
                  ),
                ),
                // Table rows
                ..._recentBorrowedItems.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  return _buildInteractiveTableRow(item, index);
                }),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildInteractiveMobileCard(
    Map<String, dynamic> item,
    int index,
    bool isMobile,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _getItemColor(item['item']).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getItemIcon(item['item']),
            color: _getItemColor(item['item']),
            size: 20,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                item['item'],
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(item['remarks']),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                item['remarks'],
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        subtitle: Text(
          '${item['teacher']} • Room ${item['room']}',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Column(
              children: [
                _buildMobileTableRow('Date & Time', item['dateTime']),
                _buildMobileTableRow('Teacher', item['teacher']),
                _buildMobileTableRow('Room', item['room']),
                _buildMobileTableRow('Item', item['item']),
                _buildMobileTableRow('Occupied By', item['occupiedBy']),
                _buildMobileTableRow(
                  'Remarks',
                  item['remarks'],
                  color: _getStatusColor(item['remarks']),
                ),
                const SizedBox(height: 16),
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          _showItemDetails(item);
                        },
                        icon: const Icon(Icons.info_outline, size: 16),
                        label: const Text('Details'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF338AFF),
                          side: const BorderSide(color: Color(0xFF338AFF)),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _returnItem(item);
                        },
                        icon: const Icon(Icons.assignment_return, size: 16),
                        label: const Text('Return'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
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

  Widget _buildInteractiveTableRow(Map<String, dynamic> item, int index) {
    return Container(
      decoration: BoxDecoration(
        color: index.isEven ? Colors.white : Colors.grey.shade50,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _getItemColor(item['item']).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      _getItemIcon(item['item']),
                      color: _getItemColor(item['item']),
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['dateTime'],
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          item['item'],
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                item['teacher'],
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                item['room'],
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                item['item'],
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                item['occupiedBy'],
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(item['remarks']),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  item['remarks'],
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          // Action buttons
          SizedBox(
            width: 80,
            child: Row(
              children: [
                IconButton(
                  onPressed: () => _showItemDetails(item),
                  icon: const Icon(Icons.info_outline, size: 18),
                  tooltip: 'View Details',
                  color: const Color(0xFF338AFF),
                ),
                IconButton(
                  onPressed: () => _returnItem(item),
                  icon: const Icon(Icons.assignment_return, size: 18),
                  tooltip: 'Return Item',
                  color: Colors.green,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getItemColor(String itemName) {
    switch (itemName.toLowerCase()) {
      case 'mouse':
        return Colors.red;
      case 'keyboard':
        return Colors.green;
      case 'monitor':
        return Colors.blue;
      case 'lamborghini':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getItemIcon(String itemName) {
    switch (itemName.toLowerCase()) {
      case 'mouse':
        return Icons.mouse;
      case 'keyboard':
        return Icons.keyboard;
      case 'monitor':
        return Icons.monitor;
      case 'lamborghini':
        return Icons.directions_car;
      default:
        return Icons.devices;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'damaged':
        return Colors.red;
      case 'in use':
        return Colors.green;
      case 'cooked':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  void _showItemDetails(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              _getItemIcon(item['item']),
              color: _getItemColor(item['item']),
              size: 24,
            ),
            const SizedBox(width: 12),
            Text('Item Details'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Item', item['item']),
            _buildDetailRow('Teacher', item['teacher']),
            _buildDetailRow('Room', item['room']),
            _buildDetailRow('Occupied By', item['occupiedBy']),
            _buildDetailRow('Date & Time', item['dateTime']),
            _buildDetailRow(
              'Status',
              item['remarks'],
              color: _getStatusColor(item['remarks']),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _returnItem(item);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Return Item'),
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

  Widget _buildMobileTableRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: color ?? Colors.black87,
                fontWeight: color != null ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _returnItem(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Return Item'),
        content: Text('Are you sure you want to return "${item['item']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${item['item']} has been returned successfully!',
                  ),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 3),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm Return'),
          ),
        ],
      ),
    );
  }
}
