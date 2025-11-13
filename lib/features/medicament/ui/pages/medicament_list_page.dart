import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../logic/medicament_provider.dart';
import '../../data/models/medicament_model.dart';
import 'medicament_form_page.dart';
import 'medicament_details_page.dart';

class MedicamentListPage extends StatelessWidget {
  const MedicamentListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes médicaments'),
      ),
      body: Consumer<MedicamentProvider>(
        builder: (context, provider, _) {
          final meds = provider.medicaments;

          if (meds.isEmpty) {
            return const Center(
              child: Text(
                'Aucun médicament pour le moment.\nAjoute-en avec le bouton +',
                textAlign: TextAlign.center,
              ),
            );
          }

          return ListView.builder(
            itemCount: meds.length,
            itemBuilder: (context, index) {
              final Medicament m = meds[index];

              return Card(
                margin:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(m.nom),
                  subtitle: Text(
                    '${m.dosage} • ${m.heures.join(', ')}\n'
                        'Du ${_formatDate(m.debut)} au ${_formatDate(m.fin)}',
                  ),
                  isThreeLine: true,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MedicamentDetailsPage(medicament: m),
                      ),
                    );
                  },
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      final provider =
                      context.read<MedicamentProvider>();

                      if (value == 'edit') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                MedicamentFormPage(medicament: m),
                          ),
                        );
                      } else if (value == 'archive') {
                        await provider.archiveMedicament(m.id);
                      } else if (value == 'delete') {
                        await provider.deleteMedicament(m.id);
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'edit',
                        child: Text('Modifier'),
                      ),
                      PopupMenuItem(
                        value: 'archive',
                        child: Text('Archiver'),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text('Supprimer'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MedicamentFormPage()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
          '${d.month.toString().padLeft(2, '0')}/'
          '${d.year}';
}
