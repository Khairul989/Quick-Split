import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quicksplit/core/router/router.dart';
import 'package:quicksplit/features/ocr/domain/models/receipt.dart';
import 'package:quicksplit/features/ocr/presentation/providers/ocr_providers.dart';

/// Screen that displays OCR processing and results
class OcrProcessingScreen extends ConsumerWidget {
  final String imagePath;

  const OcrProcessingScreen({required this.imagePath, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ocrState = ref.watch(ocrStateProvider);

    ref.listen<OcrState>(ocrStateProvider, (previous, next) {
      if (next is OcrStateSuccess) {
        // Navigate to item editor with parsed receipt
        context.pushNamed(
          RouteNames.itemsEditor,
          extra: next.parsedReceipt.items
              .map((parsedItem) => ReceiptItem(
                    name: parsedItem.name,
                    quantity: parsedItem.quantity,
                    price: parsedItem.price,
                  ))
              .toList(),
        );
      } else if (next is OcrStateError) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${next.message}')));
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Processing Receipt'), elevation: 0),
      body: _buildBody(ocrState, context, ref),
    );
  }

  Widget _buildBody(OcrState ocrState, BuildContext context, WidgetRef ref) {
    if (ocrState is OcrStateInitial) {
      // Trigger OCR processing on first build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(ocrStateProvider.notifier).processImage(imagePath);
      });
      return const Center(child: CircularProgressIndicator());
    } else if (ocrState is OcrStateLoading) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Extracting text from receipt...',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      );
    } else if (ocrState is OcrStateSuccess) {
      return _buildSuccessView(ocrState, context);
    } else if (ocrState is OcrStateError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              'OCR Processing Failed',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                ocrState.message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.pop(),
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    return const Center(child: Text('Unknown state'));
  }

  Widget _buildSuccessView(OcrStateSuccess state, BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Detected Items',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    ...state.parsedReceipt.items.map(
                      (item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text(item.name)),
                            Text('x${item.quantity}'),
                            const SizedBox(width: 8),
                            Text(
                              'RM ${item.price.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (state.parsedReceipt.items.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Text('No items detected'),
                        ),
                      ),
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total:'),
                        Text(
                          'RM ${state.parsedReceipt.calculatedTotal.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (state.parsedReceipt.errors.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                color: Colors.orange.shade100,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Parsing Warnings',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      ...state.parsedReceipt.errors.map(
                        (error) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.warning,
                                size: 16,
                                color: Colors.orange,
                              ),
                              const SizedBox(width: 8),
                              Expanded(child: Text(error)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: () => context.pop(),
              child: const Text('Go Back & Retry'),
            ),
          ),
        ],
      ),
    );
  }
}
