import 'package:flutter_test/flutter_test.dart';
import 'package:mdonator/util/tanggal.dart';

void main() {
  group('formatTanggal', () {
    test('"Minggu, 11/10/2026" dan "Senin, 12/10/2026"', () {
      expect(formatTanggal(DateTime.utc(2026, 10, 11)), 'Minggu, 11/10/2026');
      expect(formatTanggal(DateTime.utc(2026, 10, 12)), 'Senin, 12/10/2026');
    });

    test('hari dan bulan satu digit diberi nol di depan', () {
      expect(formatTanggal(DateTime.utc(2027, 1, 4)), 'Senin, 04/01/2027');
    });
  });

  test('namaHari Senin sampai Minggu', () {
    const harapan = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    for (var i = 0; i < 7; i++) {
      // 5 Oktober 2026 adalah Senin (contoh rentang pekan di API_CONTRACT.md §6.9).
      expect(namaHari(DateTime.utc(2026, 10, 5 + i)), harapan[i]);
    }
  });

  test('teks rentang pekan', () {
    expect(
      formatRentang(DateTime.utc(2026, 10, 5), DateTime.utc(2026, 10, 11)),
      'Senin, 05/10/2026 – Minggu, 11/10/2026',
    );
  });

  test('formatBulan', () {
    expect(formatBulan(DateTime.utc(2026, 10, 1)), 'Oktober 2026');
    expect(formatBulan(DateTime.utc(2027, 1, 31)), 'Januari 2027');
    expect(formatBulan(DateTime.utc(2026, 12, 1)), 'Desember 2026');
  });

  test('formatJam memotong detik tanpa mengubah jam (K1)', () {
    expect(formatJam('09:15:02'), '09:15');
    expect(formatJam('23:59:59'), '23:59');
  });

  group('bacaTanggal dan tulisTanggal', () {
    test('format kontrak "YYYY-MM-DD" bolak-balik', () {
      final tanggal = bacaTanggal('2026-01-05');
      expect(tanggal, DateTime.utc(2026, 1, 5));
      expect(tanggal.isUtc, isTrue);
      expect(tulisTanggal(tanggal), '2026-01-05');
    });

    test('tanggal tidak sah ditolak', () {
      for (final teks in ['2026-02-30', '2026-13-01', '12/10/2026', '2026-1-5', '', '2026-10-12T00:00:00']) {
        expect(() => bacaTanggal(teks), throwsFormatException, reason: '"$teks"');
      }
    });
  });
}
