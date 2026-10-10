// Satu-satunya tempat HTTP dan nama aksi (docs/08_ARCHITECTURE.md, docs/12_PROJECT_STRUCTURE.md).
// Alamat, header, batas waktu, amplop, dan kode galat mengikuti API_CONTRACT.md §2–§9.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

import '../util/kunci.dart';
import 'galat_api.dart';
import 'model.dart';

/// Versi API_CONTRACT.md yang dipakai aplikasi ini. Harus sama dengan
/// `split.contract_version` di docs/_MANIFEST.json (docs/27_API_CONTRACT.md).
const versiKontrak = '0.1.0';

enum MetodeHttp { get, post }

/// Aksi kontrak §6. Nama nilai = nilai parameter `aksi`.
enum Aksi {
  login(MetodeHttp.post, bertoken: false),
  konfigurasi(MetodeHttp.get),
  donatur(MetodeHttp.get),
  caridonatur(MetodeHttp.get),
  tambahdonasi(MetodeHttp.post, berkunci: true),
  tambahdonatur(MetodeHttp.post, berkunci: true),
  donasisaya(MetodeHttp.get),
  ubahdonasi(MetodeHttp.post, berkunci: true),
  rekap(MetodeHttp.get),
  gantipassword(MetodeHttp.post);

  const Aksi(this.metode, {this.bertoken = true, this.berkunci = false});

  final MetodeHttp metode;

  /// Wajib membawa `Authorization: Bearer`.
  final bool bertoken;

  /// Wajib membawa `Idempotency-Key` (kontrak §7).
  final bool berkunci;
}

/// Isi satu aksi tulis beserta kunci kirim ulangnya (kontrak §7).
///
/// Simpan dan "Ya, simpan" membuat [Kiriman] baru, sehingga kuncinya baru.
/// Kirim ulang setelah putus jaringan mengirim objek yang sama, sehingga kuncinya sama.
class Kiriman<T> {
  Kiriman(this.isi) : kunci = kunciBaru();

  final T isi;
  final String kunci;
}

/// Aturan kontrak §9: selama 0.x mayor dan minor harus sama; mulai 1.0 mayor sama
/// dan minor server ≥ minor klien.
bool versiCocok(String versiServer, {String versiKlien = versiKontrak}) {
  final server = _bacaVersi(versiServer);
  final klien = _bacaVersi(versiKlien);
  if (server == null || klien == null || server.$1 != klien.$1) return false;
  return klien.$1 == 0 ? server.$2 == klien.$2 : server.$2 >= klien.$2;
}

(int, int)? _bacaVersi(String versi) {
  final cocok = RegExp(r'^(\d+)\.(\d+)\.\d+$').firstMatch(versi.trim());
  if (cocok == null) return null;
  return (int.parse(cocok.group(1)!), int.parse(cocok.group(2)!));
}

class KlienApi {
  KlienApi({
    required this.alamatServer,
    this.token,
    this.padaTidakSah,
    this.padaGalatVersi,
    http.Client? klien,
    this.batasPermintaan = const Duration(seconds: 20),
  }) : _klien = klien ?? IOClient(HttpClient()..connectionTimeout = batasKoneksi);

  static const batasKoneksi = Duration(seconds: 10);

  /// `APP_URL` server; garis miring di akhir diabaikan.
  String alamatServer;

  String? token;

  /// Dipanggil pada setiap 401, kecuali dari `login` (docs/08_ARCHITECTURE.md).
  void Function(GalatApi galat)? padaTidakSah;

  /// Dipanggil setiap kali versi server tidak cocok (`X-Api-Versi` atau `konfigurasi.versi_api`),
  /// sebelum [GalatVersi] dilempar, sehingga layar blokir bisa tampil dari permintaan mana pun.
  void Function(GalatVersi galat)? padaGalatVersi;

  final Duration batasPermintaan;
  final http.Client _klien;

  Future<JawabanLogin> login(PermintaanLogin isi) =>
      _kirim(Aksi.login, JawabanLogin.fromJson, isi: isi.toJson());

  Future<Konfigurasi> konfigurasi() => _kirim(Aksi.konfigurasi, (data) {
        final konfigurasi = Konfigurasi.fromJson(data);
        if (!versiCocok(konfigurasi.versiApi)) _galatVersi(konfigurasi.versiApi);
        return konfigurasi;
      });

  Future<Donatur> donatur(int id) =>
      _kirim(Aksi.donatur, Donatur.fromJson, query: PermintaanDonatur(id).toQuery());

  Future<HasilCariDonatur> cariDonatur(String q) => _kirim(Aksi.caridonatur,
      HasilCariDonatur.fromJson, query: PermintaanCariDonatur(q).toQuery());

  Future<JawabanTambahDonasi> tambahDonasi(Kiriman<PermintaanTambahDonasi> kiriman) =>
      _kirim(Aksi.tambahdonasi, JawabanTambahDonasi.fromJson,
          isi: kiriman.isi.toJson(), kunci: kiriman.kunci);

