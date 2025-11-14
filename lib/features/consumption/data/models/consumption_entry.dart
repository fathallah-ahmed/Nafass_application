// lib/features/consumption/data/models/consumption_entry.dart

class ConsumptionEntry {
  final String id;
  final String userId;
  final DateTime dateTime;
  final String substanceType;
  final double quantity;
  final String unit;
  final int cravingLevel;
  final String mood;
  final String trigger;
  final String? note;

  ConsumptionEntry({
    required this.id,
    required this.userId,
    required this.dateTime,
    required this.substanceType,
    required this.quantity,
    required this.unit,
    required this.cravingLevel,
    required this.mood,
    required this.trigger,
    this.note,
  });

  // ---------- JSON ----------

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'dateTime': dateTime.toIso8601String(),
      'substanceType': substanceType,
      'quantity': quantity,
      'unit': unit,
      'cravingLevel': cravingLevel,
      'mood': mood,
      'trigger': trigger,
      'note': note,
    };
  }

  factory ConsumptionEntry.fromJson(Map<String, dynamic> json) {
    return ConsumptionEntry(
      id: json['id'] as String,
      userId: json['userId'] as String,
      dateTime: DateTime.parse(json['dateTime'] as String),
      substanceType: json['substanceType'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      unit: json['unit'] as String,
      cravingLevel: json['cravingLevel'] as int,
      mood: json['mood'] as String,
      trigger: json['trigger'] as String,
      note: json['note'] as String?,
    );
  }
}
