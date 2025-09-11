import 'package:flutter/material.dart';

class InventoryListScreen extends StatelessWidget {
  final bool isMobile;

  const InventoryListScreen({
    super.key,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            // Add refresh logic here
            await Future.delayed(const Duration(seconds: 1));
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Center(
                  child: Text(
                    'INVENTORY',
                    style: TextStyle(
                      fontSize: isMobile ? 24 : 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                SizedBox(height: isMobile ? 24 : 32),
                // Top Summary Cards
                if (isMobile)
                  Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildSummaryCard(
                              'Total Items',
                              '100',
                              Icons.inventory,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildSummaryCard(
                              'Categories',
                              '10',
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
                              '85',
                              Icons.check_circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildSummaryCard(
                              'In Use',
                              '15',
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
                          '100',
                          Icons.inventory,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildSummaryCard(
                          'Categories',
                          '10',
                          Icons.category,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildSummaryCard(
                          'Available',
                          '85',
                          Icons.check_circle,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildSummaryCard(
                          'In Use',
                          '15',
                          Icons.access_time,
                        ),
                      ),
                    ],
                  ),
                SizedBox(height: isMobile ? 24 : 32),
                // Search and Filter Bar
                Container(
                  padding: EdgeInsets.all(isMobile ? 16 : 20),
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
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Search items...',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      if (!isMobile) ...[
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            // Add filter action
                          },
                          icon: const Icon(Icons.filter_list),
                          label: const Text('Filter'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF338AFF),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () {
                            // Add new item action
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Add Item'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (isMobile)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              // Add filter action
                            },
                            icon: const Icon(Icons.filter_list, size: 20),
                            label: const Text('Filter'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF338AFF),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              // Add new item action
                            },
                            icon: const Icon(Icons.add, size: 20),
                            label: const Text('Add Item'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                SizedBox(height: isMobile ? 24 : 32),
                // Categories Grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isMobile ? 2 : 4,
                    childAspectRatio: isMobile ? 1.2 : 1.5,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: 8, // Replace with actual category count
                  itemBuilder: (context, index) {
                    final categories = [
                      {'name': 'Cables', 'count': '100', 'color': Colors.blue, 'icon': Icons.cable},
                      {'name': 'Adapters', 'count': '22', 'color': Colors.green, 'icon': Icons.power},
                      {'name': 'Peripherals', 'count': '45', 'color': Colors.red, 'icon': Icons.keyboard},
                      {'name': 'Networking', 'count': '12', 'color': Colors.orange, 'icon': Icons.router},
                      {'name': 'Storage', 'count': '33', 'color': Colors.purple, 'icon': Icons.storage},
                      {'name': 'Audio', 'count': '18', 'color': Colors.teal, 'icon': Icons.headphones},
                      {'name': 'Display', 'count': '25', 'color': Colors.indigo, 'icon': Icons.monitor},
                      {'name': 'Other', 'count': '8', 'color': Colors.grey, 'icon': Icons.devices_other},
                    ];
                    
                    if (index < categories.length) {
                      final category = categories[index];
                      return _buildCategoryCard(
                        category['name'] as String,
                        category['count'] as String,
                        category['color'] as Color,
                        category['icon'] as IconData,
                      );
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
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
              Icon(
                icon,
                color: const Color(0xFF338AFF),
                size: isMobile ? 28 : 24,
              ),
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

  Widget _buildCategoryCard(String title, String count, Color color, IconData icon) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                count,
                style: TextStyle(
                  fontSize: isMobile ? 24 : 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  fontSize: isMobile ? 14 : 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}