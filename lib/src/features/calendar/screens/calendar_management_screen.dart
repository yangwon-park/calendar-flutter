import 'package:flutter/material.dart';
import 'package:front_flutter/src/features/calendar/providers/calendar_provider.dart';
import 'package:front_flutter/src/features/calendar/screens/calendar_edit_screen.dart';
import 'package:provider/provider.dart';

class CalendarManagementScreen extends StatefulWidget {
  const CalendarManagementScreen({super.key});

  @override
  State<CalendarManagementScreen> createState() => _CalendarManagementScreenState();
}

class _CalendarManagementScreenState extends State<CalendarManagementScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch calendars when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CalendarProvider>().fetchCalendars();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendars'),
      ),
      body: Consumer<CalendarProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.calendars.isEmpty) {
            return const Center(child: Text('No calendars found.'));
          }

          return ListView.builder(
            itemCount: provider.calendars.length,
            itemBuilder: (context, index) {
              final calendar = provider.calendars[index];
              return ListTile(
                leading: Icon(
                  calendar.type == 'COUPLE' ? Icons.favorite : Icons.person,
                  color: calendar.type == 'COUPLE' ? Colors.pink : Colors.blue,
                ),
                title: Text(calendar.name),
                subtitle: calendar.description != null ? Text(calendar.description!) : null,
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CalendarEditScreen(calendar: calendar),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
