import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../../../core/theme/app_colors.dart';
import '../../../shared/services/theme_service.dart';
import '../../../shared/services/user_service.dart';
import '../../../shared/services/item_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
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
                _buildProfileHeader(context, userService, user?.name ?? 'User', user?.email ?? '', user?.avatarUrl),
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

  Widget _buildProfileHeader(BuildContext context, UserService userService, String name, String email, String? avatarUrl) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GestureDetector(
              onTap: () => _showImagePickerOptions(context, userService),
              child: Stack(
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      gradient: avatarUrl == null ? AppColors.primaryGradient : null,
                      shape: BoxShape.circle,
                      image: avatarUrl != null
                          ? DecorationImage(
                              image: FileImage(File(avatarUrl)),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: avatarUrl == null
                        ? Center(
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : 'U',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 40,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          )
                        : null,
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

  void _showImagePickerOptions(BuildContext context, UserService userService) {
    final theme = Theme.of(context);
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Change Profile Picture',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.camera_alt_rounded,
                    color: theme.colorScheme.primary,
                  ),
                ),
                title: const Text('Take Photo'),
                subtitle: const Text('Use your camera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera, userService);
                },
              ),
              ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.photo_library_rounded,
                    color: theme.colorScheme.secondary,
                  ),
                ),
                title: const Text('Choose from Gallery'),
                subtitle: const Text('Select an existing photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery, userService);
                },
              ),
              if (userService.currentUser?.avatarUrl != null)
                ListTile(
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.delete_rounded,
                      color: Colors.red,
                    ),
                  ),
                  title: const Text('Remove Photo'),
                  subtitle: const Text('Use default avatar'),
                  onTap: () {
                    Navigator.pop(context);
                    _removeProfilePicture(userService);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source, UserService userService) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        // Save to app's documents directory
        final directory = await getApplicationDocumentsDirectory();
        final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}${path.extension(pickedFile.path)}';
        final savedPath = path.join(directory.path, fileName);
        
        // Copy file to permanent location
        final File newImage = await File(pickedFile.path).copy(savedPath);
        
        // Delete old profile picture if exists
        final oldAvatarUrl = userService.currentUser?.avatarUrl;
        if (oldAvatarUrl != null) {
          final oldFile = File(oldAvatarUrl);
          if (await oldFile.exists()) {
            await oldFile.delete();
          }
        }
        
        // Update user profile
        await userService.updateProfile(avatarUrl: newImage.path);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Profile picture updated'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _removeProfilePicture(UserService userService) async {
    try {
      final oldAvatarUrl = userService.currentUser?.avatarUrl;
      if (oldAvatarUrl != null) {
        final oldFile = File(oldAvatarUrl);
        if (await oldFile.exists()) {
          await oldFile.delete();
        }
      }
      
      await userService.updateProfile(avatarUrl: '');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile picture removed'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
