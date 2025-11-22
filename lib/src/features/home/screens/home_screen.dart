import 'package:flutter/material.dart';
import 'package:front_flutter/src/features/authentication/services/auth_service.dart';
import 'package:table_calendar/table_calendar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Couple Calendar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService().signOut();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          TableCalendar(
            locale: 'ko_KR',
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.deepPurple,
                shape: BoxShape.circle,
              ),
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, focusedDay) {
                if (day.weekday == DateTime.sunday) {
                  return Center(
                    child: Text(
                      '${day.day}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }
                return null;
              },
              dowBuilder: (context, day) {
                if (day.weekday == DateTime.sunday) {
                  final text = const {
                    DateTime.sunday: '일',
                    DateTime.monday: '월',
                    DateTime.tuesday: '화',
                    DateTime.wednesday: '수',
                    DateTime.thursday: '목',
                    DateTime.friday: '금',
                    DateTime.saturday: '토',
                  }[day.weekday]!;
                  return Center(
                    child: Text(
                      text,
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 20),
          if (_selectedDay != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Selected: ${_selectedDay!.year}-${_selectedDay!.month.toString().padLeft(2, '0')}-${_selectedDay!.day.toString().padLeft(2, '0')}',
                style: const TextStyle(fontSize: 16),
              ),
            ),
        ],
      ),
    );
  }
}
