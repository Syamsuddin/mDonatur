// State layar Input Sumbangan (P2 docs/06_BUSINESS_PROCESS.md). Empat state Cek dan Simpan di
// docs/26_UI_CONVENTIONS.md; tempat tampil galat di docs/14_ERROR_HANDLING.md. Bintang, saran, K5,
// K9, dan hak memilih Note (K23) diputuskan server; notifier ini hanya meneruskan hasilnya.

import 'dart:async';

import 'package:flutter/widgets.dart';

import '../api/galat_api.dart';
import '../api/klien_api.dart';
import '../api/model.dart';
import '../util/rupiah.dart';
import 'sesi.dart';

/// Nominal di bawah ini ditanyakan di HP sebelum dikirim (keputusan T16, P2.4).
const batasNominalKecil = 1000;

/// Tombol nominal cepat hanya untuk `nominal_umum` sampai nilai ini: 50.000–300.000
/// (keputusan pemilik 10 Okt 2026, agar layar Input muat tanpa digulir).
const batasNominalCepat = 300000;

/// Dialog konfirmasi milik layar; `true` bila pengguna memilih Ya, simpan.
typedef Tanya = Future<bool> Function({String? judul, String? nama, required List<String> isi});

enum StatusCek { kosong, memuat, gagal, sukses }

enum StatusSimpan { siap, memuat, gagal }

enum StatusStrip { memuat, gagal, sukses }

class InputSumbanganNotifier extends ChangeNotifier {
  InputSumbanganNotifier(this._sesi) {
    nomor.addListener(_nomorBerubah);
    jumlah.addListener(_jumlahBerubah);
    _sesi.daftarkanCekIsian(_adaIsian);
    _sesi.addListener(_sesiBerubah);
    unawaited(muatStrip());
  }

  final Sesi _sesi;
  final nomor = TextEditingController();
  final jumlah = TextEditingController();
  final fokusNomor = FocusNode();
  final fokusJumlah = FocusNode();
  var _dibuang = false;

  // Teks terakhir yang sudah ditanggapi; listener controller juga terpanggil saat kursor pindah.
  var _nomorTerakhir = '';
  var _jumlahTerakhir = '';

  // Cek. _urutCek naik setiap nomor berubah, sehingga jawaban untuk nomor lama dibuang.
  var _urutCek = 0;
  StatusCek _statusCek = StatusCek.kosong;
  Donatur? _donatur;
  String? _nomorDicek;
  String? _galatNomor;
  String? _pesanCek;
  TombolPanel _tombolCek = TombolPanel.tidakAda;

  // Saran Jumlah: benar selama Jumlah masih berisi saran dari Cek (penanda "otomatis" web).
  var _jumlahOtomatis = false;
  var _mengisiSaran = false;

  // Pilihan Note admin (K23): bawaan y, dan kembali ke y setelah tersimpan (keputusan pemilik 12 Okt 2026).
  var _noteY = true;

  // Simpan. _tertunda = kiriman terakhir yang belum terjawab sukses; Kirim ulang memakainya lagi.
  StatusSimpan _statusSimpan = StatusSimpan.siap;
  Kiriman<PermintaanTambahDonasi>? _tertunda;
  String? _galatJumlah;
  String? _pesanSimpan;
  TombolPanel _tombolSimpan = TombolPanel.tidakAda;
  Sumbangan? _hasil;

  // Strip hari ini: satu baris total dan banyaknya input (P2.1).
  var _urutStrip = 0;
  StatusStrip _statusStrip = StatusStrip.memuat;
  Object? _galatStrip;
  DateTime? _tanggalStrip;
  var _totalHariIni = 0;
  var _transaksiHariIni = 0;

  StatusCek get statusCek => _statusCek;

  /// Hasil Cek untuk nomor yang tertulis; `null` sejak nomor diubah.
  Donatur? get donatur => _donatur;

