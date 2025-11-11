import 'package:uuid/uuid.dart';

import '../../../../core/storage/local_json_store.dart';
import '../models/event.dart';
import '../models/reminder.dart';

class JournalRepository {
  JournalRepository({LocalJsonStore? store})
      : _store = store ??
      LocalJsonStore(
        runtimeDirectory: 'data_dev/data',
      );

  final LocalJsonStore _store;
  final Uuid _uuid = const Uuid();

  static const String _remindersFile = 'reminders.json';
  static const String _eventsFile = 'events.json';

  Future<List<Reminder>> _readReminders() async {
    final rawList = await _store.readList(_remindersFile);
    return rawList.map(Reminder.fromJson).toList();
  }

  Future<void> _writeReminders(List<Reminder> reminders) async {
    await _store.writeList(
      _remindersFile,
      reminders.map((reminder) => reminder.toJson()).toList(),
    );
  }

  Future<List<Event>> _readEvents() async {
    final rawList = await _store.readList(_eventsFile);
    return rawList.map(Event.fromJson).toList();
  }

  Future<void> _writeEvents(List<Event> events) async {
    await _store.writeList(
      _eventsFile,
      events.map((event) => event.toJson()).toList(),
    );
  }

  Future<List<Reminder>> getReminders() async {
    final reminders = await _readReminders();
    reminders.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    return reminders;
  }

  Future<Reminder> createReminder({
    required String title,
    String? description,
    required DateTime scheduledAt,
    bool isActive = true,
    int snoozeMinutes = 5,
  }) async {
    final reminders = await _readReminders();
    final now = DateTime.now();
    final reminder = Reminder(
      id: _uuid.v4(),
      title: title,
      description: description,
      scheduledAt: scheduledAt,
      isActive: isActive,
      snoozeMinutes: snoozeMinutes,
      createdAt: now,
      updatedAt: now,
    );
    await _writeReminders(<Reminder>[...reminders, reminder]);
    return reminder;
  }

  Future<Reminder> updateReminder(Reminder reminder) async {
    final reminders = await _readReminders();
    final index = reminders.indexWhere((item) => item.id == reminder.id);
    if (index == -1) {
      throw StateError('Reminder not found: ${reminder.id}');
    }
    final updated = reminder.copyWith(updatedAt: DateTime.now());
    final updatedList = [...reminders];
    updatedList[index] = updated;
    await _writeReminders(updatedList);
    return updated;
  }

  Future<void> deleteReminder(String id) async {
    final reminders = await _readReminders();
    final updated = reminders.where((reminder) => reminder.id != id).toList();
    await _writeReminders(updated);
  }

  Future<Reminder?> toggleReminder(String id, bool isActive) async {
    final reminders = await _readReminders();
    final index = reminders.indexWhere((reminder) => reminder.id == id);
    if (index == -1) {
      return null;
    }
    final updatedReminder = reminders[index]
        .copyWith(isActive: isActive, updatedAt: DateTime.now());
    final updatedList = [...reminders];
    updatedList[index] = updatedReminder;
    await _writeReminders(updatedList);
    return updatedReminder;
  }

  Future<Reminder?> snoozeReminder(String id, int minutes) async {
    final reminders = await _readReminders();
    final index = reminders.indexWhere((reminder) => reminder.id == id);
    if (index == -1) {
      return null;
    }
    final original = reminders[index];
    final snoozed = original.copyWith(
      scheduledAt: original.scheduledAt.add(Duration(minutes: minutes)),
      updatedAt: DateTime.now(),
    );
    final updatedList = [...reminders];
    updatedList[index] = snoozed;
    await _writeReminders(updatedList);
    return snoozed;
  }

  Future<List<Reminder>> searchReminders(String keyword) async {
    final lowerKeyword = keyword.toLowerCase().trim();
    if (lowerKeyword.isEmpty) {
      return getReminders();
    }
    final reminders = await _readReminders();
    final filtered = reminders.where((reminder) {
      final title = reminder.title.toLowerCase();
      final description = reminder.description?.toLowerCase() ?? '';
      return title.contains(lowerKeyword) || description.contains(lowerKeyword);
    }).toList();
    filtered.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    return filtered;
  }

