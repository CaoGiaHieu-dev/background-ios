import 'dart:async';

import 'package:flutter/services.dart';
import './index.dart';

import 'model/callkit_model.dart';

class GmoCallKitService {
  factory GmoCallKitService.instance() => _instance;

  GmoCallKitService._internal() {
    _eventSubscription = _eventChannel.receiveBroadcastStream().listen(
          _eventListener,
          onError: _errorListener,
        );
  }
  static final GmoCallKitService _instance = GmoCallKitService._internal();

  static MethodChannel _callChannel = MethodChannel(
    UtilsCallKit.CALL_CHANNEL,
  );

  static EventChannel _eventChannel = EventChannel(
    UtilsCallKit.CALL_CHANNEL_EVENT,
  );
  IncomingAction? onDidReceiveIncomingPush;
  IncomingAction? onDidAcceptIncomingCall;
  IncomingAction? onDidRejectIncomingCall;
  OnUpdatePushToken? onDidUpdatePushToken;
  OnAudioSessionStateChanged? onAudioSessionStateChanged;
  Function? onOtherUserDidJoinRoom;
  IncomingAction? onDidEndCall;
  StreamSubscription<dynamic>? _eventSubscription;

  Future setConfig({
    String? authToken,
    String? serverUrl,
    int? ringingTimeout,
    String? ringtoneSound,
  }) async {
    return await _callChannel.invokeMethod('setConfig', <String, dynamic>{
      if (serverUrl != null) 'graphql_url': serverUrl,
      if (ringingTimeout != null) 'ringing_timeout': ringingTimeout,
      if (ringtoneSound != null) 'ringtoneSound': ringtoneSound,
    });
  }

  Future<String> getVoIPToken() async {
    return await _callChannel.invokeMethod('getVoIPToken');
  }

  Future<String> getIncomingCallerName() async {
    return await _callChannel.invokeMethod('getIncomingCallerName') ?? 'unknow';
  }

  Future<void> startCall({
    required String uuid,
    required String targetName,
    bool? hasVideo,
  }) async {
    return await _callChannel.invokeMethod('startCall', {
      'uuid': uuid,
      'targetName': targetName,
      'hasVideo': hasVideo,
    });
  }

  Future<void> endCall() async {
    return await _callChannel.invokeMethod('endCall');
  }

  Future<void> acceptIncomingCall({
    required CallStateType callerState,
  }) async {
    return await _callChannel.invokeMethod('acceptIncomingCall', {
      'callerState': callerState.value,
    });
  }

  Future<void> unansweredIncomingCall({
    bool skipLocalNotification = false,
    required String missedCallTitle,
    required String missedCallBody,
  }) async {
    return await _callChannel.invokeMethod('unansweredIncomingCall', {
      'skipLocalNotification': skipLocalNotification,
      'missedCallTitle': missedCallTitle,
      'missedCallBody': missedCallBody,
    });
  }

  Future<void> testIncomingCall({
    required String uuid,
    required String callerId,
    required String callerName,
  }) async {
    return await _callChannel.invokeMethod('testIncomingCall', {
      'uuid': uuid,
      'callerId': callerId,
      'callerName': callerName,
    });
  }

  Future<void> callConnected() async {
    return await _callChannel.invokeMethod('callConnected');
  }

  Future<void> enableVideo() async {
    await _callChannel.invokeMethod('enableVideo');
  }

  Future<void> enableAudio() async {
    await _callChannel.invokeMethod('enableAudio');
  }

  void _eventListener(dynamic event) {
    try {
      final Map<dynamic, dynamic> map = event;
      switch (map['event']) {
        case 'onDidReceiveIncomingPush':
          if (map['call'] is Map) {
            final call = CallModel.fromJson(
                Map<String, dynamic>.from(map['call'] as Map));
            onDidReceiveIncomingPush?.call(call);
          }
          break;
        case 'onDidAcceptIncomingCall':
          if (map['call'] is Map) {
            final call = CallModel.fromJson(
                Map<String, dynamic>.from(map['call'] as Map));
            onDidAcceptIncomingCall?.call(call);
          }
          break;
        case 'onDidRejectIncomingCall':
          if (map['call'] is Map) {
            final call = CallModel.fromJson(
                Map<String, dynamic>.from(map['call'] as Map));
            onDidRejectIncomingCall?.call(call);
          }
          break;
        case 'onDidActivateAudioSession':
          onAudioSessionStateChanged?.call(true);
          break;
        case 'onDidDeactivateAudioSession':
          onAudioSessionStateChanged?.call(false);
          break;
        case 'onDidEndCall':
          if (map['call'] is Map) {
            final call = CallModel.fromJson(
                Map<String, dynamic>.from(map['call'] as Map));
            onDidEndCall?.call(call);
          }
          break;
        default:
          print('Unknown event: ${map['event']}');
          break;
      }
    } catch (e) {
      print(e);
    }
  }

  void _errorListener(Object obj) {
    print('🎈 onError: $obj');
  }

  Future<void> dispose() async {
    await _eventSubscription?.cancel();
  }
}

typedef IncomingAction = void Function(CallModel call);
typedef OnUpdatePushToken = void Function(String token);
typedef OnAudioSessionStateChanged = void Function(bool active);
