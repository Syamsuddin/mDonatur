// Gerak docs/26_UI_CONVENTIONS.md §Token gerak dan docs/13_TESTING.md. Uji widget lain menyalakan Hapus
// animasi lewat bantu.dart; di sini animasi aktif dan waktu dimajukan dengan pump(durasi), karena kilau
// kerangka memuat berulang tanpa henti.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mdonator/layar/kerangka.dart';
import 'package:mdonator/tema.dart';
import 'package:mdonator/widget/kartu_hasil.dart';
import 'package:mdonator/widget/kerangka_memuat.dart';
import 'package:skeletonizer/skeletonizer.dart';

import 'bantu.dart';

Future<void> pompaInputBergerak(WidgetTester tester, ServerTiruan server, {required bool hapusAnimasi}) async {
  tester.view.physicalSize = const Size(800 * 3, 2000 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await pompaAplikasi(
    tester,
    server: server,
    simpanan: simpananMasuk(),
    kerangka: const LayarKerangka(),
    hapusAnimasi: hapusAnimasi,
  );
}

/// Cek nomor 1234 (saran Jumlah Rp 200.000 terisi), lalu Simpan dan tunggu jawaban tanpa memajukan waktu.
Future<Finder> simpanSaran(WidgetTester tester) async {
  await tester.enterText(isian('Nomor Donator'), '1234');
  await ketuk(tester, tombol<OutlinedButton>('Cek'));
  await tester.tap(tombol<FilledButton>('Simpan'));
  await tester.pump();
  await tester.pump();
  return find.byType(KartuHasil);
}

void main() {
  testWidgets('animasi aktif: nominal kartu hasil naik dari Rp 0 ke nilai akhir; Semantics selalu nilai akhir',
      (tester) async {
    final semantik = tester.ensureSemantics();
    final server = serverInput();
    server.penangan['tambahdonasi'] = (r) async => jawabDibuat(tambahDonasiUji());
    await pompaInputBergerak(tester, server, hapusAnimasi: false);

    final kartu = await simpanSaran(tester);
    expect(kartu, findsOneWidget);
    // flutter_animate mulai setelah frame pertama kartu: frame ini memulai gerak, frame berikutnya
    // 300 ms kemudian. Saat itu kartu sudah selesai muncul (gerak cepat), nominal masih menghitung naik.
    await tester.pump(Gerak.cepat);
    await tester.pump(Gerak.cepat + const Duration(milliseconds: 100));
    expect(find.descendant(of: kartu, matching: find.text('Rp 200.000')), findsNothing,
        reason: 'nominal masih menghitung naik');
    expect(find.descendant(of: kartu, matching: find.bySemanticsLabel('Rp 200.000')), findsOneWidget,
        reason: 'pembaca layar menerima nilai akhir selama nominal menghitung naik');

    await tester.pump(Gerak.hitung);
    expect(find.descendant(of: kartu, matching: find.text('Rp 200.000')), findsOneWidget);
    for (final teks in ['Data Sumbangan Berhasil Disimpan', 'Fulan bin Fulan', '09:15 WITA']) {
      expect(find.descendant(of: kartu, matching: find.text(teks)), findsOneWidget, reason: teks);
    }
    await tester.pumpAndSettle();
    semantik.dispose();
  });

  testWidgets('Hapus animasi: nominal kartu hasil langsung bernilai akhir', (tester) async {
    final server = serverInput();
    server.penangan['tambahdonasi'] = (r) async => jawabDibuat(tambahDonasiUji());
    await pompaInputBergerak(tester, server, hapusAnimasi: true);

    final kartu = await simpanSaran(tester);
    expect(find.descendant(of: kartu, matching: find.text('Rp 200.000')), findsOneWidget);
    expect(find.descendant(of: kartu, matching: find.byType(TweenAnimationBuilder<double>)), findsNothing);
  });

  testWidgets('kerangka memuat: berkilau saat animasi aktif, statis saat Hapus animasi', (tester) async {
    final semantik = tester.ensureSemantics();
    for (final (hapus, efek) in [(false, isA<ShimmerEffect>()), (true, isA<SolidColorEffect>())]) {
      aturHapusAnimasi(tester, aktif: hapus);
      for (final kerangka in const [KerangkaMemuat(), KerangkaMemuat.kepala()]) {
        await tester.pumpWidget(MaterialApp(theme: temaMDonator(), home: Scaffold(body: kerangka)));
        await tester.pump(Gerak.kilau ~/ 2);
        final skeletonizer = find.byWidgetPredicate((w) => w is Skeletonizer);
        expect(tester.widget<Skeletonizer>(skeletonizer).effect, efek,
            reason: 'Hapus animasi: $hapus, kepala: ${kerangka.diKepala}');
        expect(find.bySemanticsLabel('Memuat'), findsOneWidget);
      }
    }
    await tester.pumpWidget(const SizedBox.shrink());
    semantik.dispose();
  });
}
