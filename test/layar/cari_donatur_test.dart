// Kriteria F3 bagian Cari Donatur (docs/23_ACCEPTANCE_CRITERIA.md), P2.2 (docs/06_BUSINESS_PROCESS.md),
// dan empat state Cari Donatur (docs/26_UI_CONVENTIONS.md).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mdonator/layar/cari_donatur.dart';
import 'package:mdonator/state/sesi.dart';
import 'package:mdonator/widget/avatar_inisial.dart';
import 'package:mdonator/widget/kartu_donatur.dart';
import 'package:mdonator/widget/kerangka_memuat.dart';
import 'package:mdonator/widget/latar_dasbor.dart';

import 'bantu.dart';

/// Jawaban `caridonatur` seperti contoh kontrak §6.4, dengan [banyak] hasil.
Map<String, Object?> hasilCariUji({int banyak = 1, bool lebih = false, String nama = 'Fulan bin Fulan'}) => {
      'hasil': [
        for (var i = 0; i < banyak; i++)
          {'id': 1234 + i, 'nama': i == 0 ? nama : '$nama $i', 'alamat': 'Desa Kapuh, Simpur'},
      ],
      'lebih': lebih,
    };

Future<ServerTiruan> bukaCari(WidgetTester tester, {ServerTiruan? server, bool layarKecil = false}) async {
  final s = server ?? serverInput();
  s.penangan['caridonatur'] ??= (r) async => jawabOk(hasilCariUji());
  await pompaInput(tester, s, layarKecil: layarKecil);
  await ketuk(tester, find.byTooltip('Cari Donatur'));
  return s;
}

const petunjuk = 'Ketik minimal 2 huruf nama, alamat, atau nomor';
const labelCari = 'Nama, alamat, atau nomor';

