import 'dart:developer' as developer;

import 'package:flutter/services.dart';

import '../index.dart';

class NotificationService {
  factory NotificationService.instance() => _instance;

  NotificationService._internal();
  static final NotificationService _instance = NotificationService._internal();

  static const MethodChannel channel = MethodChannel(
    UtilsBackground.MAIN_CHANNEL,
    JSONMethodCodec(),
  );

  Future<void> createNewChannel() async {
    try {
      channel.invokeMethod<dynamic>(
        UtilsBackground.CREATE_NOTIFICATION,
      );
      developer.log(channel.toString());
    } on PlatformException catch (e) {
      developer.log("${UtilsBackground.CREATE_NOTIFICATION} : '${e.message}'.");
    }
  }
}
