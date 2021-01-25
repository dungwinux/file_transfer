import 'dart:async';

import 'package:file_transfer/control/connection.dart';
import 'package:file_transfer/view/transfer.dart';
import 'package:flutter/material.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:qr_flutter/qr_flutter.dart';

class Pairing extends StatelessWidget {
  const Pairing({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    void _openDialog([bool isPassive = true]) async {
      var connector = await showDialog<Connector>(
        context: context,
        builder: (context) => isPassive ? PassivePairing() : ActivePairing(),
      );
      if (connector != null)
        Navigator.of(context).push(
          MaterialPageRoute(
              builder: (context) => TransferPage(
                    connector: connector,
                    title: "Transfer list",
                  )),
        );
    }

    return Container(
      child: Scaffold(
        appBar: AppBar(
          title: Text("Welcome to File Transfer"),
          centerTitle: true,
        ),
        body: Container(
          padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width * 0.35,
          ),
          child: Flex(
            direction: Axis.vertical,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Tooltip(
                message: "Create a connection",
                waitDuration: Duration(milliseconds: 700),
                child: ElevatedButton.icon(
                  onPressed:
                      UniversalPlatform.isWeb ? null : () => _openDialog(false),
                  label: Text("Initiate"),
                  icon: Icon(Icons.cast),
                ),
              ),
              Tooltip(
                message: "Connect to other",
                waitDuration: Duration(milliseconds: 700),
                child: ElevatedButton.icon(
                  onPressed: () => _openDialog(true),
                  label: Text("Connect"),
                  icon: Icon(Icons.connect_without_contact),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ActivePairing extends StatefulWidget {
  ActivePairing({Key key}) : super(key: key);

  @override
  _ActivePairingState createState() => _ActivePairingState();
}

class _ActivePairingState extends State<ActivePairing> {
  ActiveConnector _connector = ActiveConnector();
  bool _isReady = false;
  Timer _update;

  _reload() {
    setState(() {
      _isReady = _connector.isReady;
      if (_isReady) _update.cancel();
    });
  }

  @override
  void initState() {
    super.initState();
    _update = Timer.periodic(Duration(microseconds: 500), (timer) {
      _reload();
    });
  }

  @override
  void dispose() {
    _update.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Scaffold(
        body: _isReady
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    QrImage(data: _connector.address, size: 200),
                    Text(_connector.address),
                    TextButton(
                      onPressed: () =>
                          Navigator.pop<Connector>(context, _connector),
                      child: Text("Ready !"),
                    )
                  ],
                ),
              )
            : CircularProgressIndicator(),
      ),
    );
  }
}

class PassivePairing extends StatefulWidget {
  PassivePairing({Key key}) : super(key: key);

  @override
  _PassivePairingState createState() => _PassivePairingState();
}

class _PassivePairingState extends State<PassivePairing> {
  TextEditingController _controller = TextEditingController();

  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit(String value) async {
    // TODO: Check for valid address
    Navigator.pop<Connector>(context, PassiveConnector(value));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                decoration: InputDecoration(
                  labelText: 'Peer address',
                  suffixIcon: IconButton(
                    icon: Icon(
                      Icons.qr_code,
                    ),
                    onPressed: () => null,
                  ),
                ),
                maxLines: 1,
                onSubmitted: _submit,
                controller: _controller,
              ),
              TextButton(
                onPressed: () => _submit(_controller.text),
                child: Text("Submit"),
              )
            ],
          ),
        ),
      ),
    );
  }
}
