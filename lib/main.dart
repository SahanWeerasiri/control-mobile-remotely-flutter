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
  runApp(const MyApp());
}

Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'my_foreground',
    'Background Service',
    description: 'This channel is used for background service notification',
    importance: Importance.high,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: false,
      notificationChannelId: channel.id,
      initialNotificationTitle: 'Background Server',
      initialNotificationContent: 'Server is starting...',
      foregroundServiceNotificationId: 888,
      autoStartOnBoot: true,
    ),
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

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  // Server instance variable
  HttpServer? server;
  int ticks = 0;

  // Initialize the server
  try {
    final router = route.Router();

    // Update the route to include the ticks counter
    router.get('/hello', (Request request) {
      return Response.ok('Hello from Flutter server! Ticks: $ticks');
    });

    final handler =
        const Pipeline().addMiddleware(logRequests()).addHandler(router);

    server = await shelf_io.serve(
      handler,
      InternetAddress.anyIPv4,
      8080,
    );

    print('Server started on http://${server.address.address}:${server.port}');

    if (service is AndroidServiceInstance) {
      service.setForegroundNotificationInfo(
        title: "Background Server",
        content: "Server running on port 8080",
      );
    }
  } catch (e) {
    print('Failed to start server: $e');
    if (service is AndroidServiceInstance) {
      service.setForegroundNotificationInfo(
        title: "Background Server",
        content: "Failed to start server: $e",
      );
    }
  }

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      // service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  // Periodic timer for updating notification and ticks
  Timer.periodic(const Duration(seconds: 1), (timer) async {
    ticks = timer.tick;

    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        service.setForegroundNotificationInfo(
          title: "Background Server",
          content: "Server running for ${timer.tick} seconds",
        );
      }
    }

    print('Background service running for ${timer.tick} seconds');
    service.invoke('update', {
      'tick': timer.tick,
      'timestamp': DateTime.now().toIso8601String(),
      'server_status': server != null ? 'running' : 'stopped',
    });
  });
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Container(),
      ),
    );
  }
}
