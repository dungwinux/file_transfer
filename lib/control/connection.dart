import 'dart:convert';
import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:path/path.dart' as path;
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class File extends FileView {
  Uint8List data;
  File(String name, this.data) : super(name, data.hashCode.toString());
  // TODO: replace better hash
}

class FileView {
  final String _name;
  final String _hash;

  FileView(this._name, this._hash);

  @override
  String toString() {
    return '$_name';
  }

  String toJson() {
    return '$_name/$_hash';
  }

  get name {
    return _name;
  }

  get hash {
    return _hash;
  }

  bool operator ==(Object other) {
    if (other is FileView) {
      return other.hash == _hash && other.name == _name;
    } else {
      return null;
    }
  }

  @override
  int get hashCode => _hash.hashCode * _name.hashCode;
}

enum TransferType { list, file }

extension TransferTypeString on TransferType {
  String get toStr {
    return ["list", "file"].elementAt(this.index);
  }
}

class TransferEvent {
  TransferType type;
  List<FileView> content;
  Uint8List data;

  TransferEvent(this.type, this.content, {this.data})
      : assert(type != null && content != null);

  TransferEvent.fromJson(Map<String, dynamic> msg) {
    assert(msg != null);
    switch (msg["type"]) {
      case "list":
        type = TransferType.list;
        break;
      case "file":
        type = TransferType.file;
        break;
      default:
        throw "Unknown content: ${msg["type"]}";
    }
    content = (jsonDecode(msg["content"]) as List).map((e) {
      var fileInfo = e.toString().split("/");
      return FileView(fileInfo[0], fileInfo[1]);
    }).toList();
    if (type == TransferType.file) assert(content.length == 1);
    if (msg["data"] != null) data = base64.decode(msg["data"]);
  }

  Map<String, dynamic> toJson() => {
        "type": type.toStr,
        if (data != null) "data": base64.encode(data),
        if (content != null)
          "content": jsonEncode(content.map((e) => e.toJson()).toList()),
      };

  @override
  String toString() {
    return toJson().toString();
  }
}

abstract class Connector {
  WebSocketChannel socket;
  // TODO: handle status
  List<File> fileList = [];
  List<FileView> receiveList = [];
  Map<FileView, String> saveLocations = Map();

  void subscribe() {
    socket.stream.asBroadcastStream().listen((event) {
      var msg = TransferEvent.fromJson(jsonDecode(event as String));
      if (msg.type == TransferType.list)
        receiveList = msg.content;
      else if (msg.type == TransferType.file) {
        if (msg.data == null) {
          var _file = fileList.singleWhere(
              (FileView element) => element == msg.content.first,
              orElse: () => null);
          if (_file != null) sendFile(_file);
        } else {
          var _file = msg.content.first;
          XFile.fromData(msg.data, name: msg.content.first._name)
              .saveTo(saveLocations.remove(_file));
        }
      }
      print(msg);
    });
  }

  void sendList([List<File> additionals = const []]) {
    fileList = (fileList.toSet()..addAll(additionals)).toList();
    var send = TransferEvent(TransferType.list, fileList);
    socket.sink.add(jsonEncode(send));
  }

  Future<void> requestFile(FileView file, String saveDir) async {
    var send = TransferEvent(TransferType.file, [file]);
    saveLocations[file] = path.join(saveDir, file.name);
    socket.sink.add(jsonEncode(send));
  }

  void sendFile(File file) async {
    var send = TransferEvent(TransferType.file, [file], data: file.data);

    socket.sink.add(jsonEncode(send));
  }
}

class ActiveConnector extends Connector {
  String host = 'localhost';
  final int port = 1234;
  ActiveConnector() {
    var handler = webSocketHandler((webSocket) {
      socket = webSocket;
      subscribe();
    });

    shelf_io.serve(handler, host, port).then((server) {
      host = server.address.host;
      print('Serving at ws://${server.address.address}:${server.port}');
    });
  }
}

class PassiveConnector extends Connector {
  PassiveConnector(String link) {
    socket = WebSocketChannel.connect(Uri.parse(link));
    subscribe();
  }
}
