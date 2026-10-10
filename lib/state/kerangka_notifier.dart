// State kerangka: tab aktif dan pesan antartab (docs/08_ARCHITECTURE.md: Kerangka memegang state
// keempat tab). Tab Donatur meminta tab Input mengecek satu nomor (P3.2, P3.5 docs/06), dan
// meneruskan `ringkasan_hari_ini` dari `tambahdonatur` ke strip tab Input (P3.4). Tab Input Saya
// meneruskan total hari ini ke strip yang sama (P4).

import 'dart:async';

import 'package:flutter/widgets.dart';

import '../api/model.dart';
import 'input_sumbangan_notifier.dart';

class KerangkaNotifier extends ChangeNotifier {
  static const tabInput = 0;
  static const tabInputSaya = 2;
  static const tabRekap = 3;

  var _tab = tabInput;
  InputSumbanganNotifier? _input;

  int get tab => _tab;

  void pilihTab(int tab) {
    if (tab == _tab) return;
    _tab = tab;
    notifyListeners();
  }

  /// Layar Input Sumbangan mendaftarkan notifiernya selama layar itu hidup.
  void daftarkanInput(InputSumbanganNotifier input) => _input = input;

  void lepasInput(InputSumbanganNotifier input) {
    if (identical(_input, input)) _input = null;
  }

  /// Pindah ke tab Input, nomor terisi, lalu Cek otomatis. Isian tab asal tidak disentuh.
  void inputSumbanganUntuk(int idDonatur) {
    pilihTab(tabInput);
    final input = _input;
    if (input != null) unawaited(input.pilihDonatur(idDonatur));
  }

  /// Strip hari ini di tab Input diperbarui dari jawaban aksi tulis tab lain.
  void terimaRingkasan(RingkasanHariIni ringkasan) => _input?.terimaRingkasan(ringkasan);

  /// Strip hari ini diperbarui dari `donasisaya` tanpa tanggal di tab Input Saya, misalnya setelah
  /// nominal hari ini diubah (`ubahdonasi` tidak membawa `ringkasan_hari_ini`).
  void terimaHariIni(DonasiSaya hariIni) => _input?.terimaHariIni(hariIni);
}

/// Menyediakan [KerangkaNotifier] bagi isi tab (docs/08_ARCHITECTURE.md).
class KerangkaScope extends InheritedNotifier<KerangkaNotifier> {
  const KerangkaScope({super.key, required KerangkaNotifier kerangka, required super.child})
      : super(notifier: kerangka);

  /// Kerangka tanpa berlangganan perubahan, untuk callback dan pendaftaran notifier.
  static KerangkaNotifier baca(BuildContext context) =>
      context.getInheritedWidgetOfExactType<KerangkaScope>()!.notifier!;
}
