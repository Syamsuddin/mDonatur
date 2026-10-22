// Pembantu uji layar: server tiruan (MockClient per aksi), secure storage tiruan, layar kecil,
// pemompa aplikasi lengkap dengan Sesi, dan isi jawaban contoh kontrak. Tanpa jaringan
// (docs/13_TESTING.md).

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mdonator/api/klien_api.dart';
import 'package:mdonator/layar/kerangka.dart';
import 'package:mdonator/main.dart';
import 'package:mdonator/state/sesi.dart';
import 'package:mdonator/util/tanggal.dart';
import 'package:mdonator/widget/strip_hari_ini.dart';

const alamatBawaanUji = 'http://10.0.2.2:3000';
const tokenUji = 'tkn-uji-123';
const tokenBaruUji = 'tkn-uji-456';
const kedaluwarsaUji = '2026-10-13T00:15:00+08:00';

/// Password tiruan untuk server tiruan; sama dengan konvensi test/api/klien_api_test.dart.
const passwordUji = 'sandi-uji-456';

/// Layar 360×640 dp dengan textScaler 1,3 (docs/23_ACCEPTANCE_CRITERIA.md §Semua layar).
void aturLayarKecil(WidgetTester tester) {
  tester.view.physicalSize = const Size(360 * 3, 640 * 3);
  tester.view.devicePixelRatio = 3;
  tester.platformDispatcher.textScaleFactorTestValue = 1.3;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

http.Response jawabJson(int status, Object isi, {String versi = versiKontrak}) => http.Response(
      jsonEncode(isi),
      status,
      headers: {'content-type': 'application/json; charset=utf-8', 'x-api-versi': versi},
    );

http.Response jawabOk(Object data) => jawabJson(200, {'ok': true, 'data': data});

http.Response jawabGalat(int status, String kode, String pesan, [Map<String, Object?> lain = const {}]) =>
    jawabJson(status, {'ok': false, 'kode': kode, 'pesan': pesan, ...lain});

/// `boleh_atur_note` mengikuti [peran], seperti server (K23), kecuali diisi lain.
Map<String, Object?> konfigurasiUji({
  String versi = versiKontrak,
  String username = 'uji_operator',
  String peran = 'operator',
  bool? bolehAturNote,
}) =>
    {
      'versi_api': versi,
      'hari_ini': '2026-10-12',
      'zona_waktu': 'Asia/Makassar',
      'nominal_umum': [50000, 100000],
      'nominal_konfirmasi': 5000000,
      'pengguna': {'id': 7, 'username': username, 'peran': peran},
      'boleh_atur_note': bolehAturNote ?? peran == 'admin',
    };

Map<String, Object?> loginUji({String token = tokenUji, String username = 'uji_operator'}) => {
      'token': token,
      'kedaluwarsa': kedaluwarsaUji,
      'pengguna': {'id': 7, 'username': username, 'peran': 'operator'},
    };

typedef Penangan = Future<http.Response> Function(http.Request permintaan);

/// Server tiruan. Bawaan: `login`, `konfigurasi`, dan `logout` sukses; aksi lain 404 `aksi_tidak_ada`.
class ServerTiruan {
  ServerTiruan() {
    penangan['login'] = (r) async => jawabOk(loginUji());
    penangan['konfigurasi'] = (r) async => jawabOk(konfigurasiUji());
    penangan['logout'] = (r) async => jawabOk(<String, Object?>{});
  }

  final penangan = <String, Penangan>{};
  final permintaan = <http.Request>[];

  late final klien = MockClient((r) async {
    permintaan.add(r);
    final aksi = r.url.queryParameters['aksi'];
    final p = penangan[aksi];
    if (p == null) return jawabGalat(404, 'aksi_tidak_ada', 'Aksi tidak ada.');
    return p(r);
  });

  List<String?> get aksi => [for (final r in permintaan) r.url.queryParameters['aksi']];
}

/// Pengaturan Android "Hapus animasi" (docs/26 §Token gerak). Tanpa itu kilau kerangka memuat berulang
/// tanpa henti dan `pumpAndSettle` tidak pernah selesai selama kerangka tampil (docs/13_TESTING.md).
/// Gerak dengan animasi aktif diuji tersendiri di gerak_test.dart.
void aturHapusAnimasi(WidgetTester tester, {bool aktif = true}) {
  tester.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: aktif);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
}

