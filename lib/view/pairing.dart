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
      print(connector?.isReady);

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
          title: Text("Pairing"),
        ),
        body: Center(
          child: Column(
            children: [
              FlatButton(
                onPressed:
                    UniversalPlatform.isWeb ? null : () => _openDialog(false),
                child: Text("Become host"),
              ),
              FlatButton(
                onPressed: () => _openDialog(true),
                child: Text("Become client"),
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
  bool _isReady;

  _reload() {
    setState(() {
      _isReady = _connector.isReady;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Scaffold(
        body: _isReady
            ? FlatButton(
                onPressed: _reload(),
                child: Text("Reload"),
              )
            : Center(
                child: Column(
                  children: [
                    QrImage(data: _connector.address, size: 200),
                    Text(_connector.address),
                    FlatButton(
                      onPressed: () =>
                          Navigator.pop<Connector>(context, _connector),
                      child: Text("Ready !"),
                    )
                  ],
                ),
              ),
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
  TextEditingController _controller;

  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Scaffold(
        body: Center(
          child: Column(
            children: [
              TextField(
                maxLines: 1,
                onSubmitted: (String value) async {
                  Navigator.pop<Connector>(context, PassiveConnector(value));
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}
