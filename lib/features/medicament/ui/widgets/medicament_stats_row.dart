import 'package:flutter/material.dart';

class MedicamentStatsRow extends StatelessWidget {
  const MedicamentStatsRow({
    super.key,
    required this.taken,
    required this.missed,
    required this.postponed,
    required this.planned,
  });

  final int taken;
  final int missed;
  final int postponed;
  final int planned;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Widget buildPill({
      required Color color,
      required IconData icon,
      required String label,
      required int value,
    }) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Text(
                '$value $label',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        buildPill(
          color: Colors.teal,
          icon: Icons.check_circle,
          label: 'pris',
          value: taken,
        ),
        const SizedBox(width: 8),
        buildPill(
          color: Colors.redAccent,
          icon: Icons.cancel,
          label: 'oubliés',
          value: missed,
        ),
        const SizedBox(width: 8),
        buildPill(
          color: Colors.deepOrange,
          icon: Icons.schedule,
          label: 'reportés',
          value: postponed,
        ),
        const SizedBox(width: 8),
        buildPill(
          color: colorScheme.secondary,
          icon: Icons.hourglass_bottom,
          label: 'prévus',
          value: planned,
        ),
      ],
    );
  }
}