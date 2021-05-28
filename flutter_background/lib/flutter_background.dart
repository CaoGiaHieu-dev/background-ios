import 'dart:developer' as developer;
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter_background/utils/utils.dart';

class FlutterBackground {
  factory FlutterBackground() => _instance;

  FlutterBackground._internal();

  static final FlutterBackground _instance = FlutterBackground._internal();
  void startBackground(
    Function callback, {
    bool onBackgrond = true,
    bool onForeground = true,
  }) {
    try {
      final CallbackHandle callbackHandle =
          PluginUtilities.getCallbackHandle(callback);
      const MethodChannel channel =
          MethodChannel(UtilsBackGroundHanlder.METHOD_CHANNEL);
      channel.invokeMethod<dynamic>(
        UtilsBackGroundHanlder.BACKGROUND,
        <String, dynamic>{
          'handle': callbackHandle?.toRawHandle(),
          'onBackground': onBackgrond,
          'onForeground': onForeground,
          'onCancel': false
        },
      );
    } on PlatformException catch (e) {
      developer.log("${UtilsBackGroundHanlder.BACKGROUND} : '${e.message}'.");
    }
  }

  void cancelBackgroundTask(Function dispose, {bool onCancel = true}) {
    try {
      final CallbackHandle callbackHandle =
          PluginUtilities.getCallbackHandle(dispose);
      const MethodChannel channel =
          MethodChannel(UtilsBackGroundHanlder.METHOD_CHANNEL);
      channel.invokeMethod<dynamic>(
        UtilsBackGroundHanlder.BACKGROUND,
        <String, dynamic>{
          'handle': callbackHandle.toRawHandle(),
          'onBackground': false,
          'onForeground': false,
          'onCancel': onCancel
        },
      );
    } on PlatformException catch (e) {
      developer.log("${UtilsBackGroundHanlder.BACKGROUND} : '${e.message}'.");
    }
  }
}
