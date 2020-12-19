import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

Future<WebSocketChannel> setupConnection(Uri uri) async {
  var channel = WebSocketChannel.connect(uri);

  return channel;
}

class Aggresive {
  Aggresive() {
    var handler = webSocketHandler((webSocket) {
      webSocket.stream.listen((message) {
        webSocket.sink.add("echo $message");
      });
    });

    shelf_io.serve(handler, 'localhost', 1234).then((server) {
      print('Serving at ws://${server.address.host}:${server.port}');
    });
  }
}
