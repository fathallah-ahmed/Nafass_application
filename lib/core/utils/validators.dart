class MedicationValidators {
  const MedicationValidators._();

  static final RegExp _timeRegExp =
  RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$');

  static final RegExp _dosageRegExp = RegExp(
    r'^(?=.*\d)(\d+([.,]\d+)?\s*[a-zA-Z%/]+.*)$',
  );

  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Le nom du médicament est obligatoire.';
    }
    if (value.trim().length < 2) {
      return 'Le nom doit contenir au moins 2 caractères.';
    }
    return null;
  }

  static String? validateDosage(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Le dosage est obligatoire.';
    }
    final trimmed = value.trim();
    if (!_dosageRegExp.hasMatch(trimmed)) {
      return 'Indique un dosage valide (ex. 500 mg).';
    }
    return null;
  }

  static String? validateTime(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "L'heure est obligatoire.";
    }
    final trimmed = value.trim();
    if (!_timeRegExp.hasMatch(trimmed)) {
      return 'Format attendu HH:MM.';
    }
    return null;
  }

  static bool validateTimesList(List<String> times) {
    if (times.isEmpty) {
      return false;
    }
    return times.every((time) => _timeRegExp.hasMatch(time));
  }

  static bool validateDateRange(DateTime start, DateTime end) {
    final normalizedStart = DateTime(start.year, start.month, start.day);
    final normalizedEnd = DateTime(end.year, end.month, end.day, 23, 59, 59);
    return !normalizedEnd.isBefore(normalizedStart);
  }
}