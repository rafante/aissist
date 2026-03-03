import 'dart:io';
import 'package:serverpod/serverpod.dart';
import 'src/web/routes/root.dart';
import 'src/generated/protocol.dart';
import 'src/generated/endpoints.dart';

/// Serverpod server for AIssist
Future<void> run(List<String> args) async {
  // Initialize Serverpod
  final pod = Serverpod(
    args,
    Protocol(),
    Endpoints(),
    authenticationHandler: null,
  );

  // Setup a default page at the web root
  pod.webServer.addRoute(RootRoute(), '/');
  pod.webServer.addRoute(RootRoute(), '/index.html');

  // Serve static files from web/static directory
  pod.webServer.addRoute(
    StaticRoute.directory(Directory('web/static')),
    '/*',
  );

  // Start the server
  await pod.start();
}
