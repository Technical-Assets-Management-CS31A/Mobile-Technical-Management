import 'package:flutter/material.dart';
import 'items_archive_screen.dart';
import 'users_archive_screen.dart';

class ArchiveScreen extends StatefulWidget {
  const ArchiveScreen({super.key});

  @override
  State<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends State<ArchiveScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Archive'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Theme.of(context).colorScheme.onPrimary,
          labelColor: Theme.of(context).colorScheme.onPrimary,
          unselectedLabelColor: Theme.of(
            context,
          ).colorScheme.onPrimary.withOpacity(0.7),
          tabAlignment: TabAlignment.fill,
          isScrollable: false,
          labelPadding: EdgeInsets.zero,
          indicatorPadding: EdgeInsets.zero,
          tabs: const [
            Tab(
              height: 48,
              icon: Icon(Icons.inventory_2_outlined, size: 20),
              text: 'Items',
            ),
            Tab(
              height: 48,
              icon: Icon(Icons.people_outline, size: 20),
              text: 'Users',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [ItemsArchiveScreen(), UsersArchiveScreen()],
      ),
    );
  }
}
