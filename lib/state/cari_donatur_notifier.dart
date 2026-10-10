// State layar Cari Donatur (P2.2 docs/06_BUSINESS_PROCESS.md). Empat state docs/26_UI_CONVENTIONS.md:
// kosong = petunjuk 2 huruf, memuat = kerangka daftar, gagal = panel + Coba lagi, sukses = daftar
// atau "Tidak ada donatur yang cocok".

import 'dart:async';

import 'package:flutter/widgets.dart';

import '../api/galat_api.dart';
import '../api/klien_api.dart';
import '../api/model.dart';
import 'sesi.dart';

/// `q` 2–100 karakter setelah dipangkas (API_CONTRACT.md §6.4). Kurang dari itu tidak dikirim.
const panjangMinimalCari = 2;
const panjangMaksimalCari = 100;

/// Jeda setelah pengguna berhenti mengetik sebelum mencari, sama dengan Nama mirip P3 [ASUMSI].
const jedaCari = Duration(milliseconds: 500);

enum StatusCari { kosong, memuat, gagal, sukses }

class CariDonaturNotifier extends ChangeNotifier {
  CariDonaturNotifier(this._klien) {
    q.addListener(_qBerubah);
  }

  final KlienApi _klien;
  final q = TextEditingController();
  var _dibuang = false;
  var _qTerakhir = '';
  Timer? _tunda;

  // Naik setiap q berubah, sehingga jawaban untuk q lama dibuang.
  var _urut = 0;
  StatusCari _status = StatusCari.kosong;
  List<DonaturCari> _hasil = const [];
  var _lebih = false;
  String? _galatQ;
  String? _pesanPanel;

  StatusCari get status => _status;
  List<DonaturCari> get hasil => _hasil;

  /// Lebih dari 20 kecocokan: layar menampilkan "Persempit pencarian".
  bool get lebih => _lebih;

  /// `errorText` isian dari `rincian.q` 422.
  String? get galatQ => _galatQ;
  String? get pesanPanel => _pesanPanel;

  /// Tombol cari di keyboard dan Coba lagi: langsung, tanpa menunggu jeda.
  Future<void> cari() async {
    _tunda?.cancel();
    final teks = q.text.trim();
    if (teks.length < panjangMinimalCari) return;
    final urutan = ++_urut;
    _status = StatusCari.memuat;
    _galatQ = null;
    _pesanPanel = null;
    notifyListeners();

    try {
      final jawaban = await _klien.cariDonatur(teks);
      if (_dibuang || urutan != _urut) return;
      _hasil = jawaban.hasil;
      _lebih = jawaban.lebih;
      _status = StatusCari.sukses;
    } on GalatApi catch (galat) {
      if (_dibuang || urutan != _urut) return;
      final pesanQ = galat.kode == KodeGalat.tidakValid ? galat.rincian[KunciRincian.q] : null;
      if (pesanQ != null) {
        _galatQ = pesanQ;
        _status = StatusCari.kosong;
      } else {
        _gagal(teksGalat(galat, post: false));
      }
    } on GalatJaringan catch (galat) {
      if (_dibuang || urutan != _urut) return;
      _gagal(teksGalat(galat, post: false));
    } on GalatVersi {
      // Layar blokir versi diurus Sesi.
      if (_dibuang || urutan != _urut) return;
      _status = StatusCari.kosong;
    }
    notifyListeners();
  }

  void _gagal(String pesan) {
    _status = StatusCari.gagal;
    _pesanPanel = pesan;
  }

  void _qBerubah() {
    if (q.text == _qTerakhir) return;
    _qTerakhir = q.text;
    _tunda?.cancel();
    _urut++;
    _galatQ = null;
    if (q.text.trim().length < panjangMinimalCari) {
      _status = StatusCari.kosong;
      _hasil = const [];
      _lebih = false;
      _pesanPanel = null;
    } else {
      _tunda = Timer(jedaCari, cari);
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _dibuang = true;
    _tunda?.cancel();
    q.dispose();
    super.dispose();
  }
}
