// Sesi global: alamat server, token, konfigurasi, dan fase aplikasi (docs/08_ARCHITECTURE.md).
// Alur P0, P1, P6, dan P7 di docs/06_BUSINESS_PROCESS.md. Secure storage hanya memuat token,
// kedaluwarsa, alamat server, dan username terakhir (docs/21_SECURITY_RULES.md); pengguna dan
// peran selalu dari `konfigurasi` (docs/05_USER_ROLE.md).

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../api/galat_api.dart';
import '../api/klien_api.dart';
import '../api/model.dart';

/// Versi aplikasi untuk Pengaturan. Harus sama dengan `version` di pubspec.yaml (diuji di
/// test/layar/pengaturan_test.dart); membacanya saat berjalan butuh paket tambahan.
const versiAplikasi = '1.0.0+1';

enum FaseSesi {
  /// Membaca secure storage, lalu `konfigurasi` bila ada token.
  memuat,

  /// Tanpa token: layar Masuk.
  perluMasuk,

  /// Token sah dan konfigurasi ada: kerangka 4 tab.
  aktif,

  /// `konfigurasi` saat aplikasi dibuka gagal karena jaringan atau server. Token tidak dihapus.
  gagal,

  /// Versi kontrak server tidak cocok (kontrak §9): layar blokir.
  versiTidakCocok,
}

/// Alamat tanpa spasi dan tanpa garis miring di akhir.
String rapikanAlamat(String alamat) => alamat.trim().replaceFirst(RegExp(r'/+$'), '');

/// Pesan untuk isian Alamat Server, atau `null` bila alamat boleh dipakai. Build rilis hanya
/// menerima https; build debug juga http (docs/21_SECURITY_RULES.md §Transport).
String? periksaAlamat(String alamat, {required bool rilis}) {
  final rapi = rapikanAlamat(alamat);
  if (rapi.isEmpty) return 'Alamat server wajib diisi.';
  final uri = Uri.tryParse(rapi);
  final skema = rilis ? const {'https'} : const {'http', 'https'};
  if (uri == null ||
      !skema.contains(uri.scheme) ||
      uri.host.isEmpty ||
      uri.hasQuery ||
      uri.hasFragment) {
    return rilis ? 'Alamat harus memakai https.' : 'Alamat harus memakai http atau https.';
  }
  return null;
}

/// Tombol di panel galat; keduanya mengirim isian yang sama sekali lagi.
enum TombolPanel { tidakAda, cobaLagi, kirimUlang }

/// Teks milik klien (docs/14_ERROR_HANDLING.md §Teks milik klien dan §Tempat tampil). Selain ini,
/// layar menampilkan `pesan` server apa adanya.
abstract final class TeksGalat {
  static const jaringanPost =
      'Tidak dapat terhubung ke server. Periksa sinyal, lalu tekan Kirim ulang.';
  static const jaringanGet =
      'Tidak dapat terhubung ke server. Periksa sinyal, lalu tekan Coba lagi.';
  static const umum = 'Terjadi kesalahan. Coba lagi; bila berulang, hubungi admin.';
  static const apiMati = 'Layanan mobile belum diaktifkan di server.';
  static const alamatKosong = 'Alamat server belum diatur. Buka Pengaturan.';
  static const versi = 'Versi aplikasi tidak cocok dengan server. Perbarui aplikasi.';

  /// P6.3 docs/06_BUSINESS_PROCESS.md, di layar Masuk.
  static const putusGantiPassword =
      'Koneksi terputus. Masuk dengan password baru; bila gagal, pakai password lama.';
}

/// Teks panel untuk [GalatApi] atau [GalatJaringan] yang tidak punya tempat tampil khusus.
/// [post] memilih teks Kirim ulang (POST) atau Coba lagi (GET).
String teksGalat(Object galat, {required bool post}) {
  if (galat is GalatJaringan) return post ? TeksGalat.jaringanPost : TeksGalat.jaringanGet;
  if (galat is! GalatApi || galat.perluPesanUmum || galat.pesan.isEmpty) return TeksGalat.umum;
  if (galat.kode == KodeGalat.apiMati) return TeksGalat.apiMati;
  return galat.pesan;
}

abstract final class _Kunci {
  static const token = 'token';
  static const kedaluwarsa = 'kedaluwarsa';
  static const alamatServer = 'alamat_server';
  static const usernameTerakhir = 'username_terakhir';
}

class Sesi extends ChangeNotifier {
  Sesi({
    required String alamatBawaan,
    this._penyimpanan = const FlutterSecureStorage(),
    http.Client? klienHttp,
    this.rilis = kReleaseMode,
  })  : alamatBawaan =
            periksaAlamat(alamatBawaan, rilis: rilis) == null ? rapikanAlamat(alamatBawaan) : '' {
    klien = KlienApi(
      alamatServer: this.alamatBawaan,
      klien: klienHttp,
      padaTidakSah: _tidakSah,
      padaGalatVersi: _versiTidakCocok,
    );
  }

  /// Build rilis: hanya alamat https yang diterima.
  final bool rilis;

