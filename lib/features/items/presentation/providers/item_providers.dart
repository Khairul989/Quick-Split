import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Item state (will be filled in Phase 3)
class ItemState {
  final List<Item> items;
  final bool isLoading;

  const ItemState({
    required this.items,
    this.isLoading = false,
  });

  ItemState copyWith({
    List<Item>? items,
    bool? isLoading,
  }) {
    return ItemState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class Item {
  final String id;
  final String name;
  final double price;
  final int quantity;

  const Item({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
  });
}

/// Items notifier for complex state logic
class ItemNotifier extends Notifier<ItemState> {
  @override
  ItemState build() {
    return const ItemState(items: []);
  }

  // Methods will be added in Phase 2/3
  void addItem(Item item) {
    state = state.copyWith(items: [...state.items, item]);
  }

  void removeItem(String itemId) {
    state = state.copyWith(
      items: state.items.where((item) => item.id != itemId).toList(),
    );
  }
}

/// Items state provider - used by widgets to rebuild when items change
final itemsProvider = NotifierProvider<ItemNotifier, ItemState>(
  ItemNotifier.new,
);

/// Computed provider: total price of all items
final totalPriceProvider = Provider(
  (ref) {
    final items = ref.watch(itemsProvider).items;
    return items.fold<double>(0, (sum, item) => sum + (item.price * item.quantity));
  },
);

/// Computed provider: item count
final itemCountProvider = Provider(
  (ref) => ref.watch(itemsProvider).items.length,
);
