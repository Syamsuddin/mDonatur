// State layar Ganti Password (P6 docs/06_BUSINESS_PROCESS.md). Empat state docs/26_UI_CONVENTIONS.md:
// kosong = isian, memuat = Simpan nonaktif + indikator, gagal = errorText / panel galat, sukses =
// pesan sukses. Semua pemeriksaan diputuskan server (kontrak §6.10). Password tidak pernah disimpan,
// dan isian dikosongkan begitu server menjawab (docs/21_SECURITY_RULES.md).

import 'package:flutter/widgets.dart';

import '../api/galat_api.dart';
import '../api/model.dart';
import 'sesi.dart';

enum StatusGantiPassword {
  kosong,
  memuat,
  gagal,
  sukses,

  /// Koneksi putus setelah mengirim (P6.3): Sesi sudah menghapus token dan mendorong Masuk;
  /// layar menutup dirinya.
  putus,
}

class GantiPasswordNotifier extends ChangeNotifier {
  GantiPasswordNotifier(this._sesi);

  final Sesi _sesi;
  final lama = TextEditingController();
  final baru = TextEditingController();
  final ulang = TextEditingController();
  var _dibuang = false;

  StatusGantiPassword _status = StatusGantiPassword.kosong;
  String? _pesanPanel;
  TombolPanel _tombol = TombolPanel.tidakAda;
  Map<String, String> _galatIsian = const {};

  StatusGantiPassword get status => _status;
  String? get pesanPanel => _pesanPanel;
  TombolPanel get tombol => _tombol;

  /// `errorText` dari `rincian` 422 (docs/14_ERROR_HANDLING.md §Pemetaan rincian).
  String? get galatLama => _galatIsian[KunciRincian.lama];
  String? get galatBaru => _galatIsian[KunciRincian.baru];
  String? get galatUlang => _galatIsian[KunciRincian.ulang];

  Future<void> kirim() async {
    if (_status == StatusGantiPassword.memuat) return;
    _status = StatusGantiPassword.memuat;
    _pesanPanel = null;
    _tombol = TombolPanel.tidakAda;
    _galatIsian = const {};
    notifyListeners();

    final isi = PermintaanGantiPassword(lama: lama.text, baru: baru.text, ulang: ulang.text);
    try {
      await _sesi.gantiPassword(isi);
      if (_dibuang) return;
      _kosongkan();
      _ubah(StatusGantiPassword.sukses);
    } on GalatApi catch (galat) {
      if (!_dibuang) _galatApi(galat);
    } on GalatJaringan {
      if (_dibuang) return;
      _kosongkan();
      _ubah(StatusGantiPassword.putus);
    } on GalatVersi {
      // Layar blokir versi diurus Sesi.
      if (_dibuang) return;
      _kosongkan();
      _ubah(StatusGantiPassword.kosong);
    }
  }

  void _galatApi(GalatApi galat) {
    if (galat.perluPesanUmum) {
      // Server tidak memutuskan apa pun; isian tetap agar Coba lagi mengirim yang sama.
      _tampilkan(TeksGalat.umum, tombol: TombolPanel.cobaLagi);
      return;
    }
    _kosongkan();
    if (galat.tidakSah) {
      // Masuk sudah didorong Sesi di atas layar ini.
      _ubah(StatusGantiPassword.kosong);
      return;
    }
    if (galat.kode == KodeGalat.tidakValid) {
      const isian = {KunciRincian.lama, KunciRincian.baru, KunciRincian.ulang};
      _galatIsian = {
        for (final e in galat.rincian.entries)
          if (isian.contains(e.key)) e.key: e.value,
      };
      final sisa = [
        for (final e in galat.rincian.entries)
          if (!isian.contains(e.key)) e.value,
      ];
      if (sisa.isEmpty && _galatIsian.isNotEmpty) {
        _ubah(StatusGantiPassword.gagal);
      } else {
        _tampilkan(sisa.isEmpty ? galat.pesan : sisa.join('\n'));
      }
    } else {
      // fitur_belum_tersedia, login_terkunci, api_mati, dan kode lain: pesan server di panel.
      _tampilkan(teksGalat(galat, post: true));
    }
  }

  void _kosongkan() {
    lama.clear();
    baru.clear();
    ulang.clear();
  }

  void _tampilkan(String pesan, {TombolPanel tombol = TombolPanel.tidakAda}) {
    _pesanPanel = pesan;
    _tombol = tombol;
    _ubah(StatusGantiPassword.gagal);
  }

  void _ubah(StatusGantiPassword status) {
    _status = status;
    notifyListeners();
  }

  @override
  void dispose() {
    _dibuang = true;
    lama.dispose();
    baru.dispose();
    ulang.dispose();
    super.dispose();
  }
}