  /// `errorText` isian Nomor Donator: `pesan` 404, atau `rincian` 422.
  String? get galatNomor => _galatNomor;
  String? get pesanCek => _pesanCek;
  TombolPanel get tombolCek => _tombolCek;

  StatusSimpan get statusSimpan => _statusSimpan;
  String? get galatJumlah => _galatJumlah;
  String? get pesanSimpan => _pesanSimpan;
  TombolPanel get tombolSimpan => _tombolSimpan;

  /// Sumbangan yang baru tersimpan, untuk kartu hasil.
  Sumbangan? get hasil => _hasil;

  /// `konfigurasi.boleh_atur_note` (admin): pilihan Note hanya tampil bila benar.
  bool get bolehAturNote => _sesi.konfigurasi?.bolehAturNote ?? false;

  /// Centang Note: benar = Note y, salah = Note n.
  bool get noteY => _noteY;

  StatusStrip get statusStrip => _statusStrip;
  Object? get galatStrip => _galatStrip;
  int get totalHariIni => _totalHariIni;
  int get transaksiHariIni => _transaksiHariIni;

  bool get _simpanMemuat => _statusSimpan == StatusSimpan.memuat;
  bool get bisaCek =>
      bacaAngka(nomor.text) != null && _statusCek != StatusCek.memuat && !_simpanMemuat;

  /// Simpan hanya aktif bila ada hasil Cek untuk nomor yang tertulis (P2.2) dan Jumlah terisi.
  bool get bisaSimpan =>
      _donatur != null &&
      nomor.text == _nomorDicek &&
      bacaAngka(jumlah.text) != null &&
      !_simpanMemuat;
  bool get isianTerkunci => _simpanMemuat;

  bool _adaIsian() => nomor.text.isNotEmpty || jumlah.text.isNotEmpty;

  /// Tombol Cek, Coba lagi di panel Cek, dan hasil pilihan Cari Donatur.
  Future<void> cek() async {
    final teks = nomor.text;
    final id = bacaAngka(teks);
    if (id == null || _simpanMemuat) return;
    final urutan = ++_urutCek;
    _statusCek = StatusCek.memuat;
    _galatNomor = null;
    _pesanCek = null;
    _tombolCek = TombolPanel.tidakAda;
    notifyListeners();

    try {
      final donatur = await _sesi.klien.donatur(id);
      if (_dibuang || urutan != _urutCek) return;
      _donatur = donatur;
      _nomorDicek = teks;
      _hasil = null;
      _statusCek = StatusCek.sukses;
      _isiSaran(donatur.saranJumlah);
      notifyListeners();
      // Keyboard ditutup agar kartu donatur dan Simpan terlihat untuk diperiksa sebelum menyimpan.
      fokusNomor.unfocus();
      fokusJumlah.unfocus();
    } on GalatApi catch (galat) {
      if (_dibuang || urutan != _urutCek) return;
      _galatCek(galat);
    } on GalatJaringan catch (galat) {
      if (_dibuang || urutan != _urutCek) return;
      _gagalCek(teksGalat(galat, post: false), TombolPanel.cobaLagi);
    } on GalatVersi {
      // Layar blokir versi diurus Sesi.
      if (_dibuang || urutan != _urutCek) return;
      _statusCek = StatusCek.kosong;
      notifyListeners();
    }
  }

  /// Ketuk satu hasil Cari Donatur: nomor terisi, lalu Cek otomatis (P2.2).
  Future<void> pilihDonatur(int id) {
    final teks = '$id';
    nomor.value = _nilaiAkhir(teks);
    return cek();
  }

  /// Ketukan nominal cepat sama dengan ketikan pengguna: menghapus penanda saran.
  void pilihNominal(int nilai) {
    if (_simpanMemuat) return;
    final teks = '$nilai';
    jumlah.value = _nilaiAkhir(teks);
  }

  /// Centang Note diubah. Sama dengan mengubah isian: Kirim ulang tidak boleh lagi mengirim isi lama.
  void aturNote(bool y) {
    if (_simpanMemuat || y == _noteY) return;
    _noteY = y;
    _lupakanGagalSimpan();
    notifyListeners();
  }

