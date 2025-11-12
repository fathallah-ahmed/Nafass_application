import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../data/models/challenge.dart';
import '../../logic/challenges_provider.dart';

class ChallengeFormPage extends StatefulWidget {
  const ChallengeFormPage({super.key});

  @override
  State<ChallengeFormPage> createState() => _ChallengeFormPageState();
}

class _ChallengeFormPageState extends State<ChallengeFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _goalValueController = TextEditingController();

  Challenge? _editing;
  bool _isInitialized = false;
  bool _isSubmitting = false;

  String _typeAddiction = 'tabac';
  ChallengeGoalType _goalType = ChallengeGoalType.qualitatif;
  ChallengeFrequency _frequency = ChallengeFrequency.quotidien;
  ChallengeState _state = ChallengeState.actif;
  bool _isIndefinite = false;
  DateTime? _startDate;
  DateTime? _endDate;
  TimeOfDay? _reminderTime;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _goalValueController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInitialized) return;
    final args = ModalRoute.of(context)?.settings.arguments;
    final provider = context.read<ChallengesProvider>();
    if (args is Challenge) {
      _editing = args;
    } else if (args is String) {
      try {
        _editing = provider.challenges.firstWhere((challenge) => challenge.id == args);
      } catch (_) {
        _editing = null;
      }
    }
    if (_editing != null) {
      final challenge = _editing!;
      _titleController.text = challenge.title;
      _descriptionController.text = challenge.description ?? '';
      _goalValueController.text = challenge.goalValue?.toString() ?? '';
      _typeAddiction = challenge.typeAddiction;
      _goalType = challenge.goalType;
      _frequency = challenge.frequency;
      _state = challenge.state;
      _isIndefinite = challenge.isIndefinite;
      _startDate = challenge.startDate;
      _endDate = challenge.endDate;
      if (challenge.reminderTime != null) {
        final parts = challenge.reminderTime!.split(':');
        if (parts.length == 2) {
          _reminderTime = TimeOfDay(
            hour: int.tryParse(parts[0]) ?? 0,
            minute: int.tryParse(parts[1]) ?? 0,
          );
        }
      }
    } else {
      _startDate = DateTime.now();
    }
    _isInitialized = true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEdit = _editing != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Modifier le défi' : 'Nouveau défi'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _titleController,
                  maxLength: 80,
                  decoration: const InputDecoration(
                    labelText: 'Titre',
                    hintText: 'Mon défi personnel',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Le titre est requis';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _typeAddiction,
                  decoration: const InputDecoration(labelText: 'Type d\'addiction'),
                  items: const [
                    DropdownMenuItem(value: 'tabac', child: Text('Tabac')),
                    DropdownMenuItem(value: 'alcool', child: Text('Alcool')),
                    DropdownMenuItem(value: 'drogue', child: Text('Drogue')),
                    DropdownMenuItem(value: 'autre', child: Text('Autre')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _typeAddiction = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                Text(
                  'Type d\'objectif',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Column(
                  children: [
                    RadioListTile<ChallengeGoalType>(
                      value: ChallengeGoalType.qualitatif,
                      groupValue: _goalType,
                      title: const Text('Qualitatif'),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _goalType = value;
                            _goalValueController.clear();
                          });
                        }
                      },
                    ),
                    RadioListTile<ChallengeGoalType>(
                      value: ChallengeGoalType.quantitatif,
                      groupValue: _goalType,
                      title: const Text('Quantitatif'),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _goalType = value);
                        }
                      },
                    ),
                  ],
                ),
                if (_goalType == ChallengeGoalType.quantitatif)
                  TextFormField(
                    controller: _goalValueController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Valeur cible',
                      hintText: 'Ex: 2.5',
                    ),
                    validator: (value) {
                      if (_goalType == ChallengeGoalType.quantitatif) {
                        final parsed = double.tryParse(value ?? '');
                        if (parsed == null || parsed <= 0) {
                          return 'Une valeur positive est requise';
                        }
                      }
                      return null;
                    },
                  ),
                const SizedBox(height: 12),
                DropdownButtonFormField<ChallengeFrequency>(
                  value: _frequency,
                  decoration: const InputDecoration(labelText: 'Fréquence'),
                  items: const [
                    DropdownMenuItem(
                      value: ChallengeFrequency.quotidien,
                      child: Text('Quotidien'),
                    ),
                    DropdownMenuItem(
                      value: ChallengeFrequency.hebdomadaire,
                      child: Text('Hebdomadaire'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _frequency = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                _DateField(
                  label: 'Date de début',
                  value: _startDate,
                  onSelect: (date) => setState(() => _startDate = date),
                ),
                const SizedBox(height: 12),
                _DateField(
                  label: 'Date de fin (optionnelle)',
                  value: _isIndefinite ? null : _endDate,
                  onSelect: (date) => setState(() {
                    _isIndefinite = false;
                    _endDate = date;
                  }),
                  isOptional: true,
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: _isIndefinite,
                  title: const Text('Défi sans date de fin'),
                  subtitle: const Text('Continuer indéfiniment jusqu\'à archivage'),
                  onChanged: (value) {
                    setState(() {
                      _isIndefinite = value;
                      if (value) {
                        _endDate = null;
                      }
                    });
                  },
                ),
                const SizedBox(height: 12),
                _TimeField(
                  label: 'Rappel (optionnel)',
                  value: _reminderTime,
                  onSelect: (time) => setState(() => _reminderTime = time),
                ),
                if (_editing != null) ...[
                  const SizedBox(height: 12),
                  if (_state == ChallengeState.actif || _state == ChallengeState.en_pause)
                    DropdownButtonFormField<ChallengeState>(
                      value: _state,
                      decoration: const InputDecoration(labelText: 'Statut du défi'),
                      items: const [
                        DropdownMenuItem(
                          value: ChallengeState.actif,
                          child: Text('Actif'),
                        ),
                        DropdownMenuItem(
                          value: ChallengeState.en_pause,
                          child: Text('En pause'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _state = value);
                        }
                      },
                    )
                  else
                    InputDecorator(
                      decoration: const InputDecoration(labelText: 'Statut du défi'),
                      child: Text(_statusLabel(_state)),
                    ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isSubmitting ? null : _submit,
                    child: _isSubmitting
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : Text(isEdit ? 'Mettre à jour' : 'Créer le défi'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La date de début est obligatoire.')),
      );
      return;
    }
    final provider = context.read<ChallengesProvider>();
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim().isEmpty
        ? null
        : _descriptionController.text.trim();
    final goalValue = _goalType == ChallengeGoalType.quantitatif
        ? double.tryParse(_goalValueController.text.trim())
        : null;
    if (_goalType == ChallengeGoalType.quantitatif && (goalValue == null || goalValue <= 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez saisir une valeur cible positive.')),
      );
      return;
    }
    final effectiveEndDate = _isIndefinite ? null : _endDate;
    if (effectiveEndDate != null && effectiveEndDate.isBefore(_startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La date de fin doit être postérieure à la date de début.')),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    final reminderString = _reminderTime == null
        ? null
        : '${_reminderTime!.hour.toString().padLeft(2, '0')}:${_reminderTime!.minute.toString().padLeft(2, '0')}';
    try {
      if (_editing == null) {
        await provider.createChallenge(
          title: title,
          description: description,
          typeAddiction: _typeAddiction,
          goalType: _goalType,
          goalValue: goalValue,
          frequency: _frequency,
          startDate: _startDate!,
          endDate: effectiveEndDate,
          isIndefinite: _isIndefinite,
          reminderTime: reminderString,
          state: _state,
        );
      } else {
        final updated = _editing!.copyWith(
          title: title,
          description: description,
          typeAddiction: _typeAddiction,
          goalType: _goalType,
          goalValue: goalValue,
          frequency: _frequency,
          startDate: _startDate!,
          endDate: effectiveEndDate,
          isIndefinite: _isIndefinite,
          reminderTime: reminderString,
          state: _state,
        );
        await provider.updateChallenge(updated);
      }
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossible d\'enregistrer le défi : $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  String _statusLabel(ChallengeState state) {
    switch (state) {
      case ChallengeState.actif:
        return 'Actif';
      case ChallengeState.en_pause:
        return 'En pause';
      case ChallengeState.termine:
        return 'Terminé';
      case ChallengeState.echoue:
        return 'Échoué';
      case ChallengeState.archive:
        return 'Archivé';
    }
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onSelect,
    this.isOptional = false,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onSelect;
  final bool isOptional;

  @override
  Widget build(BuildContext context) {
    final display = value != null
        ? DateFormat('dd MMM yyyy', 'fr').format(value!)
        : (isOptional ? 'Aucune date' : 'Sélectionner une date');
    return GestureDetector(
      onTap: () async {
        final now = DateTime.now();
        final initial = value ?? now;
        final picked = await showDatePicker(
          context: context,
          initialDate: initial,
          firstDate: DateTime(now.year - 5),
          lastDate: DateTime(now.year + 10),
          locale: const Locale('fr'),
        );
        if (picked != null) {
          onSelect(picked);
        } else if (isOptional && value != null) {
          onSelect(null);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: isOptional && value != null
              ? IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () => onSelect(null),
          )
              : const Icon(Icons.event),
        ),
        child: Text(display),
      ),
    );
  }
}

class _TimeField extends StatelessWidget {
  const _TimeField({
    required this.label,
    required this.value,
    required this.onSelect,
  });

  final String label;
  final TimeOfDay? value;
  final ValueChanged<TimeOfDay?> onSelect;

  @override
  Widget build(BuildContext context) {
    final display = value != null
        ? value!.format(context)
        : 'Aucun rappel';
    return GestureDetector(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: value ?? const TimeOfDay(hour: 9, minute: 0),
        );
        if (picked != null) {
          onSelect(picked);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: value != null
              ? IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () => onSelect(null),
          )
              : const Icon(Icons.schedule),
        ),
        child: Text(display),
      ),
    );
  }
}