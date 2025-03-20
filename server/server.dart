import 'dart:io';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_cors_headers/shelf_cors_headers.dart';

void main() async {
  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final handler = const shelf.Pipeline()
      .addMiddleware(corsHeaders())
      .addHandler(_handleRequest);

  final server = await io.serve(handler, '0.0.0.0', port);
  print('Server running on port ${server.port}');
}

Future<shelf.Response> _handleRequest(shelf.Request request) async {
  return shelf.Response.ok('Server is running!');
}
