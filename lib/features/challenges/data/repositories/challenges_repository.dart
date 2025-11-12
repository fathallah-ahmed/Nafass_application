import 'package:uuid/uuid.dart';

import '../../../../core/storage/local_json_store.dart';
import '../models/challenge.dart';
import '../models/challenge_progress.dart';

class ChallengesRepository {
  ChallengesRepository({LocalJsonStore? store})
      : _store = store ?? LocalJsonStore(runtimeDirectory: 'data_dev/data');

  final LocalJsonStore _store;
  final Uuid _uuid = const Uuid();

  static const String _challengesFile = 'challenges.json';
  static const String _progressFile = 'challenge_progress.json';

  Future<List<Challenge>> _readChallenges() async {
    final rawList = await _store.readList(_challengesFile);
    final items = rawList.map(Challenge.fromJson).toList();
    items.sort(_challengeSorter);
    return items;
  }

  Future<void> _writeChallenges(List<Challenge> challenges) async {
    final sorted = [...challenges]..sort(_challengeSorter);
    await _store.writeList(
      _challengesFile,
      sorted.map((challenge) => challenge.toJson()).toList(),
    );
  }

  Future<List<ChallengeProgress>> _readProgress() async {
    final rawList = await _store.readList(_progressFile);
    final items = rawList.map(ChallengeProgress.fromJson).toList();
    items.sort((a, b) => a.date.compareTo(b.date));
    return items;
  }

  Future<void> _writeProgress(List<ChallengeProgress> progress) async {
    final sorted = [...progress]..sort((a, b) => a.date.compareTo(b.date));
    await _store.writeList(
      _progressFile,
      sorted.map((item) => item.toJson()).toList(),
    );
  }

  Future<List<Challenge>> getChallenges({String? userId}) async {
    final challenges = await _readChallenges();
    if (userId == null) {
      return challenges;
    }
    return challenges.where((challenge) => challenge.userId == userId).toList();
  }

  Future<Challenge> createChallenge(Challenge input) async {
    final challenges = await _readChallenges();
    final now = DateTime.now();
    final challenge = (input.id.isEmpty ? input.copyWith(id: _uuid.v4()) : input)
        .copyWith(createdAt: now, updatedAt: now);
    challenge.validateCreate();
    await _writeChallenges(<Challenge>[...challenges, challenge]);
    return challenge;
  }

  Future<Challenge> updateChallenge(Challenge challenge) async {
    final challenges = await _readChallenges();
    final index = challenges.indexWhere((item) => item.id == challenge.id);
    if (index == -1) {
      throw StateError('Challenge not found: ${challenge.id}');
    }
    final updated = challenge.copyWith(updatedAt: DateTime.now());
    updated.validateUpdate();
    final copy = [...challenges];
    copy[index] = updated;
    await _writeChallenges(copy);
    return updated;
  }

  Future<void> archiveChallenge(String id, {String? reason}) async {
    final challenges = await _readChallenges();
    final index = challenges.indexWhere((element) => element.id == id);
    if (index == -1) {
      throw StateError('Challenge not found: $id');
    }
    final now = DateTime.now();
    final metadata = <String, dynamic>{
      ...?challenges[index].metadata,
      'archivedAt': now.toIso8601String(),
      if (reason != null && reason.isNotEmpty) 'reason': reason,
    };
    final archived = challenges[index].copyWith(
      state: ChallengeState.archive,
      deletedAt: now,
      metadata: metadata,
      updatedAt: now,
    );
    challenges[index] = archived;
    await _writeChallenges(challenges);
  }

  Future<void> hardDeleteChallenge(String id) async {
    final challenges = await _readChallenges();
    final filtered = challenges.where((challenge) => challenge.id != id).toList();
    await _writeChallenges(filtered);
    final progress = await _readProgress();
    await _writeProgress(progress.where((p) => p.challengeId != id).toList());
  }

  Future<List<ChallengeProgress>> getProgress(String challengeId) async {
    final progress = await _readProgress();
    return progress
        .where((item) => item.challengeId == challengeId)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  Future<ChallengeProgress> addProgress(ChallengeProgress progress) async {
    final challenges = await _readChallenges();
    final exists = challenges.any((challenge) => challenge.id == progress.challengeId);
    if (!exists) {
      throw StateError('Unknown challenge: ${progress.challengeId}');
    }
    progress.validate();
    final all = await _readProgress();
    final sanitized = progress.copyWith(id: progress.id.isEmpty ? _uuid.v4() : progress.id);
    final updated = all.where((entry) {
      return !(entry.challengeId == sanitized.challengeId && entry.date == sanitized.date);
    }).toList()
      ..add(sanitized);
    await _writeProgress(updated);
    return sanitized;
  }

  Future<void> deleteProgress(String progressId) async {
    final progress = await _readProgress();
    final updated = progress.where((item) => item.id != progressId).toList();
    await _writeProgress(updated);
  }

  Future<List<Challenge>> search({String? keyword, ChallengeState? state}) async {
    final challenges = await _readChallenges();
    final normalized = keyword?.trim().toLowerCase() ?? '';
    final filtered = challenges.where((challenge) {
      final matchesState = state == null || challenge.state == state;
      if (!matchesState) return false;
      if (normalized.isEmpty) return true;
      final title = challenge.title.toLowerCase();
      final description = challenge.description?.toLowerCase() ?? '';
      final addiction = challenge.typeAddiction.toLowerCase();
      return title.contains(normalized) ||
          description.contains(normalized) ||
          addiction.contains(normalized);
    }).toList();
    filtered.sort(_challengeSorter);
    return filtered;
  }

  int _challengeSorter(Challenge a, Challenge b) {
    final updatedCompare = b.updatedAt.compareTo(a.updatedAt);
    if (updatedCompare != 0) {
      return updatedCompare;
    }
    return b.createdAt.compareTo(a.createdAt);
  }
}