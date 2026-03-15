import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../shared/services/receipt_scanner_service.dart';
import '../../../shared/services/item_service.dart';
import '../../../shared/models/item_model.dart';

class ScanReceiptScreen extends StatefulWidget {
  const ScanReceiptScreen({super.key});

  @override
  State<ScanReceiptScreen> createState() => _ScanReceiptScreenState();
}

class _ScanReceiptScreenState extends State<ScanReceiptScreen> {
  late ReceiptScannerService _scannerService;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _scannerService = ReceiptScannerService();
  }

  @override
  void dispose() {
    _scannerService.dispose();
    super.dispose();
  }

  Future<void> _captureReceipt() async {
    final success = await _scannerService.captureReceipt(context);
    if (mounted) {
      setState(() => _isInitialized = true);
      if (!success && _scannerService.error != null) {
        _showError(_scannerService.error!);
      }
    }
  }

  Future<void> _pickFromGallery() async {
    final success = await _scannerService.pickReceiptFromGallery(context);
    if (mounted) {
      setState(() => _isInitialized = true);
      if (!success && _scannerService.error != null) {
        _showError(_scannerService.error!);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _addSelectedItems() async {
    final selectedItems = _scannerService.getSelectedItemModels();
    if (selectedItems.isEmpty) {
      _showError('Please select at least one item');
      return;
    }

    final itemService = context.read<ItemService>();
    int successCount = 0;
    int failCount = 0;

    for (final item in selectedItems) {
      final error = await itemService.addItem(item);
      if (error == null) {
        successCount++;
      } else {
        failCount++;
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            failCount == 0
                ? 'Added $successCount items successfully!'
                : 'Added $successCount items. $failCount failed.',
          ),
          backgroundColor: failCount == 0 ? Colors.green : Colors.orange,
        ),
      );

      if (successCount > 0) {
        Navigator.of(context).pop(true);
      }
    }
  }

  void _showAddManualItemDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Item Manually'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Item Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                setState(() {
                  _scannerService.addManualItem(controller.text.trim());
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showRawTextDialog() {
    final rawText = _scannerService.rawText;
    final lines = rawText.split('\n').where((l) => l.trim().isNotEmpty).toList();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Scanned Text (${lines.length} lines)',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Tap on any line to add it as an item',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: lines.length,
                itemBuilder: (context, index) {
                  final line = lines[index].trim();
                  return ListTile(
                    dense: true,
                    title: Text(
                      line,
                      style: const TextStyle(fontSize: 14),
                    ),
                    leading: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                        fontSize: 12,
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.add_circle_outline, size: 20),
                      onPressed: () {
                        setState(() {
                          _scannerService.addManualItem(line);
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Added: $line'),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                    ),
                    onTap: () {
                      setState(() {
                        _scannerService.addManualItem(line);
                      });
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Added: $line'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditItemDialog(ScannedItem item) {
    final nameController = TextEditingController(text: item.name);
    ItemCategory selectedCategory = item.category;
    int quantity = item.quantity;
    DateTime expiryDate = item.expiryDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
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
                  Text(
                    'Edit Item',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Item Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<ItemCategory>(
                value: selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: ItemCategory.values.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(_getCategoryName(category)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setModalState(() => selectedCategory = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Quantity'),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            IconButton(
                              onPressed: quantity > 1
                                  ? () => setModalState(() => quantity--)
                                  : null,
                              icon: const Icon(Icons.remove_circle_outline),
                            ),
                            Text(
                              '$quantity',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            IconButton(
                              onPressed: () => setModalState(() => quantity++),
                              icon: const Icon(Icons.add_circle_outline),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Expiry Date'),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: expiryDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                            );
                            if (date != null) {
                              setModalState(() => expiryDate = date);
                            }
                          },
                          icon: const Icon(Icons.calendar_today, size: 16),
                          label: Text(DateFormat('dd MMM yyyy').format(expiryDate)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    setState(() {
                      _scannerService.updateItemName(item.id, nameController.text);
                      _scannerService.updateItemCategory(item.id, selectedCategory);
                      _scannerService.updateItemQuantity(item.id, quantity);
                      _scannerService.updateItemExpiry(item.id, expiryDate);
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getCategoryName(ItemCategory category) {
    switch (category) {
      case ItemCategory.food:
        return 'Food';
      case ItemCategory.grocery:
        return 'Grocery';
      case ItemCategory.medicine:
        return 'Medicine';
      case ItemCategory.cosmetics:
        return 'Cosmetics';
    }
  }

  IconData _getCategoryIcon(ItemCategory category) {
    switch (category) {
      case ItemCategory.food:
        return Icons.restaurant_rounded;
      case ItemCategory.grocery:
        return Icons.shopping_basket_rounded;
      case ItemCategory.medicine:
        return Icons.medical_services_rounded;
      case ItemCategory.cosmetics:
        return Icons.face_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Receipt'),
        actions: [
          if (_isInitialized && _scannerService.rawText.isNotEmpty) ...[
            IconButton(
              onPressed: () => _showRawTextDialog(),
              icon: const Icon(Icons.text_snippet_outlined),
              tooltip: 'View scanned text',
            ),
          ],
          if (_scannerService.scannedItems.isNotEmpty) ...[
            TextButton.icon(
              onPressed: () {
                final allSelected = _scannerService.scannedItems.every((item) => item.isSelected);
                setState(() {
                  if (allSelected) {
                    _scannerService.deselectAllItems();
                  } else {
                    _scannerService.selectAllItems();
                  }
                });
              },
              icon: Icon(
                _scannerService.scannedItems.every((item) => item.isSelected)
                    ? Icons.deselect
                    : Icons.select_all,
              ),
              label: Text(
                _scannerService.scannedItems.every((item) => item.isSelected)
                    ? 'Deselect'
                    : 'Select All',
              ),
            ),
          ],
        ],
      ),
      body: _buildBody(theme, colorScheme),
      bottomNavigationBar: _scannerService.scannedItems.isNotEmpty
          ? _buildBottomBar(theme, colorScheme)
          : null,
    );
  }

  Widget _buildBody(ThemeData theme, ColorScheme colorScheme) {
    if (_scannerService.isProcessing) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Processing receipt...'),
          ],
        ),
      );
    }

    if (!_isInitialized || _scannerService.scannedItems.isEmpty) {
      return _buildScanOptions(theme, colorScheme);
    }

    return _buildItemsList(theme, colorScheme);
  }

  Widget _buildScanOptions(ThemeData theme, ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_rounded,
            size: 100,
            color: colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 24),
          Text(
            'Scan Receipt',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Take a photo of your receipt or choose from gallery to automatically extract items',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _captureReceipt,
              icon: const Icon(Icons.camera_alt_rounded),
              label: const Text('Take Photo'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _pickFromGallery,
              icon: const Icon(Icons.photo_library_rounded),
              label: const Text('Choose from Gallery'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          if (_scannerService.error != null && _isInitialized) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: colorScheme.error),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _scannerService.error!,
                      style: TextStyle(color: colorScheme.onErrorContainer),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_isInitialized && _scannerService.scannedItems.isEmpty && _scannerService.error == null) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: colorScheme.primary,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'No items found in the receipt',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Try taking a clearer photo or add items manually',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: _showAddManualItemDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Item Manually'),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildItemsList(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      children: [
        if (_scannerService.selectedImage != null)
          Container(
            height: 120,
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(
                image: FileImage(_scannerService.selectedImage!),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
              padding: const EdgeInsets.all(12),
              alignment: Alignment.bottomLeft,
              child: Row(
                children: [
                  const Icon(Icons.receipt, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '${_scannerService.scannedItems.length} items found',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _scannerService.clearAll();
                        _isInitialized = false;
                      });
                    },
                    icon: const Icon(Icons.refresh, color: Colors.white, size: 18),
                    label: const Text('Rescan', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Review Items',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton.icon(
                onPressed: _showAddManualItemDialog,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Item'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _scannerService.scannedItems.length,
            itemBuilder: (context, index) {
              final item = _scannerService.scannedItems[index];
              return _buildItemCard(item, theme, colorScheme);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildItemCard(ScannedItem item, ThemeData theme, ColorScheme colorScheme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _showEditItemDialog(item),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Checkbox(
                value: item.isSelected,
                onChanged: (value) {
                  setState(() {
                    _scannerService.toggleItemSelection(item.id);
                  });
                },
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getCategoryIcon(item.category),
                  color: colorScheme.onPrimaryContainer,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        decoration: item.isSelected ? null : TextDecoration.lineThrough,
                        color: item.isSelected ? null : colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _buildChip(
                          _getCategoryName(item.category),
                          colorScheme.secondaryContainer,
                          colorScheme.onSecondaryContainer,
                        ),
                        const SizedBox(width: 8),
                        _buildChip(
                          'Qty: ${item.quantity}',
                          colorScheme.tertiaryContainer,
                          colorScheme.onTertiaryContainer,
                        ),
                        const SizedBox(width: 8),
                        _buildChip(
                          DateFormat('dd MMM').format(item.expiryDate),
                          colorScheme.surfaceContainerHighest,
                          colorScheme.onSurface,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _scannerService.removeItem(item.id);
                  });
                },
                icon: Icon(
                  Icons.delete_outline,
                  color: colorScheme.error,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip(String label, Color backgroundColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildBottomBar(ThemeData theme, ColorScheme colorScheme) {
    final selectedCount = _scannerService.selectedCount;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$selectedCount items selected',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Tap item to edit details',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            FilledButton.icon(
              onPressed: selectedCount > 0 ? _addSelectedItems : null,
              icon: const Icon(Icons.add_shopping_cart),
              label: Text('Add $selectedCount Items'),
            ),
          ],
        ),
      ),
    );
  }
}
