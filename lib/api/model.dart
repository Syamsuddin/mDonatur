// Kelas permintaan dan jawaban API, ditulis tangan dari API_CONTRACT.md v0.1.0.
// Satu-satunya tempat nama field JSON dan nama parameter query (docs/12_PROJECT_STRUCTURE.md).
// Field jawaban yang tidak dikenal diabaikan (kontrak §4); field wajib yang hilang atau
// bertipe salah melempar FormatException, yang oleh KlienApi diubah menjadi GalatApi.

import '../util/tanggal.dart';
import 'galat_api.dart';

typedef Json = Map<String, Object?>;

T _wajib<T>(Json json, String kunci) {
  final nilai = json[kunci];
  if (nilai is T) return nilai;
  throw FormatException('Field "$kunci" tidak sesuai kontrak');
}

T? _boleh<T extends Object>(Json json, String kunci) {
  final nilai = json[kunci];
  if (nilai is T) return nilai;
  if (nilai == null) return null;
  throw FormatException('Field "$kunci" tidak sesuai kontrak');
}

DateTime _tanggal(Json json, String kunci) => bacaTanggal(_wajib<String>(json, kunci));

DateTime? _tanggalBoleh(Json json, String kunci) {
  final teks = _boleh<String>(json, kunci);
  return teks == null ? null : bacaTanggal(teks);
}

List<T> _daftar<T>(Json json, String kunci, T Function(Json) baca) {
  return [
    for (final butir in _wajib<List<Object?>>(json, kunci))
      if (butir is Json) baca(butir) else throw FormatException('Isi "$kunci" tidak sesuai kontrak'),
  ];
}

List<int> _daftarAngka(Json json, String kunci) {
  return [
    for (final butir in _wajib<List<Object?>>(json, kunci))
      if (butir is int) butir else throw FormatException('Isi "$kunci" tidak sesuai kontrak'),
  ];
}

T _enum<T extends Enum>(List<T> nilai, Json json, String kunci) {
  final teks = _wajib<String>(json, kunci);
  for (final n in nilai) {
    if (n.name == teks) return n;
  }
  throw FormatException('Nilai "$kunci" tidak sesuai kontrak');
}

// ---------------------------------------------------------------------------
// Amplop (kontrak §5)

class Amplop {
  const Amplop({required this.ok, required this.ulang, required this.data});

  factory Amplop.fromJson(Json json) => Amplop(
        ok: _wajib<bool>(json, 'ok'),
        ulang: json['ulang'] == true,
        data: _boleh<Json>(json, 'data') ?? const {},
      );

  final bool ok;

  /// Jawaban diputar ulang dari kunci kirim ulang (kontrak §7); tetap dianggap sukses.
  final bool ulang;
  final Json data;
}

/// Membaca amplop `ok: false`. Toleran: field yang hilang atau bertipe salah dikosongkan,
/// karena penanganan galat tidak boleh gagal.
GalatApi galatApiFromJson(int status, Json json) {
  final rincian = json['rincian'];
  final alasan = json['alasan'];
  final donatur = json['donatur'];
  final kode = json['kode'];
  final pesan = json['pesan'];
  final sisaDetik = json['sisa_detik'];
  final idDonatur = json['id_donatur'];
  return GalatApi(
    status: status,
    kode: kode is String ? kode : '',
    pesan: pesan is String ? pesan : '',
    rincian: rincian is Json
        ? {
            for (final e in rincian.entries)
              if (e.value is String) e.key: e.value as String,
          }
        : const {},
    alasan: alasan is List ? [for (final a in alasan) if (a is String) a] : const [],
    donatur: donatur is Json && donatur['id'] is int && donatur['nama'] is String
        ? DonaturKonfirmasi(id: donatur['id'] as int, nama: donatur['nama'] as String)
        : null,
    sisaDetik: sisaDetik is int ? sisaDetik : null,
    idDonatur: idDonatur is int ? idDonatur : null,
  );
}

// ---------------------------------------------------------------------------
// Struktur bersama (kontrak §6)

class Pengguna {
  const Pengguna({required this.id, required this.username, required this.peran});

  factory Pengguna.fromJson(Json json) => Pengguna(
        id: _wajib<int>(json, 'id'),
        username: _wajib<String>(json, 'username'),
        peran: _wajib<String>(json, 'peran'),
      );

  final int id;
  final String username;

  /// `admin` atau `operator`.
  final String peran;
}

class Sumbangan {
  const Sumbangan({
    required this.id,
    required this.idDonatur,
    required this.namaDonatur,
    required this.tanggal,
    required this.waktu,
    required this.jumlah,
  });

