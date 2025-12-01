class CalendarModel {
  final int calendarId;
  final String name;
  final String type; // 'PERSONAL', 'COUPLE', etc.
  final String? description;
  final String color;

  CalendarModel({
    required this.calendarId,
    required this.name,
    required this.type,
    this.description,
    this.color = '#000000', // Default color
  });

  factory CalendarModel.fromJson(Map<String, dynamic> json) {
    return CalendarModel(
      calendarId: json['calendarId'] as int,
      name: json['name'] as String,
      type: json['type'] as String,
      description: json['description'] as String?,
      color: json['color'] as String? ?? '#000000',
    );
  }
}