  static TextEditingValue _nilaiAkhir(String teks) =>
      TextEditingValue(text: teks, selection: TextSelection.collapsed(offset: teks.length));

  /// Tombol Simpan. Jumlah < [batasNominalKecil] ditanyakan dulu (P2.4); setiap Simpan memakai
  /// kunci kirim ulang baru.
  Future<void> simpan(Tanya tanya) async {
    if (!bisaSimpan) return;
    final nilai = bacaAngka(jumlah.text)!;
    if (nilai < batasNominalKecil) {
      final ya = await tanya(isi: ['Nominal ${formatRupiah(nilai)} — benar?']);
      if (_dibuang) return;
      if (!ya) {
        fokusJumlah.requestFocus();
        return;
      }
      if (!bisaSimpan) return;
    }
    final noteN = bolehAturNote && !_noteY;
    await _kirim(Kiriman(PermintaanTambahDonasi(idDonatur: _donatur!.id, jumlah: nilai, noteN: noteN)), tanya);
  }

  /// Kirim ulang (galat jaringan) atau Coba lagi (pesan umum): isi dan kunci sama persis.
  Future<void> kirimUlang(Tanya tanya) async {
    final kiriman = _tertunda;
    if (kiriman == null || _simpanMemuat) return;
    await _kirim(kiriman, tanya);
  }

  Future<void> _kirim(Kiriman<PermintaanTambahDonasi> kiriman, Tanya tanya) async {
    _tertunda = kiriman;
    _statusSimpan = StatusSimpan.memuat;
    _pesanSimpan = null;
    _tombolSimpan = TombolPanel.tidakAda;
    _galatJumlah = null;
    notifyListeners();

    try {
      final jawaban = await _sesi.klien.tambahDonasi(kiriman);
      if (_dibuang) return;
      _tersimpan(jawaban);
    } on GalatApi catch (galat) {
      if (_dibuang) return;
      if (galat.kode == KodeGalat.perluKonfirmasi) {
        await _konfirmasiServer(kiriman, galat, tanya);
      } else {
        _galatSimpan(galat);
      }
    } on GalatJaringan catch (galat) {
      // Isian dan kiriman tetap; Kirim ulang memakai kunci yang sama (kontrak §7).
      if (!_dibuang) _gagalSimpan(teksGalat(galat, post: true), TombolPanel.kirimUlang);
    } on GalatVersi {
      if (_dibuang) return;
      _tertunda = null;
      _statusSimpan = StatusSimpan.siap;
      notifyListeners();
    }
  }

  /// 409 `perlu_konfirmasi` (P2.6): Ya, simpan mengirim isi yang sama dengan `konfirmasi: true`
  /// dan kunci baru; Tidak kembali ke isian.
  Future<void> _konfirmasiServer(
    Kiriman<PermintaanTambahDonasi> kiriman,
    GalatApi galat,
    Tanya tanya,
  ) async {
    _tertunda = null;
    _statusSimpan = StatusSimpan.siap;
    notifyListeners();
    final ya = await tanya(
      judul: galat.pesan.isEmpty ? null : galat.pesan,
      nama: galat.donatur?.nama,
      isi: galat.alasan,
    );
    if (ya && !_dibuang) await _kirim(Kiriman(kiriman.isi.denganKonfirmasi()), tanya);
  }

  /// 201, atau 2xx dengan `"ulang": true` (P2.5).
  void _tersimpan(JawabanTambahDonasi jawaban) {
    _tertunda = null;
    _statusSimpan = StatusSimpan.siap;
    _hasil = jawaban.sumbangan;
    _terimaRingkasan(jawaban.ringkasanHariIni);
    // Mengosongkan nomor juga menutup kartu donatur (_nomorBerubah).
    nomor.clear();
    _mengisiSaran = true;
    jumlah.clear();
    _mengisiSaran = false;
    _jumlahOtomatis = false;
    _noteY = true;
    notifyListeners();
    fokusNomor.requestFocus();
  }

