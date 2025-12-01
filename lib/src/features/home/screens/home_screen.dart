import 'package:flutter/material.dart';

import 'package:front_flutter/src/features/authentication/providers/user_provider.dart';
import 'package:front_flutter/src/features/events/models/category_model.dart';
import 'package:front_flutter/src/features/events/models/event_model.dart';
import 'package:front_flutter/src/features/calendar/providers/calendar_provider.dart';

import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Event>> _events = {};
  List<Category> _categories = [];

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    // Initialize default categories
    _categories = [
      Category(id: '1', name: '일정', emoticon: '📅'),
      Category(id: '2', name: '기념일', emoticon: '❤️'),
      Category(id: '3', name: '운동', emoticon: '💪'),
    ];
    
    // Check couple status and fetch home data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().fetchHomeData();
      context.read<CalendarProvider>().fetchCalendars();
    });
  }

  List<Event> _getEventsForDay(DateTime day) {
    return _events[day] ?? [];
  }

  void _addEvent(String title, String categoryId, int? calendarId) {
    if (_selectedDay != null) {
      final event = Event(
        id: DateTime.now().toString(),
        title: title,
        date: _selectedDay!,
        categoryId: categoryId,
        calendarId: calendarId,
      );

      setState(() {
        if (_events[_selectedDay!] != null) {
          _events[_selectedDay!]!.add(event);
        } else {
          _events[_selectedDay!] = [event];
        }
      });
    }
  }

  void _addCategory(String name, String emoticon) {
    setState(() {
      _categories.add(Category(
        id: DateTime.now().toString(),
        name: name,
        emoticon: emoticon,
      ));
    });
  }

  void _showAddCategoryDialog() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController emoticonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Category'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Category Name'),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emoticonController,
                decoration: const InputDecoration(labelText: 'Emoticon (Emoji)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty &&
                    emoticonController.text.isNotEmpty) {
                  _addCategory(nameController.text, emoticonController.text);
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _showAddEventDialog() {
    final TextEditingController titleController = TextEditingController();
    String selectedCategoryId = _categories.first.id;
    
    // Get calendars from provider
    final calendars = context.read<CalendarProvider>().calendars;
    int? selectedCalendarId = calendars.isNotEmpty ? calendars.first.calendarId : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Event Title'),
                    autofocus: true,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('Category: '),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButton<String>(
                          value: selectedCategoryId,
                          isExpanded: true,
                          items: _categories.map((category) {
                            return DropdownMenuItem(
                              value: category.id,
                              child: Text('${category.emoticon} ${category.name}'),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setModalState(() {
                                selectedCategoryId = value;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  if (calendars.isNotEmpty) ...[
                    Row(
                      children: [
                        const Text('Calendar: '),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButton<int>(
                            value: selectedCalendarId,
                            isExpanded: true,
                            items: calendars.map((calendar) {
                              return DropdownMenuItem(
                                value: calendar.calendarId,
                                child: Text(calendar.name),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setModalState(() {
                                  selectedCalendarId = value;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  ElevatedButton(
                    onPressed: () {
                      if (titleController.text.isNotEmpty) {
                        _addEvent(titleController.text, selectedCategoryId, selectedCalendarId);
                        Navigator.pop(context);
                      }
                    },
                    child: const Text('Add Event'),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Couple Calendar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () {
              Navigator.of(context).pushNamed('/calendars');
            },
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.of(context).pushNamed('/mypage');
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
            eventLoader: _getEventsForDay,
            calendarStyle: const CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.deepPurple,
                shape: BoxShape.circle,
              ),
            ),
            headerStyle: const HeaderStyle(
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
              markerBuilder: (context, day, events) {
                if (events.isEmpty) return null;
                
                // Show up to 3 emoticons
                final eventList = events.cast<Event>();
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: eventList.take(3).map((event) {
                    final category = _categories.firstWhere(
                      (c) => c.id == event.categoryId,
                      orElse: () => _categories.first,
                    );
                    return Text(
                      category.emoticon,
                      style: const TextStyle(fontSize: 10),
                    );
                  }).toList(),
                );
              },
            ),
          ),
          const SizedBox(height: 8.0),
          Expanded(
            child: ListView(
              children: _getEventsForDay(_selectedDay ?? _focusedDay)
                  .map((event) {
                    final category = _categories.firstWhere(
                      (c) => c.id == event.categoryId,
                      orElse: () => _categories.first,
                    );
                    return ListTile(
                      leading: Text(
                        category.emoticon,
                        style: const TextStyle(fontSize: 24),
                      ),
                      title: Text(event.title),
                      subtitle: Text(category.name),
                    );
                  })
                  .toList(),
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.small(
            heroTag: 'add_category',
            onPressed: _showAddCategoryDialog,
            child: const Icon(Icons.category),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: 'add_event',
            onPressed: _showAddEventDialog,
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}

