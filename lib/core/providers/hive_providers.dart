import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';
import 'package:quicksplit/features/assign/domain/models/split_session.dart';
import 'package:quicksplit/features/ocr/domain/models/receipt.dart';

/// Stream provider that watches the Hive history box for changes
///
/// This provider emits the Hive box whenever it changes, enabling
/// automatic UI refresh when new split sessions are added.
final historyBoxProvider = StreamProvider<Box<SplitSession>>((ref) {
  // Get the Hive box
  final box = Hive.box<SplitSession>('history');

  // Create a stream from Hive's watch() method
  // This will emit the box whenever it changes
  final stream = box.watch().map((event) => box);

  // Start with the current box state
  // Then emit updates when the box changes
  return stream;
});

/// Stream provider that watches the Hive receipts box for changes
///
/// This provider emits the Hive box whenever it changes, enabling
/// automatic UI refresh when receipts are added or modified.
final receiptsBoxProvider = StreamProvider<Box<Receipt>>((ref) {
  // Get the Hive box
  final box = Hive.box<Receipt>('receipts');

  // Create a stream from Hive's watch() method
  // This will emit the box whenever it changes
  final stream = box.watch().map((event) => box);

  // Start with the current box state
  // Then emit updates when the box changes
  return stream;
});
