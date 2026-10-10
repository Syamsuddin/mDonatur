// Kriteria F5 (docs/23_ACCEPTANCE_CRITERIA.md), alur P3 (docs/06_BUSINESS_PROCESS.md), tempat tampil
// galat (docs/14_ERROR_HANDLING.md), dan empat state Tambah Donatur (docs/26_UI_CONVENTIONS.md).

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mdonator/layar/masuk.dart';
import 'package:mdonator/state/sesi.dart';
import 'package:mdonator/tema.dart';
import 'package:mdonator/widget/kartu_donatur.dart';
import 'package:mdonator/widget/kartu_hasil.dart';

import 'bantu.dart';

const _pesanEmoji = 'Gunakan huruf, angka, dan tanda baca biasa (tanpa emoji).';

Map<String, Object?> miripUji({bool lebih = false}) => {
      'hasil': [
        {'id': 1234, 'nama': 'Fulan bin Fulan', 'alamat': 'Desa Kapuh, Simpur'},
        {'id': 5678, 'nama': 'Fulanah', 'alamat': 'Kandangan'},
      ],
      'lebih': lebih,
    };

/// Mengisi formulir Tambah Donatur. Isian kosong tidak diketik.
Future<void> isiFormulir(
  WidgetTester tester, {
  String nama = 'Fulan bin Fulan',
  String alamat = 'Desa Kapuh, Simpur',
  String noHp = '',
  String keterangan = '',
  String sumbangan = '100000',
}) async {
  for (final (label, teks) in [
    ('Nama Donator', nama),
    ('Alamat', alamat),
    ('Nomor Handphone', noHp),
    ('Keterangan', keterangan),
    ('Sumbangan Pertama', sumbangan),
  ]) {
    if (teks.isNotEmpty) await tester.enterText(isian(label), teks);
  }
  await tester.pump();
}

bool simpanAktif(WidgetTester tester) =>
    tester.widget<FilledButton>(tombol<FilledButton>('Simpan')).onPressed != null;

Finder diDialog(String teks) =>
    find.descendant(of: find.byType(AlertDialog), matching: find.text(teks));

Map<String, Object?> isiJson(http.Request r) => jsonDecode(r.body) as Map<String, Object?>;

const _isiBawaan = {
  'nama': 'Fulan bin Fulan',
  'alamat': 'Desa Kapuh, Simpur',
  'no_hp': '',
  'keterangan': '',
  'sumbangan': 100000,
  'konfirmasi': false,
};

