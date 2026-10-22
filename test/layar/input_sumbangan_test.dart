// Kriteria F3 dan F4 (docs/23_ACCEPTANCE_CRITERIA.md), alur P2 (docs/06_BUSINESS_PROCESS.md), tempat
// tampil galat (docs/14_ERROR_HANDLING.md), dan empat state Input Sumbangan (docs/26_UI_CONVENTIONS.md).

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mdonator/layar/masuk.dart';
import 'package:mdonator/state/sesi.dart';
import 'package:mdonator/tema.dart';
import 'package:mdonator/widget/avatar_inisial.dart';
import 'package:mdonator/widget/kartu_donatur.dart';
import 'package:mdonator/widget/kartu_hasil.dart';
import 'package:mdonator/widget/kerangka_memuat.dart';
import 'package:mdonator/widget/latar_dasbor.dart';
import 'package:mdonator/widget/lencana_bintang.dart';
import 'package:mdonator/widget/nominal_cepat.dart';
import 'package:mdonator/widget/strip_hari_ini.dart';
import 'package:mdonator/widget/tombol_utama.dart';

import 'bantu.dart';

Future<void> cekNomor(WidgetTester tester, String nomor) async {
  await tester.enterText(isian('Nomor Donator'), nomor);
  await ketuk(tester, tombol<OutlinedButton>('Cek'));
}

bool simpanAktif(WidgetTester tester) =>
    tester.widget<FilledButton>(tombol<FilledButton>('Simpan')).onPressed != null;

bool punyaFokus(WidgetTester tester, String label) =>
    tester.widget<TextField>(isian(label)).focusNode!.hasFocus;

Finder diDialog(String teks) =>
    find.descendant(of: find.byType(AlertDialog), matching: find.text(teks));

Map<String, Object?> isiJson(http.Request r) => jsonDecode(r.body) as Map<String, Object?>;

