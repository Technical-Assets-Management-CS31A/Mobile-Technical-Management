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
                  CupertinoIcons.book,
                  CupertinoIcons.book_fill,
                  'Borrow',
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


  void _showMenu(BuildContext context) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 36,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Menu title
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            CupertinoIcons.line_horizontal_3,
                            color: Theme.of(context).colorScheme.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Menu',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context).colorScheme.onSurface,
                                letterSpacing: -0.5,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Profile section
                  _buildMenuProfileSection(context),
                  const SizedBox(height: 20),

                  // Menu items section
                  _buildMenuItemsSection(context),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMenuProfileSection(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary.withOpacity(0.1),
                Theme.of(context).colorScheme.primary.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(CupertinoIcons.person_fill, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      authProvider.username ?? 'User',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      authProvider.userEmail ?? 'Logged in successfully',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuItemsSection(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isStaff = authProvider.userRole == 'Staff';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          _buildMenuItem(
            context,
            icon: CupertinoIcons.settings,
            title: 'Settings',
            subtitle: 'App preferences and configuration',
            onTap: () => _navigateToSettings(context),
          ),
          const SizedBox(height: 12),
          _buildMenuItem(
            context,
            icon: CupertinoIcons.clock,
            title: 'History',
            subtitle: 'View borrowing history',
            onTap: () => _navigateToHistory(context),
          ),
          const SizedBox(height: 12),
          _buildMenuItem(
            context,
            icon: CupertinoIcons.book,
            title: 'Registered Modules',
            subtitle: 'View all registered modules',
            onTap: () => _navigateToModules(context),
          ),
          if (!isStaff) ...[
            const SizedBox(height: 12),
            _buildMenuItem(
              context,
              icon: CupertinoIcons.archivebox,
              title: 'Archive',
              subtitle: 'View archived items',
              onTap: () => _navigateToArchive(context),
            ),
          ],
          const SizedBox(height: 12),
          _buildMenuItem(
            context,
            icon: CupertinoIcons.square_arrow_right,
            title: 'Logout',
            subtitle: 'Sign out of your account',
            onTap: () => _showLogoutDialog(context),
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceBright,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDestructive
                        ? Colors.red.withOpacity(0.1)
                        : Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: isDestructive
                        ? Colors.red
                        : Theme.of(context).colorScheme.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDestructive
                              ? Colors.red
                              : Theme.of(context).colorScheme.onSurface,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  CupertinoIcons.chevron_right,
                  size: 18,
                  color: isDestructive
                      ? Colors.red.withOpacity(0.5)
                      : Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                ),
              ],
            ),
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
