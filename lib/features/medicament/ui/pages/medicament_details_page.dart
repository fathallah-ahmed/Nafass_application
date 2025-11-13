import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/medicament_model.dart';
import '../../data/models/prise_medicament_model.dart';
import '../../logic/prises_provider.dart';

class MedicamentDetailsPage extends StatelessWidget {
  final Medicament medicament;

  const MedicamentDetailsPage({super.key, required this.medicament});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(medicament.nom),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const Divider(),
          Expanded(
            child: Consumer<PrisesProvider>(
              builder: (context, provider, _) {
                final prises = provider.prises
                    .where((p) => p.medicamentId == medicament.id)
                    .toList()
                  ..sort((a, b) =>
                      a.dateHeurePrevue.compareTo(b.dateHeurePrevue));

                if (prises.isEmpty) {
                  return const Center(
                    child: Text('Aucune prise générée pour ce médicament.'),
                  );
                }

                return ListView.builder(
                  itemCount: prises.length,
                  itemBuilder: (context, index) {
                    final p = prises[index];
                    return _PriseTile(prise: p);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            medicament.nom,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          if (medicament.dosage.isNotEmpty)
            Text(medicament.dosage),
          const SizedBox(height: 4),
          Text(
            'Heures : ${medicament.heures.join(', ')}',
          ),
          const SizedBox(height: 4),
          Text(
            'Du ${_formatDate(medicament.debut)} au ${_formatDate(medicament.fin)}',
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
          '${d.month.toString().padLeft(2, '0')}/'
          '${d.year}';
}

class _PriseTile extends StatelessWidget {
  final PriseMedicament prise;

  const _PriseTile({required this.prise});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<PrisesProvider>();

    final statutColor = _statutColor(prise.statut);
    final statutLabel = _statutLabel(prise.statut);

    final date = prise.dateHeurePrevue;
    final dateText =
        '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}  '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        title: Text(dateText),
        subtitle: Text(
          'Statut : $statutLabel',
          style: TextStyle(color: statutColor),
        ),
        trailing: Wrap(
          spacing: 4,
          children: [
            IconButton(
              tooltip: 'Marquer comme pris',
              icon: const Icon(Icons.check_circle),
              onPressed: () async {
                await provider.changerStatutPrise(
                  prise.id,
                  StatutPrise.prise,
                );
              },
            ),
            IconButton(
              tooltip: 'Marquer comme oublié',
              icon: const Icon(Icons.cancel),
              onPressed: () async {
                await provider.changerStatutPrise(
                  prise.id,
                  StatutPrise.oubliee,
                );
              },
            ),
            IconButton(
              tooltip: 'Reporter',
              icon: const Icon(Icons.schedule),
              onPressed: () async {
                final newDate = await _pickNewDateTime(context, prise);
                if (newDate != null) {
                  await provider.changerStatutPrise(
                    prise.id,
                    StatutPrise.reportee,
                    nouvelleDate: newDate,
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Color _statutColor(StatutPrise s) {
    switch (s) {
      case StatutPrise.prise:
        return Colors.green;
      case StatutPrise.oubliee:
        return Colors.red;
      case StatutPrise.reportee:
        return Colors.orange;
      case StatutPrise.prevue:
      default:
        return Colors.blueGrey;
    }
  }

  String _statutLabel(StatutPrise s) {
    switch (s) {
      case StatutPrise.prise:
        return 'Pris';
      case StatutPrise.oubliee:
        return 'Oublié';
      case StatutPrise.reportee:
        return 'Reporté';
      case StatutPrise.prevue:
      default:
        return 'Prévu';
    }
  }

  Future<DateTime?> _pickNewDateTime(
      BuildContext context, PriseMedicament p) async {
    final date = p.dateHeurePrevue;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: date.hour, minute: date.minute),
    );

    if (pickedTime == null) return null;

    return DateTime(
      date.year,
      date.month,
      date.day,
      pickedTime.hour,
      pickedTime.minute,
    );
  }
}
