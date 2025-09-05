import 'package:flutter/material.dart';

class Sidebar extends StatelessWidget {
  final bool isMobile;
  final int selectedIndex;
  final Function(int) onItemSelected;

  const Sidebar({
    super.key,
    required this.isMobile,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: double.infinity,
      child: Container(
        width: isMobile ? 200 : 250,
        color: const Color(0xFF338AFF),
        child: Column(
          children: [
            // Logo and Title
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // ACLC Logo
                  Container(
                    width: isMobile ? 80 : 100,
                    height: isMobile ? 80 : 100,
                    padding: const EdgeInsets.all(8),
                    child: Image.asset(
                      'assets/icons/aclcLOGO.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (!isMobile)
                    const Column(
                      children: [
                        Text(
                          'ACLC College',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Technical Management',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const Divider(color: Colors.white24, height: 1),
            // Navigation Items
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildNavItem(0, Icons.dashboard, 'Dashboard'),
                  _buildNavItem(1, Icons.inventory, 'Inventory List'),
                  _buildNavItem(2, Icons.list, 'Item List'),
                  _buildNavItem(3, Icons.people, 'Staff'),
                  _buildNavItem(4, Icons.history, 'History'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String title) {
    final isSelected = selectedIndex == index;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.white, size: 20),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        onTap: () => onItemSelected(index),
      ),
    );
  }
}
