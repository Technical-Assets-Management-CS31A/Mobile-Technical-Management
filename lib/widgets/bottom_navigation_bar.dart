import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/login/login_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/archive/archive_screen.dart';
import '../screens/history/history_screen.dart';
import '../screens/modules/registered_modules_screen.dart';
import '../utils/snackbar_helper.dart';

class BottomBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const BottomBar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    this.onRefreshNeeded,
  });

  final VoidCallback? onRefreshNeeded;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isStudentOrTeacher = authProvider.userRole == 'Student' || authProvider.userRole == 'Teacher';

    return Container(
      height: 90,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceBright,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: isStudentOrTeacher
            ? [
                _buildNavItem(
                  context,
                  0,
                  CupertinoIcons.location,
                  CupertinoIcons.location_fill,
                  'Tracking',
                ),
                _buildNavItem(
                  context,
                  1,
                  CupertinoIcons.square_grid_2x2,
                  CupertinoIcons.square_grid_2x2_fill,
                  'Inventory',
                ),
                _buildNavItem(
                  context,
                  2,
                  CupertinoIcons.clock,
                  CupertinoIcons.clock_fill,
                  'History',
                ),
                _buildNavItem(
                  context,
                  3,
                  CupertinoIcons.line_horizontal_3,
                  CupertinoIcons.line_horizontal_3,
                  'Menu',
                ),
              ]
            : [
                _buildNavItem(
                  context,
                  0,
                  CupertinoIcons.square_grid_2x2,
                  CupertinoIcons.square_grid_2x2_fill,
                  'Dashboard',
                ),
                _buildNavItem(
                  context,
                  1,
                  CupertinoIcons.cube_box,
                  CupertinoIcons.cube_box_fill,
                  'Inventory',
                ),
                _buildNavItem(
                  context,
                  2,
                  CupertinoIcons.person_2,
                  CupertinoIcons.person_2_fill,
                  'Users',
                ),
                _buildNavItem(
                  context,
                  3,
                  CupertinoIcons.line_horizontal_3,
                  CupertinoIcons.line_horizontal_3,
                  'Menu',
                ),
              ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    int index,
    IconData iconOutlined,
    IconData iconFilled,
    String label,
  ) {
    final isSelected = selectedIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onItemSelected(index);
        },
        child: Container(
          height: double.infinity,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                padding: EdgeInsets.all(isSelected ? 10 : 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [],
                ),
                child: Icon(
                  isSelected ? iconFilled : iconOutlined,
                  color: isSelected
                      ? Colors.white
                      : Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.5),
                  size: 24,
                ),
              ),
              const SizedBox(height: 6),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 250),
                style: TextStyle(
                  fontSize: isSelected ? 12 : 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.5),
                  letterSpacing: -0.2,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToSettings(BuildContext context) {
    Navigator.of(context).pop(); // Close the menu first
    // Navigate to settings screen
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const SettingsScreen()));
  }

  void _navigateToHistory(BuildContext context) {
    Navigator.of(context).pop(); // Close the menu first
    // Navigate to history screen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const HistoryScreen(isMobile: true),
      ),
    );
  }

  Future<void> _navigateToModules(BuildContext context) async {
    Navigator.of(context).pop(); // Close the menu first
    // Navigate to registered modules screen
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const RegisteredModulesScreen(isMobile: true),
      ),
    );
    
    // Trigger refresh when returning from modules
    onRefreshNeeded?.call();
  }

  Future<void> _navigateToArchive(BuildContext context) async {
    Navigator.of(context).pop(); // Close the menu first
    // Navigate to archive screen
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const ArchiveScreen()));
    
    // Always trigger refresh when returning from archive
    onRefreshNeeded?.call();
  }

  void _showLogoutDialog(BuildContext context) {
    Navigator.of(context).pop(); // Close the settings menu first
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _logout(context);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  void _logout(BuildContext context) async {
    try {
      // Use AuthProvider to logout
      final authProvider = context.read<AuthProvider>();
      await authProvider.logout();

      // Navigate to login screen
      if (context.mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } catch (e) {
      // Handle logout error
      if (context.mounted) {
        SnackbarHelper.showErrorSnackBar(context, 'Logout failed: $e');
      }
    }
  }
}
