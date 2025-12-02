import 'dart:convert';
import 'package:front_flutter/src/core/services/api_service.dart';
import 'package:front_flutter/src/features/events/models/event_model.dart';

class EventService {
  final ApiService _apiService = ApiService();

  Future<bool> createEvent({
    required int calendarId,
    required String categoryId,
    required String title,
    String? description,
    required DateTime eventAt,
  }) async {
    try {
      final response = await _apiService.post(
        '/api/events',
        body: jsonEncode({
          'calendarId': calendarId,
          'categoryId': int.parse(categoryId),
          'title': title,
          'description': description,
          'eventAt': eventAt.toIso8601String(),
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        print('Failed to create event: ${response.statusCode}');
        print('Body: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error creating event: $e');
      return false;
    }
  }
}