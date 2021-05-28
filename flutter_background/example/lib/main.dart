import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_background/index.dart';
import 'package:flutter_background_example/socket_provider.dart';
import 'package:flutter_background/widget/retain.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

ValueNotifier<int> _count = ValueNotifier<int>(0);
ValueListenable<int> get count => _count;

void startBG() {
  WidgetsFlutterBinding.ensureInitialized();
  SocketProvider.instance().initSocket();
}

void cancelBG() {
  WidgetsFlutterBinding.ensureInitialized();
  SocketProvider.instance().onClose();
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    // SocketProvider.instance().initSocket();
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
                    FlutterBackground().startBackground(startBG);
                    // FlutterBackgroundService.initialize(
                    //   increment,
                    //   autoStart: true,
                    //   foreground: true,
                    // );
                  },
                  child: const Text('BGTask'),
                  color: Colors.amber,
                ),
                MaterialButton(
                  onPressed: () {
                    startBG();
                  },
                  child: const Text('BGTask testing'),
                  color: Colors.amber,
                ),
                MaterialButton(
                  onPressed: () {
                    FlutterBackground().cancelBackgroundTask(
                      cancelBG,
                    );
                  },
                  child: const Text('Cancel BGTask'),
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
