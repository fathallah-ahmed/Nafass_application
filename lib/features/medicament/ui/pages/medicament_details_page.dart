import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/medicament_model.dart';
import '../../data/models/prise_medicament_model.dart';
import '../../logic/prises_provider.dart';
import '../widgets/medicament_stats_row.dart';

class MedicamentDetailsPage extends StatelessWidget {
  const MedicamentDetailsPage({
    super.key,
    required this.medicament,
  });

  final Medicament medicament;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(medicament.nom),
      ),
      body: Consumer<PrisesProvider>(
        builder: (context, prisesProvider, _) {
          final prises = prisesProvider.prisesPourMedicament(medicament.id);
          final stats = prisesProvider.statistiquesPourMedicament(medicament.id);

          if (prises.isEmpty) {
            return _EmptyDetailsState(medicament: medicament);
          }

          final taken = stats[StatutPrise.prise] ?? 0;
          final missed = stats[StatutPrise.oubliee] ?? 0;
          final postponed = stats[StatutPrise.reportee] ?? 0;
          final planned = stats[StatutPrise.prevue] ?? 0;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
            children: [
              _MedicamentSummary(
                medicament: medicament,
                taken: taken,
                missed: missed,
                postponed: postponed,
                planned: planned,
                total: prises.length,
              ),
              const SizedBox(height: 24),
              Text(
                'Historique des prises',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              for (final prise in prises)
                _PriseTile(
                  key: ValueKey(prise.id),
                  prise: prise,
                ),
            ],
          );
        },
      ),
    );
  }
}

class _MedicamentSummary extends StatelessWidget {
  const _MedicamentSummary({
    required this.medicament,
    required this.taken,
    required this.missed,
    required this.postponed,
    required this.planned,
    required this.total,
  });

  final Medicament medicament;
  final int taken;
  final int missed;
  final int postponed;
  final int planned;
  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final progress = total == 0 ? 0.0 : (taken / total).clamp(0.0, 1.0);

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
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  Icons.medication_rounded,
                  color: colorScheme.primary,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      medicament.nom,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (medicament.dosage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          medicament.dosage,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    const SizedBox(height: 6),
                    Text(
                      'Traitement du ${_formatDate(medicament.debut)} au ${_formatDate(medicament.fin)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
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
                  avatar: const Icon(Icons.alarm, size: 18),
                  label: Text(heure),
                ),
            ],
          ),
          const SizedBox(height: 20),
          MedicamentStatsRow(
            taken: taken,
            missed: missed,
            postponed: postponed,
            planned: planned,
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: colorScheme.surfaceVariant,
            minHeight: 6,
            ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '$taken prise(s) sur $total réalisées',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

class _PriseTile extends StatelessWidget {
  const _PriseTile({
    super.key,
    required this.prise,
  });

  final PriseMedicament prise;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<PrisesProvider>();
    final theme = Theme.of(context);
    final statutColor = _statutColor(prise.statut, theme.colorScheme);
    final statutLabel = _statutLabel(prise.statut);

    final date = prise.dateHeurePrevue;
    final formattedDate =
        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    final formattedTime =
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formattedDate,
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Heure prévue : $formattedTime',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                Chip(
                  avatar: CircleAvatar(
                    backgroundColor: statutColor,
                    radius: 6,
                  ),
                  label: Text(statutLabel),
                  backgroundColor: statutColor.withOpacity(0.12),
                  labelStyle: theme.textTheme.bodySmall?.copyWith(
                    color: statutColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            if (prise.dateHeureReelle != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Dernière mise à jour : ${_formatDateTime(prise.dateHeureReelle!)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
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
                  tooltip: 'Reporter la prise',
                  icon: const Icon(Icons.schedule_send),
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
          ],
        ),
      ),
    );
  }

  Color _statutColor(StatutPrise statut, ColorScheme colorScheme) {
    switch (statut) {
      case StatutPrise.prise:
        return Colors.teal;
      case StatutPrise.oubliee:
        return Colors.redAccent;
      case StatutPrise.reportee:
        return Colors.deepOrange;
      case StatutPrise.prevue:
      default:
      return colorScheme.primary;
    }
  }

  String _statutLabel(StatutPrise statut) {
    switch (statut) {
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
      BuildContext context,
      PriseMedicament prise,
      ) async {
    final date = prise.dateHeurePrevue;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: date.hour, minute: date.minute),
      helpText: 'Nouvelle heure de prise',
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
  String _formatDateTime(DateTime date) {
    final formattedDate =
        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    final formattedTime =
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    return '$formattedDate • $formattedTime';
  }
}

class _EmptyDetailsState extends StatelessWidget {
  const _EmptyDetailsState({required this.medicament});

  final Medicament medicament;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.hourglass_empty, size: 48),
            const SizedBox(height: 16),
            Text(
              'Aucune prise planifiée pour ${medicament.nom}.',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Vérifie la période de traitement et les heures configurées.',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
