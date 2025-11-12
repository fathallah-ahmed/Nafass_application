import 'package:flutter/material.dart';

import '../../data/models/challenge_progress.dart';

class ChallengeStats extends StatelessWidget {
  const ChallengeStats({
    super.key,
    required this.weekRate,
    required this.monthRate,
    required this.history,
  });

  final double weekRate;
  final double monthRate;
  final List<ChallengeProgress> history;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final recent = history.reversed.take(14).toList();
    final bars = recent
        .map((item) => item.success == null
        ? (item.measuredValue != null && item.measuredValue! > 0 ? 1.0 : 0.0)
        : (item.success! ? 1.0 : 0.0))
        .toList()
        .reversed
        .toList();

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statistiques',
              style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _RateTile(
                    label: '7 derniers jours',
                    value: weekRate,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _RateTile(
                    label: '30 derniers jours',
                    value: monthRate,
                    color: colorScheme.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Historique récent',
              style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 48,
              child: bars.isEmpty
                  ? Center(
                child: Text(
                  'Pas encore de données',
                  style: textTheme.bodySmall,
                ),
              )
                  : Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final value in bars)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            height: 8 + (value * 40),
                            decoration: BoxDecoration(
                              color: value > 0
                                  ? colorScheme.primary
                                  : colorScheme.errorContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RateTile extends StatelessWidget {
  const _RateTile({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final percentage = (value * 100).clamp(0, 100).toStringAsFixed(0);
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium,
          ),
          const SizedBox(height: 8),
          Text(
            '$percentage%',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}