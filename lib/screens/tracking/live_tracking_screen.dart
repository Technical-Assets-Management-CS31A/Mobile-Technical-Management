import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'dart:async';

class LiveTrackingScreen extends StatefulWidget {
  const LiveTrackingScreen({super.key, this.isMobile = true});

  final bool isMobile;

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  Timer? _timer;
  DateTime _currentTime = DateTime.now();
  
  // Example data - Replace with API calls later
  final List<Map<String, dynamic>> _currentBorrowedItems = [
    {
      'id': '1',
      'itemName': 'Digital Multimeter',
      'serialNumber': 'DMM-2024-001',
      'borrowedAt': DateTime.now().subtract(const Duration(hours: 2, minutes: 30)),
      'dueAt': DateTime.now().add(const Duration(hours: 5, minutes: 30)),
      'currentLocation': 'Lab 202',
      'previousLocation': 'Storage Room A',
      'status': 'In Use',
      'imageUrl': null,
    },
    {
      'id': '2',
      'itemName': 'Oscilloscope',
      'serialNumber': 'OSC-2024-015',
      'borrowedAt': DateTime.now().subtract(const Duration(hours: 1, minutes: 15)),
      'dueAt': DateTime.now().add(const Duration(hours: 6, minutes: 45)),
      'currentLocation': 'Lab 202',
      'previousLocation': 'Storage Room B',
      'status': 'In Use',
      'imageUrl': null,
    },
  ];

  final List<Map<String, dynamic>> _recentActivity = [
    {
      'action': 'Moved to Lab 202',
      'item': 'Digital Multimeter',
      'timestamp': DateTime.now().subtract(const Duration(minutes: 15)),
      'icon': CupertinoIcons.location_fill,
      'color': Colors.blue,
    },
    {
      'action': 'Item Borrowed',
      'item': 'Oscilloscope',
      'timestamp': DateTime.now().subtract(const Duration(hours: 1, minutes: 15)),
      'icon': CupertinoIcons.checkmark_circle_fill,
      'color': Colors.green,
    },
    {
      'action': 'Moved to Lab 202',
      'item': 'Oscilloscope',
      'timestamp': DateTime.now().subtract(const Duration(hours: 1, minutes: 10)),
      'icon': CupertinoIcons.location_fill,
      'color': Colors.blue,
    },
    {
      'action': 'Item Borrowed',
      'item': 'Digital Multimeter',
      'timestamp': DateTime.now().subtract(const Duration(hours: 2, minutes: 30)),
      'icon': CupertinoIcons.checkmark_circle_fill,
      'color': Colors.green,
    },
  ];

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
  }

  String _formatTimeRemaining(DateTime dueDate) {
    final difference = dueDate.difference(_currentTime);
    
    if (difference.isNegative) {
      return 'OVERDUE';
    }
    
    final hours = difference.inHours;
    final minutes = difference.inMinutes.remainder(60);
    final seconds = difference.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  Color _getTimeRemainingColor(DateTime dueDate) {
    final difference = dueDate.difference(_currentTime);
    
    if (difference.isNegative) {
      return Colors.red;
    } else if (difference.inHours < 1) {
      return Colors.orange;
    } else if (difference.inHours < 3) {
      return Colors.amber;
    } else {
      return Colors.green;
    }
  }

  void _showScanDialog() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      Theme.of(context).colorScheme.primary.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  CupertinoIcons.qrcode_viewfinder,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Quick Scan',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Scan an item tag to quickly check in/out or update location',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // TODO: Implement QR/NFC scanning
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Scanner will be implemented with API integration'),
                        backgroundColor: Colors.blue,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Open Scanner',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
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
      backgroundColor: const Color(0xFFF8F9FA),
      body: RefreshIndicator(
        onRefresh: () async {
          // TODO: Implement API refresh
          await Future.delayed(const Duration(seconds: 1));
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Data refreshed'),
                duration: Duration(seconds: 1),
              ),
            );
          }
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Page Title
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(context).colorScheme.primary,
                                Theme.of(context).colorScheme.primary.withBlue(255),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            CupertinoIcons.location_fill,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Live Tracking',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1A1A1A),
                                  letterSpacing: -0.5,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Real-time item monitoring',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF6B7280),
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Current Items Section
                    if (_currentBorrowedItems.isEmpty)
                      _buildEmptyState()
                    else
                      ..._currentBorrowedItems.map((item) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _buildCurrentItemCard(item),
                          )),

                    const SizedBox(height: 8),

                    // Recent Activity Section
                    _buildRecentActivitySection(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showScanDialog,
        backgroundColor: Theme.of(context).colorScheme.primary,
        icon: const Icon(CupertinoIcons.qrcode_viewfinder, color: Colors.white),
        label: const Text(
          'Quick Scan',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentItemCard(Map<String, dynamic> item) {
    final timeRemaining = _formatTimeRemaining(item['dueAt']);
    final timeColor = _getTimeRemainingColor(item['dueAt']);
    final isOverdue = item['dueAt'].isBefore(_currentTime);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Colors.grey.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with live indicator
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.primary.withBlue(255),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    CupertinoIcons.cube_box_fill,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Currently Holding',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item['itemName'],
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                // Live indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.4),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'LIVE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Serial Number
                Row(
                  children: [
                    Icon(
                      CupertinoIcons.barcode,
                      size: 18,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Serial: ${item['serialNumber']}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Location Badge
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.blue.shade200,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          CupertinoIcons.location_solid,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Current Location',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item['currentLocation'],
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1A1A1A),
                                letterSpacing: -0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        CupertinoIcons.arrow_right_circle_fill,
                        color: Colors.blue.shade400,
                        size: 24,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Due Date Countdown
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: timeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: timeColor.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: timeColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          isOverdue
                              ? CupertinoIcons.exclamationmark_triangle_fill
                              : CupertinoIcons.clock_fill,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isOverdue ? 'OVERDUE!' : 'Time Remaining',
                              style: TextStyle(
                                fontSize: 12,
                                color: timeColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              timeRemaining,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: timeColor,
                                letterSpacing: -0.5,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          // TODO: Implement return item
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Return feature coming soon'),
                            ),
                          );
                        },
                        icon: const Icon(CupertinoIcons.arrow_turn_up_left, size: 18),
                        label: const Text('Return'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          // TODO: Implement view details
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Details view coming soon'),
                            ),
                          );
                        },
                        icon: const Icon(CupertinoIcons.info_circle, size: 18),
                        label: const Text('Details'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
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
        ],
      ),
    );
  }

  Widget _buildRecentActivitySection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  CupertinoIcons.time,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Recent Activity',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _recentActivity.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final activity = _recentActivity[index];
              return _buildActivityItem(activity);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> activity) {
    final timestamp = activity['timestamp'] as DateTime;
    final timeAgo = _formatTimeAgo(timestamp);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (activity['color'] as Color).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              activity['icon'] as IconData,
              color: activity['color'] as Color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity['action'],
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  activity['item'],
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            timeAgo,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              CupertinoIcons.cube_box,
              size: 48,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'No Active Borrowings',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You don\'t have any items checked out right now',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime timestamp) {
    final difference = _currentTime.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
