import 'package:flutter/material.dart';
import '../models/medicine_reminder_model.dart';
import '../services/medicine_reminder_service.dart';

class MedicineReminderBottomSheet extends StatefulWidget {
  final String itemId;
  final String itemName;
  final MedicineReminder? existingReminder;

  const MedicineReminderBottomSheet({
    super.key,
    required this.itemId,
    required this.itemName,
    this.existingReminder,
  });

  static Future<void> show(
    BuildContext context, {
    required String itemId,
    required String itemName,
    MedicineReminder? existingReminder,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => MedicineReminderBottomSheet(
        itemId: itemId,
        itemName: itemName,
        existingReminder: existingReminder,
      ),
    );
  }

  @override
  State<MedicineReminderBottomSheet> createState() =>
      _MedicineReminderBottomSheetState();
}

class _MedicineReminderBottomSheetState
    extends State<MedicineReminderBottomSheet> {
  final MedicineReminderService _reminderService = MedicineReminderService();
  late MedicineReminder _reminder;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _reminder = widget.existingReminder ??
        _reminderService.createDefaultReminder(
          itemId: widget.itemId,
          itemName: widget.itemName,
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.medication_rounded, color: colorScheme.primary),
                    const SizedBox(width: 12),
                    Text(
                      'Medicine Alarm',
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
                  Icon(Icons.medical_services_rounded, color: colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.itemName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Dosage',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: colorScheme.outline),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: _reminder.dosage > 1
                              ? () {
                                  setState(() {
                                    _reminder = _reminder.copyWith(
                                      dosage: _reminder.dosage - 1,
                                    );
                                  });
                                }
                              : null,
                          icon: const Icon(Icons.remove),
                          iconSize: 20,
                        ),
                        Expanded(
                          child: Text(
                            '${_reminder.dosage}',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _reminder = _reminder.copyWith(
                                dosage: _reminder.dosage + 1,
                              );
                            });
                          },
                          icon: const Icon(Icons.add),
                          iconSize: 20,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: colorScheme.outline),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButton<String>(
                      value: _reminder.dosageUnit,
                      isExpanded: true,
                      underline: const SizedBox(),
                      items: MedicineReminderService.dosageUnits
                          .map((unit) => DropdownMenuItem(
                                value: unit,
                                child: Text(unit),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _reminder = _reminder.copyWith(dosageUnit: value);
                          });
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Schedule',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            ..._reminder.schedules.asMap().entries.map((entry) {
              final index = entry.key;
              final schedule = entry.value;
              return _buildScheduleCard(theme, colorScheme, schedule, index);
            }),
            const SizedBox(height: 24),
            Row(
              children: [
                if (widget.existingReminder != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _deleteReminder(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colorScheme.error,
                        side: BorderSide(color: colorScheme.error),
                      ),
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Delete'),
                    ),
                  ),
                if (widget.existingReminder != null) const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _hasEnabledSchedule() ? () => _saveReminder() : null,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.alarm_add),
                    label: Text(widget.existingReminder != null
                        ? 'Update Alarm'
                        : 'Set Alarm'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleCard(
    ThemeData theme,
    ColorScheme colorScheme,
    MedicineSchedule schedule,
    int index,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: schedule.isEnabled
            ? colorScheme.primaryContainer.withOpacity(0.2)
            : colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: schedule.isEnabled
              ? colorScheme.primary.withOpacity(0.3)
              : colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: schedule.isEnabled
                    ? colorScheme.primary.withOpacity(0.1)
                    : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                schedule.icon,
                color: schedule.isEnabled
                    ? colorScheme.primary
                    : colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
            title: Text(
              schedule.mealTime == MealTime.morning
                  ? 'Morning'
                  : schedule.mealTime == MealTime.lunch
                      ? 'Lunch'
                      : 'Dinner',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: schedule.isEnabled
                    ? colorScheme.onSurface
                    : colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
            trailing: Switch(
              value: schedule.isEnabled,
              onChanged: (value) => _toggleSchedule(index, value),
            ),
          ),
          if (schedule.isEnabled) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: _buildTimeSelector(
                      theme,
                      colorScheme,
                      schedule,
                      index,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMedicineTimeSelector(
                      theme,
                      colorScheme,
                      schedule,
                      index,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeSelector(
    ThemeData theme,
    ColorScheme colorScheme,
    MedicineSchedule schedule,
    int index,
  ) {
    return InkWell(
      onTap: () => _selectTime(index),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colorScheme.outline.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.access_time, size: 18, color: colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              schedule.timeString,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicineTimeSelector(
    ThemeData theme,
    ColorScheme colorScheme,
    MedicineSchedule schedule,
    int index,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outline.withOpacity(0.5)),
      ),
      child: DropdownButton<MedicineTime>(
        value: schedule.medicineTime,
        isExpanded: true,
        underline: const SizedBox(),
        items: [
          DropdownMenuItem(
            value: MedicineTime.before,
            child: Text('Before meal', style: theme.textTheme.bodyMedium),
          ),
          DropdownMenuItem(
            value: MedicineTime.after,
            child: Text('After meal', style: theme.textTheme.bodyMedium),
          ),
        ],
        onChanged: (value) {
          if (value != null) {
            _updateScheduleMedicineTime(index, value);
          }
        },
      ),
    );
  }

  void _toggleSchedule(int index, bool isEnabled) {
    final schedules = List<MedicineSchedule>.from(_reminder.schedules);
    schedules[index] = schedules[index].copyWith(isEnabled: isEnabled);
    setState(() {
      _reminder = _reminder.copyWith(schedules: schedules);
    });
  }

  Future<void> _selectTime(int index) async {
    final schedule = _reminder.schedules[index];
    final time = await showTimePicker(
      context: context,
      initialTime: schedule.time,
    );
    if (time != null) {
      final schedules = List<MedicineSchedule>.from(_reminder.schedules);
      schedules[index] = schedules[index].copyWith(time: time);
      setState(() {
        _reminder = _reminder.copyWith(schedules: schedules);
      });
    }
  }

  void _updateScheduleMedicineTime(int index, MedicineTime medicineTime) {
    final schedules = List<MedicineSchedule>.from(_reminder.schedules);
    schedules[index] = schedules[index].copyWith(medicineTime: medicineTime);
    setState(() {
      _reminder = _reminder.copyWith(schedules: schedules);
    });
  }

  bool _hasEnabledSchedule() {
    return _reminder.schedules.any((s) => s.isEnabled);
  }

  Future<void> _saveReminder() async {
    setState(() => _isLoading = true);

    try {
      if (widget.existingReminder != null) {
        await _reminderService.updateReminder(_reminder);
      } else {
        await _reminderService.addReminder(_reminder);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.existingReminder != null
                  ? 'Medicine alarm updated for ${widget.itemName}'
                  : 'Medicine alarm set for ${widget.itemName}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save alarm: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() => _isLoading = false);
  }

  Future<void> _deleteReminder() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Alarm'),
        content: Text('Delete medicine alarm for ${widget.itemName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        await _reminderService.deleteReminder(_reminder.id);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Medicine alarm deleted for ${widget.itemName}'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete alarm: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
      setState(() => _isLoading = false);
    }
  }
}
