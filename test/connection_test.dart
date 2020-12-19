import 'package:flutter_test/flutter_test.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:file_transfer/control/connection.dart';

void main() async {
  // Setup ws server
  var handler = webSocketHandler((webSocket) {
    webSocket.stream.listen((message) {
      webSocket.sink.add("echo $message");
    });
  });

  shelf_io.serve(handler, 'localhost', 1234).then((server) {
    print('Serving at ws://${server.address.host}:${server.port}');
  });
  var link = Uri.parse("ws://localhost:1234");
  var _ = await setupConnection(link);

  test("Send data", () async {
    _.sink.add("test");
    var a = await _.stream.first;
    expect(a, "echo test");
  });
}
