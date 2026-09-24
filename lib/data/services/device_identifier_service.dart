import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';

class DeviceIdentifierService {
  DeviceIdentifierService({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(_channelName);

  static const String _channelName = 'recode_works/device_identifier';
  static const String _androidPrefix = 'android_';

  final MethodChannel _channel;

  Future<String> getDeviceKey() async {
    final androidId = await _channel.invokeMethod<String>('getAndroidId');
    if (androidId == null || androidId.trim().isEmpty) {
      throw StateError('Android 기기 식별자를 읽을 수 없습니다.');
    }
    return hashedAndroidKey(androidId);
  }

  static String hashedAndroidKey(String androidId) {
    final normalized = androidId.trim();
    if (normalized.isEmpty) {
      throw ArgumentError.value(androidId, 'androidId', '비어 있을 수 없습니다.');
    }
    final digest = sha256.convert(utf8.encode(normalized));
    return '$_androidPrefix$digest';
  }
}
