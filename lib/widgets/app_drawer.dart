import 'package:flutter/material.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF338AFF)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo placeholder (red and white abstract logo)
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.arrow_upward,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Web-Dashboard-Page',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'admin@company.com',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard, color: Color(0xFF338AFF)),
            title: const Text('Dashboard'),
            onTap: () {
              Navigator.pop(context);
              // Already on dashboard
            },
          ),
          ListTile(
            leading: const Icon(Icons.inventory, color: Color(0xFF338AFF)),
            title: const Text('Inventory List'),
            onTap: () {
              Navigator.pop(context);
              // Navigate to inventory list screen
            },
          ),
          ListTile(
            leading: const Icon(Icons.list, color: Color(0xFF338AFF)),
            title: const Text('Item List'),
            onTap: () {
              Navigator.pop(context);
              // Navigate to item list screen
            },
          ),
          ListTile(
            leading: const Icon(Icons.people, color: Color(0xFF338AFF)),
            title: const Text('Staff'),
            onTap: () {
              Navigator.pop(context);
              // Navigate to staff screen
            },
          ),
          ListTile(
            leading: const Icon(Icons.history, color: Color(0xFF338AFF)),
            title: const Text('History'),
            onTap: () {
              Navigator.pop(context);
              // Navigate to history screen
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings, color: Color(0xFF338AFF)),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              // Navigate to settings screen
            },
          ),
          ListTile(
            leading: const Icon(Icons.help, color: Color(0xFF338AFF)),
            title: const Text('Help & Support'),
            onTap: () {
              Navigator.pop(context);
              // Navigate to help screen
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).pushReplacementNamed('/');
            },
          ),
        ],
      ),
    );
  }
}
