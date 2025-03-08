import 'package:flutter/material.dart';
import 'package:sys/utils/app_theme.dart';

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  @override
  void initState() {
    super.initState();
  }

  void _navigateToTab(int index) {
    // Find the parent widget that can handle tab navigation
    final ScaffoldState? scaffold = Scaffold.maybeOf(context);
    if (scaffold == null) return;

    // Get the parent Navigator
    final NavigatorState? navigator = Navigator.maybeOf(context);
    if (navigator == null) return;

    // Find the parent HomeScreen and update its state
    final ancestorState = context.findAncestorStateOfType<State>();
    if (ancestorState != null) {
      // This is a simplified approach - in a real app, you'd use a more robust method
      // like Provider, Riverpod, or other state management solutions
      final setState = ancestorState.setState;
      if (setState != null) {
        setState(() {
          // This assumes the parent has a _selectedIndex field
          // In a real app, you'd use a proper state management solution
          try {
            ancestorState.widget.runtimeType.toString().contains('HomeScreen');
            // ignore: invalid_use_of_protected_member
            setState(() {
              // This is a hack and not recommended in production code
              // In a real app, use proper state management
              final field = ancestorState.runtimeType
                  .toString()
                  .contains('_selectedIndex');
              if (field) {
                // ignore: avoid_dynamic_calls
                (ancestorState as dynamic)._selectedIndex = index;
              }
            });
          } catch (e) {
            // Fallback to a simpler approach
            print('Navigation error: $e');
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          // Refresh functionality removed as we don't load appointments anymore
        },
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 220,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.primaryColor,
                        Color(0xFF2A4DA6), // Slightly lighter blue
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Decorative elements
                      Positioned(
                        right: -50,
                        bottom: -50,
                        child: Icon(
                          Icons.content_cut,
                          size: 200,
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      Positioned(
                        left: -30,
                        top: -30,
                        child: Icon(
                          Icons.circle,
                          size: 100,
                          color: Colors.white.withOpacity(0.05),
                        ),
                      ),
                      // Content
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 40),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.content_cut,
                                color: AppTheme.primaryColor,
                                size: 28,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Book your next appointment today!',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // title: const Text('Home'),
                centerTitle: true,
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    // Refresh functionality removed
                  },
                  tooltip: 'Refresh',
                ),
              ],
            ),
            // Only keeping the Popular Services section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('Popular Services'),
                    const SizedBox(height: 16),
                    _buildPopularServiceCard(
                      title: 'Classic Haircut',
                      description:
                          'Traditional haircut with scissors and clippers',
                      price: 25.0,
                      duration: 30,
                      iconData: Icons.content_cut,
                    ),
                    _buildPopularServiceCard(
                      title: 'Beard Trim',
                      description: 'Precision beard trimming and shaping',
                      price: 15.0,
                      duration: 20,
                      iconData: Icons.face,
                    ),
                    _buildPopularServiceCard(
                      title: 'Deluxe Package',
                      description:
                          'Premium service including haircut, beard trim, and more',
                      price: 75.0,
                      duration: 90,
                      iconData: Icons.spa,
                    ),
                  ],
                ),
              ),
            ),
            // Bottom padding
            const SliverToBoxAdapter(
              child: SizedBox(height: 24),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title,
      {String? actionText, VoidCallback? onTap}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (actionText != null && onTap != null)
          TextButton(
            onPressed: onTap,
            child: Text(actionText),
          ),
      ],
    );
  }

  Widget _buildPopularServiceCard({
    required String title,
    required String description,
    required double price,
    required int duration,
    required IconData iconData,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                iconData,
                color: AppTheme.primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: AppTheme.textSecondaryColor,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '\$$price',
                        style: TextStyle(
                          color: AppTheme.secondaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        '$duration min',
                        style: TextStyle(
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
