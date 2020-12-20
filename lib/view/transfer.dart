import 'package:flutter/material.dart';
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
  void _incrementCounter() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    var receive = widget.connector.receiveList;
    var broadcast = widget.connector.fileList;
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
                  );
                },
              ),
            ],
          ),
          floatingActionButton: (DefaultTabController.of(context).index == 0)
              ? FloatingActionButton(
                  onPressed: _incrementCounter,
                  tooltip: 'Add',
                  child: Icon(Icons.add),
                )
              : null,
        );
      }),
    );
  }
}
