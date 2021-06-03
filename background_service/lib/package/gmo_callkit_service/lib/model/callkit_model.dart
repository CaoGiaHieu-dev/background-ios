enum CallStateType {
  idle,
  calling,
  notthing,
}

extension CallStateTypeEx on CallStateType {
  static CallStateType create(int value) {
    switch (value) {
      case 0:
        return CallStateType.idle;
      case 1:
        return CallStateType.calling;
      default:
        return CallStateType.notthing;
    }
  }

  String get value {
    switch (this) {
      case CallStateType.idle:
        return 'idle';
      case CallStateType.calling:
        return 'calling';
      case CallStateType.notthing:
        return '';
    }
  }
}

class CallModel {
  CallModel.fromJson(Map<String, dynamic> json)
      : uuid = json['uuid'],
        callId = json['callId'],
        callerId = json['callerId'],
        callerName = json['callerName'],
        callerImage = json['callerImage'];

  final String uuid;
  final int callId;
  final String callerId;
  final String callerName;
  final String callerImage;

  Map<String, dynamic> toJson() => {
        'uuid': uuid,
        'callId': callId,
        'callerId': callerId,
        'callerName': callerName,
        'callerImage': callerImage,
      };
}
