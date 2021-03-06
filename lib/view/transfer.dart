import 'dart:async';

import 'package:flutter/material.dart';
import 'package:file_picker_cross/file_picker_cross.dart';
import 'package:file_transfer/control/connection.dart';

class TransferPage extends StatefulWidget {
  TransferPage({Key key, this.title, this.connector}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;
  final Connector connector;

  @override
  _TransferPageState createState() => _TransferPageState();
}

class _TransferPageState extends State<TransferPage> {
  int currentTab = 1;
  List<FileView> receive = [];
  List<FileView> broadcast = [];
  bool isReady = true;
  Timer _updateReceive;

  void _selectFile() async {
    try {
      final files = await FilePickerCross.importMultipleFromStorage();
      widget.connector.sendList(files
          .map((file) => File(file.fileName, file.toUint8List()))
          .toList());
    } catch (e) {}
    await Future.delayed(Duration(milliseconds: 500));
    setState(() {
      broadcast = widget.connector.fileList;
    });
  }

  @override
  void initState() {
    super.initState();
    _updateReceive = Timer.periodic(Duration(seconds: 2), (timer) {
      setState(() {
        receive = widget.connector.receiveList;
        isReady = widget.connector.isReady;
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    _updateReceive.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Builder(builder: (BuildContext context) {
        final TabController tabController = DefaultTabController.of(context);
        tabController.addListener(() {
          if (tabController.indexIsChanging) {
            // Bad practice
            // TODO: actually changing a certain state
            setState(() {});
          }
        });
        return Scaffold(
          appBar: AppBar(
            title: Text(widget.title),
            centerTitle: true,
            actions: [
              Container(
                child: Tooltip(
                  message: widget.connector.address,
                  child: Text('Online: $isReady'),
                ),
                alignment: Alignment.center,
                margin: EdgeInsets.all(5),
              ),
            ],
            bottom: TabBar(
              tabs: [
                Tab(child: Text('Send')),
                Tab(child: Text('Receive')),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              ListView.builder(
                itemCount: broadcast.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text('${broadcast[index]}'),
                  );
                },
              ),
              ListView.builder(
                itemCount: receive.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text('${receive[index]}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.download_rounded),
                          onPressed: () =>
                              widget.connector.requestFile(receive[index]),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          floatingActionButton: (DefaultTabController.of(context).index == 0)
              ? FloatingActionButton(
                  onPressed: _selectFile,
                  tooltip: 'Add',
                  child: Icon(Icons.add),
                )
              : null,
        );
      }),
    );
  }
}
