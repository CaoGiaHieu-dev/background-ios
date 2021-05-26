import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background/utils/utils.dart';

class AppRetainWidget extends StatelessWidget {
  const AppRetainWidget({
    Key key,
    @required this.child,
  }) : super(key: key);

  final Widget child;

  static const MethodChannel _channel =
      MethodChannel(UtilsBackGroundHanlder.METHOD_CHANNEL);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (Platform.isAndroid) {
          if (Navigator.of(context).canPop()) {
            return true;
          } else {
            _channel.invokeMethod<dynamic>('app_retain');
            return false;
          }
        } else {
          return true;
        }
      },
      child: child,
    );
  }
}
