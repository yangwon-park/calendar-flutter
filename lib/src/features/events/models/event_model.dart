class Event {
  final String id;
  final String title;
  final DateTime date;
  final String categoryId;
  final int? calendarId;
  final String? description;

  Event({
    required this.id,
    required this.title,
    required this.date,
    required this.categoryId,
    this.calendarId,
    this.description,
  });
}

