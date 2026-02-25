import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/constants.dart';
import '../../widgets/skeleton.dart';
import '../../widgets/keep_alive_wrapper.dart';
import '../../widgets/bottom_navigation_bar.dart';
import '../inventory/inventory_screen.dart';
import '../history/history_screen.dart';
import '../borrow/borrow_screen.dart';
import '../tracking/live_tracking_screen.dart';
import '../../services/inventory_service.dart';
import '../../utils/snackbar_helper.dart';
import '../../services/lend_service.dart';
import '../../providers/auth_provider.dart';
import '../settings/settings_screen.dart';
import '../archive/archive_screen.dart';
import '../modules/registered_modules_screen.dart';
import '../users/users_management_screen.dart';
import '../login/login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, this.isMobile = true});

  final bool isMobile;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  int _selectedIndex = 0;
  int _previousIndex = 0;
  bool _isLoading = true;
  late PageController _pageController;

  // Dashboard statistics
  int _totalItems = 0;
  int _activeStaff = 0;
  int _borrowedItems = 0;
  int _categoryCount = 0;

  // Live data for recent borrowed items
  List<Map<String, dynamic>> _recentBorrowedItems = [];
  
  // Timestamp to force refresh of child widgets
  DateTime _lastRefreshTime = DateTime.now();

  // Removed category chart; data no longer needed

  void _handleRefreshNeeded() {
    setState(() {
      _lastRefreshTime = DateTime.now();
    });
    // Only show dashboard skeleton if we are on the dashboard tab
    _loadDashboardData(useSkeleton: _selectedIndex == 0);
  }

  @override
  void initState() {
    super.initState();
    
    // Determine initial page based on role
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isStudentOrTeacher = authProvider.userRole == 'Student' || 
        authProvider.userRole == 'Teacher';
        
    // If student/teacher, start at Live Tracking screen (Page 3)
    // which corresponds to BottomBar index 0
    final initialPage = isStudentOrTeacher ? 3 : 0;
    _selectedIndex = isStudentOrTeacher ? 0 : 0; // Both start at their respective 0 index
    
    _pageController = PageController(initialPage: initialPage);
    _loadDashboardData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData({bool useSkeleton = true}) async {
    if (useSkeleton) {
      setState(() {
        _isLoading = true;
      });
    }
    try {
      final inventoryService = InventoryService();
      final lendService = LendService();
      // final staffService = StaffService(); // Not needed anymore

      // Fetch dashboard summary from API
      final summaryData = await inventoryService.getDashboardSummary();

      // Fetch recent borrowed items (last 3 items) - still using local service for now
      // Fetch recent borrowed items (last 3 items) - client side sorting
      final allLentItems = await lendService.getAllLentItems(pageSize: 50);
      
      // Sort items by lentAt date in descending order (newest first)
      allLentItems.sort((a, b) {
        if (a.lentAt == null) return 1;
        if (b.lentAt == null) return -1;
        return b.lentAt!.compareTo(a.lentAt!);
      });

      final recentItems = allLentItems
          .take(3)
          .map(
            (item) => {
              'dateTime': item.lentAt?.toString().split('.')[0] ?? '',
              'teacher': item.teacherFullName ?? 'N/A',
              'room': item.room ?? 'N/A',
              'item': item.itemName ?? 'N/A',
              'occupiedBy': item.borrowerFullName,  
              'remarks': item.status ?? 'Unknown',
              'borrowerRole': item.borrowerRole,
            },
          )
          .toList();

      if (mounted) {
        setState(() {
          _totalItems = summaryData.totalItems ?? 0;
          _borrowedItems = summaryData.totalLentItems ?? 0;
          _categoryCount = summaryData.totalItemsCategories ?? 0;
          _activeStaff = summaryData.totalActiveUsers ?? 0;
          _recentBorrowedItems = recentItems;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildModernAppBar(),
            Expanded(
              child: _isLoading
                  ? DashboardSkeleton(isMobile: widget.isMobile)
                  : _buildPageView(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final isStudentOrTeacher = authProvider.userRole == 'Student' ||
              authProvider.userRole == 'Teacher';
          
          return BottomBar(
            selectedIndex: _selectedIndex,
            onItemSelected: (index) {
              if (isStudentOrTeacher) {
                // Handle Student/Teacher navigation
                if (index == 3) {
                  // Menu item
                  _showMenu(context);
                } else {
                  // Map 0->3 (Live Tracking), 1->4 (Borrow), 2->5 (History)
                  int targetPage = index == 0 ? 3 : (index == 1 ? 4 : 5);
                  
                  if (targetPage != _pageController.page?.round()) {
                    setState(() {
                      _previousIndex = _selectedIndex;
                      _selectedIndex = index;
                    });
                    _pageController.jumpToPage(targetPage);
                  }
                }
              } else {
                // Handle Admin/Staff navigation
                if (index == 3) {
                  // Menu item
                  _showMenu(context);
                } else {
                  // Standard mapping for Dashboard (0), Inventory (1), Users (2)
                  if (index != _selectedIndex) {
                    setState(() {
                      _previousIndex = _selectedIndex;
                      _selectedIndex = index;
                    });
                    _pageController.jumpToPage(index);
                  }
                }
              }
            },
            onRefreshNeeded: _handleRefreshNeeded,
          );
        },
      ),
    );
  }

  Widget _buildModernAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary,
            const Color(AppConstants.primaryColorLight),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Good ${_getGreeting()}!',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Consumer<AuthProvider>(
                    builder: (context, authProvider, child) {
                      return Text(
                        authProvider.userRole ?? 'User',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ],
              ),
              Row(
                children: [
                  Image.asset('assets/icons/aclcLOGO.png', height: 50),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }

  Widget _buildPageView() {
    return PageView(
      controller: _pageController,
      physics: const NeverScrollableScrollPhysics(),
      onPageChanged: (index) {
        // We need to map the page index back to the bottom bar index
        // Page 0 (Dashboard) -> Bar 0 (Admin)
        // Page 1 (Inventory) -> Bar 1 (Admin)
        // Page 2 (Users) -> Bar 2 (Admin)
        // Page 3 (Live Tracking) -> Bar 0 (Student)
        // Page 4 (Borrow) -> Bar 1 (Student)
        // Page 5 (History) -> Bar 2 (Student)
        
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final isStudentOrTeacher = authProvider.userRole == 'Student' ||
            authProvider.userRole == 'Teacher';
            
        int newSelectedIndex;
        if (isStudentOrTeacher) {
          if (index == 3) newSelectedIndex = 0; // Live Tracking
          else if (index == 4) newSelectedIndex = 1; // Borrow
          else if (index == 5) newSelectedIndex = 2; // History
          else return; // Should not happen for students usually
        } else {
          newSelectedIndex = index;
        }

        // Only update state if the index actually changed
        if (newSelectedIndex != _selectedIndex) {
          setState(() {
            _previousIndex = _selectedIndex;
            _selectedIndex = newSelectedIndex;
          });
        }
      },
      children: [
        KeepAliveWrapper(child: _buildDashboardContent()),
        InventoryScreen(
          key: ValueKey('inventory_$_lastRefreshTime'),
          isMobile: true,
        ),
        StaffManagementScreen(
          key: ValueKey('users_$_lastRefreshTime'),
          isMobile: true,
        ),
        KeepAliveWrapper(
          child: LiveTrackingScreen(
            key: ValueKey('tracking_$_lastRefreshTime'),
            isMobile: true,
          ),
        ),
        KeepAliveWrapper(
          child: BorrowScreen(
            key: ValueKey('borrow_$_lastRefreshTime'),
            isMobile: true,
          ),
        ),
        KeepAliveWrapper(
          child: HistoryScreen(
            key: ValueKey('history_$_lastRefreshTime'),
            isMobile: true,
          ),
        ),
      ],
    );
  }

  Widget _buildDashboardContent() {
    return RefreshIndicator(
      onRefresh: () => _loadDashboardData(useSkeleton: false),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick Stats Section
            _buildQuickStatsSection(),
            const SizedBox(height: 24),

            // Recent Activity Section
            _buildRecentActivitySection(),

            const SizedBox(height: 100), // Space for bottom bar
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(
            'Overview',
            style: TextStyle(
              fontSize: widget.isMobile ? 24 : 28,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildModernSummaryCard(
                'Total Items',
                _totalItems.toString(),
                Icons.inventory,
                const Color(0xFF338AFF),
                'Items in inventory',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildModernSummaryCard(
                'Active Users',
                _activeStaff.toString(),
                Icons.check_circle,
                const Color(0xFF10B981),
                'All systems operational',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildModernSummaryCard(
                'Borrowed Items',
                _borrowedItems.toString(),
                Icons.access_time,
                const Color(0xFF338AFF),
                'Currently in use',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildModernSummaryCard(
                'Categories',
                _categoryCount.toString(),
                Icons.category,
                const Color(0xFF338AFF),
                'Active categories',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildModernSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _handleCardTap(title),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceBright,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
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
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.8),
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.6),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivitySection() {
    return _buildModernRecentBorrowedTable();
  }

  Widget _buildModernRecentBorrowedTable() {
    return Container(
      padding: EdgeInsets.all(widget.isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceBright,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Responsive header
          widget.isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recently Borrowed Items',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.9),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Latest borrowing transactions',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(AppConstants.secondaryColor),
                              Color(0xFF1E6BFF),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextButton.icon(
                          onPressed: () {
                            // Show menu for history access
                            _showHistoryMenu(context);
                          },
                          icon: const Icon(
                            Icons.history,
                            size: 18,
                            color: Colors.white,
                          ),
                          label: const Text(
                            'View All',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Recently Borrowed Items',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.9),
                              letterSpacing: -0.5,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Latest borrowing transactions',
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.6),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(AppConstants.secondaryColor),
                            Color(0xFF1E6BFF),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextButton.icon(
                        onPressed: () {
                          // Show menu for history access
                          _showHistoryMenu(context);
                        },
                        icon: const Icon(
                          Icons.history,
                          size: 18,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'View All',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
          SizedBox(height: widget.isMobile ? 16 : 24),
          RepaintBoundary(
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _recentBorrowedItems.length,
              itemBuilder: (context, index) =>
                  _buildModernActivityCard(_recentBorrowedItems[index], index),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernActivityCard(Map<String, dynamic> item, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => _showItemDetails(item),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      item['item'],
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.9),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(item['remarks']).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _getStatusColor(
                          item['remarks'],
                        ).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      item['remarks'],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _getStatusColor(item['remarks']),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                item['borrowerRole'] == 'Student' ? Icons.school : Icons.person,
                item['borrowerRole'] == 'Teacher'
                    ? 'Teacher'
                    : (item['borrowerRole'] ?? 'Borrower'),
                item['occupiedBy'],
              ),
              const SizedBox(height: 8),
              _buildInfoRow(Icons.room, 'Room', item['room']),
              const SizedBox(height: 8),
              _buildInfoRow(Icons.calendar_today, 'Date', item['dateTime']),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.9),
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
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
      case 'returned':
        return const Color(0xFF10B981); // Green
      case 'in use':
        return Theme.of(context).colorScheme.primary; // Primary color
      case 'damaged':
        return const Color(0xFFEF4444); // Red
      case 'for repair':
        return const Color(0xFFF59E0B); // Orange
      default:
        return Theme.of(
          context,
        ).colorScheme.onSurface.withOpacity(0.6); // Theme-aware gray
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
            const Text('Item Details'),
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
              backgroundColor: const Color(0xFF10B981),
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
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color:
                    color ??
                    Theme.of(context).colorScheme.onSurface.withOpacity(0.9),
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
              SnackbarHelper.showSuccessSnackBar(
                context,
                '${item['item']} has been returned successfully!',
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm Return'),
          ),
        ],
      ),
    );
  }

  void _showHistoryMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              // Menu title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Icon(
                      Icons.history,
                      color: Theme.of(context).colorScheme.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'History',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // History option
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceBright,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).pop(); // Close the menu first
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              const HistoryScreen(isMobile: true),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.history_outlined,
                              color: Theme.of(context).colorScheme.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Borrowing History',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w500,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface,
                                      ),
                                ),
                                Text(
                                  'View all borrowing transactions',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withOpacity(0.7),
                                      ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _handleCardTap(String cardTitle) {
    int targetIndex;
    switch (cardTitle) {
      case 'Total Items':
        targetIndex = 1; // Navigate to inventory screen
        break;
      case 'Active Users':
        // User management is no longer in bottom nav
        return;
      case 'Borrowed Items':
        // Show menu for history access
        _showHistoryMenu(context);
        return;
      case 'Categories':
        targetIndex =
            1; // Navigate to inventory screen (categories are part of inventory)
        break;
      default:
        return; // Do nothing for unknown cards
    }

    setState(() {
      _previousIndex = _selectedIndex;
      _selectedIndex = targetIndex;
    });

    _pageController.jumpToPage(targetIndex);
  }

  void _showMenu(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isStaff = authProvider.userRole == 'Staff';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
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
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Menu title
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Icon(
                          Icons.menu,
                          color: Theme.of(context).colorScheme.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Menu',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Profile section
                  _buildMenuProfileSection(context),
                  const SizedBox(height: 16),

                  // Menu items section
                  _buildMenuItemsSection(context, isStaff),
                  const SizedBox(height: 20),
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
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceBright,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: const Icon(Icons.person, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      authProvider.username ?? 'User',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      authProvider.userEmail ?? 'Logged in successfully',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.7),
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

  Widget _buildMenuItemsSection(BuildContext context, bool isStaff) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isStudentOrTeacher = authProvider.userRole == 'Student' ||
        authProvider.userRole == 'Teacher';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _buildMenuItem(
            context,
            icon: Icons.settings_outlined,
            title: 'Settings',
            subtitle: 'App preferences and configuration',
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
          if (!isStudentOrTeacher) ...[ 
            const SizedBox(height: 12),
            _buildMenuItem(
              context,
              icon: Icons.history_outlined,
              title: 'History',
              subtitle: 'View borrowing history',
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const HistoryScreen(isMobile: true),
                  ),
                );
              },
            ),
          ],
          if (!isStudentOrTeacher) ...[ 
            const SizedBox(height: 12),
            _buildMenuItem(
              context,
              icon: Icons.school_outlined,
              title: 'Registered Modules',
              subtitle: 'View all registered modules',
              onTap: () async {
                Navigator.of(context).pop();
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        const RegisteredModulesScreen(isMobile: true),
                  ),
                );
                _handleRefreshNeeded();
              },
            ),
          ],
          if (!isStaff && !isStudentOrTeacher) ...[
            const SizedBox(height: 12),
            _buildMenuItem(
              context,
              icon: Icons.archive_outlined,
              title: 'Archive',
              subtitle: 'View archived items',
              onTap: () async {
                Navigator.of(context).pop();
                await Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (context) => const ArchiveScreen()),
                );
                _handleRefreshNeeded();
              },
            ),
          ],
          const SizedBox(height: 12),
          _buildMenuItem(
            context,
            icon: Icons.logout_outlined,
            title: 'Logout',
            subtitle: 'Sign out of your account',
            onTap: () {
              Navigator.of(context).pop();
              _showLogoutDialog(context);
            },
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
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDestructive
                      ? Colors.red.withOpacity(0.1)
                      : Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: isDestructive
                      ? Colors.red
                      : Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: isDestructive
                            ? Colors.red
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: isDestructive
                    ? Colors.red
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
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
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  final authProvider = context.read<AuthProvider>();
                  await authProvider.logout();
                  if (context.mounted) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    SnackbarHelper.showErrorSnackBar(context, 'Logout failed: $e');
                  }
                }
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  @override
  bool get wantKeepAlive => true;
}
