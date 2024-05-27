import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reminder App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ReminderScreen(),
    );
  }
}

class ReminderScreen extends StatefulWidget {
  @override
  _ReminderScreenState createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> {
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  final List<String> daysOfWeek = [
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday'
  ];

  final List<String> activities = [
    'Wake up',
    'Go to gym',
    'Breakfast',
    'Meetings',
    'Lunch',
    'Quick nap',
    'Go to library',
    'Dinner',
    'Go to sleep'
  ];

  String? selectedDay;
  TimeOfDay? selectedTime;
  String? selectedActivity;

  @override
  void initState() {
    super.initState();

    tz.initializeTimeZones();

    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings initializationSettings =
        InitializationSettings(
            android: initializationSettingsAndroid, iOS: null);
    flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  tz.TZDateTime _nextInstanceOfScheduledTime(DateTime scheduledDate) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledTZDateTime =
        tz.TZDateTime.from(scheduledDate, tz.local);
    if (scheduledTZDateTime.isBefore(now)) {
      scheduledTZDateTime = scheduledTZDateTime.add(const Duration(days: 1));
    }
    return scheduledTZDateTime;
  }

  Future<void> _scheduleNotification() async {
    if (selectedDay == null ||
        selectedTime == null ||
        selectedActivity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select day, time, and activity')),
      );
      return;
    }

    final now = DateTime.now();
    final selectedDate = now.add(Duration(
      days: (daysOfWeek.indexOf(selectedDay!) - now.weekday + 7) % 7,
    ));

    final scheduledDate = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime!.hour,
      selectedTime!.minute,
    );

    final scheduledTZDateTime = _nextInstanceOfScheduledTime(scheduledDate);

    final androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'your_channel_id',
      'your_channel_name',
      channelDescription: 'your_channel_description',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );
    final platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics, iOS: null);
    await flutterLocalNotificationsPlugin.zonedSchedule(
      0,
      'Reminder',
      selectedActivity,
      scheduledTZDateTime,
      platformChannelSpecifics,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Reminder set for $selectedActivity')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reminder App'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            DropdownButton<String>(
              hint: Text('Select Day'),
              value: selectedDay,
              onChanged: (newValue) {
                setState(() {
                  selectedDay = newValue!;
                });
              },
              items: daysOfWeek.map((day) {
                return DropdownMenuItem(
                  child: Text(day),
                  value: day,
                );
              }).toList(),
            ),
            SizedBox(height: 16.0),
            GestureDetector(
              onTap: () async {
                final TimeOfDay? picked = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );
                if (picked != null && picked != selectedTime)
                  setState(() {
                    selectedTime = picked;
                  });
              },
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Select Time',
                ),
                baseStyle: TextStyle(color: Colors.black),
                child: selectedTime == null
                    ? Text('No time selected')
                    : Text('${selectedTime!.format(context)}'),
              ),
            ),
            SizedBox(height: 16.0),
            DropdownButton<String>(
              hint: Text('Select Activity'),
              value: selectedActivity,
              onChanged: (newValue) {
                setState(() {
                  selectedActivity = newValue!;
                });
              },
              items: activities.map((activity) {
                return DropdownMenuItem(
                  child: Text(activity),
                  value: activity,
                );
              }).toList(),
            ),
            SizedBox(height: 32.0),
            ElevatedButton(
              onPressed: _scheduleNotification,
              child: Text('Set Reminder'),
            ),
          ],
        ),
      ),
    );
  }
}
