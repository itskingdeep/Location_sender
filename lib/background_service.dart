// lib/background_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

Future<void> initializeService() async {
  final service = FlutterBackgroundService();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  // Create notification channel (REQUIRED for Android 8.0+)
  if (Platform.isAndroid) {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'my_foreground', // id
      'Location Service', // title
      description: 'Sharing your location in background', // description
      importance: Importance.low, // must be at low or higher level
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  if (Platform.isAndroid || Platform.isIOS) {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsIOS =
    DarwinInitializationSettings();
    const InitializationSettings initializationSettings =
    InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true,
      notificationChannelId: 'my_foreground',
      initialNotificationTitle: 'Location Service',
      initialNotificationContent: 'Sharing location...',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );

  // Start service immediately after configuration
  service.startService();
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  return true;
}

@pragma('vm:entry-point')
Future<void> onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  if (service is AndroidServiceInstance) {
    service.setForegroundNotificationInfo(
      title: "Location Service",
      content: "Sharing location...",
    );
  }

  // Notify that service is running
  service.invoke('serviceState', {'isRunning': true});

  // Listen stop event
  service.on("stopService").listen((event) {
    service.invoke('serviceState', {'isRunning': false});
    service.stopSelf();
  });

  // Run location update every 5 seconds
  Timer.periodic(const Duration(seconds: 5), (timer) async {
    if (!(await Geolocator.isLocationServiceEnabled())) {
      print("Location services disabled");
      return;
    }

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        print("Location permission denied");
        return;
      }

      Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      print("Background Location: ${pos.latitude}, ${pos.longitude}");

      // Replace with your Firebase Realtime DB REST API URL
      const firebaseUrl =
          "https://fir-connection-fd0c1-default-rtdb.firebaseio.com/user_location/user1.json";

      await http.put(
        Uri.parse(firebaseUrl),
        body: jsonEncode({
          "latitude": pos.latitude,
          "longitude": pos.longitude,
          "timestamp": DateTime.now().toIso8601String(),
        }),
      );
    } catch (e) {
      print("Error fetching location or sending to Firebase: $e");
    }
  });
}