import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class MailingService {
  MailingService({String? baseUrl})
      : _baseUrl = baseUrl ?? 'http://10.0.2.2:8000';

  // Sur l’émulateur Android, 10.0.2.2 = localhost de ton PC
  // Sur un vrai téléphone, tu devras mettre l’IP locale de ton PC (ex: http://192.168.1.10:8000)
  final String _baseUrl;

  Future<void> sendWelcomeEmail({
    required String email,
    required String firstName,
    required String lastName,
  }) async {
    final url = Uri.parse('$_baseUrl/api/mail/welcome');

    final body = jsonEncode({
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
    });

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode >= 400) {
        debugPrint('Failed to send welcome email: ${response.statusCode} ${response.body}');
      } else {
        debugPrint('Welcome email sent to $email');
      }
    } catch (e) {
      debugPrint('Error sending welcome email: $e');
    }
  }
}
