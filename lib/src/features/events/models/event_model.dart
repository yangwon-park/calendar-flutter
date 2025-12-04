class Event {
  final String id;
  final String title;
  final DateTime date;
  final DateTime? endAt;
  final String categoryId;
  final int? calendarId;
  final String? description;
  final int? slotIndex;
  final bool isAllDay;

  Event({
    required this.id,
    required this.title,
    required this.date,
    this.endAt,
    required this.categoryId,
    this.calendarId,
    this.description,
    this.slotIndex,
    this.isAllDay = false,
  });
}
