import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:file_transfer/control/connection.dart';

void main() async {
  // Setup ws server
  var handler = ActiveConnector();
  var _ = PassiveConnector("ws://localhost:1234");

  var fileList = [File("a.txt", Uint8List.fromList("Hello".codeUnits))];

  test("Send list", () async {
    handler.sendList(fileList);
    await Future.delayed(Duration(milliseconds: 100));
    expect(_.receiveList, fileList.cast<FileView>());
  });

  test("Send file", () async {
    handler.sendList(fileList);
    await Future.delayed(Duration(milliseconds: 100));
    await _.requestFile(_.receiveList.first, "test");
    await Future.delayed(Duration(milliseconds: 200));
    var received = XFile("test/a.txt");
    expect(fileList.first.data, await received.readAsBytes());
  });
  // TODO: add more test cases
}
