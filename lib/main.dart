import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:uuid/uuid.dart';

const String serverUrl = 'https://your-service-name.onrender.com'; // Replace with your Render URL

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initNotifications();
  runApp(const MainApp());
}

Future<void> initNotifications() async {
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initializationSettings = InitializationSettings(android: androidSettings);
  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (details) {
      print('Notification clicked: ${details.payload}');
    },
  );
}

Future<void> showNotification(String title, String body) async {
  const androidDetails = AndroidNotificationDetails(
    'default_channel',
    'Default Channel',
    importance: Importance.high,
    priority: Priority.high,
  );
  const details = NotificationDetails(android: androidDetails);
  await flutterLocalNotificationsPlugin.show(0, title, body, details);
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  String deviceToken = '';
  final targetTokenController = TextEditingController();
  List<String> activeDevices = [];
  bool isLoading = false;
  bool isConnected = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    setState(() => isLoading = true);
    try {
      await generateDeviceToken();
      await registerWithServer();
      startPollingForNotifications();
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> generateDeviceToken() async {
    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    final uuid = const Uuid().v4();
    setState(() {
      deviceToken = '${androidInfo.model}_$uuid';
    });
  }

  Future<void> registerWithServer() async {
    try {
      final response = await http.post(
        Uri.parse('$serverUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'deviceToken': deviceToken,
          'deviceInfo': {'model': 'Android Device'},
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          isConnected = true;
          activeDevices = List<String>.from(
            data['activeDevices'].map((d) => d['deviceToken']),
          );
        });
      }
    } catch (e) {
      setState(() => isConnected = false);
      print('Registration error: $e');
    }
  }

  void startPollingForNotifications() {
    // In a production app, you would use WebSockets or FCM instead of polling
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 2));
      await checkForNotifications();
      return true;
    });
  }

  Future<void> checkForNotifications() async {
    try {
      final response = await http.get(
        Uri.parse('$serverUrl/devices'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final devices = jsonDecode(response.body);
        setState(() {
          activeDevices = List<String>.from(
            devices.map((d) => d['deviceToken']),
          );
        });
      }
    } catch (e) {
      print('Error checking notifications: $e');
    }
  }

  Future<void> sendNotification() async {
    if (targetTokenController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a target token')),
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('$serverUrl/send-notification'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'targetToken': targetTokenController.text,
          'senderToken': deviceToken,
          'title': 'New Message',
          'body': 'Hello from ${deviceToken.split('_')[0]}!',
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification sent successfully!')),
        );
      } else {
        throw 'Failed to send notification';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Push Notifications'),
          actions: [
            Icon(
              isConnected ? Icons.cloud_done : Icons.cloud_off,
              color: isConnected ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 16),
          ],
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            const Text(
                              'Your Device Token:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            SelectableText(deviceToken),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: targetTokenController,
                      decoration: const InputDecoration(
                        labelText: 'Enter Target Device Token',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: sendNotification,
                      child: const Text('Send Notification'),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Active Devices:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: activeDevices.length,
                        itemBuilder: (context, index) {
                          return Card(
                            child: ListTile(
                              title: Text(activeDevices[index]),
                              onTap: () {
                                targetTokenController.text = activeDevices[index];
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
