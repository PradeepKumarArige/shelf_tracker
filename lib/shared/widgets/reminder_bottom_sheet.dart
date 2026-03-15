import 'package:flutter/material.dart';
import '../models/item_model.dart';
import '../services/notification_service.dart';

class ReminderBottomSheet extends StatefulWidget {
  final ItemModel item;

  const ReminderBottomSheet({super.key, required this.item});

  static Future<void> show(BuildContext context, ItemModel item) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ReminderBottomSheet(item: item),
    );
  }

  @override
  State<ReminderBottomSheet> createState() => _ReminderBottomSheetState();
}

class _ReminderBottomSheetState extends State<ReminderBottomSheet> {
  final NotificationService _notificationService = NotificationService();
  final Set<int> _selectedDays = {};
  bool _isLoading = false;

  final List<ReminderOption> _reminderOptions = [
    ReminderOption(days: 1, label: '1 day before', icon: Icons.looks_one),
    ReminderOption(days: 2, label: '2 days before', icon: Icons.looks_two),
    ReminderOption(days: 3, label: '3 days before', icon: Icons.looks_3),
    ReminderOption(days: 5, label: '5 days before', icon: Icons.looks_5),
    ReminderOption(days: 7, label: '1 week before', icon: Icons.date_range),
    ReminderOption(days: 14, label: '2 weeks before', icon: Icons.calendar_month),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final daysUntilExpiry = widget.item.daysRemaining;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.notifications_active, color: colorScheme.primary),
                  const SizedBox(width: 12),
                  Text(
                    'Set Reminder',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(widget.item.categoryIcon, color: colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.item.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        daysUntilExpiry > 0
                            ? 'Expires in $daysUntilExpiry days'
                            : daysUntilExpiry == 0
                                ? 'Expires today!'
                                : 'Expired ${-daysUntilExpiry} days ago',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: daysUntilExpiry <= 0
                              ? colorScheme.error
                              : colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Remind me:',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _reminderOptions.map((option) {
              final isAvailable = option.days < daysUntilExpiry;
              final isSelected = _selectedDays.contains(option.days);

              return FilterChip(
                label: Text(option.label),
                avatar: Icon(
                  option.icon,
                  size: 18,
                  color: isSelected
                      ? colorScheme.onPrimary
                      : isAvailable
                          ? colorScheme.primary
                          : colorScheme.onSurface.withOpacity(0.3),
                ),
                selected: isSelected,
                onSelected: isAvailable
                    ? (selected) {
                        setState(() {
                          if (selected) {
                            _selectedDays.add(option.days);
                          } else {
                            _selectedDays.remove(option.days);
                          }
                        });
                      }
                    : null,
                backgroundColor: isAvailable
                    ? colorScheme.surface
                    : colorScheme.surfaceContainerHighest.withOpacity(0.5),
                selectedColor: colorScheme.primary,
                checkmarkColor: colorScheme.onPrimary,
                labelStyle: TextStyle(
                  color: isSelected
                      ? colorScheme.onPrimary
                      : isAvailable
                          ? colorScheme.onSurface
                          : colorScheme.onSurface.withOpacity(0.3),
                ),
              );
            }).toList(),
          ),
          if (daysUntilExpiry <= 1)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: colorScheme.error, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Item expires too soon to set reminders',
                        style: TextStyle(
                          color: colorScheme.onErrorContainer,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _cancelReminders(),
                  child: const Text('Cancel Reminders'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _selectedDays.isNotEmpty ? () => _setReminders() : null,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Set Reminders'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _setReminders() async {
    setState(() => _isLoading = true);

    try {
      final hasPermission = await _notificationService.requestPermissions();
      if (!hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enable notifications in settings'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      await _notificationService.cancelItemReminders(widget.item.id);

      await _notificationService.scheduleMultipleReminders(
        item: widget.item,
        daysBefore: _selectedDays.toList(),
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Reminder${_selectedDays.length > 1 ? 's' : ''} set for ${widget.item.name}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to set reminder: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() => _isLoading = false);
  }

  Future<void> _cancelReminders() async {
    setState(() => _isLoading = true);

    try {
      await _notificationService.cancelItemReminders(widget.item.id);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reminders cancelled for ${widget.item.name}'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel reminders: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() => _isLoading = false);
  }
}

class ReminderOption {
  final int days;
  final String label;
  final IconData icon;

  ReminderOption({
    required this.days,
    required this.label,
    required this.icon,
  });
}
