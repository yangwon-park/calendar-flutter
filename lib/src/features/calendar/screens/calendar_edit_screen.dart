import 'package:flutter/material.dart';
import 'package:front_flutter/src/features/calendar/models/calendar_model.dart';
import 'package:front_flutter/src/features/calendar/providers/calendar_provider.dart';
import 'package:provider/provider.dart';

class CalendarEditScreen extends StatefulWidget {
  final CalendarModel calendar;

  const CalendarEditScreen({super.key, required this.calendar});

  @override
  State<CalendarEditScreen> createState() => _CalendarEditScreenState();
}

class _CalendarEditScreenState extends State<CalendarEditScreen> {
  late TextEditingController _nameController;
  late TextEditingController _colorController;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.calendar.name);
    _colorController = TextEditingController(text: widget.calendar.color);
    _descriptionController = TextEditingController(text: widget.calendar.description);
    
    _fetchCalendarDetails();
  }

  Future<void> _fetchCalendarDetails() async {
    final updatedCalendar = await context.read<CalendarProvider>().fetchCalendar(widget.calendar.calendarId);
    if (updatedCalendar != null && mounted) {
      setState(() {
        _nameController.text = updatedCalendar.name;
        _colorController.text = updatedCalendar.color;
        _descriptionController.text = updatedCalendar.description ?? '';
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _colorController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameController.text.isEmpty || _colorController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name and Color are required')),
      );
      return;
    }

    final success = await context.read<CalendarProvider>().updateCalendar(
      widget.calendar.calendarId,
      _nameController.text,
      widget.calendar.type,
      _colorController.text,
      _descriptionController.text.isEmpty ? null : _descriptionController.text,
    );

    if (success && mounted) {
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update calendar')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Calendar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _save,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _colorController,
              decoration: const InputDecoration(labelText: 'Color (e.g., #FF0000)'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 16),
            // Read-only Type field
            InputDecorator(
              decoration: const InputDecoration(labelText: 'Type'),
              child: Text(widget.calendar.type),
            ),
          ],
        ),
      ),
    );
  }
}