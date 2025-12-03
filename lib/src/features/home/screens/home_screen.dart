import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:front_flutter/src/features/authentication/providers/user_provider.dart';
import 'package:front_flutter/src/features/events/models/category_model.dart';
import 'package:front_flutter/src/features/events/models/event_model.dart';
import 'package:front_flutter/src/features/calendar/models/calendar_model.dart';
import 'package:front_flutter/src/features/calendar/providers/calendar_provider.dart';
import 'package:front_flutter/src/features/events/services/event_service.dart';

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
  List<Category> _categories = [];
  final EventService _eventService = EventService();

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
      _refreshData();
    });
  }

  Future<void> _refreshData() async {
    // Fetch calendars first to handle potential token refresh sequentially
    await context.read<CalendarProvider>().fetchCalendars();
    
    if (mounted) {
      await context.read<UserProvider>().fetchHomeData();
    }
  }

  List<Event> _getEventsForDay(DateTime day) {
    // Get events from UserProvider
    final eventInfos = context.watch<UserProvider>().eventInfos;
    
    // Filter events for the specific day
    // Normalize day to match keys (Local midnight)
    final normalizedDay = DateTime(day.year, day.month, day.day);
    
    return eventInfos.where((info) {
      final eventDate = DateTime(info.eventAt.year, info.eventAt.month, info.eventAt.day);
      return isSameDay(normalizedDay, eventDate);
    }).map((info) {
      // Map EventInfo to Event
      // Note: EventInfo might not have title/description if the API doesn't provide it.
      // The user's EventInfo only has calendarId, categoryId, eventAt.
      // We might need to use default title or fetch details if needed.
      // For now, we'll use a placeholder title or category name.
      
      // We need to find the category to get a name/emoticon?
      // Actually the marker builder uses categoryId to find emoticon.
      // The list view uses title.
      // If title is missing, we can use Category Name as title.
      
      return Event(
        id: 'server_event', // No ID in EventInfo
        title: info.title,
        date: info.eventAt,
        categoryId: info.categoryId.toString(),
        calendarId: info.calendarId,
      );
    }).toList();
  }

  Future<void> _addEvent(String title, String categoryId, int calendarId, String? description, DateTime eventAt) async {
    final success = await _eventService.createEvent(
      calendarId: calendarId,
      categoryId: categoryId,
      title: title,
      description: description,
      eventAt: eventAt,
    );

    if (success) {
      // Refresh home data to get updated events
      if (mounted) {
        await _refreshData();
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create event')),
        );
      }
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
    final TextEditingController descriptionController = TextEditingController();
    String selectedCategoryId = _categories.first.id;
    TimeOfDay selectedTime = TimeOfDay.now();
    
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
                  const SizedBox(height: 16),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(labelText: 'Description'),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  
                  // Start Date/Time Row (Apple Calendar Style)
                  Row(
                    children: [
                      const Text('시작', style: TextStyle(fontSize: 16)),
                      const Spacer(),
                      
                      // Date Button
                      GestureDetector(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _selectedDay ?? DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (date != null) {
                            setModalState(() {
                              _selectedDay = date; // Update selected day for the event
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${_selectedDay?.year}. ${_selectedDay?.month}. ${_selectedDay?.day}.',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 8),
                      
                      // Time Button
                      GestureDetector(
                        onTap: () {
                          // Use CupertinoDatePicker for Apple-style scrollable picker
                          showCupertinoModalPopup(
                            context: context,
                            builder: (BuildContext context) {
                              return Container(
                                height: 216,
                                padding: const EdgeInsets.only(top: 6.0),
                                margin: EdgeInsets.only(
                                  bottom: MediaQuery.of(context).viewInsets.bottom,
                                ),
                                color: CupertinoColors.systemBackground.resolveFrom(context),
                                child: SafeArea(
                                  top: false,
                                  child: CupertinoDatePicker(
                                    initialDateTime: DateTime(
                                      DateTime.now().year,
                                      DateTime.now().month,
                                      DateTime.now().day,
                                      selectedTime.hour,
                                      selectedTime.minute,
                                    ),
                                    mode: CupertinoDatePickerMode.time,
                                    use24hFormat: false,
                                    onDateTimeChanged: (DateTime newDateTime) {
                                      setModalState(() {
                                        selectedTime = TimeOfDay.fromDateTime(newDateTime);
                                      });
                                    },
                                  ),
                                ),
                              );
                            },
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            selectedTime.format(context),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
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
                    onPressed: () async {
                      if (titleController.text.isNotEmpty && selectedCalendarId != null) {
                        final eventDate = DateTime(
                           _selectedDay!.year,
                           _selectedDay!.month,
                           _selectedDay!.day,
                           selectedTime.hour,
                           selectedTime.minute,
                        );
                        
                        Navigator.pop(context);
                        await _addEvent(
                          titleController.text, 
                          selectedCategoryId, 
                          selectedCalendarId!,
                          descriptionController.text.isEmpty ? null : descriptionController.text,
                          eventDate,
                        );
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
            icon: const Icon(Icons.add),
            onPressed: _showAddEventDialog,
          ),
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () async {
              await Navigator.of(context).pushNamed('/calendars');
              _refreshData();
            },
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () async {
              await Navigator.of(context).pushNamed('/mypage');
              _refreshData();
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
              outsideDaysVisible: false,
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
            calendarBuilders: CalendarBuilders(
              selectedBuilder: (context, day, focusedDay) {
                final isToday = isSameDay(day, DateTime.now());
                return Center(
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isToday ? Colors.pink : Colors.deepPurple,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${day.day}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                );
              },
              todayBuilder: (context, day, focusedDay) {
                return Center(
                  child: Text(
                    '${day.day}',
                    style: const TextStyle(
                      color: Colors.pink,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
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
                final calendars = context.read<CalendarProvider>().calendars;

                return Positioned(
                  bottom: 1,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: eventList.take(3).map((event) {
                      final category = _categories.firstWhere(
                        (c) => c.id == event.categoryId,
                        orElse: () => _categories.first,
                      );
                      
                      final calendar = calendars.firstWhere(
                        (c) => c.calendarId == event.calendarId,
                        orElse: () => CalendarModel(
                          calendarId: -1, 
                          name: 'Unknown', 
                          type: 'PERSONAL',
                          color: '#000000',
                        ),
                      );

                      // Parse color string to Color object
                      Color calendarColor;
                      try {
                        calendarColor = Color(int.parse(calendar.color.replaceAll('#', '0xFF')));
                      } catch (e) {
                        calendarColor = Colors.black;
                      }

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 1.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              category.emoticon,
                              style: const TextStyle(fontSize: 10),
                            ),
                            const SizedBox(height: 2),
                            Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                color: calendarColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
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
                      trailing: Text(
                        '${event.date.hour > 12 ? '오후' : '오전'} ${event.date.hour > 12 ? event.date.hour - 12 : event.date.hour}:${event.date.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    );
                  })
                  .toList(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.small(
        heroTag: 'add_category',
        onPressed: _showAddCategoryDialog,
        child: const Icon(Icons.category),
      ),
    );
  }
}

