import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_background/index.dart';
import 'package:flutter_background_example/app_retain_widget.dart';
import 'package:flutter_background_example/socket_provider.dart';

void main() {
  runApp(MyApp());
}

ValueNotifier<int> _count = ValueNotifier<int>(0);
ValueListenable<int> get count => _count;
void _increment() {
  SocketProvider.socket.on('time').listen((dynamic event) {
    NotificationService.instance().createNewChannel();
  });
  Stream<dynamic>.periodic(const Duration(seconds: 1)).listen((dynamic _) {
    _count.value++;
  });
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    SocketProvider().onInit();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: AppRetainWidget(
        child: Scaffold(
          appBar: AppBar(
            centerTitle: true,
            title: ValueListenableBuilder<int>(
              valueListenable: count,
              builder: (BuildContext context, int value, Widget child) {
                return Text('$value');
              },
            ),
          ),
          body: Center(
            child: Column(
              children: <Widget>[
                MaterialButton(
                  onPressed: () =>
                      NotificationService.instance().createNewChannel(),
                  child: const Text('Notification'),
                  color: Colors.amber,
                ),
                MaterialButton(
                  onPressed: () {
                    SocketProvider.socket.on('time').listen((dynamic event) {
                      NotificationService.instance().createNewChannel();
                    });
                  },
                  child: const Text('socket connection testing'),
                  color: Colors.amber,
                ),
                MaterialButton(
                  onPressed: () {
                    FlutterBackground().startBackground(_increment);
                  },
                  child: const Text('BGTask'),
                  color: Colors.amber,
                ),
                MaterialButton(
                  onPressed: () {
                    _increment();
                  },
                  child: const Text('BGTask testing'),
                  color: Colors.amber,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
