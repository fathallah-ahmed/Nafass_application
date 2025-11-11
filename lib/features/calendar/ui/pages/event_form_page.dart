import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../data/models/event.dart';
import '../../logic/journal_provider.dart';

class EventFormPage extends StatefulWidget {
  const EventFormPage({super.key, this.event});

  final Event? event;

  @override
  State<EventFormPage> createState() => _EventFormPageState();
}

class _EventFormPageState extends State<EventFormPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _locationController;

  late DateTime _startDate;
  late TimeOfDay _startTime;
  DateTime? _endDate;
  TimeOfDay? _endTime;
  late bool _isAllDay;

  @override
  void initState() {
    super.initState();
    final event = widget.event;
    _titleController = TextEditingController(text: event?.title ?? '');
    _descriptionController = TextEditingController(text: event?.description ?? '');
    _locationController = TextEditingController(text: event?.location ?? '');

    final initialStart = event?.startAt ?? DateTime.now().add(const Duration(hours: 1));
    _startDate = DateTime(initialStart.year, initialStart.month, initialStart.day);
    _startTime = TimeOfDay.fromDateTime(initialStart);

    if (event?.endAt != null) {
      final end = event!.endAt!;
      _endDate = DateTime(end.year, end.month, end.day);
      _endTime = TimeOfDay(hour: end.hour, minute: end.minute);
    }
    _isAllDay = event?.isAllDay ?? false;
    if (_isAllDay) {
      _startTime = const TimeOfDay(hour: 8, minute: 0);
      _endTime = null;
      _endDate ??= _startDate;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  DateTime _composeDateTime(DateTime date, TimeOfDay? time, {bool endOfDay = false}) {
    if (_isAllDay || time == null) {
      if (endOfDay) {
        return DateTime(date.year, date.month, date.day, 23, 59);
      }
      return DateTime(date.year, date.month, date.day);
    }
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate.isBefore(now) ? now : _startDate,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
      helpText: 'Date de début',
    );
    if (picked != null) {
      setState(() => _startDate = picked);
      if (_endDate != null && _endDate!.isBefore(picked)) {
        _endDate = picked;
      }
    }
  }

  Future<void> _pickStartTime() async {
    if (_isAllDay) return;
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
      helpText: 'Heure de début',
    );
    if (picked != null) {
      setState(() => _startTime = picked);
    }
  }

  Future<void> _pickEndDate() async {
    final baseDate = _endDate ?? _startDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: baseDate.isBefore(_startDate) ? _startDate : baseDate,
      firstDate: _startDate,
      lastDate: DateTime(_startDate.year + 5),
      helpText: 'Date de fin',
    );
    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  Future<void> _pickEndTime() async {
    if (_isAllDay) return;
    final initial = _endTime ?? _startTime.replacing(hour: (_startTime.hour + 1) % 24);
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      helpText: 'Heure de fin',
    );
    if (picked != null) {
      setState(() => _endTime = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final provider = context.read<JournalProvider>();
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim().isEmpty
        ? null
        : _descriptionController.text.trim();
    final location = _locationController.text.trim().isEmpty
        ? null
        : _locationController.text.trim();

    final startAt = _composeDateTime(_startDate, _startTime);
    DateTime? endAt;
    if (_endDate != null) {
      endAt = _composeDateTime(_endDate!, _endTime, endOfDay: _isAllDay);
    }

    if (endAt != null && endAt.isBefore(startAt)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('La date de fin doit être postérieure au début.')),
        );
      }
      return;
    }

    if (widget.event == null) {
      await provider.addEvent(
        title: title,
        description: description,
        startAt: startAt,
        endAt: endAt,
        location: location,
        isAllDay: _isAllDay,
      );
    } else {
      final updatedEvent = widget.event!.copyWith(
        title: title,
        description: description,
        startAt: startAt,
        endAt: endAt,
        location: location,
        isAllDay: _isAllDay,
      );
      await provider.updateEvent(updatedEvent);
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat.yMMMMd('fr_FR');
    final timeFormat = DateFormat.Hm('fr_FR');

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.event == null ? 'Nouvel évènement' : 'Modifier l\'évènement'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Titre',
                          hintText: 'Ex. Consultation, activité, rencontre…',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Le titre est obligatoire';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        minLines: 2,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _locationController,
                        decoration: const InputDecoration(
                          labelText: 'Lieu',
                          hintText: 'Adresse, salle, visio…',
                        ),
                      ),
                      const SizedBox(height: 24),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        value: _isAllDay,
                        title: const Text('Évènement sur la journée entière'),
                        subtitle: const Text('Activez pour masquer la sélection d\'horaires.'),
                        onChanged: (value) {
                          setState(() {
                            _isAllDay = value;
                            if (value) {
                              _endTime = null;
                              _endDate ??= _startDate;
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      _DateTimePickerRow(
                        label: 'Début',
                        dateLabel: dateFormat.format(_startDate),
                        timeLabel: _isAllDay
                            ? 'Journée complète'
                            : timeFormat.format(
                          DateTime(1970, 1, 1, _startTime.hour, _startTime.minute),
                        ),
                        onDateTap: _pickStartDate,
                        onTimeTap: _isAllDay ? null : _pickStartTime,
                        isAllDay: _isAllDay,
                      ),
                      const SizedBox(height: 16),
                      _DateTimePickerRow(
                        label: 'Fin',
                        dateLabel: _endDate != null
                            ? dateFormat.format(_endDate!)
                            : 'Sélectionner une date',
                        timeLabel: _isAllDay
                            ? 'Journée complète'
                            : (_endTime != null
                            ? timeFormat.format(
                          DateTime(1970, 1, 1, _endTime!.hour, _endTime!.minute),
                        )
                            : 'Pas d\'heure'),
                        onDateTap: _pickEndDate,
                        onTimeTap: _isAllDay ? null : _pickEndTime,
                        isAllDay: _isAllDay,
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: _submit,
                        icon: const Icon(Icons.save_rounded),
                        label: const Text('Enregistrer'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DateTimePickerRow extends StatelessWidget {
  const _DateTimePickerRow({
    required this.label,
    required this.dateLabel,
    required this.timeLabel,
    required this.onDateTap,
    required this.onTimeTap,
    required this.isAllDay,
  });

  final String label;
  final String dateLabel;
  final String timeLabel;
  final VoidCallback onDateTap;
  final VoidCallback? onTimeTap;
  final bool isAllDay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onDateTap,
                icon: const Icon(Icons.calendar_today_rounded),
                label: Text(dateLabel),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onTimeTap,
                icon: const Icon(Icons.schedule_rounded),
                label: Text(timeLabel),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (isAllDay && label == 'Fin')
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Sélectionnez la dernière journée concernée.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }
}