/// Memompa aplikasi lengkap dengan [simpanan] sebagai isi secure storage, lalu menjalankan P0.
/// Bawaannya [kerangkaKosong], supaya uji sesi hanya melihat aksi sesi; uji layar memakai
/// `const LayarKerangka()`. Hapus animasi aktif, kecuali [hapusAnimasi] false (uji gerak).
Future<Sesi> pompaAplikasi(
  WidgetTester tester, {
  required ServerTiruan server,
  Map<String, String>? simpanan,
  Widget kerangka = kerangkaKosong,
  String alamatBawaan = alamatBawaanUji,
  bool rilis = false,
  FlutterSecureStorage penyimpanan = const FlutterSecureStorage(),
  bool hapusAnimasi = true,
}) async {
  aturHapusAnimasi(tester, aktif: hapusAnimasi);
  FlutterSecureStorage.setMockInitialValues(simpanan ?? {});
  final sesi = Sesi(
    alamatBawaan: alamatBawaan,
    klienHttp: server.klien,
    rilis: rilis,
    penyimpanan: penyimpanan,
  );
  await tester.pumpWidget(AplikasiMDonator(sesi: sesi, kerangka: kerangka));
  await sesi.mulai();
  await tester.pumpAndSettle();
  return sesi;
}

/// Secure storage yang menahan setiap tulis sampai [tahan] selesai, untuk menguji state memuat.
class PenyimpananTertahan extends FlutterSecureStorage {
  PenyimpananTertahan(this.tahan);

  final Completer<void> tahan;

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    await tahan.future;
    return super.write(key: key, value: value);
  }
}

/// Isi secure storage untuk pengguna yang sudah masuk.
Map<String, String> simpananMasuk() => {
      'token': tokenUji,
      'kedaluwarsa': kedaluwarsaUji,
      'username_terakhir': 'uji_operator',
    };

Finder isian(String label) => find.widgetWithText(TextField, label);

String? galatIsian(WidgetTester tester, String label) =>
    tester.widget<TextField>(isian(label)).decoration?.errorText;

String teksIsian(WidgetTester tester, String label) =>
    tester.widget<TextField>(isian(label)).controller!.text;

Finder tombol<T extends ButtonStyleButton>(String label) => find.widgetWithText(T, label);

/// Masuk lewat layar Masuk yang sedang tampil.
Future<void> isiDanMasuk(WidgetTester tester, {String username = 'uji_operator', String password = passwordUji}) async {
  await tester.enterText(isian('Username'), username);
  await tester.enterText(isian('Password'), password);
  await tester.tap(tombol<FilledButton>('Masuk'));
  await tester.pumpAndSettle();
}

/// Ringkasan hari ini di kepala tab Input (docs/26 §Inventaris): (nominal, pil). Labelnya diperiksa di
/// sini, sehingga pemanggil cukup membandingkan angkanya.
(String, String) ringkasanHariIni(WidgetTester tester) {
  final teks = tester
      .widgetList<Text>(find.descendant(of: find.byType(StripHariIni), matching: find.byType(Text)))
      .map((t) => t.data!)
      .toList();
  expect(teks, hasLength(3));
  expect(teks.first, 'Total input hari ini');
  return (teks[1], teks[2]);
}

String judulAppBar(WidgetTester tester) => tester
    .widget<Text>(find.descendant(of: find.byType(AppBar).last, matching: find.byType(Text)).first)
    .data!;

/// Tab tiruan berisi satu isian dan tombol yang memanggil aksi bertoken, untuk menguji alur 401
/// dan dialog Keluar tanpa bergantung pada isi layar tab mana pun.
class TabTiruan extends StatefulWidget {
  const TabTiruan({super.key});

  @override
  State<TabTiruan> createState() => _TabTiruanState();
}

class _TabTiruanState extends State<TabTiruan> {
  final _isi = TextEditingController();
  late final Sesi _sesi = SesiScope.baca(context);
  bool _adaIsian() => _isi.text.isNotEmpty;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sesi.daftarkanCekIsian(_adaIsian);
  }

  @override
  void dispose() {
    _sesi.lepasCekIsian(_adaIsian);
    _isi.dispose();
    super.dispose();
  }

  Future<void> _kirim() async {
    try {
      await _sesi.klien.donatur(1);
    } on Exception {
      // Uji hanya memeriksa reaksi Sesi terhadap 401.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(controller: _isi, decoration: const InputDecoration(labelText: 'Isian Uji')),
        OutlinedButton(onPressed: _kirim, child: const Text('Kirim Uji')),
      ],
    );
  }
}

