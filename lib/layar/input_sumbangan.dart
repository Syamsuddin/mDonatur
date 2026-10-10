// Layar Input Sumbangan, tab 1 dan layar awal (P2 docs/06_BUSINESS_PROCESS.md). Urutannya mengikuti
// langkah P2: strip hari ini tepat di bawah AppBar, Nomor Donator + Cari + Cek, hasil Cek, Sumbangan,
// nominal cepat. Simpan dan panel galatnya tetap di bawah, supaya kartu donatur yang panjang tidak
// mendorongnya keluar layar. Empat state Cek dan Simpan: docs/26_UI_CONVENTIONS.md.

import 'package:flutter/material.dart';

import '../state/input_sumbangan_notifier.dart';
import '../state/kerangka_notifier.dart';
import '../state/sesi.dart';
import '../tema.dart';
import '../widget/dialog_konfirmasi.dart';
import '../widget/isian_angka.dart';
import '../widget/kartu_donatur.dart';
import '../widget/kartu_hasil.dart';
import '../widget/kerangka_memuat.dart';
import '../widget/nominal_cepat.dart';
import '../widget/panel_galat.dart';
import '../widget/state_kosong.dart';
import '../widget/strip_hari_ini.dart';
import 'cari_donatur.dart';

/// Nomor donatur 1–32767 (kontrak §6.3): paling banyak 5 digit.
const _digitNomor = 5;

/// `jumlah` paling besar 2.147.483.647 (kontrak §6.5): paling banyak 10 digit.
const _digitJumlah = 10;

class LayarInputSumbangan extends StatefulWidget {
  const LayarInputSumbangan({super.key});

  @override
  State<LayarInputSumbangan> createState() => _LayarInputSumbanganState();
}

class _LayarInputSumbanganState extends State<LayarInputSumbangan> {
  late final KerangkaNotifier _kerangka = KerangkaScope.baca(context);
  late final InputSumbanganNotifier _notifier = InputSumbanganNotifier(SesiScope.baca(context))
    ..addListener(_kembaliKeAtas);
  final _gulir = ScrollController();
  Object? _hasilTerakhir;