  Future<JawabanTambahDonatur> tambahDonatur(Kiriman<PermintaanTambahDonatur> kiriman) =>
      _kirim(Aksi.tambahdonatur, JawabanTambahDonatur.fromJson,
          isi: kiriman.isi.toJson(), kunci: kiriman.kunci);

  Future<DonasiSaya> donasiSaya({DateTime? tanggal}) => _kirim(Aksi.donasisaya,
      DonasiSaya.fromJson, query: PermintaanDonasiSaya(tanggal: tanggal).toQuery());

  Future<JawabanUbahDonasi> ubahDonasi(Kiriman<PermintaanUbahDonasi> kiriman) =>
      _kirim(Aksi.ubahdonasi, JawabanUbahDonasi.fromJson,
          isi: kiriman.isi.toJson(), kunci: kiriman.kunci);

  Future<Rekap> rekap(PermintaanRekap permintaan) =>
      _kirim(Aksi.rekap, Rekap.fromJson, query: permintaan.toQuery());

  Future<JawabanGantiPassword> gantiPassword(PermintaanGantiPassword isi) =>
      _kirim(Aksi.gantipassword, JawabanGantiPassword.fromJson, isi: isi.toJson());

  Uri _alamat(Aksi aksi, Map<String, String> query) {
    final dasar = alamatServer.replaceFirst(RegExp(r'/+$'), '');
    return Uri.parse('$dasar/api').replace(queryParameters: {'aksi': aksi.name, ...query});
  }

  Future<T> _kirim<T>(
    Aksi aksi,
    T Function(Json data) baca, {
    Map<String, String> query = const {},
    Json? isi,
    String? kunci,
  }) async {
    final uri = _alamat(aksi, query);
    final header = <String, String>{
      if (aksi.bertoken && token != null) 'Authorization': 'Bearer $token',
      if (aksi.metode == MetodeHttp.post) 'Content-Type': 'application/json',
      if (aksi.berkunci && kunci != null) 'Idempotency-Key': kunci,
    };
    final jam = Stopwatch()..start();

    final http.Response jawaban;
    try {
      final permintaan = switch (aksi.metode) {
        MetodeHttp.get => _klien.get(uri, headers: header),
        // Isi dikirim sebagai byte agar http tidak menambah "; charset" ke Content-Type.
        MetodeHttp.post =>
          _klien.post(uri, headers: header, body: utf8.encode(jsonEncode(isi ?? const {}))),
      };
      jawaban = await permintaan.timeout(batasPermintaan);
    } on TimeoutException {
      _catat(aksi, null, jam, 'timeout');
      throw const GalatJaringan();
    } on IOException {
      _catat(aksi, null, jam, 'jaringan');
      throw const GalatJaringan();
    } on http.ClientException {
      _catat(aksi, null, jam, 'jaringan');
      throw const GalatJaringan();
    }

    final status = jawaban.statusCode;
    final versi = jawaban.headers['x-api-versi'];
    if (versi != null && !versiCocok(versi)) {
      _catat(aksi, status, jam, 'versi $versi');
      _galatVersi(versi);
    }

    final json = _json(jawaban);
    final galat = _galatAtauNull(status, json);
    if (galat == null) {
      try {
        final hasil = baca(Amplop.fromJson(json!).data);
        _catat(aksi, status, jam, '');
        return hasil;
      } on FormatException {
        _catat(aksi, status, jam, 'bentuk jawaban');
        throw GalatApi(status: status);
      }
    }

    _catat(aksi, status, jam, galat.kode.isEmpty ? 'bukan amplop' : galat.kode);
    if (galat.tidakSah && aksi != Aksi.login) padaTidakSah?.call(galat);
    throw galat;
  }

  Never _galatVersi(String versiServer) {
    final galat = GalatVersi(versiServer);
    padaGalatVersi?.call(galat);
    throw galat;
  }

  /// `null` bila jawaban adalah amplop sukses berstatus 2xx; selain itu galatnya.
  /// Jawaban yang bukan amplop JSON menjadi GalatApi berkode kosong (status HTTP saja).
  GalatApi? _galatAtauNull(int status, Json? json) {
    if (json == null) return GalatApi(status: status);
    final Amplop amplop;
    try {
      amplop = Amplop.fromJson(json);
    } on FormatException {
      return GalatApi(status: status);
    }
    if (amplop.ok && status >= 200 && status < 300) return null;
    return amplop.ok ? GalatApi(status: status) : galatApiFromJson(status, json);
  }

  Json? _json(http.Response jawaban) {
    try {
      final isi = jsonDecode(utf8.decode(jawaban.bodyBytes));
      return isi is Json ? isi : null;
    } on FormatException {
      return null;
    }
  }

  /// Format docs/15_OBSERVABILITY.md. Tidak pernah mencatat token, isi permintaan, atau data donatur.
  void _catat(Aksi aksi, int? status, Stopwatch jam, String keterangan) {
    if (!kDebugMode) return;
    final metode = aksi.metode.name.toUpperCase();
    final akhir = keterangan.isEmpty ? '' : ' $keterangan';
    debugPrint('[api] $metode ${aksi.name} ${status ?? '-'} ${jam.elapsedMilliseconds}ms$akhir');
  }
}