const kerangkaDenganTabTiruan = LayarKerangka(
  isiTab: [TabTiruan(), SizedBox.expand(), SizedBox.expand(), SizedBox.expand()],
);

/// Kerangka dengan empat tab kosong.
const kerangkaKosong = LayarKerangka(
  isiTab: [SizedBox.expand(), SizedBox.expand(), SizedBox.expand(), SizedBox.expand()],
);

// ---------------------------------------------------------------------------
// Isi jawaban contoh API_CONTRACT.md §6.3–§6.7 (S2).

/// Jawaban `donatur` sama dengan contoh kontrak §6.3; field bisa diganti per uji.
Map<String, Object?> donaturUji({
  int id = 1234,
  String nama = 'Fulan bin Fulan',
  String alamat = 'Desa Kapuh, Simpur',
  String noHp = '08xx',
  String keterangan = '',
  int bintang = 2,
  List<Map<String, Object?>>? riwayat,
  int totalTahunIni = 200000,
  int? saranJumlah = 200000,
}) =>
    {
      'id': id,
      'nama': nama,
      'alamat': alamat,
      'no_hp': noHp,
      'keterangan': keterangan,
      'bintang': bintang,
      'tahun': 2026,
      'riwayat': riwayat ?? [
        {'tanggal': '2026-01-04', 'waktu': '09:12:40', 'jumlah': 200000},
      ],
      'total_tahun_ini': totalTahunIni,
      'saran_jumlah': saranJumlah,
    };

/// Jawaban `donasisaya`. Layar Input hanya memakai total dan transaksi; daftar untuk Input Saya
/// berisi [barisDonasiSayaUji].
Map<String, Object?> donasiSayaUji({
  int total = 1550000,
  int transaksi = 10,
  String tanggal = '2026-10-12',
  List<Map<String, Object?>> daftar = const [],
}) =>
    {
      'tanggal': tanggal,
      'total': total,
      'transaksi': transaksi,
      'daftar': daftar,
    };

/// Jawaban 201 `tambahdonasi` sama dengan contoh kontrak §6.5.
Map<String, Object?> tambahDonasiUji({
  int idDonatur = 1234,
  String? namaDonatur = 'Fulan bin Fulan',
  int jumlah = 200000,
  int total = 1450000,
  int transaksi = 9,
  List<Map<String, Object?>>? terakhir,
}) =>
    {
      'sumbangan': {
        'id': 145437,
        'id_donatur': idDonatur,
        'nama_donatur': namaDonatur,
        'tanggal': '2026-10-12',
        'waktu': '09:15:02',
        'jumlah': jumlah,
      },
      'ringkasan_hari_ini': {
        'tanggal': '2026-10-12',
        'total': total,
        'transaksi': transaksi,
        'terakhir': terakhir ?? [
          {'id_donatur': idDonatur, 'jumlah': jumlah, 'waktu': '09:15:02'},
        ],
      },
    };

http.Response jawabDibuat(Object data) => jawabJson(201, {'ok': true, 'data': data});

/// Server tiruan dengan `donasisaya` dan `donatur` (contoh kontrak) yang sukses.
ServerTiruan serverInput() {
  final server = ServerTiruan();
  server.penangan['donasisaya'] = (r) async => jawabOk(donasiSayaUji());
  server.penangan['donatur'] =
      (r) async => jawabOk(donaturUji(id: int.parse(r.url.queryParameters['id']!)));
  return server;
}

