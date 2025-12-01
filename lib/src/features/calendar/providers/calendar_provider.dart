import 'package:flutter/material.dart';
import 'package:front_flutter/src/features/calendar/models/calendar_model.dart';
import 'package:front_flutter/src/features/calendar/services/calendar_service.dart';

class CalendarProvider extends ChangeNotifier {
  final CalendarService _calendarService = CalendarService();
  List<CalendarModel> _calendars = [];
  bool _isLoading = false;

  List<CalendarModel> get calendars => _calendars;
  bool get isLoading => _isLoading;

  Future<void> fetchCalendars() async {
    _isLoading = true;
    notifyListeners();

    try {
      _calendars = await _calendarService.getCalendars();
    } catch (e) {
      print('Error in CalendarProvider: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<CalendarModel?> fetchCalendar(int id) async {
    return await _calendarService.getCalendar(id);
  }

  Future<bool> updateCalendar(int id, String name, String type, String color, String? description) async {
    final success = await _calendarService.updateCalendar(id, name, type, color, description);
    if (success) {
      await fetchCalendars(); // Refresh list after update
    }
    return success;
  }
}
