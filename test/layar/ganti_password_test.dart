// Kriteria F8 Ganti password (docs/23_ACCEPTANCE_CRITERIA.md), alur P6 (docs/06_BUSINESS_PROCESS.md),
// aksi `gantipassword` (API_CONTRACT.md §6.10), dan tempat tampil galat (docs/14_ERROR_HANDLING.md).

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mdonator/layar/ganti_password.dart';
import 'package:mdonator/layar/masuk.dart';
import 'package:mdonator/state/sesi.dart';
import 'package:mdonator/tema.dart';
import 'package:mdonator/widget/panel_galat.dart';

import 'bantu.dart';

const _kedaluwarsaBaru = '2026-10-13T08:00:00+08:00';

/// Password baru tiruan untuk server tiruan (konvensi `passwordUji` di bantu.dart).
const _passwordBaruUji = 'sandi-baru-123';

Map<String, Object?> _gantiPasswordUji() => {'token': tokenBaruUji, 'kedaluwarsa': _kedaluwarsaBaru};

/// Aplikasi dengan token tersimpan, lalu menu ⋮ → Ganti Password.
Future<Sesi> _pompaGantiPassword(
  WidgetTester tester,
  ServerTiruan server, {
  Map<String, String>? simpanan,
  Widget kerangka = kerangkaKosong,
}) async {
  final sesi = await pompaAplikasi(
    tester,
    server: server,
    simpanan: simpanan ?? simpananMasuk(),
    kerangka: kerangka,
  );
  await tester.tap(find.byTooltip('Menu'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Ganti Password'));
  await tester.pumpAndSettle();
  return sesi;
}

Future<void> _isiDanSimpan(
  WidgetTester tester, {
  String lama = passwordUji,
  String baru = _passwordBaruUji,
  String? ulang,
}) async {
  await tester.enterText(isian('Password Lama'), lama);
  await tester.enterText(isian('Password Baru'), baru);
  await tester.enterText(isian('Ulangi Password Baru'), ulang ?? baru);
  await tester.tap(tombol<FilledButton>('Simpan'));
  await tester.pumpAndSettle();
}

List<String> _teksIsianPassword(WidgetTester tester) => [
      for (final label in ['Password Lama', 'Password Baru', 'Ulangi Password Baru'])
        teksIsian(tester, label),
    ];

void main() {
  testWidgets('menu ⋮ → layar Ganti Password: tiga isian berlabel, tersamar, tanpa autofill',
      (tester) async {
    aturLayarKecil(tester);
    await _pompaGantiPassword(tester, ServerTiruan());

    expect(find.byType(LayarGantiPassword), findsOneWidget);
    expect(judulAppBar(tester), 'Ganti Password');
    for (final label in ['Password Lama', 'Password Baru', 'Ulangi Password Baru']) {
      final isianPassword = tester.widget<TextField>(isian(label));
      expect(isianPassword.obscureText, isTrue, reason: label);
      expect(isianPassword.enableSuggestions, isFalse, reason: label);
      expect(isianPassword.autofillHints, isNull, reason: label);
      expect(isianPassword.controller!.text, isEmpty, reason: label);
    }
    expect(tombol<FilledButton>('Simpan'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  group('P6.1 sukses', () {
    testWidgets('200 → token tersimpan diganti; permintaan berikutnya membawa token baru',
        (tester) async {
      aturLayarKecil(tester);
      final server = ServerTiruan();
      server.penangan['gantipassword'] = (r) async => jawabOk(_gantiPasswordUji());
      final simpanan = simpananMasuk();
      final sesi = await _pompaGantiPassword(tester, server,
          simpanan: simpanan, kerangka: kerangkaDenganTabTiruan);

      await _isiDanSimpan(tester);

      final kiriman = kirimanKe(server, 'gantipassword').single;
      expect(kiriman.method, 'POST');
      expect(jsonDecode(kiriman.body),
          {'lama': passwordUji, 'baru': _passwordBaruUji, 'ulang': _passwordBaruUji});
      expect(kiriman.headers['Authorization'], 'Bearer $tokenUji');
      expect(kiriman.headers.containsKey('Idempotency-Key'), isFalse, reason: 'kontrak §6.10');

      expect(simpanan, {
        'token': tokenBaruUji,
        'kedaluwarsa': _kedaluwarsaBaru,
        'username_terakhir': 'uji_operator',
      });
      expect(sesi.kedaluwarsa, _kedaluwarsaBaru);

      // Empat state: sukses = pesan sukses; password tidak tertinggal di isian.
      final sukses = find.text('Password berhasil diganti.');
      expect(sukses, findsOneWidget);
      expect(tester.widget<Text>(sukses).style!.color, Warna.teksSukses);
      expect(_teksIsianPassword(tester), ['', '', '']);
      expect(tester.takeException(), isNull);

      // Kembali ke kerangka, lalu satu permintaan bertoken.
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(LayarGantiPassword), findsNothing);
      await tester.tap(tombol<OutlinedButton>('Kirim Uji'));
      await tester.pumpAndSettle();
      expect(kirimanKe(server, 'donatur').single.headers['Authorization'], 'Bearer $tokenBaruUji');
    });

    testWidgets('memuat: Simpan nonaktif dengan indikator, isian terkunci', (tester) async {
      final server = ServerTiruan();
      final jawaban = Completer<void>();
      server.penangan['gantipassword'] = (r) async {
        await jawaban.future;
        return jawabOk(_gantiPasswordUji());
      };
      await _pompaGantiPassword(tester, server);
      await tester.enterText(isian('Password Lama'), passwordUji);
      await tester.tap(tombol<FilledButton>('Simpan'));
      await tester.pump();

      expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed, isNull);
      expect(
          find.descendant(
              of: find.byType(FilledButton), matching: find.byType(CircularProgressIndicator)),
          findsOneWidget);
      expect(tester.widget<TextField>(isian('Password Lama')).enabled, isFalse);

      jawaban.complete();
      await tester.pumpAndSettle();
      expect(find.text('Password berhasil diganti.'), findsOneWidget);
    });
  });

  group('P6.2 cabang galat', () {
    testWidgets('422 → errorText pada isian sesuai rincian; isian dikosongkan', (tester) async {
      aturLayarKecil(tester);
      final server = ServerTiruan();
      server.penangan['gantipassword'] = (r) async => jawabGalat(422, 'tidak_valid', 'Isian tidak valid.', {
            'rincian': {'lama': 'Password lama salah.'},
          });
      final simpanan = simpananMasuk();
      await _pompaGantiPassword(tester, server, simpanan: simpanan);

      await _isiDanSimpan(tester, lama: 'salah-salah');

      expect(galatIsian(tester, 'Password Lama'), 'Password lama salah.');
      expect(galatIsian(tester, 'Password Baru'), isNull);
      expect(galatIsian(tester, 'Ulangi Password Baru'), isNull);
      expect(find.byType(PanelGalat), findsNothing);
      expect(_teksIsianPassword(tester), ['', '', '']);
      expect(simpanan['token'], tokenUji, reason: 'token lama tetap berlaku');
      expect(find.byType(LayarGantiPassword), findsOneWidget);

      server.penangan['gantipassword'] = (r) async => jawabGalat(422, 'tidak_valid', 'Isian tidak valid.', {
            'rincian': {'baru': 'Password baru minimal 8 karakter.'},
          });
      await _isiDanSimpan(tester, baru: 'pendek');
      expect(galatIsian(tester, 'Password Lama'), isNull, reason: 'galat lama dihapus');
      expect(galatIsian(tester, 'Password Baru'), 'Password baru minimal 8 karakter.');

      server.penangan['gantipassword'] = (r) async => jawabGalat(422, 'tidak_valid', 'Isian tidak valid.', {
            'rincian': {'ulang': 'Ulangan password baru tidak sama.'},
          });
      await _isiDanSimpan(tester, ulang: 'sandi-baru-124');
      expect(galatIsian(tester, 'Ulangi Password Baru'), 'Ulangan password baru tidak sama.');
      expect(tester.takeException(), isNull);
    });

    testWidgets('422 dengan kunci tanpa isian → panel galat', (tester) async {
      final server = ServerTiruan();
      server.penangan['gantipassword'] = (r) async => jawabGalat(422, 'tidak_valid', 'Isian tidak valid.', {
            'rincian': {'lain': 'Kunci lain.'},
          });
      await _pompaGantiPassword(tester, server);
      await _isiDanSimpan(tester);
      expect(find.text('Kunci lain.'), findsOneWidget);
    });

    testWidgets('409 fitur_belum_tersedia → panel berisi pesan; token tetap', (tester) async {
      aturLayarKecil(tester);
      const pesan =
          'Ganti password belum bisa dipakai karena migrasi M1 belum dijalankan. Hubungi admin.';
      final server = ServerTiruan();
      server.penangan['gantipassword'] = (r) async => jawabGalat(409, 'fitur_belum_tersedia', pesan);
      final simpanan = simpananMasuk();
      await _pompaGantiPassword(tester, server, simpanan: simpanan);

      await _isiDanSimpan(tester);

      expect(find.text(pesan), findsOneWidget);
      expect(tester.widget<Text>(find.text(pesan)).style!.color, Warna.teksBahaya);
      expect(find.text('Coba lagi'), findsNothing);
      expect(simpanan['token'], tokenUji);
      expect(find.byType(LayarGantiPassword), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('429 login_terkunci → panel berisi pesan server', (tester) async {
      final server = ServerTiruan();
      server.penangan['gantipassword'] = (r) async => jawabGalat(
          429, 'login_terkunci', 'Terlalu banyak percobaan. Coba lagi dalam 15 menit.', {'sisa_detik': 900});
      await _pompaGantiPassword(tester, server);
      await _isiDanSimpan(tester);
      expect(find.text('Terlalu banyak percobaan. Coba lagi dalam 15 menit.'), findsOneWidget);
    });

    testWidgets('galat server → pesan umum dan Coba lagi; isian tetap, Coba lagi mengirim yang sama',
        (tester) async {
      final server = ServerTiruan();
      server.penangan['gantipassword'] = (r) async => jawabGalat(500, 'galat_server', 'Rahasia server.');
      await _pompaGantiPassword(tester, server);
      await _isiDanSimpan(tester);

      expect(find.text(TeksGalat.umum), findsOneWidget);
      expect(find.text('Rahasia server.'), findsNothing);
      expect(_teksIsianPassword(tester), [passwordUji, _passwordBaruUji, _passwordBaruUji]);

      server.penangan['gantipassword'] = (r) async => jawabOk(_gantiPasswordUji());
      await tester.tap(tombol<OutlinedButton>('Coba lagi'));
      await tester.pumpAndSettle();
      final kiriman = kirimanKe(server, 'gantipassword');
      expect(kiriman, hasLength(2));
      expect(kiriman.last.body, kiriman.first.body);
      expect(find.text('Password berhasil diganti.'), findsOneWidget);
    });

    testWidgets('401 → Masuk didorong; setelah masuk, kembali ke Ganti Password yang kosong',
        (tester) async {
      final server = ServerTiruan();
      server.penangan['gantipassword'] =
          (r) async => jawabGalat(401, 'token_kedaluwarsa', 'Sesi berakhir. Silakan masuk lagi.');
      await _pompaGantiPassword(tester, server);
      await _isiDanSimpan(tester);

      expect(find.byType(LayarMasuk), findsOneWidget);
      expect(find.text('Sesi berakhir. Silakan masuk lagi.'), findsOneWidget);

      await isiDanMasuk(tester);
      expect(find.byType(LayarMasuk), findsNothing);
      expect(find.byType(LayarGantiPassword), findsOneWidget);
      expect(_teksIsianPassword(tester), ['', '', '']);
    });
  });

  testWidgets(
      'P6.3 putus setelah mengirim → token dihapus → Masuk dengan pesan; setelah masuk kembali ke tab',
      (tester) async {
    aturLayarKecil(tester);
    final server = ServerTiruan();
    server.penangan['gantipassword'] = (r) async => throw const SocketException('putus');
    final simpanan = simpananMasuk();
    await pompaAplikasi(tester,
        server: server, simpanan: simpanan, kerangka: kerangkaDenganTabTiruan);
    await tester.enterText(isian('Isian Uji'), 'nomor 1234');
    await tester.tap(find.byTooltip('Menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ganti Password'));
    await tester.pumpAndSettle();

    await _isiDanSimpan(tester);

    expect(find.byType(LayarMasuk), findsOneWidget);
    expect(find.text(TeksGalat.putusGantiPassword), findsOneWidget);
    expect(find.byType(LayarGantiPassword, skipOffstage: false), findsNothing);
    expect(simpanan.containsKey('token'), isFalse);
    expect(simpanan.containsKey('kedaluwarsa'), isFalse);
    expect(simpanan['username_terakhir'], 'uji_operator');
    expect(server.aksi.where((a) => a == 'gantipassword'), hasLength(1), reason: 'tanpa kirim ulang');
    expect(tester.takeException(), isNull);

    server.penangan['login'] = (r) async => jawabOk(loginUji(token: tokenBaruUji));
    await isiDanMasuk(tester, password: _passwordBaruUji);

    expect(find.byType(LayarMasuk), findsNothing);
    expect(judulAppBar(tester), 'Input Sumbangan');
    expect(teksIsian(tester, 'Isian Uji'), 'nomor 1234');
    expect(simpanan['token'], tokenBaruUji);
  });
}
