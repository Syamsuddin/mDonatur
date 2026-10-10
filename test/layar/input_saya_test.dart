// Kriteria F6 (docs/23_ACCEPTANCE_CRITERIA.md), alur P4 (docs/06_BUSINESS_PROCESS.md), tempat tampil
// galat (docs/14_ERROR_HANDLING.md), dan empat state Input Saya (docs/26_UI_CONVENTIONS.md).

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mdonator/layar/masuk.dart';
import 'package:mdonator/state/sesi.dart';
import 'package:mdonator/tema.dart';
import 'package:mdonator/widget/kerangka_memuat.dart';
import 'package:mdonator/widget/latar_dasbor.dart';
import 'package:mdonator/widget/panel_galat.dart';

import 'bantu.dart';

const _judulBaris = '7759 · Fulan bin Fulan';
const _pesanK6 = 'Operator hanya dapat mengubah atau menghapus sumbangan yang ia input sendiri pada hari ini.';

Finder get _lembar => find.byType(BottomSheet);

Finder _diLembar(String teks) => find.descendant(of: _lembar, matching: find.text(teks));

Finder _diDialog(String teks) => find.descendant(of: find.byType(AlertDialog), matching: find.text(teks));

Finder _baris(String judul) => find.ancestor(of: find.text(judul), matching: find.byType(ListTile));

Map<String, Object?> _isiJson(http.Request r) => jsonDecode(r.body) as Map<String, Object?>;

bool _simpanAktif(WidgetTester tester) =>
    tester.widget<FilledButton>(tombol<FilledButton>('Simpan')).onPressed != null;

/// Isi pilihan tanggal (InputDecorator berlabel "Tanggal").
Finder get _pilihanTanggal => find.ancestor(of: find.text('Tanggal'), matching: find.byType(InputDecorator));

String? _galatTanggal(WidgetTester tester) => tester.widget<InputDecorator>(_pilihanTanggal).decoration.errorText;

/// Jawaban `donasisaya` menurut parameter `tanggal`: tanpa tanggal = hari ini (2026-10-12).
Penangan _donasiSaya({
  int total = 100000,
  int transaksi = 1,
  List<Map<String, Object?>>? daftar,
}) =>
    (r) async => jawabOk(donasiSayaUji(
          tanggal: r.url.queryParameters['tanggal'] ?? '2026-10-12',
          total: total,
          transaksi: transaksi,
          daftar: daftar ?? [barisDonasiSayaUji()],
        ));

Future<void> _bukaUbah(WidgetTester tester, [String judul = _judulBaris]) => ketuk(tester, find.text(judul));

Future<void> _ubahJumlah(WidgetTester tester, String jumlah) async {
  await tester.enterText(isian('Sumbangan'), jumlah);
  await tester.pump();
}

/// Tombol OKE date picker menurut lokalisasi aplikasi (id_ID).
Future<void> _okeDatePicker(WidgetTester tester) async {
  final dialog = find.byType(DatePickerDialog);
  final oke = MaterialLocalizations.of(tester.element(dialog)).okButtonLabel;
  await tester.tap(find.descendant(of: dialog, matching: find.text(oke)));
  await tester.pumpAndSettle();
}

