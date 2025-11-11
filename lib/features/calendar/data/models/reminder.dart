import 'package:flutter/foundation.dart';

@immutable
class Reminder {
  const Reminder({
    required this.id,
    required this.title,
    this.description,
    required this.scheduledAt,
    this.isActive = true,
    this.snoozeMinutes = 5,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String? description;
  final DateTime scheduledAt;
  final bool isActive;
  final int snoozeMinutes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Reminder copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? scheduledAt,
    bool? isActive,
    int? snoozeMinutes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Reminder(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      isActive: isActive ?? this.isActive,
      snoozeMinutes: snoozeMinutes ?? this.snoozeMinutes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Reminder.fromJson(Map<String, dynamic> json) {
    return Reminder(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      scheduledAt: DateTime.parse(json['scheduledAt'] as String),
      isActive: json['isActive'] as bool? ?? true,
      snoozeMinutes: json['snoozeMinutes'] as int? ?? 5,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'description': description,
      'scheduledAt': scheduledAt.toIso8601String(),
      'isActive': isActive,
      'snoozeMinutes': snoozeMinutes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Reminder && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}