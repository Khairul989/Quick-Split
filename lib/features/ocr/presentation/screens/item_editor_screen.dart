import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quicksplit/core/router/router.dart';
import 'package:quicksplit/features/ocr/domain/models/receipt.dart';

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
      _items.add(
        ReceiptItem(
          name: 'New Item',
          quantity: 1,
          price: 0.0,
        ),
      );
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

  void _confirmAndProceed() {
    Navigator.of(context).pop(_items);
  }

  double get _totalAmount =>
      _items.fold(0.0, (sum, item) => sum + item.subtotal);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Items'),
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
                        const Icon(Icons.shopping_cart_outlined, size: 48),
                        const SizedBox(height: 16),
                        const Text('No items yet'),
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
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'RM ${_totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _addItem,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Item'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _confirmAndProceed,
                        child: const Text('Done'),
                      ),
                    ),
                  ],
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
                    child: const Text('Continue to Group Selection'),
                  ),
                ),
              ],
            ),
          ),
        ],
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
    _quantityController =
        TextEditingController(text: widget.item.quantity.toString());
    _priceController =
        TextEditingController(text: widget.item.price.toStringAsFixed(2));
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
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      hintText: 'Item name',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (_) => _notifyUpdate(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _quantityController,
                    decoration: const InputDecoration(
                      hintText: 'Qty',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _notifyUpdate(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _priceController,
                    decoration: const InputDecoration(
                      hintText: 'Price',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => _notifyUpdate(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Subtotal: RM ${((int.tryParse(_quantityController.text) ?? 1) * (double.tryParse(_priceController.text) ?? 0.0)).toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: widget.onDelete,
                  tooltip: 'Delete item',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
