import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../core/utils/validators.dart';
import '../../data/models/medicament_model.dart';
import '../../logic/medicament_provider.dart';

class MedicamentFormPage extends StatefulWidget {
  const MedicamentFormPage({super.key, this.medicament});

  final Medicament? medicament;

  bool get isEdit => medicament != null;

  @override
  State<MedicamentFormPage> createState() => _MedicamentFormPageState();
}

class _MedicamentFormPageState extends State<MedicamentFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _timesFieldKey = GlobalKey<FormFieldState<List<String>>>();

  late final TextEditingController _nameController;
  late final TextEditingController _dosageController;
  late final TextEditingController _timeInputController;
  late final FocusNode _timeInputFocusNode;

  late DateTime _startDate;
  late DateTime _endDate;
  late List<String> _intakeTimes;

  @override
  void initState() {
    super.initState();
    final medicament = widget.medicament;
    _nameController = TextEditingController(text: medicament?.nom ?? '');
    _dosageController = TextEditingController(text: medicament?.dosage ?? '');
    _timeInputController = TextEditingController();
    _timeInputFocusNode = FocusNode();

    _startDate = medicament?.debut ?? DateTime.now();
    _endDate = medicament?.fin ?? DateTime.now().add(const Duration(days: 7));
    _intakeTimes = List<String>.from(medicament?.heures ?? <String>[]);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _timeInputController.dispose();
    _timeInputFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isEdit
        ? 'Modifier un traitement'
        : 'Ajouter un traitement';

    return Scaffold(
        appBar: AppBar(
          title: Text(title),
        ), body: SafeArea(
        child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  Text(
                  'Informations générales',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Nom du médicament',
                    hintText: 'Ex : Doliprane',
                  ),
                  validator: MedicationValidators.validateName,
                ),const SizedBox(height: 16),
                TextFormField(
                  controller: _dosageController,
                  decoration: const InputDecoration(
                    labelText: 'Dosage',
                    hintText: 'Ex : 500 mg',
                  ),
                  validator: MedicationValidators.validateDosage,
                  textInputAction: TextInputAction.next,
                ),const SizedBox(height: 24),
                Text(
                  'Période de traitement',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ), const SizedBox(height: 12),
              Row(
                children: [
              Expanded(
              child: _DatePickerField(
              label: 'Date de début',
                date: _startDate,
                onTap: () async {
                  final picked = await _pickDate(context, _startDate);
                  if (picked != null) {
                    setState(() {
                      _startDate = _combineDate(picked);
                      if (_endDate.isBefore(_startDate)) {
                        _endDate = _startDate;
                      }
                    });
                  }
                },
              ),
            ),const SizedBox(width: 12),
                  Expanded(
                    child: _DatePickerField(
                      label: 'Date de fin',
                      date: _endDate,
                      onTap: () async {
                        final picked = await _pickDate(context, _endDate);
                        if (picked != null) {
                          setState(() {
                            _endDate = _combineDate(picked);
                            if (_endDate.isBefore(_startDate)) {
                              _startDate = _endDate;
                            }
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
                const SizedBox(height: 24),
                Text(
                  'Heures de prise',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                FormField<List<String>>(
                  key: _timesFieldKey,
                  initialValue: _intakeTimes,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ajoute au moins une heure de prise.';
                    }
                    if (!MedicationValidators.validateTimesList(value)) {
                      return 'Utilise le format HH:MM pour chaque heure.';
                    }
                    return null;
                  },
                  builder: (state) {
                    final theme = Theme.of(context);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _timeInputController,
                                focusNode: _timeInputFocusNode,
                                decoration: InputDecoration(
                                  labelText: 'Ajouter une heure',
                                  hintText: 'HH:MM',
                                  errorText: state.errorText,
                                ),
                                keyboardType: TextInputType.datetime,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'[0-9:]'),
                                  ),
                                ],
                                onSubmitted: (_) => _addTimeFromInput(),
                              ),
                            ),
                            const SizedBox(width: 12),
                            OutlinedButton.icon(
                              onPressed: _addTimeFromInput,
                              icon: const Icon(Icons.add),
                              label: const Text('Ajouter'),
                            ),
                            const SizedBox(width: 12),
                            IconButton(
                              tooltip: 'Choisir une heure',
                              icon: const Icon(Icons.access_time),
                              onPressed: _pickTime,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (_intakeTimes.isNotEmpty)
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final time in _intakeTimes)
                                InputChip(
                                  label: Text(time),
                                  onDeleted: () => _removeTime(time),
                                ),
                            ],
                          ),
                        if (state.hasError && _intakeTimes.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              state.errorText!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.error,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 32),
                SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                        icon: const Icon(Icons.check_circle_outline),
                        label: Text(widget.isEdit ? 'Enregistrer les modifications' : 'Créer le traitement'),
                        onPressed: _submit,  ), ),
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

    if (!MedicationValidators.validateDateRange(_startDate, _endDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La date de fin doit être postérieure ou égale à la date de début.'),
        ),
      );
      return;
    }

    final provider = context.read<MedicamentProvider>();

    final medicament = widget.medicament;
    if (widget.isEdit && medicament != null) {
      medicament
        ..nom = _nameController.text.trim()
        ..dosage = _dosageController.text.trim()
        ..heures = List<String>.from(_intakeTimes)
        ..debut = _startDate
        ..fin = _endDate;

      await provider.updateMedicament(medicament);
    } else {
      final newMedicament = Medicament(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        nom: _nameController.text.trim(),
        dosage: _dosageController.text.trim(),
        heures: List<String>.from(_intakeTimes),
        debut: _startDate,
        fin: _endDate,
      );
      await provider.addMedicament(newMedicament);
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<DateTime?> _pickDate(BuildContext context, DateTime initial) {
    final now = DateTime.now();return showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
      helpText: 'Sélectionne une date',
      locale: const Locale('fr'),
    );}DateTime _combineDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }Future<void> _pickTime() async {
    final now = TimeOfDay.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: now.hour, minute: now.minute),
      helpText: 'Choisir une heure',
    );
    if (picked != null) {
      _addTime(_formatTime(picked));
    }
  }void _addTimeFromInput() {
    final value = _timeInputController.text.trim();
    if (value.isEmpty) {
      return;
    }
    final error = MedicationValidators.validateTime(value);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)),
      );
      return;
    }
    _addTime(value);
  }void _addTime(String value) {
    final normalized = value.padLeft(5, '0');
    if (_intakeTimes.contains(normalized)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cette heure est déjà enregistrée.')),
      );
      return;
    }
    setState(() {
      _intakeTimes = [..._intakeTimes, normalized]
        ..sort((a, b) => a.compareTo(b));
      _timeInputController.clear();
    });
    _timesFieldKey.currentState?.didChange(_intakeTimes);
    _timeInputFocusNode.requestFocus();
  }void _removeTime(String value) {
    setState(() {
      _intakeTimes.remove(value);
    });
    _timesFieldKey.currentState?.didChange(_intakeTimes);
  }String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}class _DatePickerField extends StatelessWidget {
  const _DatePickerField({
    required this.label,
    required this.date,
    required this.onTap,
  });

  final String label;
  final DateTime date;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {final formattedDate =
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),child: Text(formattedDate),
      ),
  );
  }
}