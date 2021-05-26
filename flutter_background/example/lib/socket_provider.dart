import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:adhara_socket_io/adhara_socket_io.dart';

class SocketProvider {
  factory SocketProvider() {
    return _instance;
  }

  SocketProvider._internal();

  static final SocketProvider _instance = SocketProvider._internal();

  static SocketIO socket;
  static SocketIOManager manager;

  Future<void> _initSocket() async {
    socket = await SocketIOManager().createInstance(
      SocketOptions(
        'https://nodejs-socket-agrich.herokuapp.com/',
        enableLogging: false,
        transports: <Transports>[
          Transports.webSocket,
        ],
      ),
    );

    socket.onConnectError.listen(pPrint);
    socket.onConnectTimeout.listen(pPrint);
    socket.onError.listen(pPrint);
    socket.onDisconnect.listen(pPrint);
    await socket.connect();
  }

  void pPrint(Object data) {
    if (data is Map) {
      data = json.encode(data);
    }
    developer.log(data.toString());
  }

  void onClose() {
    manager.clearInstance(socket);
  }

  void onInit() {
    manager = SocketIOManager();
    _initSocket();
  }
}
