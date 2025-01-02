import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart' as r;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
  await startServer();
}

Future<void> startServer() async {
  MethodChannel platform = MethodChannel('com.example.test_venom/call_logs');
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

  router.get('/make_call', (Request request) async {
    try {
      final callLogs = await platform.invokeMethod("makeCall", {
        "phoneNumber": "0332247865", // Replace with the actual number
      });
      return Response.ok(callLogs.toString());
    } catch (e) {
      return Response.internalServerError(body: e.toString());
    }
  });

  final server = await shelf_io.serve(
    const Pipeline().addMiddleware(logRequests()).addHandler(router),
    InternetAddress.anyIPv4,
    8080,
  );

  print('Server running on http://${server.address.address}:${server.port}');
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
