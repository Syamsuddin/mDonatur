// Kriteria F2 Pengaturan alamat server (docs/23_ACCEPTANCE_CRITERIA.md) dan P7 Pengaturan
// (docs/06_BUSINESS_PROCESS.md). Aturan skema: docs/21_SECURITY_RULES.md §Transport.

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mdonator/api/klien_api.dart';
import 'package:mdonator/layar/kerangka.dart';
import 'package:mdonator/layar/masuk.dart';
import 'package:mdonator/state/sesi.dart';

import 'bantu.dart';

Future<void> bukaPengaturanDariMasuk(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Pengaturan'));
  await tester.pumpAndSettle();
}

Future<void> bukaPengaturanDariMenu(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Menu'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Pengaturan'));
  await tester.pumpAndSettle();
}

Future<void> simpanAlamat(WidgetTester tester, String alamat) async {
  await tester.enterText(isian('Alamat Server'), alamat);
  await tester.tap(tombol<FilledButton>('Simpan'));
  await tester.pumpAndSettle();
}

/// Nilai di bawah label pada daftar info diagnosa; daftar digulir sampai label terlihat.
Future<String> nilaiInfo(WidgetTester tester, String label) async {
  await tester.scrollUntilVisible(find.text(label), 100, scrollable: find.byType(Scrollable).last);
  final kolom = find.ancestor(of: find.text(label), matching: find.byType(Column)).first;
  final teks = tester.widgetList<Text>(find.descendant(of: kolom, matching: find.byType(Text))).toList();
  return teks[1].data!;
}