void main() {
  testWidgets('saat dibuka: formulir kosong, Simpan nonaktif, tanpa permintaan', (tester) async {
    final server = serverDonatur();
    await pompaTabDonatur(tester, server);

    expect(judulAppBar(tester), 'Tambah Donatur');
    for (final label in ['Nama Donator', 'Alamat', 'Nomor Handphone', 'Keterangan', 'Sumbangan Pertama']) {
      expect(teksIsian(tester, label), '', reason: label);
    }
    expect(simpanAktif(tester), isFalse);
    expect(find.text('Nama mirip'), findsNothing);
    expect(server.aksi, ['konfigurasi', 'donasisaya']);
  });

  group('nama mirip', () {
    testWidgets('Nama diketik huruf demi huruf → caridonatur sekali, 500 ms setelah ketikan terakhir', (tester) async {
      final server = serverDonatur();
      server.penangan['caridonatur'] = (r) async => jawabOk(miripUji(lebih: true));
      await pompaTabDonatur(tester, server);

      for (final teks in ['F', 'Fu', 'Ful', 'Fula', 'Fulan']) {
        await tester.enterText(isian('Nama Donator'), teks);
        await tester.pump(const Duration(milliseconds: 300));
      }
      await tester.pump(const Duration(milliseconds: 199));
      expect(kirimanKe(server, 'caridonatur'), isEmpty);
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pumpAndSettle();

      final cari = kirimanKe(server, 'caridonatur');
      expect(cari, hasLength(1));
      expect(cari.single.url.queryParameters['q'], 'Fulan');
      final judul = tester.widget<Text>(find.text('Nama mirip'));
      expect(judul.style?.color, Warna.teksPeringatan);
      // teksPeringatan hanya di atas latar putih: "Nama mirip" berada di dalam kartu (docs/26).
      expect(find.ancestor(of: find.text('Nama mirip'), matching: find.byType(Card)), findsOneWidget);
      expect(find.text('Fulan bin Fulan'), findsOneWidget);
      expect(find.text('1234 · Desa Kapuh, Simpur'), findsOneWidget);
      expect(find.text('5678 · Kandangan'), findsOneWidget);
      expect(tester.widget<Text>(find.text('Persempit pencarian')).style?.color, Warna.teksInfo);
    });

    testWidgets('Nama satu huruf → tanpa caridonatur; hasil kosong → tanpa peringatan', (tester) async {
      final server = serverDonatur();
      await pompaTabDonatur(tester, server);
      await tester.enterText(isian('Nama Donator'), 'F');
      await tester.pump(const Duration(seconds: 1));
      expect(kirimanKe(server, 'caridonatur'), isEmpty);

      await tester.enterText(isian('Nama Donator'), 'Zz');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      expect(kirimanKe(server, 'caridonatur'), hasLength(1));
      expect(find.text('Nama mirip'), findsNothing);
    });

    testWidgets('ketuk nama mirip → tab Input, nomor terisi, Cek otomatis; isian Tambah Donatur tetap', (tester) async {
      final server = serverDonatur();
      server.penangan['caridonatur'] = (r) async => jawabOk(miripUji());
      await pompaTabDonatur(tester, server);
      await isiFormulir(tester, nama: 'Fulan', keterangan: 'Ambil di rumah');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      await ketuk(tester, find.text('Fulan bin Fulan'));
      expect(judulAppBar(tester), 'Input Sumbangan');
      expect(teksIsian(tester, 'Nomor Donator'), '1234');
      expect(kirimanKe(server, 'donatur').single.url.queryParameters['id'], '1234');
      expect(find.byType(KartuDonatur), findsOneWidget);

      await pilihTab(tester, 'Donatur');
      expect(teksIsian(tester, 'Nama Donator'), 'Fulan');
      expect(teksIsian(tester, 'Alamat'), 'Desa Kapuh, Simpur');
      expect(teksIsian(tester, 'Keterangan'), 'Ambil di rumah');
      expect(teksIsian(tester, 'Sumbangan Pertama'), '100000');
      expect(kirimanKe(server, 'tambahdonatur'), isEmpty);
    });

    testWidgets('caridonatur gagal jaringan → panel Coba lagi → daftar tampil', (tester) async {
      final server = serverDonatur();
      server.penangan['caridonatur'] = (r) async => throw http.ClientException('putus');
      await pompaTabDonatur(tester, server);
      await tester.enterText(isian('Nama Donator'), 'Fulan');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      expect(find.text(TeksGalat.jaringanGet), findsOneWidget);

      server.penangan['caridonatur'] = (r) async => jawabOk(miripUji());
      await ketuk(tester, tombol<OutlinedButton>('Coba lagi'));
      expect(find.text(TeksGalat.jaringanGet), findsNothing);
      expect(find.text('Nama mirip'), findsOneWidget);
      expect(teksIsian(tester, 'Nama Donator'), 'Fulan');
    });
  });

  group('simpan', () {
    testWidgets('201 → kartu Nomor Register (32/40 tebal), isian kosong, strip tab Input diperbarui', (tester) async {
      final server = serverDonatur();
      await pompaTabDonatur(tester, server);
      expect(simpanAktif(tester), isFalse);
      await isiFormulir(tester);
      expect(simpanAktif(tester), isTrue);
      await ketuk(tester, tombol<FilledButton>('Simpan'));

      final kiriman = kirimanKe(server, 'tambahdonatur').single;
      expect(isiJson(kiriman), _isiBawaan);
      expect(kiriman.headers['Idempotency-Key'], matches(RegExp(r'^[0-9a-f-]{36}$')));

      final kartu = find.byType(KartuHasil);
      expect(kartu, findsOneWidget);
      for (final teks in [
        'Data Donatur Berhasil Disimpan',
        'Nomor Register',
        '7759',
        'Fulan bin Fulan',
        'Rp 100.000',
        '09:20 WITA',
      ]) {
        expect(find.descendant(of: kartu, matching: find.text(teks)), findsOneWidget, reason: teks);
      }
      final nomor = tester.widget<Text>(find.descendant(of: kartu, matching: find.text('7759')));
      expect(nomor.style?.fontSize, 32);
      expect(nomor.style?.height, 40 / 32);
      expect(nomor.style?.fontWeight, FontWeight.w800);
      expect(nomor.style?.fontFamily, Huruf.keluargaTampilan);

      for (final label in ['Nama Donator', 'Alamat', 'Nomor Handphone', 'Keterangan', 'Sumbangan Pertama']) {
        expect(teksIsian(tester, label), '', reason: label);
      }
      expect(simpanAktif(tester), isFalse);

      // Strip tab Input dari ringkasan_hari_ini, tanpa donasisaya ulang.
      await pilihTab(tester, 'Input');
      expect(ringkasanHariIni(tester), ('Rp 1.650.000', '11 transaksi'));
      expect(kirimanKe(server, 'donasisaya'), hasLength(1));
    });

    testWidgets('No HP dan Keterangan ikut terkirim; 2xx dengan "ulang": true diperlakukan sukses', (tester) async {
      final server = serverDonatur();
      server.penangan['tambahdonatur'] =
          (r) async => jawabJson(201, {'ok': true, 'ulang': true, 'data': tambahDonaturUji()});
      await pompaTabDonatur(tester, server);
      await isiFormulir(tester, noHp: '081234567890', keterangan: 'Ambil di rumah');
      await ketuk(tester, tombol<FilledButton>('Simpan'));

      expect(isiJson(kirimanKe(server, 'tambahdonatur').single),
          {..._isiBawaan, 'no_hp': '081234567890', 'keterangan': 'Ambil di rumah'});
      expect(find.byType(KartuHasil), findsOneWidget);
    });

    testWidgets('Sumbangan Pertama 500 → dialog lokal; Tidak → tanpa permintaan; Ya → terkirim', (tester) async {
      final server = serverDonatur();
      await pompaTabDonatur(tester, server);
      await isiFormulir(tester, sumbangan: '500');
      await ketuk(tester, tombol<FilledButton>('Simpan'));

      expect(diDialog('Nominal Rp 500 — benar?'), findsOneWidget);
      await tester.tap(tombol<TextButton>('Tidak'));
      await tester.pumpAndSettle();
      expect(kirimanKe(server, 'tambahdonatur'), isEmpty);
      expect(teksIsian(tester, 'Sumbangan Pertama'), '500');
      expect(tester.widget<TextField>(isian('Sumbangan Pertama')).focusNode!.hasFocus, isTrue);

      await ketuk(tester, tombol<FilledButton>('Simpan'));
      await tester.tap(tombol<FilledButton>('Ya, simpan'));
      await tester.pumpAndSettle();
      expect(isiJson(kirimanKe(server, 'tambahdonatur').single), {..._isiBawaan, 'sumbangan': 500});
    });

    testWidgets('Sumbangan Pertama 1.000 tidak memakai dialog lokal', (tester) async {
      final server = serverDonatur();
      await pompaTabDonatur(tester, server);
      await isiFormulir(tester, sumbangan: '1000');
      await ketuk(tester, tombol<FilledButton>('Simpan'));
      expect(find.byType(AlertDialog), findsNothing);
      expect(kirimanKe(server, 'tambahdonatur'), hasLength(1));
    });

    testWidgets('409 donatur_sudah_ada → nomor yang ada + "Input sumbangan untuk nomor ini"', (tester) async {
      final server = serverDonatur();
      server.penangan['tambahdonatur'] = (r) async =>
          jawabGalat(409, 'donatur_sudah_ada', 'Data Donator Sudah Ada!', {'id_donatur': 7759});
      await pompaTabDonatur(tester, server);
      await isiFormulir(tester);
      await ketuk(tester, tombol<FilledButton>('Simpan'));

      expect(find.text('Data Donator Sudah Ada!\nNomor Register: 7759'), findsOneWidget);
      expect(find.byType(KartuHasil), findsNothing);
      await ketuk(tester, tombol<OutlinedButton>('Input sumbangan untuk nomor ini'));

      expect(judulAppBar(tester), 'Input Sumbangan');
      expect(teksIsian(tester, 'Nomor Donator'), '7759');
      expect(kirimanKe(server, 'donatur').single.url.queryParameters['id'], '7759');
      expect(find.byType(KartuDonatur), findsOneWidget);

      await pilihTab(tester, 'Donatur');
      expect(teksIsian(tester, 'Nama Donator'), 'Fulan bin Fulan');
      expect(teksIsian(tester, 'Sumbangan Pertama'), '100000');
      expect(kirimanKe(server, 'tambahdonatur'), hasLength(1));
    });

    testWidgets('isian diubah setelah donatur_sudah_ada → panel hilang', (tester) async {
      final server = serverDonatur();
      server.penangan['tambahdonatur'] = (r) async =>
          jawabGalat(409, 'donatur_sudah_ada', 'Data Donator Sudah Ada!', {'id_donatur': 7759});
      await pompaTabDonatur(tester, server);
      await isiFormulir(tester);
      await ketuk(tester, tombol<FilledButton>('Simpan'));
      expect(tombol<OutlinedButton>('Input sumbangan untuk nomor ini'), findsOneWidget);

      await tester.enterText(isian('Keterangan'), 'Anak');
      await tester.pump();
      expect(tombol<OutlinedButton>('Input sumbangan untuk nomor ini'), findsNothing);
    });

    testWidgets('409 perlu_konfirmasi K9 → dialog alasan + nama; Ya → konfirmasi true dengan kunci baru', (tester) async {
      final server = serverDonatur();
      const alasan = ['Nominal di atas Rp. 5.000.000,-.'];
      server.penangan['tambahdonatur'] = (r) async {
        if (isiJson(r)['konfirmasi'] == true) return jawabDibuat(tambahDonaturUji(sumbangan: 6000000));
        return jawabGalat(409, 'perlu_konfirmasi', 'Periksa sebelum menyimpan.', {'alasan': alasan});
      };
      await pompaTabDonatur(tester, server);
      await isiFormulir(tester, sumbangan: '6000000');
      await ketuk(tester, tombol<FilledButton>('Simpan'));

      expect(diDialog('Periksa sebelum menyimpan.'), findsOneWidget);
      expect(diDialog('Fulan bin Fulan'), findsOneWidget);
      expect(diDialog(alasan.single), findsOneWidget);
      await tester.tap(tombol<FilledButton>('Ya, simpan'));
      await tester.pumpAndSettle();

      final kiriman = kirimanKe(server, 'tambahdonatur');
      expect(kiriman, hasLength(2));
      expect(isiJson(kiriman[0]), {..._isiBawaan, 'sumbangan': 6000000});
      expect(isiJson(kiriman[1]), {..._isiBawaan, 'sumbangan': 6000000, 'konfirmasi': true});
      expect(kiriman[1].headers['Idempotency-Key'], isNot(kiriman[0].headers['Idempotency-Key']));
      expect(find.byType(KartuHasil), findsOneWidget);
    });

    testWidgets('409 perlu_konfirmasi → Tidak: tanpa permintaan kedua, isian tetap', (tester) async {
      final server = serverDonatur();
      server.penangan['tambahdonatur'] = (r) async => jawabGalat(409, 'perlu_konfirmasi',
          'Periksa sebelum menyimpan.', {'alasan': ['Nominal di atas Rp. 5.000.000,-.']});
      await pompaTabDonatur(tester, server);
      await isiFormulir(tester, sumbangan: '6000000');
      await ketuk(tester, tombol<FilledButton>('Simpan'));
      await tester.tap(tombol<TextButton>('Tidak'));
      await tester.pumpAndSettle();

      expect(kirimanKe(server, 'tambahdonatur'), hasLength(1));
      expect(teksIsian(tester, 'Nama Donator'), 'Fulan bin Fulan');
      expect(teksIsian(tester, 'Sumbangan Pertama'), '6000000');
      expect(simpanAktif(tester), isTrue);
    });

    testWidgets('422 rincian.nama → errorText Nama Donator; isian lain tetap', (tester) async {
      final server = serverDonatur();
      server.penangan['tambahdonatur'] = (r) async => jawabGalat(422, 'tidak_valid', 'Isian belum benar.',
          {'rincian': {'nama': _pesanEmoji}});
      await pompaTabDonatur(tester, server);
      await isiFormulir(tester, nama: 'Fulan 😀', noHp: '0812');
      await ketuk(tester, tombol<FilledButton>('Simpan'));

      expect(galatIsian(tester, 'Nama Donator'), _pesanEmoji);
      for (final label in ['Alamat', 'Nomor Handphone', 'Keterangan', 'Sumbangan Pertama']) {
        expect(galatIsian(tester, label), isNull, reason: label);
      }
      expect(teksIsian(tester, 'Nama Donator'), 'Fulan 😀');
      expect(teksIsian(tester, 'Alamat'), 'Desa Kapuh, Simpur');
      expect(teksIsian(tester, 'Nomor Handphone'), '0812');
      expect(teksIsian(tester, 'Sumbangan Pertama'), '100000');
      expect(find.text('Isian belum benar.'), findsNothing);

      await tester.enterText(isian('Nama Donator'), 'Fulan');
      await tester.pump();
      expect(galatIsian(tester, 'Nama Donator'), isNull);
    });

    testWidgets('422 semua isian sekaligus → errorText masing-masing; kunci tanpa isian → panel', (tester) async {
      final server = serverDonatur();
      server.penangan['tambahdonatur'] = (r) async => jawabGalat(422, 'tidak_valid', 'Isian belum benar.', {
            'rincian': {
              'nama': 'Nama donatur kosong.',
              'alamat': 'Alamat donatur kosong.',
              'no_hp': 'Nomor HP terlalu panjang (maks. 20 karakter).',
              'keterangan': 'Keterangan terlalu panjang (maks. 255 karakter).',
              'sumbangan': 'Nominal sumbangan kosong.',
              'lain': 'Isian lain salah.',
            },
          });
      await pompaTabDonatur(tester, server);
      await isiFormulir(tester, nama: '', alamat: '');
      await ketuk(tester, tombol<FilledButton>('Simpan'));

      expect(galatIsian(tester, 'Nama Donator'), 'Nama donatur kosong.');
      expect(galatIsian(tester, 'Alamat'), 'Alamat donatur kosong.');
      expect(galatIsian(tester, 'Nomor Handphone'), 'Nomor HP terlalu panjang (maks. 20 karakter).');
      expect(galatIsian(tester, 'Keterangan'), 'Keterangan terlalu panjang (maks. 255 karakter).');
      expect(galatIsian(tester, 'Sumbangan Pertama'), 'Nominal sumbangan kosong.');
      expect(find.text('Isian lain salah.'), findsOneWidget);
    });

    testWidgets('timeout → panel Kirim ulang; kiriman ulang dengan kunci dan isi sama persis', (tester) async {
      final server = serverDonatur();
      final tidakPernah = Completer<http.Response>();
      server.penangan['tambahdonatur'] = (r) => tidakPernah.future;
      await pompaTabDonatur(tester, server);
      await isiFormulir(tester);
      await tester.tap(tombol<FilledButton>('Simpan'));
      await tester.pump();

      // Memuat: Simpan nonaktif dengan indikator, isian terkunci.
      final simpan = find.ancestor(
          of: find.byType(CircularProgressIndicator), matching: find.byType(FilledButton));
      expect(tester.widget<FilledButton>(simpan).onPressed, isNull);
      for (final label in ['Nama Donator', 'Alamat', 'Sumbangan Pertama']) {
        expect(tester.widget<TextField>(isian(label)).enabled, isFalse, reason: label);
      }

      await tester.pump(const Duration(seconds: 21));
      await tester.pumpAndSettle();
      expect(find.text(TeksGalat.jaringanPost), findsOneWidget);
      expect(teksIsian(tester, 'Nama Donator'), 'Fulan bin Fulan');
      expect(teksIsian(tester, 'Sumbangan Pertama'), '100000');

      server.penangan['tambahdonatur'] = (r) async => jawabDibuat(tambahDonaturUji());
      await ketuk(tester, tombol<OutlinedButton>('Kirim ulang'));

      final kiriman = kirimanKe(server, 'tambahdonatur');
      expect(kiriman, hasLength(2));
      expect(kiriman[1].headers['Idempotency-Key'], kiriman[0].headers['Idempotency-Key']);
      expect(kiriman[1].bodyBytes, kiriman[0].bodyBytes);
      expect(find.byType(KartuHasil), findsOneWidget);
    });

    testWidgets('isian diubah setelah galat jaringan → Kirim ulang hilang; Simpan memakai kunci baru', (tester) async {
      final server = serverDonatur();
      server.penangan['tambahdonatur'] = (r) async => throw http.ClientException('putus');
      await pompaTabDonatur(tester, server);
      await isiFormulir(tester);
      await ketuk(tester, tombol<FilledButton>('Simpan'));
      expect(tombol<OutlinedButton>('Kirim ulang'), findsOneWidget);

      await tester.enterText(isian('Alamat'), 'Kandangan');
      await tester.pump();
      expect(tombol<OutlinedButton>('Kirim ulang'), findsNothing);

      server.penangan['tambahdonatur'] = (r) async => jawabDibuat(tambahDonaturUji());
      await ketuk(tester, tombol<FilledButton>('Simpan'));
      final kiriman = kirimanKe(server, 'tambahdonatur');
      expect(kiriman, hasLength(2));
      expect(kiriman[1].headers['Idempotency-Key'], isNot(kiriman[0].headers['Idempotency-Key']));
      expect(isiJson(kiriman[1])['alamat'], 'Kandangan');
    });

    testWidgets('500 galat_server → pesan umum + Coba lagi dengan kunci sama', (tester) async {
      final server = serverDonatur();
      server.penangan['tambahdonatur'] =
          (r) async => jawabGalat(500, 'galat_server', 'Terjadi galat di server.');
      await pompaTabDonatur(tester, server);
      await isiFormulir(tester);
      await ketuk(tester, tombol<FilledButton>('Simpan'));
      expect(find.text(TeksGalat.umum), findsOneWidget);

      server.penangan['tambahdonatur'] = (r) async => jawabDibuat(tambahDonaturUji());
      await ketuk(tester, tombol<OutlinedButton>('Coba lagi'));
      final kiriman = kirimanKe(server, 'tambahdonatur');
      expect(kiriman[1].headers['Idempotency-Key'], kiriman[0].headers['Idempotency-Key']);
      expect(find.byType(KartuHasil), findsOneWidget);
    });

    testWidgets('401 saat Simpan → Masuk di atas kerangka; setelah masuk isian masih ada', (tester) async {
      final server = serverDonatur();
      server.penangan['tambahdonatur'] = (r) async =>
          jawabGalat(401, 'token_kedaluwarsa', 'Sesi berakhir. Silakan masuk lagi.');
      await pompaTabDonatur(tester, server);
      await isiFormulir(tester, keterangan: 'Anak yatim');
      await ketuk(tester, tombol<FilledButton>('Simpan'));
      expect(find.byType(LayarMasuk), findsOneWidget);
      expect(find.text('Sesi berakhir. Silakan masuk lagi.'), findsOneWidget);

      server.penangan['tambahdonatur'] = (r) async => jawabDibuat(tambahDonaturUji());
      await isiDanMasuk(tester);
      expect(find.byType(LayarMasuk), findsNothing);
      expect(judulAppBar(tester), 'Tambah Donatur');
      expect(teksIsian(tester, 'Nama Donator'), 'Fulan bin Fulan');
      expect(teksIsian(tester, 'Keterangan'), 'Anak yatim');
      expect(teksIsian(tester, 'Sumbangan Pertama'), '100000');

      await ketuk(tester, tombol<FilledButton>('Simpan'));
      final kiriman = kirimanKe(server, 'tambahdonatur');
      expect(kiriman, hasLength(2));
      expect(kiriman[1].headers['Authorization'], 'Bearer $tokenUji');
      expect(find.byType(KartuHasil), findsOneWidget);
    });

    testWidgets('Keluar dengan isian Tambah Donatur yang belum disimpan → dialog', (tester) async {
      await pompaTabDonatur(tester, serverDonatur());
      await tester.enterText(isian('Alamat'), 'Kandangan');
      await tester.tap(find.byTooltip('Menu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Keluar'));
      await tester.pumpAndSettle();
      expect(diDialog('Isian yang belum disimpan akan hilang. Keluar?'), findsOneWidget);
    });
  });

  testWidgets('360×640 dp, textScaler 1,3: nama mirip, panel sudah ada, kartu hasil → tanpa luapan', (tester) async {
    final server = serverDonatur();
    server.penangan['caridonatur'] = (r) async => jawabOk({
          'hasil': [
            for (var i = 0; i < 20; i++)
              {
                'id': 32700 + i,
                'nama': 'Hj. Siti Fatimah binti Haji Abdurrahman Kandangan $i',
                'alamat': 'Jl. Brigjend H. Hasan Basry Gang Keluarga RT 04 Desa Kapuh, Kecamatan Simpur',
              },
          ],
          'lebih': true,
        });
    server.penangan['tambahdonatur'] = (r) async =>
        jawabGalat(409, 'donatur_sudah_ada', 'Data Donator Sudah Ada!', {'id_donatur': 32767});
    await pompaTabDonatur(tester, server, layarKecil: true);
    expect(tester.takeException(), isNull);

    await isiFormulir(
      tester,
      nama: 'Hj. Siti Fatimah binti Haji Abdurrahman Kandangan',
      alamat: 'Jl. Brigjend H. Hasan Basry Gang Keluarga RT 04 Desa Kapuh, Kecamatan Simpur',
      noHp: '081234567890',
      keterangan: 'Ambil di rumah setiap Minggu pagi sesudah subuh',
      sumbangan: '2000000',
    );
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(find.text('Nama mirip'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Simpan tetap di bawah tanpa digulir; panel dengan tombol panjang tidak meluap.
    await ketuk(tester, tombol<FilledButton>('Simpan'));
    expect(tombol<OutlinedButton>('Input sumbangan untuk nomor ini'), findsOneWidget);
    expect(tester.takeException(), isNull);

    server.penangan['tambahdonatur'] = (r) async => jawabDibuat(tambahDonaturUji(
          id: 32767,
          nama: 'Hj. Siti Fatimah binti Haji Abdurrahman Kandangan',
          sumbangan: 2000000000,
        ));
    // Daftar nama mirip yang panjang mendorong Keterangan ke bawah: gulir sampai terlihat.
    await tester.scrollUntilVisible(
      isian('Keterangan'),
      300,
      scrollable: find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down).first,
    );
    await tester.enterText(isian('Keterangan'), 'Anak');
    await ketuk(tester, tombol<FilledButton>('Simpan'));
    expect(find.byType(KartuHasil), findsOneWidget);
    expect(find.text('32767'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
