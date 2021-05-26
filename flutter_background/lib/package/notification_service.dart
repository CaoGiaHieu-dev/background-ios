import 'dart:developer' as developer;

import 'package:flutter/services.dart';

import '../index.dart';

class NotificationService {
  factory NotificationService.instance() => _instance;

  NotificationService._internal();
  static const Map<String, String> channelMap = <String, String>{
    'id': 'CHAT_MESSAGES',
    'name': 'Chats',
    'description': 'Chat notifications',
  };

  static final NotificationService _instance = NotificationService._internal();
  Future<void> createNewChannel() async {
    try {
      final dynamic result =
          await const MethodChannel(UtilsBackGroundHanlder.METHOD_CHANNEL)
              .invokeMethod<dynamic>(
        UtilsBackGroundHanlder.CREATE_NOTIFICATION,
      );
      developer.log(result.toString());
    } on PlatformException catch (e) {
      developer.log("${UtilsBackGroundHanlder.NOTIFICATION} : '${e.message}'.");
    }
  }

  // void notification() {
  //   try {
  //     const MethodChannel(UtilsBackGroundHanlder.METHOD_CHANNEL)
  //         .invokeMethod<dynamic>(
  //       UtilsBackGroundHanlder.NOTIFICATION,
  //       channelMap as dynamic,
  //     );
  //   } on PlatformException catch (e) {
  //     developer.log("${UtilsBackGroundHanlder.NOTIFICATION} : '${e.message}'.");
  //   }
  // }
}
