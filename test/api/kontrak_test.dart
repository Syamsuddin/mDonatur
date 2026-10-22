// Kepatuhan kontrak tanpa server (docs/13_TESTING.md): setiap blok ```json di API_CONTRACT.md
// §5–§6 harus terbaca oleh model aksi pada bagiannya. Kontrak berubah → uji ini memaksa
// model, daftar aksi, katalog kode, dan versiKontrak ikut berubah.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mdonator/api/galat_api.dart';
import 'package:mdonator/api/klien_api.dart';
import 'package:mdonator/api/model.dart';

final _kontrak = File('API_CONTRACT.md').readAsStringSync();

/// Model jawaban per bagian kontrak §6.
final _pembaca = <String, Object Function(Json)>{
  '6.1': JawabanLogin.fromJson,
  '6.2': Konfigurasi.fromJson,
  '6.3': Donatur.fromJson,
  '6.4': HasilCariDonatur.fromJson,
  '6.5': JawabanTambahDonasi.fromJson,
  '6.6': JawabanTambahDonatur.fromJson,
  '6.7': DonasiSaya.fromJson,
  '6.8': JawabanUbahDonasi.fromJson,
  '6.9': Rekap.fromJson,
  '6.10': JawabanGantiPassword.fromJson,
};

/// Semua blok ```json di §5–§6 beserta nomor bagiannya.
List<({String bagian, Json isi})> _blokJson() {
  final hasil = <({String bagian, Json isi})>[];
  final baris = const LineSplitter().convert(_kontrak);
  var bagian = '';
  for (var i = 0; i < baris.length; i++) {
    final judul = RegExp(r'^#{2,3} (\d+(?:\.\d+)?)[. ]').firstMatch(baris[i]);
    if (judul != null) {
      bagian = judul.group(1)!;
    } else if (baris[i].trim() == '```json') {
      final isi = StringBuffer();
      for (i++; baris[i].trim() != '```'; i++) {
        isi.writeln(baris[i]);
      }
      hasil.add((bagian: bagian, isi: jsonDecode(isi.toString()) as Json));
    }
  }
  return [for (final b in hasil) if (b.bagian == '5' || b.bagian.startsWith('6.')) b];
}

/// Baris tabel Markdown di antara dua judul bagian, sebagai daftar sel.
List<List<String>> _tabel(String dariJudul, String sampaiJudul) {
  final awal = _kontrak.indexOf(dariJudul);
  final akhir = _kontrak.indexOf(sampaiJudul, awal);
  expect(awal, isNonNegative, reason: 'judul "$dariJudul" tidak ada di kontrak');
  return [
    for (final b in const LineSplitter().convert(_kontrak.substring(awal, akhir)))
      if (b.startsWith('|') && !b.startsWith('|---') && !b.startsWith('|:-'))
        b.substring(1, b.length - 1).split('|').map((s) => s.trim()).toList(),
  ];
}

Json _contoh(String bagian, {bool ok = true}) =>
    _blokJson().firstWhere((b) => b.bagian == bagian && b.isi['ok'] == ok).isi;

Json _data(String bagian) => Amplop.fromJson(_contoh(bagian)).data;

