// lib/features/consumption/ui/pages/consumption_stats_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../logic/consumption_cubit.dart';
import '../../data/models/consumption_entry.dart';

class ConsumptionStatsPage extends StatelessWidget {
  const ConsumptionStatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analyse de ma consommation'),
      ),
      body: BlocBuilder<ConsumptionCubit, ConsumptionState>(
        builder: (context, state) {
          if (state.status == ConsumptionStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == ConsumptionStatus.failure) {
            return Center(
              child: Text('Erreur : ${state.errorMessage}'),
            );
          }

          final entries = state.entries;

          if (entries.isEmpty) {
            return const Center(
              child: Text('Pas encore de données à analyser.'),
            );
          }

          // -----------------------
          // 🔢 Calculs de base
          // -----------------------
          final now = DateTime.now();
          final sevenDaysAgo = now.subtract(const Duration(days: 7));

          final last7Entries = entries
              .where((e) => e.dateTime.isAfter(sevenDaysAgo))
              .toList();

          int countType(List<ConsumptionEntry> list, String cat) =>
              list
                  .where(
                    (e) => _categoryForType(e.substanceType) == cat,
                  )
                  .length;

          final total = entries.length;
          final totalLast7 = last7Entries.length;
          final cigs = countType(entries, 'Cigarette');
          final alcool = countType(entries, 'Alcool');
          final drogue = countType(entries, 'Drogue');
          final autres = countType(entries, 'Autre');

          final trigger = _mostFrequent(
            entries.map((e) => e.trigger).where((t) => t != 'Aucun'),
          );
          final mood = _mostFrequent(entries.map((e) => e.mood));

          final streakSansDrogue = _currentNoDrugStreak(entries);

          // -----------------------
          // 🧾 UI
          // -----------------------
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Résumé rapide
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Résumé rapide',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Nombre total de consommations enregistrées : $total',
                      ),
                      Text(
                        'Dont sur les 7 derniers jours : $totalLast7',
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Répartition par type
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Par type de substance',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const SizedBox(height: 4),
                      _StatLine(label: 'Cigarette', value: cigs),
                      _StatLine(label: 'Alcool', value: alcool),
                      _StatLine(label: 'Drogue', value: drogue),
                      _StatLine(label: 'Autres', value: autres),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Déclencheurs & humeur
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Facteurs fréquents',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Déclencheur le plus fréquent : '
                        '${trigger ?? '—'}',
                      ),
                      Text(
                        'Humeur la plus fréquente : '
                        '${mood ?? '—'}',
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Streak sans drogue
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: Colors.green[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.emoji_events),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Streak de jours sans drogue : '
                          '$streakSansDrogue jour${streakSansDrogue > 1 ? 's' : ''}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Normalise le type de substance en 4 catégories pour les stats.
  static String _categoryForType(String substanceType) {
    if (substanceType.startsWith('Cigarette')) return 'Cigarette';
    if (substanceType.startsWith('Alcool')) return 'Alcool';
    if (substanceType.startsWith('Drogue')) return 'Drogue';
    // Chicha, Autre, etc.
    return 'Autre';
  }

  /// Renvoie la valeur la plus fréquente (ou null si rien).
  static String? _mostFrequent(Iterable<String> values) {
    final counts = <String, int>{};
    for (final v in values) {
      final key = v.trim();
      if (key.isEmpty) continue;
      counts[key] = (counts[key] ?? 0) + 1;
    }
    if (counts.isEmpty) return null;
    return counts.entries
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key;
  }

  /// Nombre de jours consécutifs (à partir d'aujourd'hui) sans consommation de drogue.
  static int _currentNoDrugStreak(List<ConsumptionEntry> entries) {
    if (entries.isEmpty) return 0;

    // Regrouper par jour
    final byDay = <DateTime, List<ConsumptionEntry>>{};
    for (final e in entries) {
      final day = DateTime(e.dateTime.year, e.dateTime.month, e.dateTime.day);
      byDay.putIfAbsent(day, () => []).add(e);
    }

    int streak = 0;
    DateTime day = DateTime.now();

    // Date minimale dans les données pour ne pas boucler à l'infini
    final minDay =
        byDay.keys.reduce((a, b) => a.isBefore(b) ? a : b);

    while (true) {
      final key = DateTime(day.year, day.month, day.day);
      final list = byDay[key];

      final hasDrug = list?.any(
            (e) => _categoryForType(e.substanceType) == 'Drogue',
          ) ??
          false;

      if (hasDrug) {
        break;
      }

      streak++;

      if (key.isAtSameMomentAs(minDay) || key.isBefore(minDay)) {
        break;
      }

      day = day.subtract(const Duration(days: 1));
    }

    return streak;
  }
}

/// Ligne simple "label : valeur"
class _StatLine extends StatelessWidget {
  final String label;
  final int value;

  const _StatLine({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value.toString(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
