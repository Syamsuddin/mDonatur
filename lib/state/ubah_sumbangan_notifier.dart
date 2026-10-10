// State lembar Ubah Sumbangan (P4.3–P4.5 docs/06_BUSINESS_PROCESS.md). Hanya nominal yang dikirim;
// K6 dan K9 diputuskan server, notifier ini hanya meneruskan hasilnya. Tempat tampil galat:
// docs/14_ERROR_HANDLING.md.

import 'package:flutter/widgets.dart';

import '../api/galat_api.dart';
import '../api/klien_api.dart';
import '../api/model.dart';
import '../util/rupiah.dart';
import 'input_sumbangan_notifier.dart' show StatusSimpan, Tanya, batasNominalKecil;
import 'sesi.dart';

class UbahSumbanganNotifier extends ChangeNotifier {
  /// [padaTidakAda] memuat ulang daftar Input Saya bila sumbangan ini tidak ada lagi (404, P4.5).
  UbahSumbanganNotifier(this._sesi, this.baris, {this.padaTidakAda})
      : jumlah = TextEditingController(text: '${baris.jumlah}') {
    // Jumlah lama terpilih semua, sehingga ketikan langsung menggantinya.
    jumlah.selection = TextSelection(baseOffset: 0, extentOffset: jumlah.text.length);
    _jumlahTerakhir = jumlah.text;
    jumlah.addListener(_jumlahBerubah);
  }

  final Sesi _sesi;

  /// Baris Input Saya yang diketuk; hanya baris `boleh_ubah: true` yang membuka lembar ini.
  final BarisDonasiSaya baris;
  final VoidCallback? padaTidakAda;
  final TextEditingController jumlah;
  final fokusJumlah = FocusNode();
  var _dibuang = false;

  // Teks terakhir yang sudah ditanggapi; listener controller juga terpanggil saat kursor pindah.
  var _jumlahTerakhir = '';

  // _tertunda = kiriman terakhir yang belum terjawab sukses; Kirim ulang memakainya lagi.
  StatusSimpan _statusSimpan = StatusSimpan.siap;
  Kiriman<PermintaanUbahDonasi>? _tertunda;
  String? _galatJumlah;
  String? _pesanSimpan;
  TombolPanel _tombolSimpan = TombolPanel.tidakAda;
  JawabanUbahDonasi? _hasil;

  StatusSimpan get statusSimpan => _statusSimpan;
  String? get galatJumlah => _galatJumlah;
  String? get pesanSimpan => _pesanSimpan;
  TombolPanel get tombolSimpan => _tombolSimpan;

  /// Jawaban 200, atau 2xx dengan `"ulang": true`. Lembar menutup diri saat nilai ini terisi (P4.3).
  JawabanUbahDonasi? get hasil => _hasil;

  bool get _simpanMemuat => _statusSimpan == StatusSimpan.memuat;
  bool get bisaSimpan => bacaAngka(jumlah.text) != null && !_simpanMemuat && _hasil == null;
  bool get isianTerkunci => _simpanMemuat || _hasil != null;

  /// Lembar tidak bisa ditutup selama menunggu jawaban, agar hasilnya tidak hilang dari layar.
  bool get bisaDitutup => !_simpanMemuat;

  /// Tombol Simpan. Nominal < [batasNominalKecil] ditanyakan dulu (P4.3, sama dengan P2.4); setiap
  /// Simpan memakai kunci kirim ulang baru.
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
    await _kirim(Kiriman(PermintaanUbahDonasi(id: baris.id, jumlah: nilai)), tanya);
  }

  /// Kirim ulang (galat jaringan) atau Coba lagi (pesan umum): isi dan kunci sama persis.
  Future<void> kirimUlang(Tanya tanya) async {
    final kiriman = _tertunda;
    if (kiriman == null || _simpanMemuat) return;
    await _kirim(kiriman, tanya);
  }

  Future<void> _kirim(Kiriman<PermintaanUbahDonasi> kiriman, Tanya tanya) async {
    _tertunda = kiriman;
    _statusSimpan = StatusSimpan.memuat;
    _pesanSimpan = null;
    _tombolSimpan = TombolPanel.tidakAda;
    _galatJumlah = null;
    notifyListeners();

    try {
      final jawaban = await _sesi.klien.ubahDonasi(kiriman);
      if (_dibuang) return;
      _tertunda = null;
      _statusSimpan = StatusSimpan.siap;
      _hasil = jawaban;
      notifyListeners();
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

  /// 409 `perlu_konfirmasi` K9 (P4.5, sama dengan P2.6): Ya, simpan mengirim isi yang sama dengan
  /// `konfirmasi: true` dan kunci baru; Tidak kembali ke isian.
  Future<void> _konfirmasiServer(
    Kiriman<PermintaanUbahDonasi> kiriman,
    GalatApi galat,
    Tanya tanya,
  ) async {
    _tertunda = null;
    _statusSimpan = StatusSimpan.siap;
    notifyListeners();
    final ya = await tanya(
      judul: galat.pesan.isEmpty ? null : galat.pesan,
      nama: galat.donatur?.nama ?? baris.namaDonatur,
      isi: galat.alasan,
    );
    if (ya && !_dibuang) await _kirim(Kiriman(kiriman.isi.denganKonfirmasi()), tanya);
  }

  void _galatSimpan(GalatApi galat) {
    if (galat.kode == KodeGalat.tidakValid) {
      final rincian = {...galat.rincian};
      _galatJumlah = rincian.remove(KunciRincian.jumlah);
      if (rincian.isEmpty && _galatJumlah != null) {
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
      // 403 tidak_berhak dan 404 tidak_ada: pesan server di lembar (docs/14_ERROR_HANDLING.md).
      _gagalSimpan(teksGalat(galat, post: true), TombolPanel.tidakAda);
      if (galat.kode == KodeGalat.tidakAda) padaTidakAda?.call();
    }
  }

  void _gagalSimpan(String pesan, TombolPanel tombol) {
    if (tombol == TombolPanel.tidakAda) _tertunda = null;
    _statusSimpan = StatusSimpan.gagal;
    _pesanSimpan = pesan;
    _tombolSimpan = tombol;
    notifyListeners();
  }

  void _jumlahBerubah() {
    if (jumlah.text == _jumlahTerakhir) return;
    _jumlahTerakhir = jumlah.text;
    _galatJumlah = null;
    // Isian berubah setelah Simpan gagal: Kirim ulang tidak boleh lagi mengirim isi lama.
    if (_statusSimpan == StatusSimpan.gagal) {
      _tertunda = null;
      _statusSimpan = StatusSimpan.siap;
      _pesanSimpan = null;
      _tombolSimpan = TombolPanel.tidakAda;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _dibuang = true;
    jumlah.dispose();
    fokusJumlah.dispose();
    super.dispose();
  }
}
