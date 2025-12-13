import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';
import 'package:quicksplit/features/assign/domain/models/split_session.dart';
import 'package:quicksplit/features/groups/domain/models/group.dart';

final mostActiveGroupProvider = StreamProvider.autoDispose<Group?>((
  ref,
) async* {
  final historyBox = Hive.box<SplitSession>('history');
  final groupsBox = Hive.box<Group>('groups');

  final now = DateTime.now();
  final firstDayOfMonth = DateTime(now.year, now.month, 1);
  final firstDayOfNextMonth = DateTime(now.year, now.month + 1, 1);

  Group? computeMostActive() {
    final sessions = historyBox.values
        .where(
          (s) =>
              s.isSaved &&
              s.createdAt.isAfter(firstDayOfMonth) &&
              s.createdAt.isBefore(firstDayOfNextMonth),
        )
        .toList();

    final Map<String, int> groupCounts = {};
    for (final session in sessions) {
      if (session.groupId != null) {
        groupCounts[session.groupId!] =
            (groupCounts[session.groupId!] ?? 0) + 1;
      }
    }

    if (groupCounts.isEmpty) return null;

    final mostActiveId = groupCounts.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
    return groupsBox.get(mostActiveId);
  }

  final streamController = StreamController<Group?>();
  streamController.add(computeMostActive());

  final historyListener = historyBox.watch().listen((_) {
    streamController.add(computeMostActive());
  });

  final groupsListener = groupsBox.watch().listen((_) {
    streamController.add(computeMostActive());
  });

  ref.onDispose(() {
    historyListener.cancel();
    groupsListener.cancel();
    streamController.close();
  });

  yield* streamController.stream;
});
