import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:front_flutter/src/features/authentication/providers/user_provider.dart';
import 'package:front_flutter/src/features/events/models/category_model.dart';
import 'package:front_flutter/src/features/events/models/event_model.dart';
import 'package:front_flutter/src/features/calendar/models/calendar_model.dart';
import 'package:front_flutter/src/features/calendar/providers/calendar_provider.dart';
import 'package:front_flutter/src/features/events/services/event_service.dart';
import 'package:front_flutter/src/features/home/models/home_response.dart';

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

  Map<String, int> _calculateEventSlots(List<EventInfo> events) {
    // Sort events by start time, then duration (longer first), then title
    final sortedEvents = List<EventInfo>.from(events);
    sortedEvents.sort((a, b) {
      int cmp = a.startAt.compareTo(b.startAt);
      if (cmp != 0) return cmp;
      
      final durationA = (a.endAt ?? a.startAt).difference(a.startAt);
      final durationB = (b.endAt ?? b.startAt).difference(b.startAt);
      cmp = durationB.compareTo(durationA); // Longer duration first
      if (cmp != 0) return cmp;
      
      return a.title.compareTo(b.title);
    });

    final slots = <String, int>{};
    final occupiedSlots = <int, DateTime>{}; // Slot Index -> End Time

    for (final event in sortedEvents) {
      int slot = 0;
      final start = DateTime(event.startAt.year, event.startAt.month, event.startAt.day);
      final end = event.endAt != null 
          ? DateTime(event.endAt!.year, event.endAt!.month, event.endAt!.day)
          : start;

      // Find first available slot
      while (true) {
        if (!occupiedSlots.containsKey(slot)) {
          break; // Slot is empty
        }
        
        final occupiedUntil = occupiedSlots[slot]!;
        if (start.isAfter(occupiedUntil)) {
          break; // Slot is free after previous event
        }
        slot++;
      }

      // Assign slot
      final key = '${event.title}_${event.startAt.toIso8601String()}_${event.calendarId}';
      slots[key] = slot;
      occupiedSlots[slot] = end;
    }

    return slots;
  }

  List<Event> _getEventsForDay(DateTime day) {
    // Get events from UserProvider
    final eventInfos = context.watch<UserProvider>().eventInfos;
    
    // Calculate slots for ALL events first
    final eventSlots = _calculateEventSlots(eventInfos);
    
    // Filter events for the specific day
    // Normalize day to match keys (Local midnight)
    final normalizedDay = DateTime(day.year, day.month, day.day);
    
    final events = eventInfos.where((info) {
      final startDate = DateTime(info.startAt.year, info.startAt.month, info.startAt.day);
      final endDate = info.endAt != null 
          ? DateTime(info.endAt!.year, info.endAt!.month, info.endAt!.day)
          : startDate;
          
      return !normalizedDay.isBefore(startDate) && !normalizedDay.isAfter(endDate);
    }).map((info) {
      final key = '${info.title}_${info.startAt.toIso8601String()}_${info.calendarId}';
      return Event(
        id: 'server_event', // No ID in EventInfo
        title: info.title,
        date: info.startAt,
        endAt: info.endAt,
        categoryId: info.categoryId.toString(),
        calendarId: info.calendarId,
        slotIndex: eventSlots[key],
        isAllDay: info.isAllDay,
      );
    }).toList();

    // Sort events to ensure consistent order across days
    events.sort((a, b) {
      // Sort by start date first
      int cmp = a.date.compareTo(b.date);
      if (cmp != 0) return cmp;
      // Then by title
      return a.title.compareTo(b.title);
    });

    return events;
  }

  Future<void> _addEvent(String title, String categoryId, int calendarId, String? description, bool isAllDay, DateTime startAt, DateTime? endAt) async {
    final success = await _eventService.createEvent(
      calendarId: calendarId,
      categoryId: int.parse(categoryId),
      title: title,
      description: description,
      isAllDay: isAllDay,
      startAt: startAt,
      endAt: endAt,
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
    
    DateTime now = DateTime.now();
    DateTime startDate = _selectedDay ?? now;
    TimeOfDay startTime = TimeOfDay.now();
    
    DateTime endDate = startDate;
    TimeOfDay endTime = TimeOfDay.fromDateTime(now.add(const Duration(hours: 1)));
    
    bool isAllDay = false;
    
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
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(labelText: 'Description'),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  
                  // All Day Toggle
                  Row(
                    children: [
                      const Text('하루 종일', style: TextStyle(fontSize: 16)),
                      const Spacer(),
                      Switch(
                        value: isAllDay,
                        onChanged: (value) {
                          setModalState(() {
                            isAllDay = value;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Start Date/Time Row
                  Row(
                    children: [
                      const Text('시작', style: TextStyle(fontSize: 16)),
                      const Spacer(),
                      
                      // Date Button
                      GestureDetector(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: startDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (date != null) {
                            setModalState(() {
                              startDate = date;
                              // Ensure end date is not before start date
                              if (endDate.isBefore(startDate)) {
                                endDate = startDate;
                              }
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
                            '${startDate.year}. ${startDate.month}. ${startDate.day}.',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                      
                      if (!isAllDay) ...[
                        const SizedBox(width: 8),
                        // Time Button
                        GestureDetector(
                          onTap: () {
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
                                        startDate.year,
                                        startDate.month,
                                        startDate.day,
                                        startTime.hour,
                                        startTime.minute,
                                      ),
                                      mode: CupertinoDatePickerMode.time,
                                      use24hFormat: false,
                                      onDateTimeChanged: (DateTime newDateTime) {
                                        setModalState(() {
                                          startTime = TimeOfDay.fromDateTime(newDateTime);
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
                              startTime.format(context),
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),

                  // End Date/Time Row
                  Row(
                    children: [
                      const Text('종료', style: TextStyle(fontSize: 16)),
                      const Spacer(),
                      
                      // Date Button
                      GestureDetector(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: endDate,
                            firstDate: startDate, // Can't end before start
                            lastDate: DateTime(2100),
                          );
                          if (date != null) {
                            setModalState(() {
                              endDate = date;
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
                            '${endDate.year}. ${endDate.month}. ${endDate.day}.',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                      
                      if (!isAllDay) ...[
                        const SizedBox(width: 8),
                        // Time Button
                        GestureDetector(
                          onTap: () {
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
                                        endDate.year,
                                        endDate.month,
                                        endDate.day,
                                        endTime.hour,
                                        endTime.minute,
                                      ),
                                      mode: CupertinoDatePickerMode.time,
                                      use24hFormat: false,
                                      onDateTimeChanged: (DateTime newDateTime) {
                                        setModalState(() {
                                          endTime = TimeOfDay.fromDateTime(newDateTime);
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
                              endTime.format(context),
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ],
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
                        final startDateTime = DateTime(
                           startDate.year,
                           startDate.month,
                           startDate.day,
                           isAllDay ? 0 : startTime.hour,
                           isAllDay ? 0 : startTime.minute,
                        );
                        
                        final endDateTime = DateTime(
                           endDate.year,
                           endDate.month,
                           endDate.day,
                           isAllDay ? 23 : endTime.hour,
                           isAllDay ? 59 : endTime.minute,
                        );
                        
                        Navigator.pop(context);
                        await _addEvent(
                          titleController.text, 
                          selectedCategoryId, 
                          selectedCalendarId!,
                          descriptionController.text.isEmpty ? null : descriptionController.text,
                          isAllDay,
                          startDateTime,
                          endDateTime,
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
            rowHeight: 64.0,
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
                final color = isToday ? Colors.pink : Colors.deepPurple;
                
                return Container(
                  margin: const EdgeInsets.all(2.0), // Slight spacing between cells
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1), // Light background
                    borderRadius: BorderRadius.circular(8.0), // Rounded corners
                    border: Border.all(color: color.withValues(alpha: 0.5), width: 1), // Optional: subtle border
                  ),
                  alignment: Alignment.topCenter, // Align text to top (or center?)
                  // Usually numbers are centered or top-centered. 
                  // Let's keep it centered but maybe add padding if needed.
                  // Actually, standard calendar numbers are often centered.
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8.0), // Adjust if needed
                    child: Text(
                      '${day.day}',
                      style: TextStyle(
                        color: color, // Text matches theme color
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
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
                
                // Filter events that fit within the max visible slots (e.g., 3)
                // We use slotIndex to determine visibility
                final visibleEvents = events.cast<Event>().where((e) => (e.slotIndex ?? 0) < 3).toList();
                final calendars = context.read<CalendarProvider>().calendars;

                return Stack(
                  children: visibleEvents.map((event) {
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

                    // Determine position (Start, Middle, End, Single)
                    final startDate = DateTime(event.date.year, event.date.month, event.date.day);
                    final endDate = event.endAt != null 
                        ? DateTime(event.endAt!.year, event.endAt!.month, event.endAt!.day)
                        : startDate;
                    final currentDay = DateTime(day.year, day.month, day.day);
                    
                    final isStart = isSameDay(currentDay, startDate);
                    final isEnd = isSameDay(currentDay, endDate);
                    final isSingleDay = isStart && isEnd;
                    
                    // Check if it should be a dot (single day, non-all-day)
                    // Note: endAt might not be null even for single day events (e.g. timed events).
                    // So we check if it's single day AND not all day.
                    final showAsDot = !event.isAllDay && (event.endAt == null || isSingleDay);

                    // Calculate top position based on slot index
                    // Base top = 42.0 (moved down to avoid selection circle)
                    // Row height = 5.0 (4.0 bar + 1.0 margin)
                    final top = 42.0 + ((event.slotIndex ?? 0) * 5.0);

                    if (showAsDot) {
                      return Positioned(
                        top: top,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            width: 16, // Pill width
                            height: 4,
                            decoration: BoxDecoration(
                              color: calendarColor,
                              borderRadius: BorderRadius.circular(2), // Rounded pill
                            ),
                          ),
                        ),
                      );
                    }

                    // Bar Styling
                    BorderRadius borderRadius;
                    EdgeInsets margin;
                    
                    if (isSingleDay) {
                      borderRadius = BorderRadius.circular(4);
                      margin = const EdgeInsets.symmetric(horizontal: 1.5);
                    } else if (isStart) {
                      borderRadius = const BorderRadius.horizontal(left: Radius.circular(4));
                      margin = const EdgeInsets.only(left: 1.5, right: 0);
                    } else if (isEnd) {
                      borderRadius = const BorderRadius.horizontal(right: Radius.circular(4));
                      margin = const EdgeInsets.only(left: 0, right: 1.5);
                    } else {
                      // Middle
                      borderRadius = BorderRadius.zero;
                      margin = EdgeInsets.zero;
                    }

                    return Positioned(
                      top: top,
                      left: 0,
                      right: 0,
                      height: 4,
                      child: Container(
                        margin: margin,
                        decoration: BoxDecoration(
                          color: calendarColor.withValues(alpha: 0.5), // Slightly more opaque
                          borderRadius: borderRadius,
                          border: isStart 
                              ? Border(left: BorderSide(color: calendarColor, width: 3)) 
                              : null,
                        ),
                      ),
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
        onPressed: _showAddEventDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
