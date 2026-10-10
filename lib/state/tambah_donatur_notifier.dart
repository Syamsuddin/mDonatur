// State layar Tambah Donatur (P3 docs/06_BUSINESS_PROCESS.md). Empat state di
// docs/26_UI_CONVENTIONS.md; tempat tampil galat di docs/14_ERROR_HANDLING.md. Validasi, duplikat
// persis, dan K9 diputuskan server; notifier ini hanya meneruskan hasilnya.

import 'package:flutter/widgets.dart';

import '../api/galat_api.dart';
import '../api/klien_api.dart';
import '../api/model.dart';
import '../util/rupiah.dart';
import 'cari_donatur_notifier.dart';
import 'input_sumbangan_notifier.dart' show StatusSimpan, Tanya, batasNominalKecil;
import 'sesi.dart';

class TambahDonaturNotifier extends ChangeNotifier {
  /// [padaRingkasan] meneruskan `ringkasan_hari_ini` ke strip tab Input (P3.4).
  TambahDonaturNotifier(this._sesi, {this.padaRingkasan}) : mirip = CariDonaturNotifier(_sesi.klien) {
    for (final MapEntry(key: kunci, value: isian) in _isian.entries) {
      _teksTerakhir[kunci] = isian.text;
      isian.addListener(() => _isianBerubah(kunci, isian));
    }
    _sesi.daftarkanCekIsian(_adaIsian);
  }

  final Sesi _sesi;
  final void Function(RingkasanHariIni ringkasan)? padaRingkasan;

  /// Nama mirip (P3.2): `caridonatur` dengan `q` = Nama, 500 ms setelah ketikan terakhir. Isian
  /// Nama Donator adalah isian cari milik notifier ini.
  final CariDonaturNotifier mirip;
  final alamat = TextEditingController();
  final noHp = TextEditingController();
  final keterangan = TextEditingController();
  final sumbangan = TextEditingController();
  final fokusSumbangan = FocusNode();
  var _dibuang = false;

  TextEditingController get nama => mirip.q;

  /// Isian menurut kunci `rincian` 422 (docs/14_ERROR_HANDLING.md §Pemetaan rincian).
  late final Map<String, TextEditingController> _isian = {
    KunciRincian.nama: nama,
    KunciRincian.alamat: alamat,
    KunciRincian.noHp: noHp,
    KunciRincian.keterangan: keterangan,
    KunciRincian.sumbangan: sumbangan,
  };

  // Teks terakhir yang sudah ditanggapi; listener controller juga terpanggil saat kursor pindah.
  final _teksTerakhir = <String, String>{};
  final _galat = <String, String>{};

  // _tertunda = kiriman terakhir yang belum terjawab sukses; Kirim ulang memakainya lagi.
  StatusSimpan _statusSimpan = StatusSimpan.siap;
  Kiriman<PermintaanTambahDonatur>? _tertunda;
  String? _pesanSimpan;
  TombolPanel _tombolSimpan = TombolPanel.tidakAda;
  int? _idSudahAda;
  JawabanTambahDonatur? _hasil;

  String? get galatNama => _galat[KunciRincian.nama];
  String? get galatAlamat => _galat[KunciRincian.alamat];
  String? get galatNoHp => _galat[KunciRincian.noHp];
  String? get galatKeterangan => _galat[KunciRincian.keterangan];
  String? get galatSumbangan => _galat[KunciRincian.sumbangan];

  StatusSimpan get statusSimpan => _statusSimpan;
  String? get pesanSimpan => _pesanSimpan;
  TombolPanel get tombolSimpan => _tombolSimpan;

  /// Nomor donatur yang sudah ada (409 `donatur_sudah_ada`, P3.5), untuk aksi
  /// "Input sumbangan untuk nomor ini".
  int? get idSudahAda => _idSudahAda;

  /// Donatur dan sumbangan pertama yang baru tersimpan, untuk kartu Nomor Register.
  JawabanTambahDonatur? get hasil => _hasil;

  bool get _simpanMemuat => _statusSimpan == StatusSimpan.memuat;

  /// Isian wajib, panjang, dan huruf diperiksa server (422); klien hanya butuh Sumbangan Pertama
  /// yang berupa angka untuk menyusun permintaan.
  bool get bisaSimpan => bacaAngka(sumbangan.text) != null && !_simpanMemuat;
  bool get isianTerkunci => _simpanMemuat;

  bool _adaIsian() => _isian.values.any((isian) => isian.text.isNotEmpty);

