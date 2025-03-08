import 'package:flutter/material.dart';
import 'package:sys/services/auth_service.dart';
import 'package:sys/utils/app_theme.dart';
import 'package:sys/screens/login_screen.dart';
import 'package:sys/screens/edit_profile_screen.dart';
import 'package:sys/screens/payments_screen.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  User? _user;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = await _authService.getCurrentUser();
      setState(() {
        _user = user;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _navigateToEditProfile() async {
    if (_user != null) {
      final result = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => EditProfileScreen(user: _user!),
        ),
      );

      if (result == true) {
        _loadUserData(); // Reload user data after successful update
      }
    }
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About BarberBook'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'BarberBook is your premium barber appointment booking app.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'Our mission is to provide a seamless experience for booking barber appointments. No more waiting in line or making phone calls - book your favorite barber with just a few taps!',
              ),
              const SizedBox(height: 16),
              const Text(
                'Features:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildFeatureItem('Easy appointment booking'),
              _buildFeatureItem('View upcoming and past appointments'),
              _buildFeatureItem('Browse available services'),
              _buildFeatureItem('Manage your profile'),
              _buildFeatureItem('Track payment history'),
              const SizedBox(height: 16),
              const Text(
                'Contact Us:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildContactItem(Icons.email_outlined, 'support@barberbook.com'),
              _buildContactItem(Icons.phone_outlined, '+1 (555) 123-4567'),
              _buildContactItem(
                  Icons.location_on_outlined, '123 Main Street, Anytown, USA'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• '),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.primaryColor),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (result == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        await _authService.logout();

        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to logout. Please try again.'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _user == null
              ? Center(
                  child: Text(
                    'Failed to load user data',
                    style: TextStyle(color: AppTheme.errorColor),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 16),

                      // Profile Avatar
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                        child: Icon(
                          Icons.person,
                          size: 80,
                          color: AppTheme.primaryColor,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // User Name
                      Text(
                        _user!.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // User Email
                      Text(
                        _user!.email,
                        style: TextStyle(
                          fontSize: 16,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Profile Options
                      _buildProfileOption(
                        icon: Icons.person_outline,
                        title: 'Edit Profile',
                        onTap: _navigateToEditProfile,
                      ),

                      _buildProfileOption(
                        icon: Icons.payment_outlined,
                        title: 'Payment History',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const PaymentsScreen(),
                            ),
                          );
                        },
                      ),

                      _buildProfileOption(
                        icon: Icons.info_outline,
                        title: 'About',
                        onTap: _showAboutDialog,
                      ),

                      const SizedBox(height: 16),

                      // Logout Button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _logout,
                          icon: const Icon(Icons.logout),
                          label: const Text('Logout'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.errorColor,
                            side: BorderSide(color: AppTheme.errorColor),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // App Version
                      Text(
                        'Version 1.0.0',
                        style: TextStyle(
                          color: AppTheme.textLightColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.grey.withOpacity(0.2),
        ),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: AppTheme.primaryColor,
        ),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
      ),
    );
  }
}