void main() {
  testWidgets('kosong: petunjuk tampil; q kurang dari 2 huruf tidak dikirim', (tester) async {
    final server = await bukaCari(tester);
    expect(find.byType(LayarCariDonatur), findsOneWidget);
    expect(judulAppBar(tester), 'Cari Donatur');
    expect(find.text(petunjuk), findsOneWidget);
    expect(tester.widget<TextField>(isian(labelCari)).focusNode?.hasFocus ?? true, isTrue);

    await tester.enterText(isian(labelCari), 'a');
    await tester.pump(const Duration(seconds: 1));
    await tester.enterText(isian(labelCari), '  a  ');
    await tester.pump(const Duration(seconds: 1));
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump(const Duration(seconds: 1));

    expect(kirimanKe(server, 'caridonatur'), isEmpty);
    expect(find.text(petunjuk), findsOneWidget);
  });

  testWidgets('isian cari di kepala dasbor; hasil di dalam kartu dengan avatar inisial', (tester) async {
    await bukaCari(tester);
    final kepala = find.byWidgetPredicate((w) => w is LatarDasbor && w.kepala != null);
    expect(find.descendant(of: kepala, matching: isian(labelCari)), findsOneWidget);
    expect(tester.getBottomLeft(isian(labelCari)).dy, lessThan(tester.getTopLeft(find.text(petunjuk)).dy));

    await tester.enterText(isian(labelCari), 'fulan');
    await tester.pumpAndSettle(const Duration(milliseconds: 500));
    final baris = find.widgetWithText(ListTile, 'Fulan bin Fulan');
    expect(find.ancestor(of: baris, matching: find.byType(Card)), findsOneWidget);
    final avatar = tester.widget<AvatarInisial>(find.descendant(of: baris, matching: find.byType(AvatarInisial)));
    expect(avatar.nama, 'Fulan bin Fulan');
    expect(find.descendant(of: baris, matching: find.text('FB')), findsOneWidget);
  });

  test('inisialNama: huruf pertama dua kata pertama yang diawali huruf atau angka', () {
    expect(inisialNama('Fulan bin Fulan'), 'FB');
    expect(inisialNama('  hj.   siti aminah '), 'HS');
    expect(inisialNama('(donatur terhapus)'), 'T');
    expect(inisialNama('Toko 99 Jaya'), 'T9');
    expect(inisialNama(''), '');
  });

  testWidgets('q ≥ 2 huruf dikirim sekali setelah jeda 500 ms, sudah dipangkas; hasil tampil', (tester) async {
    final server = await bukaCari(tester);
    await tester.enterText(isian(labelCari), 'fu');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.enterText(isian(labelCari), ' ful ');
    await tester.pump(const Duration(milliseconds: 400));
    expect(kirimanKe(server, 'caridonatur'), isEmpty, reason: 'jeda diulang setiap ketikan');

    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();
    final kiriman = kirimanKe(server, 'caridonatur');
    expect(kiriman, hasLength(1));
    expect(kiriman.single.url.queryParameters['q'], 'ful');
    expect(find.widgetWithText(ListTile, 'Fulan bin Fulan'), findsOneWidget);
    expect(find.text('1234 · Desa Kapuh, Simpur'), findsOneWidget);
    expect(find.text('Persempit pencarian'), findsNothing);
  });

  testWidgets('tombol cari di keyboard langsung mengirim, tanpa kiriman kedua dari jeda', (tester) async {
    final server = await bukaCari(tester);
    await tester.enterText(isian(labelCari), 'fu');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump();
    expect(kirimanKe(server, 'caridonatur'), hasLength(1));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(kirimanKe(server, 'caridonatur'), hasLength(1));
  });

  testWidgets('memuat → kerangka daftar', (tester) async {
    final server = serverInput();
    final jawaban = Completer<void>();
    server.penangan['caridonatur'] = (r) async {
      await jawaban.future;
      return jawabOk(hasilCariUji());
    };
    await bukaCari(tester, server: server);
    await tester.enterText(isian(labelCari), 'fu');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    expect(find.byType(KerangkaMemuat), findsOneWidget);

    jawaban.complete();
    await tester.pumpAndSettle();
    expect(find.byType(KerangkaMemuat), findsNothing);
    expect(find.widgetWithText(ListTile, 'Fulan bin Fulan'), findsOneWidget);
  });

  testWidgets('lebih: true → "Persempit pencarian"', (tester) async {
    final server = serverInput();
    server.penangan['caridonatur'] = (r) async => jawabOk(hasilCariUji(banyak: 20, lebih: true));
    await bukaCari(tester, server: server);
    await tester.enterText(isian(labelCari), 'fu');
    await tester.pumpAndSettle(const Duration(milliseconds: 500));
    expect(find.text('Persempit pencarian'), findsOneWidget);
  });

  testWidgets('hasil kosong → "Tidak ada donatur yang cocok"', (tester) async {
    final server = serverInput();
    server.penangan['caridonatur'] = (r) async => jawabOk({'hasil': <Object?>[], 'lebih': false});
    await bukaCari(tester, server: server);
    await tester.enterText(isian(labelCari), 'zz');
    await tester.pumpAndSettle(const Duration(milliseconds: 500));
    expect(find.text('Tidak ada donatur yang cocok'), findsOneWidget);
  });

  testWidgets('galat jaringan → panel + Coba lagi; Coba lagi mengirim lagi', (tester) async {
    final server = serverInput();
    server.penangan['caridonatur'] = (r) async => throw http.ClientException('putus');
    await bukaCari(tester, server: server);
    await tester.enterText(isian(labelCari), 'fu');
    await tester.pumpAndSettle(const Duration(milliseconds: 500));
    expect(find.text(TeksGalat.jaringanGet), findsOneWidget);
    expect(teksIsian(tester, labelCari), 'fu');

    server.penangan['caridonatur'] = (r) async => jawabOk(hasilCariUji());
    await ketuk(tester, tombol<OutlinedButton>('Coba lagi'));
    expect(kirimanKe(server, 'caridonatur'), hasLength(2));
    expect(find.widgetWithText(ListTile, 'Fulan bin Fulan'), findsOneWidget);
  });

  testWidgets('422 rincian.q → errorText isian cari', (tester) async {
    final server = serverInput();
    server.penangan['caridonatur'] = (r) async => jawabGalat(422, 'tidak_valid', 'Isian belum benar.',
        {'rincian': {'q': 'Ketik minimal 2 huruf.'}});
    await bukaCari(tester, server: server);
    await tester.enterText(isian(labelCari), 'fu');
    await tester.pumpAndSettle(const Duration(milliseconds: 500));
    expect(galatIsian(tester, labelCari), 'Ketik minimal 2 huruf.');
  });

  testWidgets('jawaban untuk q lama dibuang bila q sudah berganti', (tester) async {
    final server = serverInput();
    final lama = Completer<void>();
    server.penangan['caridonatur'] = (r) async {
      if (r.url.queryParameters['q'] == 'fu') {
        await lama.future;
        return jawabOk(hasilCariUji(nama: 'Fulan bin Fulan'));
      }
      return jawabOk(hasilCariUji(nama: 'Kapuh Madani'));
    };
    await bukaCari(tester, server: server);
    await tester.enterText(isian(labelCari), 'fu');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.enterText(isian(labelCari), 'ka');
    await tester.pumpAndSettle(const Duration(milliseconds: 500));
    expect(find.widgetWithText(ListTile, 'Kapuh Madani'), findsOneWidget);

    lama.complete();
    await tester.pumpAndSettle();
    expect(find.widgetWithText(ListTile, 'Kapuh Madani'), findsOneWidget);
    expect(find.widgetWithText(ListTile, 'Fulan bin Fulan'), findsNothing);
  });

  testWidgets('ketuk hasil → kembali ke Input, nomor terisi, Cek otomatis', (tester) async {
    final server = await bukaCari(tester);
    await tester.enterText(isian(labelCari), 'fu');
    await tester.pumpAndSettle(const Duration(milliseconds: 500));
    await ketuk(tester, find.widgetWithText(ListTile, 'Fulan bin Fulan'));

    expect(find.byType(LayarCariDonatur), findsNothing);
    expect(judulAppBar(tester), 'Input Sumbangan');
    expect(teksIsian(tester, 'Nomor Donator'), '1234');
    expect(kirimanKe(server, 'donatur').single.url.queryParameters['id'], '1234');
    expect(find.byType(KartuDonatur), findsOneWidget);
    expect(teksIsian(tester, 'Sumbangan'), '200000');
  });

  testWidgets('kembali tanpa memilih → nomor tidak berubah, tanpa Cek', (tester) async {
    final server = serverInput();
    server.penangan['caridonatur'] = (r) async => jawabOk(hasilCariUji());
    await pompaInput(tester, server);
    await tester.enterText(isian('Nomor Donator'), '77');
    await ketuk(tester, find.byTooltip('Cari Donatur'));
    expect(find.byType(LayarCariDonatur), findsOneWidget);
    // Tombol Back Android.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(LayarCariDonatur), findsNothing);

    expect(teksIsian(tester, 'Nomor Donator'), '77');
    expect(kirimanKe(server, 'donatur'), isEmpty);
  });

  testWidgets('360×640 dp, textScaler 1,3: petunjuk, 20 hasil + lebih, galat → tanpa luapan', (tester) async {
    final server = serverInput();
    server.penangan['caridonatur'] = (r) async => jawabOk(hasilCariUji(
          banyak: 20,
          lebih: true,
          nama: 'Hj. Siti Fatimah binti Haji Abdurrahman Kandangan',
        ));
    await bukaCari(tester, server: server, layarKecil: true);
    expect(tester.takeException(), isNull);

    await tester.enterText(isian(labelCari), 'siti');
    await tester.pumpAndSettle(const Duration(milliseconds: 500));
    expect(find.text('Persempit pencarian'), findsOneWidget);
    expect(tester.takeException(), isNull);

    server.penangan['caridonatur'] = (r) async => throw http.ClientException('putus');
    await tester.enterText(isian(labelCari), 'fatimah');
    await tester.pumpAndSettle(const Duration(milliseconds: 500));
    expect(find.text(TeksGalat.jaringanGet), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
