// Uji unit KlienApi dengan MockClient, tanpa jaringan (docs/13_TESTING.md §Unit API).

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mdonator/api/galat_api.dart';
import 'package:mdonator/api/klien_api.dart';
import 'package:mdonator/api/model.dart';

const alamatUji = 'https://contoh.org/donatur';
const tokenUji = 'tkn-uji-123';
const passwordUji = 'sandi-uji-456';

http.Response jawabJson(int status, Object isi, {String? versi = versiKontrak}) => http.Response(
      jsonEncode(isi),
      status,
      headers: {
        'content-type': 'application/json; charset=utf-8',
        'x-api-versi': ?versi,
      },
    );

http.Response jawabGalat(int status, String kode, [Json tambahan = const {}]) =>
    jawabJson(status, {'ok': false, 'kode': kode, 'pesan': 'Pesan uji', ...tambahan});

const sumbanganUji = {
  'id': 145437,
  'id_donatur': 1234,
  'nama_donatur': 'Fulan Uji',
  'tanggal': '2026-10-12',
  'waktu': '09:15:02',
  'jumlah': 200000,
};

const ringkasanUji = {
  'tanggal': '2026-10-12',
  'total': 200000,
  'transaksi': 1,
  'terakhir': [
    {'id_donatur': 1234, 'jumlah': 200000, 'waktu': '09:15:02'},
  ],
};

const konfigurasiUji = {
  'versi_api': versiKontrak,
  'hari_ini': '2026-10-12',
  'zona_waktu': 'Asia/Makassar',
  'nominal_umum': [50000, 100000],
  'nominal_konfirmasi': 5000000,
  'pengguna': {'id': 6, 'username': 'operator1', 'peran': 'operator'},
};

KlienApi buatKlien(
  MockClientHandler penangan, {
  void Function(GalatApi)? padaTidakSah,
  Duration batas = const Duration(seconds: 20),
}) =>
    KlienApi(
      alamatServer: alamatUji,
      token: tokenUji,
      padaTidakSah: padaTidakSah,
      klien: MockClient(penangan),
      batasPermintaan: batas,
    );

/// Memanggil satu aksi dengan isi contoh. Switch lengkap: aksi baru di enum memaksa uji ini diperbarui.
Future<Object> panggil(KlienApi api, Aksi aksi) => switch (aksi) {
      Aksi.login => api.login(const PermintaanLogin(username: 'operator1', password: passwordUji)),
      Aksi.konfigurasi => api.konfigurasi(),
      Aksi.donatur => api.donatur(1234),
      Aksi.caridonatur => api.cariDonatur('Fulan'),
      Aksi.tambahdonasi =>
        api.tambahDonasi(Kiriman(const PermintaanTambahDonasi(idDonatur: 1234, jumlah: 200000))),
      Aksi.tambahdonatur => api.tambahDonatur(Kiriman(const PermintaanTambahDonatur(
          nama: 'Fulan Uji', alamat: 'Desa Uji', noHp: '081234567890', sumbangan: 100000))),
      Aksi.donasisaya => api.donasiSaya(),
      Aksi.ubahdonasi => api.ubahDonasi(Kiriman(const PermintaanUbahDonasi(id: 145437, jumlah: 150000))),
      Aksi.rekap => api.rekap(const PermintaanRekap(periode: Periode.hari)),
      Aksi.gantipassword => api.gantiPassword(
          const PermintaanGantiPassword(lama: passwordUji, baru: 'sandi-baru-789', ulang: 'sandi-baru-789')),
    };

final polaUuidV4 = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$');

