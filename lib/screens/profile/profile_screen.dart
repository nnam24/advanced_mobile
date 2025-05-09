import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../widgets/animated_background.dart';
import '../auth/login_screen.dart';
import '../subscription/subscription_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Fetch subscription data when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchSubscriptionData();
      FocusScope.of(context).requestFocus(_focusNode);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Chỉ gọi API khi màn hình được tạo lần đầu, không gọi mỗi khi dependencies thay đổi
    // Việc này sẽ tránh gọi API liên tục
  }

  // Thêm phương thức mới để gọi API và xử lý lỗi
  Future<void> _fetchSubscriptionData() async {
    try {
      await Provider.of<SubscriptionProvider>(context, listen: false).fetchCurrentSubscription();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load subscription data: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final subscriptionProvider = Provider.of<SubscriptionProvider>(context);
    final user = authProvider.currentUser;
    final subscription = subscriptionProvider.currentSubscription;

    return Focus(
      focusNode: _focusNode,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: RefreshIndicator(
          onRefresh: _fetchSubscriptionData,
          child: Stack(
            children: [
              const AnimatedBackground(),
              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile Header
                      Center(
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                              child: user?.photoUrl != null && user!.photoUrl.isNotEmpty
                                  ? ClipRRect(
                                borderRadius: BorderRadius.circular(50),
                                child: Image.network(
                                  user.photoUrl,
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      Icons.person,
                                      size: 50,
                                      color: Theme.of(context).colorScheme.primary,
                                    );
                                  },
                                ),
                              )
                                  : Icon(
                                Icons.person,
                                size: 50,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              user?.name ?? 'User',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user?.email ?? 'email@example.com',
                              style: TextStyle(
                                fontSize: 16,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: subscriptionProvider.isLoading
                                    ? Colors.grey.withOpacity(0.2)
                                    : _getPlanColor(subscription?.name ?? 'basic').withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: subscriptionProvider.isLoading
                                  ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                                  : Text(
                                _getPlanName(subscription?.name ?? 'basic'),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _getPlanColor(subscription?.name ?? 'basic'),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Account Section
                      _buildSectionHeader(context, 'Account'),
                      const SizedBox(height: 8),
                      _buildProfileCard(
                        context,
                        [
                          _buildProfileItem(
                            context,
                            Icons.edit,
                            'Edit Profile',
                            'Update your personal information',
                                () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const EditProfileScreen(),
                                ),
                              );
                            },
                          ),
                          const Divider(),
                          _buildProfileItem(
                            context,
                            Icons.token,
                            'Token Balance',
                            '${user?.tokenBalance ?? 0} tokens available',
                                () {
                              // Show token details
                            },
                          ),
                          const Divider(),
                          _buildProfileItem(
                            context,
                            Icons.upgrade,
                            'Upgrade Plan',
                            'Current plan: ${subscriptionProvider.isLoading ? 'Loading...' : _getPlanName(subscription?.name ?? 'basic')}',
                                () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SubscriptionScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Preferences Section
                      _buildSectionHeader(context, 'Preferences'),
                      const SizedBox(height: 8),
                      _buildProfileCard(
                        context,
                        [
                          _buildProfileItem(
                            context,
                            Icons.dark_mode,
                            'Theme',
                            'Dark mode / Light mode',
                                () {
                              // Toggle theme
                            },
                          ),
                          const Divider(),
                          _buildProfileItem(
                            context,
                            Icons.notifications,
                            'Notifications',
                            'Manage notification settings',
                                () {
                              // Notification settings
                            },
                          ),
                          const Divider(),
                          _buildProfileItem(
                            context,
                            Icons.language,
                            'Language',
                            'English (US)',
                                () {
                              // Language settings
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Support Section
                      _buildSectionHeader(context, 'Support'),
                      const SizedBox(height: 8),
                      _buildProfileCard(
                        context,
                        [
                          _buildProfileItem(
                            context,
                            Icons.help_outline,
                            'Help Center',
                            'Get help with using the app',
                                () {
                              // Help center
                            },
                          ),
                          const Divider(),
                          _buildProfileItem(
                            context,
                            Icons.privacy_tip_outlined,
                            'Privacy Policy',
                            'Read our privacy policy',
                                () {
                              // Privacy policy
                            },
                          ),
                          const Divider(),
                          _buildProfileItem(
                            context,
                            Icons.description_outlined,
                            'Terms of Service',
                            'Read our terms of service',
                                () {
                              // Terms of service
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Logout Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: authProvider.isLoading
                              ? null
                              : () {
                            _showLogoutConfirmation(context, authProvider);
                          },
                          icon: authProvider.isLoading
                              ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                              : const Icon(Icons.logout),
                          label: Text(authProvider.isLoading ? 'Logging out...' : 'Logout'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            disabledBackgroundColor: Colors.red.withOpacity(0.6),
                            disabledForegroundColor: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // App Version
                      Center(
                        child: Text(
                          'Jarvis AI v1.0.0',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Close the dialog first
              Navigator.of(dialogContext).pop();

              // Show loading indicator
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 16),
                        Text('Logging out...'),
                      ],
                    ),
                    duration: Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }

              // Call the API logout method
              try {
                await authProvider.logout();

                // Use a more direct approach to navigate to login screen
                if (context.mounted) {
                  // Get the navigator state at the root level
                  final navigator = Navigator.of(context, rootNavigator: true);

                  // Navigate to login screen and remove all previous routes
                  navigator.pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                  );
                }
              } catch (e) {
                // Show error if logout fails
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Logout failed: ${e.toString()}'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildProfileItem(
      BuildContext context,
      IconData icon,
      String title,
      String subtitle,
      VoidCallback onTap,
      ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 12.0,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: Theme.of(context).colorScheme.primary,
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
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  Color _getPlanColor(String planId) {
    switch (planId) {
      case 'basic':
        return Colors.grey;
      case 'starter':
        return Colors.blue;
      case 'pro':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _getPlanName(String planId) {
    switch (planId) {
      case 'basic':
        return 'Free Plan';
      case 'starter':
        return 'Starter Plan';
      case 'pro':
        return 'Pro Plan';
      default:
        return 'Unknown Plan';
    }
  }
}
