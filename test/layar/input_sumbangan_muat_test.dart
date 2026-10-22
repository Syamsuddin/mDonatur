// Permintaan pemilik 10 Okt 2026: layar Input Sumbangan muat satu layar tanpa digulir di HP setara
// Pixel 5 (393×851 dp, status bar 52 dp, gesture bar 24 dp, skala huruf 1,0) untuk donatur bulanan.
// Uji ini memuat huruf aplikasi (Plus Jakarta Sans dan Outfit) dari assets/huruf/ agar lebar teks sama
// dengan Android; uji widget lain memakai font uji Flutter. Berkasnya tersendiri supaya huruf itu tidak
// memengaruhi uji lain.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mdonator/layar/kerangka.dart';
import 'package:mdonator/tema.dart';
import 'package:mdonator/widget/kartu_donatur.dart';
import 'package:mdonator/widget/kartu_hasil.dart';

import 'bantu.dart';

/// Huruf yang didaftarkan di pubspec.yaml (docs/09_STACK.md), dimuat dari berkasnya.
Future<void> muatHurufAplikasi() async {
  const keluarga = {
    Huruf.keluargaIsi: ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold'],
    Huruf.keluargaTampilan: ['SemiBold', 'Bold', 'ExtraBold'],
  };
  for (final MapEntry(key: nama, value: berat) in keluarga.entries) {
    final pemuat = FontLoader(nama);
    for (final b in berat) {
      pemuat.addFont(File('assets/huruf/$nama-$b.ttf').readAsBytes().then(ByteData.sublistView));
    }
    await pemuat.load();
  }
}

void aturPixel5(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 2.75;
  tester.view.padding = const FakeViewPadding(top: 52 * 2.75, bottom: 24 * 2.75);
  addTearDown(tester.view.reset);
}

ScrollPosition gulirInput(WidgetTester tester) => tester
    .state<ScrollableState>(
        find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down).first)
    .position;

void main() {
  setUpAll(muatHurufAplikasi);

  // Admin mendapat centang Note sebaris dengan Sumbangan (K23); tinggi layar tidak boleh bertambah.
  for (final peran in ['operator', 'admin']) {
    testWidgets('Pixel 5 ($peran): donatur bulanan (10 riwayat), 6 nominal, Simpan → tanpa gulir', (tester) async {
      aturPixel5(tester);
      final server = serverInput();
      server.penangan['konfigurasi'] = (r) async => jawabOk({
            ...konfigurasiUji(peran: peran),
            'nominal_umum': [50000, 100000, 150000, 200000, 250000, 300000, 350000, 500000, 1000000, 2000000],
          });
      server.penangan['donasisaya'] = (r) async => jawabOk(donasiSayaUji(total: 12450000, transaksi: 58));
      server.penangan['donatur'] = (r) async => jawabOk(donaturUji(
            nama: 'MUHAMMAD SYAIFFUL HIDAYAT',
            alamat: 'Desa Kapuh RT 03, Kecamatan Simpur',
            noHp: '081234567890',
            keterangan: 'Ambil di rumah',
            bintang: 3,
            riwayat: [
              for (var b = 1; b <= 10; b++)
                {'tanggal': '2026-${'$b'.padLeft(2, '0')}-02', 'waktu': '09:00:00', 'jumlah': 1000000},
            ],
            totalTahunIni: 10000000,
            saranJumlah: null,
          ));
      server.penangan['tambahdonasi'] = (r) async => jawabDibuat(tambahDonasiUji(jumlah: 1000000));
      await pompaAplikasi(tester, server: server, simpanan: simpananMasuk(), kerangka: const LayarKerangka());
      expect(find.byType(Checkbox), peran == 'admin' ? findsOneWidget : findsNothing);
      expect(gulirInput(tester).maxScrollExtent, 0, reason: 'layar kosong');

      await tester.enterText(isian('Nomor Donator'), '1125');
      await tester.pump();
      await tester.tap(tombol<OutlinedButton>('Cek'));
      await tester.pumpAndSettle();
      expect(find.byType(KartuDonatur), findsOneWidget);
      expect(gulirInput(tester).maxScrollExtent, 0, reason: 'dengan kartu donatur');
      expect(tester.takeException(), isNull);

      await tester.tap(tombol<OutlinedButton>('300.000'));
      await tester.pump();
      await tester.tap(tombol<FilledButton>('Simpan'));
      await tester.pumpAndSettle();
      expect(find.byType(KartuHasil), findsOneWidget);
      expect(gulirInput(tester).maxScrollExtent, 0, reason: 'dengan kartu hasil');
    });
  }
}
