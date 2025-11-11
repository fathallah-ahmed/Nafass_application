import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../data/models/event.dart';
import '../../data/models/reminder.dart';
import '../../logic/journal_provider.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  CalendarFormat _format = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedDay = now;
    _selectedDay = DateTime(now.year, now.month, now.day);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<JournalProvider>(
      builder: (context, provider, _) {
        final reminders = provider.remindersForDay(_selectedDay);
        final events = provider.eventsForDay(_selectedDay);

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: TableCalendar<dynamic>(
                    firstDay: DateTime(2010),
                    lastDay: DateTime(2100),
                    focusedDay: _focusedDay,
                    calendarFormat: _format,
                    availableCalendarFormats: const {
                      CalendarFormat.month: 'Mois',
                      CalendarFormat.twoWeeks: '2 semaines',
                      CalendarFormat.week: 'Semaine',
                    },
                    selectedDayPredicate: (day) => DateUtils.isSameDay(day, _selectedDay),
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = DateTime(
                          selectedDay.year,
                          selectedDay.month,
                          selectedDay.day,
                        );
                        _focusedDay = focusedDay;
                      });
                    },
                    onFormatChanged: (format) {
                      setState(() => _format = format);
                    },
                    onPageChanged: (focusedDay) => _focusedDay = focusedDay,
                    eventLoader: (day) {
                      final items = <Object>[];
                      items.addAll(provider.eventsForDay(day));
                      items.addAll(provider.remindersForDay(day));
                      return items;
                    },
                    calendarStyle: CalendarStyle(
                      markersAlignment: Alignment.bottomCenter,
                      markerDecoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      todayDecoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.18),
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    headerStyle: HeaderStyle(
                      formatButtonVisible: true,
                      titleCentered: true,
                      titleTextFormatter: (date, locale) => DateFormat.yMMMM(locale).format(date),
                      leftChevronIcon: const Icon(Icons.chevron_left_rounded),
                      rightChevronIcon: const Icon(Icons.chevron_right_rounded),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: (reminders.isEmpty && events.isEmpty)
                  ? const _CalendarEmptyState()
                  : ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                children: [
                  _CalendarSection(
                    title: 'Rappels',
                    children: reminders
                        .map((reminder) => _ReminderCard(reminder: reminder))
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                  _CalendarSection(
                    title: 'Événements',
                    children:
                    events.map((event) => _EventCard(event: event)).toList(),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CalendarSection extends StatelessWidget {
  const _CalendarSection({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }
}

class _CalendarEmptyState extends StatelessWidget {
  const _CalendarEmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today_rounded, size: 56, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              'Aucun rappel ni évènement pour cette journée.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  const _ReminderCard({required this.reminder});

  final Reminder reminder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeFormat = DateFormat.Hm('fr_FR');
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  reminder.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  timeFormat.format(reminder.scheduledAt),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            if ((reminder.description ?? '').isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(reminder.description!),
            ],
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Chip(
                label: Text(reminder.isActive ? 'Actif' : 'Inactif'),
                backgroundColor: reminder.isActive
                    ? theme.colorScheme.primaryContainer
                    : theme.colorScheme.surfaceVariant,
                labelStyle: theme.textTheme.bodySmall?.copyWith(
                  color: reminder.isActive
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event});

  final Event event;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat.Hm('fr_FR');
    final dayFormat = DateFormat.yMMMMd('fr_FR');
    final hasTime = !event.isAllDay;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              event.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            if (event.endAt != null)
              Text(
                hasTime
                    ? '${dayFormat.format(event.startAt)} • ${dateFormat.format(event.startAt)} → ${dateFormat.format(event.endAt!)}'
                    : '${dayFormat.format(event.startAt)} → ${dayFormat.format(event.endAt!)}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else
              Text(
                hasTime
                    ? '${dayFormat.format(event.startAt)} • ${dateFormat.format(event.startAt)}'
                    : dayFormat.format(event.startAt),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            if ((event.description ?? '').isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(event.description!),
            ],
            if ((event.location ?? '').isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.place_rounded, size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(child: Text(event.location!)),
                ],
              ),
            ],
            if (event.isAllDay)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Chip(
                  label: const Text('Journée entière'),
                  backgroundColor: theme.colorScheme.secondaryContainer,
                  labelStyle: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}