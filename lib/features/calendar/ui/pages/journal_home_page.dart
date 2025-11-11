import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../data/models/event.dart';
import '../../data/models/reminder.dart';
import '../../logic/journal_provider.dart';
import 'calendar_page.dart';
import 'event_form_page.dart';
import 'reminder_form_page.dart';

class JournalHomePage extends StatefulWidget {
  const JournalHomePage({super.key});

  @override
  State<JournalHomePage> createState() => _JournalHomePageState();
}

class _JournalHomePageState extends State<JournalHomePage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _eventSearchController = TextEditingController();

  String _reminderSort = 'date';
  bool _dateAscending = true;
  bool _activeFirst = true;
  String _eventQuery = '';
  List<Event> _eventSearchResults = const <Event>[];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this)
      ..addListener(() => setState(() {}));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<JournalProvider>().loadAll();
    });

    _eventSearchController.addListener(() {
      final query = _eventSearchController.text;
      _searchEvents(query);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _eventSearchController.dispose();
    super.dispose();
  }

  Future<void> _searchEvents(String query) async {
    final provider = context.read<JournalProvider>();
    final results = await provider.searchEvents(query);
    if (!mounted) return;
    setState(() {
      _eventQuery = query;
      _eventSearchResults = query.trim().isEmpty ? const <Event>[] : results;
    });
  }

  void _openReminderForm([Reminder? reminder]) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ReminderFormPage(reminder: reminder),
      ),
    );
  }

  void _openEventForm([Event? event]) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => EventFormPage(event: event),
      ),
    );
  }

  Widget? _buildFab() {
    if (_tabController.index == 0) {
      return FloatingActionButton.extended(
        onPressed: () => _openReminderForm(),
        icon: const Icon(Icons.add_alarm_rounded),
        label: const Text('Nouveau rappel'),
      );
    }
    if (_tabController.index == 1) {
      return FloatingActionButton.extended(
        onPressed: () => _openEventForm(),
        icon: const Icon(Icons.event_available_rounded),
        label: const Text('Nouvel évènement'),
      );
    }
    return null;
  }

  Future<void> _handleReminderSort(JournalProvider provider, String criteria) async {
    if (criteria == 'date') {
      if (_reminderSort == 'date') {
        _dateAscending = !_dateAscending;
      } else {
        _reminderSort = 'date';
      }
      await provider.sortRemindersByDate(ascending: _dateAscending);
    } else {
      if (_reminderSort == 'active') {
        _activeFirst = !_activeFirst;
      } else {
        _reminderSort = 'active';
      }
      await provider.sortRemindersByActive(activeFirst: _activeFirst);
    }
    setState(() {
      _reminderSort = criteria;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Journal'),
        actions: [
          IconButton(
            tooltip: 'Rechercher',
            icon: const Icon(Icons.search_rounded),
            onPressed: () {
              final provider = context.read<JournalProvider>();
              showSearch<void>(
                context: context,
                delegate: JournalSearchDelegate(provider),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: colorScheme.primary,
          labelColor: colorScheme.primary,
          unselectedLabelColor: colorScheme.onSurfaceVariant,
          tabs: const [
            Tab(text: 'Rappels'),
            Tab(text: 'Événements'),
            Tab(text: 'Calendrier'),
          ],
        ),
      ),
      floatingActionButton: _buildFab(),
      body: TabBarView(
        controller: _tabController,
        children: [
          _RemindersTab(
            onEdit: _openReminderForm,
            onSort: _handleReminderSort,
            sortKey: _reminderSort,
            activeFirst: _activeFirst,
            dateAscending: _dateAscending,
          ),
          _EventsTab(
            controller: _eventSearchController,
            results: _eventQuery.isEmpty
                ? null
                : _eventSearchResults,
            onEdit: _openEventForm,
          ),
          const CalendarPage(),
        ],
      ),
    );
  }
}

class _RemindersTab extends StatelessWidget {
  const _RemindersTab({
    required this.onEdit,
    required this.onSort,
    required this.sortKey,
    required this.activeFirst,
    required this.dateAscending,
  });

  final ValueChanged<Reminder?> onEdit;
  final Future<void> Function(JournalProvider provider, String criteria) onSort;
  final String sortKey;
  final bool activeFirst;
  final bool dateAscending;

  @override
  Widget build(BuildContext context) {
    return Consumer<JournalProvider>(
      builder: (context, provider, _) {
        final reminders = provider.reminders;
        if (provider.isLoading && reminders.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 12,
                  children: [
                    FilterChip(
                      label: Text('Date ${dateAscending ? '↑' : '↓'}'),
                      selected: sortKey == 'date',
                      onSelected: (_) => onSort(provider, 'date'),
                    ),
                    FilterChip(
                      label: Text(activeFirst ? 'Actifs en premier' : 'Inactifs en premier'),
                      selected: sortKey == 'active',
                      onSelected: (_) => onSort(provider, 'active'),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: reminders.isEmpty
                  ? const _EmptyPlaceholder(
                icon: Icons.alarm_add_rounded,
                message: 'Aucun rappel enregistré. Ajoutez-en un pour ne rien oublier.',
              )
                  : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
                itemCount: reminders.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final reminder = reminders[index];
                  return _ReminderTile(
                    reminder: reminder,
                    onEdit: () => onEdit(reminder),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ReminderTile extends StatelessWidget {
  const _ReminderTile({
    required this.reminder,
    required this.onEdit,
  });

  final Reminder reminder;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<JournalProvider>();
    final theme = Theme.of(context);
    final dateFormat = DateFormat.yMMMMd('fr_FR');
    final timeFormat = DateFormat.Hm('fr_FR');

    Future<bool> handleDelete() async {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Supprimer le rappel ?'),
          content: const Text('Cette action est irréversible.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Supprimer'),
            ),
          ],
        ),
      );
      if (confirmed ?? false) {
        await provider.deleteReminder(reminder.id);
        return true;
      }
      return false;
    }

    Future<void> handleSnooze(int minutes) async {
      await provider.snoozeReminder(reminder.id, minutes);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rappel reporté de $minutes minutes.'),
          ),
        );
      }
    }

    return Dismissible(
      key: ValueKey(reminder.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => handleDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(
          Icons.delete_forever_rounded,
          color: theme.colorScheme.onErrorContainer,
        ),
      ),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reminder.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${dateFormat.format(reminder.scheduledAt)} • ${timeFormat.format(reminder.scheduledAt)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if ((reminder.description ?? '').isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        reminder.description!,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        Chip(
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
                        Chip(
                          label: Text('Rappel +${reminder.snoozeMinutes} min'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Switch.adaptive(
                    value: reminder.isActive,
                    onChanged: (value) => provider.toggleReminder(
                      reminder.id,
                      value,
                    ),
                  ),
                  PopupMenuButton<int>(
                    icon: const Icon(Icons.more_vert_rounded),
                    onSelected: (value) async {
                      if (value == -1) {
                        onEdit();
                      } else if (value == -2) {
                        await handleDelete();
                      } else {
                        await handleSnooze(value);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem<int>(
                        value: 5,
                        child: Text('Reporter de 5 minutes'),
                      ),
                      const PopupMenuItem<int>(
                        value: 10,
                        child: Text('Reporter de 10 minutes'),
                      ),
                      const PopupMenuItem<int>(
                        value: 15,
                        child: Text('Reporter de 15 minutes'),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem<int>(
                        value: -1,
                        child: Text('Modifier'),
                      ),
                      const PopupMenuItem<int>(
                        value: -2,
                        child: Text('Supprimer'),
                      ),
                    ],
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _EventsTab extends StatelessWidget {
  const _EventsTab({
    required this.controller,
    required this.results,
    required this.onEdit,
  });

  final TextEditingController controller;
  final List<Event>? results;
  final ValueChanged<Event?> onEdit;

  @override
  Widget build(BuildContext context) {
    return Consumer<JournalProvider>(
      builder: (context, provider, _) {
        final List<Event> events =
        (results == null || results!.isEmpty && controller.text.isEmpty)
            ? provider.events
            : (controller.text.isEmpty ? provider.events : results!);

        if (provider.isLoading && provider.events.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: 'Rechercher un évènement',
                  prefixIcon: const Icon(Icons.search_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: events.isEmpty
                  ? const _EmptyPlaceholder(
                icon: Icons.event_busy_rounded,
                message: 'Aucun évènement pour le moment.',
              )
                  : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
                itemBuilder: (context, index) {
                  final event = events[index];
                  return _EventTile(
                    event: event,
                    onEdit: () => onEdit(event),
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemCount: events.length,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _EventTile extends StatelessWidget {
  const _EventTile({
    required this.event,
    required this.onEdit,
  });

  final Event event;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<JournalProvider>();
    final theme = Theme.of(context);
    final dateFormat = DateFormat.yMMMMd('fr_FR');
    final timeFormat = DateFormat.Hm('fr_FR');

    Future<void> handleDelete() async {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Supprimer l\'évènement ?'),
          content: const Text('Cette action est irréversible.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Supprimer'),
            ),
          ],
        ),
      );
      if (confirmed ?? false) {
        await provider.deleteEvent(event.id);
      }
    }

    String buildDateRange() {
      final startDate = dateFormat.format(event.startAt);
      final startTime = timeFormat.format(event.startAt);
      if (event.isAllDay) {
        if (event.endAt != null &&
            dateFormat.format(event.endAt!) != startDate) {
          final endDate = dateFormat.format(event.endAt!);
          return '$startDate → $endDate (journée entière)';
        }
        return '$startDate • Journée entière';
      }
      if (event.endAt == null) {
        return '$startDate • $startTime';
      }
      final sameDay = DateUtils.isSameDay(event.startAt, event.endAt);
      final endDate = dateFormat.format(event.endAt!);
      final endTime = timeFormat.format(event.endAt!);
      return sameDay
          ? '$startDate • $startTime → $endTime'
          : '$startDate • $startTime → $endDate • $endTime';
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
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
                      Text(
                        buildDateRange(),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'edit') {
                      onEdit();
                    } else if (value == 'delete') {
                      await handleDelete();
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem<String>(
                      value: 'edit',
                      child: Text('Modifier'),
                    ),
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: Text('Supprimer'),
                    ),
                  ],
                ),
              ],
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
                  Expanded(
                    child: Text(
                      event.location!,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
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

class _EmptyPlaceholder extends StatelessWidget {
  const _EmptyPlaceholder({
    required this.icon,
    required this.message,
  });

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              message,
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

class JournalSearchDelegate extends SearchDelegate<void> {
  JournalSearchDelegate(this.provider)
      : super(searchFieldLabel: 'Rechercher un rappel ou un évènement');

  final JournalProvider provider;

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear_rounded),
          onPressed: () {
            query = '';
            showSuggestions(context);
          },
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back_rounded),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildResultList();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildResultList();
  }

  Widget _buildResultList() {
    final keyword = query.trim();
    if (keyword.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('Commencez à taper pour lancer une recherche.'),
        ),
      );
    }

    return FutureBuilder<_SearchResults>(
      future: _performSearch(keyword),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData ||
            (snapshot.data!.reminders.isEmpty && snapshot.data!.events.isEmpty)) {
          return const Center(child: Text('Aucun résultat trouvé.'));
        }

        final reminders = snapshot.data!.reminders;
        final events = snapshot.data!.events;
        final theme = Theme.of(context);

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (reminders.isNotEmpty) ...[
              Text(
                'Rappels',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              ...reminders.map(
                    (reminder) => Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    title: Text(reminder.title),
                    subtitle: Text(DateFormat.yMMMMd('fr_FR')
                        .add_Hm()
                        .format(reminder.scheduledAt)),
                    onTap: () {
                      close(context, null);
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ReminderFormPage(reminder: reminder),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
            if (events.isNotEmpty) ...[
              Text(
                'Événements',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              ...events.map(
                    (event) => Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    title: Text(event.title),
                    subtitle: Text(DateFormat.yMMMMd('fr_FR')
                        .add_Hm()
                        .format(event.startAt)),
                    onTap: () {
                      close(context, null);
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => EventFormPage(event: event),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Future<_SearchResults> _performSearch(String keyword) async {
    final reminders = await provider.searchReminders(keyword);
    final events = await provider.searchEvents(keyword);
    return _SearchResults(reminders: reminders, events: events);
  }
}

class _SearchResults {
  const _SearchResults({
    required this.reminders,
    required this.events,
  });

  final List<Reminder> reminders;
  final List<Event> events;
}