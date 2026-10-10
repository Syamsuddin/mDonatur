// Permintaan pemilik 10 Okt 2026: layar Input Sumbangan muat satu layar tanpa digulir di HP setara
// Pixel 5 (393×851 dp, status bar 52 dp, gesture bar 24 dp, skala huruf 1,0) untuk donatur bulanan.
// Uji ini memuat Roboto dari cache SDK Flutter (tidak dibundel ke aplikasi) agar lebar teks sama
// dengan Android; berkasnya tersendiri supaya font itu tidak memengaruhi uji lain.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mdonator/layar/kerangka.dart';
import 'package:mdonator/widget/kartu_donatur.dart';
import 'package:mdonator/widget/kartu_hasil.dart';

import 'bantu.dart';

Future<void> muatRoboto() async {
  final folder = '${Platform.environment['FLUTTER_ROOT']}/bin/cache/artifacts/material_fonts';
  final pemuat = FontLoader('Roboto');
  for (final berkas in ['Roboto-Regular.ttf', 'Roboto-Medium.ttf', 'Roboto-Bold.ttf']) {
    pemuat.addFont(File('$folder/$berkas').readAsBytes().then(ByteData.sublistView));
  }
  await pemuat.load();
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
  setUpAll(muatRoboto);

  testWidgets('Pixel 5: donatur bulanan (10 riwayat), 6 nominal, Simpan → tanpa gulir', (tester) async {
    aturPixel5(tester);
    final server = serverInput();
    server.penangan['konfigurasi'] = (r) async => jawabOk({
          ...konfigurasiUji(),
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
