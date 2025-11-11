import 'package:flutter/foundation.dart';

import '../data/models/event.dart';
import '../data/models/reminder.dart';
import '../data/repositories/journal_repository.dart';
import 'notification_service.dart';

class JournalProvider extends ChangeNotifier {
  JournalProvider({
    JournalRepository? repository,
    NotificationService? notificationService,
  })  : _repository = repository ?? JournalRepository(),
        _notificationService = notificationService ?? NotificationService();

  final JournalRepository _repository;
  final NotificationService _notificationService;

  List<Reminder> _reminders = <Reminder>[];
  List<Event> _events = <Event>[];

  bool _isLoading = false;

  List<Reminder> get reminders => List.unmodifiable(_reminders);
  List<Event> get events => List.unmodifiable(_events);
  bool get isLoading => _isLoading;

  Future<void> loadAll() async {
    _isLoading = true;
    notifyListeners();

    final reminders = await _repository.getReminders();
    final events = await _repository.getEvents();

    _reminders = reminders;
    _events = events;
    _isLoading = false;

    await _synchronizeNotifications();

    notifyListeners();
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
    final reminder = await _repository.createReminder(
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
    await _repository.deleteReminder(id);
    _reminders = _reminders.where((reminder) => reminder.id != id).toList();
    try {
      await _notificationService.cancelReminder(id);
    } catch (_) {
      // Windows/Web : on ignore
    }
    notifyListeners();
  }

  Future<Reminder?> toggleReminder(String id, bool isActive) async {
    final updated = await _repository.toggleReminder(id, isActive);
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
    final updated = await _repository.snoozeReminder(id, minutes);
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
    return _repository.searchReminders(keyword);
  }

  Future<void> sortRemindersByDate({bool ascending = true}) async {
    final sorted = await _repository.sortRemindersByDate(ascending: ascending);
    _reminders = sorted;
    notifyListeners();
  }

  Future<void> sortRemindersByActive({bool activeFirst = true}) async {
    final sorted = await _repository.sortRemindersByActive(
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
    final event = await _repository.createEvent(
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
    await _repository.deleteEvent(id);
    _events = _events.where((event) => event.id != id).toList();
    notifyListeners();
  }

  Future<List<Event>> searchEvents(String keyword) {
    return _repository.searchEvents(keyword);
  }

  Future<List<Event>> eventsOnDay(DateTime day) {
    return _repository.eventsOnDay(day);
  }

  Future<List<Event>> eventsInRange(DateTime start, DateTime end) {
    return _repository.eventsInRange(start, end);
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