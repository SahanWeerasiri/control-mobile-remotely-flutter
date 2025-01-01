import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart' as route;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeService();
  await startServer();
  runApp(const MyApp());
}

Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  // Create notification channel
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'my_foreground', // same as in service configuration
    'Background Service', // name of the channel
    description:
        'This channel is used for background service notification', // description
    importance: Importance.high, // importance must be at least 'low'
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  // Configure the background service
  await service.configure(
    androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: true,
        isForegroundMode: false,
        notificationChannelId: channel.id,
        initialNotificationTitle: 'Background Service',
        initialNotificationContent: 'Initializing',
        foregroundServiceNotificationId: 888,
        autoStartOnBoot: true),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );

  await service.startService();
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  return true;
}

int _ticks = 0; // Shared state for ticks

Future<void> startServer() async {
  // Create the router to define routes
  final router = route.Router();

  // Define a simple GET request
  router.get('/hello', (Request request) {
    return Response.ok('Hello from Flutter server! Ticks: $_ticks');
  });

  // Create the handler using the router
  final handler = const Pipeline()
      .addMiddleware(logRequests()) // Optional middleware to log requests
      .addHandler(router);

  // Start the HTTP server (bind to the device's IP address and a port)
  final server = await shelf_io.serve(handler, InternetAddress.anyIPv4, 8080);
  print('Server started on http://${server.address.address}:${server.port}');
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      // service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  // Update the _ticks variable periodically in the background service
  Timer.periodic(const Duration(seconds: 1), (timer) async {
    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        // Update notification content
        service.setForegroundNotificationInfo(
          title: "Background Service",
          content: "Running for ${timer.tick} seconds",
        );
      }
    }

    // Update the ticks and log the background service activity
    print('Background service running for ${timer.tick} seconds');
    _ticks = timer.tick; // Update shared state

    // Broadcast service status (e.g., update the UI or other parts of the app)
    service.invoke('update', {
      'tick': timer.tick,
      'timestamp': DateTime.now().toIso8601String(),
    });
  });
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Container(), // Empty container since we don't need UI
      ),
    );
  }
}