  void _galatCek(GalatApi galat) {
    if (galat.kode == KodeGalat.tidakAda && galat.pesan.isNotEmpty) {
      _galatNomor = galat.pesan;
      _statusCek = StatusCek.gagal;
      notifyListeners();
    } else if (galat.kode == KodeGalat.tidakValid) {
      final rincian = {...galat.rincian};
      _galatNomor = rincian.remove(KunciRincian.id) ?? rincian.remove(KunciRincian.idDonatur);
      if (rincian.isEmpty && _galatNomor != null) {
        _statusCek = StatusCek.gagal;
        notifyListeners();
      } else {
        _gagalCek(rincian.isEmpty ? galat.pesan : rincian.values.join('\n'), TombolPanel.tidakAda);
      }
    } else {
      _gagalCek(teksGalat(galat, post: false),
          galat.perluPesanUmum ? TombolPanel.cobaLagi : TombolPanel.tidakAda);
    }
  }

  void _gagalCek(String pesan, TombolPanel tombol) {
    _statusCek = StatusCek.gagal;
    _pesanCek = pesan;
    _tombolCek = tombol;
    notifyListeners();
  }

  void _galatSimpan(GalatApi galat) {
    if (galat.kode == KodeGalat.tidakValid) {
      final rincian = {...galat.rincian};
      _galatNomor = rincian.remove(KunciRincian.idDonatur);
      _galatJumlah = rincian.remove(KunciRincian.jumlah);
      if (rincian.isEmpty && (_galatNomor != null || _galatJumlah != null)) {
        _tertunda = null;
        _statusSimpan = StatusSimpan.gagal;
        notifyListeners();
      } else {
        _gagalSimpan(rincian.isEmpty ? galat.pesan : rincian.values.join('\n'), TombolPanel.tidakAda);
      }
    } else if (galat.perluPesanUmum) {
      // Galat tidak disimpan server (kontrak §7), jadi Coba lagi boleh memakai kiriman yang sama.
      _gagalSimpan(TeksGalat.umum, TombolPanel.cobaLagi);
    } else {
      _gagalSimpan(teksGalat(galat, post: true), TombolPanel.tidakAda);
    }
  }

  void _gagalSimpan(String pesan, TombolPanel tombol) {
    if (tombol == TombolPanel.tidakAda) _tertunda = null;
    _statusSimpan = StatusSimpan.gagal;
    _pesanSimpan = pesan;
    _tombolSimpan = tombol;
    notifyListeners();
  }

  /// Saran mengisi Jumlah hanya bila Jumlah kosong atau masih berisi saran sebelumnya; tanpa saran,
  /// saran lama dihapus. Sama dengan `isiSaranJumlah()` web (Fase 11).
  void _isiSaran(int? saran) {
    if (jumlah.text.isNotEmpty && !_jumlahOtomatis) return;
    final teks = saran == null ? '' : '$saran';
    _mengisiSaran = true;
    // Seluruh saran terpilih, sehingga ketikan langsung menggantinya.
    jumlah.value = TextEditingValue(
      text: teks,
      selection: TextSelection(baseOffset: 0, extentOffset: teks.length),
    );
    _mengisiSaran = false;
    _jumlahOtomatis = saran != null;
  }

  void _nomorBerubah() {
    if (nomor.text == _nomorTerakhir) return;
    _nomorTerakhir = nomor.text;
    // Mengubah nomor membuang hasil Cek (P2.2) dan jawaban Cek yang masih ditunggu.
    _urutCek++;
    _donatur = null;
    _nomorDicek = null;
    _statusCek = StatusCek.kosong;
    _galatNomor = null;
    _pesanCek = null;
    _tombolCek = TombolPanel.tidakAda;
    _lupakanGagalSimpan();
    notifyListeners();
  }

