import 'package:flutter/foundation.dart';

@immutable
class ChallengeProgress {
   ChallengeProgress({
    required this.id,
    required this.challengeId,
    required DateTime date,
    this.success,
    this.measuredValue,
    this.note,
  }) : date = DateTime(date.year, date.month, date.day);

  final String id;
  final String challengeId;
  final DateTime date;
  final bool? success;
  final double? measuredValue;
  final String? note;

  ChallengeProgress copyWith({
    String? id,
    String? challengeId,
    DateTime? date,
    bool? success,
    double? measuredValue,
    String? note,
  }) {
    return ChallengeProgress(
      id: id ?? this.id,
      challengeId: challengeId ?? this.challengeId,
      date: date ?? this.date,
      success: success ?? this.success,
      measuredValue: measuredValue ?? this.measuredValue,
      note: note ?? this.note,
    );
  }

  void validate() {
    if (challengeId.trim().isEmpty) {
      throw ArgumentError('challengeId is required');
    }
    if (measuredValue == null && success == null) {
      throw ArgumentError('Progress requires success or measuredValue');
    }
  }

  Map<String, dynamic> toJson() {
    final formattedDate = '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
    return <String, dynamic>{
      'id': id,
      'challengeId': challengeId,
      'date': formattedDate,
      'success': success,
      'measuredValue': measuredValue,
      'note': note,
    };
  }

  factory ChallengeProgress.fromJson(Map<String, dynamic> json) {
    final rawDate = json['date'] as String;
    return ChallengeProgress(
      id: json['id'] as String,
      challengeId: json['challengeId'] as String,
      date: DateTime.parse('$rawDate${rawDate.contains('T') ? '' : 'T00:00:00'}'),
      success: json['success'] as bool?,
      measuredValue: (json['measuredValue'] as num?)?.toDouble(),
      note: json['note'] as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChallengeProgress && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}