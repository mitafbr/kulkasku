// File ini sengaja dibuat supaya `flutter create` tidak membuat contoh test bawaan.
import 'package:flutter_test/flutter_test.dart';
import 'package:kulkasku/data/logic.dart';

void main() {
  test('format suhu', () {
    expect(formatSuhu(4), '4°C');
    expect(formatSuhu(-18), '−18°C');
  });
}