  factory Sumbangan.fromJson(Json json) => Sumbangan(
        id: _wajib<int>(json, 'id'),
        idDonatur: _wajib<int>(json, 'id_donatur'),
        namaDonatur: _boleh<String>(json, 'nama_donatur'),
        tanggal: _tanggal(json, 'tanggal'),
        waktu: _wajib<String>(json, 'waktu'),
        jumlah: _wajib<int>(json, 'jumlah'),
      );

  final int id;
  final int idDonatur;

  /// `null` bila donaturnya sudah terhapus (K7).
  final String? namaDonatur;
  final DateTime tanggal;

  /// "HH:MM:SS" apa adanya dari server, tanpa konversi zona (K1).
  final String waktu;
  final int jumlah;
}

class InputTerakhir {
  const InputTerakhir({required this.idDonatur, required this.jumlah, required this.waktu});

  factory InputTerakhir.fromJson(Json json) => InputTerakhir(
        idDonatur: _wajib<int>(json, 'id_donatur'),
        jumlah: _wajib<int>(json, 'jumlah'),
        waktu: _wajib<String>(json, 'waktu'),
      );

  final int idDonatur;
  final int jumlah;
  final String waktu;
}

class RingkasanHariIni {
  const RingkasanHariIni({
    required this.tanggal,
    required this.total,
    required this.transaksi,
    required this.terakhir,
  });

  factory RingkasanHariIni.fromJson(Json json) => RingkasanHariIni(
        tanggal: _tanggal(json, 'tanggal'),
        total: _wajib<int>(json, 'total'),
        transaksi: _wajib<int>(json, 'transaksi'),
        terakhir: _daftar(json, 'terakhir', InputTerakhir.fromJson),
      );

  final DateTime tanggal;
  final int total;
  final int transaksi;
  final List<InputTerakhir> terakhir;
}

// ---------------------------------------------------------------------------
// 6.1 login

class PermintaanLogin {
  const PermintaanLogin({required this.username, required this.password});

  final String username;
  final String password;

  Json toJson() => {'username': username, 'password': password};
}

class JawabanLogin {
  const JawabanLogin({required this.token, required this.kedaluwarsa, required this.pengguna});

  factory JawabanLogin.fromJson(Json json) => JawabanLogin(
        token: _wajib<String>(json, 'token'),
        kedaluwarsa: _wajib<String>(json, 'kedaluwarsa'),
        pengguna: Pengguna.fromJson(_wajib<Json>(json, 'pengguna')),
      );

  /// Buram bagi klien: hanya disimpan dan dikirim, tidak diurai (kontrak §3).
  final String token;

  /// ISO-8601 dengan offset zona server, hanya untuk ditampilkan di Pengaturan.
  final String kedaluwarsa;
  final Pengguna pengguna;
}

// ---------------------------------------------------------------------------
// 6.2 konfigurasi

class Konfigurasi {
  const Konfigurasi({
    required this.versiApi,
    required this.hariIni,
    required this.zonaWaktu,
    required this.nominalUmum,
    required this.nominalKonfirmasi,
    required this.pengguna,
  });

  factory Konfigurasi.fromJson(Json json) => Konfigurasi(
        versiApi: _wajib<String>(json, 'versi_api'),
        hariIni: _tanggal(json, 'hari_ini'),
        zonaWaktu: _wajib<String>(json, 'zona_waktu'),
        nominalUmum: _daftarAngka(json, 'nominal_umum'),
        nominalKonfirmasi: _wajib<int>(json, 'nominal_konfirmasi'),
        pengguna: Pengguna.fromJson(_wajib<Json>(json, 'pengguna')),
      );

  final String versiApi;

  /// Tanggal server dalam WITA; satu-satunya sumber "hari ini" (kontrak §4).
  final DateTime hariIni;
  final String zonaWaktu;
  final List<int> nominalUmum;
  final int nominalKonfirmasi;
  final Pengguna pengguna;
}

// ---------------------------------------------------------------------------
// 6.3 donatur

class PermintaanDonatur {
  const PermintaanDonatur(this.id);

  final int id;

  Map<String, String> toQuery() => {'id': '$id'};
}

class RiwayatSumbangan {
  const RiwayatSumbangan({
    required this.tanggal,
    required this.waktu,
    required this.jumlah,
    required this.noteN,
  });

  factory RiwayatSumbangan.fromJson(Json json) => RiwayatSumbangan(
        tanggal: _tanggal(json, 'tanggal'),
        waktu: _wajib<String>(json, 'waktu'),
        jumlah: _wajib<int>(json, 'jumlah'),
        noteN: _boleh<bool>(json, 'note_n') ?? false,
      );

