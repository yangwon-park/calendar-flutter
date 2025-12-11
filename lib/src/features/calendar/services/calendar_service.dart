import 'dart:convert';
import 'package:front_flutter/src/core/errors/exceptions.dart';
import 'package:front_flutter/src/core/services/api_service.dart';
import 'package:front_flutter/src/features/calendar/models/calendar_model.dart';

class CalendarService {
  final ApiService _apiService = ApiService();

  Future<List<CalendarModel>> getCalendars() async {
    try {
      final response = await _apiService.get('/api/calendars');

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
        final List<dynamic> data = body['data'] ?? [];
        return data.map((json) => CalendarModel.fromJson(json)).toList();
      } else if (response.statusCode == 401 || response.statusCode == 403 || response.statusCode == 4002 || response.statusCode == 4003) {
        throw UnauthorizedException();
      } else {
        print('Failed to fetch calendars: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error fetching calendars: $e');
      if (e is UnauthorizedException) rethrow;
      return [];
    }
  }

  Future<CalendarModel?> getCalendar(int id) async {
    try {
      final response = await _apiService.get('/api/calendars/$id');

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
        // Assuming the single object is also wrapped in 'data' or is the body itself?
        // User said "Response is same as GET /api/calendars but just one object".
        // GET /api/calendars response was wrapped in 'data'.
        // So likely this is also wrapped in 'data'.
        final dynamic data = body['data'] ?? body; 
        print('GetCalendar Raw Data: $data'); // Debugging color issue
        // Fallback to body if data is null, just in case, but likely it's body['data']
        return CalendarModel.fromJson(data);
      } else if (response.statusCode == 401 || response.statusCode == 403 || response.statusCode == 4002 || response.statusCode == 4003) {
        throw UnauthorizedException();
      } else {
        print('Failed to fetch calendar $id: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching calendar $id: $e');
      if (e is UnauthorizedException) rethrow;
      return null;
    }
  }

  Future<bool> updateCalendar(int id, String name, String type, String color, String? description) async {
    try {
      final response = await _apiService.put(
        '/api/calendars/$id',
        body: jsonEncode({
          'name': name,
          'type': type,
          'color': color,
          'description': description,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print('Failed to update calendar: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error updating calendar: $e');
      return false;
    }
  }
}
