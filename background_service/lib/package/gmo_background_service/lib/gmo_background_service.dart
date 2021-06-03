import 'dart:async';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'index.dart';

class GmoBackgroundService {
  factory GmoBackgroundService.instance() => _instance;

  GmoBackgroundService._internal();
  static final GmoBackgroundService _instance = GmoBackgroundService._internal()
    .._setupBackground();

  static const MethodChannel _backgroundChannel = MethodChannel(
    UtilsBackground.BG_CHANNEL,
    JSONMethodCodec(),
  );

  static const MethodChannel _mainChannel = MethodChannel(
    UtilsBackground.MAIN_CHANNEL,
    JSONMethodCodec(),
  );

  void _setupMain() {
    _mainChannel.setMethodCallHandler(_handle);
  }

  void _setupBackground() {
    _backgroundChannel.setMethodCallHandler(_handle);
  }

  Future<dynamic> _handle(MethodCall call) async {
    switch (call.method) {
      case UtilsBackground.RECEIVE_DATA:
        _streamController.sink.add(call.arguments as Map<String, dynamic>);
        break;
      default:
    }

    return true;
  }

  void startBackground(Function bgTask) {
    final CallbackHandle handle = PluginUtilities.getCallbackHandle(bgTask)!;

    final GmoBackgroundService service = GmoBackgroundService.instance();
    service._setupMain();

    _mainChannel.invokeMethod<dynamic>(
      UtilsBackground.BACKGROUND_TASK,
      <String, dynamic>{
        'handle': handle.toRawHandle(),
      },
    );
  }

  void sendData(Map<String, dynamic> data) {
    _backgroundChannel.invokeMethod<dynamic>(
      UtilsBackground.SEND_DATA,
      data,
    );
  }

  void cancelBackgroundTask(Function bgTask) {
    final CallbackHandle handle = PluginUtilities.getCallbackHandle(bgTask)!;

    final GmoBackgroundService service = GmoBackgroundService.instance();
    service._setupMain();

    _mainChannel.invokeMethod<dynamic>(
      UtilsBackground.CANCEL,
      <String, dynamic>{
        'handle': handle.toRawHandle(),
      },
    );
    dispose();
  }

  static final StreamController<Map<String, dynamic>> _streamController =
      StreamController<Map<String, dynamic>>.broadcast();

  static Stream<Map<String, dynamic>> get onDataReceived =>
      _streamController.stream;

  void dispose() {
    _streamController.close();
  }
}
