import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';
import 'package:quicksplit/features/assign/domain/models/split_session.dart';

final groupBalanceProvider = StreamProvider.family.autoDispose<double, String>((ref, groupId) async* {
  final historyBox = Hive.box<SplitSession>('history');

  double computeBalance() {
    final sessions = historyBox.values
        .where((s) => s.groupId == groupId && s.isSaved)
        .toList();

    double balance = 0.0;
    for (final session in sessions) {
      for (final share in session.calculatedShares) {
        final remaining = share.total - (share.amountPaid ?? 0);
        if (remaining > 0.01) {
          balance += remaining;
        }
      }
    }

    return balance;
  }

  final streamController = StreamController<double>();
  streamController.add(computeBalance());

  final listener = historyBox.watch().listen((_) {
    streamController.add(computeBalance());
  });

  ref.onDispose(() {
    listener.cancel();
    streamController.close();
  });

  yield* streamController.stream;
});
