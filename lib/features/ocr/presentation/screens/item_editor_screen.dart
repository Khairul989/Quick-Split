import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quicksplit/core/router/router.dart';
import 'package:quicksplit/features/ocr/domain/models/receipt.dart';
import 'package:quicksplit/features/ocr/presentation/providers/ocr_providers.dart';

/// Screen for editing receipt items
class ItemEditorScreen extends ConsumerStatefulWidget {
  final List<ReceiptItem>? initialItems;

  const ItemEditorScreen({this.initialItems, super.key});

  @override
  ConsumerState<ItemEditorScreen> createState() => _ItemEditorScreenState();
}

class _ItemEditorScreenState extends ConsumerState<ItemEditorScreen> {
  late List<ReceiptItem> _items;

  @override
  void initState() {
    super.initState();
    _items = widget.initialItems ?? [];
  }

  void _addItem() {
    setState(() {
      _items.add(ReceiptItem(name: 'New Item', quantity: 1, price: 0.0));
    });
  }

  void _deleteItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  void _updateItem(int index, ReceiptItem item) {
    setState(() {
      _items[index] = item;
    });
  }

  double get _totalAmount =>
      _items.fold(0.0, (sum, item) => sum + item.subtotal);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            ref.read(ocrStateProvider.notifier).reset();
            context.pop();
          },
        ),
        title: const Text(
          'Edit Items',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: colorScheme.surface.withValues(alpha: 0.8),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: _items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_cart_outlined,
                          size: 48,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No items yet',
                          style: TextStyle(
                            color: theme.textTheme.bodyMedium?.color,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _addItem,
                          icon: const Icon(Icons.add),
                          label: const Text('Add First Item'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _items.length,
                    padding: const EdgeInsets.all(16),
                    itemBuilder: (context, index) {
                      return ItemEditorTile(
                        item: _items[index],
                        onUpdate: (updatedItem) =>
                            _updateItem(index, updatedItem),
                        onDelete: () => _deleteItem(index),
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: theme.dividerColor)),
          color: colorScheme.surface.withValues(alpha: 0.8),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 16,
          left: 16,
          right: 16,
          top: 12,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'RM ${_totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Inter Tight',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _addItem,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(color: colorScheme.primary),
                  backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
                ),
                icon: Icon(Icons.add, color: colorScheme.primary),
                label: Text(
                  'Add Item',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _items.isEmpty
                    ? null
                    : () {
                        final receipt = Receipt(
                          merchantName: 'Receipt',
                          items: _items,
                          subtotal: _totalAmount,
                          sst: 0,
                          serviceCharge: 0,
                          rounding: 0,
                          total: _totalAmount,
                        );
                        context.pushNamed(
                          RouteNames.groupSelect,
                          extra: receipt,
                        );
                      },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: isDark
                      ? colorScheme.primary
                      : theme.textTheme.bodyLarge?.color,
                ),
                child: const Text(
                  'Continue to Group Selection',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ItemEditorTile extends StatefulWidget {
  final ReceiptItem item;
  final Function(ReceiptItem) onUpdate;
  final VoidCallback onDelete;

  const ItemEditorTile({
    required this.item,
    required this.onUpdate,
    required this.onDelete,
    super.key,
  });

  @override
  State<ItemEditorTile> createState() => _ItemEditorTileState();
}

class _ItemEditorTileState extends State<ItemEditorTile> {
  late TextEditingController _nameController;
  late TextEditingController _quantityController;
  late TextEditingController _priceController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item.name);
    _quantityController = TextEditingController(
      text: widget.item.quantity.toString(),
    );
    _priceController = TextEditingController(
      text: widget.item.price.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _notifyUpdate() {
    final updatedItem = ReceiptItem(
      id: widget.item.id,
      name: _nameController.text,
      quantity: int.tryParse(_quantityController.text) ?? 1,
      price: double.tryParse(_priceController.text) ?? 0.0,
    );
    widget.onUpdate(updatedItem);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final subtotal =
        (int.tryParse(_quantityController.text) ?? 1) *
        (double.tryParse(_priceController.text) ?? 0.0);
    final secondaryTextColor = theme.textTheme.bodySmall?.color;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Grid layout: 5 columns total
          Row(
            children: [
              // Item Name column (2/5 width)
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Item Name',
                      style: TextStyle(fontSize: 12, color: secondaryTextColor),
                    ),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: _nameController,
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.textTheme.bodyMedium?.color,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: theme.inputDecorationTheme.fillColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: theme.dividerColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: theme.dividerColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: colorScheme.primary),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        isDense: true,
                      ),
                      onChanged: (_) => _notifyUpdate(),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Qty column (1/5 width)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Qty',
                      style: TextStyle(fontSize: 12, color: secondaryTextColor),
                    ),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: _quantityController,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: 'Inter Tight',
                        color: theme.textTheme.bodyMedium?.color,
                      ),
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: theme.inputDecorationTheme.fillColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: theme.dividerColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: theme.dividerColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: colorScheme.primary),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        isDense: true,
                      ),
                      onChanged: (_) => _notifyUpdate(),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Price column (2/5 width)
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Price',
                      style: TextStyle(fontSize: 12, color: secondaryTextColor),
                    ),
                    const SizedBox(height: 4),
                    Stack(
                      children: [
                        TextFormField(
                          controller: _priceController,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: 'Inter Tight',
                            color: theme.textTheme.bodyMedium?.color,
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            prefixText: 'RM ',
                            prefixStyle: TextStyle(
                              fontSize: 14,
                              color: secondaryTextColor,
                            ),
                            filled: true,
                            fillColor: theme.inputDecorationTheme.fillColor,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: theme.dividerColor),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: theme.dividerColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: colorScheme.primary,
                              ),
                            ),
                            contentPadding: const EdgeInsets.only(
                              left: 28,
                              right: 12,
                              top: 10,
                              bottom: 10,
                            ),
                            isDense: true,
                          ),
                          onChanged: (_) => _notifyUpdate(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Subtotal and delete button row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Subtotal: RM ${subtotal.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 14, color: secondaryTextColor),
              ),
              Text(
                'RM ${subtotal.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.textTheme.bodyMedium?.color,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete, size: 20),
                color: Colors.red,
                onPressed: widget.onDelete,
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.red.withValues(alpha: 0.05),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
