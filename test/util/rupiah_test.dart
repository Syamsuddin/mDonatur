import 'package:flutter_test/flutter_test.dart';
import 'package:mdonator/util/rupiah.dart';

void main() {
  group('formatRupiah', () {
    const kasus = {
      0: 'Rp 0',
      1: 'Rp 1',
      999: 'Rp 999',
      1000: 'Rp 1.000',
      100000: 'Rp 100.000',
      2147483647: 'Rp 2.147.483.647',
    };
    kasus.forEach((nilai, harapan) {
      test('$nilai → "$harapan"', () => expect(formatRupiah(nilai), harapan));
    });
  });

  test('formatRibuan tanpa "Rp" untuk tombol nominal cepat', () {
    expect(formatRibuan(100000), '100.000');
    expect(formatRibuan(2000000), '2.000.000');
    expect(formatRibuan(50000), '50.000');
  });

  group('bacaAngka hanya menerima digit', () {
    test('digit → bilangan bulat', () {
      expect(bacaAngka('100000'), 100000);
      expect(bacaAngka('7'), 7);
      expect(bacaAngka('007'), 7);
      expect(bacaAngka('2147483647'), 2147483647);
    });

    test('selain digit → null', () {
      for (final teks in ['', ' ', '100.000', '100,000', '1.5', '-5', '+5', ' 5', '5 ', 'abc', '1e5', '٣']) {
        expect(bacaAngka(teks), isNull, reason: '"$teks"');
      }
    });
  });
}
