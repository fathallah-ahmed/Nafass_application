import 'package:flutter/foundation.dart';

import '../data/models/event.dart';
import '../data/models/reminder.dart';
import '../data/repositories/journal_repository.dart';
import 'package:nafass_application/core/utils/notification_service.dart';
import '../../auth/logic/auth_provider.dart';

class JournalProvider extends ChangeNotifier {
  JournalProvider({
    required AuthProvider authProvider,
    JournalRepository? repository,
    NotificationService? notificationService,
  })  : _repository = repository ?? JournalRepository(),
        _notificationService = notificationService ?? NotificationService(),
        _authProvider = authProvider,
        _activeUserId = authProvider.currentUser?.id;

  final JournalRepository _repository;
  final NotificationService _notificationService;
  AuthProvider _authProvider;

  List<Reminder> _reminders = <Reminder>[];
  List<Event> _events = <Event>[];

  bool _isLoading = false;
  String? _activeUserId;

  List<Reminder> get reminders => List.unmodifiable(_reminders);
  List<Event> get events => List.unmodifiable(_events);
  bool get isLoading => _isLoading;

  void updateAuth(AuthProvider authProvider) {
    _authProvider = authProvider;
    final newUserId = _authProvider.currentUser?.id;
    if (_activeUserId == newUserId) {
      return;
    }
    _activeUserId = newUserId;
    if (newUserId == null) {
      _reminders = <Reminder>[];
      _events = <Event>[];
      notifyListeners();
    } else {
      loadAll();
    }
  }

  String _requireUserId() {
    final userId = _authProvider.currentUser?.id;
    if (userId == null) {
      throw StateError('No authenticated user');
    }
    return userId;
  }

