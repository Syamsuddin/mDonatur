// State layar Input Saya (P4 docs/06_BUSINESS_PROCESS.md). Empat state di docs/26_UI_CONVENTIONS.md:
// kosong = "Belum ada input pada tanggal ini", memuat = kerangka daftar, gagal = panel + Coba lagi,
// sukses = daftar + total. Total, boleh_ubah (K6), dan note_n diputuskan server; notifier ini hanya
// meneruskan hasilnya.

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../api/galat_api.dart';
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

  StatusInputSaya get status => _status;

  /// Jawaban terakhir untuk tanggal yang dipilih; `null` selama tanggal baru dimuat atau setelah
  /// gagal.
  DonasiSaya? get data => _data;

  /// Isi panel galat daftar; `null` bila galatnya hanya pada pilihan tanggal.
  String? get pesanGalat => _pesanGalat;

  /// `errorText` pilihan tanggal dari `rincian.tanggal` 422 (docs/14_ERROR_HANDLING.md).
  String? get galatTanggal => _galatTanggal;

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
