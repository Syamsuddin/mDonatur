// State layar Rekap (P5 docs/06_BUSINESS_PROCESS.md). Empat state di docs/26_UI_CONVENTIONS.md:
// kosong = "Tidak ada sumbangan pada periode ini", memuat = kerangka kartu, gagal = panel + Coba
// lagi, sukses = ringkasan + rincian. Rentang, angka, dan tanggal navigasi dihitung server
// (kontrak §6.9); notifier ini hanya memegang pilihan periode, cakupan, dan tanggal.

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../api/galat_api.dart';
import '../api/model.dart';
import 'sesi.dart';

enum StatusRekap { memuat, gagal, sukses }

class RekapNotifier extends ChangeNotifier {
  RekapNotifier(this._sesi) {
    _sesi.addListener(_sesiBerubah);
  }

  final Sesi _sesi;
  var _dibuang = false;

  // Bawaan P5.1: Hari, Input saya, hari ini.
  var _periode = Periode.hari;
  var _cakupan = Cakupan.saya;

  // null = hari ini menurut server, dikirim tanpa `tanggal`. Panah mengisinya dengan tanggal
  // `navigasi`; mengganti segmen tidak mengubahnya (P5.2).
  DateTime? _tanggal;

  // Naik setiap memuat, sehingga jawaban permintaan sebelumnya dibuang.
  var _urut = 0;
  var _pernahDimuat = false;
  StatusRekap _status = StatusRekap.memuat;
  Rekap? _data;
  String? _pesanGalat;

  Periode get periode => _periode;
  Cakupan get cakupan => _cakupan;
  StatusRekap get status => _status;

  /// Jawaban terakhir untuk pilihan yang tampil; `null` selama pilihan baru dimuat atau setelah
  /// gagal.
  Rekap? get data => _data;

  /// Isi panel galat.
  String? get pesanGalat => _pesanGalat;

  /// Tab Rekap dibuka, tarik ke bawah, atau Coba lagi: muat ulang pilihan yang sama. Rekap yang
  /// sudah tampil tetap ada sampai jawaban baru tiba.
  Future<void> muat() async {
    _pernahDimuat = true;
    final urutan = ++_urut;
    final permintaan = PermintaanRekap(periode: _periode, tanggal: _tanggal, cakupan: _cakupan);
    _status = StatusRekap.memuat;
    _pesanGalat = null;
    notifyListeners();

    try {
      final data = await _sesi.klien.rekap(permintaan);
      if (_dibuang || urutan != _urut) return;
      _data = data;
      _status = StatusRekap.sukses;
    } on GalatApi catch (galat) {
      if (_dibuang || urutan != _urut) return;
      // `rincian` 422 menyebut periode, tanggal, atau cakupan; layar ini tidak punya isian untuk
      // kunci itu, jadi isinya tampil di panel (docs/14_ERROR_HANDLING.md).
      final rincian = galat.kode == KodeGalat.tidakValid ? galat.rincian.values : const <String>[];
      _gagal(rincian.isEmpty ? teksGalat(galat, post: false) : rincian.join('\n'));
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

  /// Segmen Hari / Minggu / Bulan, dengan tanggal yang sama (P5.2).
  Future<void> pilihPeriode(Periode periode) async {
    if (periode == _periode) return;
    _periode = periode;
    return _ganti();
  }

  /// Segmen Input saya / Semua operator, dengan tanggal yang sama (P5.2).
  Future<void> pilihCakupan(Cakupan cakupan) async {
    if (cakupan == _cakupan) return;
    _cakupan = cakupan;
    return _ganti();
  }

  /// Panah ←: periode `navigasi.sebelum`.
  Future<void> sebelumnya() async {
    final data = _data;
    if (data == null) return;
    _tanggal = data.navigasi.sebelum;
    return _ganti();
  }

  /// Panah →: periode `navigasi.sesudah`; tidak berbuat apa-apa bila nilainya `null`.
  Future<void> berikutnya() async {
    final sesudah = _data?.navigasi.sesudah;
    if (sesudah == null) return;
    _tanggal = sesudah;
    return _ganti();
  }

  /// Angka periode lain tidak boleh tampil di bawah judul periode baru: kosongkan dulu.
  Future<void> _ganti() {
    _data = null;
    return muat();
  }

  void _gagal(String pesan) {
    _data = null;
    _status = StatusRekap.gagal;
    _pesanGalat = pesan;
  }

  /// Rekap dimuat ulang setelah masuk lagi (401) bila tadinya gagal, dan saat `hari_ini` berganti
  /// sementara yang tampil adalah hari ini (P0.4: resume melewati tengah malam).
  void _sesiBerubah() {
    final hariIni = _sesi.konfigurasi?.hariIni;
    if (_dibuang ||
        !_pernahDimuat ||
        hariIni == null ||
        _sesi.fase != FaseSesi.aktif ||
        _sesi.perluMasukUlang ||
        _status == StatusRekap.memuat) {
      return;
    }
    final hariBerganti = _tanggal == null && _data != null && _data!.tanggal != hariIni;
    if (_status == StatusRekap.gagal || hariBerganti) unawaited(muat());
  }

  @override
  void dispose() {
    _dibuang = true;
    _sesi.removeListener(_sesiBerubah);
    super.dispose();
  }
}
