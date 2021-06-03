import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketProvider {
  factory SocketProvider.instance() => _instance;
  SocketProvider._internal();
  static final SocketProvider _instance = SocketProvider._internal();

  static IO.Socket? socket;
  static final StreamController _dataReceive = StreamController<String>();
  static Stream<dynamic> get onDataReceived => _dataReceive.stream;
  Future<void> initSocket(String url) async {
    socket = IO.io(
      url,
      IO.OptionBuilder().setTransports(['websocket']).build(),
    );
    socket?.onConnect((data) => print(data));
    socket?.onError((data) => print('data'));
    socket?.onDisconnect((_) => print('disconnect'));
  }

  void emit(String eventName, String messenger) {
    socket?.onConnect((_) {
      socket?.emit(eventName, messenger);
    });
  }

  void listen(String event) {
    socket?.on(
      event,
      (data) => _dataReceive.sink.add(data),
    );
  }

  void onClose() {
    _dataReceive.close();
    socket?.dispose();
    socket?.close();
  }
}