/// Uji perilaku memakai layar 800×2000 dp agar seluruh formulir terlihat tanpa menggulir; tata letak
/// 360 dp diuji sendiri dengan [layarKecil].
Future<Sesi> pompaInput(WidgetTester tester, ServerTiruan server, {bool layarKecil = false}) {
  if (layarKecil) {
    aturLayarKecil(tester);
  } else {
    tester.view.physicalSize = const Size(800 * 3, 2000 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
  }
  return pompaAplikasi(
    tester,
    server: server,
    simpanan: simpananMasuk(),
    kerangka: const LayarKerangka(),
  );
}

List<http.Request> kirimanKe(ServerTiruan server, String aksi) =>
    [for (final r in server.permintaan) if (r.url.queryParameters['aksi'] == aksi) r];

Future<void> ketuk(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

// ---------------------------------------------------------------------------
// Isi jawaban contoh API_CONTRACT.md §6.6 (S3).

/// Jawaban 201 `tambahdonatur` sama dengan contoh kontrak §6.6. Ringkasannya berbeda dari
/// [donasiSayaUji], supaya pembaruan strip tab Input terlihat.
Map<String, Object?> tambahDonaturUji({
  int id = 7759,
  String nama = 'Fulan bin Fulan',
  int sumbangan = 100000,
  int total = 1650000,
  int transaksi = 11,
}) =>
    {
      'donatur': {'id': id, 'nama': nama, 'alamat': 'Desa Kapuh, Simpur', 'no_hp': '', 'keterangan': ''},
      'sumbangan': {
        'id': 145438,
        'id_donatur': id,
        'nama_donatur': nama,
        'tanggal': '2026-10-12',
        'waktu': '09:20:11',
        'jumlah': sumbangan,
      },
      'ringkasan_hari_ini': {
        'tanggal': '2026-10-12',
        'total': total,
        'transaksi': transaksi,
        'terakhir': [
          {'id_donatur': id, 'jumlah': sumbangan, 'waktu': '09:20:11'},
        ],
      },
    };

/// Server tiruan untuk tab Input dan Donatur: `caridonatur` tanpa hasil, `tambahdonatur` 201.
ServerTiruan serverDonatur() {
  final server = serverInput();
  server.penangan['caridonatur'] = (r) async => jawabOk({'hasil': <Object?>[], 'lebih': false});
  server.penangan['tambahdonatur'] = (r) async => jawabDibuat(tambahDonaturUji());
  return server;
}

Future<void> pilihTab(WidgetTester tester, String label) async {
  await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text(label)));
  await tester.pumpAndSettle();
}

/// Seperti [pompaInput], lalu pindah ke tab Donatur.
Future<Sesi> pompaTabDonatur(WidgetTester tester, ServerTiruan server, {bool layarKecil = false}) async {
  final sesi = await pompaInput(tester, server, layarKecil: layarKecil);
  await pilihTab(tester, 'Donatur');
  return sesi;
}

// ---------------------------------------------------------------------------
// Isi jawaban contoh API_CONTRACT.md §6.7–§6.8 (S4).

/// Satu baris `donasisaya.daftar`, sama dengan contoh kontrak §6.7. `note_n` hanya dikirim bila
/// [noteN] diisi, seperti server untuk operator.
Map<String, Object?> barisDonasiSayaUji({
  int id = 145438,
  String waktu = '09:20:11',
  int idDonatur = 7759,
  String? namaDonatur = 'Fulan bin Fulan',
  int jumlah = 100000,
  bool bolehUbah = true,
  bool bolehHapus = false,
  bool? noteN,
}) =>
    {
      'id': id,
      'waktu': waktu,
      'id_donatur': idDonatur,
      'nama_donatur': namaDonatur,
      'jumlah': jumlah,
      'boleh_ubah': bolehUbah,
      'boleh_hapus': bolehHapus,
      'note_n': ?noteN,
    };

/// Jawaban 200 `ubahdonasi` (kontrak §6.8): Sumbangan + `boleh_ubah`.
Map<String, Object?> ubahDonasiUji({int id = 145438, int idDonatur = 7759, int jumlah = 150000}) => {
      'sumbangan': {
        'id': id,
        'id_donatur': idDonatur,
        'nama_donatur': 'Fulan bin Fulan',
        'tanggal': '2026-10-12',
        'waktu': '09:20:11',
        'jumlah': jumlah,
        'boleh_ubah': true,
      },
    };

/// Server tiruan untuk tab Input Saya: `donasisaya` berisi satu baris contoh kontrak (strip tab
/// Input memakai jawaban yang sama), `ubahdonasi` 200.
ServerTiruan serverInputSaya() {
  final server = serverInput();
  server.penangan['donasisaya'] =
      (r) async => jawabOk(donasiSayaUji(daftar: [barisDonasiSayaUji()]));
  server.penangan['ubahdonasi'] = (r) async => jawabOk(ubahDonasiUji());
  return server;
}

/// Seperti [pompaInput], lalu pindah ke tab Input Saya.
Future<Sesi> pompaTabInputSaya(WidgetTester tester, ServerTiruan server, {bool layarKecil = false}) async {
  final sesi = await pompaInput(tester, server, layarKecil: layarKecil);
  await pilihTab(tester, 'Input Saya');
  return sesi;
}

// ---------------------------------------------------------------------------
// Isi jawaban contoh API_CONTRACT.md §6.9 (S5).

