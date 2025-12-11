import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
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
  String _selectedColor = '#000000';
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.calendar.name);
    _selectedColor = widget.calendar.color;
    _descriptionController = TextEditingController(text: widget.calendar.description);
    
    _fetchCalendarDetails();
  }

  Future<void> _fetchCalendarDetails() async {
    final updatedCalendar = await context.read<CalendarProvider>().fetchCalendar(widget.calendar.calendarId);
    if (updatedCalendar != null && mounted) {
      setState(() {
        _nameController.text = updatedCalendar.name;
        _selectedColor = updatedCalendar.color;
        _descriptionController.text = updatedCalendar.description ?? '';
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name is required')),
      );
      return;
    }

    final success = await context.read<CalendarProvider>().updateCalendar(
      widget.calendar.calendarId,
      _nameController.text,
      widget.calendar.type,
      _selectedColor,
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            
            const Text(
              'Color',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Color',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                Color currentColor;
                try {
                  currentColor = Color(int.parse(_selectedColor.replaceAll('#', '0xFF')));
                } catch (e) {
                  currentColor = Colors.black;
                }

                showDialog(
                  context: context,
                  builder: (context) {
                    Color pickedColor = currentColor;
                    return AlertDialog(
                      title: const Text('Select Color'),
                      content: SingleChildScrollView(
                        child: ColorPicker(
                          pickerColor: currentColor,
                          onColorChanged: (color) {
                            pickedColor = color;
                          },
                          displayThumbColor: true,
                          enableAlpha: false, // Calendar colors usually opaque
                          paletteType: PaletteType.hsvWithHue,
                          pickerAreaHeightPercent: 0.8,
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              // Convert Color to Hex String #RRGGBB
                              _selectedColor = '#${pickedColor.red.toRadixString(16).padLeft(2, '0')}${pickedColor.green.toRadixString(16).padLeft(2, '0')}${pickedColor.blue.toRadixString(16).padLeft(2, '0')}'.toUpperCase();
                            });
                            Navigator.of(context).pop();
                          },
                          child: const Text('Select'),
                        ),
                      ],
                    );
                  },
                );
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Color(int.parse(_selectedColor.replaceAll('#', '0xFF'))),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _selectedColor,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const Spacer(),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            // Read-only Type field
            InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Type',
                border: OutlineInputBorder(),
              ),
              child: Text(widget.calendar.type),
            ),
          ],
        ),
      ),
    );
  }
}