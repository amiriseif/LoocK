import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class TheftNotificationService {
  final DatabaseReference _theftsRef = FirebaseDatabase.instance.ref('11110000t');
  final DatabaseReference _visitorRef = FirebaseDatabase.instance.ref('visitor');

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  // Initialize Notifications
  Future<void> initializeNotifications() async {
    const AndroidInitializationSettings androidInitialization =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
    InitializationSettings(android: androidInitialization);

    await _notificationsPlugin.initialize(initializationSettings);
    print("Notifications Initialized Successfully");
  }

  // Show Local Notification
  Future<void> showNotification(String title, String body) async {
    const AndroidNotificationDetails androidDetails =
    AndroidNotificationDetails(
      'theft_channel_id', // Channel ID
      'Theft Alerts', // Channel Name
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails platformDetails =
    NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      0, // Notification ID
      title,
      body,
      platformDetails,
    );
  }

  // Listen to Realtime Database Changes
  void startListening() {
    print("Starting to Listen for Theft and Visitor Data...");

    // Listen for theft data
    _theftsRef.onValue.listen((event) {
      final data = event.snapshot.value;
      print("Received theft data: $data");

      if (data != null && data is Map) {
        Map<dynamic, dynamic> theftData = data;

        if (theftData['thief'] == 'yes') {
          showNotification('Theft Alert!', 'A theft attempt has been detected.');
        }
      }
    });

    // Listen for visitor data
    _visitorRef.onValue.listen((event) {
      final data = event.snapshot.value;
      print("Received visitor data: $data");

      if (data != null && data is Map) {
        Map<dynamic, dynamic> visitorData = data;

        if (visitorData['ringing'] == 'yes') {
          showNotification(
              'Visitor Alert!', 'A visitor is at the door and ringing the bell.');
        }
      }
    });
  }
}
