import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../auth/logic/auth_provider.dart';
import '../../calendar/data/models/reminder.dart';
import 'package:nafass_application/core/utils/notification_service.dart';
import '../data/models/challenge.dart';
import '../data/models/challenge_progress.dart';
import '../data/repositories/challenges_repository.dart';

class ChallengesProvider extends ChangeNotifier {
  ChallengesProvider({
    required AuthProvider authProvider,
    required NotificationService notificationService,
    ChallengesRepository? repository,
  })  : _authProvider = authProvider,
        _notificationService = notificationService,
        _repository = repository ?? ChallengesRepository();

  final ChallengesRepository _repository;
  final NotificationService _notificationService;
  AuthProvider _authProvider;

  final List<Challenge> _challenges = <Challenge>[];
  final Map<String, List<ChallengeProgress>> _progressByChallenge =
  <String, List<ChallengeProgress>>{};
  final Uuid _uuid = const Uuid();

  bool _isLoading = false;

  bool get isLoading => _isLoading;

  UnmodifiableListView<Challenge> get challenges => UnmodifiableListView(_challenges);

  List<Challenge> get activeChallenges =>
      _challenges.where((challenge) => challenge.state == ChallengeState.actif).toList(growable: false);

  Challenge? findById(String id) {
    try {
      return _challenges.firstWhere((challenge) => challenge.id == id);
    } catch (_) {
      return null;
    }
  }

  List<ChallengeProgress> progressFor(String challengeId) {
    final list = _progressByChallenge[challengeId];
    if (list == null) {
      return const <ChallengeProgress>[];
    }
    return List.unmodifiable(list);
  }

  void updateAuth(AuthProvider authProvider) {
    _authProvider = authProvider;
  }

