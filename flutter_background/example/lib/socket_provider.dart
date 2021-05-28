import 'dart:async';
import 'package:adhara_socket_io/adhara_socket_io.dart';
import 'package:flutter_background/index.dart';

class SocketProvider {
  factory SocketProvider.instance() => _instance;
  SocketProvider._internal();
  static final SocketProvider _instance = SocketProvider._internal();

  static SocketIO socket;

  Future<void> initSocket() async {
    socket = socket ??
        await SocketIOManager().createInstance(
          SocketOptions(
            'https://nodejs-socket-agrich.herokuapp.com/',
            enableLogging: false,
            transports: <Transports>[
              Transports.webSocket,
            ],
          ),
        );

    await socket.connect();
    socket.on('time').listen((dynamic event) {
      NotificationService.instance().createNewChannel();
    });
  }

  Future<void> onClose() async {
    await SocketIOManager().clearInstance(socket);
  }
}