  /// Tombol Simpan. Sumbangan Pertama < [batasNominalKecil] ditanyakan dulu (P3.3); setiap Simpan
  /// memakai kunci kirim ulang baru.
  Future<void> simpan(Tanya tanya) async {
    if (!bisaSimpan) return;
    final nilai = bacaAngka(sumbangan.text)!;
    if (nilai < batasNominalKecil) {
      final ya = await tanya(isi: ['Nominal ${formatRupiah(nilai)} — benar?']);
      if (_dibuang) return;
      if (!ya) {
        fokusSumbangan.requestFocus();
        return;
      }
      if (!bisaSimpan) return;
    }
    final isi = PermintaanTambahDonatur(
      nama: nama.text,
      alamat: alamat.text,
      noHp: noHp.text,
      keterangan: keterangan.text,
      sumbangan: nilai,
    );
    await _kirim(Kiriman(isi), tanya);
  }

  /// Kirim ulang (galat jaringan) atau Coba lagi (pesan umum): isi dan kunci sama persis.
  Future<void> kirimUlang(Tanya tanya) async {
    final kiriman = _tertunda;
    if (kiriman == null || _simpanMemuat) return;
    await _kirim(kiriman, tanya);
  }

  Future<void> _kirim(Kiriman<PermintaanTambahDonatur> kiriman, Tanya tanya) async {
    _tertunda = kiriman;
    _statusSimpan = StatusSimpan.memuat;
    _pesanSimpan = null;
    _tombolSimpan = TombolPanel.tidakAda;
    _idSudahAda = null;
    _hasil = null;
    _galat.clear();
    notifyListeners();

    try {
      final jawaban = await _sesi.klien.tambahDonatur(kiriman);
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

  /// 409 `perlu_konfirmasi` K9 (P3.6, sama dengan P2.6): Ya, simpan mengirim isi yang sama dengan
  /// `konfirmasi: true` dan kunci baru; Tidak kembali ke isian.
  Future<void> _konfirmasiServer(
    Kiriman<PermintaanTambahDonatur> kiriman,
    GalatApi galat,
    Tanya tanya,
  ) async {
    _tertunda = null;
    _statusSimpan = StatusSimpan.siap;
    notifyListeners();
    final nama = kiriman.isi.nama.trim();
    final ya = await tanya(
      judul: galat.pesan.isEmpty ? null : galat.pesan,
      nama: nama.isEmpty ? null : nama,
      isi: galat.alasan,
    );
    if (ya && !_dibuang) await _kirim(Kiriman(kiriman.isi.denganKonfirmasi()), tanya);
  }

  /// 201, atau 2xx dengan `"ulang": true` (P3.4).
  void _tersimpan(JawabanTambahDonatur jawaban) {
    _tertunda = null;
    _statusSimpan = StatusSimpan.siap;
    _hasil = jawaban;
    padaRingkasan?.call(jawaban.ringkasanHariIni);
    // Mengosongkan Nama juga mengosongkan daftar nama mirip (CariDonaturNotifier).
    for (final isian in _isian.values) {
      isian.clear();
    }
    notifyListeners();
  }

  void _galatSimpan(GalatApi galat) {
    if (galat.kode == KodeGalat.tidakValid) {
      final sisa = {...galat.rincian};
      for (final kunci in _isian.keys) {
        if (sisa.remove(kunci) case final pesan?) _galat[kunci] = pesan;
      }
      if (sisa.isEmpty && _galat.isNotEmpty) {
        _tertunda = null;
        _statusSimpan = StatusSimpan.gagal;
        notifyListeners();
      } else {
        _gagalSimpan(sisa.isEmpty ? galat.pesan : sisa.values.join('\n'), TombolPanel.tidakAda);
      }
    } else if (galat.kode == KodeGalat.donaturSudahAda) {
      _idSudahAda = galat.idDonatur;
      _gagalSimpan(teksGalat(galat, post: true), TombolPanel.tidakAda);
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

  void _isianBerubah(String kunci, TextEditingController isian) {
    if (isian.text == _teksTerakhir[kunci]) return;
    _teksTerakhir[kunci] = isian.text;
    _galat.remove(kunci);
    _lupakanGagalSimpan();
    notifyListeners();
  }

  /// Isian berubah setelah Simpan gagal: Kirim ulang tidak boleh lagi mengirim isi lama, dan
  /// nomor donatur yang sudah ada tidak lagi berlaku untuk isian baru.
  void _lupakanGagalSimpan() {
    if (_statusSimpan != StatusSimpan.gagal) return;
    _tertunda = null;
    _statusSimpan = StatusSimpan.siap;
    _pesanSimpan = null;
    _tombolSimpan = TombolPanel.tidakAda;
    _idSudahAda = null;
  }

  @override
  void dispose() {
    _dibuang = true;
    _sesi.lepasCekIsian(_adaIsian);
    mirip.dispose();
    alamat.dispose();
    noHp.dispose();
    keterangan.dispose();
    sumbangan.dispose();
    fokusSumbangan.dispose();
    super.dispose();
  }
}