  Future<void> loadAll({String? userId}) async {
    final resolvedUserId = userId ?? _authProvider.currentUser?.id;
    if (resolvedUserId == null) {
      _challenges.clear();
      _progressByChallenge.clear();
      notifyListeners();
      return;
    }
    _isLoading = true;
    notifyListeners();
    try {
      final fetched = await _repository.getChallenges(userId: resolvedUserId);
      _challenges
        ..clear()
        ..addAll(fetched);
      _progressByChallenge.clear();
      for (final challenge in _challenges) {
        final history = await _repository.getProgress(challenge.id);
        _progressByChallenge[challenge.id] = history;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Challenge> createChallenge({
    required String title,
    String? description,
    required String typeAddiction,
    required ChallengeGoalType goalType,
    double? goalValue,
    required DateTime startDate,
    DateTime? endDate,
    bool isIndefinite = false,
    ChallengeFrequency frequency = ChallengeFrequency.quotidien,
    ChallengeState state = ChallengeState.actif,
    String? reminderTime,
  }) async {
    final userId = _authProvider.currentUser?.id;
    if (userId == null) {
      throw StateError('Cannot create challenge without authenticated user');
    }

    final challenge = Challenge(
      id: _uuid.v4(),
      userId: userId,
      title: title,
      description: description,
      typeAddiction: typeAddiction,
      goalType: goalType,
      goalValue: goalValue,
      startDate: startDate,
      endDate: endDate,
      isIndefinite: isIndefinite,
      frequency: frequency,
      state: state,
      reminderTime: reminderTime,
    );

    challenge.validateCreate();
    final persisted = await _repository.createChallenge(challenge);
    _challenges
      ..add(persisted)
      ..sort(_challengeSorter);
    _progressByChallenge[persisted.id] = <ChallengeProgress>[];
    await _scheduleReminderIfNeeded(persisted);
    notifyListeners();
    return persisted;
  }

  Future<Challenge> updateChallenge(Challenge challenge) async {
    final updated = await _repository.updateChallenge(challenge);
    final index = _challenges.indexWhere((item) => item.id == updated.id);
    if (index != -1) {
      final previous = _challenges[index];
      _challenges[index] = updated;
      _challenges.sort(_challengeSorter);
      final reminderChanged = previous.reminderTime != updated.reminderTime;
      final stateChanged = previous.state != updated.state;
      if (reminderChanged || stateChanged) {
        await _rescheduleReminder(updated);
      }
    }
    notifyListeners();
    return updated;
  }

  Future<void> archiveChallenge(String id, {String? reason}) async {
    await _repository.archiveChallenge(id, reason: reason);
    final index = _challenges.indexWhere((challenge) => challenge.id == id);
    if (index != -1) {
      final now = DateTime.now();
      final metadata = <String, dynamic>{
        ...?_challenges[index].metadata,
        'archivedAt': now.toIso8601String(),
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      };
      _challenges[index] = _challenges[index]
          .copyWith(state: ChallengeState.archive, deletedAt: now, metadata: metadata, updatedAt: now);
      await _cancelReminder(id);
    }
    notifyListeners();
  }

  Future<void> deleteChallengeHard(String id) async {
    await _repository.hardDeleteChallenge(id);
    _challenges.removeWhere((challenge) => challenge.id == id);
    _progressByChallenge.remove(id);
    await _cancelReminder(id);
    notifyListeners();
  }

  Future<ChallengeProgress> addDailyProgress({
    required String challengeId,
    required String date,
    bool? success,
    double? measuredValue,
    String? note,
  }) async {
    if (success == null && measuredValue == null) {
      throw ArgumentError('Either success or measuredValue is required');
    }
    final parsedDate = DateTime.parse('${date}T00:00:00');
    final progress = ChallengeProgress(
      id: _uuid.v4(),
      challengeId: challengeId,
      date: parsedDate,
      success: success,
      measuredValue: measuredValue,
      note: note,
    );
    final stored = await _repository.addProgress(progress);
    final history = _progressByChallenge.putIfAbsent(challengeId, () => <ChallengeProgress>[]);
    history.removeWhere((entry) => entry.date == stored.date);
    history.add(stored);
    history.sort((a, b) => a.date.compareTo(b.date));
    await _evaluateLifecycle(challengeId);
    notifyListeners();
    return stored;
  }

  Future<void> deleteProgress(String progressId) async {
    await _repository.deleteProgress(progressId);
    for (final entry in _progressByChallenge.entries) {
      final before = entry.value.length;
      entry.value.removeWhere((progress) => progress.id == progressId);
      final removed = entry.value.length < before;
      if (removed) {
        entry.value.sort((a, b) => a.date.compareTo(b.date));
        await _evaluateLifecycle(entry.key);
        break;
      }
    }
    notifyListeners();
  }

  Future<List<Challenge>> searchChallenges({String? keyword, ChallengeState? state}) async {
    return _repository.search(keyword: keyword, state: state);
  }

  double successRate(String challengeId, {int days = 14}) {
    final history = _progressByChallenge[challengeId];
    if (history == null || history.isEmpty) {
      return 0;
    }
    final now = DateTime.now();
    final threshold = now.subtract(Duration(days: days));
    final relevant = history.where((entry) => entry.date.isAfter(threshold)).toList();
    if (relevant.isEmpty) {
      return 0;
    }
    final successes = relevant.where(_isSuccessful).length;
    return successes / relevant.length;
  }

  int currentStreak(String challengeId) {
    final history = _progressByChallenge[challengeId];
    if (history == null || history.isEmpty) {
      return 0;
    }
    int streak = 0;
    for (final entry in history.reversed) {
      if (_isSuccessful(entry)) {
        streak += 1;
      } else {
        break;
      }
    }
    return streak;
  }

  List<double> lastNMeasured(String challengeId, int n) {
    final history = _progressByChallenge[challengeId];
    if (history == null || history.isEmpty) {
      return const <double>[];
    }
    final values = history
        .where((entry) => entry.measuredValue != null)
        .map((entry) => entry.measuredValue!)
        .toList();
    if (values.length <= n) {
      return values;
    }
    return values.sublist(values.length - n);
  }

  Future<void> _evaluateLifecycle(String challengeId) async {
    final index = _challenges.indexWhere((challenge) => challenge.id == challengeId);
    if (index == -1) {
      return;
    }
    final challenge = _challenges[index];
    if (challenge.state == ChallengeState.archive) {
      return;
    }
    final history = _progressByChallenge[challengeId] ?? <ChallengeProgress>[];
    if (history.isEmpty) {
      return;
    }
    final window = history.reversed.take(7).toList();
    if (window.isEmpty) {
      return;
    }
    final successes = window.where(_isSuccessful).length;
    final ratio = successes / window.length;
    ChallengeState? nextState;
    Map<String, dynamic>? extra;
    if (window.length >= 7 && successes >= 6 && challenge.state != ChallengeState.termine) {
      nextState = ChallengeState.termine;
      extra = {
        'completedAt': DateTime.now().toIso8601String(),
        'window': '7d',
        'successRate': ratio,
      };
    } else if (window.length >= 7 && successes <= 1 && challenge.state != ChallengeState.echoue) {
      nextState = ChallengeState.echoue;
      extra = {
        'failedAt': DateTime.now().toIso8601String(),
        'window': '7d',
        'successRate': ratio,
      };
    } else if (challenge.state != ChallengeState.actif && successes > 1) {
      nextState = ChallengeState.actif;
      extra = {
        'reopenedAt': DateTime.now().toIso8601String(),
      };
    }
    if (nextState != null && nextState != challenge.state) {
      final metadata = <String, dynamic>{
        ...?challenge.metadata,
        if (extra != null) ...extra,
      };
      final persisted = await _repository.updateChallenge(
        challenge.copyWith(state: nextState, metadata: metadata),
      );
      _challenges[index] = persisted;
      if (nextState == ChallengeState.actif) {
        await _scheduleReminderIfNeeded(persisted);
      } else {
        await _cancelReminder(challengeId);
      }
    }
  }

  Future<void> _scheduleReminderIfNeeded(Challenge challenge) async {
    if (challenge.state != ChallengeState.actif || !challenge.hasReminder) {
      return;
    }
    final scheduledAt = _nextReminderDate(challenge);
    if (scheduledAt == null) {
      return;
    }
    final reminder = Reminder(
      id: 'challenge_${challenge.id}',
      userId: challenge.userId,
      title: 'Défi: ${challenge.title}',
      description: challenge.frequency == ChallengeFrequency.quotidien
          ? 'N\'oubliez pas votre check-in du jour'
          : 'Check-in hebdomadaire',
      scheduledAt: scheduledAt,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    try {
      await _notificationService.scheduleReminder(reminder);
    } catch (_) {}
  }

  Future<void> _rescheduleReminder(Challenge challenge) async {
    try {
      await _notificationService.cancelReminder('challenge_${challenge.id}');
    } catch (_) {}
    await _scheduleReminderIfNeeded(challenge);
  }

  Future<void> _cancelReminder(String challengeId) async {
    try {
      await _notificationService.cancelReminder('challenge_$challengeId');
    } catch (_) {}
  }

  DateTime? _nextReminderDate(Challenge challenge) {
    final reminder = challenge.reminderTime;
    if (reminder == null || reminder.isEmpty) {
      return null;
    }
    final format = DateFormat('HH:mm');
    late final TimeOfDay timeOfDay;
    try {
      final parsed = format.parse(reminder);
      timeOfDay = TimeOfDay(hour: parsed.hour, minute: parsed.minute);
    } catch (_) {
      return null;
    }
    final now = DateTime.now();
    DateTime candidate = DateTime(now.year, now.month, now.day, timeOfDay.hour, timeOfDay.minute);
    if (challenge.frequency == ChallengeFrequency.quotidien) {
      if (!candidate.isAfter(now)) {
        candidate = candidate.add(const Duration(days: 1));
      }
      return candidate;
    }
    final targetWeekday = challenge.startDate.weekday;
    while (candidate.weekday != targetWeekday || !candidate.isAfter(now)) {
      candidate = candidate.add(const Duration(days: 1));
    }
    return candidate;
  }

  bool _isSuccessful(ChallengeProgress entry) {
    if (entry.success != null) {
      return entry.success!;
    }
    if (entry.measuredValue != null) {
      return entry.measuredValue! > 0;
    }
    return false;
  }

  int _challengeSorter(Challenge a, Challenge b) {
    final updatedCompare = b.updatedAt.compareTo(a.updatedAt);
    if (updatedCompare != 0) {
      return updatedCompare;
    }
    return b.createdAt.compareTo(a.createdAt);
  }
}