  final DateTime tanggal;
  final String waktu;
  final int jumlah;

  /// Hanya pernah benar untuk admin (kontrak §6.3).
  final bool noteN;
}

class Donatur {
  const Donatur({
    required this.id,
    required this.nama,
    required this.alamat,
    required this.noHp,
    required this.keterangan,
    required this.bintang,
    required this.tahun,
    required this.riwayat,
    required this.totalTahunIni,
    required this.saranJumlah,
  });

  factory Donatur.fromJson(Json json) => Donatur(
        id: _wajib<int>(json, 'id'),
        nama: _wajib<String>(json, 'nama'),
        alamat: _wajib<String>(json, 'alamat'),
        noHp: _wajib<String>(json, 'no_hp'),
        keterangan: _wajib<String>(json, 'keterangan'),
        bintang: _wajib<int>(json, 'bintang'),
        tahun: _wajib<int>(json, 'tahun'),
        riwayat: _daftar(json, 'riwayat', RiwayatSumbangan.fromJson),
        totalTahunIni: _wajib<int>(json, 'total_tahun_ini'),
        saranJumlah: _boleh<int>(json, 'saran_jumlah'),
      );

  final int id;
  final String nama;
  final String alamat;
  final String noHp;
  final String keterangan;
  final int bintang;
  final int tahun;
  final List<RiwayatSumbangan> riwayat;
  final int totalTahunIni;
  final int? saranJumlah;
}

// ---------------------------------------------------------------------------
// 6.4 caridonatur

class PermintaanCariDonatur {
  const PermintaanCariDonatur(this.q);

  final String q;

  Map<String, String> toQuery() => {'q': q};
}

class DonaturCari {
  const DonaturCari({required this.id, required this.nama, required this.alamat});

  factory DonaturCari.fromJson(Json json) => DonaturCari(
        id: _wajib<int>(json, 'id'),
        nama: _wajib<String>(json, 'nama'),
        alamat: _wajib<String>(json, 'alamat'),
      );

  final int id;
  final String nama;
  final String alamat;
}

class HasilCariDonatur {
  const HasilCariDonatur({required this.hasil, required this.lebih});

  factory HasilCariDonatur.fromJson(Json json) => HasilCariDonatur(
        hasil: _daftar(json, 'hasil', DonaturCari.fromJson),
        lebih: _wajib<bool>(json, 'lebih'),
      );

  final List<DonaturCari> hasil;

  /// Lebih dari 20 kecocokan; layar menampilkan "Persempit pencarian".
  final bool lebih;
}

// ---------------------------------------------------------------------------
// 6.5 tambahdonasi

class PermintaanTambahDonasi {
  const PermintaanTambahDonasi({
    required this.idDonatur,
    required this.jumlah,
    this.konfirmasi = false,
  });

  final int idDonatur;
  final int jumlah;
  final bool konfirmasi;

  PermintaanTambahDonasi denganKonfirmasi() =>
      PermintaanTambahDonasi(idDonatur: idDonatur, jumlah: jumlah, konfirmasi: true);

  Json toJson() => {'id_donatur': idDonatur, 'jumlah': jumlah, 'konfirmasi': konfirmasi};
}

class JawabanTambahDonasi {
  const JawabanTambahDonasi({required this.sumbangan, required this.ringkasanHariIni});

  factory JawabanTambahDonasi.fromJson(Json json) => JawabanTambahDonasi(
        sumbangan: Sumbangan.fromJson(_wajib<Json>(json, 'sumbangan')),
        ringkasanHariIni: RingkasanHariIni.fromJson(_wajib<Json>(json, 'ringkasan_hari_ini')),
      );

  final Sumbangan sumbangan;
  final RingkasanHariIni ringkasanHariIni;
}

// ---------------------------------------------------------------------------
// 6.6 tambahdonatur

class PermintaanTambahDonatur {
  const PermintaanTambahDonatur({
    required this.nama,
    required this.alamat,
    this.noHp = '',
    this.keterangan = '',
    required this.sumbangan,
    this.konfirmasi = false,
  });

  final String nama;
  final String alamat;
  final String noHp;
  final String keterangan;
  final int sumbangan;
  final bool konfirmasi;

  PermintaanTambahDonatur denganKonfirmasi() => PermintaanTambahDonatur(
        nama: nama,
        alamat: alamat,
        noHp: noHp,
        keterangan: keterangan,
        sumbangan: sumbangan,
        konfirmasi: true,
      );

