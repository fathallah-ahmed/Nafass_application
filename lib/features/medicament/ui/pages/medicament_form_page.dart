import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/medicament_model.dart';
import '../../logic/medicament_provider.dart';

class MedicamentFormPage extends StatefulWidget {
  final Medicament? medicament;

  const MedicamentFormPage({super.key, this.medicament});

  @override
  State<MedicamentFormPage> createState() => _MedicamentFormPageState();
}

class _MedicamentFormPageState extends State<MedicamentFormPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nomController;
  late TextEditingController _dosageController;
  late TextEditingController _heuresController;

  late DateTime _debut;
  late DateTime _fin;

  bool get isEdit => widget.medicament != null;

  @override
  void initState() {
    super.initState();

    final m = widget.medicament;
    _nomController = TextEditingController(text: m?.nom ?? '');
    _dosageController = TextEditingController(text: m?.dosage ?? '');
    _heuresController = TextEditingController(
      text: m != null ? m.heures.join(', ') : '',
    );

    _debut = m?.debut ?? DateTime.now();
    _fin = m?.fin ?? DateTime.now().add(const Duration(days: 7));
  }

  @override
  void dispose() {
    _nomController.dispose();
    _dosageController.dispose();
    _heuresController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = isEdit ? 'Modifier un médicament' : 'Ajouter un médicament';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nomController,
                decoration: const InputDecoration(
                  labelText: 'Nom du médicament',
                ),
                validator: (v) =>
                v == null || v.trim().isEmpty ? 'Champ obligatoire' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _dosageController,
                decoration: const InputDecoration(
                  labelText: 'Dosage (ex: 500 mg)',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _heuresController,
                decoration: const InputDecoration(
                  labelText: 'Heures (ex: 08:00, 20:00)',
                  helperText:
                  'Sépare les heures par une virgule. Format HH:MM',
                ),
                validator: (v) =>
                v == null || v.trim().isEmpty ? 'Au moins une heure' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _DateTile(
                      label: 'Début',
                      date: _debut,
                      onTap: () async {
                        final picked = await _pickDate(context, _debut);
                        if (picked != null) {
                          setState(() => _debut = picked);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _DateTile(
                      label: 'Fin',
                      date: _fin,
                      onTap: () async {
                        final picked = await _pickDate(context, _fin);
                        if (picked != null) {
                          setState(() => _fin = picked);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.check),
                label: const Text('Enregistrer'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<DateTime?> _pickDate(BuildContext context, DateTime initial) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    return picked;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<MedicamentProvider>();

    final heures = _heuresController.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    if (heures.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ajoute au moins une heure valide.')),
      );
      return;
    }

    if (_fin.isBefore(_debut)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La date de fin doit être après le début.')),
      );
      return;
    }

    if (isEdit) {
      final m = widget.medicament!;
      m.nom = _nomController.text.trim();
      m.dosage = _dosageController.text.trim();
      m.heures = heures;
      m.debut = _debut;
      m.fin = _fin;

      await provider.updateMedicament(m);
    } else {
      final m = Medicament(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        nom: _nomController.text.trim(),
        dosage: _dosageController.text.trim(),
        heures: heures,
        debut: _debut,
        fin: _fin,
      );
      await provider.addMedicament(m);
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }
}

class _DateTile extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onTap;

  const _DateTile({
    required this.label,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final text =
        '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';

    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        child: Text(text),
      ),
    );
  }
}