/// Jawaban `rekap` sama dengan contoh kontrak §6.9 (minggu × semua); field bisa diganti per uji.
Map<String, Object?> rekapUji({
  String periode = 'minggu',
  String cakupan = 'semua',
  String tanggal = '2026-10-08',
  String dari = '2026-10-05',
  String sampai = '2026-10-11',
  int total = 27000000,
  int transaksi = 146,
  int donatur = 139,
  List<Map<String, Object?>>? perHari,
  List<Map<String, Object?>>? perOperator,
  String sebelum = '2026-09-28',
  String? sesudah = '2026-10-12',
}) =>
    {
      'periode': periode,
      'cakupan': cakupan,
      'tanggal': tanggal,
      'dari': dari,
      'sampai': sampai,
      'total': total,
      'transaksi': transaksi,
      'donatur': donatur,
      'per_hari': perHari ?? [
        {'tanggal': '2026-10-05', 'transaksi': 98, 'total': 18100000},
        {'tanggal': '2026-10-08', 'transaksi': 48, 'total': 8900000},
      ],
      'per_operator': perOperator ?? [
        {'id_user': 3, 'nama': 'operator1', 'transaksi': 80, 'total': 15000000},
        {'id_user': 6, 'nama': 'operator2', 'transaksi': 65, 'total': 11950000},
        {'id_user': null, 'nama': 'User lama (sudah dihapus)', 'transaksi': 1, 'total': 50000},
      ],
      'navigasi': {'sebelum': sebelum, 'sesudah': sesudah},
    };

/// Server `rekap` tiruan: rentang dan navigasi mengikuti tabel kontrak §6.9 (pekan Senin–Minggu,
/// `sesudah` null bila periode berikutnya dimulai setelah [hariIni]); `per_hari` satu baris untuk
/// hari, `per_operator` kosong untuk cakupan saya; angka lain dari [rekapUji]. Hanya untuk uji:
/// aplikasi tidak pernah menghitung rentang sendiri.
Penangan penanganRekap({
  String hariIni = '2026-10-12',
  int total = 27000000,
  int transaksi = 146,
  int donatur = 139,
  List<Map<String, Object?>>? perHari,
  List<Map<String, Object?>>? perOperator,
}) =>
    (r) async {
      final q = r.url.queryParameters;
      final periode = q['periode']!;
      final cakupan = q['cakupan'] ?? 'saya';
      final tanggal = bacaTanggal(q['tanggal'] ?? hariIni);
      DateTime geser(DateTime t, int hari) => t.add(Duration(days: hari));
      final (dari, sampai, sebelum, sesudah) = switch (periode) {
        'hari' => (tanggal, tanggal, geser(tanggal, -1), geser(tanggal, 1)),
        'minggu' => (
            geser(tanggal, 1 - tanggal.weekday),
            geser(tanggal, 7 - tanggal.weekday),
            geser(tanggal, -6 - tanggal.weekday),
            geser(tanggal, 8 - tanggal.weekday),
          ),
        _ => (
            DateTime.utc(tanggal.year, tanggal.month),
            DateTime.utc(tanggal.year, tanggal.month + 1, 0),
            DateTime.utc(tanggal.year, tanggal.month - 1),
            DateTime.utc(tanggal.year, tanggal.month + 1),
          ),
      };
      return jawabOk(rekapUji(
        periode: periode,
        cakupan: cakupan,
        tanggal: tulisTanggal(tanggal),
        dari: tulisTanggal(dari),
        sampai: tulisTanggal(sampai),
        total: total,
        transaksi: transaksi,
        donatur: donatur,
        perHari: transaksi == 0
            ? const []
            : periode == 'hari'
                ? [
                    {'tanggal': tulisTanggal(tanggal), 'transaksi': transaksi, 'total': total},
                  ]
                : perHari,
        perOperator: cakupan == 'semua' && transaksi > 0 ? perOperator : const [],
        sebelum: tulisTanggal(sebelum),
        sesudah: sesudah.isAfter(bacaTanggal(hariIni)) ? null : tulisTanggal(sesudah),
      ));
    };

/// Server tiruan untuk tab Rekap: tab Input seperti [serverInput], `rekap` dari [penanganRekap].
ServerTiruan serverRekap() {
  final server = serverInput();
  server.penangan['rekap'] = penanganRekap();
  return server;
}

/// Seperti [pompaInput], lalu pindah ke tab Rekap.
Future<Sesi> pompaTabRekap(WidgetTester tester, ServerTiruan server, {bool layarKecil = false}) async {
  final sesi = await pompaInput(tester, server, layarKecil: layarKecil);
  await pilihTab(tester, 'Rekap');
  return sesi;
}
