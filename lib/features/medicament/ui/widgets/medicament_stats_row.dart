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

    // Widget pour un "pill"
    Widget buildPill({
      required Color color,
      required IconData icon,
      required String label,
      required int value,
    }) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                '$value $label',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Une ligne de 2 colonnes
    Widget buildTwoColumns(Widget left, Widget right) {
      return Row(
        children: [
          Expanded(child: left),
          const SizedBox(width: 8),
          Expanded(child: right),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        buildTwoColumns(
          buildPill(
            color: Colors.teal,
            icon: Icons.check_circle,
            label: 'pris',
            value: taken,
          ),
          buildPill(
            color: Colors.redAccent,
            icon: Icons.cancel,
            label: 'oubliés',
            value: missed,
          ),
        ),
        const SizedBox(height: 8),
        buildTwoColumns(
          buildPill(
            color: Colors.deepOrange,
            icon: Icons.schedule,
            label: 'reportés',
            value: postponed,
          ),
          buildPill(
            color: colorScheme.secondary,
            icon: Icons.hourglass_bottom,
            label: 'prévus',
            value: planned,
          ),
        ),
      ],
    );
  }
}