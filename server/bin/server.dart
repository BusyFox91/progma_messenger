import 'dart:io';
import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';

import 'package:server/database_helper.dart' as db_helper;
// Configure routes.
final _router = Router()
  ..get('/', _rootHandler)
  ..get('/echo/<message>', _echoHandler)
  ..post('/send', _postMessageHandler);
  // ..post('/userCreate);

Response _rootHandler(Request req) {
  return Response.ok('This is the root of the server.\nYou can send "/echo/<message>" to check the server.\n');
}

Response _echoHandler(Request request) {
  final message = request.params['message'] ?? '';
  return Response.ok('GET:\n$message\n');
}

Future<Response> _postMessageHandler(Request req) async {
  try {
    final rawbody = await req.readAsString();
    
    final Map<String, dynamic> data = jsonDecode(rawbody) as Map<String, dynamic>;
    
    final String sender = data['sender'] ?? 'Anonymous';
    final String reciever = data['reciever'] ?? 'Anonymous';
    final String message = data['message'] ?? '';

    if (reciever == 'Anonymous') {return Response.badRequest(body: 'Wrong POST-request: No such user "$reciever"');}

    return Response.ok("POST:\nfrom: $sender\nto: $reciever\nMessage:\n$message\n");
  } catch(e) {
    return Response.badRequest(body: 'Wrong POST-request:\n$e');
  }
}


void main(List<String> args) async {
  // final db = 
  // Use any available host or container IP (usually `0.0.0.0`).
  final ip = InternetAddress.anyIPv4;

  // Configure a pipeline that logs requests.
  final handler = Pipeline()
      .addMiddleware(logRequests())
      .addHandler(_router.call);

  // For running in containers, we respect the PORT environment variable.
  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await serve(handler, ip, port);
  print('Server listening on port ${server.port}');
}
