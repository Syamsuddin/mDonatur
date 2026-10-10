// Tiga jenis galat yang boleh keluar dari KlienApi (docs/14_ERROR_HANDLING.md).
// Arti tiap kode dan tindakan yang diharapkan: API_CONTRACT.md §8.

/// Kode galat mesin dari katalog kontrak §8.
abstract final class KodeGalat {
  static const permintaanSalah = 'permintaan_salah';
  static const tokenTidakSah = 'token_tidak_sah';
  static const tokenKedaluwarsa = 'token_kedaluwarsa';
  static const akunNonaktif = 'akun_nonaktif';
  static const loginGagal = 'login_gagal';
  static const tidakBerhak = 'tidak_berhak';
  static const aksiTidakAda = 'aksi_tidak_ada';
  static const tidakAda = 'tidak_ada';
  static const metodeSalah = 'metode_salah';
  static const perluKonfirmasi = 'perlu_konfirmasi';
  static const donaturSudahAda = 'donatur_sudah_ada';
  static const kunciUlangBentrok = 'kunci_ulang_bentrok';
  static const fiturBelumTersedia = 'fitur_belum_tersedia';
  static const terlaluBesar = 'terlalu_besar';
  static const tipeTidakDidukung = 'tipe_tidak_didukung';
  static const tidakValid = 'tidak_valid';
  static const loginTerkunci = 'login_terkunci';
  static const galatServer = 'galat_server';
  static const apiMati = 'api_mati';

  static const semua = {
    permintaanSalah, tokenTidakSah, tokenKedaluwarsa, akunNonaktif, loginGagal,
    tidakBerhak, aksiTidakAda, tidakAda, metodeSalah, perluKonfirmasi,
    donaturSudahAda, kunciUlangBentrok, fiturBelumTersedia, terlaluBesar,
    tipeTidakDidukung, tidakValid, loginTerkunci, galatServer, apiMati,
  };

  /// Kode yang hanya muncul bila klien sendiri keliru; ditampilkan dengan pesan umum.
  static const bugKlien = {
    permintaanSalah, aksiTidakAda, metodeSalah, kunciUlangBentrok, terlaluBesar,
    tipeTidakDidukung,
  };
}

/// Donatur yang ikut dikirim bersama 409 `perlu_konfirmasi` pada `tambahdonasi`.
class DonaturKonfirmasi {
  const DonaturKonfirmasi({required this.id, required this.nama});

  final int id;
  final String nama;
}

/// Jawaban `ok: false` dari server, atau jawaban yang bukan JSON (kode kosong).
class GalatApi implements Exception {
  const GalatApi({
    required this.status,
    this.kode = '',
    this.pesan = '',
    this.rincian = const {},
    this.alasan = const [],
    this.donatur,
    this.sisaDetik,
    this.idDonatur,
  });

  final int status;
  final String kode;
  final String pesan;
  final Map<String, String> rincian;
  final List<String> alasan;
  final DonaturKonfirmasi? donatur;
  final int? sisaDetik;
  final int? idDonatur;

  bool get tidakSah => status == 401;

  /// Benar bila layar harus menampilkan pesan umum, bukan [pesan] server:
  /// jawaban bukan JSON, galat server, kode tak dikenal berstatus 5xx, atau bug klien.
  bool get perluPesanUmum =>
      kode.isEmpty ||
      kode == KodeGalat.galatServer ||
      KodeGalat.bugKlien.contains(kode) ||
      (status >= 500 && !KodeGalat.semua.contains(kode));

  @override
  String toString() => 'GalatApi($status, $kode)';
}

/// Timeout, tanpa jaringan, atau koneksi putus sebelum jawaban lengkap diterima.
class GalatJaringan implements Exception {
  const GalatJaringan();

  @override
  String toString() => 'GalatJaringan';
}

/// Versi kontrak server tidak cocok dengan versi yang dipakai aplikasi (kontrak §9).
class GalatVersi implements Exception {
  const GalatVersi(this.versiServer);

  final String versiServer;

  @override
  String toString() => 'GalatVersi($versiServer)';
}