  /// `SERVER_URL` build ini, atau kosong bila tidak diisi atau tidak sah.
  final String alamatBawaan;

  final FlutterSecureStorage _penyimpanan;

  /// Satu klien untuk semua notifier; alamat dan tokennya mengikuti sesi.
  late final KlienApi klien;

  FaseSesi _fase = FaseSesi.memuat;
  bool _perluMasukUlang = false;
  String? _alamatTersimpan;
  String? _usernameTerakhir;
  String? _kedaluwarsa;
  Konfigurasi? _konfigurasi;
  String? _versiServer;
  Object? _galatAwal;
  String? _pesanMasuk;
  final _cekIsian = <bool Function()>{};

  FaseSesi get fase => _fase;

  /// 401 saat kerangka tampil: layar Masuk didorong di atas kerangka, isi tab tetap.
  bool get perluMasukUlang => _perluMasukUlang;

  /// Alamat di Pengaturan menang atas [alamatBawaan] (P0).
  String get alamatServer => _alamatTersimpan ?? alamatBawaan;
  bool get memakaiAlamatBawaan => _alamatTersimpan == null;
  String? get usernameTerakhir => _usernameTerakhir;
  String? get kedaluwarsa => _kedaluwarsa;
  Konfigurasi? get konfigurasi => _konfigurasi;

  /// `versi_api` terakhir yang diketahui, dari `konfigurasi` atau dari [GalatVersi].
  String? get versiServer => _versiServer;

  /// [GalatApi] atau [GalatJaringan] yang membuat fase [FaseSesi.gagal].
  Object? get galatAwal => _galatAwal;

  /// `pesan` server dari 401 terakhir, untuk ditampilkan di layar Masuk.
  String? get pesanMasuk => _pesanMasuk;

  bool get adaToken => klien.token != null;

  /// P0: baca secure storage, lalu `konfigurasi` bila ada token.
  Future<void> mulai() async {
    final isi = await _penyimpanan.readAll();
    final alamat = isi[_Kunci.alamatServer];
    _alamatTersimpan = alamat != null && periksaAlamat(alamat, rilis: rilis) == null ? alamat : null;
    klien.alamatServer = alamatServer;
    _usernameTerakhir = isi[_Kunci.usernameTerakhir];
    final token = isi[_Kunci.token];
    if (token == null) {
      _ubahFase(FaseSesi.perluMasuk);
      return;
    }
    klien.token = token;
    _kedaluwarsa = isi[_Kunci.kedaluwarsa];
    await _muatKonfigurasi();
  }

  /// Tombol Coba lagi pada fase [FaseSesi.gagal].
  Future<void> cobaLagi() async {
    _ubahFase(FaseSesi.memuat);
    await _muatKonfigurasi();
  }

  /// P1: `login`, simpan token, lalu `konfigurasi`. Galat diteruskan ke pemanggil;
  /// `login_gagal` tidak memicu alur 401 (KlienApi).
  Future<void> masuk({required String username, required String password}) async {
    final jawaban = await klien.login(PermintaanLogin(username: username, password: password));
    klien.token = jawaban.token;
    _kedaluwarsa = jawaban.kedaluwarsa;
    _usernameTerakhir = jawaban.pengguna.username;
    await Future.wait([
      _penyimpanan.write(key: _Kunci.token, value: jawaban.token),
      _penyimpanan.write(key: _Kunci.kedaluwarsa, value: jawaban.kedaluwarsa),
      _penyimpanan.write(key: _Kunci.usernameTerakhir, value: jawaban.pengguna.username),
    ]);
    _terimaKonfigurasi(await klien.konfigurasi());
  }

  /// P6 Ganti Password. 200: semua token lama batal, jadi token tersimpan diganti token baru.
  /// [GalatJaringan]: klien tidak tahu password mana yang berlaku (kontrak §6.10), maka token
  /// dihapus dan Masuk didorong di atas kerangka dengan pesan P6.3, seperti alur 401 sehingga
  /// isi tab tetap. Semua galat diteruskan ke pemanggil.
  Future<void> gantiPassword(PermintaanGantiPassword isi) async {
    final JawabanGantiPassword jawaban;
    try {
      jawaban = await klien.gantiPassword(isi);
    } on GalatJaringan {
      _mintaMasukUlang(TeksGalat.putusGantiPassword);
      rethrow;
    }
    klien.token = jawaban.token;
    _kedaluwarsa = jawaban.kedaluwarsa;
    notifyListeners();
    await Future.wait([
      _penyimpanan.write(key: _Kunci.token, value: jawaban.token),
      _penyimpanan.write(key: _Kunci.kedaluwarsa, value: jawaban.kedaluwarsa),
    ]);
  }

  /// P7 Keluar: tanpa aksi server. Alamat server dan username terakhir tetap tersimpan.
  Future<void> keluar() async {
    _lupakanSesi();
    _ubahFase(FaseSesi.perluMasuk);
    await _hapusToken();
  }

