// Layar Tambah Donatur, tab 2 (P3 docs/06_BUSINESS_PROCESS.md). Urutannya mengikuti P3: kartu hasil
// setelah tersimpan, Nama Donator dengan daftar "Nama mirip" tepat di bawahnya, isian lain, lalu
// Sumbangan Pertama, di lembar dasbor tanpa isi kepala. "Nama mirip" di dalam kartu, karena warna
// teksPeringatan hanya boleh di atas latar putih. Simpan dan panel galatnya tetap di bawah seperti layar
// Input Sumbangan. Empat
// state: docs/26_UI_CONVENTIONS.md; tempat tampil galat: docs/14_ERROR_HANDLING.md.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../state/cari_donatur_notifier.dart';
import '../state/input_sumbangan_notifier.dart' show StatusSimpan;
import '../state/kerangka_notifier.dart';
import '../state/sesi.dart';
import '../state/tambah_donatur_notifier.dart';
import '../tema.dart';
import '../widget/avatar_inisial.dart';
import '../widget/dialog_konfirmasi.dart';
import '../widget/isian_angka.dart';
import '../widget/kartu_hasil.dart';
import '../widget/kerangka_memuat.dart';
import '../widget/latar_dasbor.dart';
import '../widget/panel_galat.dart';
import '../widget/tombol_utama.dart';

// Batas panjang kontrak §6.6; nilai di luar batas tidak bisa diketik.
const _panjangNama = 100;
const _panjangAlamat = 255;
const _panjangNoHp = 20;
const _panjangKeterangan = 255;

/// `sumbangan` paling besar 2.147.483.647 (kontrak §6.6): paling banyak 10 digit.
const _digitSumbangan = 10;

class LayarTambahDonatur extends StatefulWidget {
  const LayarTambahDonatur({super.key});

  @override
  State<LayarTambahDonatur> createState() => _LayarTambahDonaturState();
}

class _LayarTambahDonaturState extends State<LayarTambahDonatur> {
  late final KerangkaNotifier _kerangka = KerangkaScope.baca(context);
  late final TambahDonaturNotifier _notifier = TambahDonaturNotifier(
    SesiScope.baca(context),
    padaRingkasan: _kerangka.terimaRingkasan,
  )..addListener(_kembaliKeAtas);
  late final _berubah = Listenable.merge([_notifier, _notifier.mirip]);
  final _gulir = ScrollController();
  Object? _hasilTerakhir;

  @override
  void dispose() {
    _notifier.dispose();
    _gulir.dispose();
    super.dispose();
  }

  /// Setelah tersimpan, layar kembali ke atas (tanpa animasi) agar kartu Nomor Register terlihat.
  void _kembaliKeAtas() {
    final hasil = _notifier.hasil;
    if (hasil == null || identical(hasil, _hasilTerakhir)) return;
    _hasilTerakhir = hasil;
    if (_gulir.hasClients) _gulir.jumpTo(0);
  }