void main() {
  late List<String> log;
  late DebugPrintCallback debugPrintAsli;

  setUp(() {
    log = [];
    debugPrintAsli = debugPrint;
    debugPrint = (String? pesan, {int? wrapWidth}) => log.add(pesan ?? '');
  });
  tearDown(() => debugPrint = debugPrintAsli);

  group('alamat, metode, dan header', () {
    for (final aksi in Aksi.values) {
      test('${aksi.name}: hanya header yang diwajibkan kontrak', () async {
        late http.Request diterima;
        final api = buatKlien((r) async {
          diterima = r;
          return jawabGalat(422, KodeGalat.tidakValid);
        });
        await expectLater(panggil(api, aksi), throwsA(isA<GalatApi>()));

        expect(diterima.method, aksi.metode.name.toUpperCase());
        expect(diterima.url.path, '/donatur/api');
        expect(diterima.url.queryParameters['aksi'], aksi.name);
        expect(diterima.headers['Authorization'], aksi.bertoken ? 'Bearer $tokenUji' : isNull);
        expect(diterima.headers['Content-Type'],
            aksi.metode == MetodeHttp.post ? 'application/json' : isNull);
        expect(diterima.headers.containsKey('Idempotency-Key'), aksi.berkunci);
        if (aksi.metode == MetodeHttp.get) expect(diterima.body, isEmpty);
      });
    }

    test('garis miring di akhir alamat server diabaikan', () async {
      late Uri diterima;
      final api = KlienApi(
        alamatServer: '$alamatUji/',
        token: tokenUji,
        klien: MockClient((r) async {
          diterima = r.url;
          return jawabJson(200, {'ok': true, 'data': konfigurasiUji});
        }),
      );
      await api.konfigurasi();
      expect(diterima.toString(), '$alamatUji/api?aksi=konfigurasi');
    });

    test('parameter GET mengikuti kontrak', () async {
      final diterima = <Map<String, String>>[];
      final api = buatKlien((r) async {
        diterima.add(r.url.queryParameters);
        return jawabGalat(422, KodeGalat.tidakValid);
      });
      Future<void> coba(Future<Object> f) => expectLater(f, throwsA(isA<GalatApi>()));

      await coba(api.donatur(1234));
      await coba(api.cariDonatur('Fulan bin%_'));
      await coba(api.donasiSaya());
      await coba(api.donasiSaya(tanggal: DateTime.utc(2026, 10, 12)));
      await coba(api.rekap(PermintaanRekap(
          periode: Periode.minggu, tanggal: DateTime.utc(2026, 10, 8), cakupan: Cakupan.semua)));

      expect(diterima, [
        {'aksi': 'donatur', 'id': '1234'},
        {'aksi': 'caridonatur', 'q': 'Fulan bin%_'},
        {'aksi': 'donasisaya'},
        {'aksi': 'donasisaya', 'tanggal': '2026-10-12'},
        {'aksi': 'rekap', 'periode': 'minggu', 'tanggal': '2026-10-08', 'cakupan': 'semua'},
      ]);
    });

    test('isi POST berupa bilangan bulat JSON, tanpa id_user/note/tanggal/waktu', () async {
      final isi = <Json>[];
      final api = buatKlien((r) async {
        isi.add(jsonDecode(r.body) as Json);
        return jawabGalat(422, KodeGalat.tidakValid);
      });
      for (final aksi in [Aksi.login, Aksi.tambahdonasi, Aksi.tambahdonatur, Aksi.ubahdonasi]) {
        await expectLater(panggil(api, aksi), throwsA(isA<GalatApi>()));
      }
      expect(isi[0], {'username': 'operator1', 'password': passwordUji});
      expect(isi[1], {'id_donatur': 1234, 'jumlah': 200000, 'konfirmasi': false});
      expect(isi[2], {
        'nama': 'Fulan Uji',
        'alamat': 'Desa Uji',
        'no_hp': '081234567890',
        'keterangan': '',
        'sumbangan': 100000,
        'konfirmasi': false,
      });
      expect(isi[3], {'id': 145437, 'jumlah': 150000, 'konfirmasi': false});
      for (final i in isi) {
        expect(i.keys, isNot(anyOf(contains('id_user'), contains('note'), contains('tanggal'), contains('waktu'))));
      }
    });

    test('tanpa token, header Authorization tidak dikirim', () async {
      late http.Request diterima;
      final api = KlienApi(
        alamatServer: alamatUji,
        klien: MockClient((r) async {
          diterima = r;
          return jawabGalat(401, KodeGalat.tokenTidakSah);
        }),
      );
      await expectLater(api.konfigurasi(), throwsA(isA<GalatApi>()));
      expect(diterima.headers.containsKey('Authorization'), isFalse);
    });
  });

  group('kunci kirim ulang (kontrak §7)', () {
    test('kunci berbentuk UUID v4 dan baru untuk setiap simpan', () {
      const isi = PermintaanTambahDonasi(idDonatur: 1234, jumlah: 200000);
      final kunci = {for (var i = 0; i < 50; i++) Kiriman(isi).kunci};
      expect(kunci, hasLength(50));
      for (final k in kunci) {
        expect(k, matches(polaUuidV4));
        expect(k, matches(RegExp(r'^[A-Za-z0-9-]{8,64}$')));
      }
    });

    test('dua simpan berturut-turut mengirim kunci berbeda', () async {
      final kunci = <String?>[];
      final api = buatKlien((r) async {
        kunci.add(r.headers['Idempotency-Key']);
        return jawabJson(201, {'ok': true, 'data': {'sumbangan': sumbanganUji, 'ringkasan_hari_ini': ringkasanUji}});
      });
      const isi = PermintaanTambahDonasi(idDonatur: 1234, jumlah: 200000);
      await api.tambahDonasi(Kiriman(isi));
      await api.tambahDonasi(Kiriman(isi));
      expect(kunci, hasLength(2));
      expect(kunci[0], isNot(kunci[1]));
    });

    test('Kirim ulang setelah timeout memakai kunci dan isi yang sama', () async {
      final kunci = <String?>[];
      final isi = <String>[];
      var ke = 0;
      final api = buatKlien(batas: const Duration(milliseconds: 50), (r) async {
        kunci.add(r.headers['Idempotency-Key']);
        isi.add(r.body);
        if (ke++ == 0) await Future<void>.delayed(const Duration(milliseconds: 300));
        return jawabJson(201, {'ok': true, 'data': {'sumbangan': sumbanganUji, 'ringkasan_hari_ini': ringkasanUji}});
      });
      final kiriman = Kiriman(const PermintaanTambahDonasi(idDonatur: 1234, jumlah: 200000));

      await expectLater(api.tambahDonasi(kiriman), throwsA(isA<GalatJaringan>()));
      expect(kunci, hasLength(1), reason: 'POST tidak boleh diulang otomatis');

      final jawaban = await api.tambahDonasi(kiriman);
      expect(jawaban.sumbangan.id, 145437);
      expect(kunci, [kiriman.kunci, kiriman.kunci]);
      expect(isi[0], isi[1]);
    });

    test('"Ya, simpan" setelah 409 mengirim konfirmasi: true dengan kunci baru', () async {
      final diterima = <http.Request>[];
      final api = buatKlien((r) async {
        diterima.add(r);
        final isi = jsonDecode(r.body) as Json;
        return isi['konfirmasi'] == true
            ? jawabJson(201, {'ok': true, 'data': {'sumbangan': sumbanganUji, 'ringkasan_hari_ini': ringkasanUji}})
            : jawabGalat(409, KodeGalat.perluKonfirmasi, {'alasan': ['K5'], 'donatur': {'id': 1234, 'nama': 'Fulan Uji'}});
      });
      const isi = PermintaanTambahDonasi(idDonatur: 1234, jumlah: 200000);

      await expectLater(api.tambahDonasi(Kiriman(isi)), throwsA(isA<GalatApi>()));
      await api.tambahDonasi(Kiriman(isi.denganKonfirmasi()));

      expect(diterima[0].headers['Idempotency-Key'], isNot(diterima[1].headers['Idempotency-Key']));
      expect((jsonDecode(diterima[1].body) as Json)['konfirmasi'], isTrue);
      expect((jsonDecode(diterima[1].body) as Json)['id_donatur'], 1234);
    });

    test('galat 500 tidak memicu kiriman ulang otomatis', () async {
      var jumlahKiriman = 0;
      final api = buatKlien((r) async {
        jumlahKiriman++;
        return jawabGalat(500, KodeGalat.galatServer);
      });
      await expectLater(panggil(api, Aksi.ubahdonasi), throwsA(isA<GalatApi>()));
      expect(jumlahKiriman, 1);
    });
  });

  group('jawaban sukses', () {
    test('"ulang": true dianggap sukses', () async {
      final api = buatKlien((r) async => jawabJson(201, {
            'ok': true,
            'ulang': true,
            'data': {'sumbangan': sumbanganUji, 'ringkasan_hari_ini': ringkasanUji},
          }));
      final jawaban =
          await api.tambahDonasi(Kiriman(const PermintaanTambahDonasi(idDonatur: 1234, jumlah: 200000)));
      expect(jawaban.sumbangan.jumlah, 200000);
      expect(jawaban.ringkasanHariIni.transaksi, 1);
    });

    test('field jawaban yang tidak dikenal diabaikan', () async {
      final api = buatKlien((r) async => jawabJson(200, {
            'ok': true,
            'baru_di_amplop': 1,
            'data': {
              ...konfigurasiUji,
              'field_baru': 'x',
              'pengguna': {'id': 6, 'username': 'operator1', 'peran': 'operator', 'nama_lengkap': 'x'},
            },
          }));
      final konfigurasi = await api.konfigurasi();
      expect(konfigurasi.hariIni, DateTime.utc(2026, 10, 12));
      expect(konfigurasi.pengguna.username, 'operator1');
    });

    test('ubahdonasi membaca boleh_ubah di dalam sumbangan', () async {
      final api = buatKlien((r) async => jawabJson(200, {
            'ok': true,
            'data': {
              'sumbangan': {...sumbanganUji, 'jumlah': 150000, 'boleh_ubah': true},
            },
          }));
      final jawaban =
          await api.ubahDonasi(Kiriman(const PermintaanUbahDonasi(id: 145437, jumlah: 150000)));
      expect(jawaban.sumbangan.jumlah, 150000);
      expect(jawaban.bolehUbah, isTrue);
    });

    test('gantipassword mengembalikan token baru', () async {
      final api = buatKlien((r) async => jawabJson(200, {
            'ok': true,
            'data': {'token': 'tkn-baru', 'kedaluwarsa': '2026-10-13T00:15:00+08:00'},
          }));
      final jawaban = await panggil(api, Aksi.gantipassword) as JawabanGantiPassword;
      expect(jawaban.token, 'tkn-baru');
    });

    test('nama_donatur null untuk donatur terhapus, note_n hanya bila dikirim', () async {
      final api = buatKlien((r) async => jawabJson(200, {
            'ok': true,
            'data': {
              'tanggal': '2026-10-12',
              'total': 300000,
              'transaksi': 2,
              'daftar': [
                {'id': 2, 'waktu': '10:00:00', 'id_donatur': 9, 'nama_donatur': null, 'jumlah': 100000, 'boleh_ubah': false},
                {'id': 1, 'waktu': '09:00:00', 'id_donatur': 8, 'nama_donatur': 'A', 'jumlah': 200000, 'boleh_ubah': true, 'note_n': true},
              ],
            },
          }));
      final d = await api.donasiSaya();
      expect(d.daftar[0].namaDonatur, isNull);
      expect(d.daftar[0].noteN, isFalse);
      expect(d.daftar[1].noteN, isTrue);
    });
  });

  group('katalog galat kontrak §8', () {
    // (status, kode, field tambahan) per baris katalog.
    final katalog = <(int, String, Json)>[
      (400, KodeGalat.permintaanSalah, {}),
      (401, KodeGalat.tokenTidakSah, {}),
      (401, KodeGalat.tokenKedaluwarsa, {}),
      (401, KodeGalat.akunNonaktif, {}),
      (401, KodeGalat.loginGagal, {}),
      (403, KodeGalat.tidakBerhak, {}),
      (404, KodeGalat.aksiTidakAda, {}),
      (404, KodeGalat.tidakAda, {}),
      (405, KodeGalat.metodeSalah, {}),
      (409, KodeGalat.perluKonfirmasi, {
        'alasan': ['Donatur nomor 1234 sudah tercatat menyumbang 1 kali hari ini.'],
        'donatur': {'id': 1234, 'nama': 'Fulan Uji'},
      }),
      (409, KodeGalat.donaturSudahAda, {'id_donatur': 1234}),
      (409, KodeGalat.kunciUlangBentrok, {}),
      (409, KodeGalat.fiturBelumTersedia, {}),
      (413, KodeGalat.terlaluBesar, {}),
      (415, KodeGalat.tipeTidakDidukung, {}),
      (422, KodeGalat.tidakValid, {'rincian': {'jumlah': 'Nominal sumbangan Kosong'}}),
      (429, KodeGalat.loginTerkunci, {'sisa_detik': 840}),
      (500, KodeGalat.galatServer, {}),
      (503, KodeGalat.apiMati, {}),
    ];

    test('uji ini mencakup setiap kode katalog', () {
      expect(katalog.map((k) => k.$2).toSet(), KodeGalat.semua);
    });

    for (final (status, kode, tambahan) in katalog) {
      test('$status $kode → GalatApi dengan field yang benar', () async {
        final api = buatKlien((r) async => jawabGalat(status, kode, tambahan));
        final aksi = kode == KodeGalat.loginGagal ? Aksi.login : Aksi.tambahdonasi;
        final galat = await panggil(api, aksi).then<GalatApi>(
          (_) => fail('seharusnya galat'),
          onError: (Object e) => e as GalatApi,
        );

        expect(galat.status, status);
        expect(galat.kode, kode);
        expect(galat.pesan, 'Pesan uji');
        expect(galat.perluPesanUmum, KodeGalat.bugKlien.contains(kode) || kode == KodeGalat.galatServer);
        switch (kode) {
          case KodeGalat.tidakValid:
            expect(galat.rincian, {'jumlah': 'Nominal sumbangan Kosong'});
          case KodeGalat.perluKonfirmasi:
            expect(galat.alasan, hasLength(1));
            expect(galat.donatur?.id, 1234);
            expect(galat.donatur?.nama, 'Fulan Uji');
          case KodeGalat.loginTerkunci:
            expect(galat.sisaDetik, 840);
          case KodeGalat.donaturSudahAda:
            expect(galat.idDonatur, 1234);
          default:
            expect(galat.rincian, isEmpty);
            expect(galat.alasan, isEmpty);
            expect(galat.donatur, isNull);
        }
      });
    }

    test('tanpa jawaban: timeout → GalatJaringan', () async {
      final api = buatKlien(batas: const Duration(milliseconds: 50), (r) async {
        await Future<void>.delayed(const Duration(milliseconds: 300));
        return jawabJson(200, {'ok': true, 'data': konfigurasiUji});
      });
      await expectLater(api.konfigurasi(), throwsA(isA<GalatJaringan>()));
    });

    test('tanpa jawaban: tanpa jaringan atau koneksi putus → GalatJaringan', () async {
      for (final lempar in <Object>[
        const SocketException('tidak ada jaringan'),
        http.ClientException('koneksi putus'),
        const HandshakeException('sertifikat'),
      ]) {
        final api = buatKlien((r) async => throw lempar);
        await expectLater(api.konfigurasi(), throwsA(isA<GalatJaringan>()), reason: '$lempar');
      }
    });
  });

  group('401 dan padaTidakSah', () {
    for (final kode in [KodeGalat.tokenTidakSah, KodeGalat.tokenKedaluwarsa, KodeGalat.akunNonaktif]) {
      test('$kode memanggil padaTidakSah dengan galatnya', () async {
        final dipanggil = <GalatApi>[];
        final api = buatKlien((r) async => jawabGalat(401, kode), padaTidakSah: dipanggil.add);
        await expectLater(api.donasiSaya(), throwsA(isA<GalatApi>()));
        expect(dipanggil.single.kode, kode);
      });
    }

    test('401 dari login tidak memanggil padaTidakSah', () async {
      final dipanggil = <GalatApi>[];
      final api = buatKlien((r) async => jawabGalat(401, KodeGalat.loginGagal), padaTidakSah: dipanggil.add);
      await expectLater(panggil(api, Aksi.login), throwsA(isA<GalatApi>()));
      expect(dipanggil, isEmpty);
    });

    test('401 bukan JSON tetap memanggil padaTidakSah (menurut status HTTP)', () async {
      final dipanggil = <GalatApi>[];
      final api = buatKlien((r) async => http.Response('Unauthorized', 401), padaTidakSah: dipanggil.add);
      await expectLater(api.konfigurasi(), throwsA(isA<GalatApi>()));
      expect(dipanggil.single.kode, isEmpty);
    });

    test('status selain 401 tidak memanggil padaTidakSah', () async {
      final dipanggil = <GalatApi>[];
      for (final (status, kode) in [(403, KodeGalat.tidakBerhak), (422, KodeGalat.tidakValid), (500, KodeGalat.galatServer)]) {
        final api = buatKlien((r) async => jawabGalat(status, kode), padaTidakSah: dipanggil.add);
        await expectLater(api.donasiSaya(), throwsA(isA<GalatApi>()));
      }
      expect(dipanggil, isEmpty);
    });
  });

  group('versi kontrak (§9)', () {
    test('aturan kecocokan versi', () {
      expect(versiCocok('0.1.0'), isTrue);
      expect(versiCocok('0.1.7'), isTrue);
      expect(versiCocok('0.2.0'), isFalse);
      expect(versiCocok('0.0.9'), isFalse);
      expect(versiCocok('1.1.0'), isFalse);
      expect(versiCocok('1.3.0', versiKlien: '1.2.0'), isTrue);
      expect(versiCocok('1.2.5', versiKlien: '1.2.0'), isTrue);
      expect(versiCocok('1.1.0', versiKlien: '1.2.0'), isFalse);
      expect(versiCocok('2.2.0', versiKlien: '1.2.0'), isFalse);
      expect(versiCocok(''), isFalse);
      expect(versiCocok('0.1'), isFalse);
      expect(versiCocok('v0.1.0'), isFalse);
    });

    test('X-Api-Versi tidak cocok → GalatVersi, juga untuk jawaban sukses', () async {
      final api = buatKlien((r) async => jawabJson(200, {'ok': true, 'data': konfigurasiUji}, versi: '0.2.0'));
      await expectLater(
        api.konfigurasi(),
        throwsA(isA<GalatVersi>().having((g) => g.versiServer, 'versiServer', '0.2.0')),
      );
    });

    test('X-Api-Versi tidak cocok pada galat → GalatVersi, bukan GalatApi', () async {
      final api = buatKlien((r) async =>
          jawabJson(401, {'ok': false, 'kode': KodeGalat.tokenTidakSah, 'pesan': 'x'}, versi: '1.0.0'));
      await expectLater(api.donasiSaya(), throwsA(isA<GalatVersi>()));
    });

    test('konfigurasi.versi_api tidak cocok → GalatVersi', () async {
      final api = buatKlien((r) async => jawabJson(200, {
            'ok': true,
            'data': {...konfigurasiUji, 'versi_api': '0.3.0'},
          }));
      await expectLater(
        api.konfigurasi(),
        throwsA(isA<GalatVersi>().having((g) => g.versiServer, 'versiServer', '0.3.0')),
      );
    });

    test('versi patch berbeda tetap diterima', () async {
      final api = buatKlien((r) async => jawabJson(200, {
            'ok': true,
            'data': {...konfigurasiUji, 'versi_api': '0.1.4'},
          }, versi: '0.1.4'));
      expect((await api.konfigurasi()).versiApi, '0.1.4');
    });
  });

  group('jawaban bukan amplop JSON ditangani menurut status HTTP', () {
    Future<GalatApi> galatDari(http.Response jawaban) async {
      final api = buatKlien((r) async => jawaban);
      return api.konfigurasi().then<GalatApi>(
            (_) => fail('seharusnya galat'),
            onError: (Object e) => e as GalatApi,
          );
    }

    test('HTML 502 dari proxy', () async {
      final galat = await galatDari(http.Response('<html>Bad Gateway</html>', 502));
      expect(galat.status, 502);
      expect(galat.kode, isEmpty);
      expect(galat.perluPesanUmum, isTrue);
    });

    test('HTML 200 (mis. halaman hosting)', () async {
      final galat = await galatDari(http.Response('<html>ok</html>', 200));
      expect(galat.status, 200);
      expect(galat.kode, isEmpty);
    });

    test('JSON yang bukan objek', () async {
      final galat = await galatDari(jawabJson(200, [1, 2, 3]));
      expect(galat.kode, isEmpty);
    });

    test('amplop sukses dengan field wajib hilang', () async {
      final data = Map<String, Object?>.of(konfigurasiUji)..remove('hari_ini');
      final galat = await galatDari(jawabJson(200, {'ok': true, 'data': data}));
      expect(galat.status, 200);
      expect(galat.kode, isEmpty);
    });

    test('angka sebagai string atau pecahan melanggar kontrak §4', () async {
      for (final nilai in <Object>['5000000', 5000000.5]) {
        final galat = await galatDari(jawabJson(200, {
          'ok': true,
          'data': {...konfigurasiUji, 'nominal_konfirmasi': nilai},
        }));
        expect(galat.kode, isEmpty, reason: '$nilai');
      }
    });

    test('kode tak dikenal: 5xx → pesan umum, 4xx → pesan server', () async {
      final galat5xx = await galatDari(jawabGalat(502, 'kode_baru'));
      expect(galat5xx.perluPesanUmum, isTrue);
      final galat4xx = await galatDari(jawabGalat(409, 'kode_baru'));
      expect(galat4xx.kode, 'kode_baru');
      expect(galat4xx.perluPesanUmum, isFalse);
    });
  });

  group('log debug (docs/15_OBSERVABILITY.md)', () {
    test('format baku, tanpa token, password, atau data donatur', () async {
      final api = buatKlien((r) async => r.url.queryParameters['aksi'] == 'login'
          ? jawabGalat(401, KodeGalat.loginGagal)
          : jawabJson(201, {
              'ok': true,
              'data': {
                'donatur': {'id': 7759, 'nama': 'Fulan Uji', 'alamat': 'Desa Uji', 'no_hp': '081234567890', 'keterangan': ''},
                'sumbangan': {...sumbanganUji, 'id_donatur': 7759},
                'ringkasan_hari_ini': ringkasanUji,
              },
            }));
      await expectLater(panggil(api, Aksi.login), throwsA(isA<GalatApi>()));
      await panggil(api, Aksi.tambahdonatur);

      expect(log, hasLength(2));
      expect(log[0], matches(RegExp(r'^\[api\] POST login 401 \d+ms login_gagal$')));
      expect(log[1], matches(RegExp(r'^\[api\] POST tambahdonatur 201 \d+ms$')));
      for (final baris in log) {
        for (final rahasia in [tokenUji, passwordUji, 'operator1', 'Fulan Uji', 'Desa Uji', '081234567890']) {
          expect(baris, isNot(contains(rahasia)));
        }
      }
    });
  });
}