  Json toJson() => {
        'nama': nama,
        'alamat': alamat,
        'no_hp': noHp,
        'keterangan': keterangan,
        'sumbangan': sumbangan,
        'konfirmasi': konfirmasi,
      };
}

class DonaturBaru {
  const DonaturBaru({
    required this.id,
    required this.nama,
    required this.alamat,
    required this.noHp,
    required this.keterangan,
  });

  factory DonaturBaru.fromJson(Json json) => DonaturBaru(
        id: _wajib<int>(json, 'id'),
        nama: _wajib<String>(json, 'nama'),
        alamat: _wajib<String>(json, 'alamat'),
        noHp: _wajib<String>(json, 'no_hp'),
        keterangan: _wajib<String>(json, 'keterangan'),
      );

  /// Nomor Register yang ditampilkan besar di kartu hasil.
  final int id;
  final String nama;
  final String alamat;
  final String noHp;
  final String keterangan;
}

class JawabanTambahDonatur {
  const JawabanTambahDonatur({
    required this.donatur,
    required this.sumbangan,
    required this.ringkasanHariIni,
  });

  factory JawabanTambahDonatur.fromJson(Json json) => JawabanTambahDonatur(
        donatur: DonaturBaru.fromJson(_wajib<Json>(json, 'donatur')),
        sumbangan: Sumbangan.fromJson(_wajib<Json>(json, 'sumbangan')),
        ringkasanHariIni: RingkasanHariIni.fromJson(_wajib<Json>(json, 'ringkasan_hari_ini')),
      );

  final DonaturBaru donatur;
  final Sumbangan sumbangan;
  final RingkasanHariIni ringkasanHariIni;
}

// ---------------------------------------------------------------------------
// 6.7 donasisaya

class PermintaanDonasiSaya {
  const PermintaanDonasiSaya({this.tanggal});

  /// `null` = hari ini menurut server.
  final DateTime? tanggal;

  Map<String, String> toQuery() => {if (tanggal != null) 'tanggal': tulisTanggal(tanggal!)};
}

class BarisDonasiSaya {
  const BarisDonasiSaya({
    required this.id,
    required this.waktu,
    required this.idDonatur,
    required this.namaDonatur,
    required this.jumlah,
    required this.bolehUbah,
    required this.noteN,
  });

  factory BarisDonasiSaya.fromJson(Json json) => BarisDonasiSaya(
        id: _wajib<int>(json, 'id'),
        waktu: _wajib<String>(json, 'waktu'),
        idDonatur: _wajib<int>(json, 'id_donatur'),
        namaDonatur: _boleh<String>(json, 'nama_donatur'),
        jumlah: _wajib<int>(json, 'jumlah'),
        bolehUbah: _wajib<bool>(json, 'boleh_ubah'),
        noteN: _boleh<bool>(json, 'note_n') ?? false,
      );

  final int id;
  final String waktu;
  final int idDonatur;
  final String? namaDonatur;
  final int jumlah;

  /// Hasil aturan K6 dari server; klien hanya mengizinkan Ubah bila benar.
  final bool bolehUbah;
  final bool noteN;
}

class DonasiSaya {
  const DonasiSaya({
    required this.tanggal,
    required this.total,
    required this.transaksi,
    required this.daftar,
  });

  factory DonasiSaya.fromJson(Json json) => DonasiSaya(
        tanggal: _tanggal(json, 'tanggal'),
        total: _wajib<int>(json, 'total'),
        transaksi: _wajib<int>(json, 'transaksi'),
        daftar: _daftar(json, 'daftar', BarisDonasiSaya.fromJson),
      );

  final DateTime tanggal;
  final int total;
  final int transaksi;
  final List<BarisDonasiSaya> daftar;
}

// ---------------------------------------------------------------------------
// 6.8 ubahdonasi

class PermintaanUbahDonasi {
  const PermintaanUbahDonasi({required this.id, required this.jumlah, this.konfirmasi = false});

  final int id;
  final int jumlah;
  final bool konfirmasi;

  PermintaanUbahDonasi denganKonfirmasi() =>
      PermintaanUbahDonasi(id: id, jumlah: jumlah, konfirmasi: true);

  Json toJson() => {'id': id, 'jumlah': jumlah, 'konfirmasi': konfirmasi};
}

class JawabanUbahDonasi {
  const JawabanUbahDonasi({required this.sumbangan, required this.bolehUbah});

  factory JawabanUbahDonasi.fromJson(Json json) {
    final sumbangan = _wajib<Json>(json, 'sumbangan');
    return JawabanUbahDonasi(
      sumbangan: Sumbangan.fromJson(sumbangan),
      bolehUbah: _wajib<bool>(sumbangan, 'boleh_ubah'),
    );
  }