  void _jumlahBerubah() {
    if (jumlah.text == _jumlahTerakhir) return;
    _jumlahTerakhir = jumlah.text;
    if (!_mengisiSaran) {
      _jumlahOtomatis = false;
      _galatJumlah = null;
      _lupakanGagalSimpan();
    }
    notifyListeners();
  }

  /// Isian berubah setelah Simpan gagal: Kirim ulang tidak boleh lagi mengirim isi lama.
  void _lupakanGagalSimpan() {
    if (_statusSimpan != StatusSimpan.gagal) return;
    _tertunda = null;
    _statusSimpan = StatusSimpan.siap;
    _pesanSimpan = null;
    _tombolSimpan = TombolPanel.tidakAda;
  }

  /// P2.1: `donasisaya` tanpa tanggal untuk total dan banyaknya input hari ini.
  Future<void> muatStrip() async {
    final urutan = ++_urutStrip;
    _statusStrip = StatusStrip.memuat;
    _galatStrip = null;
    notifyListeners();
    try {
      final saya = await _sesi.klien.donasiSaya();
      if (_dibuang || urutan != _urutStrip) return;
      _isiStrip(saya.tanggal, saya.total, saya.transaksi);
    } on GalatApi catch (galat) {
      if (_dibuang || urutan != _urutStrip) return;
      _gagalStrip(galat);
    } on GalatJaringan catch (galat) {
      if (_dibuang || urutan != _urutStrip) return;
      _gagalStrip(galat);
    } on GalatVersi catch (galat) {
      if (_dibuang || urutan != _urutStrip) return;
      _gagalStrip(galat);
    }
    notifyListeners();
  }

  void _gagalStrip(Object galat) {
    _galatStrip = galat;
    _statusStrip = StatusStrip.gagal;
  }

  /// `ringkasan_hari_ini` dari tab lain (`tambahdonatur`, P3.4) memperbarui strip.
  void terimaRingkasan(RingkasanHariIni ringkasan) {
    if (_dibuang) return;
    _terimaRingkasan(ringkasan);
    notifyListeners();
  }

  void _terimaRingkasan(RingkasanHariIni ringkasan) {
    // Jawaban donasisaya yang masih ditunggu lebih lama dari ringkasan ini.
    _urutStrip++;
    _isiStrip(ringkasan.tanggal, ringkasan.total, ringkasan.transaksi);
  }

  /// `donasisaya` tanpa tanggal dari tab Input Saya memperbarui strip (P4), karena `ubahdonasi`
  /// tidak membawa `ringkasan_hari_ini`.
  void terimaHariIni(DonasiSaya hariIni) {
    if (_dibuang) return;
    _urutStrip++;
    _isiStrip(hariIni.tanggal, hariIni.total, hariIni.transaksi);
    notifyListeners();
  }

  void _isiStrip(DateTime tanggal, int total, int transaksi) {
    _tanggalStrip = tanggal;
    _totalHariIni = total;
    _transaksiHariIni = transaksi;
    _galatStrip = null;
    _statusStrip = StatusStrip.sukses;
  }

  /// Strip dimuat ulang setelah masuk lagi (401) bila tadinya gagal, dan saat `hari_ini` berganti
  /// (P0.4: resume melewati tengah malam).
  void _sesiBerubah() {
    final konfigurasi = _sesi.konfigurasi;
    if (_dibuang ||
        konfigurasi == null ||
        _sesi.fase != FaseSesi.aktif ||
        _sesi.perluMasukUlang ||
        _statusStrip == StatusStrip.memuat) {
      return;
    }
    if (_statusStrip == StatusStrip.gagal || konfigurasi.hariIni != _tanggalStrip) {
      unawaited(muatStrip());
    }
  }

  @override
  void dispose() {
    _dibuang = true;
    _sesi.removeListener(_sesiBerubah);
    _sesi.lepasCekIsian(_adaIsian);
    nomor.dispose();
    jumlah.dispose();
    fokusNomor.dispose();
    fokusJumlah.dispose();
    super.dispose();
  }
}