void main() {
  group('saat dibuka', () {
    testWidgets('donasisaya tanpa tanggal → strip total; Cek dan Simpan nonaktif', (tester) async {
      final server = serverInput();
      await pompaInput(tester, server);

      expect(server.aksi, ['konfigurasi', 'donasisaya']);
      expect(kirimanKe(server, 'donasisaya').single.url.queryParameters.containsKey('tanggal'), isFalse);
      expect(ringkasanHariIni(tester), ('Rp 1.550.000', '10 transaksi'));
      expect(find.text('Ketik nomor donatur lalu tekan Cek'), findsOneWidget);
      expect(tester.widget<OutlinedButton>(tombol<OutlinedButton>('Cek')).onPressed, isNull);
      expect(simpanAktif(tester), isFalse);
    });

    testWidgets('ringkasan memuat → kerangka memuat di kepala dasbor, lalu ringkasan', (tester) async {
      final server = serverInput();
      final tahan = Completer<http.Response>();
      server.penangan['donasisaya'] = (r) => tahan.future;
      await pompaInput(tester, server);
      final kepala = find.byWidgetPredicate((w) => w is LatarDasbor && w.kepala != null);
      final kerangka = find.descendant(of: kepala, matching: find.byType(KerangkaMemuat));
      expect(kerangka, findsOneWidget);
      expect(tester.widget<KerangkaMemuat>(kerangka).diKepala, isTrue);
      expect(find.byType(StripHariIni), findsNothing);

      tahan.complete(jawabOk(donasiSayaUji()));
      await tester.pumpAndSettle();
      expect(kerangka, findsNothing);
      expect(ringkasanHariIni(tester), ('Rp 1.550.000', '10 transaksi'));
    });

    testWidgets('strip gagal → panel Coba lagi → dimuat ulang', (tester) async {
      final server = serverInput();
      server.penangan['donasisaya'] = (r) async => throw http.ClientException('putus');
      await pompaInput(tester, server);
      expect(find.text(TeksGalat.jaringanGet), findsOneWidget);

      server.penangan['donasisaya'] = (r) async => jawabOk(donasiSayaUji(total: 50000, transaksi: 1));
      await ketuk(tester, tombol<OutlinedButton>('Coba lagi'));
      expect(ringkasanHariIni(tester), ('Rp 50.000', '1 transaksi'));
      expect(find.text(TeksGalat.jaringanGet), findsNothing);
    });

    testWidgets('401 saat strip dimuat → setelah masuk strip dimuat ulang', (tester) async {
      final server = serverInput();
      server.penangan['donasisaya'] = (r) async =>
          jawabGalat(401, 'token_kedaluwarsa', 'Sesi berakhir. Silakan masuk lagi.');
      await pompaInput(tester, server);
      expect(find.byType(LayarMasuk), findsOneWidget);

      server.penangan['donasisaya'] = (r) async => jawabOk(donasiSayaUji());
      await isiDanMasuk(tester);
      expect(find.byType(LayarMasuk), findsNothing);
      expect(kirimanKe(server, 'donasisaya'), hasLength(2));
      expect(ringkasanHariIni(tester), ('Rp 1.550.000', '10 transaksi'));
    });

    testWidgets('hari_ini berganti saat resume → strip dimuat ulang untuk hari baru', (tester) async {
      final server = serverInput();
      server.penangan['tambahdonasi'] = (r) async => jawabDibuat(tambahDonasiUji());
      final sesi = await pompaInput(tester, server);
      await cekNomor(tester, '1234');
      await ketuk(tester, tombol<FilledButton>('Simpan'));
      expect(ringkasanHariIni(tester), ('Rp 1.450.000', '9 transaksi'));

      server.penangan['konfigurasi'] =
          (r) async => jawabOk({...konfigurasiUji(), 'hari_ini': '2026-10-13'});
      server.penangan['donasisaya'] =
          (r) async => jawabOk(donasiSayaUji(total: 0, transaksi: 0, tanggal: '2026-10-13'));
      await sesi.segarkan();
      await tester.pumpAndSettle();

      expect(ringkasanHariIni(tester), ('Rp 0', '0 transaksi'));
      expect(kirimanKe(server, 'donasisaya'), hasLength(2));
    });
  });

  group('F3 cek donatur', () {
    testWidgets('jawaban contoh kontrak §6.3 → kartu lengkap', (tester) async {
      final semantik = tester.ensureSemantics();
      final server = serverInput();
      await pompaInput(tester, server);
      await cekNomor(tester, '1234');

      expect(kirimanKe(server, 'donatur').single.url.queryParameters['id'], '1234');
      expect(find.byType(KartuDonatur), findsOneWidget);
      expect(find.text('Fulan bin Fulan'), findsOneWidget);
      expect(tester.widget<AvatarInisial>(find.descendant(of: find.byType(KartuDonatur), matching: find.byType(AvatarInisial))).nama,
          'Fulan bin Fulan');
      expect(find.text('Alamat Desa Kapuh, Simpur', findRichText: true), findsOneWidget);
      expect(find.text('No HP 08xx', findRichText: true), findsOneWidget);
      expect(find.textContaining('Keterangan', findRichText: true), findsNothing,
          reason: 'keterangan kosong tidak ditampilkan');
      expect(find.text('Bintang 2'), findsOneWidget);
      expect(find.bySemanticsLabel('Bintang 2 dari 5'), findsOneWidget);
      expect(find.text('Riwayat 2026'), findsOneWidget);
      expect(find.text('04/01 Rp 200.000', findRichText: true), findsOneWidget);
      expect(find.text('Total Rp 200.000'), findsOneWidget);
      expect(find.text('Ketik nomor donatur lalu tekan Cek'), findsNothing);
      semantik.dispose();
    });

    testWidgets('keterangan dan bintang lain ikut tampil', (tester) async {
      final server = serverInput();
      server.penangan['donatur'] =
          (r) async => jawabOk(donaturUji(keterangan: 'Ambil di rumah', bintang: 5, riwayat: []));
      await pompaInput(tester, server);
      await cekNomor(tester, '1234');

      expect(find.text('No HP 08xx · Keterangan Ambil di rumah', findRichText: true), findsOneWidget);
      expect(find.text('Bintang 5'), findsOneWidget);
      expect(find.text('Belum ada sumbangan tahun 2026.'), findsOneWidget);
    });

    testWidgets('memuat: indikator di tombol Cek', (tester) async {
      final server = serverInput();
      final jawaban = Completer<void>();
      server.penangan['donatur'] = (r) async {
        await jawaban.future;
        return jawabOk(donaturUji());
      };
      await pompaInput(tester, server);
      await tester.enterText(isian('Nomor Donator'), '1234');
      await tester.pump();
      await tester.tap(tombol<OutlinedButton>('Cek'));
      await tester.pump();

      final cek = find.ancestor(of: find.byType(CircularProgressIndicator), matching: find.byType(OutlinedButton));
      expect(cek, findsOneWidget);
      expect(tester.widget<OutlinedButton>(cek).onPressed, isNull);

      jawaban.complete();
      await tester.pumpAndSettle();
      expect(find.byType(KartuDonatur), findsOneWidget);
    });

    testWidgets('404 tidak_ada → pesan server di isian Nomor Donator', (tester) async {
      final server = serverInput();
      server.penangan['donatur'] =
          (r) async => jawabGalat(404, 'tidak_ada', 'Data Donator nomor 999 tidak ditemukan!');
      await pompaInput(tester, server);
      await cekNomor(tester, '999');

      expect(galatIsian(tester, 'Nomor Donator'), 'Data Donator nomor 999 tidak ditemukan!');
      expect(find.byType(KartuDonatur), findsNothing);
      expect(teksIsian(tester, 'Nomor Donator'), '999');
      expect(simpanAktif(tester), isFalse);

      // Mengubah nomor menghapus pesan lama.
      await tester.enterText(isian('Nomor Donator'), '99');
      await tester.pump();
      expect(galatIsian(tester, 'Nomor Donator'), isNull);
    });

    testWidgets('422 rincian.id → pesan di isian Nomor Donator', (tester) async {
      final server = serverInput();
      server.penangan['donatur'] = (r) async => jawabGalat(422, 'tidak_valid', 'Isian belum benar.',
          {'rincian': {'id': 'Nomor donatur harus angka 1–32767.'}});
      await pompaInput(tester, server);
      await cekNomor(tester, '99999');

      expect(galatIsian(tester, 'Nomor Donator'), 'Nomor donatur harus angka 1–32767.');
      expect(find.text('Isian belum benar.'), findsNothing);
    });

    testWidgets('galat jaringan saat Cek → panel Coba lagi; nomor tetap', (tester) async {
      final server = serverInput();
      server.penangan['donatur'] = (r) async => throw http.ClientException('putus');
      await pompaInput(tester, server);
      await cekNomor(tester, '1234');
      expect(find.text(TeksGalat.jaringanGet), findsOneWidget);
      expect(teksIsian(tester, 'Nomor Donator'), '1234');

      server.penangan['donatur'] = (r) async => jawabOk(donaturUji());
      await ketuk(tester, tombol<OutlinedButton>('Coba lagi'));
      expect(find.byType(KartuDonatur), findsOneWidget);
      expect(kirimanKe(server, 'donatur'), hasLength(2));
    });

    testWidgets('Nomor Donator hanya digit, paling banyak 5', (tester) async {
      await pompaInput(tester, serverInput());
      await tester.enterText(isian('Nomor Donator'), '12a3-45 6789');
      await tester.pump();
      expect(teksIsian(tester, 'Nomor Donator'), '12345');
      expect(tester.widget<TextField>(isian('Nomor Donator')).keyboardType, TextInputType.number);
    });

    testWidgets('riwayat note_n (admin) → tanggal tebal tanpa label', (tester) async {
      final server = serverInput();
      server.penangan['konfigurasi'] = (r) async => jawabOk(konfigurasiUji(peran: 'admin'));
      server.penangan['donatur'] = (r) async => jawabOk(donaturUji(riwayat: [
            {'tanggal': '2026-01-04', 'waktu': '09:12:40', 'jumlah': 200000},
            {'tanggal': '2026-02-01', 'waktu': '10:00:00', 'jumlah': 50000, 'note_n': true},
          ]));
      await pompaInput(tester, server);
      await cekNomor(tester, '1234');

      // RichText → gaya bawaan → TextSpan butir riwayat → [tanggal, nominal].
      FontWeight? beratTanggal(String isi) {
        final akar = tester.widget<RichText>(find.text(isi, findRichText: true)).text as TextSpan;
        final butir = akar.children!.single as TextSpan;
        return (butir.children!.first as TextSpan).style?.fontWeight;
      }

      expect(beratTanggal('01/02 Rp 50.000'), FontWeight.w700);
      expect(beratTanggal('04/01 Rp 200.000'), isNot(FontWeight.w700));
      // Tanpa label "Note n" di kartu; label "Note" milik centang pilihan admin (K23), bukan riwayat.
      expect(find.descendant(of: find.byType(KartuDonatur), matching: find.textContaining('Note', findRichText: true)),
          findsNothing);
    });

    testWidgets('lencana bintang: n bintang terisi dan 5 − n kosong, emas, teks "Bintang n"', (tester) async {
      final semantik = tester.ensureSemantics();
      for (var bintang = 0; bintang <= 5; bintang++) {
        await tester.pumpWidget(MaterialApp(
          theme: temaMDonator(),
          home: Scaffold(body: Center(child: LencanaBintang(bintang: bintang))),
        ));
        final ikon = tester.widgetList<Icon>(
            find.descendant(of: find.byType(LencanaBintang), matching: find.byType(Icon)));
        expect(ikon.map((i) => i.icon), [
          for (var i = 0; i < 5; i++) i < bintang ? Icons.star_rounded : Icons.star_outline_rounded,
        ], reason: 'bintang $bintang');
        expect(ikon.every((i) => i.color == Warna.emas && i.size == Bentuk.ikonBintang), isTrue,
            reason: 'warna dan ukuran bintang $bintang');
        final teks = tester.widget<Text>(find.text('Bintang $bintang'));
        expect(DefaultTextStyle.of(tester.element(find.text('Bintang $bintang'))).style.merge(teks.style).color,
            Warna.teks, reason: 'teks bintang $bintang');
        expect(find.bySemanticsLabel('Bintang $bintang dari 5'), findsOneWidget);
      }
      semantik.dispose();
    });
  });

  group('F4 simpan', () {
    testWidgets('Simpan aktif hanya setelah Cek untuk nomor yang tertulis', (tester) async {
      await pompaInput(tester, serverInput());
      await tester.enterText(isian('Nomor Donator'), '1234');
      await tester.enterText(isian('Sumbangan'), '50000');
      await tester.pump();
      expect(simpanAktif(tester), isFalse, reason: 'belum Cek');

      await ketuk(tester, tombol<OutlinedButton>('Cek'));
      expect(simpanAktif(tester), isTrue);

      await tester.enterText(isian('Nomor Donator'), '12345');
      await tester.pump();
      expect(simpanAktif(tester), isFalse, reason: 'nomor berubah');
      expect(find.byType(KartuDonatur), findsNothing);

      await tester.enterText(isian('Nomor Donator'), '1234');
      await tester.pump();
      expect(simpanAktif(tester), isFalse, reason: 'nomor kembali tetap butuh Cek ulang');
    });

    testWidgets('saran Jumlah mengisi Jumlah kosong; keyboard ditutup agar kartu dan Simpan terlihat', (tester) async {
      await pompaInput(tester, serverInput());
      await tester.enterText(isian('Nomor Donator'), '1234');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      final jumlah = tester.widget<TextField>(isian('Sumbangan')).controller!;
      expect(jumlah.text, '200000');
      expect(jumlah.selection, const TextSelection(baseOffset: 0, extentOffset: 6));
      expect(punyaFokus(tester, 'Nomor Donator'), isFalse);
      expect(punyaFokus(tester, 'Sumbangan'), isFalse);
      expect(simpanAktif(tester), isTrue);
    });

    testWidgets('saran tidak menimpa Jumlah yang diketik pengguna', (tester) async {
      await pompaInput(tester, serverInput());
      await tester.enterText(isian('Sumbangan'), '75000');
      await cekNomor(tester, '1234');
      expect(teksIsian(tester, 'Sumbangan'), '75000');

      // Mengetik di atas saran juga menghapus penanda otomatis.
      await tester.enterText(isian('Sumbangan'), '');
      await cekNomor(tester, '1234');
      expect(teksIsian(tester, 'Sumbangan'), '200000');
      await tester.enterText(isian('Sumbangan'), '2000001');
      await cekNomor(tester, '5678');
      expect(teksIsian(tester, 'Sumbangan'), '2000001');
    });

    testWidgets('Cek ke donatur lain mengganti saran sebelumnya; tanpa saran → Jumlah kosong', (tester) async {
      final server = serverInput();
      server.penangan['donatur'] = (r) async {
        final id = int.parse(r.url.queryParameters['id']!);
        return jawabOk(donaturUji(id: id, saranJumlah: {1234: 200000, 5678: 100000}[id]));
      };
      await pompaInput(tester, server);

      await cekNomor(tester, '1234');
      expect(teksIsian(tester, 'Sumbangan'), '200000');
      await cekNomor(tester, '5678');
      expect(teksIsian(tester, 'Sumbangan'), '100000');
      await cekNomor(tester, '9');
      expect(teksIsian(tester, 'Sumbangan'), '');
    });

    testWidgets('nominal cepat = nominal_umum sampai Rp 300.000, urutannya sama; ketukan mengisi Jumlah', (tester) async {
      final semantik = tester.ensureSemantics();
      final server = serverInput();
      const nominal = [100000, 50000, 2000000, 300000, 150000, 350000];
      server.penangan['konfigurasi'] =
          (r) async => jawabOk({...konfigurasiUji(), 'nominal_umum': nominal});
      await pompaInput(tester, server);

      final label = [
        for (final t in tester.widgetList<Text>(
            find.descendant(of: find.byType(NominalCepat), matching: find.byType(Text))))
          t.data,
      ];
      expect(label, ['100.000', '50.000', '300.000', '150.000']);
      expect(find.bySemanticsLabel('Rp 300.000'), findsOneWidget);

      await cekNomor(tester, '1234');
      await ketuk(tester, tombol<OutlinedButton>('300.000'));
      expect(teksIsian(tester, 'Sumbangan'), '300000');

      // Pilihan nominal cepat tidak ditimpa saran Cek berikutnya.
      await cekNomor(tester, '5678');
      expect(teksIsian(tester, 'Sumbangan'), '300000');
      semantik.dispose();
    });

    testWidgets('nominal cepat yang sama dengan isian Sumbangan tampil terpilih (kuningLembut, garis emas)',
        (tester) async {
      final semantik = tester.ensureSemantics();
      final server = serverInput();
      server.penangan['konfigurasi'] =
          (r) async => jawabOk({...konfigurasiUji(), 'nominal_umum': [50000, 100000, 150000, 200000]});
      await pompaInput(tester, server);
      ButtonStyle gaya(String label) => tester.widget<OutlinedButton>(tombol<OutlinedButton>(label)).style!;
      bool terpilih(String label) => gaya(label).backgroundColor!.resolve({}) == Warna.kuningLembut;

      await cekNomor(tester, '1234');
      // Saran Jumlah Rp 200.000 terisi dari Cek, jadi tombol 200.000 ikut terpilih.
      expect(teksIsian(tester, 'Sumbangan'), '200000');
      expect([for (final n in ['50.000', '100.000', '200.000']) terpilih(n)], [false, false, true]);
      expect(gaya('200.000').side!.resolve({}), const BorderSide(color: Warna.emas, width: Bentuk.garisTerpilih));
      expect(tester.getSemantics(tombol<OutlinedButton>('200.000')), isSemantics(isSelected: true, isButton: true));
      expect(tester.getSemantics(tombol<OutlinedButton>('100.000')), isSemantics(isSelected: false));

      await ketuk(tester, tombol<OutlinedButton>('100.000'));
      expect([for (final n in ['100.000', '200.000']) terpilih(n)], [true, false]);

      await tester.enterText(isian('Sumbangan'), '123');
      await tester.pump();
      expect(['50.000', '100.000', '150.000', '200.000'].any(terpilih), isFalse);
      semantik.dispose();
    });

    testWidgets('Cek bergaya isi; Simpan tombol utama bergradien, nonaktif berlatar garis', (tester) async {
      await pompaInput(tester, serverInput());
      final cek = tester.widget<OutlinedButton>(tombol<OutlinedButton>('Cek')).style!;
      expect(cek.backgroundColor!.resolve({}), Warna.primer);
      expect(cek.foregroundColor!.resolve({}), Warna.diAtasPrimer);
      ShapeDecoration latarSimpan() => tester
          .widget<DecoratedBox>(find.descendant(of: find.byType(TombolUtama), matching: find.byType(DecoratedBox)).first)
          .decoration as ShapeDecoration;
      expect(simpanAktif(tester), isFalse);
      expect((latarSimpan().color, latarSimpan().gradient), (Warna.garis, null));

      await cekNomor(tester, '1234');
      expect(simpanAktif(tester), isTrue);
      expect((latarSimpan().color, latarSimpan().gradient), (null, Gradien.tombol));
      expect(tester.getSize(tombol<FilledButton>('Simpan')).height, Bentuk.tinggiTombolUtama);
    });

    testWidgets('nominal_umum bawaan server → enam tombol 50.000–300.000 dalam dua baris', (tester) async {
      final server = serverInput();
      server.penangan['konfigurasi'] = (r) async => jawabOk({
            ...konfigurasiUji(),
            'nominal_umum': [50000, 100000, 150000, 200000, 250000, 300000, 350000, 500000, 1000000, 2000000],
          });
      await pompaInput(tester, server);
      final tombolCepat = find.descendant(of: find.byType(NominalCepat), matching: find.byType(OutlinedButton));
      expect(tombolCepat, findsNWidgets(6));
      final baris = {for (final e in tombolCepat.evaluate()) tester.getTopLeft(find.byWidget(e.widget)).dy};
      expect(baris, hasLength(2));
      expect(find.text('350.000'), findsNothing);
    });

    testWidgets('Jumlah 500 → dialog lokal; Tidak → tanpa permintaan; Ya → terkirim', (tester) async {
      final server = serverInput();
      server.penangan['tambahdonasi'] = (r) async => jawabDibuat(tambahDonasiUji(jumlah: 500));
      await pompaInput(tester, server);
      await cekNomor(tester, '1234');
      await tester.enterText(isian('Sumbangan'), '500');
      await ketuk(tester, tombol<FilledButton>('Simpan'));

      expect(diDialog('Nominal Rp 500 — benar?'), findsOneWidget);
      await tester.tap(tombol<TextButton>('Tidak'));
      await tester.pumpAndSettle();
      expect(kirimanKe(server, 'tambahdonasi'), isEmpty);
      expect(teksIsian(tester, 'Sumbangan'), '500');
      expect(punyaFokus(tester, 'Sumbangan'), isTrue);

      await ketuk(tester, tombol<FilledButton>('Simpan'));
      await tester.tap(tombol<FilledButton>('Ya, simpan'));
      await tester.pumpAndSettle();
      expect(isiJson(kirimanKe(server, 'tambahdonasi').single),
          {'id_donatur': 1234, 'jumlah': 500, 'konfirmasi': false});
    });

    testWidgets('Jumlah 1.000 tidak memakai dialog lokal', (tester) async {
      final server = serverInput();
      server.penangan['tambahdonasi'] = (r) async => jawabDibuat(tambahDonasiUji(jumlah: 1000));
      await pompaInput(tester, server);
      await cekNomor(tester, '1234');
      await tester.enterText(isian('Sumbangan'), '1000');
      await ketuk(tester, tombol<FilledButton>('Simpan'));
      expect(find.byType(AlertDialog), findsNothing);
      expect(kirimanKe(server, 'tambahdonasi'), hasLength(1));
    });

    testWidgets('201 → kartu hasil, strip = ringkasan_hari_ini, isian kosong, fokus Nomor', (tester) async {
      final server = serverInput();
      server.penangan['tambahdonasi'] = (r) async => jawabDibuat(tambahDonasiUji(terakhir: [
            {'id_donatur': 1234, 'jumlah': 200000, 'waktu': '09:15:02'},
            {'id_donatur': 77, 'jumlah': 50000, 'waktu': '08:01:00'},
          ]));
      await pompaInput(tester, server);
      await cekNomor(tester, '1234');
      await ketuk(tester, tombol<FilledButton>('Simpan'));

      final kiriman = kirimanKe(server, 'tambahdonasi').single;
      expect(isiJson(kiriman), {'id_donatur': 1234, 'jumlah': 200000, 'konfirmasi': false});
      expect(kiriman.headers['Idempotency-Key'], matches(RegExp(r'^[0-9a-f-]{36}$')));

      final kartu = find.byType(KartuHasil);
      expect(kartu, findsOneWidget);
      for (final teks in ['Data Sumbangan Berhasil Disimpan', 'Fulan bin Fulan', 'Rp 200.000', '09:15 WITA']) {
        expect(find.descendant(of: kartu, matching: find.text(teks)), findsOneWidget, reason: teks);
      }
      // Ringkasan di kepala: label, total, dan banyaknya input saja, tanpa input terakhir.
      final strip = find.byType(StripHariIni);
      expect(
        tester.widgetList<Text>(find.descendant(of: strip, matching: find.byType(Text))).map((t) => t.data),
        ['Total input hari ini', 'Rp 1.450.000', '9 transaksi'],
      );
      expect(find.textContaining('1234 · Rp'), findsNothing);
      expect(find.textContaining('77 · Rp'), findsNothing);
      expect(find.byType(KartuDonatur), findsNothing);
      expect(teksIsian(tester, 'Nomor Donator'), '');
      expect(teksIsian(tester, 'Sumbangan'), '');
      expect(punyaFokus(tester, 'Nomor Donator'), isTrue);
      expect(simpanAktif(tester), isFalse);
    });

    testWidgets('2xx dengan "ulang": true diperlakukan sukses', (tester) async {
      final server = serverInput();
      server.penangan['tambahdonasi'] =
          (r) async => jawabJson(201, {'ok': true, 'ulang': true, 'data': tambahDonasiUji()});
      await pompaInput(tester, server);
      await cekNomor(tester, '1234');
      await ketuk(tester, tombol<FilledButton>('Simpan'));
      expect(find.byType(KartuHasil), findsOneWidget);
    });

    testWidgets('409 perlu_konfirmasi → dialog alasan + nama; Ya → konfirmasi true dengan kunci baru', (tester) async {
      final server = serverInput();
      const alasan = [
        'Donatur nomor 1234 sudah tercatat menyumbang 1 kali hari ini.',
        'Nominal Rp. 6.000.000,- di atas Rp. 5.000.000,-.',
      ];
      server.penangan['tambahdonasi'] = (r) async {
        if (isiJson(r)['konfirmasi'] == true) return jawabDibuat(tambahDonasiUji(jumlah: 6000000));
        return jawabGalat(409, 'perlu_konfirmasi', 'Periksa sebelum menyimpan.', {
          'alasan': alasan,
          'donatur': {'id': 1234, 'nama': 'Fulan bin Fulan'},
        });
      };
      await pompaInput(tester, server);
      await cekNomor(tester, '1234');
      await tester.enterText(isian('Sumbangan'), '6000000');
      await ketuk(tester, tombol<FilledButton>('Simpan'));

      expect(diDialog('Periksa sebelum menyimpan.'), findsOneWidget);
      expect(diDialog('Fulan bin Fulan'), findsOneWidget);
      for (final a in alasan) {
        expect(diDialog(a), findsOneWidget);
      }
      await tester.tap(tombol<FilledButton>('Ya, simpan'));
      await tester.pumpAndSettle();

      final kiriman = kirimanKe(server, 'tambahdonasi');
      expect(kiriman, hasLength(2));
      expect(isiJson(kiriman[0]), {'id_donatur': 1234, 'jumlah': 6000000, 'konfirmasi': false});
      expect(isiJson(kiriman[1]), {'id_donatur': 1234, 'jumlah': 6000000, 'konfirmasi': true});
      expect(kiriman[1].headers['Idempotency-Key'], isNot(kiriman[0].headers['Idempotency-Key']));
      expect(find.byType(KartuHasil), findsOneWidget);
    });

    testWidgets('409 perlu_konfirmasi → Tidak: tanpa permintaan kedua, isian tetap', (tester) async {
      final server = serverInput();
      server.penangan['tambahdonasi'] = (r) async => jawabGalat(409, 'perlu_konfirmasi',
          'Periksa sebelum menyimpan.', {
        'alasan': ['Donatur nomor 1234 sudah tercatat menyumbang 1 kali hari ini.'],
        'donatur': {'id': 1234, 'nama': 'Fulan bin Fulan'},
      });
      await pompaInput(tester, server);
      await cekNomor(tester, '1234');
      await ketuk(tester, tombol<FilledButton>('Simpan'));
      await tester.tap(tombol<TextButton>('Tidak'));
      await tester.pumpAndSettle();

      expect(kirimanKe(server, 'tambahdonasi'), hasLength(1));
      expect(teksIsian(tester, 'Nomor Donator'), '1234');
      expect(teksIsian(tester, 'Sumbangan'), '200000');
      expect(find.byType(KartuDonatur), findsOneWidget);
      expect(simpanAktif(tester), isTrue);
    });

    testWidgets('timeout → panel Kirim ulang; kiriman ulang dengan kunci dan isi sama persis', (tester) async {
      final server = serverInput();
      final tidakPernah = Completer<http.Response>();
      server.penangan['tambahdonasi'] = (r) => tidakPernah.future;
      await pompaInput(tester, server);
      await cekNomor(tester, '1234');
      await tester.ensureVisible(tombol<FilledButton>('Simpan'));
      await tester.tap(tombol<FilledButton>('Simpan'));
      await tester.pump();

      // Memuat: Simpan nonaktif dengan indikator, isian terkunci.
      final simpan = find.ancestor(
          of: find.byType(CircularProgressIndicator), matching: find.byType(FilledButton));
      expect(tester.widget<FilledButton>(simpan).onPressed, isNull);
      expect(tester.widget<TextField>(isian('Sumbangan')).enabled, isFalse);

      await tester.pump(const Duration(seconds: 21));
      await tester.pumpAndSettle();
      expect(find.text(TeksGalat.jaringanPost), findsOneWidget);
      expect(teksIsian(tester, 'Nomor Donator'), '1234');
      expect(teksIsian(tester, 'Sumbangan'), '200000');

      server.penangan['tambahdonasi'] = (r) async => jawabDibuat(tambahDonasiUji());
      await ketuk(tester, tombol<OutlinedButton>('Kirim ulang'));

      final kiriman = kirimanKe(server, 'tambahdonasi');
      expect(kiriman, hasLength(2));
      expect(kiriman[1].headers['Idempotency-Key'], kiriman[0].headers['Idempotency-Key']);
      expect(kiriman[1].bodyBytes, kiriman[0].bodyBytes);
      expect(find.byType(KartuHasil), findsOneWidget);
    });

    testWidgets('isian diubah setelah galat jaringan → Kirim ulang hilang; Simpan memakai kunci baru', (tester) async {
      final server = serverInput();
      server.penangan['tambahdonasi'] = (r) async => throw http.ClientException('putus');
      await pompaInput(tester, server);
      await cekNomor(tester, '1234');
      await ketuk(tester, tombol<FilledButton>('Simpan'));
      expect(tombol<OutlinedButton>('Kirim ulang'), findsOneWidget);

      await tester.enterText(isian('Sumbangan'), '100000');
      await tester.pump();
      expect(tombol<OutlinedButton>('Kirim ulang'), findsNothing);

      server.penangan['tambahdonasi'] = (r) async => jawabDibuat(tambahDonasiUji(jumlah: 100000));
      await ketuk(tester, tombol<FilledButton>('Simpan'));
      final kiriman = kirimanKe(server, 'tambahdonasi');
      expect(kiriman, hasLength(2));
      expect(kiriman[1].headers['Idempotency-Key'], isNot(kiriman[0].headers['Idempotency-Key']));
      expect(isiJson(kiriman[1])['jumlah'], 100000);
    });

    testWidgets('422 rincian.jumlah → errorText Sumbangan; isian tetap', (tester) async {
      final server = serverInput();
      server.penangan['tambahdonasi'] = (r) async => jawabGalat(422, 'tidak_valid', 'Isian belum benar.',
          {'rincian': {'jumlah': 'Nominal sumbangan harus angka tanpa titik atau koma'}});
      await pompaInput(tester, server);
      await cekNomor(tester, '1234');
      await tester.enterText(isian('Sumbangan'), '0');
      await ketuk(tester, tombol<FilledButton>('Simpan'));
      await tester.tap(tombol<FilledButton>('Ya, simpan'));
      await tester.pumpAndSettle();

      expect(galatIsian(tester, 'Sumbangan'), 'Nominal sumbangan harus angka tanpa titik atau koma');
      expect(teksIsian(tester, 'Sumbangan'), '0');
      expect(teksIsian(tester, 'Nomor Donator'), '1234');
      expect(find.text('Isian belum benar.'), findsNothing);
    });

    testWidgets('500 galat_server → pesan umum + Coba lagi dengan kunci sama', (tester) async {
      final server = serverInput();
      server.penangan['tambahdonasi'] =
          (r) async => jawabGalat(500, 'galat_server', 'Terjadi galat di server.');
      await pompaInput(tester, server);
      await cekNomor(tester, '1234');
      await ketuk(tester, tombol<FilledButton>('Simpan'));
      expect(find.text(TeksGalat.umum), findsOneWidget);

      server.penangan['tambahdonasi'] = (r) async => jawabDibuat(tambahDonasiUji());
      await ketuk(tester, tombol<OutlinedButton>('Coba lagi'));
      final kiriman = kirimanKe(server, 'tambahdonasi');
      expect(kiriman[1].headers['Idempotency-Key'], kiriman[0].headers['Idempotency-Key']);
      expect(find.byType(KartuHasil), findsOneWidget);
    });

    testWidgets('401 saat Simpan → Masuk di atas kerangka; setelah masuk isian masih ada', (tester) async {
      final server = serverInput();
      server.penangan['tambahdonasi'] = (r) async =>
          jawabGalat(401, 'token_kedaluwarsa', 'Sesi berakhir. Silakan masuk lagi.');
      await pompaInput(tester, server);
      await cekNomor(tester, '1234');
      await tester.enterText(isian('Sumbangan'), '150000');
      await ketuk(tester, tombol<FilledButton>('Simpan'));
      expect(find.byType(LayarMasuk), findsOneWidget);
      expect(find.text('Sesi berakhir. Silakan masuk lagi.'), findsOneWidget);

      server.penangan['tambahdonasi'] = (r) async => jawabDibuat(tambahDonasiUji(jumlah: 150000));
      await isiDanMasuk(tester);
      expect(find.byType(LayarMasuk), findsNothing);
      expect(teksIsian(tester, 'Nomor Donator'), '1234');
      expect(teksIsian(tester, 'Sumbangan'), '150000');
      expect(find.byType(KartuDonatur), findsOneWidget);

      await ketuk(tester, tombol<FilledButton>('Simpan'));
      final kiriman = kirimanKe(server, 'tambahdonasi');
      expect(kiriman, hasLength(2));
      expect(kiriman[1].headers['Authorization'], 'Bearer $tokenUji');
      expect(find.byType(KartuHasil), findsOneWidget);
    });

    testWidgets('Keluar dengan isian yang belum disimpan → dialog', (tester) async {
      await pompaInput(tester, serverInput());
      await tester.enterText(isian('Nomor Donator'), '1234');
      await tester.tap(find.byTooltip('Menu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Keluar'));
      await tester.pumpAndSettle();
      expect(diDialog('Isian yang belum disimpan akan hilang. Keluar?'), findsOneWidget);
    });
  });

  group('Note (admin, K23)', () {
    Finder labelNote() => find.text('Note');
    bool? nilaiNote(WidgetTester tester) => tester.widget<Checkbox>(find.byType(Checkbox)).value;

    /// Server admin: `tambahdonasi` menandai jawaban `note_n` bila isinya membawa note "n".
    ServerTiruan serverAdmin() {
      final server = serverInput();
      server.penangan['konfigurasi'] = (r) async => jawabOk(konfigurasiUji(username: 'uji_admin', peran: 'admin'));
      server.penangan['tambahdonasi'] = (r) async {
        final data = tambahDonasiUji();
        if (isiJson(r)['note'] == 'n') (data['sumbangan']! as Map<String, Object?>)['note_n'] = true;
        return jawabDibuat(data);
      };
      return server;
    }

    testWidgets('operator (boleh_atur_note false): tanpa centang Note dan tanpa field note', (tester) async {
      final server = serverInput();
      await pompaInput(tester, server);
      await cekNomor(tester, '1234');
      expect(find.byType(Checkbox), findsNothing);
      expect(labelNote(), findsNothing);
      await ketuk(tester, tombol<FilledButton>('Simpan'));
      expect(isiJson(kirimanKe(server, 'tambahdonasi').single).containsKey('note'), isFalse);
    });

    testWidgets('admin dengan peran yang tidak dibolehkan server: centang tidak tampil (hak dari server)', (tester) async {
      final server = serverInput();
      server.penangan['konfigurasi'] =
          (r) async => jawabOk(konfigurasiUji(username: 'uji_admin', peran: 'admin', bolehAturNote: false));
      await pompaInput(tester, server);
      expect(find.byType(Checkbox), findsNothing);
    });

    testWidgets('bawaan tercentang (y) → tanpa field note; kosongkan → note "n", jam kartu hasil tebal; lalu kembali y',
        (tester) async {
      final server = serverAdmin();
      await pompaInput(tester, server);
      expect(nilaiNote(tester), isTrue);

      await cekNomor(tester, '1234');
      await ketuk(tester, tombol<FilledButton>('Simpan'));
      expect(isiJson(kirimanKe(server, 'tambahdonasi').last), {'id_donatur': 1234, 'jumlah': 200000, 'konfirmasi': false});
      expect(tester.widget<Text>(find.text('09:15 WITA')).style?.fontWeight, isNot(FontWeight.w700));

      await cekNomor(tester, '1234');
      await ketuk(tester, labelNote()); // label ikut bisa diketuk
      expect(nilaiNote(tester), isFalse);
      await ketuk(tester, tombol<FilledButton>('Simpan'));
      expect(isiJson(kirimanKe(server, 'tambahdonasi').last),
          {'id_donatur': 1234, 'jumlah': 200000, 'konfirmasi': false, 'note': 'n'});
      expect(find.byType(KartuHasil), findsOneWidget);
      expect(tester.widget<Text>(find.text('09:15 WITA')).style?.fontWeight, FontWeight.w700);
      expect(nilaiNote(tester), isTrue, reason: 'kembali ke y setelah tersimpan (keputusan pemilik)');

      await cekNomor(tester, '1234');
      await ketuk(tester, find.byType(Checkbox));
      await ketuk(tester, find.byType(Checkbox));
      expect(nilaiNote(tester), isTrue);
      await ketuk(tester, tombol<FilledButton>('Simpan'));
      expect(isiJson(kirimanKe(server, 'tambahdonasi').last).containsKey('note'), isFalse);
    });

    testWidgets('Note n + 409 perlu_konfirmasi → Ya, simpan tetap membawa note "n" dengan kunci baru', (tester) async {
      final server = serverAdmin();
      server.penangan['tambahdonasi'] = (r) async {
        if (isiJson(r)['konfirmasi'] == true) return jawabDibuat(tambahDonasiUji());
        return jawabGalat(409, 'perlu_konfirmasi', 'Periksa sebelum menyimpan.', {
          'alasan': ['Donatur nomor 1234 sudah tercatat menyumbang 1 kali hari ini.'],
          'donatur': {'id': 1234, 'nama': 'Fulan bin Fulan'},
        });
      };
      await pompaInput(tester, server);
      await cekNomor(tester, '1234');
      await ketuk(tester, find.byType(Checkbox));
      await ketuk(tester, tombol<FilledButton>('Simpan'));
      await tester.tap(tombol<FilledButton>('Ya, simpan'));
      await tester.pumpAndSettle();

      final kiriman = kirimanKe(server, 'tambahdonasi');
      expect(kiriman, hasLength(2));
      expect(isiJson(kiriman[1]), {'id_donatur': 1234, 'jumlah': 200000, 'konfirmasi': true, 'note': 'n'});
      expect(kiriman[1].headers['Idempotency-Key'], isNot(kiriman[0].headers['Idempotency-Key']));
    });

    testWidgets('selama menyimpan centang terkunci; diubah setelah galat jaringan → Kirim ulang hilang', (tester) async {
      final server = serverAdmin();
      final tahan = Completer<http.Response>();
      server.penangan['tambahdonasi'] = (r) => tahan.future;
      await pompaInput(tester, server);
      await cekNomor(tester, '1234');
      await tester.tap(tombol<FilledButton>('Simpan'));
      await tester.pump();
      expect(tester.widget<Checkbox>(find.byType(Checkbox)).onChanged, isNull);
      await tester.tap(labelNote());
      await tester.pump();
      expect(nilaiNote(tester), isTrue);

      tahan.completeError(http.ClientException('putus'));
      await tester.pumpAndSettle();
      expect(tombol<OutlinedButton>('Kirim ulang'), findsOneWidget);
      await ketuk(tester, find.byType(Checkbox));
      expect(tombol<OutlinedButton>('Kirim ulang'), findsNothing);

      server.penangan['tambahdonasi'] = (r) async => jawabDibuat(tambahDonasiUji());
      await ketuk(tester, tombol<FilledButton>('Simpan'));
      final kiriman = kirimanKe(server, 'tambahdonasi');
      expect(kiriman, hasLength(2));
      expect(kiriman[1].headers['Idempotency-Key'], isNot(kiriman[0].headers['Idempotency-Key']));
      expect(isiJson(kiriman[1])['note'], 'n');
    });

    testWidgets('360×640 dp, textScaler 1,3: centang sebaris Sumbangan tanpa luapan, juga dengan errorText', (tester) async {
      final server = serverAdmin();
      server.penangan['tambahdonasi'] = (r) async => jawabGalat(422, 'tidak_valid', 'Isian belum benar.', {
            'rincian': {'jumlah': 'Nominal sumbangan harus angka tanpa titik atau koma'},
          });
      await pompaInput(tester, server, layarKecil: true);
      await cekNomor(tester, '1234');
      // Kartu donatur di layar kecil mendorong Sumbangan keluar layar: gulir sampai centangnya terlihat.
      await tester.scrollUntilVisible(
        find.byType(Checkbox),
        100,
        scrollable: find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down).first,
      );
      expect(find.byType(Checkbox), findsOneWidget);
      expect(tester.takeException(), isNull);
      await ketuk(tester, tombol<FilledButton>('Simpan'));
      expect(galatIsian(tester, 'Sumbangan'), 'Nominal sumbangan harus angka tanpa titik atau koma');
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('360×640 dp, textScaler 1,3: kartu panjang, strip besar → tanpa luapan', (tester) async {
    final server = serverInput();
    server.penangan['konfigurasi'] = (r) async => jawabOk({
          ...konfigurasiUji(),
          'nominal_umum': [50000, 100000, 150000, 200000, 250000, 300000, 350000, 500000, 1000000, 2000000],
        });
    server.penangan['donatur'] = (r) async => jawabOk(donaturUji(
          nama: 'Hj. Siti Fatimah binti Haji Abdurrahman Kandangan',
          alamat: 'Jl. Brigjend H. Hasan Basry Gang Keluarga RT 04 Desa Kapuh, Kecamatan Simpur',
          noHp: '081234567890',
          keterangan: 'Ambil di rumah setiap Minggu pagi sesudah subuh',
          bintang: 5,
          riwayat: [
            for (var b = 1; b <= 10; b++)
              {'tanggal': '2026-${'$b'.padLeft(2, '0')}-02', 'waktu': '09:00:00', 'jumlah': 2000000},
          ],
          totalTahunIni: 20000000,
        ));
    server.penangan['tambahdonasi'] = (r) async => jawabDibuat(tambahDonasiUji(
          total: 123456789,
          transaksi: 128,
          terakhir: [
            for (var i = 0; i < 6; i++) {'id_donatur': 32760 + i, 'jumlah': 2000000, 'waktu': '09:15:02'},
          ],
        ));
    await pompaInput(tester, server, layarKecil: true);
    expect(tester.takeException(), isNull);

    await cekNomor(tester, '32767');
    // Gulir sampai nominal cepat terakhir; Simpan tetap di bawah tanpa digulir.
    expect(tombol<FilledButton>('Simpan'), findsOneWidget);
    await tester.scrollUntilVisible(
      tombol<OutlinedButton>('300.000'),
      200,
      scrollable: find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down).first,
    );
    expect(tester.takeException(), isNull);

    await ketuk(tester, tombol<FilledButton>('Simpan'));
    expect(find.byType(KartuHasil), findsOneWidget);
    expect(tester.takeException(), isNull);

    server.penangan['donatur'] =
        (r) async => jawabGalat(404, 'tidak_ada', 'Data Donator nomor 32766 tidak ditemukan!');
    await cekNomor(tester, '32766');
    expect(galatIsian(tester, 'Nomor Donator'), isNotNull);
    expect(tester.takeException(), isNull);
  });
}
