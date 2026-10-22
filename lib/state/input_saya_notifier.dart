// State layar Input Saya (P4 docs/06_BUSINESS_PROCESS.md). Empat state di docs/26_UI_CONVENTIONS.md:
// kosong = "Belum ada input pada tanggal ini", memuat = kerangka daftar, gagal = panel + Coba lagi,
// sukses = daftar + total. Total, boleh_ubah (K6), boleh_hapus (K23), dan note_n diputuskan server;
// notifier ini hanya meneruskan hasilnya. Hapus dikirim tanpa dialog (K23).

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../api/galat_api.dart';
import '../api/klien_api.dart';
import '../api/model.dart';
import '../util/tanggal.dart';
import 'sesi.dart';

/// Tanggal paling awal yang diterima `donasisaya` di server (2000-01-01 sampai 2100-12-31).
final tanggalPertamaInputSaya = DateTime.utc(2000);

enum StatusInputSaya { memuat, gagal, sukses }

class InputSayaNotifier extends ChangeNotifier {
  /// [padaHariIni] meneruskan total dan transaksi hari ini ke strip tab Input, karena `ubahdonasi`
  /// tidak membawa `ringkasan_hari_ini`.
  InputSayaNotifier(this._sesi, {this.padaHariIni}) {
    _sesi.addListener(_sesiBerubah);
  }

  final Sesi _sesi;
  final void Function(DonasiSaya hariIni)? padaHariIni;
  var _dibuang = false;

  // Pilihan pengguna; null = hari ini menurut server, dikirim tanpa `tanggal` (P4.1).
  DateTime? _pilihan;

  // Naik setiap memuat, sehingga jawaban permintaan sebelumnya dibuang.
  var _urut = 0;
  var _pernahDimuat = false;
  StatusInputSaya _status = StatusInputSaya.memuat;
  DonasiSaya? _data;
  String? _pesanGalat;
  String? _galatTanggal;

  // Hapus: satu kiriman pada satu waktu. Setelah galat jaringan atau pesan umum, kirimannya disimpan,
  // sehingga Kirim ulang atau Coba lagi memakai kunci yang sama (kontrak §7).
  int? _idDihapus;
  Kiriman<PermintaanHapusDonasi>? _hapusTertunda;
  String? _pesanHapus;
  TombolPanel _tombolHapus = TombolPanel.tidakAda;

  StatusInputSaya get status => _status;

  /// Jawaban terakhir untuk tanggal yang dipilih; `null` selama tanggal baru dimuat atau setelah
  /// gagal.
  DonasiSaya? get data => _data;

  /// Isi panel galat daftar; `null` bila galatnya hanya pada pilihan tanggal.
  String? get pesanGalat => _pesanGalat;

  /// `errorText` pilihan tanggal dari `rincian.tanggal` 422 (docs/14_ERROR_HANDLING.md).
  String? get galatTanggal => _galatTanggal;

  /// Id sumbangan yang sedang dihapus, sampai daftar selesai dimuat ulang; selama itu tidak ada hapus lain.
  int? get idDihapus => _idDihapus;

  /// Isi panel galat hapus di atas daftar.
  String? get pesanHapus => _pesanHapus;
  TombolPanel get tombolHapus => _tombolHapus;

  /// `konfigurasi.hari_ini`: batas akhir date picker (P4.1).
  DateTime? get hariIni => _sesi.konfigurasi?.hariIni;

  /// Tanggal yang ditampilkan. Tanpa pilihan, tanggal jawaban terakhir, sehingga daftar kemarin
  /// tetap berlabel kemarin bila `hari_ini` berganti sebelum dimuat ulang.
  DateTime? get tanggal => _pilihan ?? _data?.tanggal ?? hariIni;

  /// Tab Input Saya dibuka, tarik ke bawah, Coba lagi, atau setelah Ubah tersimpan: muat ulang
  /// tanggal yang dipilih. Daftar yang sudah tampil tetap ada sampai jawaban baru tiba.
  Future<void> muat() async {
    _pernahDimuat = true;
    final urutan = ++_urut;
    final pilihan = _pilihan;
    _status = StatusInputSaya.memuat;
    _pesanGalat = null;
    _galatTanggal = null;
    _lupakanGagalHapus();
    notifyListeners();

    try {
      final data = await _sesi.klien.donasiSaya(tanggal: pilihan);
      if (_dibuang || urutan != _urut) return;
      _data = data;
      _status = StatusInputSaya.sukses;
      if (pilihan == null) padaHariIni?.call(data);
    } on GalatApi catch (galat) {
      if (_dibuang || urutan != _urut) return;
      final rincian = galat.kode == KodeGalat.tidakValid ? {...galat.rincian} : <String, String>{};
      _galatTanggal = rincian.remove(KunciRincian.tanggal);
      _gagal(switch (_galatTanggal) {
        null => teksGalat(galat, post: false),
        _ when rincian.isEmpty => null,
        _ => rincian.values.join('\n'),
      });
    } on GalatJaringan catch (galat) {
      if (_dibuang || urutan != _urut) return;
      _gagal(teksGalat(galat, post: false));
    } on GalatVersi {
      // Layar blokir versi diurus Sesi.
      if (_dibuang || urutan != _urut) return;
      _gagal(TeksGalat.versi);
    }
    notifyListeners();
  }