  Future<bool> _tanya({String? judul, String? nama, required List<String> isi}) =>
      tampilkanDialogKonfirmasi(context, judul: judul, nama: nama, isi: isi);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _berubah,
      builder: (context, _) {
        final n = _notifier;
        final terkunci = n.isianTerkunci;
        final simpanMemuat = n.statusSimpan == StatusSimpan.memuat;
        return LatarDasbor(
          isi: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ListView(
                  controller: _gulir,
                  padding: const EdgeInsets.all(Jarak.tepiLayar),
                  children: [
                    if (n.hasil case final hasil?) ...[
                      KartuHasil(
                        key: ObjectKey(hasil),
                        pesan: 'Data Donatur Berhasil Disimpan',
                        nomorRegister: hasil.donatur.id,
                        judul: hasil.donatur.nama,
                        jumlah: hasil.sumbangan.jumlah,
                        waktu: hasil.sumbangan.waktu,
                      ),
                      const SizedBox(height: Jarak.antarIsian),
                    ],
                    _IsianTeks(
                      label: 'Nama Donator',
                      controller: n.nama,
                      errorText: n.galatNama,
                      panjang: _panjangNama,
                      enabled: !terkunci,
                      huruf: TextCapitalization.words,
                    ),
                    _NamaMirip(
                      mirip: n.mirip,
                      padaPilih: terkunci ? null : _kerangka.inputSumbanganUntuk,
                    ),
                    const SizedBox(height: Jarak.antarIsian),
                    _IsianTeks(
                      label: 'Alamat',
                      controller: n.alamat,
                      errorText: n.galatAlamat,
                      panjang: _panjangAlamat,
                      enabled: !terkunci,
                      huruf: TextCapitalization.words,
                    ),
                    const SizedBox(height: Jarak.antarIsian),
                    _IsianTeks(
                      label: 'Nomor Handphone',
                      controller: n.noHp,
                      errorText: n.galatNoHp,
                      panjang: _panjangNoHp,
                      enabled: !terkunci,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: Jarak.antarIsian),
                    _IsianTeks(
                      label: 'Keterangan',
                      controller: n.keterangan,
                      errorText: n.galatKeterangan,
                      panjang: _panjangKeterangan,
                      enabled: !terkunci,
                      huruf: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: Jarak.antarIsian),
                    IsianAngka(
                      label: 'Sumbangan Pertama',
                      controller: n.sumbangan,
                      focusNode: n.fokusSumbangan,
                      errorText: n.galatSumbangan,
                      maksDigit: _digitSumbangan,
                      enabled: !terkunci,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => n.simpan(_tanya),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Jarak.tepiLayar, vertical: Jarak.j8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (n.statusSimpan == StatusSimpan.gagal && n.pesanSimpan != null) ...[
                      _PanelSimpan(
                        notifier: n,
                        padaInputNomor: _kerangka.inputSumbanganUntuk,
                        padaKirimUlang: () => n.kirimUlang(_tanya),
                      ),
                      const SizedBox(height: Jarak.j8),
                    ],
                    TombolUtama(
                      onPressed: n.bisaSimpan ? () => n.simpan(_tanya) : null,
                      child: simpanMemuat ? const IndikatorTombol() : const Text('Simpan'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Isian teks Tambah Donatur: berlabel, border garis luar, panjang dibatasi kontrak.
class _IsianTeks extends StatelessWidget {
  const _IsianTeks({
    required this.label,
    required this.controller,
    required this.errorText,
    required this.panjang,
    required this.enabled,
    this.keyboardType,
    this.huruf = TextCapitalization.none,
  });

  final String label;
  final TextEditingController controller;
  final String? errorText;
  final int panjang;
  final bool enabled;
  final TextInputType? keyboardType;
  final TextCapitalization huruf;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      textCapitalization: huruf,
      autocorrect: false,
      inputFormatters: [LengthLimitingTextInputFormatter(panjang)],
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(labelText: label, errorText: errorText, errorMaxLines: 3),
    );
  }
}

/// Peringatan "Nama mirip" (P3.2): hasil `caridonatur` untuk Nama. Ketuk satu nama → tab Input
/// dengan nomor itu. Selama pencarian berikutnya berjalan, hasil sebelumnya tetap tampil.
class _NamaMirip extends StatelessWidget {
  const _NamaMirip({required this.mirip, required this.padaPilih});

  final CariDonaturNotifier mirip;
  final ValueChanged<int>? padaPilih;

  @override
  Widget build(BuildContext context) {
    final gaya = Theme.of(context).textTheme.bodyMedium!;
    final tampil = mirip.status == StatusCari.sukses || mirip.status == StatusCari.memuat;
    if (mirip.status == StatusCari.gagal) {
      return Padding(
        padding: const EdgeInsets.only(top: Jarak.j8),
        child: PanelGalat(pesan: mirip.pesanPanel ?? '', labelTombol: 'Coba lagi', padaTombol: mirip.cari),
      );
    }
    if (!tampil || mirip.hasil.isEmpty) return const SizedBox.shrink();
    final pilih = padaPilih;
    return Padding(
      padding: const EdgeInsets.only(top: Jarak.j8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: Jarak.isiKartu),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Jarak.tepiLayar),
                child: Text('Nama mirip', style: gaya.copyWith(color: Warna.teksPeringatan)),
              ),
              for (final donatur in mirip.hasil)
                ListTile(
                  leading: AvatarInisial(donatur.nama),
                  title: Text(donatur.nama),
                  subtitle: Text('${donatur.id} · ${donatur.alamat}'),
                  onTap: pilih == null ? null : () => pilih(donatur.id),
                ),
              if (mirip.lebih)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Jarak.tepiLayar),
                  child: Text('Persempit pencarian', style: gaya.copyWith(color: Warna.teksInfo)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Panel di atas Simpan. 409 `donatur_sudah_ada` (P3.5): nomor yang ada + aksi
/// "Input sumbangan untuk nomor ini"; galat lain dengan Coba lagi atau Kirim ulang.
class _PanelSimpan extends StatelessWidget {
  const _PanelSimpan({
    required this.notifier,
    required this.padaInputNomor,
    required this.padaKirimUlang,
  });

  final TambahDonaturNotifier notifier;
  final ValueChanged<int> padaInputNomor;
  final VoidCallback padaKirimUlang;

  @override
  Widget build(BuildContext context) {
    final n = notifier;
    if (n.idSudahAda case final id?) {
      return PanelGalat(
        pesan: '${n.pesanSimpan}\nNomor Register: $id',
        labelTombol: 'Input sumbangan untuk nomor ini',
        padaTombol: () => padaInputNomor(id),
      );
    }
    return PanelGalat(
      pesan: n.pesanSimpan ?? '',
      labelTombol: switch (n.tombolSimpan) {
        TombolPanel.tidakAda => null,
        TombolPanel.cobaLagi => 'Coba lagi',
        TombolPanel.kirimUlang => 'Kirim ulang',
      },
      padaTombol: padaKirimUlang,
    );
  }
}