  final Sumbangan sumbangan;
  final bool bolehUbah;
}

// ---------------------------------------------------------------------------
// 6.9 rekap

/// Nama nilai sama dengan nilai `periode` di kontrak.
enum Periode { hari, minggu, bulan }

/// Nama nilai sama dengan nilai `cakupan` di kontrak.
enum Cakupan { saya, semua }

class PermintaanRekap {
  const PermintaanRekap({required this.periode, this.tanggal, this.cakupan = Cakupan.saya});

  final Periode periode;

  /// `null` = hari ini menurut server.
  final DateTime? tanggal;
  final Cakupan cakupan;

  Map<String, String> toQuery() => {
        'periode': periode.name,
        if (tanggal != null) 'tanggal': tulisTanggal(tanggal!),
        'cakupan': cakupan.name,
      };
}

class RekapHari {
  const RekapHari({required this.tanggal, required this.transaksi, required this.total});

  factory RekapHari.fromJson(Json json) => RekapHari(
        tanggal: _tanggal(json, 'tanggal'),
        transaksi: _wajib<int>(json, 'transaksi'),
        total: _wajib<int>(json, 'total'),
      );

  final DateTime tanggal;
  final int transaksi;
  final int total;
}

class RekapOperator {
  const RekapOperator({
    required this.idUser,
    required this.nama,
    required this.transaksi,
    required this.total,
  });

  factory RekapOperator.fromJson(Json json) => RekapOperator(
        idUser: _boleh<int>(json, 'id_user'),
        nama: _wajib<String>(json, 'nama'),
        transaksi: _wajib<int>(json, 'transaksi'),
        total: _wajib<int>(json, 'total'),
      );

  /// `null` pada baris gabungan "User lama (sudah dihapus)".
  final int? idUser;
  final String nama;
  final int transaksi;
  final int total;
}

class NavigasiRekap {
  const NavigasiRekap({required this.sebelum, required this.sesudah});

  factory NavigasiRekap.fromJson(Json json) => NavigasiRekap(
        sebelum: _tanggal(json, 'sebelum'),
        sesudah: _tanggalBoleh(json, 'sesudah'),
      );

  final DateTime sebelum;

  /// `null` bila periode berikutnya dimulai setelah hari ini.
  final DateTime? sesudah;
}

class Rekap {
  const Rekap({
    required this.periode,
    required this.cakupan,
    required this.tanggal,
    required this.dari,
    required this.sampai,
    required this.total,
    required this.transaksi,
    required this.donatur,
    required this.perHari,
    required this.perOperator,
    required this.navigasi,
  });

  factory Rekap.fromJson(Json json) => Rekap(
        periode: _enum(Periode.values, json, 'periode'),
        cakupan: _enum(Cakupan.values, json, 'cakupan'),
        tanggal: _tanggal(json, 'tanggal'),
        dari: _tanggal(json, 'dari'),
        sampai: _tanggal(json, 'sampai'),
        total: _wajib<int>(json, 'total'),
        transaksi: _wajib<int>(json, 'transaksi'),
        donatur: _wajib<int>(json, 'donatur'),
        perHari: _daftar(json, 'per_hari', RekapHari.fromJson),
        perOperator: _daftar(json, 'per_operator', RekapOperator.fromJson),
        navigasi: NavigasiRekap.fromJson(_wajib<Json>(json, 'navigasi')),
      );

  final Periode periode;
  final Cakupan cakupan;
  final DateTime tanggal;
  final DateTime dari;
  final DateTime sampai;
  final int total;
  final int transaksi;

  /// Banyaknya donatur berbeda, bukan banyaknya transaksi.
  final int donatur;
  final List<RekapHari> perHari;
  final List<RekapOperator> perOperator;
  final NavigasiRekap navigasi;
}

// ---------------------------------------------------------------------------
// 6.10 gantipassword

class PermintaanGantiPassword {
  const PermintaanGantiPassword({required this.lama, required this.baru, required this.ulang});

  final String lama;
  final String baru;
  final String ulang;

  Json toJson() => {'lama': lama, 'baru': baru, 'ulang': ulang};
}

class JawabanGantiPassword {
  const JawabanGantiPassword({required this.token, required this.kedaluwarsa});

  factory JawabanGantiPassword.fromJson(Json json) => JawabanGantiPassword(
        token: _wajib<String>(json, 'token'),
        kedaluwarsa: _wajib<String>(json, 'kedaluwarsa'),
      );

  final String token;
  final String kedaluwarsa;
}