  Future<void> loadAll() async {
    final userId = _authProvider.currentUser?.id;
    if (userId == null) {
      _reminders = <Reminder>[];
      _events = <Event>[];
      _isLoading = false;
      _activeUserId = null;
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final reminders = await _repository.getReminders(userId: userId);
      final events = await _repository.getEvents(userId: userId);

      _reminders = reminders;
      _events = events;
      _activeUserId = userId;

      await _synchronizeNotifications();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _synchronizeNotifications() async {
    for (final reminder in _reminders) {
      if (!reminder.isActive || reminder.scheduledAt.isBefore(DateTime.now())) {
        await _notificationService.cancelReminder(reminder.id);
      } else {
        try {
          await _notificationService.rescheduleReminder(reminder);
        } catch (_) {
          // Windows/Web : pas de scheduling → on ignore
        }
      }
    }
  }

  Future<Reminder> addReminder({
    required String title,
    String? description,
    required DateTime scheduledAt,
    bool isActive = true,
    int snoozeMinutes = 5,
  }) async {
    final userId = _requireUserId();
    final reminder = await _repository.createReminder(
      userId: userId,
      title: title,
      description: description,
      scheduledAt: scheduledAt,
      isActive: isActive,
      snoozeMinutes: snoozeMinutes,
    );
    _reminders = [..._reminders, reminder]
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

    if (reminder.isActive) {
      try {
        await _notificationService.scheduleReminder(reminder);
      } catch (_) {
        // Windows/Web : pas de scheduling → on ignore
      }
    }

    notifyListeners();
    return reminder;
  }

  Future<Reminder> updateReminder(Reminder reminder) async {
    final updated = await _repository.updateReminder(reminder);
    final index = _reminders.indexWhere((item) => item.id == updated.id);
    if (index == -1) {
      _reminders = [..._reminders, updated];
    } else {
      final updatedList = [..._reminders];
      updatedList[index] = updated;
      _reminders = updatedList;
    }
    _reminders.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    try {
      await _notificationService.rescheduleReminder(updated);
    } catch (_) {
      // Windows/Web : pas de scheduling → on ignore
    }
    notifyListeners();
    return updated;
  }

  Future<void> deleteReminder(String id) async {
    final userId = _requireUserId();
    await _repository.deleteReminder(id: id, userId: userId);
    _reminders = _reminders.where((reminder) => reminder.id != id).toList();
    try {
      await _notificationService.cancelReminder(id);
    } catch (_) {
      // Windows/Web : on ignore
    }
    notifyListeners();
  }

  Future<Reminder?> toggleReminder(String id, bool isActive) async {
    final userId = _requireUserId();
    final updated = await _repository.toggleReminder(
      id,
      isActive,
      userId: userId,
    );
    if (updated == null) {
      return null;
    }
    final index = _reminders.indexWhere((reminder) => reminder.id == id);
    if (index != -1) {
      final list = [..._reminders];
      list[index] = updated;
      _reminders = list;
      _reminders.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    }

    if (updated.isActive) {
      try {
        await _notificationService.scheduleReminder(updated);
      } catch (_) {
        // Windows/Web : on ignore
      }
    } else {
      try {
        await _notificationService.cancelReminder(updated.id);
      } catch (_) {
        // Windows/Web : on ignore
      }
    }

    notifyListeners();
    return updated;
  }

  Future<Reminder?> snoozeReminder(String id, int minutes) async {
    final userId = _requireUserId();
    final updated = await _repository.snoozeReminder(
      id,
      minutes,
      userId: userId,
    );
    if (updated == null) {
      return null;
    }
    final index = _reminders.indexWhere((reminder) => reminder.id == id);
    if (index != -1) {
      final list = [..._reminders];
      list[index] = updated;
      _reminders = list;
      _reminders.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    }
    try {
      await _notificationService.rescheduleReminder(updated);
    } catch (_) {
      // Windows/Web : pas de scheduling → on ignore
    }
    notifyListeners();
    return updated;
  }

  Future<List<Reminder>> searchReminders(String keyword) {
    final userId = _authProvider.currentUser?.id;
    if (userId == null) {
      return Future.value(const <Reminder>[]);
    }
    return _repository.searchReminders(keyword, userId: userId);
  }

  Future<void> sortRemindersByDate({bool ascending = true}) async {
    final userId = _requireUserId();
    final sorted = await _repository.sortRemindersByDate(
      userId: userId,
      ascending: ascending,
    );
    _reminders = sorted;
    notifyListeners();
  }

  Future<void> sortRemindersByActive({bool activeFirst = true}) async {
    final userId = _requireUserId();
    final sorted = await _repository.sortRemindersByActive(
      userId: userId,
      activeFirst: activeFirst,
    );
    _reminders = sorted;
    notifyListeners();
  }

  Future<Event> addEvent({
    required String title,
    String? description,
    required DateTime startAt,
    DateTime? endAt,
    String? location,
    bool isAllDay = false,
  }) async {
    final userId = _requireUserId();
    final event = await _repository.createEvent(
      userId: userId,
      title: title,
      description: description,
      startAt: startAt,
      endAt: endAt,
      location: location,
      isAllDay: isAllDay,
    );
    _events = [..._events, event]
      ..sort((a, b) => a.startAt.compareTo(b.startAt));
    notifyListeners();
    return event;
  }

  Future<Event> updateEvent(Event event) async {
    final updated = await _repository.updateEvent(event);
    final index = _events.indexWhere((item) => item.id == updated.id);
    if (index == -1) {
      _events = [..._events, updated];
    } else {
      final updatedList = [..._events];
      updatedList[index] = updated;
      _events = updatedList;
    }
    _events.sort((a, b) => a.startAt.compareTo(b.startAt));
    notifyListeners();
    return updated;
  }

  Future<void> deleteEvent(String id) async {
    final userId = _requireUserId();
    await _repository.deleteEvent(id: id, userId: userId);
    _events = _events.where((event) => event.id != id).toList();
    notifyListeners();
  }

  Future<List<Event>> searchEvents(String keyword) {
    final userId = _authProvider.currentUser?.id;
    if (userId == null) {
      return Future.value(const <Event>[]);
    }
    return _repository.searchEvents(keyword, userId: userId);
  }

  Future<List<Event>> eventsOnDay(DateTime day) {
    final userId = _authProvider.currentUser?.id;
    if (userId == null) {
      return Future.value(const <Event>[]);
    }
    return _repository.eventsOnDay(day, userId: userId);
  }

  Future<List<Event>> eventsInRange(DateTime start, DateTime end) {
    final userId = _authProvider.currentUser?.id;
    if (userId == null) {
      return Future.value(const <Event>[]);
    }
    return _repository.eventsInRange(start, end, userId: userId);
  }

  List<Reminder> remindersForDay(DateTime day) {
    final startOfDay = DateTime(day.year, day.month, day.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return _reminders
        .where((reminder) =>
    !reminder.scheduledAt.isBefore(startOfDay) &&
        reminder.scheduledAt.isBefore(endOfDay))
        .toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
  }

  List<Event> eventsForDay(DateTime day) {
    final startOfDay = DateTime(day.year, day.month, day.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return _events
        .where((event) {
      final start = event.startAt;
      final end = event.endAt ?? event.startAt;
      final overlaps = !end.isBefore(startOfDay) && start.isBefore(endOfDay);
      return overlaps;
    })
        .toList()
      ..sort((a, b) => a.startAt.compareTo(b.startAt));
  }
}