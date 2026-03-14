import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../shared/models/item_model.dart';
import '../../../shared/widgets/category_chip.dart';
import '../../../shared/services/item_service.dart';
import '../../../core/theme/app_colors.dart';

class AddItemScreen extends StatefulWidget {
  const AddItemScreen({super.key});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();
  final _uuid = const Uuid();

  ItemCategory _selectedCategory = ItemCategory.food;
  DateTime _purchaseDate = DateTime.now();
  DateTime _expiryDate = DateTime.now().add(const Duration(days: 7));
  int _quantity = 1;
  bool _isSaving = false;
  bool _isVoiceInput = false;

  @override
  void initState() {
    super.initState();
    _resetForm();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _processVoiceArguments();
    });
  }

  void _resetForm() {
    _nameController.clear();
    _locationController.clear();
    _notesController.clear();
    _selectedCategory = ItemCategory.food;
    _purchaseDate = DateTime.now();
    _expiryDate = DateTime.now().add(const Duration(days: 7));
    _quantity = 1;
    _isVoiceInput = false;
  }

  void _processVoiceArguments() {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args == null || args is! Map<String, dynamic> || args.isEmpty) {
      return;
    }

    setState(() {
      _isVoiceInput = true;
      
      if (args['name'] != null) {
        _nameController.text = args['name'] as String;
      }
      
      if (args['category'] != null) {
        final categoryStr = args['category'] as String;
        switch (categoryStr.toLowerCase()) {
          case 'food':
            _selectedCategory = ItemCategory.food;
            break;
          case 'grocery':
            _selectedCategory = ItemCategory.grocery;
            break;
          case 'medicine':
            _selectedCategory = ItemCategory.medicine;
            break;
          case 'cosmetics':
            _selectedCategory = ItemCategory.cosmetics;
            break;
        }
      }
      
      if (args['expiryDays'] != null) {
        final days = args['expiryDays'] as int;
        _expiryDate = DateTime.now().add(Duration(days: days));
      }
      
      if (args['quantity'] != null) {
        _quantity = args['quantity'] as int;
      }
      
      if (args['location'] != null) {
        _locationController.text = args['location'] as String;
      }
    });

    if (_nameController.text.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Voice input: "${_nameController.text}" - Review and save'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Item'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveItem,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildScanOption(context),
              const SizedBox(height: 24),
              _buildDividerWithText('Or enter manually'),
              const SizedBox(height: 24),
              _buildNameField(),
              const SizedBox(height: 20),
              _buildCategorySelector(),
              const SizedBox(height: 20),
              _buildDateFields(),
              const SizedBox(height: 20),
              _buildQuantityField(),
              const SizedBox(height: 20),
              _buildLocationField(),
              const SizedBox(height: 20),
              _buildNotesField(),
              const SizedBox(height: 32),
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScanOption(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      children: [
        Expanded(
          child: _ScanOptionCard(
            icon: Icons.qr_code_scanner_rounded,
            title: 'Scan Barcode',
            subtitle: 'Auto-fill product details',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Barcode scanner coming soon!'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ScanOptionCard(
            icon: Icons.receipt_long_rounded,
            title: 'Scan Receipt',
            subtitle: 'Add multiple items',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Receipt scanner coming soon!'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildDividerWithText(String text) {
    final theme = Theme.of(context);

    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      textCapitalization: TextCapitalization.words,
      decoration: const InputDecoration(
        labelText: 'Item Name',
        hintText: 'e.g., Organic Milk',
        prefixIcon: Icon(Icons.inventory_2_outlined),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter item name';
        }
        return null;
      },
    );
  }

  Widget _buildCategorySelector() {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ItemCategory.values.map((category) {
            return CategoryChip(
              category: category,
              isSelected: _selectedCategory == category,
              onTap: () => setState(() => _selectedCategory = category),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDateFields() {
    return Row(
      children: [
        Expanded(
          child: _DateField(
            label: 'Purchase Date',
            date: _purchaseDate,
            onTap: () => _selectDate(context, isPurchaseDate: true),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _DateField(
            label: 'Expiry Date',
            date: _expiryDate,
            onTap: () => _selectDate(context, isPurchaseDate: false),
          ),
        ),
      ],
    );
  }

  Widget _buildQuantityField() {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quantity',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            IconButton.filled(
              onPressed:
                  _quantity > 1 ? () => setState(() => _quantity--) : null,
              icon: const Icon(Icons.remove),
              style: IconButton.styleFrom(
                backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                foregroundColor: theme.colorScheme.primary,
                disabledBackgroundColor:
                    theme.colorScheme.onSurface.withOpacity(0.05),
              ),
            ),
            const SizedBox(width: 16),
            Text(
              '$_quantity',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 16),
            IconButton.filled(
              onPressed: () => setState(() => _quantity++),
              icon: const Icon(Icons.add),
              style: IconButton.styleFrom(
                backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                foregroundColor: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLocationField() {
    return TextFormField(
      controller: _locationController,
      textCapitalization: TextCapitalization.words,
      decoration: const InputDecoration(
        labelText: 'Storage Location',
        hintText: 'e.g., Refrigerator, Pantry',
        prefixIcon: Icon(Icons.location_on_outlined),
      ),
    );
  }

  Widget _buildNotesField() {
    return TextFormField(
      controller: _notesController,
      maxLines: 3,
      textCapitalization: TextCapitalization.sentences,
      decoration: const InputDecoration(
        labelText: 'Notes (Optional)',
        hintText: 'Any additional information...',
        alignLabelWithHint: true,
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveItem,
        child: _isSaving
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text('Add Item'),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context,
      {required bool isPurchaseDate}) async {
    final initialDate = isPurchaseDate ? _purchaseDate : _expiryDate;
    final firstDate = isPurchaseDate
        ? DateTime.now().subtract(const Duration(days: 365))
        : DateTime.now();
    final lastDate = DateTime.now().add(const Duration(days: 365 * 5));

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (picked != null) {
      setState(() {
        if (isPurchaseDate) {
          _purchaseDate = picked;
        } else {
          _expiryDate = picked;
        }
      });
    }
  }

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) return;

    if (_expiryDate.isBefore(_purchaseDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Expiry date cannot be before purchase date'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final item = ItemModel(
      id: _uuid.v4(),
      name: _nameController.text.trim(),
      category: _selectedCategory,
      purchaseDate: _purchaseDate,
      expiryDate: _expiryDate,
      quantity: _quantity,
      location: _locationController.text.trim().isNotEmpty
          ? _locationController.text.trim()
          : null,
      notes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
    );

    final itemService = context.read<ItemService>();
    final error = await itemService.addItem(item);

    if (mounted) {
      setState(() => _isSaving = false);

      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $error'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      } else {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Item added successfully'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    }
  }
}

class _ScanOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDark;

  const _ScanOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onTap;

  const _DateField({
    required this.label,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(color: theme.dividerColor),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  DateFormat('MMM d, y').format(date),
                  style: theme.textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
