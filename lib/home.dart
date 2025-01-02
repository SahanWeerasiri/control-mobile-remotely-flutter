import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart' as r;

Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'my_foreground',
    'Background Service',
    description: 'Used for background service notifications',
    importance: Importance.high,
  );

  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true,
      notificationChannelId: channel.id,
      initialNotificationTitle: 'Background Server',
      initialNotificationContent: 'Starting...',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onStart,
    ),
  );

  await service.startService();
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  MethodChannel platform = MethodChannel('com.example.test_venom/call_logs');
  HttpServer? server;

  final router = r.Router();
  router.get('/hello', (Request request) => Response.ok('Hello from Flutter!'));
  router.get('/call_logs', (Request request) async {
    try {
      final callLogs = await platform.invokeMethod("getCallLogs");
      return Response.ok(callLogs.toString());
    } catch (e) {
      return Response.internalServerError(body: e.toString());
    }
  });

  server = await shelf_io.serve(
    const Pipeline().addMiddleware(logRequests()).addHandler(router),
    InternetAddress.anyIPv4,
    8080,
  );

  print('Server running on http://${server.address.address}:${server.port}');

  Timer.periodic(const Duration(seconds: 1), (timer) {
    service.invoke('update', {'tick': timer.tick});
  });
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Call Logs App')),
        body: Center(child: const Text('Server running in the background')),
      ),
    );
  }
}
