import 'package:flutter_test/flutter_test.dart';
import 'package:recode_works/data/services/device_identifier_service.dart';

void main() {
  test('ANDROID_ID를 원문이 노출되지 않는 고정 기기 키로 변환한다', () {
    const androidId = 'device-serial-like-id';

    final first = DeviceIdentifierService.hashedAndroidKey(androidId);
    final second = DeviceIdentifierService.hashedAndroidKey(androidId);

    expect(first, second);
    expect(first, startsWith('android_'));
    expect(first, hasLength(72));
    expect(first, isNot(contains(androidId)));
  });
}
