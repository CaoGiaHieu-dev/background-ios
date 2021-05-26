import 'dart:developer' as developer;
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter_background/utils/utils.dart';

class FlutterBackground {
  factory FlutterBackground() => _instance;

  FlutterBackground._internal();

  static final FlutterBackground _instance = FlutterBackground._internal();
  void startBackground(Function callback) {
    try {
      final CallbackHandle callbackHandle =
          PluginUtilities.getCallbackHandle(callback);
      developer.log(callbackHandle.toRawHandle().toString());
      const MethodChannel channel =
          MethodChannel(UtilsBackGroundHanlder.METHOD_CHANNEL);
      channel.invokeMethod<dynamic>(
        UtilsBackGroundHanlder.BACKGROUND,
        callbackHandle?.toRawHandle(),
      );
    } on PlatformException catch (e) {
      developer.log("${UtilsBackGroundHanlder.BACKGROUND} : '${e.message}'.");
    }
  }
}