void main() {
  group('daftar', () {
    testWidgets('saat tab dibuka: donasisaya tanpa tanggal; total, transaksi, dan daftar tampil', (tester) async {
      final server = serverInputSaya();
      server.penangan['donasisaya'] = _donasiSaya(total: 1550000, transaksi: 10);
      await pompaInput(tester, server);
      // Tab Input Saya belum dibuka: hanya strip tab Input yang memanggil donasisaya.
      expect(server.aksi, ['konfigurasi', 'donasisaya']);

      await pilihTab(tester, 'Input Saya');
      expect(judulAppBar(tester), 'Input Saya');
      final saya = kirimanKe(server, 'donasisaya');
      expect(saya, hasLength(2));
      expect(saya[1].url.queryParameters.containsKey('tanggal'), isFalse);

      expect(find.text('Senin, 12/10/2026'), findsOneWidget);
      expect(find.text('Total 10 transaksi'), findsOneWidget);
      expect(find.text('Rp 1.550.000'), findsOneWidget);
      final baris = _baris(_judulBaris);
      expect(baris, findsOneWidget);
      for (final teks in ['09:20', 'Rp 100.000']) {
        expect(find.descendant(of: baris, matching: find.text(teks)), findsOneWidget, reason: teks);
      }
      expect(find.descendant(of: baris, matching: find.byIcon(Icons.edit)), findsOneWidget);
    });

    testWidgets('tab dibuka lagi → dimuat ulang; tarik ke bawah → dimuat ulang', (tester) async {
      final server = serverInputSaya();
      await pompaTabInputSaya(tester, server);
      expect(kirimanKe(server, 'donasisaya'), hasLength(2));

      await pilihTab(tester, 'Input');
      await pilihTab(tester, 'Input Saya');
      expect(kirimanKe(server, 'donasisaya'), hasLength(3));

      server.penangan['donasisaya'] = _donasiSaya(
        total: 300000,
        transaksi: 2,
        daftar: [barisDonasiSayaUji(id: 145439, waktu: '10:01:00', jumlah: 200000), barisDonasiSayaUji()],
      );
      await tester.fling(find.text(_judulBaris), const Offset(0, 800), 1000);
      await tester.pump();
      // Selesaikan animasi gulir, lalu animasi indikator menetap dan menghilang.
      for (var i = 0; i < 3; i++) {
        await tester.pump(const Duration(seconds: 1));
      }
      await tester.pumpAndSettle();
      final saya = kirimanKe(server, 'donasisaya');
      expect(saya, hasLength(4));
      expect(saya.last.url.queryParameters.containsKey('tanggal'), isFalse);
      expect(find.text('Total 2 transaksi'), findsOneWidget);
      // Tanggal dan ringkasan di kepala dasbor, baris sumbangan di dalam kartu.
      final kepala = find.byWidgetPredicate((w) => w is LatarDasbor && w.kepala != null);
      expect(find.descendant(of: kepala, matching: find.text('Total 2 transaksi')), findsOneWidget);
      expect(find.descendant(of: kepala, matching: find.byIcon(Icons.calendar_month)), findsOneWidget);
      expect(find.ancestor(of: find.text('10:01'), matching: find.byType(Card)), findsOneWidget);
      expect(find.text('10:01'), findsOneWidget);
    });

    testWidgets('memuat → kerangka daftar; galat jaringan → panel Coba lagi → daftar', (tester) async {
      final server = serverInputSaya();
      await pompaInput(tester, server);
      final tahan = Completer<http.Response>();
      server.penangan['donasisaya'] = (r) => tahan.future;
      await pilihTab(tester, 'Input Saya');
      expect(find.byType(KerangkaMemuat), findsOneWidget);
      expect(find.text('Senin, 12/10/2026'), findsOneWidget);

      tahan.completeError(http.ClientException('putus'));
      await tester.pumpAndSettle();
      expect(find.byType(KerangkaMemuat), findsNothing);
      expect(find.text(TeksGalat.jaringanGet), findsOneWidget);

      server.penangan['donasisaya'] = _donasiSaya();
      await ketuk(tester, tombol<OutlinedButton>('Coba lagi'));
      expect(find.text(TeksGalat.jaringanGet), findsNothing);
      expect(find.text(_judulBaris), findsOneWidget);
    });

    testWidgets('500 → pesan umum + Coba lagi', (tester) async {
      final server = serverInputSaya();
      await pompaInput(tester, server);
      server.penangan['donasisaya'] = (r) async => jawabGalat(500, 'galat_server', 'Terjadi galat di server.');
      await pilihTab(tester, 'Input Saya');
      expect(find.text(TeksGalat.umum), findsOneWidget);
      expect(tombol<OutlinedButton>('Coba lagi'), findsOneWidget);
    });

    testWidgets('daftar kosong → "Belum ada input pada tanggal ini"', (tester) async {
      final server = serverInputSaya();
      server.penangan['donasisaya'] = _donasiSaya(total: 0, transaksi: 0, daftar: []);
      await pompaTabInputSaya(tester, server);
      expect(find.text('Belum ada input pada tanggal ini'), findsOneWidget);
      expect(find.byType(ListTile), findsNothing);
    });

    testWidgets('boleh_ubah false: tidak bisa diketuk dan tanpa ikon ubah; tidak ada aksi hapus', (tester) async {
      final server = serverInputSaya();
      server.penangan['donasisaya'] = _donasiSaya(daftar: [
        barisDonasiSayaUji(),
        barisDonasiSayaUji(id: 145400, waktu: '08:00:00', idDonatur: 1234, bolehUbah: false),
      ]);
      await pompaTabInputSaya(tester, server);

      final terkunci = _baris('1234 · Fulan bin Fulan');
      expect(tester.widget<ListTile>(terkunci).onTap, isNull);
      expect(find.descendant(of: terkunci, matching: find.byIcon(Icons.edit)), findsNothing);
      expect(find.byIcon(Icons.edit), findsOneWidget);

      await tester.tap(find.text('1234 · Fulan bin Fulan'));
      await tester.pumpAndSettle();
      expect(_lembar, findsNothing);

      await _bukaUbah(tester);
      expect(_lembar, findsOneWidget);
      for (final hapus in [find.textContaining('Hapus'), find.textContaining('hapus'), find.byIcon(Icons.delete)]) {
        expect(hapus, findsNothing);
      }
    });

    testWidgets('nama_donatur null → "(donatur terhapus)"; note_n → jam tebal (admin)', (tester) async {
      final server = serverInputSaya();
      server.penangan['konfigurasi'] = (r) async => jawabOk(konfigurasiUji(username: 'uji_admin', peran: 'admin'));
      server.penangan['donasisaya'] = _donasiSaya(daftar: [
        barisDonasiSayaUji(),
        barisDonasiSayaUji(id: 145401, waktu: '08:30:00', idDonatur: 4321, namaDonatur: null, noteN: false),
        barisDonasiSayaUji(id: 145402, waktu: '07:45:00', idDonatur: 5555, noteN: true),
      ]);
      await pompaTabInputSaya(tester, server);

      expect(find.text('4321 · (donatur terhapus)'), findsOneWidget);
      expect(tester.widget<Text>(find.text('07:45')).style?.fontWeight, FontWeight.w700);
      for (final jam in ['09:20', '08:30']) {
        expect(tester.widget<Text>(find.text(jam)).style?.fontWeight, FontWeight.w400, reason: jam);
      }
      expect(find.textContaining('Note'), findsNothing);
    });

    testWidgets('date picker: setelah hari_ini tidak bisa dipilih; kemarin → tanggal=; hari ini → tanpa tanggal', (tester) async {
      final server = serverInputSaya();
      server.penangan['donasisaya'] = _donasiSaya(total: 1550000, transaksi: 10);
      await pompaTabInputSaya(tester, server);

      await ketuk(tester, _pilihanTanggal);
      final dialog = tester.widget<DatePickerDialog>(find.byType(DatePickerDialog));
      expect([dialog.lastDate.year, dialog.lastDate.month, dialog.lastDate.day], [2026, 10, 12]);
      expect([dialog.firstDate.year, dialog.firstDate.month, dialog.firstDate.day], [2000, 1, 1]);

      // 13 Oktober nonaktif: pilihan tetap 12 (hari_ini), sehingga dikirim tanpa tanggal.
      await tester.tap(find.text('13'));
      await tester.pump();
      await _okeDatePicker(tester);
      expect(kirimanKe(server, 'donasisaya').last.url.queryParameters.containsKey('tanggal'), isFalse);
      expect(find.text('Senin, 12/10/2026'), findsOneWidget);

      server.penangan['donasisaya'] = _donasiSaya(total: 999, transaksi: 1, daftar: [
        barisDonasiSayaUji(id: 145000, waktu: '16:00:00', jumlah: 999, bolehUbah: false),
      ]);
      await ketuk(tester, _pilihanTanggal);
      await tester.tap(find.text('11'));
      await tester.pump();
      await _okeDatePicker(tester);
      expect(kirimanKe(server, 'donasisaya').last.url.queryParameters['tanggal'], '2026-10-11');
      expect(find.text('Minggu, 11/10/2026'), findsOneWidget);
      expect(find.text('16:00'), findsOneWidget);

      // Strip tab Input tetap hari ini; data tanggal lain tidak diteruskan ke sana.
      await pilihTab(tester, 'Input');
      expect(ringkasanHariIni(tester), ('Rp 1.550.000', '10 transaksi'));

      // Tanggal pilihan tetap saat tab dibuka lagi.
      await pilihTab(tester, 'Input Saya');
      expect(kirimanKe(server, 'donasisaya').last.url.queryParameters['tanggal'], '2026-10-11');
      expect(find.text('Minggu, 11/10/2026'), findsOneWidget);

      server.penangan['donasisaya'] = _donasiSaya();
      await ketuk(tester, _pilihanTanggal);
      await tester.tap(find.text('12'));
      await tester.pump();
      await _okeDatePicker(tester);
      expect(kirimanKe(server, 'donasisaya').last.url.queryParameters.containsKey('tanggal'), isFalse);
      expect(find.text('Senin, 12/10/2026'), findsOneWidget);
    });

    testWidgets('422 rincian.tanggal → errorText pilihan tanggal', (tester) async {
      final server = serverInputSaya();
      await pompaInput(tester, server);
      server.penangan['donasisaya'] = (r) async => jawabGalat(422, 'tidak_valid', 'Isian tidak valid.', {
            'rincian': {'tanggal': 'Tanggal harus YYYY-MM-DD antara 2000-01-01 dan 2100-12-31.'},
          });
      await pilihTab(tester, 'Input Saya');
      expect(_galatTanggal(tester), 'Tanggal harus YYYY-MM-DD antara 2000-01-01 dan 2100-12-31.');
      expect(find.byType(KerangkaMemuat), findsNothing);
    });

    testWidgets('401 saat memuat → Masuk; setelah masuk daftar dimuat ulang', (tester) async {
      final server = serverInputSaya();
      await pompaInput(tester, server);
      server.penangan['donasisaya'] =
          (r) async => jawabGalat(401, 'token_kedaluwarsa', 'Sesi berakhir. Silakan masuk lagi.');
      await pilihTab(tester, 'Input Saya');
      expect(find.byType(LayarMasuk), findsOneWidget);

      server.penangan['donasisaya'] = _donasiSaya();
      await isiDanMasuk(tester);
      expect(find.byType(LayarMasuk), findsNothing);
      expect(judulAppBar(tester), 'Input Saya');
      expect(find.text(_judulBaris), findsOneWidget);
      expect(kirimanKe(server, 'donasisaya').last.headers['Authorization'], 'Bearer $tokenUji');
    });

    testWidgets('hari_ini berganti saat resume → daftar hari baru dimuat', (tester) async {
      final server = serverInputSaya();
      final sesi = await pompaTabInputSaya(tester, server);
      server.penangan['konfigurasi'] = (r) async => jawabOk({...konfigurasiUji(), 'hari_ini': '2026-10-13'});
      server.penangan['donasisaya'] = (r) async => jawabOk(donasiSayaUji(
            tanggal: r.url.queryParameters['tanggal'] ?? '2026-10-13',
            total: 0,
            transaksi: 0,
          ));
      await sesi.segarkan();
      await tester.pumpAndSettle();
      expect(find.text('Selasa, 13/10/2026'), findsOneWidget);
      expect(find.text('Belum ada input pada tanggal ini'), findsOneWidget);
      expect(kirimanKe(server, 'donasisaya').last.url.queryParameters.containsKey('tanggal'), isFalse);
    });
  });

  group('ubah', () {
    testWidgets('lembar berisi Jumlah lama; 200 → lembar tertutup, daftar dan strip dimuat ulang', (tester) async {
      final server = serverInputSaya();
      await pompaTabInputSaya(tester, server);
      await _bukaUbah(tester);

      expect(_diLembar('Ubah Sumbangan'), findsOneWidget);
      expect(find.descendant(of: _lembar, matching: find.textContaining('Senin, 12/10/2026 09:20')), findsOneWidget);
      expect(teksIsian(tester, 'Sumbangan'), '100000');
      final terpilih = tester.widget<TextField>(isian('Sumbangan')).controller!.selection;
      expect([terpilih.start, terpilih.end], [0, 6]);
      expect(_simpanAktif(tester), isTrue);

      server.penangan['donasisaya'] = _donasiSaya(total: 150000, daftar: [barisDonasiSayaUji(jumlah: 150000)]);
      await _ubahJumlah(tester, '150000');
      await ketuk(tester, tombol<FilledButton>('Simpan'));

      final kiriman = kirimanKe(server, 'ubahdonasi').single;
      expect(_isiJson(kiriman), {'id': 145438, 'jumlah': 150000, 'konfirmasi': false});
      expect(kiriman.headers['Idempotency-Key'], matches(RegExp(r'^[0-9a-f-]{36}$')));
      expect(_lembar, findsNothing);
      expect(kirimanKe(server, 'donasisaya'), hasLength(3));
      expect(find.descendant(of: _baris(_judulBaris), matching: find.text('Rp 150.000')), findsOneWidget);

      // ubahdonasi tanpa ringkasan_hari_ini: strip tab Input dari donasisaya hari ini yang dimuat ulang.
      await pilihTab(tester, 'Input');
      expect(ringkasanHariIni(tester), ('Rp 150.000', '1 transaksi'));
    });

    testWidgets('2xx dengan "ulang": true diperlakukan sukses', (tester) async {
      final server = serverInputSaya();
      server.penangan['ubahdonasi'] =
          (r) async => jawabJson(200, {'ok': true, 'ulang': true, 'data': ubahDonasiUji()});
      await pompaTabInputSaya(tester, server);
      await _bukaUbah(tester);
      await _ubahJumlah(tester, '150000');
      await ketuk(tester, tombol<FilledButton>('Simpan'));
      expect(_lembar, findsNothing);
    });

    testWidgets('Batal → lembar tertutup tanpa permintaan', (tester) async {
      final server = serverInputSaya();
      await pompaTabInputSaya(tester, server);
      await _bukaUbah(tester);
      await ketuk(tester, tombol<TextButton>('Batal'));
      expect(_lembar, findsNothing);
      expect(kirimanKe(server, 'ubahdonasi'), isEmpty);
      expect(kirimanKe(server, 'donasisaya'), hasLength(2));
    });

    testWidgets('Jumlah kosong → Simpan nonaktif', (tester) async {
      await pompaTabInputSaya(tester, serverInputSaya());
      await _bukaUbah(tester);
      await _ubahJumlah(tester, '');
      expect(_simpanAktif(tester), isFalse);
    });

    testWidgets('403 tidak_berhak → pesan server di lembar, isian tetap', (tester) async {
      final server = serverInputSaya();
      server.penangan['ubahdonasi'] = (r) async => jawabGalat(403, 'tidak_berhak', _pesanK6);
      await pompaTabInputSaya(tester, server);
      await _bukaUbah(tester);
      await _ubahJumlah(tester, '150000');
      await ketuk(tester, tombol<FilledButton>('Simpan'));

      expect(_lembar, findsOneWidget);
      expect(_diLembar(_pesanK6), findsOneWidget);
      expect(teksIsian(tester, 'Sumbangan'), '150000');
      expect(kirimanKe(server, 'donasisaya'), hasLength(2));
    });

    testWidgets('404 tidak_ada → pesan di lembar dan daftar dimuat ulang', (tester) async {
      final server = serverInputSaya();
      server.penangan['ubahdonasi'] =
          (r) async => jawabGalat(404, 'tidak_ada', 'Data sumbangan tidak ditemukan.');
      await pompaTabInputSaya(tester, server);
      server.penangan['donasisaya'] = _donasiSaya(total: 0, transaksi: 0, daftar: []);
      await _bukaUbah(tester);
      await ketuk(tester, tombol<FilledButton>('Simpan'));

      expect(_diLembar('Data sumbangan tidak ditemukan.'), findsOneWidget);
      expect(kirimanKe(server, 'donasisaya'), hasLength(3));
      await ketuk(tester, tombol<TextButton>('Batal'));
      expect(find.text('Belum ada input pada tanggal ini'), findsOneWidget);
    });

    testWidgets('422 rincian.jumlah → errorText Sumbangan', (tester) async {
      final server = serverInputSaya();
      server.penangan['ubahdonasi'] = (r) async => jawabGalat(422, 'tidak_valid', 'Isian tidak valid.', {
            'rincian': {'jumlah': 'Nominal sumbangan harus angka tanpa titik atau koma.'},
          });
      await pompaTabInputSaya(tester, server);
      await _bukaUbah(tester);
      await ketuk(tester, tombol<FilledButton>('Simpan'));
      expect(galatIsian(tester, 'Sumbangan'), 'Nominal sumbangan harus angka tanpa titik atau koma.');
      expect(find.byType(PanelGalat), findsNothing);

      await _ubahJumlah(tester, '150000');
      expect(galatIsian(tester, 'Sumbangan'), isNull);
    });

    testWidgets('nominal 500 → dialog lokal; Tidak → tanpa permintaan; Ya → terkirim', (tester) async {
      final server = serverInputSaya();
      await pompaTabInputSaya(tester, server);
      await _bukaUbah(tester);
      await _ubahJumlah(tester, '500');
      await ketuk(tester, tombol<FilledButton>('Simpan'));
      expect(_diDialog('Nominal Rp 500 — benar?'), findsOneWidget);
      await ketuk(tester, tombol<TextButton>('Tidak'));
      expect(kirimanKe(server, 'ubahdonasi'), isEmpty);
      expect(_lembar, findsOneWidget);

      await ketuk(tester, tombol<FilledButton>('Simpan'));
      await ketuk(tester, tombol<FilledButton>('Ya, simpan'));
      expect(_isiJson(kirimanKe(server, 'ubahdonasi').single)['jumlah'], 500);
      expect(_lembar, findsNothing);
    });

    testWidgets('409 perlu_konfirmasi K9 → dialog alasan; Ya → konfirmasi true dengan kunci baru', (tester) async {
      final server = serverInputSaya();
      server.penangan['ubahdonasi'] = (r) async => _isiJson(r)['konfirmasi'] == true
          ? jawabOk(ubahDonasiUji(jumlah: 6000000))
          : jawabGalat(409, 'perlu_konfirmasi', 'Periksa sebelum menyimpan.', {
              'alasan': ['Nominal baru Rp. 6.000.000,- di atas Rp. 5.000.000,-.'],
            });
      await pompaTabInputSaya(tester, server);
      await _bukaUbah(tester);
      await _ubahJumlah(tester, '6000000');
      await ketuk(tester, tombol<FilledButton>('Simpan'));

      expect(_diDialog('Periksa sebelum menyimpan.'), findsOneWidget);
      expect(_diDialog('Fulan bin Fulan'), findsOneWidget);
      expect(_diDialog('Nominal baru Rp. 6.000.000,- di atas Rp. 5.000.000,-.'), findsOneWidget);
      await ketuk(tester, tombol<FilledButton>('Ya, simpan'));

      final kiriman = kirimanKe(server, 'ubahdonasi');
      expect(kiriman, hasLength(2));
      expect(_isiJson(kiriman[1]), {'id': 145438, 'jumlah': 6000000, 'konfirmasi': true});
      expect(kiriman[1].headers['Idempotency-Key'], isNot(kiriman[0].headers['Idempotency-Key']));
      expect(_lembar, findsNothing);
    });

    testWidgets('409 perlu_konfirmasi → Tidak: tanpa kiriman kedua, lembar dan isian tetap', (tester) async {
      final server = serverInputSaya();
      server.penangan['ubahdonasi'] = (r) async => jawabGalat(409, 'perlu_konfirmasi', 'Periksa sebelum menyimpan.', {
            'alasan': ['Nominal baru Rp. 6.000.000,- di atas Rp. 5.000.000,-.'],
          });
      await pompaTabInputSaya(tester, server);
      await _bukaUbah(tester);
      await _ubahJumlah(tester, '6000000');
      await ketuk(tester, tombol<FilledButton>('Simpan'));
      await ketuk(tester, tombol<TextButton>('Tidak'));
      expect(kirimanKe(server, 'ubahdonasi'), hasLength(1));
      expect(_lembar, findsOneWidget);
      expect(teksIsian(tester, 'Sumbangan'), '6000000');
    });

    testWidgets('timeout → lembar tertahan selama memuat; Kirim ulang dengan kunci dan isi sama', (tester) async {
      final server = serverInputSaya();
      final tidakPernah = Completer<http.Response>();
      server.penangan['ubahdonasi'] = (r) => tidakPernah.future;
      await pompaTabInputSaya(tester, server);
      await _bukaUbah(tester);
      await _ubahJumlah(tester, '150000');
      await tester.tap(tombol<FilledButton>('Simpan'));
      await tester.pump();

      // Memuat: Simpan nonaktif dengan indikator, Batal dan isian terkunci, ketuk di luar diabaikan.
      final simpan = find.ancestor(of: find.byType(CircularProgressIndicator), matching: find.byType(FilledButton));
      expect(tester.widget<FilledButton>(simpan).onPressed, isNull);
      expect(tester.widget<TextButton>(tombol<TextButton>('Batal')).onPressed, isNull);
      expect(tester.widget<TextField>(isian('Sumbangan')).enabled, isFalse);
      await tester.tapAt(const Offset(20, 120));
      await tester.pump();
      expect(_lembar, findsOneWidget);

      await tester.pump(const Duration(seconds: 21));
      await tester.pumpAndSettle();
      expect(_diLembar(TeksGalat.jaringanPost), findsOneWidget);
      expect(teksIsian(tester, 'Sumbangan'), '150000');

      server.penangan['ubahdonasi'] = (r) async => jawabOk(ubahDonasiUji());
      await ketuk(tester, tombol<OutlinedButton>('Kirim ulang'));
      final kiriman = kirimanKe(server, 'ubahdonasi');
      expect(kiriman, hasLength(2));
      expect(kiriman[1].headers['Idempotency-Key'], kiriman[0].headers['Idempotency-Key']);
      expect(kiriman[1].bodyBytes, kiriman[0].bodyBytes);
      expect(_lembar, findsNothing);
    });

    testWidgets('Jumlah diubah setelah galat jaringan → Kirim ulang hilang; Simpan memakai kunci baru', (tester) async {
      final server = serverInputSaya();
      server.penangan['ubahdonasi'] = (r) async => throw http.ClientException('putus');
      await pompaTabInputSaya(tester, server);
      await _bukaUbah(tester);
      await ketuk(tester, tombol<FilledButton>('Simpan'));
      expect(tombol<OutlinedButton>('Kirim ulang'), findsOneWidget);

      await _ubahJumlah(tester, '120000');
      expect(tombol<OutlinedButton>('Kirim ulang'), findsNothing);
      server.penangan['ubahdonasi'] = (r) async => jawabOk(ubahDonasiUji(jumlah: 120000));
      await ketuk(tester, tombol<FilledButton>('Simpan'));
      final kiriman = kirimanKe(server, 'ubahdonasi');
      expect(kiriman[1].headers['Idempotency-Key'], isNot(kiriman[0].headers['Idempotency-Key']));
      expect(_isiJson(kiriman[1])['jumlah'], 120000);
    });

    testWidgets('500 galat_server → pesan umum + Coba lagi dengan kunci sama', (tester) async {
      final server = serverInputSaya();
      server.penangan['ubahdonasi'] = (r) async => jawabGalat(500, 'galat_server', 'Terjadi galat di server.');
      await pompaTabInputSaya(tester, server);
      await _bukaUbah(tester);
      await ketuk(tester, tombol<FilledButton>('Simpan'));
      expect(_diLembar(TeksGalat.umum), findsOneWidget);

      server.penangan['ubahdonasi'] = (r) async => jawabOk(ubahDonasiUji());
      await ketuk(tester, tombol<OutlinedButton>('Coba lagi'));
      final kiriman = kirimanKe(server, 'ubahdonasi');
      expect(kiriman[1].headers['Idempotency-Key'], kiriman[0].headers['Idempotency-Key']);
      expect(_lembar, findsNothing);
    });

    testWidgets('401 saat Simpan → Masuk di atas; setelah masuk lembar dan isian masih ada', (tester) async {
      final server = serverInputSaya();
      server.penangan['ubahdonasi'] =
          (r) async => jawabGalat(401, 'token_kedaluwarsa', 'Sesi berakhir. Silakan masuk lagi.');
      await pompaTabInputSaya(tester, server);
      await _bukaUbah(tester);
      await _ubahJumlah(tester, '150000');
      await ketuk(tester, tombol<FilledButton>('Simpan'));
      expect(find.byType(LayarMasuk), findsOneWidget);

      server.penangan['ubahdonasi'] = (r) async => jawabOk(ubahDonasiUji());
      await isiDanMasuk(tester);
      expect(find.byType(LayarMasuk), findsNothing);
      expect(_lembar, findsOneWidget);
      expect(teksIsian(tester, 'Sumbangan'), '150000');

      await ketuk(tester, tombol<FilledButton>('Simpan'));
      final kiriman = kirimanKe(server, 'ubahdonasi');
      expect(kiriman, hasLength(2));
      expect(kiriman[1].headers['Authorization'], 'Bearer $tokenUji');
      expect(_lembar, findsNothing);
    });
  });

  testWidgets('360×640 dp, textScaler 1,3: daftar panjang, nominal besar, lembar dengan panel → tanpa luapan',
      (tester) async {
    final server = serverInputSaya();
    server.penangan['donasisaya'] = _donasiSaya(total: 2000000000, transaksi: 58, daftar: [
      for (var i = 0; i < 30; i++)
        barisDonasiSayaUji(
          id: 146000 + i,
          waktu: '23:59:${(59 - i).toString().padLeft(2, '0')}',
          idDonatur: 32767,
          namaDonatur: 'Hj. Siti Fatimah binti Haji Abdurrahman Kandangan $i',
          jumlah: 2000000000,
          bolehUbah: i.isEven,
          noteN: i % 3 == 0,
        ),
    ]);
    server.penangan['ubahdonasi'] = (r) async => jawabGalat(403, 'tidak_berhak', _pesanK6);
    await pompaTabInputSaya(tester, server, layarKecil: true);
    expect(find.text('Rp 2.000.000.000'), findsWidgets);
    expect(tester.takeException(), isNull);

    // Huruf uji selebar 1 em membuat nama panjang terlipat sangat tinggi: ketuk bagian atas baris.
    final baris = _baris('32767 · Hj. Siti Fatimah binti Haji Abdurrahman Kandangan 0');
    await tester.ensureVisible(baris);
    await tester.pumpAndSettle();
    await tester.tapAt(tester.getTopLeft(baris) + const Offset(Jarak.tepiLayar, Jarak.j8));
    await tester.pumpAndSettle();
    expect(_lembar, findsOneWidget);
    expect(tester.takeException(), isNull);
    await ketuk(tester, tombol<FilledButton>('Simpan'));
    expect(_diLembar(_pesanK6), findsOneWidget);
    expect(tester.takeException(), isNull);

    await ketuk(tester, tombol<TextButton>('Batal'));
    await ketuk(tester, _pilihanTanggal);
    expect(find.byType(DatePickerDialog), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
