import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../data/models/reminder.dart';
import '../../logic/journal_provider.dart';

class ReminderFormPage extends StatefulWidget {
  const ReminderFormPage({super.key, this.reminder});

  final Reminder? reminder;

  @override
  State<ReminderFormPage> createState() => _ReminderFormPageState();
}

class _ReminderFormPageState extends State<ReminderFormPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late bool _isActive;
  late int _snoozeMinutes;

  final List<int> _snoozeOptions = const <int>[5, 10, 15, 30, 60];

  @override
  void initState() {
    super.initState();
    final reminder = widget.reminder;
    _titleController = TextEditingController(text: reminder?.title ?? '');
    _descriptionController =
        TextEditingController(text: reminder?.description ?? '');
    final scheduledAt = reminder?.scheduledAt ?? DateTime.now().add(const Duration(minutes: 30));
    _selectedDate = DateTime(scheduledAt.year, scheduledAt.month, scheduledAt.day);
    _selectedTime = TimeOfDay.fromDateTime(scheduledAt);
    _isActive = reminder?.isActive ?? true;
    _snoozeMinutes = reminder?.snoozeMinutes ?? 5;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  DateTime get _scheduledDateTime {
    return DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isBefore(now) ? now : _selectedDate,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
      helpText: 'Choisir une date',
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      helpText: 'Choisir une heure',
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
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
    final scheduledAt = _scheduledDateTime;

    if (widget.reminder == null) {
      await provider.addReminder(
        title: title,
        description: description,
        scheduledAt: scheduledAt,
        isActive: _isActive,
        snoozeMinutes: _snoozeMinutes,
      );
    } else {
      final updatedReminder = widget.reminder!.copyWith(
        title: title,
        description: description,
        scheduledAt: scheduledAt,
        isActive: _isActive,
        snoozeMinutes: _snoozeMinutes,
      );
      await provider.updateReminder(updatedReminder);
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMMd('fr_FR');
    final timeFormat = DateFormat.Hm('fr_FR');

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.reminder == null ? 'Nouveau rappel' : 'Modifier le rappel'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
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
                          hintText: 'Ex. Rendez-vous médical',
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
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          hintText: 'Ajoutez des détails complémentaires',
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _pickDate,
                              icon: const Icon(Icons.calendar_month_rounded),
                              label: Text(dateFormat.format(_selectedDate)),
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
                              onPressed: _pickTime,
                              icon: const Icon(Icons.schedule_rounded),
                              label: Text(timeFormat.format(
                                  DateTime(1970, 1, 1, _selectedTime.hour, _selectedTime.minute))),
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
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        value: _snoozeMinutes,
                        decoration: const InputDecoration(
                          labelText: 'Durée de report',
                        ),
                        items: _snoozeOptions
                            .map(
                              (minutes) => DropdownMenuItem<int>(
                            value: minutes,
                            child: Text('$minutes minutes'),
                          ),
                        )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _snoozeMinutes = value);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        value: _isActive,
                        title: const Text('Activer le rappel'),
                        subtitle: const Text(
                            'Désactivez pour conserver le rappel sans notification.'),
                        onChanged: (value) => setState(() => _isActive = value),
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