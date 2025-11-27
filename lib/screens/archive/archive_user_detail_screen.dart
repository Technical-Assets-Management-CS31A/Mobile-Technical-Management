import 'package:flutter/material.dart';
import '../../models/entities/user.dart';
import '../../services/archive_service.dart';

class ArchiveUserDetailScreen extends StatefulWidget {
  const ArchiveUserDetailScreen({super.key, required this.staff});

  final Staff staff;

  @override
  State<ArchiveUserDetailScreen> createState() =>
      _ArchiveUserDetailScreenState();
}

class _ArchiveUserDetailScreenState extends State<ArchiveUserDetailScreen> {
  final ArchiveService _archiveService = ArchiveService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeService();
  }

  Future<void> _initializeService() async {
    try {
      await _archiveService.initialize();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error initializing service: $e')),
        );
      }
    }
  }

  Future<void> _restoreUser() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _archiveService.restoreUser(widget.staff.id);
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${widget.staff.name} has been restored successfully',
              ),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(
            context,
          ).pop(true); // Return true to indicate user was restored
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to restore ${widget.staff.name}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error restoring user: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _permanentlyDeleteUser() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Theme.of(context).colorScheme.surfaceBright,
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
              Text(
                'Delete User',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.9),
                ),
              ),
              const SizedBox(height: 12),

              // Message
              Text(
                'Are you sure you want to delete ${widget.staff.name}?',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'This action cannot be undone.',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                ),
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
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.outline,
                        ),
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
                      onPressed: () => Navigator.pop(context, true),
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

    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        final success = await _archiveService.permanentlyDeleteUser(
          widget.staff.id,
        );
        if (success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '${widget.staff.name} has been permanently deleted',
                ),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.of(
              context,
            ).pop(true); // Return true to indicate user was deleted
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to delete ${widget.staff.name}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting user: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Widget _buildInfoCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildImageCard({
    required String title,
    required String imageUrl,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceBright,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              imageUrl,
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: double.infinity,
                  height: 200,
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.broken_image,
                        size: 48,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Image not available',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                );
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  width: double.infinity,
                  height: 200,
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  child: Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String? status) {
    if (status == null) {
      return const Color(0xFF718096);
    }
    switch (status.toLowerCase()) {
      case 'online':
        return const Color(0xFF10B981);
      case 'offline':
        return const Color(0xFF6B7280);
      case 'busy':
        return const Color(0xFFF59E0B);
      case 'away':
        return const Color(0xFF3B82F6);
      default:
        return const Color(0xFF718096);
    }
  }

  Color _getUserRoleColor(String? userRole) {
    if (userRole == null) {
      return const Color(0xFF718096);
    }
    switch (userRole.toLowerCase()) {
      case 'superadmin':
        return const Color(0xFFDC2626);
      case 'admin':
        return const Color(0xFF3B82F6); // Blue for admin
      case 'staff':
        return const Color(0xFF10B981); // Green for staff
      default:
        return const Color(0xFF718096);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Archived User Details'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 0,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            )
          else ...[
            IconButton(
              icon: const Icon(Icons.restore),
              onPressed: _restoreUser,
              tooltip: 'Restore User',
            ),
            IconButton(
              icon: const Icon(Icons.delete_forever),
              onPressed: _permanentlyDeleteUser,
              tooltip: 'Permanently Delete',
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    Theme.of(context).colorScheme.primary.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.archive,
                      color: Theme.of(context).colorScheme.primary,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Archived User Details',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This user has been archived and cannot access the system',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Personal Information Section
            Text(
              'Personal Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),

            _buildInfoCard(
              title: 'Full Name',
              value: widget.staff.name,
              icon: Icons.person,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),

            // Account Information Section
            Text(
              'Account Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),

            _buildInfoCard(
              title: 'Username',
              value: widget.staff.username,
              icon: Icons.account_circle,
              color: Theme.of(context).colorScheme.secondary,
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildInfoCard(
                    title: 'User Role',
                    value: widget.staff.userRole,
                    icon: Icons.admin_panel_settings,
                    color: _getUserRoleColor(widget.staff.userRole),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInfoCard(
                    title: 'Status',
                    value: widget.staff.status ?? 'Unknown',
                    icon: Icons.circle,
                    color: _getStatusColor(widget.staff.status),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Contact Information Section
            Text(
              'Contact Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildInfoCard(
                    title: 'Email',
                    value: widget.staff.email,
                    icon: Icons.email,
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInfoCard(
                    title: 'Phone Number',
                    value: widget.staff.phoneNumber ?? 'No Phone',
                    icon: Icons.phone,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Teacher-specific fields (only show for teachers)
            if (widget.staff.userRole == 'Teacher') ...[
              const SizedBox(height: 24),
              Text(
                'Teacher Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              _buildInfoCard(
                title: 'Department',
                value: widget.staff.department ?? 'N/A',
                icon: Icons.business,
                color: Theme.of(context).colorScheme.primary,
              ),
            ],

            // Student-specific fields (only show for students)
            if (widget.staff.userRole == 'Student') ...[
              const SizedBox(height: 24),
              Text(
                'Student Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              
              // Student ID and Course Row
              _buildInfoCard(
                title: 'Course',
                value: widget.staff.course ?? 'N/A',
                icon: Icons.book,
                color: Theme.of(context).colorScheme.secondary,
              ),
              const SizedBox(height: 16),
              
              // Section and Year Row
              Row(
                children: [
                  Expanded(
                    child: _buildInfoCard(
                      title: 'Section',
                      value: widget.staff.section ?? 'N/A',
                      icon: Icons.group,
                      color: Theme.of(context).colorScheme.tertiary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildInfoCard(
                      title: 'Year',
                      value: widget.staff.year ?? 'N/A',
                      icon: Icons.calendar_today,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              Text(
                'Address',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              
              _buildInfoCard(
                title: 'Street',
                value: widget.staff.street ?? 'N/A',
                icon: Icons.location_on,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: _buildInfoCard(
                      title: 'City/Municipality',
                      value: widget.staff.cityMunicipality ?? 'N/A',
                      icon: Icons.location_city,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildInfoCard(
                      title: 'Province',
                      value: widget.staff.province ?? 'N/A',
                      icon: Icons.map,
                      color: Theme.of(context).colorScheme.tertiary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              _buildInfoCard(
                title: 'Postal Code',
                value: widget.staff.postalCode ?? 'N/A',
                icon: Icons.markunread_mailbox,
                color: Theme.of(context).colorScheme.primary,
              ),

              // Student Images Section
              const SizedBox(height: 24),
              Text(
                'Student Images',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              
              // Profile Picture
              if (widget.staff.profilePicture != null && widget.staff.profilePicture!.isNotEmpty) ...[
                _buildImageCard(
                  title: 'Profile Picture',
                  imageUrl: widget.staff.profilePicture!,
                ),
                const SizedBox(height: 16),
              ],
              
              // Student ID Pictures Column
              Column(
                children: [
                  if (widget.staff.frontStudentIdPicture != null && widget.staff.frontStudentIdPicture!.isNotEmpty) ...[
                    _buildImageCard(
                      title: 'Front ID',
                      imageUrl: widget.staff.frontStudentIdPicture!,
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (widget.staff.backStudentIdPicture != null && widget.staff.backStudentIdPicture!.isNotEmpty)
                    _buildImageCard(
                      title: 'Back ID',
                      imageUrl: widget.staff.backStudentIdPicture!,
                    ),
                ],
              ),
            ],
            const SizedBox(height: 24),

            // Date Information Section
            if (widget.staff.createdAt != null ||
                widget.staff.updatedAt != null) ...[
              Text(
                'Date Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  if (widget.staff.createdAt != null) ...[
                    Expanded(
                      child: _buildInfoCard(
                        title: 'Created',
                        value: _formatDate(widget.staff.createdAt!),
                        icon: Icons.calendar_today,
                        color: Colors.brown,
                      ),
                    ),
                    if (widget.staff.updatedAt != null)
                      const SizedBox(width: 16),
                  ],
                  if (widget.staff.updatedAt != null)
                    Expanded(
                      child: _buildInfoCard(
                        title: 'Last Updated',
                        value: _formatDate(widget.staff.updatedAt!),
                        icon: Icons.update,
                        color: Colors.cyan,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),
            ],

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _restoreUser,
                    icon: const Icon(Icons.restore),
                    label: const Text('Restore User'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _permanentlyDeleteUser,
                    icon: const Icon(Icons.delete_forever),
                    label: const Text('Delete Forever'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