  /// Tab Donatur memakai notifier ini lewat kerangka: Cek nomor dan strip hari ini (P3).
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _kerangka.daftarkanInput(_notifier);
  }

  @override
  void dispose() {
    _kerangka.lepasInput(_notifier);
    _notifier.dispose();
    _gulir.dispose();
    super.dispose();
  }

  /// Setelah tersimpan, layar kembali ke atas (tanpa animasi) agar Nomor Donator dan kartu hasil
  /// terlihat, walaupun Simpan ditekan saat formulir tergulir.
  void _kembaliKeAtas() {
    final hasil = _notifier.hasil;
    if (hasil == null || identical(hasil, _hasilTerakhir)) return;
    _hasilTerakhir = hasil;
    if (_gulir.hasClients) _gulir.jumpTo(0);
  }

  Future<bool> _tanya({String? judul, String? nama, required List<String> isi}) =>
      tampilkanDialogKonfirmasi(context, judul: judul, nama: nama, isi: isi);

  Future<void> _bukaCari() async {
    final id = await Navigator.of(context).push<int>(
      MaterialPageRoute(builder: (_) => const LayarCariDonatur()),
    );
    if (id != null && mounted) await _notifier.pilihDonatur(id);
  }

  @override
  Widget build(BuildContext context) {
    final nominal = [
      for (final nilai in SesiScope.of(context).konfigurasi?.nominalUmum ?? const <int>[])
        if (nilai <= batasNominalCepat) nilai,
    ];
    return ListenableBuilder(
      listenable: _notifier,
      builder: (context, _) {
        final n = _notifier;
        final terkunci = n.isianTerkunci;
        final simpanMemuat = n.statusSimpan == StatusSimpan.memuat;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListView(
                controller: _gulir,
                children: [
                  // Strip ikut tergulir, supaya saat keyboard terbuka isian tetap mendapat ruang.
                  _Strip(notifier: n),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                        Jarak.tepiLayar, Jarak.j12, Jarak.tepiLayar, Jarak.j8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: IsianAngka(
                                label: 'Nomor Donator',
                                controller: n.nomor,
                                focusNode: n.fokusNomor,
                                errorText: n.galatNomor,
                                maksDigit: _digitNomor,
                                enabled: !terkunci,
                                padat: true,
                                textInputAction: TextInputAction.search,
                                onSubmitted: (_) => n.cek(),
                              ),
                            ),
                            const SizedBox(width: Jarak.j4),
                            IconButton(
                              icon: const Icon(Icons.search),
                              tooltip: 'Cari Donatur',
                              onPressed: terkunci ? null : _bukaCari,
                            ),
                            const SizedBox(width: Jarak.j4),
                            OutlinedButton(
                              onPressed: n.bisaCek ? n.cek : null,
                              child: n.statusCek == StatusCek.memuat
                                  ? const IndikatorTombol()
                                  : const Text('Cek'),
                            ),
                          ],
                        ),
                        const SizedBox(height: Jarak.antarIsianRapat),
                        if (n.statusCek == StatusCek.gagal && n.pesanCek != null) ...[
                          PanelGalat(
                            pesan: n.pesanCek!,
                            labelTombol: n.tombolCek == TombolPanel.cobaLagi ? 'Coba lagi' : null,
                            padaTombol: n.bisaCek ? n.cek : null,
                          ),
                          const SizedBox(height: Jarak.antarIsianRapat),
                        ],
                        if (n.donatur case final donatur?) ...[
                          KartuDonatur(donatur: donatur),
                          const SizedBox(height: Jarak.antarIsianRapat),
                        ] else if (n.hasil case final hasil?) ...[
                          KartuHasil(
                            pesan: 'Data Sumbangan Berhasil Disimpan',
                            judul: hasil.namaDonatur ?? '(donatur terhapus)',
                            jumlah: hasil.jumlah,
                            waktu: hasil.waktu,
                          ),
                          const SizedBox(height: Jarak.antarIsianRapat),
                        ] else if (n.statusCek == StatusCek.kosong)
                          const StateKosong('Ketik nomor donatur lalu tekan Cek'),
                        IsianAngka(
                          label: 'Sumbangan',
                          controller: n.jumlah,
                          focusNode: n.fokusJumlah,
                          errorText: n.galatJumlah,
                          maksDigit: _digitJumlah,
                          enabled: !terkunci,
                          padat: true,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => n.simpan(_tanya),
                        ),
                        const SizedBox(height: Jarak.j8),
                        NominalCepat(nominal: nominal, padaPilih: terkunci ? null : n.pilihNominal),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            DecoratedBox(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Warna.garis, width: Bentuk.garisPemisah)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Jarak.tepiLayar, vertical: Jarak.j8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (n.statusSimpan == StatusSimpan.gagal && n.pesanSimpan != null) ...[
                      PanelGalat(
                        pesan: n.pesanSimpan!,
                        labelTombol: switch (n.tombolSimpan) {
                          TombolPanel.tidakAda => null,
                          TombolPanel.cobaLagi => 'Coba lagi',
                          TombolPanel.kirimUlang => 'Kirim ulang',
                        },
                        padaTombol: () => n.kirimUlang(_tanya),
                      ),
                      const SizedBox(height: Jarak.j8),
                    ],
                    FilledButton(
                      onPressed: n.bisaSimpan ? () => n.simpan(_tanya) : null,
                      child: simpanMemuat ? const IndikatorTombol() : const Text('Simpan'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Strip di bawah AppBar: total hari ini, kerangka memuat, atau panel galat dengan Coba lagi.
class _Strip extends StatelessWidget {
  const _Strip({required this.notifier});

  final InputSumbanganNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final n = notifier;
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Warna.garis, width: Bentuk.garisPemisah)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Jarak.tepiLayar, vertical: Jarak.j8),
        child: switch (n.statusStrip) {
          StatusStrip.sukses => StripHariIni(total: n.totalHariIni, transaksi: n.transaksiHariIni),
          StatusStrip.memuat => const KerangkaMemuat(baris: 1),
          StatusStrip.gagal => PanelGalat(
              pesan: teksGalat(n.galatStrip ?? const Object(), post: false),
              labelTombol: 'Coba lagi',
              padaTombol: n.muatStrip,
            ),
        },
      ),
    );
  }
}
