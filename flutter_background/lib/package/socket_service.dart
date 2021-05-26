import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/services.dart';

import '../index.dart';

class SocketService {
  static void connectChannel(String host, {String query = ''}) {
    try {
      const MethodChannel(UtilsBackGroundHanlder.METHOD_CHANNEL)
          .invokeMethod<dynamic>(
        UtilsBackGroundHanlder.CONNECT_SERVER,
        <String, dynamic>{
          'host': host,
          'data': query,
        } as dynamic,
      );
    } on PlatformException catch (e) {
      developer
          .log("${UtilsBackGroundHanlder.CONNECT_SERVER} : '${e.message}'.");
    }
  }

  static Stream<dynamic> listenToEvent(String eventName) {
    try {
      const EventChannel result =
          EventChannel(UtilsBackGroundHanlder.EVENT_CHANNEL);
      return result.receiveBroadcastStream(eventName);
    } on PlatformException catch (e) {
      developer
          .log("${UtilsBackGroundHanlder.CONNECT_SERVER} : '${e.message}'.");
      return const Stream<dynamic>.empty();
    }
  }
}
