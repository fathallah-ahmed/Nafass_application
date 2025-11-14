import 'package:flutter/material.dart';
import '../../data/models/consumption_entry.dart';

class ConsumptionListItem extends StatelessWidget {
  final ConsumptionEntry entry;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const ConsumptionListItem({
    super.key,
    required this.entry,
    this.onTap,
    this.onLongPress,
  });

  /// Choix d’icône selon la substance
  IconData _iconForSubstance(String type) {
    switch (type.toLowerCase()) {
      case 'alcool':
        return Icons.local_bar;
      case 'cigarette':
        return Icons.smoking_rooms_outlined;
      case 'drogue':
        return Icons.medication_liquid_outlined;
      default:
        return Icons.track_changes;
    }
  }

  @override
  Widget build(BuildContext context) {
    final date = entry.dateTime;

    final dateText =
        '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';

    return Card(
      elevation: 1.5,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        leading: CircleAvatar(
          radius: 22,
          backgroundColor:
              Theme.of(context).colorScheme.primary.withOpacity(0.12),
          child: Icon(
            _iconForSubstance(entry.substanceType),
            color: Theme.of(context).colorScheme.primary,
          ),
        ),

        title: Text(
          '${entry.substanceType} — ${entry.quantity} ${entry.unit}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),

        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              dateText,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),

            // 🔥 OPTIONNEL : afficher humeur + déclencheur
            if (entry.mood.isNotEmpty || entry.trigger.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Humeur : ${entry.mood} | Déclencheur : ${entry.trigger}',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),

        onTap: onTap,
        onLongPress: onLongPress,
      ),
    );
  }
}