void main() {
  group('setiap contoh JSON §5–§6 terbaca model', () {
    final blok = _blokJson();

    test('contoh ditemukan untuk semua aksi yang punya blok JSON', () {
      expect(
        blok.map((b) => b.bagian).toSet(),
        containsAll(['5', '6.1', '6.2', '6.3', '6.4', '6.5', '6.6', '6.7', '6.9']),
      );
    });

    for (final (indeks, b) in blok.indexed) {
      test('blok ${indeks + 1} (§${b.bagian})', () {
        final amplop = Amplop.fromJson(b.isi);
        if (!amplop.ok) {
          final galat = galatApiFromJson(409, b.isi);
          expect(KodeGalat.semua, contains(galat.kode));
          expect(galat.pesan, isNotEmpty);
        } else if (b.bagian == '5') {
          expect(amplop.data, isEmpty);
        } else {
          final baca = _pembaca[b.bagian];
          expect(baca, isNotNull, reason: '§${b.bagian} punya contoh JSON tetapi belum punya model');
          expect(baca!(amplop.data), isNotNull);
        }
      });
    }
  });

  group('isi contoh terbaca dengan benar', () {
    test('§5 galat tidak_valid membawa rincian', () {
      final galat = galatApiFromJson(422, _contoh('5', ok: false));
      expect(galat.kode, KodeGalat.tidakValid);
      expect(galat.pesan, 'Isian belum benar.');
      expect(galat.rincian, {'jumlah': 'Nominal sumbangan Kosong'});
    });

    test('§6.1 login', () {
      final jawaban = JawabanLogin.fromJson(_data('6.1'));
      expect(jawaban.token, isNotEmpty);
      expect(jawaban.kedaluwarsa, '2026-10-13T00:15:00+08:00');
      expect(jawaban.pengguna.id, 6);
      expect(jawaban.pengguna.username, 'operator1');
      expect(jawaban.pengguna.peran, 'operator');
    });

    test('§6.2 konfigurasi', () {
      final k = Konfigurasi.fromJson(_data('6.2'));
      expect(k.versiApi, versiKontrak);
      expect(k.hariIni, DateTime.utc(2026, 10, 12));
      expect(k.zonaWaktu, 'Asia/Makassar');
      expect(k.nominalUmum, hasLength(10));
      expect(k.nominalUmum.first, 50000);
      expect(k.nominalUmum.last, 2000000);
      expect(k.nominalKonfirmasi, 5000000);
      expect(k.pengguna.peran, 'operator');
      expect(k.bolehAturNote, isFalse);
    });

    test('§6.3 donatur', () {
      final d = Donatur.fromJson(_data('6.3'));
      expect(d.id, 1234);
      expect(d.nama, 'Fulan bin Fulan');
      expect(d.keterangan, '');
      expect(d.bintang, 2);
      expect(d.tahun, 2026);
      expect(d.riwayat.single.tanggal, DateTime.utc(2026, 1, 4));
      expect(d.riwayat.single.waktu, '09:12:40');
      expect(d.riwayat.single.jumlah, 200000);
      expect(d.riwayat.single.noteN, isFalse);
      expect(d.totalTahunIni, 200000);
      expect(d.saranJumlah, 200000);
    });

    test('§6.4 caridonatur', () {
      final h = HasilCariDonatur.fromJson(_data('6.4'));
      expect(h.hasil.single.id, 1234);
      expect(h.hasil.single.alamat, 'Desa Kapuh, Simpur');
      expect(h.lebih, isFalse);
    });

    test('§6.5 tambahdonasi 201 dan 409', () {
      final j = JawabanTambahDonasi.fromJson(_data('6.5'));
      expect(j.sumbangan.id, 145437);
      expect(j.sumbangan.namaDonatur, 'Fulan bin Fulan');
      expect(j.sumbangan.waktu, '09:15:02');
      expect(j.ringkasanHariIni.total, 1450000);
      expect(j.ringkasanHariIni.transaksi, 9);
      expect(j.ringkasanHariIni.terakhir.single.idDonatur, 1234);

      final galat = galatApiFromJson(409, _contoh('6.5', ok: false));
      expect(galat.kode, KodeGalat.perluKonfirmasi);
      expect(galat.alasan.single, contains('sudah tercatat menyumbang 1 kali hari ini'));
      expect(galat.donatur?.id, 1234);
      expect(galat.donatur?.nama, 'Fulan bin Fulan');
    });

    test('§6.6 tambahdonatur', () {
      final j = JawabanTambahDonatur.fromJson(_data('6.6'));
      expect(j.donatur.id, 7759);
      expect(j.donatur.noHp, '');
      expect(j.sumbangan.idDonatur, 7759);
      expect(j.sumbangan.jumlah, 100000);
      expect(j.ringkasanHariIni.terakhir.map((t) => t.idDonatur), [7759, 1234]);
    });

    test('§6.7 donasisaya', () {
      final d = DonasiSaya.fromJson(_data('6.7'));
      expect(d.tanggal, DateTime.utc(2026, 10, 12));
      expect(d.total, 1550000);
      expect(d.transaksi, 10);
      expect(d.daftar.single.bolehUbah, isTrue);
      expect(d.daftar.single.bolehHapus, isFalse);
      expect(d.daftar.single.noteN, isFalse);
      expect(d.daftar.single.namaDonatur, 'Fulan bin Fulan');
    });

    test('§6.9 rekap', () {
      final r = Rekap.fromJson(_data('6.9'));
      expect(r.periode, Periode.minggu);
      expect(r.cakupan, Cakupan.semua);
      expect(r.dari, DateTime.utc(2026, 10, 5));
      expect(r.sampai, DateTime.utc(2026, 10, 11));
      expect(r.total, 27000000);
      expect(r.transaksi, 146);
      expect(r.donatur, 139);
      expect(r.perHari.map((h) => h.tanggal), [DateTime.utc(2026, 10, 5), DateTime.utc(2026, 10, 8)]);
      expect(r.perOperator, hasLength(3));
      expect(r.perOperator.last.idUser, isNull);
      expect(r.perOperator.last.nama, 'User lama (sudah dihapus)');
      expect(r.navigasi.sebelum, DateTime.utc(2026, 9, 28));
      expect(r.navigasi.sesudah, DateTime.utc(2026, 10, 12));
    });
  });

  group('kode mengikuti kontrak', () {
    test('versiKontrak sama dengan versi kontrak dan manifest', () {
      final versiDokumen = RegExp(r'\*\*Versi kontrak: ([0-9.]+)\*\*').firstMatch(_kontrak)?.group(1);
      expect(versiDokumen, versiKontrak);
      final manifest = jsonDecode(File('docs/_MANIFEST.json').readAsStringSync()) as Json;
      final split = (manifest['requirements'] as Json)['split'] as Json;
      expect(split['contract_version'], versiKontrak);
    });

    test('daftar aksi §6 sama dengan enum Aksi (nama, metode, token, kunci)', () {
      final baris = _tabel('| Aksi | Metode |', '### 6.1');
      final dariKontrak = {
        for (final sel in baris.skip(1))
          sel[0].replaceAll('`', ''): (sel[1], sel[2] == '✓', sel[3] == 'wajib'),
      };
      final dariKode = {
        for (final a in Aksi.values) a.name: (a.metode.name.toUpperCase(), a.bertoken, a.berkunci),
      };
      expect(dariKode, dariKontrak);
    });

    test('katalog kode galat §8 sama dengan KodeGalat.semua', () {
      final baris = _tabel('## 8. Katalog kode galat', '## 9.');
      final kode = {
        for (final sel in baris.skip(1))
          if (sel[1].startsWith('`')) sel[1].replaceAll('`', ''),
      };
      expect(KodeGalat.semua, kode);
    });
  });
}
