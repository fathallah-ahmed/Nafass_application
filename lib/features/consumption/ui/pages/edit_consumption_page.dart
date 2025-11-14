import 'package:flutter/material.dart';

import '../../data/models/consumption_entry.dart';

class EditConsumptionPage extends StatefulWidget {
  final ConsumptionEntry entry;

  const EditConsumptionPage({super.key, required this.entry});

  @override
  State<EditConsumptionPage> createState() => _EditConsumptionPageState();
}

class _EditConsumptionPageState extends State<EditConsumptionPage> {
  final _formKey = GlobalKey<FormState>();

  // Substance & quantité
  late String _substanceType; // Cigarette / Chicha / Alcool / Drogue / Autre
  late String _unit;
  late double _quantity;
  late double _cravingLevel;
  String? _note;

  // Humeur & déclencheur
  late String _mood;
  late String _trigger;

  // Champs spécifiques
  String? _otherSubstanceLabel;
  String? _drugType;

  late DateTime _dateTime;

  final List<String> _drugTypes = [
    'Cannabis',
    'Cocaïne',
    'Ecstasy / MDMA',
    'Amphétamines',
    'Héroïne',
    'Médicaments détournés',
    'Autre drogue',
  ];

  @override
  void initState() {
    super.initState();

    final e = widget.entry;

    _unit = e.unit;
    _quantity = e.quantity;
    _cravingLevel = e.cravingLevel.toDouble();
    _mood = e.mood;
    _trigger = e.trigger;
    _note = e.note;
    _dateTime = e.dateTime;

    // Décoder le type de substance
    final type = e.substanceType;

    if (type.startsWith('Drogue:')) {
      _substanceType = 'Drogue';
      final after = type.substring('Drogue:'.length).trim();
      _drugType = after.isNotEmpty ? after : 'Cannabis';
    } else if (type.startsWith('Autre:')) {
      _substanceType = 'Autre';
      final after = type.substring('Autre:'.length).trim();
      _otherSubstanceLabel = after.isNotEmpty ? after : null;
    } else if (type == 'Cigarette' ||
        type == 'Chicha' ||
        type == 'Alcool') {
      _substanceType = type;
    } else {
      // Cas bizarre : on le range dans "Autre"
      _substanceType = 'Autre';
      _otherSubstanceLabel = type;
    }

    // S'assurer que _drugType a une valeur quand on est en "Drogue"
    if (_substanceType == 'Drogue' && _drugType == null) {
      _drugType = 'Cannabis';
    }
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dateTime,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dateTime),
    );
    if (time == null) return;

    setState(() {
      _dateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  void _submit() {
    final isValid = _formKey.currentState!.validate();
    if (!isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Merci de corriger les champs en rouge.'),
        ),
      );
      return;
    }

    _formKey.currentState!.save();

    // Construire le type de substance final
    String finalSubstanceType = _substanceType;

    if (_substanceType == 'Autre' &&
        _otherSubstanceLabel != null &&
        _otherSubstanceLabel!.trim().isNotEmpty) {
      finalSubstanceType = 'Autre: ${_otherSubstanceLabel!.trim()}';
    }

    if (_substanceType == 'Drogue' &&
        _drugType != null &&
        _drugType!.trim().isNotEmpty) {
      finalSubstanceType = 'Drogue: $_drugType';
    }

    final updated = ConsumptionEntry(
      id: widget.entry.id,            // on garde le même id
      userId: widget.entry.userId,    // on garde le même user
      dateTime: _dateTime,
      substanceType: finalSubstanceType,
      quantity: _quantity,
      unit: _unit,
      cravingLevel: _cravingLevel.toInt(),
      mood: _mood,
      trigger: _trigger,
      note: _note,
    );

    Navigator.of(context).pop(updated);
  }

  @override
  Widget build(BuildContext context) {
    // Choix des unités en fonction du type
    final List<String> units = _substanceType == 'Drogue'
        ? <String>['g', '0.5 g', 'mg', 'pilules', 'comprimés', 'joints']
        : <String>['cigarettes', 'verres', 'sessions'];

    if (!units.contains(_unit)) {
      _unit = units.first;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier une consommation'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: ListView(
            children: [
              // Type de substance
              const Text(
                'Type de substance',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _substanceType,
                items: const [
                  DropdownMenuItem(
                    value: 'Cigarette',
                    child: Text('Cigarette'),
                  ),
                  DropdownMenuItem(
                    value: 'Chicha',
                    child: Text('Chicha'),
                  ),
                  DropdownMenuItem(
                    value: 'Alcool',
                    child: Text('Alcool'),
                  ),
                  DropdownMenuItem(
                    value: 'Drogue',
                    child: Text('Drogue'),
                  ),
                  DropdownMenuItem(
                    value: 'Autre',
                    child: Text('Autre'),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _substanceType = value;
                    if (_substanceType == 'Drogue') {
                      _unit = 'g';
                      _drugType ??= 'Cannabis';
                    } else {
                      _unit = 'cigarettes';
                    }
                  });
                },
              ),
              const SizedBox(height: 12),

              // Si "Autre" → champ texte pour préciser (obligatoire)
              if (_substanceType == 'Autre') ...[
                const Text(
                  'Préciser la substance',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: _otherSubstanceLabel ?? '',
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Ex : Vape, narguilé spécial, etc.',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Merci de préciser la substance.';
                    }
                    if (value.trim().length < 3) {
                      return 'Minimum 3 caractères.';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _otherSubstanceLabel = value?.trim();
                  },
                ),
                const SizedBox(height: 16),
              ],

              // Si "Drogue" → liste des types de drogue (obligatoire)
              if (_substanceType == 'Drogue') ...[
                const Text(
                  'Type de drogue',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _drugType,
                  items: _drugTypes
                      .map(
                        (d) => DropdownMenuItem(
                          value: d,
                          child: Text(d),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _drugType = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Choisis un type de drogue.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ],

              // Quantité
              const Text(
                'Quantité',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Slider(
                min: 1,
                max: 20,
                divisions: 19,
                value: _quantity,
                label: _quantity.toStringAsFixed(0),
                onChanged: (v) => setState(() => _quantity = v),
              ),
              const SizedBox(height: 8),

              // Unité
              const Text(
                'Unité',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _unit,
                items: units
                    .map(
                      (u) => DropdownMenuItem(
                        value: u,
                        child: Text(u[0].toUpperCase() + u.substring(1)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _unit = value);
                  }
                },
              ),
              const SizedBox(height: 16),

              // Craving
              const Text(
                'Niveau d’envie (craving)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Slider(
                min: 0,
                max: 10,
                divisions: 10,
                value: _cravingLevel,
                label: _cravingLevel.toStringAsFixed(0),
                onChanged: (v) => setState(() => _cravingLevel = v),
              ),
              const SizedBox(height: 16),

              // Humeur
              const Text(
                'Humeur',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _mood,
                items: const [
                  DropdownMenuItem(value: 'Très bien', child: Text('Très bien')),
                  DropdownMenuItem(value: 'Bien', child: Text('Bien')),
                  DropdownMenuItem(value: 'Normal', child: Text('Normal')),
                  DropdownMenuItem(value: 'Stressé', child: Text('Stressé')),
                  DropdownMenuItem(value: 'Triste', child: Text('Triste')),
                  DropdownMenuItem(
                      value: 'En colère', child: Text('En colère')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _mood = value);
                  }
                },
              ),
              const SizedBox(height: 16),

              // Déclencheur
              const Text(
                'Déclencheur',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _trigger,
                items: const [
                  DropdownMenuItem(value: 'Aucun', child: Text('Aucun')),
                  DropdownMenuItem(value: 'Social', child: Text('Social')),
                  DropdownMenuItem(value: 'Stress', child: Text('Stress')),
                  DropdownMenuItem(value: 'Ennui', child: Text('Ennui')),
                  DropdownMenuItem(
                      value: 'Habitude', child: Text('Habitude')),
                  DropdownMenuItem(
                      value: 'Émotion forte', child: Text('Émotion forte')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _trigger = value);
                  }
                },
              ),
              const SizedBox(height: 16),

              // Date & heure
              const Text(
                'Date et heure',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: _pickDateTime,
                child: Text(
                  '${_dateTime.day}/${_dateTime.month}/${_dateTime.year} '
                  '${_dateTime.hour.toString().padLeft(2, '0')}:'
                  '${_dateTime.minute.toString().padLeft(2, '0')}',
                ),
              ),
              const SizedBox(height: 16),

              // Note
              const Text(
                'Note (facultatif)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: _note ?? '',
                maxLines: 3,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Comment tu te sentais, contexte, etc.',
                ),
                validator: (value) {
                  if (value != null && value.trim().length > 300) {
                    return '300 caractères maximum.';
                  }
                  return null;
                },
                onSaved: (value) => _note = value?.trim().isEmpty == true
                    ? null
                    : value!.trim(),
              ),
              const SizedBox(height: 24),

              // Bouton enregistrer
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  child: const Text('Enregistrer les modifications'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