  Future<List<Reminder>> sortRemindersByDate({bool ascending = true}) async {
    final reminders = await _readReminders();
    final sorted = [...reminders]
      ..sort((a, b) => ascending
          ? a.scheduledAt.compareTo(b.scheduledAt)
          : b.scheduledAt.compareTo(a.scheduledAt));
    return sorted;
  }

  Future<List<Reminder>> sortRemindersByActive({
    bool activeFirst = true,
  }) async {
    final reminders = await _readReminders();
    final sorted = [...reminders]
      ..sort((a, b) {
        if (a.isActive == b.isActive) {
          return a.scheduledAt.compareTo(b.scheduledAt);
        }
        if (a.isActive) {
          return activeFirst ? -1 : 1;
        }
        return activeFirst ? 1 : -1;
      });
    return sorted;
  }

  Future<List<Event>> getEvents() async {
    final events = await _readEvents();
    events.sort((a, b) => a.startAt.compareTo(b.startAt));
    return events;
  }

  Future<Event> createEvent({
    required String title,
    String? description,
    required DateTime startAt,
    DateTime? endAt,
    String? location,
    bool isAllDay = false,
  }) async {
    final events = await _readEvents();
    final now = DateTime.now();
    final event = Event(
      id: _uuid.v4(),
      title: title,
      description: description,
      startAt: startAt,
      endAt: endAt,
      location: location,
      isAllDay: isAllDay,
      createdAt: now,
      updatedAt: now,
    );
    await _writeEvents(<Event>[...events, event]);
    return event;
  }

  Future<Event> updateEvent(Event event) async {
    final events = await _readEvents();
    final index = events.indexWhere((item) => item.id == event.id);
    if (index == -1) {
      throw StateError('Event not found: ${event.id}');
    }
    final updated = event.copyWith(updatedAt: DateTime.now());
    final updatedList = [...events];
    updatedList[index] = updated;
    await _writeEvents(updatedList);
    return updated;
  }

  Future<void> deleteEvent(String id) async {
    final events = await _readEvents();
    final updated = events.where((event) => event.id != id).toList();
    await _writeEvents(updated);
  }

  Future<List<Event>> searchEvents(String keyword) async {
    final lowerKeyword = keyword.toLowerCase().trim();
    if (lowerKeyword.isEmpty) {
      return getEvents();
    }
    final events = await _readEvents();
    final filtered = events.where((event) {
      final title = event.title.toLowerCase();
      final description = event.description?.toLowerCase() ?? '';
      final location = event.location?.toLowerCase() ?? '';
      return title.contains(lowerKeyword) ||
          description.contains(lowerKeyword) ||
          location.contains(lowerKeyword);
    }).toList();
    filtered.sort((a, b) => a.startAt.compareTo(b.startAt));
    return filtered;
  }

  Future<List<Event>> eventsOnDay(DateTime day) async {
    final events = await _readEvents();
    final startOfDay = DateTime(day.year, day.month, day.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    bool occursOnDay(Event event) {
      final start = event.startAt;
      final end = event.endAt ?? event.startAt;
      return !(end.isBefore(startOfDay) || start.isAfter(endOfDay));
    }

    final filtered = events.where(occursOnDay).toList();
    filtered.sort((a, b) => a.startAt.compareTo(b.startAt));
    return filtered;
  }

  Future<List<Event>> eventsInRange(DateTime start, DateTime end) async {
    final events = await _readEvents();
    final normalizedStart = start.isBefore(end) ? start : end;
    final normalizedEnd = end.isAfter(start) ? end : start;

    bool overlaps(Event event) {
      final eventEnd = event.endAt ?? event.startAt;
      return !(eventEnd.isBefore(normalizedStart) ||
          event.startAt.isAfter(normalizedEnd));
    }

    final filtered = events.where(overlaps).toList();
    filtered.sort((a, b) => a.startAt.compareTo(b.startAt));
    return filtered;
  }
}