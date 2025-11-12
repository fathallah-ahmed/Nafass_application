import 'package:flutter/foundation.dart';

const Set<String> _allowedAddictionTypes = {'tabac', 'alcool', 'drogue', 'autre'};
const Object _metadataSentinel = Object();

enum ChallengeGoalType { quantitatif, qualitatif }

enum ChallengeFrequency { quotidien, hebdomadaire }

enum ChallengeState { actif, en_pause, termine, echoue, archive }

String challengeTypeAddictionFromString(String value) {
  final normalized = value.trim().toLowerCase();
  if (!_allowedAddictionTypes.contains(normalized)) {
    throw ArgumentError('Invalid addiction type: $value');
  }
  return normalized;
}

ChallengeGoalType challengeGoalTypeFromString(String value) {
  return ChallengeGoalType.values.firstWhere(
        (element) => element.name == value,
    orElse: () => throw ArgumentError('Invalid goal type: $value'),
  );
}

ChallengeFrequency challengeFrequencyFromString(String value) {
  return ChallengeFrequency.values.firstWhere(
        (element) => element.name == value,
    orElse: () => throw ArgumentError('Invalid frequency: $value'),
  );
}

ChallengeState challengeStateFromString(String value) {
  return ChallengeState.values.firstWhere(
        (element) => element.name == value,
    orElse: () => throw ArgumentError('Invalid state: $value'),
  );
}

@immutable
class Challenge {
  Challenge({
    required this.id,
    required this.userId,
    required String title,
    this.description,
    required String typeAddiction,
    this.goalType = ChallengeGoalType.quantitatif,
    this.goalValue,
    this.frequency = ChallengeFrequency.quotidien,
    required this.startDate,
    DateTime? endDate,
    bool? isIndefinite,
    this.state = ChallengeState.actif,
    this.reminderTime,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.deletedAt,
    this.metadata,
  })  : title = title.trim(),
        typeAddiction = challengeTypeAddictionFromString(typeAddiction),
        isIndefinite = isIndefinite ?? endDate == null,
        endDate = (isIndefinite ?? endDate == null) ? null : endDate,
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  final String id;
  final String userId;
  final String title;
  final String? description;
  final String typeAddiction;
  final ChallengeGoalType goalType;
  final double? goalValue;
  final ChallengeFrequency frequency;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isIndefinite;
  final ChallengeState state;
  final String? reminderTime;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final Map<String, dynamic>? metadata;

  bool get hasReminder => reminderTime != null && reminderTime!.trim().isNotEmpty;

  Challenge copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    String? typeAddiction,
    ChallengeGoalType? goalType,
    double? goalValue,
    ChallengeFrequency? frequency,
    DateTime? startDate,
    DateTime? endDate,
    bool? isIndefinite,
    ChallengeState? state,
    String? reminderTime,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    Object? metadata = _metadataSentinel,
  }) {
    final nextIsIndefinite = isIndefinite ?? this.isIndefinite;
    final nextEndDate = nextIsIndefinite ? null : (endDate ?? this.endDate);
    return Challenge(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      typeAddiction: typeAddiction ?? this.typeAddiction,
      goalType: goalType ?? this.goalType,
      goalValue: goalValue ?? this.goalValue,
      frequency: frequency ?? this.frequency,
      startDate: startDate ?? this.startDate,
      endDate: nextEndDate,
      isIndefinite: nextIsIndefinite,
      state: state ?? this.state,
      reminderTime: reminderTime ?? this.reminderTime,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      metadata: identical(metadata, _metadataSentinel)
          ? this.metadata
          : metadata as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'typeAddiction': typeAddiction,
      'goalType': goalType.name,
      'goalValue': goalValue,
      'frequency': frequency.name,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'isIndefinite': isIndefinite,
      'state': state.name,
      'reminderTime': reminderTime,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory Challenge.fromJson(Map<String, dynamic> json) {
    final endDateRaw = json['endDate'] as String?;
    final isIndefinite = json['isIndefinite'] as bool?;
    return Challenge(
      id: json['id'] as String,
      userId: json['userId'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      typeAddiction: json['typeAddiction'] as String,
      goalType: challengeGoalTypeFromString(json['goalType'] as String),
      goalValue: (json['goalValue'] as num?)?.toDouble(),
      frequency: challengeFrequencyFromString(json['frequency'] as String),
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: endDateRaw != null ? DateTime.tryParse(endDateRaw) : null,
      isIndefinite: isIndefinite,
      state: challengeStateFromString(json['state'] as String),
      reminderTime: json['reminderTime'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      deletedAt:
      json['deletedAt'] != null ? DateTime.tryParse(json['deletedAt'] as String) : null,
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : null,
    );
  }

  void validateCreate() {
    if (userId.trim().isEmpty) {
      throw ArgumentError('Challenge userId is required');
    }
    if (title.trim().isEmpty) {
      throw ArgumentError('Challenge title is required');
    }
    if (!_allowedAddictionTypes.contains(typeAddiction)) {
      throw ArgumentError('Invalid addiction type: $typeAddiction');
    }
    _validateGoal();
    _validateDates();
  }

  void validateUpdate() {
    if (id.trim().isEmpty) {
      throw ArgumentError('Challenge id is required for update');
    }
    if (userId.trim().isEmpty) {
      throw ArgumentError('Challenge userId is required');
    }
    if (title.trim().isEmpty) {
      throw ArgumentError('Challenge title cannot be empty');
    }
    if (!_allowedAddictionTypes.contains(typeAddiction)) {
      throw ArgumentError('Invalid addiction type: $typeAddiction');
    }
    _validateGoal();
    _validateDates();
  }

  void _validateGoal() {
    if (goalType == ChallengeGoalType.quantitatif) {
      if (goalValue == null || goalValue! <= 0) {
        throw ArgumentError('Quantitative challenges require goalValue > 0');
      }
    } else if (goalValue != null) {
      throw ArgumentError('Qualitative challenges must not define goalValue');
    }
  }

  void _validateDates() {
    if (!isIndefinite && endDate != null && endDate!.isBefore(startDate)) {
      throw ArgumentError('endDate must be on or after startDate');
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Challenge && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}