void main() {
  group('alamat server', () {
    testWidgets('"http://host/donatur/" disimpan tanpa garis miring; aksi ke {BASE}/api?aksi=',
        (tester) async {
      aturLayarKecil(tester);
      final server = ServerTiruan();
      final simpanan = <String, String>{};
      await pompaAplikasi(tester, server: server, simpanan: simpanan);
      await bukaPengaturanDariMasuk(tester);
      expect(teksIsian(tester, 'Alamat Server'), alamatBawaanUji);
      expect(tester.takeException(), isNull);

      await simpanAlamat(tester, 'http://host/donatur/');
      expect(simpanan['alamat_server'], 'http://host/donatur');
      expect(teksIsian(tester, 'Alamat Server'), 'http://host/donatur');
      expect(find.text('Alamat server tersimpan.'), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await isiDanMasuk(tester);
      expect(server.permintaan.map((r) => r.url.toString()), [
        'http://host/donatur/api?aksi=login',
        'http://host/donatur/api?aksi=konfigurasi',
      ]);
    });

    testWidgets('alamat tersimpan menang atas SERVER_URL saat dibuka', (tester) async {
      final server = ServerTiruan();
      await pompaAplikasi(tester,
          server: server, simpanan: {...simpananMasuk(), 'alamat_server': 'https://contoh.org/donatur'});
      expect(server.permintaan.single.url.toString(), 'https://contoh.org/donatur/api?aksi=konfigurasi');
    });

    test('mode rilis menolak http dan menerima https; mode debug menerima keduanya', () {
      expect(periksaAlamat('http://host/donatur', rilis: true), 'Alamat harus memakai https.');
      expect(periksaAlamat('https://host/donatur', rilis: true), isNull);
      expect(periksaAlamat('http://host/donatur', rilis: false), isNull);
      expect(periksaAlamat('https://host/donatur', rilis: false), isNull);
      for (final salah in ['', '   ', 'host/donatur', 'ftp://host', 'https://', 'https://host/?a=1']) {
        expect(periksaAlamat(salah, rilis: false), isNotNull, reason: '"$salah"');
      }
      expect(rapikanAlamat(' https://host/donatur// '), 'https://host/donatur');
    });

    testWidgets('memuat: Simpan dan isian nonaktif dengan indikator sampai tersimpan', (tester) async {
      final tahan = Completer<void>();
      final simpanan = <String, String>{};
      await pompaAplikasi(tester,
          server: ServerTiruan(), simpanan: simpanan, penyimpanan: PenyimpananTertahan(tahan));
      await bukaPengaturanDariMasuk(tester);
      await tester.enterText(isian('Alamat Server'), 'https://host/donatur');
      await tester.tap(tombol<FilledButton>('Simpan'));
      await tester.pump();

      expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed, isNull);
      expect(find.descendant(of: find.byType(FilledButton), matching: find.byType(CircularProgressIndicator)),
          findsOneWidget);
      expect(tester.widget<TextField>(isian('Alamat Server')).enabled, isFalse);
      expect(tester.widget<TextButton>(tombol<TextButton>('Pakai alamat bawaan')).onPressed, isNull);

      tahan.complete();
      await tester.pumpAndSettle();
      expect(simpanan['alamat_server'], 'https://host/donatur');
      expect(find.text('Alamat server tersimpan.'), findsOneWidget);
    });

    testWidgets('mode rilis: alamat http ditolak di isian dan tidak disimpan', (tester) async {
      final simpanan = <String, String>{};
      await pompaAplikasi(tester,
          server: ServerTiruan(), simpanan: simpanan, alamatBawaan: 'https://donatur.contoh.org', rilis: true);
      await bukaPengaturanDariMasuk(tester);

      await simpanAlamat(tester, 'http://host/donatur');
      expect(galatIsian(tester, 'Alamat Server'), 'Alamat harus memakai https.');
      expect(simpanan.containsKey('alamat_server'), isFalse);
      expect(teksIsian(tester, 'Alamat Server'), 'http://host/donatur', reason: 'isian tetap');

      await simpanAlamat(tester, 'https://host/donatur');
      expect(galatIsian(tester, 'Alamat Server'), isNull);
      expect(simpanan['alamat_server'], 'https://host/donatur');
    });

    test('mode rilis: SERVER_URL http diabaikan', () {
      expect(Sesi(alamatBawaan: 'http://10.0.2.2:3000', rilis: true).alamatBawaan, isEmpty);
      expect(Sesi(alamatBawaan: 'https://donatur.contoh.org/', rilis: true).alamatBawaan,
          'https://donatur.contoh.org');
    });

    testWidgets('tanpa alamat sama sekali → Masuk meminta membuka Pengaturan', (tester) async {
      final server = ServerTiruan();
      await pompaAplikasi(tester, server: server, alamatBawaan: '');
      await isiDanMasuk(tester);
      expect(find.text('Alamat server belum diatur. Buka Pengaturan.'), findsOneWidget);
      expect(server.permintaan, isEmpty);
    });
  });

  group('ganti alamat saat sudah masuk', () {
    testWidgets('alamat berganti → token dihapus → Masuk', (tester) async {
      aturLayarKecil(tester);
      final server = ServerTiruan();
      final simpanan = simpananMasuk();
      await pompaAplikasi(tester, server: server, simpanan: simpanan);
      expect(find.byType(LayarKerangka), findsOneWidget);
      await bukaPengaturanDariMenu(tester);
      expect(tester.takeException(), isNull);

      await simpanAlamat(tester, 'https://server-lain.org');

      expect(find.byType(LayarMasuk), findsOneWidget);
      expect(simpanan, {
        'alamat_server': 'https://server-lain.org',
        'username_terakhir': 'uji_operator',
      });
      expect(teksIsian(tester, 'Username'), 'uji_operator');
    });

    testWidgets('alamat sama disimpan ulang → tetap masuk', (tester) async {
      final simpanan = simpananMasuk();
      await pompaAplikasi(tester, server: ServerTiruan(), simpanan: simpanan);
      await bukaPengaturanDariMenu(tester);
      await simpanAlamat(tester, '$alamatBawaanUji/');
      expect(find.text('Alamat server tersimpan.'), findsOneWidget);
      expect(simpanan['token'], tokenUji);
    });

    testWidgets('"Pakai alamat bawaan" mengembalikan SERVER_URL dan menghapus token', (tester) async {
      final server = ServerTiruan();
      final simpanan = {...simpananMasuk(), 'alamat_server': 'https://contoh.org/donatur'};
      final sesi = await pompaAplikasi(tester, server: server, simpanan: simpanan);
      expect(sesi.alamatServer, 'https://contoh.org/donatur');
      await bukaPengaturanDariMenu(tester);

      await tester.tap(tombol<TextButton>('Pakai alamat bawaan'));
      await tester.pumpAndSettle();

      expect(sesi.alamatServer, alamatBawaanUji);
      expect(sesi.memakaiAlamatBawaan, isTrue);
      expect(simpanan.containsKey('alamat_server'), isFalse);
      expect(simpanan.containsKey('token'), isFalse);
      expect(find.byType(LayarMasuk), findsOneWidget);

      await isiDanMasuk(tester);
      expect(server.permintaan.last.url.toString(), '$alamatBawaanUji/api?aksi=konfigurasi');
    });

    testWidgets('dari layar Masuk ulang (401): alamat berganti → Masuk di layar akar', (tester) async {
      final server = ServerTiruan();
      server.penangan['donatur'] =
          (r) async => jawabGalat(401, 'token_tidak_sah', 'Token tidak sah.');
      await pompaAplikasi(tester, server: server, simpanan: simpananMasuk(), kerangka: kerangkaDenganTabTiruan);
      await tester.tap(tombol<OutlinedButton>('Kirim Uji'));
      await tester.pumpAndSettle();
      expect(find.byType(LayarMasuk), findsOneWidget);

      await bukaPengaturanDariMasuk(tester);
      await simpanAlamat(tester, 'https://server-lain.org');

      expect(find.byType(LayarMasuk), findsOneWidget);
      expect(find.byType(LayarKerangka, skipOffstage: false), findsNothing);
      expect(Navigator.of(tester.element(find.byType(LayarMasuk))).canPop(), isFalse);
    });
  });

  group('informasi diagnosa', () {
    testWidgets('versi aplikasi, versiKontrak, versi_api, username, peran, kedaluwarsa', (tester) async {
      aturLayarKecil(tester);
      await pompaAplikasi(tester, server: ServerTiruan(), simpanan: simpananMasuk());
      await bukaPengaturanDariMenu(tester);
      expect(tester.takeException(), isNull);

      expect(await nilaiInfo(tester, 'Versi aplikasi'), versiAplikasi);
      expect(await nilaiInfo(tester, 'Versi kontrak'), versiKontrak);
      expect(await nilaiInfo(tester, 'Versi API server'), versiKontrak);
      expect(await nilaiInfo(tester, 'Alamat server'), alamatBawaanUji);
      expect(await nilaiInfo(tester, 'Username'), 'uji_operator');
      expect(await nilaiInfo(tester, 'Peran'), 'operator');
      expect(await nilaiInfo(tester, 'Token berlaku sampai'), 'Selasa, 13/10/2026 00:15');
    });

    testWidgets('belum masuk → nilai yang belum diketahui tampil "—"', (tester) async {
      await pompaAplikasi(tester, server: ServerTiruan());
      await bukaPengaturanDariMasuk(tester);
      expect(await nilaiInfo(tester, 'Versi API server'), '—');
      expect(await nilaiInfo(tester, 'Username'), '—');
      expect(await nilaiInfo(tester, 'Peran'), '—');
    });

    test('versiAplikasi sama dengan version di pubspec.yaml', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      final versi = RegExp(r'^version:\s*(\S+)', multiLine: true).firstMatch(pubspec)!.group(1);
      expect(versiAplikasi, versi);
    });
  });
}
