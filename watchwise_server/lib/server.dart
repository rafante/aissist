import 'dart:io';
import 'package:serverpod/serverpod.dart';
import 'src/generated/protocol.dart';
import 'src/generated/endpoints_clean.dart';

/// Serverpod server for AIssist
void run(List<String> args) async {
  // Initialize Serverpod with clean endpoints (no auth dependencies)
  final pod = Serverpod(args, Protocol(), CleanEndpoints());

  // Setup a default page at the web root
  pod.webServer.addRoute(RootRoute(), '/');
  pod.webServer.addRoute(RootRoute(), '/index.html');

  // Serve all files in the web/static directory 
  final root = Directory(Uri(path: 'web/static').toFilePath());
  pod.webServer.addRoute(StaticRoute.directory(root));

  print('🎬 AIssist API Server starting...');
  print('📋 Available endpoints: /greeting/hello');
  
  // Start the server
  await pod.start();
  
  print('🚀 AIssist API running on port 8080!');
}