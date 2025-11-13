import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/medicament_model.dart';
import 'medicament_details_page.dart';
import '../../data/models/prise_medicament_model.dart';
import '../../logic/medicament_provider.dart';
import '../../logic/prises_provider.dart';
import '../widgets/medicament_stats_row.dart';
import 'medicament_form_page.dart';

class MedicamentListPage extends StatefulWidget  {
  const MedicamentListPage({super.key});
  @override
  State<MedicamentListPage> createState() => _MedicamentListPageState();
}

class _MedicamentListPageState extends State<MedicamentListPage> {
  bool _showArchived = false;


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Traitements & prises'),
        actions: [
          IconButton(
            tooltip: _showArchived
                ? 'Afficher les traitements actifs'
                : 'Afficher les traitements archivés',
            icon: Icon(_showArchived ? Icons.medical_services : Icons.archive_outlined),
            onPressed: () {
              setState(() => _showArchived = !_showArchived);
            },
          ),
        ],
      ),
      body: Consumer2<MedicamentProvider, PrisesProvider>(
        builder: (context, medicamentProvider, prisesProvider, _) {
          final List<Medicament> medicaments = _showArchived
              ? medicamentProvider.archivedMedicaments
              : medicamentProvider.medicaments;

          if (medicaments.isEmpty) {
            return _EmptyState(
              isArchive: _showArchived,
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
            children: [
            _SectionHeader(
            isArchive: _showArchived,
            count: medicaments.length,
          ),
          const SizedBox(height: 12),
          for (final medicament in medicaments)
          Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Builder(
          builder: (context) {
          final prises =
          prisesProvider.prisesPourMedicament(medicament.id);
          final stats = prisesProvider
              .statistiquesPourMedicament(medicament.id);
          final totalPrises = prises.length;
          final taken = stats[StatutPrise.prise] ?? 0;
          final missed = stats[StatutPrise.oubliee] ?? 0;
          final postponed = stats[StatutPrise.reportee] ?? 0;
          final planned = stats[StatutPrise.prevue] ?? 0;

          PriseMedicament? nextIntake;
          for (final prise in prises) {
          if (prise.dateHeurePrevue.isAfter(DateTime.now())) {
          nextIntake = prise;
          break;
          }
          }
          return _MedicamentCard(
          medicament: medicament,
          totalPrises: totalPrises,
          taken: taken,
          missed: missed,
          postponed: postponed,
          planned: planned,
          nextIntake: nextIntake,
          onOpenDetails: () {
          Navigator.push(
          context,
          MaterialPageRoute(
          builder: (_) => MedicamentDetailsPage(
          medicament: medicament,
          ),
          ),
          );
          },
          onEdit: medicament.archive
          ? null
              : () {
          Navigator.push(
          context,
          MaterialPageRoute(
          builder: (_) => MedicamentFormPage(
          medicament: medicament),
          ),
          );
          },
          onArchive: medicament.archive
          ? null
              : () async {
          await context
              .read<MedicamentProvider>()
              .archiveMedicament(medicament.id);
          },
          onDelete: () async {
          final confirmed = await _confirmDelete(context);
          if (confirmed == true) {
          await context
              .read<MedicamentProvider>()
              .deleteMedicament(medicament.id);
          }
          },
          );
                      }


                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MedicamentFormPage()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Nouveau traitement'),
      ),
      backgroundColor: theme.colorScheme.surfaceVariant.withOpacity(0.2),
    );
  }
}

Future<bool?> _confirmDelete(BuildContext context) async {
  return showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Supprimer le traitement ?'),
        content: const Text(
          'Cette action supprimera également les prises associées. Voulez-vous continuer ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      );
    },
  );
}

class _MedicamentCard extends StatelessWidget {
  const _MedicamentCard({
    required this.medicament,
    required this.totalPrises,
    required this.taken,
    required this.missed,
    required this.postponed,
    required this.planned,
    required this.onOpenDetails,
    required this.onDelete,
    this.onEdit,
    this.onArchive,
    this.nextIntake,
  });

  final Medicament medicament;
  final int totalPrises;
  final int taken;
  final int missed;
  final int postponed;
  final int planned;
  final PriseMedicament? nextIntake;
  final VoidCallback onOpenDetails;
  final VoidCallback onDelete;
  final VoidCallback? onEdit;
  final VoidCallback? onArchive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final double progress = totalPrises == 0
        ? 0
        : (taken / totalPrises).clamp(0.0, 1.0);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.medication_rounded,
                    color: colorScheme.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              medicament.nom,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (medicament.archive)
                            const Padding(
                              padding: EdgeInsets.only(left: 8.0),
                              child: Chip(
                                label: Text('Archivé'),
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                          PopupMenuButton<String>(
                            onSelected: (value) {
                              switch (value) {
                                case 'details':
                                  onOpenDetails();
                                  break;
                                case 'edit':
                                  if (onEdit != null) onEdit!();
                                  break;
                                case 'archive':
                                  if (onArchive != null) onArchive!();
                                  break;
                                case 'delete':
                                  onDelete();
                                  break;
                              }
                            },
                            itemBuilder: (context) {
                              final items = <PopupMenuEntry<String>>[
                                const PopupMenuItem(
                                  value: 'details',
                                  child: Text('Voir les détails'),
                                ),
                              ];
                              if (onEdit != null) {
                                items.add(
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Text('Modifier'),
                                  ),
                                );
                              }
                              if (onArchive != null) {
                                items.add(
                                  const PopupMenuItem(
                                    value: 'archive',
                                    child: Text('Archiver'),
                                  ),
                                );
                              }
                              items.add(
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Supprimer'),
                                ),
                              );
                              return items;
                            },
                          ),
                        ],
                      ),
                      if (medicament.dosage.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            medicament.dosage,
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(color: colorScheme.primary),
                          ),
                        ),
                      const SizedBox(height: 6),
                      Text(
                        'Du ${_formatDate(medicament.debut)} au ${_formatDate(medicament.fin)}',
                        style: theme.textTheme.bodySmall,
                      ),
                      if (nextIntake != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Prochaine prise : ${_formatDateTime(nextIntake!.dateHeurePrevue)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.tertiary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final heure in medicament.heures)
                  Chip(
                    label: Text(heure),
                    avatar: const Icon(Icons.schedule, size: 18),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            MedicamentStatsRow(
              taken: taken,
              missed: missed,
              postponed: postponed,
              planned: planned,
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: colorScheme.surfaceVariant,
              minHeight: 6,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: onOpenDetails,
                  icon: const Icon(Icons.visibility_rounded),
                  label: const Text('Détails'),
                ),
                if (onEdit != null)
                  const SizedBox(width: 12),
                if (onEdit != null)
                  FilledButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_rounded),
                    label: const Text('Modifier'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatDateTime(DateTime date) {
    final datePart = _formatDate(date);
    final timePart =
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    return '$datePart • $timePart';
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.isArchive});

  final bool isArchive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isArchive ? Icons.archive_rounded : Icons.medication_rounded,
              size: 64,
              color: colorScheme.primary.withOpacity(0.7),
            ),
            const SizedBox(height: 16),
            Text(
              isArchive
                  ? 'Aucun traitement archivé pour le moment.'
                  : 'Ajoute ton premier traitement pour planifier tes prises.',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              isArchive
                  ? 'Les traitements archivés apparaîtront ici.'
                  : 'Utilise le bouton "+" pour enregistrer un médicament et ses heures de prise.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.isArchive,
    required this.count,
  });

  final bool isArchive;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitle = isArchive
        ? 'Historique des traitements terminés'
        : 'Planifie et suis tes prises quotidiennes';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isArchive ? 'Traitements archivés' : 'Traitements en cours',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$subtitle • $count élément(s)',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
