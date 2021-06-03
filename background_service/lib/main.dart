import 'package:background_service/package/gmo_background_service/lib/gmo_background_service.dart';
import 'package:background_service/package/gmo_callkit_service/lib/gmo_callkit_service.dart';
import 'package:background_service/socket_provider.dart';
import 'package:device_info/device_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'package/gmo_background_service/lib/index.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

Future<void> startBG() async {
  WidgetsFlutterBinding.ensureInitialized();

  final DeviceInfoPlugin deviceInfoPlugin = new DeviceInfoPlugin();
  var data = await deviceInfoPlugin.iosInfo;
  String identifier = data.identifierForVendor;
  await SocketProvider.instance()
      .initSocket('https://nodejsbun.herokuapp.com/');
  SocketProvider.instance().emit('join', identifier);
  SocketProvider.instance().listen('call');
  SocketProvider.onDataReceived.listen(
    (dynamic event) {
      GmoBackgroundService.instance().sendData(
        <String, dynamic>{'call': event},
      );
      GmoCallKitService.instance().getIncomingCallerName();
      // NotificationService.instance().createNewChannel();
    },
  );
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
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: AppRetainWidget(
        child: Scaffold(
          appBar: AppBar(
            centerTitle: true,
            title: StreamBuilder<Map<String, dynamic>>(
              stream: GmoBackgroundService.onDataReceived,
              builder: (BuildContext context,
                  AsyncSnapshot<Map<String, dynamic>> snapshot) {
                if (snapshot.hasData) {
                  return Text(
                    snapshot.data!['call'].toString(),
                    maxLines: 2,
                    textAlign: TextAlign.center,
                  );
                } else {
                  return const Text('Timer loading ...');
                }
              },
            ),
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                MaterialButton(
                  onPressed: () {
                    GmoBackgroundService.instance().startBackground(
                      startBG,
                    );
                  },
                  child: const Text('BGTask'),
                  color: Colors.amber,
                ),
                MaterialButton(
                  onPressed: () {
                    GmoBackgroundService.instance().cancelBackgroundTask(
                      cancelBG,
                    );
                  },
                  child: const Text('Cancel BGTask'),
                  color: Colors.amber,
                ),
                MaterialButton(
                  onPressed: () {
                    GmoCallKitService.instance().setConfig();
                  },
                  child: const Text('Setting call'),
                  color: Colors.amber,
                ),
                MaterialButton(
                  onPressed: () {
                    GmoCallKitService.instance().startCall(
                      uuid: '00000000-0000-0000-0000-000000000000',
                      targetName: 'targetName',
                      hasVideo: false,
                    );
                  },
                  child: const Text('Call'),
                  color: Colors.amber,
                ),
                MaterialButton(
                  onPressed: () {
                    GmoCallKitService.instance().endCall();
                  },
                  child: const Text('End Call'),
                  color: Colors.amber,
                ),
                MaterialButton(
                  onPressed: () {
                    GmoCallKitService.instance().testIncomingCall(
                      uuid: '00000000-0000-0000-0000-000000000000',
                      callerId: '00000000-0000-0000-0000-000000000000',
                      callerName: 'unknow',
                    );
                  },
                  child: const Text('test incomming Call'),
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