  /// P0.4: dipanggil saat aplikasi kembali ke depan.
  Future<void> segarkan() async {
    if (_fase == FaseSesi.gagal) return cobaLagi();
    if (_fase != FaseSesi.aktif || _perluMasukUlang || klien.token == null) return;
    try {
      _terimaKonfigurasi(await klien.konfigurasi());
    } on GalatApi {
      // 401 sudah ditangani _tidakSah. Galat lain tidak menutup kerangka: konfigurasi lama
      // tetap dipakai, dan permintaan berikutnya menampilkan galatnya sendiri.
    } on GalatJaringan {
      // Sinyal lemah saat resume bukan alasan menutup kerangka.
    } on GalatVersi {
      // Fase sudah diubah _versiTidakCocok.
    }
  }

  /// P7 Pengaturan. [alamat] `null` berarti kembali ke [alamatBawaan]. Mengembalikan pesan untuk
  /// isian Alamat Server, atau `null` bila tersimpan. Alamat yang berganti menghapus token,
  /// karena token itu milik server lama.
  Future<String?> ubahAlamat(String? alamat) async {
    if (alamat != null) {
      final galat = periksaAlamat(alamat, rilis: rilis);
      if (galat != null) return galat;
    }
    final baru = alamat == null ? null : rapikanAlamat(alamat);
    final berganti = (baru ?? alamatBawaan) != alamatServer;
    if (baru == null) {
      await _penyimpanan.delete(key: _Kunci.alamatServer);
    } else {
      await _penyimpanan.write(key: _Kunci.alamatServer, value: baru);
    }
    _alamatTersimpan = baru;
    klien.alamatServer = alamatServer;
    if (berganti) {
      _versiServer = null;
      if (_fase != FaseSesi.perluMasuk || klien.token != null) {
        _lupakanSesi();
        _ubahFase(FaseSesi.perluMasuk);
        await _hapusToken();
        return null;
      }
    }
    notifyListeners();
    return null;
  }

  /// Notifier layar mendaftarkan pemeriksa isian yang belum disimpan, untuk dialog Keluar (P7).
  void daftarkanCekIsian(bool Function() cek) => _cekIsian.add(cek);
  void lepasCekIsian(bool Function() cek) => _cekIsian.remove(cek);
  bool get adaIsianBelumDisimpan => _cekIsian.any((cek) => cek());

  Future<void> _muatKonfigurasi() async {
    try {
      _terimaKonfigurasi(await klien.konfigurasi());
    } on GalatVersi {
      // Fase sudah diubah _versiTidakCocok.
    } on GalatApi catch (galat) {
      // 401 sudah mengubah fase lewat _tidakSah.
      if (!galat.tidakSah) _gagal(galat);
    } on GalatJaringan catch (galat) {
      _gagal(galat);
    }
  }

  void _terimaKonfigurasi(Konfigurasi konfigurasi) {
    _konfigurasi = konfigurasi;
    _versiServer = konfigurasi.versiApi;
    _galatAwal = null;
    _pesanMasuk = null;
    _perluMasukUlang = false;
    _ubahFase(FaseSesi.aktif);
  }

  void _gagal(Object galat) {
    _galatAwal = galat;
    _ubahFase(FaseSesi.gagal);
  }

  /// 401 selain dari `login` (docs/14_ERROR_HANDLING.md): hapus token. Di kerangka, konfigurasi
  /// dibiarkan agar isi tab tetap bisa dipakai; masuk lagi menggantinya.
  void _tidakSah(GalatApi galat) => _mintaMasukUlang(galat.pesan.isEmpty ? null : galat.pesan);

  void _mintaMasukUlang(String? pesan) {
    klien.token = null;
    _kedaluwarsa = null;
    _pesanMasuk = pesan;
    if (_fase == FaseSesi.aktif) {
      _perluMasukUlang = true;
      notifyListeners();
    } else {
      _konfigurasi = null;
      _ubahFase(FaseSesi.perluMasuk);
    }
    unawaited(_hapusToken());
  }

  void _versiTidakCocok(GalatVersi galat) {
    _versiServer = galat.versiServer;
    _perluMasukUlang = false;
    _ubahFase(FaseSesi.versiTidakCocok);
  }

  void _lupakanSesi() {
    klien.token = null;
    _kedaluwarsa = null;
    _konfigurasi = null;
    _galatAwal = null;
    _pesanMasuk = null;
    _perluMasukUlang = false;
  }

  Future<void> _hapusToken() => Future.wait([
        _penyimpanan.delete(key: _Kunci.token),
        _penyimpanan.delete(key: _Kunci.kedaluwarsa),
      ]);

  void _ubahFase(FaseSesi fase) {
    _fase = fase;
    notifyListeners();
  }
}

/// Menyediakan [Sesi] di akar pohon widget (docs/08_ARCHITECTURE.md).
class SesiScope extends InheritedNotifier<Sesi> {
  const SesiScope({super.key, required Sesi sesi, required super.child}) : super(notifier: sesi);

  /// Sesi, dan widget dibangun ulang setiap kali sesi berubah.
  static Sesi of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SesiScope>()!.notifier!;

  /// Sesi tanpa berlangganan perubahan, untuk callback seperti `onPressed`.
  static Sesi baca(BuildContext context) =>
      context.getInheritedWidgetOfExactType<SesiScope>()!.notifier!;
}
