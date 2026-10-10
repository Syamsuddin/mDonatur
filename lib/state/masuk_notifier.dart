// State layar Masuk (P1 docs/06_BUSINESS_PROCESS.md). Empat state docs/26_UI_CONVENTIONS.md:
// kosong = isian, memuat = Masuk nonaktif + indikator, gagal = panel galat, sukses = tab Input
// (diurus Sesi). Tempat tampil tiap galat: docs/14_ERROR_HANDLING.md.

import 'package:flutter/widgets.dart';

import '../api/galat_api.dart';
import 'sesi.dart';

enum StatusMasuk { kosong, memuat, gagal }

class MasukNotifier extends ChangeNotifier {
  MasukNotifier(this._sesi)
      : username = TextEditingController(text: _sesi.usernameTerakhir ?? ''),
        password = TextEditingController() {
    // 401 di tengah pemakaian, atau saat aplikasi dibuka: tampilkan pesan server.
    final pesan = _sesi.pesanMasuk;
    if (pesan != null) {
      _status = StatusMasuk.gagal;
      _pesanPanel = pesan;
    }
  }

  final Sesi _sesi;
  final TextEditingController username;
  final TextEditingController password;
  var _dibuang = false;

  StatusMasuk _status = StatusMasuk.kosong;
  String? _pesanPanel;
  TombolPanel _tombol = TombolPanel.tidakAda;
  Map<String, String> _galatIsian = const {};

  StatusMasuk get status => _status;
  String? get pesanPanel => _pesanPanel;
  TombolPanel get tombol => _tombol;

  /// `errorText` isian Username dan Password dari `rincian` 422.
  String? get galatUsername => _galatIsian['username'];
  String? get galatPassword => _galatIsian['password'];

  Future<void> kirim() async {
    if (_status == StatusMasuk.memuat) return;
    if (_sesi.alamatServer.isEmpty) {
      _tampilkan(TeksGalat.alamatKosong);
      return;
    }
    _status = StatusMasuk.memuat;
    _pesanPanel = null;
    _tombol = TombolPanel.tidakAda;
    _galatIsian = const {};
    notifyListeners();

    try {
      await _sesi.masuk(username: username.text, password: password.text);
      // Sukses: Sesi mengganti layar, dan layar ini bisa sudah dibuang.
      if (_dibuang) return;
      password.clear();
      _status = StatusMasuk.kosong;
      notifyListeners();
    } on GalatApi catch (galat) {
      if (!_dibuang) _galatApi(galat);
    } on GalatJaringan {
      // Password tetap di isian (hanya di memori) agar Kirim ulang bisa langsung ditekan.
      if (!_dibuang) _tampilkan(TeksGalat.jaringanPost, tombol: TombolPanel.kirimUlang);
    } on GalatVersi {
      // Layar blokir versi diurus Sesi.
      if (_dibuang) return;
      password.clear();
      _status = StatusMasuk.kosong;
      notifyListeners();
    }
  }

  void _galatApi(GalatApi galat) {
    if (galat.perluPesanUmum) {
      _tampilkan(TeksGalat.umum, tombol: TombolPanel.cobaLagi);
      return;
    }
    // Server sudah memutuskan isian ini; password tidak disimpan di isian (docs/21_SECURITY_RULES.md).
    password.clear();
    if (galat.kode == KodeGalat.tidakValid) {
      const isian = {'username', 'password'};
      _galatIsian = {
        for (final e in galat.rincian.entries)
          if (isian.contains(e.key)) e.key: e.value,
      };
      final sisa = [
        for (final e in galat.rincian.entries)
          if (!isian.contains(e.key)) e.value,
      ];
      if (sisa.isEmpty && _galatIsian.isNotEmpty) {
        _status = StatusMasuk.gagal;
        notifyListeners();
      } else {
        _tampilkan(sisa.isEmpty ? galat.pesan : sisa.join('\n'));
      }
    } else {
      _tampilkan(teksGalat(galat, post: true));
    }
  }

  void _tampilkan(String pesan, {TombolPanel tombol = TombolPanel.tidakAda}) {
    _status = StatusMasuk.gagal;
    _pesanPanel = pesan;
    _tombol = tombol;
    notifyListeners();
  }

  @override
  void dispose() {
    _dibuang = true;
    username.dispose();
    password.dispose();
    super.dispose();
  }
}
