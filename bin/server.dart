import 'dart:io';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_cors_headers/shelf_cors_headers.dart';
import 'dart:convert';

void main() async {
  // Render.com provides the PORT environment variable
  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = NotificationServer(port: port);
  await server.start();
}

class NotificationServer {
  final int port;
  final Map<String, DateTime> activeDevices = {};

  NotificationServer({required this.port});

  Future<void> start() async {
    final handler = const shelf.Pipeline()
        .addMiddleware(corsHeaders())
        .addMiddleware(shelf.logRequests())
        .addHandler(_handleRequest);

    final server = await io.serve(handler, '0.0.0.0', port);
    print('Server started on port ${server.port}');
  }

  Future<shelf.Response> _handleRequest(shelf.Request request) async {
    switch ('${request.method} ${request.url.path}') {
      case 'POST register':
        return _handleRegister(request);
      case 'POST send-notification':
        return _handleSendNotification(request);
      default:
        return shelf.Response.notFound('Not Found');
    }
  }

  Future<shelf.Response> _handleRegister(shelf.Request request) async {
    final payload = await request.readAsString();
    final data = jsonDecode(payload);
    final deviceToken = data['deviceToken'];
    
    activeDevices[deviceToken] = DateTime.now();
    
    return shelf.Response.ok(
      jsonEncode({
        'status': 'success',
        'activeDevices': activeDevices.keys.toList()
      }),
      headers: {'content-type': 'application/json'}
    );
  }

  Future<shelf.Response> _handleSendNotification(shelf.Request request) async {
    final payload = await request.readAsString();
    final data = jsonDecode(payload);
    
    return shelf.Response.ok(
      jsonEncode({'status': 'success', 'message': 'Notification sent'}),
      headers: {'content-type': 'application/json'}
    );
  }
}
