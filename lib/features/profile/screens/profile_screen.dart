import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/services/theme_service.dart';
import '../../../shared/services/user_service.dart';
import '../../../shared/services/item_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeService = context.watch<ThemeService>();

    return Consumer<UserService>(
      builder: (context, userService, child) {
        final user = userService.currentUser;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Profile'),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildProfileHeader(context, user?.name ?? 'User', user?.email ?? ''),
                const SizedBox(height: 24),
                _buildSettingsSection(context, themeService, userService),
                const SizedBox(height: 24),
                _buildNotificationSection(context, userService),
                const SizedBox(height: 24),
                _buildDataSection(context),
                const SizedBox(height: 24),
                _buildSupportSection(context),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileHeader(BuildContext context, String name, String email) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: const BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.camera_alt_rounded,
                      color: theme.colorScheme.primary,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              name,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              email,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => _showEditProfileDialog(context),
              child: const Text('Edit Profile'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection(
      BuildContext context, ThemeService themeService, UserService userService) {
    final theme = Theme.of(context);
    final user = userService.currentUser;

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Settings',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Divider(height: 1),
          _buildSettingsTile(
            context,
            icon: Icons.dark_mode_rounded,
            title: 'Dark Mode',
            subtitle: _getThemeModeText(themeService.themeMode),
            trailing: Switch.adaptive(
              value: themeService.isDarkMode,
              onChanged: (_) => themeService.toggleTheme(),
              activeColor: theme.colorScheme.primary,
            ),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.language_rounded,
            title: 'Language',
            subtitle: _getLanguageName(user?.language ?? 'en'),
            onTap: () => _showLanguageDialog(context, userService),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.calendar_today_rounded,
            title: 'Default Expiry Alert',
            subtitle: '${user?.defaultExpiryDays ?? 7} days before',
            onTap: () => _showExpiryAlertDialog(context, userService),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSection(BuildContext context, UserService userService) {
    final theme = Theme.of(context);
    final user = userService.currentUser;

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Notifications',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Divider(height: 1),
          _buildSettingsTile(
            context,
            icon: Icons.notifications_rounded,
            title: 'Push Notifications',
            subtitle: user?.notificationEnabled == true ? 'Enabled' : 'Disabled',
            trailing: Switch.adaptive(
              value: user?.notificationEnabled ?? true,
              onChanged: (value) => userService.updateSettings(
                notificationEnabled: value,
              ),
              activeColor: theme.colorScheme.primary,
            ),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.email_rounded,
            title: 'Email Alerts',
            subtitle: user?.emailAlertsEnabled == true ? 'Enabled' : 'Disabled',
            trailing: Switch.adaptive(
              value: user?.emailAlertsEnabled ?? true,
              onChanged: (value) => userService.updateSettings(
                emailAlertsEnabled: value,
              ),
              activeColor: theme.colorScheme.primary,
            ),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.local_offer_rounded,
            title: 'Deal Notifications',
            subtitle:
                user?.dealNotificationsEnabled == true ? 'Enabled' : 'Disabled',
            trailing: Switch.adaptive(
              value: user?.dealNotificationsEnabled ?? true,
              onChanged: (value) => userService.updateSettings(
                dealNotificationsEnabled: value,
              ),
              activeColor: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataSection(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<ItemService>(
      builder: (context, itemService, child) {
        final deletedCount = itemService.deletedCount;
        
        return Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Data Management',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Divider(height: 1),
              _buildSettingsTile(
                context,
                icon: Icons.delete_outline_rounded,
                title: 'Trash',
                subtitle: deletedCount > 0 ? '$deletedCount items' : 'Empty',
                onTap: () => Navigator.pushNamed(context, '/trash'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSupportSection(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Support',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Divider(height: 1),
          _buildSettingsTile(
            context,
            icon: Icons.help_outline_rounded,
            title: 'Help Center',
            onTap: () {},
          ),
          _buildSettingsTile(
            context,
            icon: Icons.feedback_outlined,
            title: 'Send Feedback',
            onTap: () {},
          ),
          _buildSettingsTile(
            context,
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            onTap: () {},
          ),
          _buildSettingsTile(
            context,
            icon: Icons.info_outline_rounded,
            title: 'About',
            subtitle: 'Version 1.0.0',
            onTap: () => _showAboutDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Icon(
        icon,
        color: theme.colorScheme.primary,
      ),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing:
          trailing ?? (onTap != null ? const Icon(Icons.chevron_right_rounded) : null),
      onTap: onTap,
    );
  }

  String _getThemeModeText(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'System';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
    }
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'en':
        return 'English';
      case 'es':
        return 'Spanish';
      case 'fr':
        return 'French';
      case 'de':
        return 'German';
      default:
        return 'English';
    }
  }

  void _showEditProfileDialog(BuildContext context) {
    final userService = context.read<UserService>();
    final user = userService.currentUser;
    final nameController = TextEditingController(text: user?.name ?? '');
    final emailController = TextEditingController(text: user?.email ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await userService.updateProfile(
                name: nameController.text.trim(),
                email: emailController.text.trim(),
              );
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog(BuildContext context, UserService userService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('English'),
              trailing: userService.currentUser?.language == 'en'
                  ? const Icon(Icons.check)
                  : null,
              onTap: () {
                userService.updateSettings(language: 'en');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Spanish'),
              trailing: userService.currentUser?.language == 'es'
                  ? const Icon(Icons.check)
                  : null,
              onTap: () {
                userService.updateSettings(language: 'es');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('French'),
              trailing: userService.currentUser?.language == 'fr'
                  ? const Icon(Icons.check)
                  : null,
              onTap: () {
                userService.updateSettings(language: 'fr');
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showExpiryAlertDialog(BuildContext context, UserService userService) {
    final days = [3, 5, 7, 14, 30];
    final currentDays = userService.currentUser?.defaultExpiryDays ?? 7;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Expiry Alert'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: days.map((d) {
            return ListTile(
              title: Text('$d days before'),
              trailing: currentDays == d ? const Icon(Icons.check) : null,
              onTap: () {
                userService.updateSettings(defaultExpiryDays: d);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Shelf Tracker',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.inventory_2_rounded,
          color: Colors.white,
          size: 32,
        ),
      ),
      children: [
        const Text(
          'Track expiration dates of your household items and never let anything go to waste!',
        ),
      ],
    );
  }
}