  /// Hasil date picker. Tanggal yang sama dengan `hari_ini` dikirim tanpa `tanggal` (P4.1).
  Future<void> pilihTanggal(DateTime tanggal) {
    final baru = tanggalSaja(tanggal);
    _pilihan = baru == hariIni ? null : baru;
    _data = null;
    return muat();
  }

  /// Ikon hapus pada baris `boleh_hapus` (P4.6): langsung dikirim tanpa dialog konfirmasi, dengan kunci
  /// kirim ulang baru, lalu daftar dimuat ulang.
  Future<void> hapus(BarisDonasiSaya baris) async {
    if (!baris.bolehHapus || _idDihapus != null) return;
    await _hapus(Kiriman(PermintaanHapusDonasi(id: baris.id)));
  }

  /// Kirim ulang (galat jaringan) atau Coba lagi (pesan umum) di panel hapus: isi dan kunci sama.
  Future<void> kirimUlangHapus() async {
    final kiriman = _hapusTertunda;
    if (kiriman == null || _idDihapus != null) return;
    await _hapus(kiriman);
  }

  Future<void> _hapus(Kiriman<PermintaanHapusDonasi> kiriman) async {
    _idDihapus = kiriman.isi.id;
    _lupakanGagalHapus();
    notifyListeners();

    String? pesan;
    var tombol = TombolPanel.tidakAda;
    var muatUlang = false;
    try {
      await _sesi.klien.hapusDonasi(kiriman);
      muatUlang = true;
    } on GalatApi catch (galat) {
      if (galat.perluPesanUmum) {
        // Galat tidak disimpan server (kontrak §7), jadi Coba lagi boleh memakai kiriman yang sama.
        pesan = TeksGalat.umum;
        tombol = TombolPanel.cobaLagi;
      } else {
        // 403 dan 404: pesan server; 404 berarti sumbangan sudah tidak ada, jadi daftar dimuat ulang.
        pesan = teksGalat(galat, post: true);
        muatUlang = galat.kode == KodeGalat.tidakAda;
      }
    } on GalatJaringan catch (galat) {
      pesan = teksGalat(galat, post: true);
      tombol = TombolPanel.kirimUlang;
    } on GalatVersi {
      // Layar blokir versi diurus Sesi.
    }
    if (_dibuang) return;
    // Baris yang dihapus tetap menunjukkan indikator sampai daftar baru tiba.
    if (muatUlang) await muat();
    if (_dibuang) return;
    _idDihapus = null;
    _pesanHapus = pesan;
    _tombolHapus = tombol;
    _hapusTertunda = tombol == TombolPanel.tidakAda ? null : kiriman;
    notifyListeners();
  }

  void _lupakanGagalHapus() {
    _pesanHapus = null;
    _tombolHapus = TombolPanel.tidakAda;
    _hapusTertunda = null;
  }

  void _gagal(String? pesan) {
    _data = null;
    _status = StatusInputSaya.gagal;
    _pesanGalat = pesan;
  }

  /// Daftar dimuat ulang setelah masuk lagi (401) bila tadinya gagal, dan saat `hari_ini` berganti
  /// sementara yang tampil adalah hari ini (P0.4: resume melewati tengah malam).
  void _sesiBerubah() {
    final hariIni = this.hariIni;
    if (_dibuang ||
        !_pernahDimuat ||
        hariIni == null ||
        _sesi.fase != FaseSesi.aktif ||
        _sesi.perluMasukUlang ||
        _status == StatusInputSaya.memuat) {
      return;
    }
    final hariBerganti = _pilihan == null && _data != null && _data!.tanggal != hariIni;
    if (_status == StatusInputSaya.gagal || hariBerganti) unawaited(muat());
  }

  @override
  void dispose() {
    _dibuang = true;
    _sesi.removeListener(_sesiBerubah);
    super.dispose();
  }
}
